# Aula 19 — Arquitetura da camada de apresentação e desempenho de renderização

**Carga horária:** 4h
**Unidade:** V — Estilos arquiteturais, renderização e análise comparativa

## Objetivos da aula

- Explicar reconstrução de subárvore no Flutter e reconciliação no React Native.
- Aplicar memoização, chaves de identidade e listas virtualizadas para reduzir custo de renderização.
- Medir o custo de renderização de uma lista longa e refatorar a composição em ambas as implementações.

## 1. Por que desempenho de renderização é uma questão de arquitetura, não de otimização tardia

Retomando a Aula 1: o smartphone tem CPU/GPU limitadas e sem ventoinha — renderizar mais do que o necessário a cada interação não é apenas "menos eficiente", é uma decisão que se manifesta como travamento visível (*jank*) percebido diretamente pelo usuário. Diferente de otimizações de backend, que muitas vezes são invisíveis ao usuário final, um problema de desempenho de renderização em mobile é imediatamente visível como uma interface que "engasga" ao rolar ou animar — motivo pelo qual a arquitetura da camada de apresentação, e não apenas o algoritmo de negócio, é tratada como preocupação central nesta aula.

> **Definição — Jank**: percepção visual de travamento ou engasgo na interface, causada quando um quadro (frame) leva mais tempo que o orçamento disponível para ser calculado e desenhado. O valor de referência mais citado é ~16ms para 60 quadros por segundo — mas a maioria dos aparelhos Android relevantes hoje já roda a 90Hz ou 120Hz, o que reduz o orçamento real para **~11,1ms** ou **~8,3ms** por quadro. Isso não enfraquece o argumento desta aula, pelo contrário: o orçamento disponível para cada reconstrução/re-renderização encolheu, tornando o desperdício de trabalho ainda mais visível ao usuário do que era há poucos anos.

## 2. Reconstrução de subárvore no Flutter

Retomando a Aula 9: quando `setState()` é chamado dentro de um `State`, o Flutter reconstrói (chama `build()` novamente) o widget correspondente **e toda a sua subárvore de widgets filhos**, por padrão — mesmo que apenas uma pequena parte visual precise mudar.

```dart
// Ineficiente: setState no topo reconstrói toda a lista de produtos
// a cada favoritar, mesmo que só um item tenha mudado visualmente
class TelaCatalogo extends StatefulWidget {
  @override
  State<TelaCatalogo> createState() => _TelaCatalogoState();
}

class _TelaCatalogoState extends State<TelaCatalogo> {
  Set<String> favoritos = {};

  void alternarFavorito(String id) {
    setState(() {
      favoritos.contains(id) ? favoritos.remove(id) : favoritos.add(id);
    }); // reconstrói TODA a árvore abaixo de TelaCatalogo
  }

  @override
  Widget build(BuildContext context) {
    return ListView(children: produtos.map((p) => CardProduto(
      produto: p,
      favoritado: favoritos.contains(p.id),
      onFavoritar: () => alternarFavorito(p.id),
    )).toList());
  }
}
```

O Flutter, no entanto, é inteligente o suficiente para **não redesenhar** widgets cuja configuração (parâmetros) não mudou entre uma reconstrução e outra — o custo real de `build()` sendo chamado novamente é geralmente pequeno se o próprio método `build()` for barato; o problema de desempenho surge quando `build()` contém cálculo pesado (ex.: filtrar uma lista grande) executado a cada reconstrução desnecessária.

### Escopo de reconstrução

A técnica mais eficaz para reduzir o custo de reconstrução é limitar o escopo de `setState()` ao menor trecho de árvore possível — mas **isso não significa mover o próprio dado para dentro do widget filho**. "Favoritado" é estado de domínio: pertence ao usuário, precisa persistir e sincronizar (Aula 11), não é um detalhe efêmero de apresentação. Movê-lo para dentro de `_CardProdutoState`, como uma versão anterior deste material chegou a sugerir, contraria diretamente a separação de camadas das Aulas 10 e 17 — e, pior, **não funciona**: dentro de um `ListView.builder`, ao rolar a lista para longe e voltar, o `State` do item é descartado e recriado, e o favorito marcado localmente simplesmente desaparece (ou, sem uma `Key` estável — §5 desta aula — pode reaparecer associado ao item errado).

