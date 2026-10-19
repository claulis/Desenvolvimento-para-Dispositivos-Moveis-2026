# Aula 8 — Exemplo Flutter completo com persistência

Tutorial passo a passo, para copiar, colar e executar. No final, o app **Lista de Compras** adiciona, marca, remove e controla a quantidade de itens, e **lembra tudo depois de fechado** (pacote `shared_preferences`).

## Pré-requisitos

- Flutter instalado: [docs.flutter.dev/install](https://docs.flutter.dev/install)
- VS Code com as extensões **Flutter** e **Dart**
- Para rodar no Android: Android Studio instalado (traz o SDK e o emulador). Veja o Passo 6

Confira o ambiente. Tudo que aparecer com ✗ precisa ser resolvido antes de continuar:

```bash
flutter doctor
```

## Passo 1: Criar o projeto

```bash
flutter create lista_compras
cd lista_compras
flutter pub add shared_preferences
code .
```

Apague o teste de exemplo, que não serve para este app:

```bash
# Windows (PowerShell)
Remove-Item test/widget_test.dart

# macOS / Linux
rm test/widget_test.dart
```

## Passo 2: Modelo `Item`

Crie a pasta `lib/models/` e o arquivo `lib/models/item.dart`:

```dart
class Item {
  Item({
    required this.id,
    required this.nome,
    this.quantidade = 1,
    this.comprado = false,
  });

  final String id;
  final String nome;
  int quantidade;
  bool comprado;

  Map<String, dynamic> toJson() => {
        'id': id,
        'nome': nome,
        'quantidade': quantidade,
        'comprado': comprado,
      };

  factory Item.fromJson(Map<String, dynamic> json) => Item(
        id: json['id'] as String,
        nome: json['nome'] as String,
        quantidade: json['quantidade'] as int,
        comprado: json['comprado'] as bool,
      );
}
```

## Passo 3: Armazenamento

Crie o arquivo `lib/lista_storage.dart`:

```dart
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'models/item.dart';

class ListaStorage {
  static const _chave = 'lista_compras';
  final _prefs = SharedPreferencesAsync();

  Future<List<Item>> carregar() async {
    final texto = await _prefs.getString(_chave);
    if (texto == null) return [];
    final lista = jsonDecode(texto) as List<dynamic>;
    return lista.map((e) => Item.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> salvar(List<Item> itens) {
    return _prefs.setString(_chave, jsonEncode(itens));
  }
}
```

## Passo 4: Tela principal

Abra `lib/main.dart`, apague tudo e cole:

```dart
import 'package:flutter/material.dart';

import 'lista_storage.dart';
import 'models/item.dart';

void main() => runApp(const ListaComprasApp());

class ListaComprasApp extends StatelessWidget {
  const ListaComprasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lista de Compras',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
      ),
      home: const ListaPage(),
    );
  }
}

class ListaPage extends StatefulWidget {
  const ListaPage({super.key});

  @override
  State<ListaPage> createState() => _ListaPageState();
}

class _ListaPageState extends State<ListaPage> {
  final _controller = TextEditingController();
  final List<Item> _itens = [];
  final _storage = ListaStorage();
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    final itens = await _storage.carregar();
    if (!mounted) return;
    setState(() {
      _itens.addAll(itens);
      _carregando = false;
    });
  }

  void _atualizar(VoidCallback alteracao) {
    setState(alteracao);
    _storage.salvar(_itens);
  }

  void _adicionar() {
    final nome = _controller.text.trim();
    if (nome.isEmpty) return;
    _atualizar(() {
      _itens.add(
        Item(id: DateTime.now().microsecondsSinceEpoch.toString(), nome: nome),
      );
    });
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista de Compras'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Remover comprados',
            onPressed: () =>
                _atualizar(() => _itens.removeWhere((i) => i.comprado)),
          ),
        ],
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          decoration: const InputDecoration(
                            labelText: 'Novo item',
                            border: OutlineInputBorder(),
                          ),
                          onSubmitted: (_) => _adicionar(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: _adicionar,
                        child: const Text('Adicionar'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _itens.isEmpty
                      ? const Center(child: Text('Sua lista está vazia.'))
                      : ListView.builder(
                          itemCount: _itens.length,
                          itemBuilder: (context, i) {
                            final item = _itens[i];
                            return Dismissible(
                              key: ValueKey(item.id),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                color: Colors.red,
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 16),
                                child: const Icon(
                                  Icons.delete,
                                  color: Colors.white,
                                ),
                              ),
                              onDismissed: (_) =>
                                  _atualizar(() => _itens.remove(item)),
                              child: CheckboxListTile(
                                value: item.comprado,
                                onChanged: (marcado) {
                                  _atualizar(
                                    () => item.comprado = marcado ?? false,
                                  );
                                },
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                title: Text(
                                  item.nome,
                                  style: TextStyle(
                                    decoration: item.comprado
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                ),
                                subtitle: Text(
                                  'Quantidade: ${item.quantidade}',
                                ),
                                secondary: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove),
                                      onPressed: item.quantidade > 1
                                          ? () => _atualizar(
                                                () => item.quantidade--,
                                              )
                                          : null,
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add),
                                      onPressed: () =>
                                          _atualizar(() => item.quantidade++),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
```

## Passo 5: Teste automatizado

Crie o arquivo `test/item_test.dart`:

```dart
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lista_compras/models/item.dart';

void main() {
  test('Item sobrevive ao ciclo JSON', () {
    final original = Item(
      id: '1',
      nome: 'Arroz',
      quantidade: 2,
      comprado: true,
    );

    final texto = jsonEncode([original]);
    final lista = jsonDecode(texto) as List<dynamic>;
    final volta = Item.fromJson(lista.first as Map<String, dynamic>);

    expect(volta.id, '1');
    expect(volta.nome, 'Arroz');
    expect(volta.quantidade, 2);
    expect(volta.comprado, true);
  });
}
```

Rode no terminal, dentro da pasta do projeto:

```bash
flutter test
```

Resultado esperado: *All tests passed!*

Estrutura final do projeto:

```text
lista_compras/
├── lib/
│   ├── main.dart
│   ├── lista_storage.dart
│   └── models/
│       └── item.dart
├── test/
│   └── item_test.dart
└── pubspec.yaml
```

## Passo 6: Rodar o app

### Comandos Flutter

Dentro da pasta `lista_compras`:

```bash
flutter pub get                    # baixa as dependências
flutter analyze                    # procura problemas no código
flutter devices                    # lista emuladores, celulares e navegadores disponíveis
flutter emulators                  # lista os emuladores Android criados
flutter emulators --launch NOME    # abre um emulador pelo id mostrado acima
flutter run                        # roda no dispositivo disponível (pergunta qual, se houver vários)
flutter run -d chrome --web-port=5000   # roda no Chrome (a porta fixa mantém os dados salvos)
flutter run -d ID_DO_DISPOSITIVO   # roda no dispositivo escolhido em flutter devices
```

Com o app rodando, no terminal: `r` faz hot reload, `R` faz hot restart e `q` encerra.

### Preparar o Android (uma única vez)

1. Instale o [Android Studio](https://developer.android.com/studio) e abra-o uma vez, aceitando o assistente de instalação (ele baixa o Android SDK).
2. Aceite as licenças:

   ```bash
   flutter doctor --android-licenses
   ```

3. Confira se a seção *Android toolchain* do `flutter doctor` está sem ✗.

### Rodar no emulador Android, pelo VS Code

1. **Criar o emulador** (só na primeira vez): no Android Studio, abra *More Actions > Virtual Device Manager* (ou *Tools > Device Manager*), clique em **Create Device**, escolha um modelo (por exemplo, *Pixel 8*), escolha uma imagem do sistema (baixe se pedir) e finalize.
2. No VS Code, abra a pasta `lista_compras`.
3. Aperte **Ctrl+Shift+P**, digite **Flutter: Launch Emulator** e escolha o emulador criado. Aguarde a tela do Android aparecer.
4. Na **barra de status** (canto inferior direito do VS Code), confirme que o nome do emulador aparece como dispositivo. Se não aparecer, clique no nome do dispositivo atual e escolha o emulador.
5. Abra `lib/main.dart` e aperte **F5** (ou menu *Run > Start Debugging*). Se pedir o ambiente, escolha **Dart & Flutter**.
6. Aguarde a primeira compilação (pode levar alguns minutos). O app abre no emulador.
7. Para parar, aperte **Shift+F5**. Para aplicar mudanças no código, salve com **Ctrl+S** (hot reload).

Pelo terminal, o equivalente é:

```bash
flutter emulators
flutter emulators --launch NOME_DO_EMULADOR
flutter run
```

### Rodar no celular Android, pelo VS Code

1. **Ativar o modo desenvolvedor no celular:** *Configurações > Sobre o telefone* e toque 7 vezes em **Número da versão**.
2. **Ativar a depuração USB:** *Configurações > Sistema > Opções do desenvolvedor > Depuração USB*.
3. Conecte o celular ao computador por um cabo USB (que transfira dados, não só carregue).
4. No celular, aceite a janela **Permitir depuração USB?** (marque *Sempre permitir*).
5. No terminal, confirme que o celular foi reconhecido:

   ```bash
   flutter devices
   ```

   O modelo do celular deve aparecer na lista. Se não aparecer, troque o cabo ou a porta USB, e confira `flutter doctor`.
6. No VS Code, clique no dispositivo na **barra de status** (canto inferior direito) e escolha o celular.
7. Abra `lib/main.dart` e aperte **F5**. O app é instalado e abre no celular.
8. Para parar, **Shift+F5**. Com o app aberto, salvar o código (**Ctrl+S**) atualiza o celular na hora (hot reload).

Pelo terminal, o equivalente é:

```bash
flutter devices
flutter run -d ID_DO_CELULAR
```

Opcional, sem cabo (Android 11 ou mais novo, celular e computador na mesma rede Wi-Fi): em *Opções do desenvolvedor*, ative **Depuração por Wi-Fi**, escolha *Parear dispositivo com código* e rode:

```bash
adb pair IP:PORTA_DE_PAREAMENTO
adb connect IP:PORTA
flutter devices
```

### Testar a persistência

1. Rode o app, adicione três itens, marque um e mude uma quantidade.
2. Pare o app (**Shift+F5**) e rode de novo (**F5**).
3. Os itens, as marcações e as quantidades devem reaparecer.

## Erros comuns

| Sintoma | Solução |
| --- | --- |
| `flutter test` falha dizendo que `MyApp` não existe | apagar `test/widget_test.dart` (Passo 1) |
| `Target of URI doesn't exist: package:shared_preferences/...` | `flutter pub add shared_preferences` |
| `MissingPluginException` ao abrir ou salvar | parar o app e rodar de novo (hot reload não instala plugins) |
| Celular não aparece em `flutter devices` | conferir a depuração USB, aceitar a janela no celular, trocar o cabo |
| `cmdline-tools component is missing` no `flutter doctor` | Android Studio: *Settings > Languages & Frameworks > Android SDK > SDK Tools*, marcar **Android SDK Command-line Tools** |
| Emulador não aparece na barra de status | `flutter emulators --launch NOME` e aguardar a tela do Android carregar |
| A lista volta vazia ao reabrir no Chrome | `flutter run -d chrome --web-port=5000` |
