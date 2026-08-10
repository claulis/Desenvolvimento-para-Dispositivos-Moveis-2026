import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'produto.dart';

void main() => runApp(const ProviderScope(child: App()));

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: TelaCatalogo());
  }
}

final produtosProvider = FutureProvider<List<Produto>>((ref) async {
  final json = await rootBundle.loadString('assets/produtos.json');
  final lista = jsonDecode(json) as List;
  return lista.map((item) => Produto.fromJson(item as Map<String, dynamic>)).toList();
});

// Estado de domínio: favoritos por id de produto — não vive dentro do card.
final favoritosProvider = StateProvider<Set<String>>((ref) => {});

// Family provider: cada card observa apenas a própria fatia (é ou não é
// favorito), em vez de todo o Set de favoritos — a "escuta seletiva" da
// Aula 19 §2.
final favoritoProvider = Provider.family<bool, String>((ref, produtoId) {
  return ref.watch(favoritosProvider).contains(produtoId);
});

class TelaCatalogo extends ConsumerWidget {
  const TelaCatalogo({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final produtosAsync = ref.watch(produtosProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Catálogo (solução)')),
      body: produtosAsync.when(
        data: (produtos) => ListView.builder(
          itemCount: produtos.length,
          itemBuilder: (context, index) {
            final produto = produtos[index];
            return CardProduto(key: ValueKey(produto.id), produto: produto);
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (erro, _) => Center(child: Text('Erro: $erro')),
      ),
    );
  }
}

class CardProduto extends ConsumerWidget {
  final Produto produto;
  const CardProduto({required this.produto, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Só este card reconstrói quando o favorito de produto.id muda —
    // não a lista inteira.
    final favoritado = ref.watch(favoritoProvider(produto.id));

    return ListTile(
      title: Text(produto.nome),
      subtitle: Text('R\$ ${produto.preco.toStringAsFixed(2)}'),
      trailing: IconButton(
        icon: Icon(favoritado ? Icons.favorite : Icons.favorite_border),
        onPressed: () {
          final atual = ref.read(favoritosProvider);
          final novo = Set<String>.from(atual);
          novo.contains(produto.id) ? novo.remove(produto.id) : novo.add(produto.id);
          ref.read(favoritosProvider.notifier).state = novo;
        },
      ),
    );
  }
}
