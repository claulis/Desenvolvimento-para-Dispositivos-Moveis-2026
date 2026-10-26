# Aula 18 — React Native: camada de dados e conectividade

**Carga horária:** 4h
**Unidade:** IV — Arquitetura de software em React Native

## Objetivos da aula

- Implementar o padrão repositório em React Native, com persistência local e detecção de conectividade.
- Projetar estratégia off-line, cache e degradação graciosa.
- Comparar as ferramentas de dados do React Native com as equivalentes em Flutter (Aula 13).

## Organização da aula

A aula percorre a camada de dados em React Native e a relaciona, tópico a tópico, à Aula 13. A sequência é: abstração que isola a origem dos dados (§1), ferramentas de acesso e armazenamento (§2 e §3), detecção do estado da rede (§4) e estratégias que mantêm o aplicativo útil sem conexão (§5 e §6). O objetivo é evidenciar que o problema da conectividade intermitente pertence ao domínio do aplicativo móvel, e não a um framework específico. Cada tópico segue a ordem: problema, mecanismo e aplicação.

## 1. Padrão repositório em React Native

### Problema

Os problemas descritos na Aula 13 persistem: se a interface ou o domínio acessam a API diretamente, qualquer mudança no servidor, no formato dos dados ou na estratégia de cache propaga-se por todo o código. Além disso, a fonte dos dados varia em tempo de execução, conforme haja ou não rede.

### Mecanismo

Os mesmos princípios da Aula 13 aplicam-se: a camada de domínio não deve saber se um dado vem de uma API remota, de armazenamento local ou de cache. Essa decisão pertence exclusivamente ao repositório. A separação é feita por uma **interface** (o contrato visto pelo domínio) e uma **implementação** que coordena as fontes remota e local.

Há ainda uma decisão de projeto essencial: distinguir falhas de **conectividade** de falhas de **servidor**. Apenas as primeiras justificam o uso de cache como alternativa. Para isso, define-se um erro de domínio próprio, `NetworkError`, lançado sempre que a falha é de conectividade.

### Aplicação

```tsx
// Erro de domínio próprio, lançado pelo interceptador de rede (§2) sempre que
// a falha é de conectividade — não confundir com erros HTTP (4xx/5xx), que
// devem se propagar normalmente em vez de cair no fallback de cache.
export class NetworkError extends Error {
  constructor(mensagem: string) {
    super(mensagem);
    this.name = 'NetworkError';
  }
}

interface PedidoRepository {
  obterPedidos(): Promise<Pedido[]>;
  salvarPedido(pedido: Pedido): Promise<void>;
  enviarAlteracao(alteracao: AlteracaoPendente): Promise<void>;
}

class PedidoRepositoryImpl implements PedidoRepository {
  constructor(
    private remoto: PedidoRemoteDataSource,
    private local: PedidoLocalDataSource
  ) {}

  async obterPedidos(): Promise<Pedido[]> {
    try {
      const pedidos = await this.remoto.buscarPedidos();
      await this.local.salvarCache(pedidos);
      return pedidos;
    } catch (erro) {
      if (erro instanceof NetworkError) {
        return this.local.obterCache(); // sem rede: usa cache
      }
      throw erro;
    }
  }

  async salvarPedido(pedido: Pedido): Promise<void> {
    await this.remoto.salvar(pedido);
  }

  async enviarAlteracao(alteracao: AlteracaoPendente): Promise<void> {
    await this.remoto.enviarAlteracao(alteracao); // usado na sincronização, §6
  }
}
```

Leitura do fluxo: o repositório tenta a fonte remota; em caso de êxito, atualiza o cache e devolve os dados recentes. Se o erro capturado é uma instância de `NetworkError`, devolve o cache. Qualquer outro erro (por exemplo, resposta 500 do servidor) é relançado com `throw erro`, pois a ausência de rede não o explica, e mascará-lo com dados antigos ocultaria uma falha real. A sintaxe `private remoto` no construtor é um atalho do TypeScript que declara e inicializa a propriedade simultaneamente.

## 2. Cliente HTTP

### Problema

O código de aplicação precisa realizar requisições, definir tempos limite e tratar falhas de forma uniforme. Fazê-lo em cada chamada individual produz repetição e inconsistência.

### Mecanismo

O React Native não inclui um cliente HTTP dedicado além do `fetch` padrão da Web API, disponível no runtime JavaScript. Bibliotecas como o `axios` são amplamente adotadas por oferecerem **interceptadores** (código executado em todas as requisições ou respostas), cancelamento de requisição e tratamento de erro mais estruturado. Seu papel equivale ao do pacote `dio` no ecossistema Flutter (Aula 13).