A técnica correta é **escuta seletiva, não descida de estado**: a fonte da verdade continua no gerenciador de estado (Aula 10), e cada item da lista observa apenas a sua própria fatia daquele estado, de forma que alternar um favorito reconstrua unicamente o card correspondente:

```dart
// Eficiente: o estado de "favoritado" continua no domínio (favoritosProvider),
// mas cada CardProduto observa (ref.watch) só a fatia referente ao seu id —
// alternar um favorito reconstrói apenas aquele card, sem mover o dado
// para fora do lugar onde ele pertence.
class CardProduto extends ConsumerWidget {
  final Produto produto;
  const CardProduto({required this.produto, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritado = ref.watch(favoritoProvider(produto.id));

    return ListTile(
      title: Text(produto.nome),
      trailing: IconButton(
        icon: Icon(favoritado ? Icons.favorite : Icons.favorite_border),
        onPressed: () => ref.read(favoritosProvider.notifier).alternar(produto.id),
      ),
    );
  }
}
```

O mesmo princípio, com nomes diferentes por gerenciador de estado: `Selector`/`Consumer` com um seletor específico (Provider), `ref.watch(provider(id))` com um *family provider* (Riverpod, acima), ou `BlocSelector` (BLoC). Em todos os casos, a ideia é a mesma — observar a menor fatia de estado necessária, não duplicar o dado para fora do domínio.

## 3. Reconciliação no React Native (e React)

> **Definição — Reconciliação (reconciliation)**: algoritmo do React que compara a árvore de elementos produzida por uma nova renderização com a árvore anterior (usando uma estrutura em memória chamada *Virtual DOM*, ou sua equivalente para React Native), calculando o conjunto mínimo de mudanças reais necessárias na árvore de componentes nativos, em vez de recriar tudo do zero a cada renderização.

Diferente do Flutter, onde a preocupação central é o escopo de `setState()`, no React Native a preocupação central é **quando um componente é re-renderizado desnecessariamente**, mesmo que a reconciliação evite trabalho nativo redundante — o cálculo da nova árvore de elementos e sua comparação (`diffing`) ainda tem custo em JavaScript.

```tsx
// Ineficiente: alterar o estado de favoritos no componente pai
// re-renderiza (recalcula o JSX de) todos os CardProduto filhos
function TelaCatalogo() {
  const [favoritos, setFavoritos] = useState<Set<string>>(new Set());

  return (
    <FlatList
      data={produtos}
      renderItem={({ item }) => (
        <CardProduto
          produto={item}
          favoritado={favoritos.has(item.id)}
          onFavoritar={() => alternarFavorito(item.id)}
        />
      )}
    />
  );
}
```

## 4. Memoização

> **Definição — Memoização**: técnica que armazena o resultado de um cálculo (ou, no contexto de interface, o resultado de uma renderização) associado às entradas que o produziram, reaproveitando esse resultado quando as mesmas entradas se repetem, evitando recomputação desnecessária.

Em React Native, `React.memo` evita a re-renderização de um componente cujas propriedades não mudaram desde a última renderização:

```tsx
const CardProduto = React.memo(function CardProduto({ produto, favoritado, onFavoritar }: Props) {
  return (
    <Pressable onPress={onFavoritar}>
      <Text>{produto.nome}</Text>
      <Text>{favoritado ? '♥' : '♡'}</Text>
    </Pressable>
  );
});
```

> **Cuidado**: `React.memo` só evita a re-renderização se as *props* forem referencialmente estáveis — passar uma função `onFavoritar={() => alternarFavorito(item.id)}` inline recria uma nova função a cada renderização do pai, anulando o efeito de `React.memo`. A solução é envolver a função com `useCallback`, e valores derivados custosos com `useMemo`.

```tsx
const alternarFavorito = useCallback((id: string) => {
  setFavoritos((atual) => {
    const novo = new Set(atual);
    novo.has(id) ? novo.delete(id) : novo.add(id);
    return novo;
  });
}, []);
```

