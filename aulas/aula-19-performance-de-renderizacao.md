# Aula 19 — Arquitetura da camada de apresentação e desempenho de renderização

**Carga horária:** 4h
**Unidade:** V — Estilos arquiteturais, renderização e análise comparativa

## Objetivos da aula

- Explicar reconstrução de subárvore no Flutter e reconciliação no React Native.
- Aplicar memoização, chaves de identidade e listas virtualizadas para reduzir custo de renderização.
- Medir o custo de renderização de uma lista longa e refatorar a composição em ambas as implementações.

## 1. Por que desempenho de renderização é uma questão de arquitetura, não de otimização tardia

Retomando a Aula 1: o smartphone tem CPU/GPU limitadas e sem ventoinha — renderizar mais do que o necessário a cada interação não é apenas "menos eficiente", é uma decisão que se manifesta como travamento visível (*jank*) percebido diretamente pelo usuário. Diferente de otimizações de backend, que muitas vezes são invisíveis ao usuário final, um problema de desempenho de renderização em mobile é imediatamente visível como uma interface que "engasga" ao rolar ou animar — motivo pelo qual a arquitetura da camada de apresentação, e não apenas o algoritmo de negócio, é tratada como preocupação central nesta aula.

> **Definição — Jank**: percepção visual de travamento ou engasgo na interface, causada quando um quadro (frame) leva mais tempo que o orçamento disponível (tipicamente ~16ms para 60 quadros por segundo) para ser calculado e desenhado.

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

A técnica mais eficaz para reduzir o custo de reconstrução é **extrair widgets** para que o escopo de `setState()` seja o menor possível, movendo o estado para o nível mais baixo da árvore onde ele é efetivamente necessário:

```dart
// Eficiente: o estado de "favoritado" vive dentro do próprio CardProduto,
// então alternar um favorito só reconstrói aquele card específico
class CardProduto extends StatefulWidget {
  final Produto produto;
  const CardProduto({required this.produto, super.key});

  @override
  State<CardProduto> createState() => _CardProdutoState();
}

class _CardProdutoState extends State<CardProduto> {
  bool favoritado = false;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(widget.produto.nome),
      trailing: IconButton(
        icon: Icon(favoritado ? Icons.favorite : Icons.favorite_border),
        onPressed: () => setState(() => favoritado = !favoritado),
      ),
    );
  }
}
```

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

No Flutter, o equivalente conceitual a "memoização de renderização" é justamente a extração de widget filho `const` sempre que possível — widgets `const` são construídos uma única vez e reaproveitados pela própria linguagem Dart, sem custo algum de reconstrução.

## 5. Chaves de identidade (keys)

> **Definição — Chave de identidade (key)**: identificador único associado a um elemento de uma lista dinâmica, usado pelo algoritmo de reconciliação (React/React Native) ou pelo Flutter (`Key`/`ValueKey`) para determinar se um elemento em uma nova renderização é "o mesmo" elemento de antes (apenas reordenado ou atualizado) ou um elemento genuinamente novo — crítico para preservar estado interno e evitar re-renderização/reconstrução completa de listas.

```tsx
// Errado: usar o índice como chave é enganoso quando a lista é reordenada
{produtos.map((produto, index) => <CardProduto key={index} produto={produto} />)}

// Correto: chave estável, baseada no identificador real do dado
{produtos.map((produto) => <CardProduto key={produto.id} produto={produto} />)}
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

Um padrão de bug de desempenho relatado com frequência em aplicativos de feed de conteúdo (redes sociais, marketplaces): a rolagem fica "engasgada" (baixa taxa de quadros) especificamente ao curtir/favoritar um item no meio de uma lista longa. A causa raiz, tanto em Flutter quanto em React Native, costuma ser a mesma: o estado de "curtido" é mantido no componente pai da lista inteira (não no item individual), fazendo com que a interação com **um** item dispare a reconstrução/re-renderização de **todos** os itens visíveis simultaneamente. A correção — mover o estado de "curtido" para o próprio componente de item, como demonstrado nas seções 2 e 3 desta aula — é o mesmo princípio arquitetural aplicado nas duas plataformas, reforçando que o problema de desempenho de renderização é conceitual, não específico de framework.

## Síntese da aula

| Conceito Flutter | Conceito React Native | Efeito |
|---|---|---|
| Escopo de `setState()` | `React.memo` + `useCallback` | Limita o que é reconstruído/re-renderizado |
| Widget `const` | Memoização de valores (`useMemo`) | Evita recomputação redundante |
| `ValueKey` | `key` | Preserva identidade e estado de itens em listas |
| `ListView.builder` | `FlatList`/`FlashList` | Renderiza apenas itens visíveis (virtualização) |

## Leitura recomendada

- Documentação oficial: [Flutter performance best practices](https://docs.flutter.dev/perf/best-practices) e [React Native - Optimizing FlatList](https://reactnative.dev/docs/optimizing-flatlist-configuration).

## Atividade da aula

**Prática: medição do custo de renderização de uma lista longa e refatoração da composição nas duas implementações**: usando o *Flutter DevTools* (aba de performance) e o *React DevTools Profiler* (ou Flipper), medir o tempo de reconstrução/re-renderização ao interagir com um item de uma lista de pelo menos 200 elementos nas duas implementações do módulo do curso, identificar reconstruções/re-renderizações desnecessárias, e refatorar aplicando as técnicas desta aula, registrando a métrica antes e depois da correção.