A distinção entre falha de rede e erro de servidor apoia-se em uma característica do `axios`: quando o servidor responde (mesmo com status 4xx ou 5xx), o objeto de erro possui a propriedade `response`; quando a requisição sequer obtém resposta (sem conexão, *timeout*), `response` é indefinida.

### Aplicação

```tsx
const api = axios.create({ baseURL: 'https://api.exemplo.com', timeout: 8000 });

api.interceptors.response.use(
  (resposta) => resposta,
  (erro) => {
    if (!erro.response) throw new NetworkError('Sem conexão com o servidor');
    throw erro;
  }
);
```

O interceptador de resposta converte, em um único ponto, toda falha sem resposta em `NetworkError`. Assim, o repositório da §1 não precisa conhecer detalhes do `axios`: depende apenas do erro de domínio. O `timeout: 8000` garante que uma conexão pendente seja encerrada após oito segundos, em vez de manter o usuário aguardando indefinidamente.

## 3. Persistência local

### Problema

Como na Aula 13, o volume e a estrutura dos dados determinam a ferramenta adequada. Uma preferência de tema e uma lista extensa de pedidos relacionados têm necessidades muito diferentes.

### Mecanismo e critério de escolha

| Ferramenta | Modelo de armazenamento | Uso adequado |
|---|---|---|
| `AsyncStorage` | Chave-valor assíncrono | Pares chave-valor simples, sem estrutura relacional |
| `MMKV` (`react-native-mmkv`) | Chave-valor de alto desempenho | Chave-valor mais rápido que `AsyncStorage` |
| `WatermelonDB` / `op-sqlite` | Banco estruturado (SQLite) | Dados estruturados e relacionais, com necessidade de consultas complexas |

A tabela é diretamente comparável à da Aula 13: `AsyncStorage` cumpre o papel do `shared_preferences` do Flutter, e `WatermelonDB`/`op-sqlite` cumprem o papel de `sqflite`/`drift`. Trata-se da mesma decisão arquitetural (tipo e volume do dado determinam a ferramenta), expressa em bibliotecas diferentes.

### Aplicação

```tsx
import { MMKV } from 'react-native-mmkv';

// Para caches maiores que uns poucos KB, MMKV é preferível a AsyncStorage:
// é síncrono (sem custo de Promise para uma leitura local) e não tem o limite
// prático de ~2MB por entrada do AsyncStorage no Android — relevante assim
// que a lista de pedidos em cache cresce além de um protótipo pequeno.
const armazenamento = new MMKV();

function salvarCache(pedidos: Pedido[]): void {
  armazenamento.set('pedidos_cache', JSON.stringify(pedidos));
}

function obterCache(): Pedido[] {
  const dados = armazenamento.getString('pedidos_cache');
  return dados ? JSON.parse(dados) : [];
}
```

Como o armazenamento guarda texto, a lista é serializada com `JSON.stringify` ao gravar e reconstruída com `JSON.parse` ao ler (serialização, Aula 13). O retorno de lista vazia quando não há cache evita que o código chamador precise tratar `null`. A natureza síncrona do MMKV dispensa `await` na leitura local, o que simplifica o código.

## 4. Detecção do estado de conectividade

### Problema

O aplicativo precisa informar o usuário sobre a condição da rede e ajustar seu comportamento. Para isso, é necessário observar o estado de conectividade ao longo do tempo, e não apenas consultá-lo uma vez.

### Mecanismo

O pacote `@react-native-community/netinfo` cumpre, em React Native, o papel do `connectivity_plus` estudado na Aula 13: expõe o estado de conectividade atual e permite assinar mudanças em tempo real. O hook abaixo encapsula a assinatura e entrega ao componente apenas um valor booleano.

Existe uma sutileza importante. A propriedade `isConnected` informa se há uma interface de rede ativa (por exemplo, um Wi-Fi associado), mas **não** garante que a internet seja alcançável. Já `isInternetReachable` indica se é possível, de fato, alcançar a internet.

### Aplicação

```tsx
import NetInfo from '@react-native-community/netinfo';

function useConectividade() {
  const [conectado, setConectado] = useState(true);

  useEffect(() => {
    const cancelarAssinatura = NetInfo.addEventListener((estado) => {
      // isConnected reporta apenas se há uma interface de rede ativa (ex.: Wi-Fi
      // associado) — não se a internet é de fato alcançável. Um Wi-Fi de portal
      // cativo (hotel, aeroporto) sem login feito conta como "conectado" por
      // isConnected e falha em isInternetReachable. Convém usar o segundo quando
      // a pergunta real é "consigo falar com meu servidor agora?".
      setConectado(estado.isInternetReachable ?? estado.isConnected ?? false);
    });
    return cancelarAssinatura;
  }, []);

  return conectado;
}
```

