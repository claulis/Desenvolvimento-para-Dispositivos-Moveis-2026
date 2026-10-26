# Aula 17 — React Native: arquitetura em camadas e gerenciamento de estado

**Carga horária:** 4h
**Unidade:** IV — Arquitetura de software em React Native

## Objetivos da aula

- Estruturar uma aplicação React Native em camadas de apresentação, domínio e dados.
- Explicar o papel dos hooks na separação entre estado e interface.
- Comparar Context, Redux e Zustand como soluções de gerenciamento de estado.

## Organização da aula

A aula retoma, em React Native, as duas questões da Aula 12: **onde cada tipo de código deve residir** (arquitetura em camadas, §1, §2, §4 e §6) e **como o estado é armazenado e propagado** (§2.1, §3 e §5). Uma distinção organiza o conteúdo: a diferença entre **estado de servidor** e **estado de cliente** (§2.1), que determina qual ferramenta é adequada a cada tipo de dado. Cada tópico segue a sequência: problema, mecanismo e aplicação.

## 1. Arquitetura em camadas em React Native

### Problema

Os problemas da mistura de responsabilidades descritos na Aula 12 (dificuldade de trocar a fonte de dados, impossibilidade de testar regras sem a interface, reuso custoso de lógica) não dependem do framework. Um componente React Native que acessa a rede diretamente reproduz exatamente os mesmos defeitos de um widget Flutter equivalente.

### Mecanismo

Os mesmos princípios de arquitetura em camadas estudados na Aula 12 aplicam-se integralmente ao React Native. A separação entre apresentação, domínio e dados é uma decisão de arquitetura de software, independente do framework de interface escolhido. O que muda é a sintaxe e as ferramentas disponíveis em cada ecossistema. A dependência permanece unidirecional: apresentação → domínio → dados.

### Aplicação

O primeiro exemplo mostra a violação:

```tsx
// Violação de camada: componente conhece detalhes de rede
function TelaPedidosRuim() {
  const [pedidos, setPedidos] = useState([]);

  useEffect(() => {
    fetch('https://api.exemplo.com/pedidos')
      .then((res) => res.json())
      .then((dados) => setPedidos(dados)); // rede + parsing + estado, tudo aqui
  }, []);

  return <ListaDePedidos pedidos={pedidos} />;
}
```

O componente conhece o endereço da API, o formato da resposta e o ciclo de vida do estado. Além disso, `useState([])` sem tipo faz o TypeScript inferir `never[]`/`any[]`, o que compromete a verificação de tipos. O segundo exemplo apresenta a correção:

```tsx
// Correto: componente delega ao domínio/dados via um hook customizado
function TelaPedidos() {
  const { pedidos, carregando, erro } = usePedidos(); // hook encapsula a lógica

  if (carregando) return <IndicadorDeCarregamento />;
  if (erro) return <MensagemDeErro erro={erro} />;
  return <ListaDePedidos pedidos={pedidos} />;
}
```

Agora o componente apenas decide **como exibir** o que o hook entrega, nos três estados clássicos da Aula 4 (carregando, erro e conteúdo).

## 2. O papel dos hooks customizados na separação de camadas

### Problema

No React, a lógica de estado e de efeitos colaterais só pode ser escrita dentro de componentes ou de hooks. Se permanecer no componente visual, ela se mistura à interface. É preciso um mecanismo para extrair essa lógica sem recorrer a classes ou herança.

### Mecanismo

> **Definição — Hook customizado**: função JavaScript/TypeScript, com nome prefixado por `use`, que encapsula lógica reutilizável de estado e efeitos colaterais, podendo internamente chamar outros hooks (`useState`, `useEffect`, hooks de terceiros) — o mecanismo central pelo qual React e React Native permitem extrair lógica de fora do componente visual sem recorrer a classes ou herança.

