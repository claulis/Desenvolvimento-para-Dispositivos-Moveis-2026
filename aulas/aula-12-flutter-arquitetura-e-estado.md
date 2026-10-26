# Aula 12 — Flutter: arquitetura em camadas e gerenciamento de estado

**Carga horária:** 4h
**Unidade:** III — Arquitetura de software em Flutter

## Objetivos da aula

- Estruturar uma aplicação Flutter em camadas de apresentação, domínio e dados.
- Identificar violações de camada em código Flutter existente.
- Comparar Provider, Riverpod e BLoC como soluções de gerenciamento de estado.

## Organização da aula

A aula trata de duas questões relacionadas. A primeira é **onde cada tipo de código deve residir** (arquitetura em camadas, §1, §2, §4 e §6). A segunda é **como os dados que alteram a interface são armazenados e propagados** (gerenciamento de estado, §3 e §5). Em cada tópico, o conteúdo segue a sequência: problema, mecanismo e aplicação. A justificativa de cada decisão arquitetural é parte do conteúdo avaliado, e não apenas a sua descrição.

## 1. Por que separar em camadas também em Flutter

### Problema

Um projeto Flutter pequeno pode, tecnicamente, concentrar toda a lógica (chamada de rede, regra de negócio e construção de widget) no método `build()` de um único `StatefulWidget`. A solução funciona em um protótipo descartável, mas não escala. Três situações revelam o problema:

- **Troca da fonte de dados** (substituir uma API por outra): exige alterar o código de todas as telas que acessam a rede diretamente.
- **Teste automatizado de regra de negócio**: só é possível se a regra puder ser executada sem instanciar widgets.
- **Reuso de lógica em outra tela**: exige extrair a lógica de dentro da árvore de widgets, com risco de regressão.

Em todos os casos, o custo decorre de uma única causa: responsabilidades distintas estão misturadas no mesmo lugar.

### Mecanismo

> **Definição — Arquitetura em camadas**: organização do código em grupos de responsabilidade com dependência unidirecional (tipicamente apresentação → domínio → dados), de modo que uma camada superior dependa apenas de camadas inferiores, nunca o contrário, permitindo que cada camada seja compreendida, testada e substituída de forma relativamente independente.

A **dependência unidirecional** é o elemento central da definição. Se a camada de dados não conhece a existência de widgets, ela pode ser alterada ou substituída sem qualquer impacto sobre a interface. Se o domínio não conhece detalhes de HTTP, pode ser testado isoladamente. Cada camada, portanto, delimita uma região do código que pode mudar por um único motivo.

| Camada | Responsabilidade | Exemplos no Flutter |
|---|---|---|
| Apresentação | Construir a interface e reagir a interação do usuário | Widgets, `build()`, gerenciadores de estado |
| Domínio | Regras de negócio independentes de framework | Classes de modelo, casos de uso, validações |
| Dados | Obter e persistir dados de fontes externas | Repositórios, clientes HTTP, banco local |

## 2. Padrão de apresentação e a árvore de widgets

### Problema

No Android nativo tradicional, padrões como MVP e MVVM surgiram para desacoplar a `Activity`/`Fragment` da lógica, pois a manipulação **imperativa** de views (por exemplo, `view.setText(...)`) incentivava o acúmulo de lógica nessas classes.

### Mecanismo

O Flutter já impõe uma separação parcial pela própria natureza declarativa do `build()`: o widget descreve **como a interface deve parecer dado o estado atual**, e não **como transicionar de um estado visual para outro**. Isso elimina uma classe inteira de erros (a interface fora de sincronia com os dados), mas não impede a mistura de camadas. Sem disciplina, é comum observar chamadas de rede diretamente em `initState()` ou em um `onPressed`, misturando apresentação e dados. Trata-se da violação de camada mais frequente em código Flutter de iniciantes.

### Aplicação

O primeiro exemplo apresenta a violação:

```dart
// Violação de camada: o widget conhece detalhes de rede e parsing
class TelaPedidosRuim extends StatefulWidget {
  @override
  State<TelaPedidosRuim> createState() => _EstadoRuim();
}

class _EstadoRuim extends State<TelaPedidosRuim> {
  List<dynamic> pedidos = [];

  @override
  void initState() {
    super.initState();
    http.get(Uri.parse('https://api.exemplo.com/pedidos')).then((resposta) {
      setState(() => pedidos = jsonDecode(resposta.body)); // rede + parsing + estado, tudo aqui
    });
  }
  // ...
}
```

