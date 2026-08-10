import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'config.dart';
import 'pedido.dart';

abstract class PedidoRepository {
  Future<List<Pedido>> obterPedidos();
}

class PedidoRepositoryImpl implements PedidoRepository {
  final Dio _dio;

  PedidoRepositoryImpl({Dio? dio}) : _dio = dio ?? Dio(BaseOptions(baseUrl: baseUrlApiSimulada));

  @override
  Future<List<Pedido>> obterPedidos() async {
    try {
      final pedidos = await _comNovaTentativa(() => _buscarPedidosRemoto());
      await _salvarCache(pedidos);
      return pedidos;
    } on DioException catch (e) {
      // dio embrulha falhas de conexão em DioException — nunca em
      // SocketException. Ver Aula 11 §1: capturar o tipo errado aqui faz o
      // fallback de cache nunca disparar.
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        return _obterCache();
      }
      rethrow;
    }
  }

  Future<List<Pedido>> _buscarPedidosRemoto() async {
    final resposta = await _dio.get('/pedidos');
    return (resposta.data as List)
        .map((json) => Pedido.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<Pedido>> _obterCache() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString('pedidos_cache');
    if (json == null) return [];
    return (jsonDecode(json) as List)
        .map((item) => Pedido.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> _salvarCache(List<Pedido> pedidos) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pedidos_cache', jsonEncode(pedidos.map((p) => p.toJson()).toList()));
  }

  Future<T> _comNovaTentativa<T>(Future<T> Function() operacao, {int maxTentativas = 4}) async {
    var tentativa = 0;
    while (true) {
      try {
        return await operacao();
      } on DioException catch (e) {
        final transitorio = e.type == DioExceptionType.connectionError ||
            e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            (e.response?.statusCode ?? 0) >= 500;
        tentativa++;
        if (!transitorio || tentativa >= maxTentativas) rethrow;

        final espera = Duration(
          milliseconds: (1000 * (1 << tentativa)) + Random().nextInt(1000),
        );
        await Future.delayed(espera);
      }
    }
  }
}