Um hook customizado é uma função comum que chama outros hooks. O prefixo `use` não é apenas convenção: as ferramentas de análise do React o utilizam para verificar que os hooks são chamados corretamente. O componente passa a receber apenas o resultado (`{ pedidos, carregando, erro }`), sem conhecer como foi obtido.

### Aplicação

```tsx
function usePedidos() {
  const [pedidos, setPedidos] = useState<Pedido[]>([]);
  const [carregando, setCarregando] = useState(true);
  const [erro, setErro] = useState<Error | null>(null);
  const repositorio = usePedidoRepository(); // injeção via contexto/DI

  useEffect(() => {
    let cancelado = false; // guarda contra atualização em componente desmontado

    repositorio
      .obterPedidos()
      .then((dados) => { if (!cancelado) setPedidos(dados); })
      .catch((e) => { if (!cancelado) setErro(e); })
      .finally(() => { if (!cancelado) setCarregando(false); });

    return () => { cancelado = true; }; // se o componente desmontar ou repositorio
  }, [repositorio]);                    // mudar antes da resposta, ignora o resultado

  return { pedidos, carregando, erro };
}
```

Leitura do código: o `useEffect` executa a busca quando o componente é exibido e sempre que `repositorio` muda (lista de dependências). A função devolvida pelo efeito é a **função de limpeza**, executada antes de o efeito ser reexecutado ou quando o componente é desmontado. Ao marcar `cancelado = true`, ela impede que uma resposta tardia altere o estado.

> **Por que a flag `cancelado` (ou um `AbortController`) não é opcional**: sem ela, se o componente desmontar (ou `repositorio` mudar) antes de a `Promise` resolver, o `.then`/`.catch` chama `setPedidos`/`setErro` em um componente que não existe mais. Trata-se de uma condição de corrida que o React sinaliza como aviso e que, em cenários mais complexos, pode causar atualização de estado incorreta (por exemplo, a resposta de uma requisição antiga sobrescrevendo a de uma mais recente). É a versão em React Native do princípio "o processo pode morrer ou mudar a qualquer momento" discutido para o Android nativo na Aula 2: aqui, o equivalente é o componente ser desmontado a qualquer momento. Em chamadas HTTP reais, recomenda-se encadear um `AbortController` e passar seu `signal` para `fetch`/`axios`, cancelando a requisição de fato, e não apenas ignorando o resultado.

O hook `usePedidos` desempenha, no React Native, papel equivalente ao do gerenciador de estado exposto por um `Provider`/`Riverpod` no Flutter (Aula 12). Ele é a fronteira entre o componente de apresentação (que apenas consome `{ pedidos, carregando, erro }`) e o domínio/dados (que o hook encapsula, delegando ao repositório, tema retomado na Aula 18).

> **Nota — o ecossistema abandonou esse padrão manual**: implementar `loading`, `error` e cache à mão com `useEffect`, como acima, é o que a comunidade React descreve como misturar **estado de servidor** (dados que vivem no backend e apenas são espelhados localmente) com **estado de cliente** (dados que só existem na interface, como um formulário em preenchimento). Bibliotecas de *server state*, como **TanStack Query** (ou SWR), resolvem loading, erro, cache e revalidação automaticamente (retomado na §2.1 e na Aula 18). Vale implementar manualmente uma vez, como acima, precisamente para compreender o problema que essas bibliotecas resolvem, mas esse não é o padrão recomendado para um projeto real em 2026.

## 2.1. Estado de cliente x estado de servidor

### Problema

Tratar todo dado da aplicação da mesma forma conduz a soluções inadequadas. Um dado obtido de uma API pode ficar desatualizado a qualquer momento, pode precisar de nova busca e pode falhar. Um campo de formulário em edição não tem nenhuma dessas características. Aplicar a mesma ferramenta aos dois produz código desnecessariamente complexo.

### Mecanismo