Neste código, o widget conhece o endereço da API, o formato da resposta e o ciclo de vida do estado. Qualquer alteração em um desses aspectos exige modificar a tela, e a lógica não pode ser testada sem a árvore de widgets. Além disso, `List<dynamic>` abdica da verificação de tipos do Dart.

O segundo exemplo apresenta a versão corrigida:

```dart
// Correto: widget delega ao domínio/dados via um gerenciador de estado
@riverpod
Future<List<Pedido>> pedidos(PedidosRef ref) async {
  final repositorio = ref.watch(pedidoRepositoryProvider);
  return repositorio.obterPedidos(); // gerado como AsyncValue<List<Pedido>> abaixo
}

class TelaPedidos extends ConsumerWidget {
  const TelaPedidos({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pedidosAsync = ref.watch(pedidosProvider); // apresentação só consome
    return pedidosAsync.when(
      data: (pedidos) => ListaDePedidos(pedidos: pedidos),
      loading: () => const CircularProgressIndicator(),
      error: (erro, _) => MensagemDeErro(erro: erro),
    );
  }
}
```

Agora o widget apenas **consome** um valor tipado (`List<Pedido>`) e decide como exibi-lo. A obtenção dos dados está encapsulada no repositório (Aula 13), e o widget não sabe se a origem é uma API ou um banco local.

> **Definição — `AsyncValue`**: tipo do Riverpod que representa o resultado de uma operação assíncrona em um dos três estados mutuamente exclusivos — `data` (sucesso, com o valor), `loading` (em andamento) ou `error` (falha, com o erro) — e cujo método `.when(...)` obriga o código consumidor a tratar os três.

A obrigatoriedade de tratar os três casos não é acidental. São os mesmos três estados discutidos na Aula 4 (carregando, erro e conteúdo): o `AsyncValue` é a materialização, em tipo de dado, do princípio de que esses estados fazem parte do design da interface, e não constituem "detalhes de implementação" passíveis de esquecimento. Como o compilador exige os três ramos, o desenvolvedor não consegue omitir o tratamento de erro por descuido.

**Nota de comportamento**: por padrão, `.when(...)` evita "piscar" o indicador de carregamento durante uma revalidação (por exemplo, após `ref.invalidate(pedidosProvider)`). O caso `data` continua sendo chamado com o valor anterior, marcado internamente como `isRefreshing`, em vez de cair no caso `loading`. Se a interface precisar distinguir "carregando pela primeira vez" de "atualizando em segundo plano com dado antigo na tela", deve-se inspecionar `pedidosAsync.isRefreshing` dentro do caso `data`, em vez de assumir que todo `loading` corresponde à primeira carga.

## 3. Gerenciamento de estado: por que existe mais de uma solução

### Problema

> **Definição — Gerenciamento de estado**: conjunto de estratégias e ferramentas para armazenar, atualizar e propagar dados que afetam a interface ao longo do tempo, de forma que widgets distantes na árvore possam reagir a uma mesma fonte de verdade sem acoplamento direto entre si.

O Flutter, por si só, oferece apenas `setState()`. Esse mecanismo é suficiente para o estado **local** de um único widget, mas insuficiente para o estado **compartilhado** entre telas distantes. Considere o carrinho de compras: ele é alterado na tela de catálogo e exibido na tela de checkout, que estão em ramos diferentes da árvore. Sem uma ferramenta específica, o dado precisaria ser repassado manualmente por todos os widgets intermediários (*prop drilling*), o que acopla widgets que não utilizam o dado.

### Mecanismo comum

As soluções apresentadas a seguir compartilham a mesma ideia: o dado reside **fora** dos widgets que o exibem, em um objeto acessível a toda a árvore, e os widgets interessados **se inscrevem** para ser notificados quando ele mudar. A fonte única de verdade evita que duas telas exibam valores divergentes. As soluções diferem no modelo mental e no grau de rigor que impõem.

### Provider

Biblioteca que expõe objetos (tipicamente `ChangeNotifier`) para a árvore de widgets via `InheritedWidget`. Qualquer widget descendente pode escutar mudanças, e apenas a parte relevante da árvore é reconstruída.

```dart
class CarrinhoNotifier extends ChangeNotifier {
  final List<Item> _itens = [];
  List<Item> get itens => List.unmodifiable(_itens);

  void adicionar(Item item) {
    _itens.add(item);
    notifyListeners(); // avisa widgets que escutam
  }
}

// No widget:
final carrinho = context.watch<CarrinhoNotifier>();
```