> **`React.memo` sozinho não basta dentro de `FlatList`**: mesmo com `useCallback` no manipulador, o `renderItem` inline do exemplo da §3 (`renderItem={({ item }) => <CardProduto .../>}`) recria a função de renderização a cada render do componente pai — anulando parte do efeito de memoização do item. Extraia `renderItem` como uma função nomeada e estável (com `useCallback`), não inline. Além disso, para listas realmente longas, as props de configuração da `FlatList` importam tanto quanto a memoização dos itens: `initialNumToRender` (quantos itens renderizar na primeira passada), `windowSize` (quantas "telas" de itens manter fora da área visível), `getItemLayout` (evita medir cada item dinamicamente, quando a altura é conhecida) e `removeClippedSubviews` (remove da árvore nativa itens fora da área visível no Android).

No Flutter, `const` resolve a alocação do widget em tempo de compilação — mas **não é o equivalente direto de `useMemo`**. Um widget `const` sempre foi barato de "reconstruir" (a mesma instância é reaproveitada), então declará-lo `const` não é, por si, uma técnica de memoização de *cálculo*. O equivalente real de `useMemo` — cachear o resultado de um **cálculo caro** para não repeti-lo a cada `build()` — é armazenar esse resultado fora do método `build()`: um campo do `State`, um `late final`, ou um provider derivado (`Provider`/`Riverpod`) que só recalcula quando sua entrada muda. A lição desta aula é que reconstruir `build()` em si raramente é caro — cálculo pesado *dentro* de `build()`, reexecutado a cada reconstrução, é o problema real.

## 5. Chaves de identidade (keys)

> **Definição — Chave de identidade (key)**: identificador único associado a um elemento de uma lista dinâmica, usado pelo algoritmo de reconciliação (React/React Native) ou pelo Flutter (`Key`/`ValueKey`) para determinar se um elemento em uma nova renderização é "o mesmo" elemento de antes (apenas reordenado ou atualizado) ou um elemento genuinamente novo — crítico para preservar estado interno e evitar re-renderização/reconstrução completa de listas.

```tsx
// Ao mapear manualmente um array em JSX (fora de FlatList), a prop é `key`:
// Errado: usar o índice como chave é enganoso quando a lista é reordenada
{produtos.map((produto, index) => <CardProduto key={index} produto={produto} />)}
// Correto: chave estável, baseada no identificador real do dado
{produtos.map((produto) => <CardProduto key={produto.id} produto={produto} />)}
```

```tsx
// Dentro de FlatList — o componente de lista recomendado neste componente,
// §6 — a chave NÃO é passada via prop `key`: FlatList usa `keyExtractor`,
// uma função dedicada, separada de `renderItem`.
<FlatList
  data={produtos}
  keyExtractor={(item) => item.id}
  renderItem={({ item }) => <CardProduto produto={item} />}
/>
```

```dart
// Flutter: ValueKey cumpre o mesmo papel
ListView.builder(
  itemBuilder: (context, index) => CardProduto(
    key: ValueKey(produtos[index].id),
    produto: produtos[index],
  ),
)
```

Usar o índice da lista como chave é um erro recorrente e sutil: ao remover ou reordenar um item, o React (ou o Flutter) pode associar incorretamente o estado interno de um item ao item errado, causando bugs visuais difíceis de depurar (ex.: o item errado aparece marcado como favorito após uma remoção).

## 6. Listas virtualizadas

> **Definição — Lista virtualizada**: componente de lista que renderiza apenas os itens atualmente visíveis na tela (mais uma pequena margem), reciclando os componentes visuais conforme o usuário rola, em vez de manter todos os itens da coleção renderizados simultaneamente na memória — retomando diretamente a restrição de memória discutida na Aula 1.

| Framework | Componente de lista virtualizada |
|---|---|
| Android nativo | `RecyclerView` |
| Flutter | `ListView.builder`, `SliverList` |
| React Native | `FlatList`, `FlashList` (biblioteca da comunidade, mais performática) |

