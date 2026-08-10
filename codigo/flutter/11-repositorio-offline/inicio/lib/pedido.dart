class Pedido {
  final String id;
  final String status;
  final double total;

  Pedido({required this.id, required this.status, required this.total});

  factory Pedido.fromJson(Map<String, dynamic> json) => Pedido(
        id: json['id'] as String,
        status: json['status'] as String,
        total: (json['total'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {'id': id, 'status': status, 'total': total};
}