Funcionamento: `notifyListeners()` avisa todos os widgets que chamaram `context.watch`, e eles são reconstruídos. O getter `itens` devolve uma lista não modificável para impedir que código externo altere o estado sem passar por `adicionar`, o que contornaria a notificação.

### Riverpod

Evolução do Provider, desacoplada da árvore de widgets (não depende de `BuildContext` para declarar providers), com verificação em tempo de compilação e melhor testabilidade. É considerada por parte da comunidade Flutter como sucessora natural do Provider em projetos novos.

```dart
// Riverpod 3, com geração de código (@riverpod) — a API recomendada atualmente.
// A classe legada StateNotifier/StateNotifierProvider foi desaconselhada
// pelo próprio autor do Riverpod desde a versão 2.6 (2024); não se recomenda
// adotá-la como padrão em projetos novos.
@riverpod
class Carrinho extends _$Carrinho {
  @override
  List<Item> build() => [];

  void adicionar(Item item) {
    state = [...state, item]; // reatribuição imutável, não mutação da lista
  }
}

// No widget:
final itens = ref.watch(carrinhoProvider);
ref.read(carrinhoProvider.notifier).adicionar(novoItem);
```

Funcionamento: o estado é imutável. Em vez de modificar a lista (`_itens.add`), cria-se uma **nova** lista (`[...state, item]`) e atribui-se a `state`. A atribuição de um novo objeto é o gatilho de notificação, e a comparação entre o valor anterior e o novo permite detectar a mudança de forma confiável. Distingue-se `ref.watch` (escuta e reconstrói o widget quando o valor muda) de `ref.read` (lê uma única vez, apropriado para disparar ações em callbacks).

> **Nota**: o exemplo acima é o motivo pelo qual `CarrinhoNotifier`, definido como `ChangeNotifier` na seção do Provider, **não** deve ser reaproveitado como argumento de tipo de um `StateNotifierProvider`. Trata-se de APIs de gerenciadores de estado distintos (o Provider usa `ChangeNotifier`; o Riverpod legado usava `StateNotifier`, uma classe diferente), e confundi-los é um erro de tipo, não de estilo.

### BLoC (Business Logic Component)

Padrão que modela o estado como um fluxo de **eventos** de entrada transformados em **estados** de saída, com uso explícito de `Stream`s do Dart. É mais verboso, porém impõe separação muito rígida entre a intenção do usuário (evento) e o resultado (estado), o que se mostra vantajoso em times grandes e em domínios com regras de transição de estado complexas.

```dart
class CarrinhoBloc extends Bloc<CarrinhoEvent, CarrinhoState> {
  CarrinhoBloc() : super(CarrinhoVazio()) {
    on<ItemAdicionado>((evento, emit) {
      final novaLista = [...state.itens, evento.item];
      emit(CarrinhoComItens(novaLista));
    });
  }
}
```

Funcionamento: a interface não altera o estado diretamente; ela **envia um evento** (`ItemAdicionado`). O BLoC processa o evento, calcula o novo estado e o **emite** (`emit`). Como todo estado é consequência de um evento nomeado, o histórico de eventos oferece rastreabilidade completa do que ocorreu na aplicação.

### Critério de escolha

| Solução | Quando escolher |
|---|---|
| Nenhuma (`setState` + `InheritedWidget`) | Estado verdadeiramente local ou compartilhado apenas por uma pequena subárvore. É a resposta mais comum na comunidade Flutter para o início de um projeto: inicia-se sem biblioteca e adota-se uma quando a dificuldade de compartilhar estado entre telas distantes aparecer de fato |
| Provider | Projetos pequenos ou médios, equipe já familiarizada, prioridade em simplicidade |
| Riverpod | Projetos que valorizam testabilidade e segurança em tempo de compilação, sem dependência de `BuildContext` |
| BLoC | Domínios com regras de transição de estado complexas, equipes grandes que valorizam rastreabilidade explícita de eventos |

Não existe "o melhor" isolado do contexto. A escolha é uma decisão arquitetural que deve ser **justificada** por critérios (tamanho do time, complexidade das transições, necessidade de testes), e não uma preferência estética. Esse é o tipo de argumento exigido na Avaliação 2 (Aula 14).

## 4. Onde o gerenciador de estado se encaixa na arquitetura em camadas

