import 'dart:io';

import 'package:dio/dio.dart';

import 'config.dart';
import 'pedido.dart';

abstract class PedidoRepository {
  Future<List<Pedido>> obterPedidos();
}

// TODO (Aula 11): este repositório tem o bug descrito na Aula 11 §1 —
// captura SocketException, mas o dio lança DioException em falha de
// conectividade. O resultado é que o fallback de cache abaixo NUNCA
// dispara. Corrija o tipo capturado e implemente:
//   1. Fallback para cache local (SharedPreferences) quando a falha for
//      de conectividade.
//   2. Nova tentativa com espera progressiva + jitter, apenas para erros
//      transitórios (Aula 11 §5).
//   3. Persistência do cache a cada busca bem-sucedida.
class PedidoRepositoryImpl implements PedidoRepository {
  final Dio _dio;

  PedidoRepositoryImpl({Dio? dio}) : _dio = dio ?? Dio(BaseOptions(baseUrl: baseUrlApiSimulada));

  @override
  Future<List<Pedido>> obterPedidos() async {
    try {
      final resposta = await _dio.get('/pedidos');
      return (resposta.data as List)
          .map((json) => Pedido.fromJson(json as Map<String, dynamic>))
          .toList();
    } on SocketException {
      // Este catch nunca dispara com o cliente dio configurado acima — é
      // exatamente o bug que a atividade pede para encontrar e corrigir.
      return [];
    }
  }
}
