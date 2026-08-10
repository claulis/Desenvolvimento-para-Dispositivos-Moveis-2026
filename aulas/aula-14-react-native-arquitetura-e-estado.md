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
    repositorio
      .obterPedidos()
      .then(setPedidos)
      .catch(setErro)
      .finally(() => setCarregando(false));
  }, [repositorio]);

  return { pedidos, carregando, erro };
}
```

O hook customizado `usePedidos` desempenha, no React Native, um papel equivalente ao gerenciador de estado exposto por um `Provider`/`Riverpod` no Flutter (Aula 10): é a fronteira entre o componente de apresentação (que apenas consome `{ pedidos, carregando, erro }`) e o domínio/dados (que o hook encapsula, delegando ao repositório, tema retomado na Aula 15).

## 3. Gerenciamento de estado: Context, Redux e Zustand

### Context API

Mecanismo nativo do React para compartilhar dados entre componentes sem passar propriedades manualmente por cada nível da árvore (*prop drilling*). Adequado para estado que muda com pouca frequência (tema, dados de sessão do usuário autenticado) — usar Context para estado que muda a cada interação (ex.: texto digitado em tempo real) pode causar reconstruções desnecessárias em toda a árvore de consumidores.

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

// Em qualquer componente descendente:
const { itens, adicionar } = useContext(CarrinhoContext)!;
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
| Redux | Aplicações grandes, equipes que valorizam rastreabilidade explícita e ferramentas de depuração maduras |
| Zustand | Projetos que querem simplicidade de API sem abrir mão de estado global compartilhado |

Essa tabela é estruturalmente paralela à da Aula 10 (Provider/Riverpod/BLoC) — o critério de decisão (tamanho do projeto, necessidade de rastreabilidade, preferência por simplicidade x rigor estrutural) é o mesmo raciocínio arquitetural aplicado a dois ecossistemas distintos, reforçando o argumento comparativo central deste componente.

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

## Síntese da aula

| Camada | Não deve conter |
|---|---|
| Apresentação (componentes) | Lógica de negócio, chamadas de rede diretas |
| Domínio | Referência a hooks de estado ou componentes React |
| Dados | Regra de negócio (apenas obtenção/persistência) |

## Leitura recomendada

- Documentação oficial: [Passing Data Deeply with Context](https://react.dev/learn/passing-data-deeply-with-context), [Redux Toolkit](https://redux-toolkit.js.org/) e [Zustand](https://github.com/pmndrs/zustand).

## Atividade da aula

**Estudo de caso: identificação de violações de camada em código React Native e reorganização do módulo**: a partir de um trecho de código fornecido (contendo chamada de rede, regra de validação e JSX misturados em um único componente), identificar cada violação e reescrever o módulo separando apresentação, domínio e dados, adotando um dos três gerenciadores de estado apresentados, com justificativa da escolha.