O gerenciador de estado escolhido (Provider, Riverpod ou BLoC) pertence à **fronteira entre apresentação e domínio**. Ele recebe do domínio dados já validados e prontos e expõe à apresentação um formato consumível para a reconstrução de widgets. A lógica de negócio em si (por exemplo, "um pedido só pode ser cancelado se ainda não foi enviado") deve residir no domínio, de modo que seja testável independentemente de qualquer widget ou gerenciador de estado.

A razão é a mesma da §1: se a regra residir no gerenciador de estado, a troca de Provider por Riverpod (migração comum, conforme a §5) obrigaria reescrever também a regra de negócio, que não tem relação com a tecnologia de estado.

## 5. Exemplo real: por que aplicativos Flutter de médio porte migram de Provider para Riverpod ou BLoC

É comum, em relatos de equipes de desenvolvimento, que um projeto Flutter iniciado com `setState()` simples migre para Provider ao crescer e, depois, para Riverpod ou BLoC, conforme aumentam o número de fontes de estado compartilhado e a necessidade de testes automatizados.

A migração não ocorre porque o Provider "pare de funcionar". O motivo é que a recuperação de providers pelo `BuildContext` no Provider tradicional não possui tipagem estrita em tempo de compilação. Buscar um provider fora do escopo em que foi disponibilizado produz erro apenas **em tempo de execução**. Esse custo cresce com o tamanho do time e da base de código, pois mais pessoas passam a alterar a árvore de widgets sem conhecer todos os escopos existentes.

## 6. O motivo prático de isolar o domínio: um teste que roda em milissegundos, sem emulador

### Problema

A testabilidade foi usada como critério de decisão desde a tabela da §3, mas até aqui nenhuma linha de teste foi apresentada. O benefício de isolar a regra de negócio do widget precisa ser demonstrado, pois não é abstrato.

### Mecanismo

Um domínio livre de `Widget`, `BuildContext` ou chamadas de rede diretas pode ser testado com o pacote `test` puro, **sem instanciar nenhuma árvore de widgets e sem emulador**. A diferença de custo é de segundos (testes que compilam e montam um aplicativo inteiro) para milissegundos (execução de uma função Dart comum).

### Aplicação

```dart
// Domínio puro, sem nenhuma dependência de Flutter
bool podeCancelarPedido(Pedido pedido) {
  return pedido.status != StatusPedido.enviado;
}

// test/pedido_test.dart — roda em milissegundos, sem emulador
void main() {
  test('pedido enviado não pode ser cancelado', () {
    final pedido = Pedido(status: StatusPedido.enviado);
    expect(podeCancelarPedido(pedido), isFalse);
  });

  test('pedido pendente pode ser cancelado', () {
    final pedido = Pedido(status: StatusPedido.pendente);
    expect(podeCancelarPedido(pedido), isTrue);
  });
}
```

Cada teste segue a estrutura *preparar, executar, verificar*: constrói-se um pedido com determinado status, chama-se a função e compara-se o resultado esperado com o obtido (`expect`).

Este é o retorno concreto do rigor arquitetural discutido na aula: quanto mais a lógica de negócio estiver isolada em funções e classes puras de domínio, maior a fração do sistema que pode ser coberta por testes rápidos, executados a cada alteração de código e sem depender de emulador. Tal característica é pré-requisito prático de qualquer pipeline de integração contínua.

## Síntese da aula

| Camada | Não deve conter |
|---|---|
| Apresentação (widgets) | Lógica de negócio, chamadas de rede diretas |
| Domínio | Referência a widgets, `BuildContext`, ou detalhes de HTTP/banco |
| Dados | Regra de negócio (apenas obtenção/persistência) |

| Conceito | Problema que resolve |
|---|---|
| Arquitetura em camadas | Mistura de responsabilidades, que dificulta troca de fonte de dados, testes e reuso |
| `AsyncValue` | Esquecimento do tratamento de carregamento e erro |
| Gerenciamento de estado | Compartilhamento de dados entre telas distantes, sem acoplamento |
| Domínio isolado | Testes lentos que dependem de emulador |

## Leitura recomendada

- MARTIN, Robert C. *Arquitetura Limpa*. Rio de Janeiro: Alta Books, 2019 — capítulos sobre regra de dependência, aplicáveis à separação de camadas em Flutter.
- Documentação oficial: [State management approaches](https://docs.flutter.dev/data-and-backend/state-mgmt/options).