> **Definição — Estado de servidor (*server state*)**: dado cuja fonte de verdade vive fora do aplicativo (numa API, num banco remoto), que o app apenas espelha localmente, sujeito a ficar desatualizado, a precisar de revalidação, cache e nova tentativa — em oposição ao **estado de cliente** (*client state*), dado que só existe na interface e não tem contraparte remota (ex.: texto de um formulário em edição, aba selecionada).

O critério de classificação é a pergunta: **"quem é o dono do dado?"**. Se o dono é o servidor, o dado é estado de servidor, e o aplicativo mantém apenas uma cópia que precisa ser mantida atualizada. Se o dono é a própria interface, é estado de cliente.

`usePedidos` na §2 é *server state*, e é exatamente por isso que reimplementá-lo à mão com `useState`/`useEffect` significa reconstruir manualmente loading, erro, cache e revalidação que uma biblioteca de *server state* já resolve. O **TanStack Query** (sucessor do React Query) é a referência do ecossistema para isso.

### Aplicação

```tsx
function usePedidos() {
  return useQuery({
    queryKey: ['pedidos'],
    queryFn: () => pedidoRepository.obterPedidos(),
  });
}

// No componente:
const { data: pedidos, isLoading, error } = usePedidos();
```

Leitura do código: `queryKey` identifica o dado no cache (duas telas que usam a mesma chave compartilham o resultado, sem requisições duplicadas), e `queryFn` é a função que o obtém. Em poucas linhas, `useQuery` cobre cache, revalidação em segundo plano, nova tentativa com backoff e persistência offline (com o plugin de persistência), o mesmo conjunto de responsabilidades implementado manualmente na §2, agora comparável lado a lado.

**Context, Redux e Zustand continuam sendo a ferramenta adequada para *client state*** (carrinho em edição, tema, sessão). A distinção entre estado de cliente e de servidor, e não a questão "qual biblioteca é melhor", é o critério organizador desta aula. Se o projeto já utiliza Redux Toolkit, o complemento **RTK Query** resolve o mesmo problema de *server state* sem introduzir nova dependência.

## 3. Gerenciamento de estado: Context, Redux e Zustand

### Problema

Retomando a Aula 12: o estado local (`useState`) é suficiente para um componente, mas insuficiente quando o dado é compartilhado entre componentes distantes na árvore (por exemplo, o carrinho, usado no catálogo e no checkout). Repassar o dado manualmente por todos os componentes intermediários (*prop drilling*) acopla componentes que não o utilizam.

### Context API

Mecanismo nativo do React para compartilhar dados entre componentes sem passar propriedades manualmente por cada nível da árvore. É adequado para estado que muda com pouca frequência (tema, dados de sessão do usuário autenticado).

**Limitação estrutural.** O Context **não faz** *bailout* seletivo de re-renderização: qualquer mudança no `value` do provider re-renderiza **todos** os componentes que o consomem, mesmo aqueles que leem apenas uma parte do objeto que não mudou. Usar Context para estado que muda a cada interação (por exemplo, o texto digitado em tempo real) pode, portanto, causar reconstruções desnecessárias em todos os consumidores. É essa limitação, e não a frequência de mudança isoladamente, que explica por que o Context é uma escolha pobre para estado que muda rápido, e por que a Aula 22 recomenda observação seletiva em bibliotecas dedicadas.

```tsx
const CarrinhoContext = createContext<CarrinhoContextType | null>(null);

function CarrinhoProvider({ children }: { children: React.ReactNode }) {
  const [itens, setItens] = useState<Item[]>([]);
  const adicionar = (item: Item) => setItens((atual) => [...atual, item]);

  return (
    <CarrinhoContext.Provider value={{ itens, adicionar }}>
      {children}
    </CarrinhoContext.Provider>
  );
}

// Hook de acesso: lança erro descritivo se usado fora do provider, em vez de
// silenciar o problema com "!" (non-null assertion), que descarta a segurança
// de tipo do TypeScript exatamente no ponto em que ela mais importa.
function useCarrinho() {
  const contexto = useContext(CarrinhoContext);
  if (!contexto) {
    throw new Error('useCarrinho deve ser usado dentro de um CarrinhoProvider');
  }
  return contexto;
}

// Em qualquer componente descendente:
const { itens, adicionar } = useCarrinho();
```

