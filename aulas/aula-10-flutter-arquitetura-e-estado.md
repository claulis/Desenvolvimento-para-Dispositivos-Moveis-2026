# Aula 10 — Flutter: arquitetura em camadas e gerenciamento de estado

**Carga horária:** 4h
**Unidade:** III — Arquitetura de software em Flutter

## Objetivos da aula

- Estruturar uma aplicação Flutter em camadas de apresentação, domínio e dados.
- Identificar violações de camada em código Flutter existente.
- Comparar Provider, Riverpod e BLoC como soluções de gerenciamento de estado.

## 1. Por que separar em camadas também em Flutter

Um projeto Flutter pequeno pode, tecnicamente, colocar toda a lógica — chamada de rede, regra de negócio, e construção de widget — dentro do método `build()` de um único `StatefulWidget`. Isso funciona para um protótipo descartável, mas não escala: qualquer mudança na fonte de dados (trocar uma API por outra), qualquer teste automatizado de regra de negócio, ou qualquer reuso de lógica em outra tela, exige desembaraçar a lógica de dentro da árvore de widgets.

> **Definição — Arquitetura em camadas**: organização do código em grupos de responsabilidade com dependência unidirecional (tipicamente apresentação → domínio → dados), de modo que uma camada superior dependa apenas de camadas inferiores, nunca o contrário, permitindo que cada camada seja compreendida, testada e substituída de forma relativamente independente.

| Camada | Responsabilidade | Exemplos no Flutter |
|---|---|---|
| Apresentação | Construir a interface e reagir a interação do usuário | Widgets, `build()`, gerenciadores de estado |
| Domínio | Regras de negócio independentes de framework | Classes de modelo, casos de uso, validações |
| Dados | Obter e persistir dados de fontes externas | Repositórios, clientes HTTP, banco local |

## 2. Padrão de apresentação e a árvore de widgets

Diferente do Android nativo tradicional (onde padrões como MVP e MVVM surgiram para desacoplar a `Activity`/`Fragment` da lógica), o Flutter já força uma separação parcial pela própria natureza declarativa do `build()`: o widget descreve **como a interface deve parecer dado o estado atual**, não **como transicionar de um estado visual para outro** (diferente da manipulação imperativa de views do Android tradicional, ex. `view.setText(...)`). Ainda assim, sem disciplina, é comum ver chamadas de rede diretamente dentro de `initState()` ou de um `onPressed`, misturando apresentação e dados — a violação de camada mais comum em código Flutter de iniciantes.

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

```dart
// Correto: widget delega ao domínio/dados via um gerenciador de estado
class TelaPedidos extends ConsumerWidget {
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

## 3. Gerenciamento de estado: por que existe mais de uma solução

> **Definição — Gerenciamento de estado**: conjunto de estratégias e ferramentas para armazenar, atualizar e propagar dados que afetam a interface ao longo do tempo, de forma que widgets distantes na árvore possam reagir a uma mesma fonte de verdade sem acoplamento direto entre si.

O Flutter, por si só, oferece apenas `setState()` — suficiente para estado local de um único widget, mas insuficiente para estado compartilhado entre telas distantes (ex.: o carrinho de compras, acessível tanto na tela de catálogo quanto na de checkout). Três soluções dominam o ecossistema, cada uma com um modelo mental diferente:

### Provider

Biblioteca que expõe objetos (tipicamente `ChangeNotifier`) para a árvore de widgets via `InheritedWidget`, permitindo que qualquer widget descendente escute mudanças e reconstrua apenas a parte relevante da árvore.

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

### Riverpod

Evolução do Provider, desacoplada da árvore de widgets (não depende de `BuildContext` para declarar providers), com verificação em tempo de compilação e melhor testabilidade — considerada por parte da comunidade Flutter como sucessora natural do Provider em projetos novos.

```dart
final carrinhoProvider = StateNotifierProvider<CarrinhoNotifier, List<Item>>(
  (ref) => CarrinhoNotifier(),
);

// No widget:
final itens = ref.watch(carrinhoProvider);
```

### BLoC (Business Logic Component)

Padrão que modela o estado como um fluxo de **eventos** de entrada transformados em **estados** de saída, usando `Stream`s do Dart de forma explícita — mais verboso, mas com separação muito rígida entre intenção do usuário (evento) e resultado (estado), vantajosa em times grandes e em domínios com regras de transição de estado complexas.

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

### Critério de escolha

| Solução | Quando escolher |
|---|---|
| Provider | Projetos pequenos/médios, equipe já familiarizada, prioridade em simplicidade |
| Riverpod | Projetos que valorizam testabilidade e segurança em tempo de compilação, sem dependência de `BuildContext` |
| BLoC | Domínios com regras de transição de estado complexas, equipes grandes que valorizam rastreabilidade explícita de eventos |

Não existe "o melhor" isolado do contexto — a escolha é uma decisão arquitetural que deve ser justificada, não uma preferência estética, exatamente o tipo de argumento que será exigido na Avaliação 2 (Aula 12).

## 4. Onde o gerenciador de estado se encaixa na arquitetura em camadas

O gerenciador de estado escolhido (Provider, Riverpod ou BLoC) pertence à **fronteira entre apresentação e domínio**: ele recebe do domínio dados já validados e prontos, e expõe à apresentação um formato consumível para reconstrução de widgets — mas a lógica de negócio em si (ex.: "um pedido só pode ser cancelado se ainda não foi enviado") deve residir no domínio, testável independentemente de qualquer widget ou gerenciador de estado.

## 5. Exemplo real: por que aplicativos Flutter de médio porte migram de Provider para Riverpod ou BLoC

É comum em relatos de equipes de desenvolvimento que um projeto Flutter iniciado com `setState()` simples migre para Provider ao crescer, e depois para Riverpod ou BLoC conforme o número de fontes de estado compartilhado e a necessidade de testes automatizados aumentam — não porque Provider "pare de funcionar", mas porque a ausência de tipagem estrita na recuperação de providers pelo `BuildContext` no Provider tradicional torna erros de contexto (buscar um provider fora do escopo onde foi disponibilizado) detectáveis apenas em tempo de execução, um custo que cresce com o tamanho do time e da base de código.

## Síntese da aula

| Camada | Não deve conter |
|---|---|
| Apresentação (widgets) | Lógica de negócio, chamadas de rede diretas |
| Domínio | Referência a widgets, `BuildContext`, ou detalhes de HTTP/banco |
| Dados | Regra de negócio (apenas obtenção/persistência) |

## Leitura recomendada

- MARTIN, Robert C. *Arquitetura Limpa*. Rio de Janeiro: Alta Books, 2019 — capítulos sobre regra de dependência, aplicáveis à separação de camadas em Flutter.
- Documentação oficial: [State management approaches](https://docs.flutter.dev/data-and-backend/state-mgmt/options).

## Atividade da aula

**Estudo de caso: identificação de violações de camada em código Flutter e reorganização do módulo**: a partir de um trecho de código Flutter fornecido (contendo chamada de rede, regra de validação e construção de widget misturadas em um único `StatefulWidget`), identificar cada violação de camada e reescrever o módulo separando apresentação, domínio e dados, adotando um dos três gerenciadores de estado apresentados.
