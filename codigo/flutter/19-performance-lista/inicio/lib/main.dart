import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'produto.dart';

void main() => runApp(const App());

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: TelaCatalogo());
  }
}

// TODO (Aula 19): esta é a versão INEFICIENTE proposital (mesmo padrão da
// Aula 19 §2) — o estado de favoritos vive aqui, no widget pai da lista
// inteira. Favoritar um item reconstrói TODA a lista.
//
// Meça o custo de reconstrução com o Widget Rebuild Profiler (Flutter
// DevTools), registre em MEDICOES.md, e então refatore aplicando escuta
// seletiva por item (ver solucao/lib/main.dart) — sem mover o dado de
// favorito para dentro do State de cada card, o que quebraria ao rolar a
// lista (Aula 19 §2).
class TelaCatalogo extends StatefulWidget {
  const TelaCatalogo({super.key});

  @override
  State<TelaCatalogo> createState() => _TelaCatalogoState();
}

class _TelaCatalogoState extends State<TelaCatalogo> {
  List<Produto> _produtos = [];
  Set<String> _favoritos = {};

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    final json = await rootBundle.loadString('assets/produtos.json');
    final lista = jsonDecode(json) as List;
    setState(() {
      _produtos = lista.map((item) => Produto.fromJson(item as Map<String, dynamic>)).toList();
    });
  }

  void _alternarFavorito(String id) {
    setState(() {
      _favoritos.contains(id) ? _favoritos.remove(id) : _favoritos.add(id);
    }); // reconstrói TODA a árvore abaixo de TelaCatalogo, inclusive os 249
    //     outros cards que não mudaram — este é o custo a medir.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Catálogo (início — ineficiente)')),
      body: _produtos.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: _produtos
                  .map((p) => ListTile(
                        title: Text(p.nome),
                        subtitle: Text('R\$ ${p.preco.toStringAsFixed(2)}'),
                        trailing: IconButton(
                          icon: Icon(_favoritos.contains(p.id) ? Icons.favorite : Icons.favorite_border),
                          onPressed: () => _alternarFavorito(p.id),
                        ),
                      ))
                  .toList(),
            ),
    );
  }
}