Funcionamento: o `CarrinhoProvider` mantém o estado e o publica por meio do `value`. A atualização `[...atual, item]` cria uma nova lista em vez de alterar a existente, o que é necessário para o React detectar a mudança. O hook `useCarrinho` encapsula o acesso e converte o uso fora do provider em um erro explícito, em vez de um `null` silencioso.

### Redux (com Redux Toolkit)

Biblioteca que centraliza todo o estado da aplicação em uma única árvore imutável (*store*), atualizada exclusivamente por meio de ações despachadas e processadas por funções puras (*reducers*). O modelo é previsível e rastreável, com ferramentas maduras de depuração (Redux DevTools), mas historicamente mais verboso. O Redux Toolkit reduz essa verbosidade com convenções padronizadas.

```tsx
const carrinhoSlice = createSlice({
  name: 'carrinho',
  initialState: { itens: [] as Item[] },
  reducers: {
    itemAdicionado: (state, action: PayloadAction<Item>) => {
      state.itens.push(action.payload); // Redux Toolkit permite mutação "aparente" via Immer
    },
  },
});

// Em um componente:
const itens = useSelector((state: RootState) => state.carrinho.itens);
const dispatch = useDispatch();
dispatch(itemAdicionado(novoItem));
```

Funcionamento: o componente não altera o estado diretamente; **despacha uma ação** (`itemAdicionado`) que descreve o que ocorreu. O reducer calcula o novo estado a partir do anterior e da ação. A biblioteca Immer, embutida no Redux Toolkit, permite escrever `push` de forma aparentemente mutável, mas produz internamente uma nova cópia imutável. O `useSelector` inscreve o componente apenas na fatia do estado que ele lê (`state.carrinho.itens`), o que evita o problema de re-renderização do Context.

### Zustand

Biblioteca minimalista que expõe estado global por meio de um hook simples, sem a estrutura formal de ações e reducers do Redux nem a necessidade de envolver a árvore em um `Provider`. É atrativa para equipes que consideram o Redux excessivamente burocrático para o tamanho do projeto.

```tsx
const useCarrinhoStore = create<CarrinhoState>((set) => ({
  itens: [],
  adicionar: (item) => set((state) => ({ itens: [...state.itens, item] })),
}));

// Em qualquer componente, sem Provider:
const itens = useCarrinhoStore((state) => state.itens);
const adicionar = useCarrinhoStore((state) => state.adicionar);
```

Funcionamento: o estado e as ações que o alteram ficam na mesma definição. O argumento passado ao hook (`(state) => state.itens`) é um **seletor**: o componente é re-renderizado apenas quando o valor selecionado muda, o que oferece a observação seletiva ausente no Context.

### Critério de escolha

| Solução | Quando escolher |
|---|---|
| Context | Estado de baixa frequência de mudança, sem necessidade de ferramentas de depuração avançadas |
| Redux (+ RTK Query, se já em uso) | Aplicações grandes, equipes que valorizam rastreabilidade explícita e ferramentas de depuração maduras |
| Zustand | Projetos que buscam simplicidade de API sem abrir mão de estado global compartilhado |
| TanStack Query (ou SWR) | Sempre que o dado é *server state* (ver §2.1), combinável com qualquer uma das três acima para o *client state* restante |

Esta tabela é estruturalmente paralela à da Aula 12 (Provider/Riverpod/BLoC). O critério de decisão (tamanho do projeto, necessidade de rastreabilidade, preferência por simplicidade ou rigor estrutural) é o mesmo raciocínio arquitetural aplicado a dois ecossistemas distintos, o que reforça o argumento comparativo central deste componente.

## 4. Onde o gerenciador de estado se encaixa na arquitetura