Leitura do código: `addEventListener` registra um ouvinte e devolve a função que o remove. Retornar essa função de dentro do `useEffect` faz o React cancelar a assinatura quando o componente é desmontado, o que evita vazamento de memória. O operador `??` (coalescência nula) usa `isInternetReachable` quando disponível (pode ser `null` enquanto a verificação não termina), recorre a `isConnected` em seguida e assume `false` como último caso. A lista de dependências vazia (`[]`) indica que a assinatura é criada uma única vez.

## 5. Estratégia off-line e degradação graciosa

> **Definição — Degradação graciosa (graceful degradation)**: princípio de projeto segundo o qual um sistema, ao perder acesso a um recurso (como a rede), reduz sua funcionalidade de forma controlada e comunicada ao usuário, em vez de falhar de forma abrupta ou travar (crashing) — a aplicação continua útil, ainda que com capacidades reduzidas.

### Problema

A interface precisa representar vários estados possíveis: carregando, erro, vazio, com dados e com dados possivelmente desatualizados por falta de rede. Quando esses estados são representados por múltiplos booleanos independentes (`carregando`, `temErro`, `offline`), combinações incoerentes tornam-se possíveis, e o código passa a depender de condições cruzadas difíceis de raciocinar.

### Mecanismo

A solução consiste em modelar os estados como um **tipo união discriminada**: um único valor, que só pode estar em um estado por vez, e cada estado carrega apenas os dados que lhe dizem respeito. Uma função pura calcula esse estado a partir das informações disponíveis, e o componente apenas o exibe.

### Aplicação

```tsx
// Estado explícito e mutuamente exclusivo, em vez de múltiplos booleanos
// combináveis — com carregando=true e produtos.length>0 simultâneos (caso
// normal de stale-while-revalidate, Aula 13), a versão com booleanos soltos
// exibiria o indicador de carregamento SOBRE a lista já preenchida ao mesmo
// tempo, o que não é a intenção aqui. Calcular um único estado nomeado evita
// essa ambiguidade por construção.
type EstadoCatalogo =
  | { tipo: 'carregando' }
  | { tipo: 'erro'; erro: Error }
  | { tipo: 'vazio' }
  | { tipo: 'comDados'; produtos: Produto[]; desatualizado: boolean };

function calcularEstado(
  conectado: boolean,
  carregando: boolean,
  erro: Error | null,
  produtos: Produto[]
): EstadoCatalogo {
  if (produtos.length > 0) return { tipo: 'comDados', produtos, desatualizado: !conectado };
  if (carregando) return { tipo: 'carregando' };
  if (erro) return { tipo: 'erro', erro };
  return { tipo: 'vazio' };
}

function TelaCatalogo() {
  const conectado = useConectividade();
  const { produtos, carregando, erro } = useProdutos();
  const estado = calcularEstado(conectado, carregando, erro, produtos);

  return (
    <View style={{ flex: 1 }}>
      {!conectado && <FaixaOffline texto="Sem conexão — exibindo dados salvos" />}
      {estado.tipo === 'carregando' && <IndicadorDeCarregamento />}
      {estado.tipo === 'erro' && <MensagemDeErro erro={estado.erro} />}
      {estado.tipo === 'comDados' && <ListaDeProdutos produtos={estado.produtos} />}
      {estado.tipo === 'vazio' && <EstadoVazio />}
    </View>
  );
}
```

Leitura da função `calcularEstado`: a ordem das verificações expressa prioridades. Se há produtos, eles são exibidos, mesmo que uma atualização esteja em andamento ou que a rede tenha caído (estratégia *stale-while-revalidate*, Aula 13). Só na ausência de produtos é que se consideram, nessa ordem, o carregamento, o erro e, por fim, o estado vazio. O campo `desatualizado` sinaliza que os dados podem estar defasados. O discriminante `tipo` permite ao TypeScript restringir o tipo dentro de cada condição: em `estado.tipo === 'erro'`, o compilador sabe que `estado.erro` existe.

