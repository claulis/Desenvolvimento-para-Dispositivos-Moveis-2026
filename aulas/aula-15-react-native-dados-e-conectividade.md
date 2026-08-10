# Aula 15 — React Native: camada de dados e conectividade

**Carga horária:** 4h
**Unidade:** IV — Arquitetura de software em React Native

## Objetivos da aula

- Implementar o padrão repositório em React Native, com persistência local e detecção de conectividade.
- Projetar estratégia off-line, cache e degradação graciosa.
- Comparar as ferramentas de dados do React Native com as equivalentes em Flutter (Aula 11).

## 1. Padrão repositório em React Native

Os mesmos princípios da Aula 11 se aplicam: a camada de domínio não deve saber se um dado vem de uma API remota, de armazenamento local, ou de cache — essa decisão pertence exclusivamente ao repositório.

```tsx
interface PedidoRepository {
  obterPedidos(): Promise<Pedido[]>;
  salvarPedido(pedido: Pedido): Promise<void>;
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
}
```

## 2. Cliente HTTP

O React Native não inclui um cliente HTTP dedicado além do `fetch` padrão da Web API, disponível no runtime JavaScript. Bibliotecas como `axios` são amplamente adotadas por oferecerem interceptadores, cancelamento de requisição e tratamento de erro mais estruturado — papel equivalente ao do pacote `dio` no ecossistema Flutter (Aula 11).

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

## 3. Persistência local

| Ferramenta | Uso adequado |
|---|---|
| `AsyncStorage` | Pares chave-valor simples, sem estrutura relacional |
| `MMKV` (`react-native-mmkv`) | Chave-valor de alto desempenho, mais rápido que `AsyncStorage` |
| `WatermelonDB` / `op-sqlite` | Dados estruturados e relacionais com necessidade de consultas complexas |

A tabela é diretamente comparável à da Aula 11: `AsyncStorage` cumpre o papel do `shared_preferences` do Flutter, e `WatermelonDB`/`op-sqlite` cumprem o papel do `sqflite`/`drift` — mesma decisão arquitetural (tipo e volume do dado determinam a ferramenta), expressa em bibliotecas diferentes.

```tsx
import AsyncStorage from '@react-native-async-storage/async-storage';

async function salvarCache(pedidos: Pedido[]): Promise<void> {
  await AsyncStorage.setItem('pedidos_cache', JSON.stringify(pedidos));
}

async function obterCache(): Promise<Pedido[]> {
  const dados = await AsyncStorage.getItem('pedidos_cache');
  return dados ? JSON.parse(dados) : [];
}
```

## 4. Detecção do estado de conectividade

O pacote `@react-native-community/netinfo` cumpre, em React Native, o papel do `connectivity_plus` estudado na Aula 11: expõe o estado de conectividade atual e permite assinar mudanças em tempo real.

```tsx
import NetInfo from '@react-native-community/netinfo';

function useConectividade() {
  const [conectado, setConectado] = useState(true);

  useEffect(() => {
    const cancelarAssinatura = NetInfo.addEventListener((estado) => {
      setConectado(estado.isConnected ?? false);
    });
    return cancelarAssinatura;
  }, []);

  return conectado;
}
```

## 5. Estratégia off-line e degradação graciosa

> **Definição — Degradação graciosa (graceful degradation)**: princípio de projeto segundo o qual um sistema, ao perder acesso a um recurso (como a rede), reduz sua funcionalidade de forma controlada e comunicada ao usuário, em vez de falhar de forma abrupta ou travar (crashing) — a aplicação continua útil, ainda que com capacidades reduzidas.

Aplicado a uma tela de catálogo de produtos:

```tsx
function TelaCatalogo() {
  const conectado = useConectividade();
  const { produtos, carregando, erro } = useProdutos();

  return (
    <View style={{ flex: 1 }}>
      {!conectado && <FaixaOffline texto="Sem conexão — exibindo dados salvos" />}
      {carregando && <IndicadorDeCarregamento />}
      {erro && conectado && <MensagemDeErro erro={erro} />}
      {produtos.length > 0 && <ListaDeProdutos produtos={produtos} />}
      {produtos.length === 0 && !carregando && <EstadoVazio />}
    </View>
  );
}
```

Esse componente traduz diretamente, em código, a discussão da Aula 8 sobre estados de vazio, carregamento e erro, agora somada ao estado de "offline com dados em cache" introduzido na Aula 11 — a mesma teoria de estados de interface, aplicada agora ao segundo framework do componente.

## 6. Sincronização de mudanças pendentes

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

Esse padrão — acumular mudanças feitas offline e reconciliá-las ao restabelecer conexão — é idêntico em intenção ao sincronizador Flutter da Aula 11, reforçando que o problema de conectividade intermitente é do domínio do aplicativo móvel, não de uma linguagem ou framework específico.

## 7. Exemplo real: carrinho de compras que sobrevive à perda de conexão

Em aplicativos de e-commerce, um comportamento esperado — e frequentemente ausente em implementações mal projetadas — é que o carrinho de compras montado pelo usuário sobreviva a uma perda temporária de conexão: o usuário deve poder continuar adicionando itens ao carrinho mesmo sem rede, com a sincronização ocorrendo de forma transparente quando a conexão retornar, sem que o usuário perceba a interrupção como uma falha. Implementar esse comportamento exige exatamente a combinação de persistência local, detecção de conectividade e sincronização estudada nesta aula — não é um "recurso avançado", é a aplicação direta da resiliência esperada de qualquer aplicativo móvel de uso sério.

## Síntese da aula

| Mecanismo Flutter (Aula 11) | Equivalente React Native |
|---|---|
| `http`/`dio` | `fetch`/`axios` |
| `shared_preferences` | `AsyncStorage`/`MMKV` |
| `sqflite`/`drift` | `WatermelonDB`/`op-sqlite` |
| `connectivity_plus` | `@react-native-community/netinfo` |

## Leitura recomendada

- Documentação oficial: [NetInfo](https://github.com/react-native-netinfo/react-native-netinfo) e [AsyncStorage](https://react-native-async-storage.github.io/async-storage/).

## Atividade da aula

**Prática: repositório com duas fontes intercambiáveis, testado com banda limitada e perda de conexão no emulador**: implementar um `PedidoRepository` equivalente ao construído em Flutter na Aula 11, com fonte remota e local, cache e sincronização de pendências, testado sob as mesmas condições de rede limitada e modo avião no emulador Android.