Assim como discutido para o Flutter na Aula 12, o gerenciador de estado (Context, Redux ou Zustand) ocupa a fronteira entre apresentação e domínio. A regra de negócio (por exemplo, "um item só pode ser adicionado ao carrinho se houver estoque") não deve residir dentro do reducer do Redux ou da store do Zustand, acoplada à interface. Deve residir em uma função de domínio, testável isoladamente, chamada a partir da ação ou da store.

A justificativa é a mesma da Aula 12: se a regra residir no reducer, a migração entre Redux e Zustand (comum, conforme a §5) obrigaria reescrever também a regra de negócio, que não tem relação com a tecnologia de estado.

```tsx
// Domínio, sem dependência de React ou de qualquer gerenciador de estado
export function podeAdicionarAoCarrinho(item: Item, estoque: number): boolean {
  return estoque > 0 && item.disponivel;
}
```

## 5. Exemplo real: por que times pequenos migram de Redux para Zustand

Um padrão observado em relatos de equipes de produto: projetos React Native iniciados com Redux (por ser historicamente a opção mais conhecida) frequentemente migram, parcial ou totalmente, para Zustand ou Context quando a equipe percebe que a maior parte do código repetitivo do Redux (ações, reducers e seletores para operações simples) não se justifica em projetos de porte pequeno a médio.

O Redux é mantido apenas em domínios com fluxos de estado genuinamente complexos, nos quais o rigor estrutural compensa a verbosidade. Trata-se, novamente, de uma decisão arquitetural a ser justificada por características do projeto, e não por preferência isolada da equipe.

## 6. O motivo prático de isolar o domínio: um teste em poucas linhas

### Problema

Como na Aula 12, o benefício de isolar o domínio precisa ser demonstrado. Se a regra depende de componentes ou de um gerenciador de estado, testá-la exige montar a árvore de componentes e simular hooks, o que é lento e frágil.

### Mecanismo e aplicação

Uma função de domínio pura, sem dependência de React ou de qualquer gerenciador de estado, é testável sem montar nenhum componente:

```tsx
// pedidos/dominio/podeAdicionarAoCarrinho.ts — já apresentada na §4
export function podeAdicionarAoCarrinho(item: Item, estoque: number): boolean {
  return estoque > 0 && item.disponivel;
}

// pedidos/dominio/podeAdicionarAoCarrinho.test.ts — roda em milissegundos, com Vitest/Jest
test('item sem estoque não pode ser adicionado', () => {
  expect(podeAdicionarAoCarrinho({ disponivel: true } as Item, 0)).toBe(false);
});
```

O teste chama a função com uma entrada conhecida e compara a saída com o valor esperado. Ele não precisa de emulador, de `render()` de componente nem de simulação de hooks. É o retorno concreto de manter a regra de negócio fora do reducer ou da store, discutido na §4.

## Síntese da aula

| Camada | Não deve conter |
|---|---|
| Apresentação (componentes) | Lógica de negócio, chamadas de rede diretas |
| Domínio | Referência a hooks de estado ou componentes React |
| Dados | Regra de negócio (apenas obtenção/persistência) |

| Conceito | Problema que resolve |
|---|---|
| Hook customizado | Lógica de estado e efeitos misturada ao componente visual |
| Função de limpeza do `useEffect` | Atualização de estado em componente desmontado |
| Estado de servidor x de cliente | Uso da mesma ferramenta para dados de natureza diferente |
| Context / Redux / Zustand | Compartilhamento de estado de cliente entre componentes distantes |
| TanStack Query | Reimplementação manual de loading, erro, cache e revalidação |
| Domínio isolado | Testes lentos que dependem de componentes e simulação de hooks |

## Leitura recomendada

- Documentação oficial: [Passing Data Deeply with Context](https://react.dev/learn/passing-data-deeply-with-context), [Redux Toolkit](https://redux-toolkit.js.org/), [Zustand](https://github.com/pmndrs/zustand) e [TanStack Query](https://tanstack.com/query/latest).
