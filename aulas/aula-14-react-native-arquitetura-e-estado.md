# Aula 14 — React Native: arquitetura em camadas e gerenciamento de estado

**Carga horária:** 4h
**Unidade:** IV — Arquitetura de software em React Native

## Objetivos da aula

- Estruturar uma aplicação React Native em camadas de apresentação, domínio e dados.
- Explicar o papel dos hooks na separação entre estado e interface.
- Comparar Context, Redux e Zustand como soluções de gerenciamento de estado.

## 1. Arquitetura em camadas em React Native

Os mesmos princípios de arquitetura em camadas estudados na Aula 10 para Flutter se aplicam integralmente a React Native — a separação entre apresentação, domínio e dados é uma decisão de arquitetura de software, independente do framework de interface escolhido. O que muda é a sintaxe e as ferramentas disponíveis em cada ecossistema.

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

```tsx
// Correto: componente delega ao domínio/dados via um hook customizado
function TelaPedidos() {
  const { pedidos, carregando, erro } = usePedidos(); // hook encapsula a lógica

  if (carregando) return <IndicadorDeCarregamento />;
  if (erro) return <MensagemDeErro erro={erro} />;
  return <ListaDePedidos pedidos={pedidos} />;
}
```

## 2. O papel dos hooks customizados na separação de camadas

> **Definição — Hook customizado**: função JavaScript/TypeScript, com nome prefixado por `use`, que encapsula lógica reutilizável de estado e efeitos colaterais, podendo internamente chamar outros hooks (`useState`, `useEffect`, hooks de terceiros) — o mecanismo central pelo qual React e React Native permitem extrair lógica de fora do componente visual sem recorrer a classes ou herança.

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

> **Por que a flag `cancelado`/`AbortController` não é opcional**: sem ela, se o componente desmontar (ou `repositorio` mudar) antes da `Promise` resolver, o `.then`/`.catch` chama `setPedidos`/`setErro` em um componente que não existe mais — uma condição de corrida que o React sinaliza como aviso e que, em cenários mais complexos, pode causar atualização de estado incorreta. É a versão em React Native do princípio "o processo pode morrer/mudar a qualquer momento" já discutido para o Android nativo na Aula 2 — aqui, o equivalente é o componente ser desmontado a qualquer momento. Em chamadas HTTP reais, prefira encadear um `AbortController` e passar seu `signal` para `fetch`/`axios`, cancelando a requisição de fato, não apenas ignorando seu resultado.

O hook customizado `usePedidos` desempenha, no React Native, um papel equivalente ao gerenciador de estado exposto por um `Provider`/`Riverpod` no Flutter (Aula 10): é a fronteira entre o componente de apresentação (que apenas consome `{ pedidos, carregando, erro }`) e o domínio/dados (que o hook encapsula, delegando ao repositório, tema retomado na Aula 15).

> **Nota — o ecossistema abandonou esse padrão manual**: implementar `loading`/`error`/cache à mão com `useEffect`, como acima, é exatamente o que a comunidade React chama de misturar **estado de servidor** (dados que vivem no backend e apenas são espelhados localmente) com **estado de cliente** (dados que só existem na interface, como um formulário sendo preenchido). Bibliotecas de *server state* como **TanStack Query** (ou SWR) resolvem loading/error/cache/revalidação automaticamente — retomado na §3 desta aula e na Aula 15. Vale implementar manualmente uma vez, como acima, precisamente para entender o problema que essas bibliotecas resolvem — mas não é o padrão recomendado para um projeto real em 2026.

## 3. Gerenciamento de estado: Context, Redux e Zustand

### Context API

Mecanismo nativo do React para compartilhar dados entre componentes sem passar propriedades manualmente por cada nível da árvore (*prop drilling*). Adequado para estado que muda com pouca frequência (tema, dados de sessão do usuário autenticado) — usar Context para estado que muda a cada interação (ex.: texto digitado em tempo real) pode causar reconstruções desnecessárias em toda a árvore de consumidores. E isso vale mesmo para mudanças pouco frequentes, por um motivo estrutural: o Context **não faz** *bailout* seletivo de re-renderização — qualquer mudança no `value` do provider re-renderiza **todos** os componentes que o consomem, mesmo os que leem apenas uma parte do objeto que não mudou. É essa limitação (não a frequência de mudança isoladamente) que explica por que Context é uma escolha pobre para estado que muda rápido, e por que a Aula 19 recomenda `Selector`/observação seletiva em bibliotecas dedicadas.

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

### Redux (com Redux Toolkit)

Biblioteca que centraliza todo o estado da aplicação em uma única árvore imutável (*store*), atualizada exclusivamente por meio de ações despachadas e processadas por funções puras (*reducers*) — um modelo previsível e rastreável, com ferramentas maduras de depuração (Redux DevTools), mas historicamente mais verboso; o Redux Toolkit reduz essa verbosidade com convenções padronizadas.

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

### Zustand

Biblioteca minimalista que expõe estado global por meio de um hook simples, sem a estrutura formal de ações/reducers do Redux nem a necessidade de envolver a árvore em um `Provider` — atrativa para equipes que consideram o Redux excessivamente burocrático para o tamanho do projeto.

