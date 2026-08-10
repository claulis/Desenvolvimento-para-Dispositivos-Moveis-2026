class Produto {
  final String id;
  final String nome;
  final double preco;

  Produto({required this.id, required this.nome, required this.preco});

  factory Produto.fromJson(Map<String, dynamic> json) => Produto(
        id: json['id'] as String,
        nome: json['nome'] as String,
        preco: (json['preco'] as num).toDouble(),
      );
}