Renderizar uma lista de milhares de produtos com um `ListView`/`Column` comum (que constrói todos os itens de uma vez) em vez de `ListView.builder`/`FlatList` (que constroem apenas o necessário) é uma das causas mais comuns e mais facilmente evitáveis de mau desempenho em telas de listagem mobile.

## 7. Exemplo real: rolagem engasgada em lista de feed

Um padrão de bug de desempenho relatado com frequência em aplicativos de feed de conteúdo (redes sociais, marketplaces): a rolagem fica "engasgada" (baixa taxa de quadros) especificamente ao curtir/favoritar um item no meio de uma lista longa. A causa raiz, tanto em Flutter quanto em React Native, costuma ser a mesma: o estado de "curtido" é observado de forma grosseira demais — o componente pai reconstrói/re-renderiza a lista inteira a cada interação com **um** item, em vez de cada item observar apenas a sua própria fatia de estado. A correção — escuta seletiva por item (`ref.watch(favoritoProvider(id))`/`Selector`/`BlocSelector` em Flutter, `React.memo` com `renderItem` estável e seletor por id em React Native), como demonstrado nas seções 2 e 3 — é o mesmo princípio arquitetural aplicado nas duas plataformas, reforçando que o problema de desempenho de renderização é conceitual, não específico de framework. O que **não** resolve o problema, e na verdade o piora, é mover o dado de "curtido" para fora do domínio e para dentro do estado local do item — como visto na §2, isso quebra ao rolar a lista e sai da arquitetura estabelecida nas Aulas 10 e 17.

## Síntese da aula

| Conceito Flutter | Conceito React Native | Efeito |
|---|---|---|
| Escopo de `setState()` | `React.memo` + `useCallback` | Limita o que é reconstruído/re-renderizado |
| Widget `const` | Memoização de valores (`useMemo`) | Evita recomputação redundante |
| `ValueKey` | `key` | Preserva identidade e estado de itens em listas |
| `ListView.builder` | `FlatList`/`FlashList` | Renderiza apenas itens visíveis (virtualização) |

## Ferramentas de medição

Medir em modo debug produz números artificialmente ruins e não deve ser usado para julgar desempenho — sempre meça em modo profile/release:

| Framework | Ferramenta | Como medir |
|---|---|---|
| Flutter | *Flutter DevTools* > aba **Performance** + *Widget Rebuild Profiler* | Rodar com `flutter run --profile` (nunca em modo debug, que tem overhead de desenvolvimento embutido) |
| React Native | *React DevTools Profiler* + *Hermes profiler* (`Settings > Enable Sampling Profiler` no menu de desenvolvedor) | O **Flipper foi descontinuado** pela equipe do React Native — não o recomende como ferramenta atual; use o React DevTools Profiler e o sampling profiler do próprio Hermes |

## Leitura recomendada

- Documentação oficial: [Flutter performance best practices](https://docs.flutter.dev/perf/best-practices) e [React Native - Optimizing FlatList](https://reactnative.dev/docs/optimizing-flatlist-configuration).

## Atividade da aula

**Prática: medição do custo de renderização de uma lista longa e refatoração da composição nas duas implementações**: usando as ferramentas de medição acima, medir o tempo de reconstrução/re-renderização ao interagir com um item de uma lista de pelo menos 200 elementos nas duas implementações do módulo do curso, identificar reconstruções/re-renderizações desnecessárias, e refatorar aplicando as técnicas desta aula, registrando a métrica antes e depois da correção. Ponto de partida com uma lista de 200+ produtos já semeada (versão lenta pronta, para focar a aula na medição e correção, não na montagem dos dados) em [`codigo/flutter/19-performance-lista/`](../codigo/flutter/19-performance-lista/) e [`codigo/react-native/19-performance-lista/`](../codigo/react-native/19-performance-lista/); registre as métricas em `MEDICOES.md` dentro de cada projeto.

Vale fechar a aula amarrando de volta à Aula 1: jank em um aparelho de entrada, sem ventoinha e com CPU/GPU limitadas, é exatamente onde a fragmentação de aparelhos (Aula 1) e a renderização (esta aula) se encontram — o mesmo argumento central do curso, agora com uma métrica concreta para sustentá-lo.