```tsx
const useCarrinhoStore = create<CarrinhoState>((set) => ({
  itens: [],
  adicionar: (item) => set((state) => ({ itens: [...state.itens, item] })),
}));

// Em qualquer componente, sem Provider:
const itens = useCarrinhoStore((state) => state.itens);
const adicionar = useCarrinhoStore((state) => state.adicionar);
```

### Critério de escolha

| Solução | Quando escolher |
|---|---|
| Context | Estado de baixa frequência de mudança, sem necessidade de ferramentas de depuração avançadas |
| Redux (+ RTK Query, se já em uso) | Aplicações grandes, equipes que valorizam rastreabilidade explícita e ferramentas de depuração maduras |
| Zustand | Projetos que querem simplicidade de API sem abrir mão de estado global compartilhado |
| TanStack Query (ou SWR) | Sempre que o dado é *server state* (ver §2.1) — combinável com qualquer uma das três acima para o *client state* restante |

Essa tabela é estruturalmente paralela à da Aula 10 (Provider/Riverpod/BLoC) — o critério de decisão (tamanho do projeto, necessidade de rastreabilidade, preferência por simplicidade x rigor estrutural) é o mesmo raciocínio arquitetural aplicado a dois ecossistemas distintos, reforçando o argumento comparativo central deste componente.

## 2.1. Estado de cliente x estado de servidor

> **Definição — Estado de servidor (*server state*)**: dado cuja fonte de verdade vive fora do aplicativo (numa API, num banco remoto), que o app apenas espelha localmente, sujeito a ficar desatualizado, a precisar de revalidação, cache e nova tentativa — em oposição ao **estado de cliente** (*client state*), dado que só existe na interface e não tem contraparte remota (ex.: texto de um formulário em edição, aba selecionada).

`usePedidos` na §2 é *server state* — e é exatamente por isso que reimplementá-lo à mão com `useState`/`useEffect` significa reconstruir, manualmente, loading/erro/cache/revalidação que uma biblioteca de *server state* já resolve. **TanStack Query** (sucessora do React Query) é a referência do ecossistema para isso:

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

Em poucas linhas, `useQuery` cobre cache, revalidação em segundo plano, nova tentativa com backoff e persistência offline (com o plugin de persistência) — o mesmo conjunto de responsabilidades manuais implementado na §2, agora comparável lado a lado com o que foi escrito à mão. **Context, Redux e Zustand continuam sendo a ferramenta certa para *client state*** (carrinho em edição, tema, sessão) — a distinção client/server state, não "qual biblioteca é melhor", é o critério organizador desta aula. Se o projeto já usa Redux Toolkit, o complemento **RTK Query** resolve o mesmo problema de *server state* sem introduzir uma dependência nova.

## 4. Onde o gerenciador de estado se encaixa na arquitetura

Assim como discutido para o Flutter na Aula 10: o gerenciador de estado (Context, Redux ou Zustand) ocupa a fronteira entre apresentação e domínio. A regra de negócio (ex.: "um item só pode ser adicionado ao carrinho se houver estoque") não deve residir dentro do reducer do Redux ou da store do Zustand de forma acoplada à interface — deve residir em uma função de domínio testável isoladamente, chamada a partir da ação/store.

```tsx
// Domínio, sem dependência de React ou de qualquer gerenciador de estado
export function podeAdicionarAoCarrinho(item: Item, estoque: number): boolean {
  return estoque > 0 && item.disponivel;
}
```

## 5. Exemplo real: por que times pequenos migram de Redux para Zustand

Um padrão observado em relatos de equipes de produto: projetos React Native iniciados com Redux (por ser historicamente a opção mais conhecida) frequentemente migram parcial ou totalmente para Zustand ou Context quando a equipe percebe que a maior parte do "boilerplate" do Redux (actions, reducers, seletores para operações simples) não se paga em projetos de porte pequeno a médio — mantendo Redux apenas em domínios com fluxos de estado genuinamente complexos, onde o rigor estrutural compensa a verbosidade. Essa é, novamente, uma decisão arquitetural a ser justificada por características do projeto, não por preferência isolada da equipe.

## 6. O motivo prático de isolar o domínio: um teste em três linhas

Assim como na Aula 10 para Flutter: uma função de domínio pura, sem dependência de React ou de qualquer gerenciador de estado, é testável sem montar nenhum componente:

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

Esse teste não precisa de emulador, de `render()` de componente, nem de mock de hooks — é o retorno concreto de manter a regra de negócio fora do reducer/store, discutido na §4.

## Síntese da aula

| Camada | Não deve conter |
|---|---|
| Apresentação (componentes) | Lógica de negócio, chamadas de rede diretas |
| Domínio | Referência a hooks de estado ou componentes React |
| Dados | Regra de negócio (apenas obtenção/persistência) |

## Leitura recomendada

- Documentação oficial: [Passing Data Deeply with Context](https://react.dev/learn/passing-data-deeply-with-context), [Redux Toolkit](https://redux-toolkit.js.org/), [Zustand](https://github.com/pmndrs/zustand) e [TanStack Query](https://tanstack.com/query/latest).

## Atividade da aula

**Estudo de caso: identificação de violações de camada em código React Native e reorganização do módulo**: a partir de um trecho de código fornecido (contendo chamada de rede, regra de validação e JSX misturados em um único componente), identificar cada violação e reescrever o módulo separando apresentação, domínio e dados, adotando um dos três gerenciadores de estado apresentados, com justificativa da escolha.
