# Dart em 30 minutos — só o que este componente usa

Este não é um curso de Dart. Cobre exclusivamente a sintaxe usada nos exemplos das Aulas 9–19, para quem chega ao componente com POO (em qualquer linguagem) mas sem experiência prévia em Dart. Se sua equipe já tem essa base, pule este anexo.

## Tipagem e variáveis

```dart
String nome = 'Ana';       // tipo explícito
var idade = 30;             // tipo inferido (continua sendo int, não dinâmico)
final total = 19.9;         // não pode ser reatribuída
const limite = 100;         // constante em tempo de compilação
```

## Null safety

Por padrão, uma variável **não pode ser nula** a menos que seu tipo termine em `?`:

```dart
String nome = 'Ana';    // nunca nulo
String? apelido;         // pode ser nulo — precisa de verificação antes de usar

if (apelido != null) {
  print(apelido.length); // Dart sabe, aqui dentro, que apelido não é nulo
}

print(apelido?.length);  // acesso seguro: se apelido for nulo, retorna nulo
print(apelido!.length);  // afirma "eu garanto que não é nulo" — usar com cuidado
```

## `late`

Declara que uma variável não-nula será inicializada depois da declaração, mas antes do primeiro uso — comum em campos de `State` que dependem de `initState()`:

```dart
class _MinhaTelaState extends State<MinhaTela> {
  late final PedidoRepository repositorio; // inicializada em initState, não na declaração

  @override
  void initState() {
    super.initState();
    repositorio = PedidoRepositoryImpl();
  }
}
```

## `required` em construtores nomeados

```dart
class Produto {
  final String id;
  final double preco;

  Produto({required this.id, required this.preco}); // obrigatórios, mas nomeados
}

final produto = Produto(id: 'p1', preco: 19.9); // ordem não importa, nomes sim
```

## `Future` e `async`/`await`

`Future<T>` representa um valor do tipo `T` que estará disponível no futuro (o equivalente a uma `Promise<T>` do JavaScript). `async`/`await` são a forma de "esperar" esse valor sem bloquear a thread:

```dart
Future<List<Pedido>> obterPedidos() async {
  final resposta = await http.get(Uri.parse('https://api.exemplo.com/pedidos'));
  return parsearPedidos(resposta.body);
}

// Consumindo:
void carregar() async {
  final pedidos = await obterPedidos();
  print(pedidos.length);
}
```

## `factory` constructors

Um construtor `factory` pode decidir o que retornar (inclusive uma instância já existente), em vez de sempre criar uma nova — usado nas Aulas 11/15 para desserialização de JSON:

```dart
class Pedido {
  final String id;
  final double total;

  Pedido({required this.id, required this.total});

  factory Pedido.fromJson(Map<String, dynamic> json) => Pedido(
        id: json['id'] as String,
        total: (json['total'] as num).toDouble(),
      );
}

final pedido = Pedido.fromJson({'id': 'p1', 'total': 19.9});
```

## Coleções imutáveis "aparentes"

Padrão comum nos exemplos de gerenciamento de estado (Aula 10): em vez de alterar uma lista existente, cria-se uma nova lista com o item adicionado — o padrão que aparece como `state = [...state, item]`:

```dart
final novaLista = [...listaAntiga, novoItem]; // spread operator: copia + adiciona
```

## Onde continuar

Documentação oficial: [dart.dev/language](https://dart.dev/language) — a seção "Language tour" cobre, em profundidade, tudo o que este resumo simplificou.