Este componente traduz diretamente, em código, a discussão da Aula 4 sobre estados de vazio, carregamento e erro, agora somada ao estado "offline com dados em cache" introduzido na Aula 13. Modelar o estado como um tipo nomeado e mutuamente exclusivo, em vez de múltiplos booleanos independentes, é a mesma disciplina de rigor exigida pela Aula 4: os estados de interface não são detalhes, fazem parte do design, e devem ser representados sem ambiguidade no código.

## 6. Sincronização de mudanças pendentes

### Problema

Alterações realizadas sem rede não podem ser descartadas nem enviadas de imediato. Precisam ser guardadas e enviadas quando a conexão retornar, sem perda.

### Mecanismo e aplicação

As alterações ficam registradas como **pendentes**. Na sincronização, cada uma é enviada ao servidor; as que falham permanecem na lista para uma tentativa posterior. Ao final, o armazenamento é atualizado apenas com as alterações restantes.

```tsx
async function sincronizarPendentes(repositorio: PedidoRepository) {
  const pendentes = await AsyncStorage.getItem('alteracoes_pendentes');
  const lista: AlteracaoPendente[] = pendentes ? JSON.parse(pendentes) : [];

  const restantes: AlteracaoPendente[] = [];
  for (const alteracao of lista) {
    try {
      await repositorio.enviarAlteracao(alteracao);
    } catch {
      restantes.push(alteracao); // mantém para tentar depois
    }
  }
  await AsyncStorage.setItem('alteracoes_pendentes', JSON.stringify(restantes));
}
```

Observa-se que as alterações bem-sucedidas desaparecem da lista porque só as falhas são acrescentadas a `restantes`. Diferentemente do sincronizador Flutter da Aula 13, que interrompe o processo ao primeiro erro de conectividade, este laço tenta todas as alterações e conserva as que falharem; ambas as abordagens são válidas, com compromissos diferentes (a primeira poupa tentativas inúteis sem rede, a segunda aproveita o caso em que apenas algumas alterações são rejeitadas).

Esse padrão (acumular mudanças feitas offline e reconciliá-las ao restabelecer a conexão) é idêntico em intenção ao sincronizador da Aula 13, o que reforça que o problema de conectividade intermitente é do domínio do aplicativo móvel, e não de uma linguagem ou framework específico. A mesma ressalva da Aula 13 vale aqui: este laço não trata **conflito** entre uma alteração local e uma mudança concorrente no servidor; apenas repete o envio até ter êxito. Também não distingue um erro de servidor permanente (que reenviar nunca resolverá) de uma falha transitória.

> **Elo com a Aula 17**: depois de implementar cache, revalidação e sincronização manualmente nesta aula, convém observar o mesmo comportamento coberto em poucas linhas por uma biblioteca de *server state* como o TanStack Query (persistência offline via plugin, nova tentativa com backoff embutida). A melhor forma de compreender o que a biblioteca faz é compará-la com a implementação manual desenvolvida aqui.

## 7. Exemplo real: carrinho de compras que sobrevive à perda de conexão

Em aplicativos de e-commerce, um comportamento esperado, e frequentemente ausente em implementações mal projetadas, é que o carrinho montado pelo usuário sobreviva a uma perda temporária de conexão. O usuário deve poder continuar adicionando itens mesmo sem rede, com a sincronização ocorrendo de forma transparente quando a conexão retornar, sem que perceba a interrupção como falha.

Esse comportamento combina os mecanismos da aula:

- **persistência local** (§3): o carrinho é gravado no aparelho a cada alteração;
- **detecção de conectividade** (§4): o aplicativo sabe quando a rede retornou;
- **sincronização** (§6): as alterações pendentes são enviadas ao servidor.

Não se trata de um recurso avançado, e sim da aplicação direta da resiliência esperada de qualquer aplicativo móvel de uso sério.

## Síntese da aula

| Mecanismo Flutter (Aula 13) | Equivalente React Native | Problema que resolve |
|---|---|---|
| `http`/`dio` | `fetch`/`axios` | Padronização de requisições e tratamento de falhas |
| `shared_preferences` | `AsyncStorage`/`MMKV` | Persistência de pares chave-valor |
| `sqflite`/`drift` | `WatermelonDB`/`op-sqlite` | Persistência de dados estruturados e relacionais |
| `connectivity_plus` | `@react-native-community/netinfo` | Observação do estado da rede em tempo real |
| `AsyncValue` / estados de interface | União discriminada (`EstadoCatalogo`) | Estados de interface incoerentes ou ambíguos |

## Leitura recomendada

- Documentação oficial: [NetInfo](https://github.com/react-native-netinfo/react-native-netinfo) e [AsyncStorage](https://react-native-async-storage.github.io/async-storage/).
