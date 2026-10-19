# Aula 8 — Exemplo Flutter completo com persistência



## Visão geral

Em 9 passos curtos, a turma constrói um app Flutter de lista de compras que **lembra os itens mesmo depois de fechado**, usando `shared_preferences`.

**O app final faz isto:**

- adiciona itens digitando o nome e tocando em *Adicionar*
- marca itens como comprados (o texto fica riscado)
- ajusta a quantidade com os botões + e −
- remove itens arrastando para o lado, ou todos os comprados de uma vez
- guarda tudo no aparelho e recarrega ao abrir



### Antes de codar: a analogia do quadro branco

Imagine a tela como um quadro branco numa sala. O **estado** (`State`) é o que está escrito no quadro. Chamar `setState` é apagar e reescrever o quadro. Mas quando a aula acaba e a sala fecha (o app é encerrado), o quadro é apagado. **Persistir** é tirar uma foto do quadro antes de sair e, na próxima aula, escrever de novo o que está na foto. É exatamente o que o passo 8 faz.

### Pré-requisitos

- Flutter instalado (este guia foi preparado para o Flutter 3.47, estável desde agosto de 2026, com Dart 3.13). Instalação: [docs.flutter.dev/install](https://docs.flutter.dev/install)
- VS Code com as extensões **Flutter** e **Dart**
- Um destino para rodar o app: o **Chrome** (mais simples para a sala de aula) ou um emulador/celular Android

Confira a instalação no terminal. Tudo que aparecer com ✗ precisa ser resolvido antes de começar:

```bash
flutter doctor
```

> Para a aula, só o Flutter e o Chrome precisam estar com ✓. Android Studio, Visual Studio e Xcode só são necessários se a turma for rodar nesses destinos.

### Mapa dos passos

1. Criar o projeto e rodar o primeiro app
2. Entender a estrutura da tela (Stateless x Stateful)
3. Criar o modelo `Item` e mostrar uma lista fixa
4. Adicionar itens (`TextField`, botão e `setState`)
5. Marcar como comprado
6. Remover itens
7. Controlar a quantidade
8. Persistir com `shared_preferences`
9. Testar o modelo


## Conceitos de base

Três peças aparecem em todo o código deste guia: o Flutter e seus widgets, a biblioteca `material.dart` e os pacotes. Leia agora ou volte aqui quando surgir dúvida. A linguagem Dart tem a sua própria seção logo depois.

### Flutter e widgets

O **Flutter** é o framework do Google para criar apps de celular, web e desktop com um único código, escrito em Dart. No Flutter, **tudo que aparece na tela é um widget**: um texto, um botão, uma margem, a tela inteira. Widgets se encaixam uns dentro dos outros, como peças de Lego, e formam a *árvore de widgets*. O método `build` descreve essa árvore, e quando os dados mudam o Flutter reconstrói a parte afetada.

### O que é o `material.dart`

É a primeira linha do nosso `main.dart`:

```dart
import 'package:flutter/material.dart';
```

Lendo a linha por partes:

- `import` traz código de outro arquivo para o seu
- `package:flutter` indica *de onde*: o pacote do próprio Flutter
- `material.dart` é a biblioteca importada: o conjunto de widgets prontos do **Material Design**

O Material Design é o sistema de design do Google: um conjunto de regras e componentes visuais (cores, tipografia, botões, barras, campos de texto, animações). A biblioteca `material.dart` entrega esses componentes prontos, para não precisarmos desenhar cada botão do zero. A versão atual do Material, usada por padrão nos apps novos, é a 3. Existe também o `cupertino.dart`, com componentes no estilo do iOS.

O que usamos dela no app:

| Elemento | Para que serve no app |
| --- | --- |
| `MaterialApp` | raiz do app: título, tema e tela inicial |
| `ThemeData`, `ColorScheme.fromSeed`, `Colors` | tema e cores; a partir de uma cor "semente", o Flutter gera uma paleta completa |
| `Scaffold`, `AppBar` | esqueleto da tela e barra superior |
| `TextField`, `InputDecoration`, `OutlineInputBorder` | campo de texto com rótulo e borda |
| `FilledButton`, `IconButton`, `Icon`, `Icons` | botões e ícones |
| `CheckboxListTile` | linha da lista com caixa de seleção |
| `CircularProgressIndicator` | círculo que gira enquanto carrega |

Os widgets de estrutura, como `Column`, `Row`, `Text`, `Padding`, `Expanded`, `ListView`, `Dismissible`, `StatelessWidget`, `StatefulWidget` e `setState`, vêm de uma biblioteca mais básica, a `widgets.dart`, que não tem estilo próprio. O `material.dart` já inclui tudo isso, e por isso **um só import basta**.

> **Nota para o professor:** no Flutter 3.47, o código do Material também foi publicado como o pacote `material_ui`, com as mesmas classes e de adoção opcional por enquanto. Ao migrar, mudam o import e a dependência no pubspec, para `package:material_ui/material_ui.dart`. Detalhes em [Migrate to standalone material\_ui and cupertino\_ui packages](https://docs.flutter.dev/release/breaking-changes/material-ui-and-cupertino-ui).

### Pacotes, `pub.dev` e `pubspec.yaml`

Um **pacote** é código pronto, escrito por outras pessoas, que você reaproveita. O repositório oficial de pacotes Dart e Flutter é o [pub.dev](https://pub.dev). O `shared_preferences`, que usaremos no passo 8, é um deles.

O arquivo `pubspec.yaml`, na raiz do projeto, é a *ficha* do app: nome, versão e a lista de pacotes de que ele depende. Depois do passo 8, ele terá algo assim (o número da versão pode ser mais novo):

```yaml
dependencies:
  flutter:
    sdk: flutter
  shared_preferences: ^2.5.4

dev_dependencies:
  flutter_test:
    sdk: flutter
```

- `dependencies` são pacotes que o app precisa para funcionar
- `dev_dependencies` são pacotes só para desenvolvimento, como o `flutter_test`, que usamos no passo 9
- `^2.5.4` significa: qualquer versão compatível a partir da 2.5.4, até antes da 3.0.0
- `flutter pub add nome` escreve a linha no `pubspec.yaml` e baixa o pacote. `flutter pub get` baixa tudo que já está listado
- para usar um pacote no código, importamos com `import 'package:nome/arquivo.dart';`. Pelo mesmo motivo, no teste importamos `package:lista_compras/models/item.dart`: `lista_compras` é o nome do nosso próprio pacote

## Guia rápido de Dart

Dart é a linguagem do Flutter. Se você conhece Java, C# ou JavaScript, vai achá-la familiar. O compilador confere os tipos antes de o app rodar, o que pega muitos erros cedo. Esta seção segue a ordem em que as ideias aparecem no código e mostra, em cada uma, onde ela é usada.

### 1. Variáveis, tipos e texto

```dart
String nome = 'Arroz';   // tipo escrito
final quantidade = 2;    // tipo descoberto (int); recebe valor uma única vez
const taxa = 0.1;        // constante, conhecida já na compilação
var contador = 0;        // tipo descoberto; pode receber outro valor depois
contador = contador + 1;
```

| Palavra | Significado | Onde aparece |
| --- | --- | --- |
| `var` | variável cujo tipo o Dart descobre sozinho; o valor pode mudar | pouco usada neste app |
| `final` | recebe valor **uma única vez**; o valor pode ser calculado durante a execução | `final nome = _controller.text.trim();` |
| `const` | valor conhecido **antes** de o app rodar; nunca muda | `const Text('Olá')`, `static const _chave = ...` |

Os tipos básicos são `int` (inteiro), `double` (decimal), `String` (texto) e `bool` (verdadeiro ou falso).

Textos aceitam aspas simples ou duplas. Para colocar um valor no meio do texto, usamos a **interpolação**: `'Oi, $nome'` para uma variável simples, e `'Quantidade: ${item.quantidade}'` quando é uma expressão, como o acesso a um campo.

### 2. Funções

```dart
int dobro(int x) {
  return x * 2;
}

int dobro2(int x) => x * 2; // forma curta
```

- o tipo antes do nome é o que a função devolve; `void` significa que não devolve nada
- a seta `=>` é uma forma curta, válida quando o corpo é **uma única expressão**. É o que torna possível `void main() => runApp(const ListaComprasApp());`
- `main` é a função em que todo programa Dart começa

### 3. Parâmetros nomeados, obrigatórios e padrão

```dart
Item({
  required this.id,
  required this.nome,
  this.quantidade = 1,
  this.comprado = false,
});

// na chamada, a ordem é livre:
Item(nome: 'Arroz', id: '1');
```

- as chaves `{ }` na declaração criam parâmetros **nomeados**: quem chama escreve `nome: valor`
- `required` obriga a informar. Sem ele, o parâmetro é opcional
- `this.quantidade = 1` define um **valor padrão** para quando o parâmetro for omitido
- `this.nome` é um atalho: recebe o argumento e já o guarda no campo `nome` do objeto
- quase todo widget do Flutter usa parâmetros nomeados: `Padding(padding: ..., child: ...)`. Parâmetros **posicionais** (sem nome) existem, e o primeiro argumento de `Text('Olá')` é um deles

### 4. Funções são valores: callbacks e lambdas

Em Dart, uma função pode ser guardada numa variável e passada como argumento.

```dart
onPressed: _adicionar,    // passa a função; o botão a chama quando for tocado
onPressed: _adicionar(),  // ERRO: chama agora e passa o resultado
```

A diferença é só o par de parênteses, e é um erro clássico de iniciantes.

Uma **lambda** é uma função sem nome, escrita no lugar em que é usada:

```dart
(i) => i.comprado        // recebe i e devolve i.comprado
() => item.quantidade++  // não recebe nada
(_) => _adicionar()      // recebe um valor que vamos ignorar
```

- `_` como nome de parâmetro é a convenção para “recebo, mas não uso”
- `VoidCallback` é um tipo que significa “função sem parâmetros e sem retorno”. Nosso `_atualizar(VoidCallback alteracao)` recebe um pedaço de código e o executa dentro do `setState`
- uma lambda **lembra** as variáveis que existiam ao seu redor quando foi criada. Por isso, a lambda dentro do `itemBuilder` enxerga o `item` daquela linha

### 5. Classes, herança e `@override`

```dart
class ListaPage extends StatefulWidget {
  const ListaPage({super.key});

  @override
  State<ListaPage> createState() => _ListaPageState();
}
```

- uma **classe** é um molde, e um **objeto** é uma peça feita com esse molde: `Item(id: '1', nome: 'Arroz')`. Em Dart não se escreve `new`
- a classe reúne **campos** (os dados), um **construtor** (método com o mesmo nome da classe, que cria o objeto) e **métodos** (as ações)
- `extends` faz a classe **herdar** tudo da classe-mãe. Todo widget de tela herda de `StatelessWidget` ou `StatefulWidget`
- `@override` marca um método que **substitui** o da classe-mãe: `build`, `initState`, `dispose`, `createState`
- `super` é a classe-mãe: `super.key` repassa o parâmetro `key` ao construtor dela, e `super.initState()` executa a versão dela do método
- nomes que começam com `_` são **privados ao arquivo**: `_ListaPageState`, `_itens`, `_adicionar`. Dart não tem as palavras `private` e `public`
- `factory Item.fromJson(...)` é um construtor com nome próprio, que monta o objeto a partir de outros dados
- `static const _chave` pertence à classe, e não a cada objeto
- `const ListaPage({super.key})` é um construtor constante: é ele que permite escrever `const ListaPage()`

### 6. Valores nulos (null safety)

Em Dart, uma variável **não pode ser nula**, a menos que o tipo termine com `?`.

```dart
String nome = 'Arroz';  // nunca nulo
String? talvez;         // pode ser nulo

final texto = await _prefs.getString(_chave); // String?
if (texto == null) return [];
// daqui em diante, o Dart sabe que texto não é nulo

final marcado2 = marcado ?? false; // se marcado for nulo, usa false
```

- `bool? marcado` no `onChanged` do checkbox e o retorno de `getString` são tipos que podem ser nulos
- `a ?? b` significa “use `a`; se `a` for nulo, use `b`”
- depois de um teste `== null` com `return`, o Dart passa a tratar a variável como não nula
- `dynamic` é “qualquer tipo, sem conferir”. O `jsonDecode` devolve valores assim, e por isso usamos `as`: `json['id'] as String` diz ao Dart qual é o tipo real. Se o valor não for desse tipo, o app para com um erro de conversão

### 7. Coleções e genéricos

```dart
final List<Item> _itens = [];
_itens.add(item);
_itens.remove(item);
_itens.removeWhere((i) => i.comprado);
final pendentes = _itens.where((i) => !i.comprado).length;
```

- `List<Item>` lê-se “lista de `Item`”. O que fica entre `<` e `>` é um **genérico**: o tipo dos elementos guardados. O mesmo vale para `Map<String, dynamic>` (um dicionário com chaves de texto e valores de qualquer tipo) e `State<ListaPage>`
- `[]` cria uma lista, e `{'id': id, 'nome': nome}` cria um `Map`
- `!` antes de um valor verdadeiro ou falso inverte: `!i.comprado` é “não comprado”

| Método ou propriedade | O que faz | Onde aparece |
| --- | --- | --- |
| `add(x)` | acrescenta no fim | `_adicionar` |
| `remove(x)` | remove o elemento igual a `x` | `onDismissed` |
| `removeWhere(teste)` | remove todos que passam no teste | botão de remover comprados |
| `addAll(outra)` | acrescenta todos os elementos de outra lista | `_carregar` |
| `where(teste)` | seleciona os que passam no teste | exercício 1 |
| `map(função)` | transforma cada elemento | `ListaStorage.carregar` |
| `toList()` | transforma o resultado de `map` ou `where` numa lista de verdade | `ListaStorage.carregar` |
| `first`, `length`, `isEmpty` | primeiro elemento, tamanho, se está vazia | `_itens.isEmpty`, `lista.first` |

### 8. Decisões e operadores

```dart
if (nome.isEmpty) return;           // sai da função cedo
final resposta = comprado ? 'sim' : 'não'; // condição ? se verdadeiro : se falso
item.quantidade++;                  // soma 1
```

- `if (nome.isEmpty) return;` é um *retorno antecipado*: se o nome estiver vazio, a função termina ali e o resto não roda
- `condição ? A : B` escolhe entre dois valores. No app, risca o texto (ou não) e habilita o botão − (ou o desabilita)
- `++` e `--` somam e subtraem 1

### 9. Tarefas demoradas: `Future`, `async` e `await`

Imagine pedir um prato num restaurante. Você recebe uma **senha** e, enquanto a comida não fica pronta, pode conversar. Quando chamam sua senha, você busca o prato. A senha é o `Future`: uma promessa de um valor que chegará depois.

```dart
Future<void> _carregar() async {
  final itens = await _storage.carregar(); // espera, sem travar a tela
  if (!mounted) return;
  setState(() {
    _itens.addAll(itens);
    _carregando = false;
  });
}
```

- ler do aparelho, gravar e acessar a internet são operações lentas, então o Dart as faz de forma **assíncrona**: a tela continua respondendo enquanto isso
- `Future<List<Item>>` lê-se “uma lista de `Item` que vai chegar”. `Future<void>` é uma tarefa que termina, mas não devolve valor
- `async` marca a função, e `await` só pode ser usado dentro de uma função `async`. O `await` pausa **aquela função** até o resultado chegar, e o app segue funcionando
- em `_storage.salvar(_itens);` não usamos `await`: disparamos a gravação e seguimos em frente. O `initState` não pode ser `async`, então ele também chama `_carregar()` sem esperar
- depois de um `await`, a tela pode ter sido fechada. O `if (!mounted) return;` evita chamar `setState` numa tela que já não existe

### 10. Imports, bibliotecas e convenções

| Forma do import | Exemplo | De onde vem |
| --- | --- | --- |
| `dart:` | `import 'dart:convert';` | bibliotecas que já vêm com o Dart (aqui: `jsonEncode` e `jsonDecode`) |
| `package:` | `import 'package:flutter/material.dart';` | pacotes: o Flutter, o pub.dev ou o seu próprio projeto |
| caminho relativo | `import 'models/item.dart';` | outro arquivo do seu projeto |

Convenções de nomes:

- classes em `UpperCamelCase`: `ListaPage`, `Item`
- variáveis, métodos e parâmetros em `lowerCamelCase`: `quantidade`, `_adicionar`
- arquivos em `snake_case`: `lista_storage.dart`
- **vírgula no fim** de uma lista de argumentos: o formatador do Dart (`Shift+Alt+F` no VS Code) usa a vírgula para quebrar o código em linhas e deixá-lo legível

### 11. Exercício de leitura: decifrando uma linha

Esta linha reúne quase tudo que vimos:

```dart
onDismissed: (_) => _atualizar(() => _itens.remove(item)),
```

| Pedaço | O que é |
| --- | --- |
| `onDismissed:` | parâmetro **nomeado** do `Dismissible`, que espera receber uma função |
| `(_)` | início de uma **lambda** com um parâmetro que ignoramos (a direção do gesto) |
| `=>` | “devolve”: o corpo da lambda é uma única expressão |
| `_atualizar(...)` | nosso método **privado**, que faz `setState` e grava no aparelho |
| `() => _itens.remove(item)` | outra lambda, sem parâmetros: é o `VoidCallback` com a alteração a executar |
| `_itens.remove(item)` | remove o item da lista (devolve um `bool`, que aqui é ignorado) |

Leia em voz alta: *“quando o item for dispensado, atualize a lista removendo esse item”*.

**Desafio para a turma:** escolham outras duas linhas do `main.dart` final e decifrem do mesmo jeito, apontando o conceito de cada pedaço.

## Passo 1: Criar o projeto e rodar o primeiro app

O comando `flutter create` gera um projeto completo, já com um app de exemplo funcionando. Escolha uma pasta de trabalho e rode:

```bash
flutter create lista_compras
cd lista_compras
code .
```

- `flutter create` cria a pasta do projeto com todas as plataformas
- o nome precisa ser em minúsculas, com `_` entre as palavras (é o nome do *pacote* Dart)
- `code .` abre a pasta no VS Code

A pasta que mais importa para nós é a `lib/`, onde fica o código do app. O arquivo `pubspec.yaml` lista as dependências, e a pasta `test/` guarda os testes.

### Limpar o `main.dart`

O exemplo gerado é um contador, que não vamos usar. Abra `lib/main.dart`, apague tudo e escreva:

```dart
import 'package:flutter/material.dart';

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
      home: const Scaffold(
        body: Center(child: Text('Olá, compras!')),
      ),
    );
  }
}
```

O exemplo gerado também criou o arquivo `test/widget_test.dart`, que testa o contador e **vai dar erro** agora. **Apague esse arquivo** (botão direito no VS Code, *Delete*). Voltaremos aos testes no passo 9.

### Rodar o app

```bash
flutter run -d chrome
```

No VS Code, também dá para abrir o `main.dart` e apertar **F5**, escolhendo o dispositivo na barra de status (canto inferior direito).

**Resultado esperado:** uma página com o texto *Olá, compras!* no centro.

**Pense antes:** troque o texto para `'Minha lista'` e salve o arquivo com Ctrl+S. O que você espera ver? Isso se chama *hot reload*: o Flutter troca o código em execução sem reiniciar o app. No terminal, `r` faz hot reload e `R` faz hot restart (reinicia o app e zera o estado).

> **Nota para o professor:** no Flutter 3.47, o Material também existe como pacote separado (`material_ui`), de adoção opcional por enquanto. O import `package:flutter/material.dart`, usado neste guia, continua funcionando. Detalhes em [Migrate to standalone material\_ui and cupertino\_ui packages](https://docs.flutter.dev/release/breaking-changes/material-ui-and-cupertino-ui).

## Passo 2: A estrutura da tela (Stateless x Stateful)

No Flutter, tudo que aparece na tela é um *widget*. Há dois tipos de widget de tela:

|  | `StatelessWidget` | `StatefulWidget` |
| --- | --- | --- |
| Analogia | Uma foto: não muda | Um quadro branco: pode ser reescrito |
| Guarda dados que mudam? | Não | Sim, na classe `State` |
| Exemplo no app | `ListaComprasApp` (só configura o tema) | `ListaPage` (a lista muda a cada toque) |

Um `StatefulWidget` sempre vem em **duas classes**: o widget (a configuração, que não muda) e o `State` (os dados e o método `build`, que desenha a tela). O Flutter só redesenha quando chamamos `setState`.

Em `lib/main.dart`, troque o `home` do `MaterialApp` por `const ListaPage()` e acrescente as duas classes abaixo, no fim do arquivo:

```dart
      home: const ListaPage(),
```

```dart
class ListaPage extends StatefulWidget {
  const ListaPage({super.key});

  @override
  State<ListaPage> createState() => _ListaPageState();
}

class _ListaPageState extends State<ListaPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lista de Compras')),
      body: const Center(child: Text('Nada por aqui ainda')),
    );
  }
}
```

- `Scaffold` é o esqueleto de uma tela Material: barra superior (`appBar`), corpo (`body`) e outros pontos de encaixe
- o `_` no início de `_ListaPageState` torna a classe privada ao arquivo
- `const` diz ao Flutter que o widget nunca muda, o que o poupa de reconstruí-lo

**Resultado esperado:** uma barra no topo com o título *Lista de Compras* e a mensagem *Nada por aqui ainda* no centro.

**Pense antes:** por que a tela da lista precisa ser `Stateful`, e o `MaterialApp` não?

## Passo 3: O modelo `Item` e uma lista fixa

Um app precisa de um jeito de representar os dados. Em vez de guardar só textos, criamos uma **classe** que descreve um item da lista: um nome, uma quantidade e se já foi comprado.

Crie a pasta `lib/models/` e dentro dela o arquivo `item.dart`:

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
}
```

- `final` significa que o valor não muda depois de criado (`id` e `nome`)
- `quantidade` e `comprado` não são `final`, pois mudam ao longo do uso
- o `id` identifica cada item de forma única; vamos precisar dele para remover itens e para salvar
- `required` obriga quem cria o `Item` a informar o campo; `this.quantidade = 1` define um valor padrão

Agora use o modelo na tela. No topo do `main.dart`, acrescente o import e, em seguida, substitua a classe `_ListaPageState` inteira:

```dart
import 'models/item.dart';
```

```dart
class _ListaPageState extends State<ListaPage> {
  final List<Item> _itens = [
    Item(id: '1', nome: 'Arroz'),
    Item(id: '2', nome: 'Feijão', quantidade: 2),
    Item(id: '3', nome: 'Café'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lista de Compras')),
      body: ListView.builder(
        itemCount: _itens.length,
        itemBuilder: (context, i) {
          final item = _itens[i];
          return ListTile(
            title: Text(item.nome),
            subtitle: Text('Quantidade: ${item.quantidade}'),
          );
        },
      ),
    );
  }
}
```

- `ListView.builder` cria os itens **sob demanda**: só desenha os que cabem na tela, o que funciona bem mesmo com listas enormes
- o `itemBuilder` é chamado uma vez por posição `i`, de 0 até `itemCount - 1`
- `'${item.quantidade}'` insere o valor de uma variável dentro de um texto

**Resultado esperado:** três linhas na tela: *Arroz*, *Feijão* (quantidade 2) e *Café*.

**Pense antes:** se dois itens tivessem o mesmo nome, como o app saberia qual deles remover? É por isso que existe o `id`.

## Passo 4: Adicionar itens

Agora a lista deixa de ser fixa. O usuário digita o nome e toca em *Adicionar*. Substitua a classe `_ListaPageState` inteira (a lista agora começa vazia):

```dart
class _ListaPageState extends State<ListaPage> {
  final _controller = TextEditingController();
  final List<Item> _itens = [];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _adicionar() {
    final nome = _controller.text.trim();
    if (nome.isEmpty) return;
    setState(() {
      _itens.add(
        Item(id: DateTime.now().microsecondsSinceEpoch.toString(), nome: nome),
      );
    });
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lista de Compras')),
      body: Column(
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
                      return ListTile(
                        title: Text(item.nome),
                        subtitle: Text('Quantidade: ${item.quantidade}'),
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

O que há de novo:

- `TextEditingController` lê (e limpa) o que o usuário digitou. Como ele guarda recursos, liberamos no `dispose`
- `trim()` tira espaços das pontas, e `isEmpty` impede adicionar item vazio
- **`setState`** é o coração do passo: avisa ao Flutter que os dados mudaram e que a tela precisa ser redesenhada
- `Expanded` dentro do `Row` dá ao campo de texto o espaço que sobra ao lado do botão; dentro da `Column`, faz a lista ocupar o resto da tela
- `onSubmitted` faz a tecla Enter também adicionar o item
- o `id` vem da hora atual em microssegundos, que na prática nunca se repete

**Resultado esperado:** digitar *Leite*, tocar em *Adicionar* e ver *Leite* aparecer na lista, com o campo limpo.

**Pense antes:** o que aconteceria se tirássemos o `setState` e deixássemos só `_itens.add(...)`? (Teste e observe: a lista muda, mas a tela não.)

### Checkpoint 1

Até aqui o `main.dart` tem: o import do Material, o import do `Item`, `main()`, `ListaComprasApp`, `ListaPage` e esta `_ListaPageState`. Se a turma travar, compare com o código final no fim do documento. Ele só difere por mais recursos nas linhas da lista e pelo armazenamento.

## Passo 5: Marcar como comprado

Troque o `ListTile` por um `CheckboxListTile`, que já traz a caixa de seleção embutida. No `itemBuilder`, substitua o `return ListTile(...)` por:

```dart
                      return CheckboxListTile(
                        value: item.comprado,
                        onChanged: (marcado) {
                          setState(() => item.comprado = marcado ?? false);
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                        title: Text(
                          item.nome,
                          style: TextStyle(
                            decoration: item.comprado
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        subtitle: Text('Quantidade: ${item.quantidade}'),
                      );
```

- `value` diz se a caixa está marcada, e `onChanged` roda quando o usuário toca nela
- `marcado` é do tipo `bool?` (pode ser nulo), por isso o `?? false`: se vier nulo, usamos `false`
- `controlAffinity: leading` põe a caixa à esquerda do texto
- `condição ? A : B` é o operador ternário: se `item.comprado` for verdadeiro, risca o texto; senão, não aplica nenhum efeito (`null`)

**Resultado esperado:** ao tocar numa linha, a caixa marca e o nome fica riscado. Tocando de novo, volta ao normal.

**Pense antes:** por que o estado *comprado* fica dentro do `Item`, e não dentro do widget da linha? Dica: o `ListView.builder` descarta e recria as linhas que saem da tela, e depois vamos precisar salvar esse estado.

## Passo 6: Remover itens

Vamos remover de duas formas: arrastando um item para o lado e com um botão que limpa todos os comprados.

**1. Arrastar para remover.** Envolva o `CheckboxListTile` com um `Dismissible`. O `itemBuilder` inteiro passa a ficar assim:

```dart
                    itemBuilder: (context, i) {
                      final item = _itens[i];
                      return Dismissible(
                        key: ValueKey(item.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 16),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (_) => setState(() => _itens.remove(item)),
                        child: CheckboxListTile(
                          value: item.comprado,
                          onChanged: (marcado) {
                            setState(() => item.comprado = marcado ?? false);
                          },
                          controlAffinity: ListTileControlAffinity.leading,
                          title: Text(
                            item.nome,
                            style: TextStyle(
                              decoration: item.comprado
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                          subtitle: Text('Quantidade: ${item.quantidade}'),
                        ),
                      );
                    },
```

- o `key` é obrigatório e precisa ser **único por item**: é por ele que o Flutter sabe qual linha foi arrastada. Aqui usamos o `id`
- `endToStart` permite arrastar só da direita para a esquerda
- `background` é o fundo vermelho com a lixeira que aparece enquanto se arrasta
- `onDismissed` roda quando o gesto termina. **É obrigatório remover o item da lista aqui**; senão, o Flutter reclama que o widget ainda está na árvore

**2. Botão de limpar comprados.** Na `AppBar`, acrescente a lista `actions`:

```dart
      appBar: AppBar(
        title: const Text('Lista de Compras'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Remover comprados',
            onPressed: () =>
                setState(() => _itens.removeWhere((i) => i.comprado)),
          ),
        ],
      ),
```

`removeWhere` percorre a lista e remove todo item para o qual a condição `i.comprado` é verdadeira.

**Resultado esperado:** arrastar um item para a esquerda o remove. Marcar dois itens e tocar na vassoura na barra superior remove os dois de uma vez.

**Pense antes:** no `ListTile` simples do passo 3 não precisávamos de `key`. Por que o `Dismissible` precisa?

## Passo 7: Controlar a quantidade

O `CheckboxListTile` tem um espaço chamado `secondary`, que fica do lado oposto à caixa de seleção. Vamos colocar ali os botões **−** e **+**. Dentro do `CheckboxListTile`, logo depois do `subtitle`, acrescente:

```dart
                          secondary: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove),
                                onPressed: item.quantidade > 1
                                    ? () => setState(() => item.quantidade--)
                                    : null,
                              ),
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: () =>
                                    setState(() => item.quantidade++),
                              ),
                            ],
                          ),
```

- `mainAxisSize: MainAxisSize.min` faz o `Row` ocupar só o espaço dos dois botões
- `item.quantidade++` soma 1, e `item.quantidade--` subtrai 1
- quando `onPressed` é `null`, o botão fica **desabilitado** (acinzentado). Usamos isso para impedir quantidades menores que 1

**Resultado esperado:** cada linha mostra os botões − e + à direita. O + aumenta a quantidade; o − diminui e fica desabilitado quando a quantidade é 1.

**Pense antes:** o que mudaria se, em vez de desabilitar o botão, deixássemos a quantidade chegar a 0 ou a números negativos? Onde mais no app essa regra poderia ficar guardada?

## Passo 8: Persistir os dados com `shared_preferences`

**O problema.** Adicione alguns itens, pare o app e rode de novo: a lista voltou vazia. Os dados estão na memória (`_itens`), e a memória é apagada quando o app fecha. Precisamos de um lugar onde guardar.

**A escolha.** Para uma lista pequena de texto, o pacote `shared_preferences` é a opção mais simples: guarda pares *chave → valor* no aparelho (no navegador, usa o armazenamento local). Ele só aceita tipos simples (texto, número, `bool`, lista de textos). Por isso vamos transformar a lista inteira em **um único texto JSON** e guardá-lo numa chave. Na seção final há uma comparação com outras opções (SQLite, Hive etc.) para quando a lista crescer.

> **Qual API usar?** Desde a versão 2.3.0, o pacote tem três APIs, e a documentação recomenda a `SharedPreferencesAsync` (ou a `WithCache`) para código novo. Usamos a `SharedPreferencesAsync`. Tutoriais antigos usam `SharedPreferences.getInstance()`: funciona, mas guarda os dados num lugar diferente no Android, então **não misture as duas no mesmo app**. Fonte: [shared\_preferences no pub.dev](https://pub.dev/packages/shared_preferences).

### Como o `shared_preferences` funciona

O `shared_preferences` é um **plugin**: um pacote com código Dart e também código nativo de cada sistema (Android, iOS, navegador e outros). Para quem programa, ele oferece uma interface única. Por baixo, cada plataforma usa o seu próprio mecanismo de armazenamento de preferências.

A ideia é a de um **armário de gavetas etiquetadas**: cada gaveta tem uma *chave* (a etiqueta) e guarda um *valor*. Nosso app usa uma única gaveta, de chave `lista_compras`, que guarda o texto JSON com todos os itens.

| Plataforma | Onde os dados ficam |
| --- | --- |
| Android | armazenamento de preferências do Android (DataStore nas APIs novas; SharedPreferences na API antiga) |
| iOS e macOS | `NSUserDefaults` |
| Web | `localStorage` do navegador |
| Windows e Linux | um arquivo na pasta de dados do usuário |

Fonte: documentação do pacote no [pub.dev](https://pub.dev/packages/shared_preferences).

**O caminho de um salvamento, no nosso app:**

1. a tela chama `_storage.salvar(_itens)` depois de qualquer mudança
2. a `ListaStorage` transforma a lista em texto com `jsonEncode`
3. `setString('lista_compras', texto)` envia o texto para a plataforma, por um canal de comunicação entre o Dart e o código nativo
4. o código nativo grava o texto no armazenamento do sistema
5. ao reabrir o app, `getString('lista_compras')` faz o caminho inverso e devolve o texto, que o `fromJson` converte de volta em itens

**O que ele sabe guardar.** Só cinco tipos simples, cada um com um par de métodos:

| Tipo | Gravar | Ler |
| --- | --- | --- |
| `String` | `setString` | `getString` |
| `int` | `setInt` | `getInt` |
| `double` | `setDouble` | `getDouble` |
| `bool` | `setBool` | `getBool` |
| `List<String>` | `setStringList` | `getStringList` |

Por isso um `Item`, ou uma `List<Item>`, não pode ser guardado direto: convertemos para texto JSON primeiro. Além desses, há `remove(chave)` para apagar uma gaveta, `containsKey(chave)` para saber se ela existe, `getKeys()` para listar as chaves e `clear()` para apagar tudo.

```dart
final prefs = SharedPreferencesAsync();

await prefs.setString('apelido', 'Ana');
await prefs.setInt('visitas', 3);

final apelido = await prefs.getString('apelido');      // 'Ana'
final visitas = await prefs.getInt('visitas');         // 3
final nada = await prefs.getString('nao_existe');      // null

await prefs.remove('apelido');
```

Toda leitura devolve `null` quando a chave não existe. Foi esse o caso da primeira execução do nosso app, tratado em `if (texto == null) return [];`.

**As três APIs do pacote:**

| API | Como funciona | Quando usar |
| --- | --- | --- |
| `SharedPreferencesAsync` | sem cache: toda leitura vai ao armazenamento nativo, e todos os métodos são assíncronos | código novo; é a que usamos |
| `SharedPreferencesWithCache` | mantém uma cópia em memória, e a leitura depois de criada é imediata | quando há muitas leituras seguidas |
| `SharedPreferences` (antiga) | cache em memória, criada com `SharedPreferences.getInstance()` | código antigo |

**Cuidados:**

- **não é criptografado.** Nunca guarde senhas ou tokens de login nele; para isso existe o `flutter_secure_storage`
- os dados somem se o app for desinstalado ou se o usuário limpar os dados do app (ou do navegador)
- **não é um banco de dados.** A cada mudança gravamos a lista inteira de novo, o que é ótimo para dezenas de itens e ruim para milhares. Não há como buscar ou filtrar sem ler tudo
- o valor é um texto: se o formato do `Item` mudar (um campo novo, por exemplo), os dados já salvos continuam no formato antigo. Veja o exercício 3

### 8.1 Instalar o pacote

```bash
flutter pub add shared_preferences
```

O comando baixa o pacote e acrescenta uma linha parecida com `shared_preferences: ^2.5.4` na seção `dependencies` do `pubspec.yaml` (o número da versão pode ser mais novo). Se o app estiver rodando, pare e rode de novo: plugins nativos não entram com hot reload.

### 8.2 Ensinar o `Item` a virar JSON

JSON é um formato de texto para dados. Um `Item` ficaria assim:

```json
{"id": "1", "nome": "Arroz", "quantidade": 1, "comprado": false}
```

Em `lib/models/item.dart`, acrescente dois métodos **dentro** da classe `Item`, depois dos campos:

```dart
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
```

- `toJson` transforma o objeto num `Map` (um dicionário chave → valor)
- `fromJson` faz o caminho inverso: lê o `Map` e cria um `Item`. `factory` é um construtor que pode devolver um objeto montado a partir de outros dados
- `as String`, `as int` e `as bool` dizem ao Dart o tipo de cada valor que veio do JSON

### 8.3 Isolar o armazenamento numa classe

Crie o arquivo `lib/lista_storage.dart`. Toda a conversa com o `shared_preferences` fica **só aqui**; a tela não precisa saber como os dados são guardados:

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

- `Future` e `async`/`await`: ler do aparelho leva um instante, então a função devolve uma *promessa* de resultado. `await` espera essa promessa ser cumprida sem travar a tela
- na primeira execução não existe nada salvo: `getString` devolve `null`, e devolvemos uma lista vazia
- `jsonEncode(itens)` transforma a lista em texto. Ele chama o `toJson()` de cada `Item` automaticamente
- `jsonDecode` faz o inverso; depois usamos `fromJson` em cada elemento

### 8.4 Ligar o armazenamento à tela

No `main.dart`, acrescente `import 'lista_storage.dart';` junto dos outros imports. Depois faça estas alterações na `_ListaPageState`.

**a) Novos campos e métodos**, logo abaixo de `final List<Item> _itens = [];`:

```dart
  final _storage = ListaStorage();
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregar();
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
```

- `initState` roda **uma vez**, quando a tela nasce: é o lugar certo para carregar os dados
- `if (!mounted) return;` evita mexer numa tela que foi fechada enquanto esperávamos a leitura
- `_atualizar` é um atalho: faz o `setState` **e** salva. Assim, toda mudança na lista é gravada

**b) Troque `setState(` por `_atualizar(` nos 6 lugares** em que o usuário muda a lista: em `_adicionar`, no botão de remover comprados, no `onDismissed`, no `onChanged` do checkbox e nos botões − e +. Exemplo:

```dart
// antes
onDismissed: (_) => setState(() => _itens.remove(item)),
// depois
onDismissed: (_) => _atualizar(() => _itens.remove(item)),
```

**c) Mostrar um indicador enquanto carrega.** No `body` do `Scaffold`, inclua o teste de `_carregando` antes da `Column`:

```dart
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // ... o mesmo conteúdo de antes ...
              ],
            ),
```

### 8.5 Testar a persistência

1. Rode o app, adicione três itens, marque um e mude uma quantidade.
2. No terminal do `flutter run`, aperte **R** (hot restart). O app reinicia do zero e a lista deve voltar do jeito que estava.
3. Para o teste definitivo, pare o app (**Shift+F5** no VS Code) e rode de novo.

**Resultado esperado:** os itens, as marcações e as quantidades reaparecem depois de reiniciar.

> **No Chrome:** os dados ficam presos ao endereço da página (incluindo a porta). Se, ao parar e rodar de novo, a lista vier vazia, o Flutter pode ter aberto numa porta diferente. Fixe a porta: `flutter run -d chrome --web-port=5000`.

**Pense antes:** quais são as vantagens de a tela chamar `_storage.salvar(...)` em vez de usar o `SharedPreferencesAsync` diretamente? O que você teria de mudar na tela se um dia trocássemos por um banco de dados?

### Checkpoint 2

O app está completo. O `main.dart` deve ficar igual ao **código final** no fim deste documento.

## Passo 9: Testar o modelo

De tudo que fizemos, a conversão para JSON é a parte mais frágil: se alguém trocar o nome de uma chave em `toJson` e esquecer o `fromJson`, o app quebra na hora de ler os dados salvos. Vale a pena um teste automatizado que garanta que um `Item` **sobrevive à ida e volta**.

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

- `test` define um caso de teste, e `expect(valor, esperado)` falha se os dois forem diferentes
- `lista_compras` no import é o nome do pacote, o mesmo que demos no `flutter create`
- o teste não usa o `shared_preferences`: ele só testa a conversão, que é Dart puro

**Resultado esperado:** o terminal termina com *All tests passed!*

**Pense antes:** troque `'quantidade'` por `'qtd'` apenas dentro do `toJson` e rode o teste de novo. O que acontece? Esse é o erro que o teste existe para pegar. Depois desfaça a troca.

## Erros comuns

| Sintoma | Causa provável | Solução |
| --- | --- | --- |
| `flutter test` falha dizendo que `MyApp` não existe | sobrou o `test/widget_test.dart` do exemplo | apagar esse arquivo (passo 1) |
| `Target of URI doesn't exist: package:shared_preferences/...` | o pacote não foi instalado | `flutter pub add shared_preferences` |
| `MissingPluginException` ao abrir ou salvar | o plugin foi instalado com o app já rodando | parar o app e rodar de novo (hot reload não basta) |
| `Vertical viewport was given unbounded height` | `ListView` dentro de `Column` sem `Expanded` | envolver o `ListView` em `Expanded` (passo 4) |
| Erro de largura infinita no `TextField` | `TextField` dentro de `Row` sem `Expanded` | envolver o `TextField` em `Expanded` (passo 4) |
| `A dismissed Dismissible widget is still part of the tree` | o item não foi removido da lista no `onDismissed` | remover o item dentro do `onDismissed` (passo 6) |
| A tela não muda ao adicionar ou marcar | a lista foi alterada fora do `setState` | alterar sempre dentro de `_atualizar` ou `setState` |
| A lista volta vazia ao reabrir no Chrome | o navegador abriu em outra porta, e os dados são por endereço | `flutter run -d chrome --web-port=5000` |
| `type 'Null' is not a subtype of type 'int'` ao carregar | os dados salvos não têm um campo que o `fromJson` agora exige | limpar os dados do navegador ou do app, ou aceitar o valor ausente (`json['campo'] as int? ?? 1`) |

## Resumo de comandos

| Comando | Para que serve |
| --- | --- |
| `flutter doctor` | confere se o ambiente está pronto |
| `flutter create lista_compras` | cria o projeto |
| `flutter pub add shared_preferences` | instala o pacote de armazenamento |
| `flutter pub get` | baixa as dependências listadas no `pubspec.yaml` |
| `flutter run -d chrome` | roda o app no Chrome |
| `flutter devices` | lista os dispositivos disponíveis |
| `flutter test` | roda os testes automatizados |
| `flutter analyze` | procura problemas no código |
| tecla `r` / `R` no terminal | hot reload / hot restart |

## Onde guardar os dados: comparação

O `shared_preferences` resolveu bem este app. Conforme os dados crescem, vale conhecer as outras opções:

| Opção | Quando usar | Limite |
| --- | --- | --- |
| `shared_preferences` | configurações e listas pequenas | só tipos simples; sem consultas; lê e grava tudo de uma vez |
| `flutter_secure_storage` | dados sensíveis, como tokens de login | não serve para listas grandes |
| SQLite, com `drift` ou `sqflite` | muitos registros, filtros, ordenação, relacionamentos | exige modelar tabelas e escrever consultas |
| Banco na nuvem, como Firebase ou Supabase | sincronizar entre aparelhos e usuários | precisa de conta, rede e backend |

Como isolamos tudo na `ListaStorage`, trocar de opção significa mudar **só esse arquivo**.


## Código final completo (gabarito)

Estrutura do projeto ao final:

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

### `lib/models/item.dart`

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

### `lib/lista_storage.dart`

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

### `lib/main.dart`

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

### `test/item_test.dart`

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

## Como testar no emulador ou no celular Android

Até aqui rodamos no Chrome. Para ver o app como ele é de verdade, rode no Android. Há duas opções: um emulador (celular virtual no computador) ou o seu próprio celular.

### Preparar o Android (uma única vez)

1. Instale o [Android Studio](https://developer.android.com/studio) e abra-o uma vez, aceitando o assistente de instalação (ele baixa o Android SDK).
2. Aceite as licenças e confira o ambiente:

   ```bash
   flutter doctor --android-licenses
   flutter doctor
   ```

3. A seção *Android toolchain* do `flutter doctor` deve ficar sem ✗. Se aparecer `cmdline-tools component is missing`, no Android Studio vá em *Settings > Languages & Frameworks > Android SDK > SDK Tools* e marque **Android SDK Command-line Tools**.

### Opção A: emulador Android

1. **Criar o emulador** (só na primeira vez): no Android Studio, abra *More Actions > Virtual Device Manager* (ou *Tools > Device Manager*), clique em **Create Device**, escolha um modelo (por exemplo, *Pixel 8*), escolha uma imagem do sistema (baixe se pedir) e finalize.
2. No VS Code, abra a pasta `lista_compras`.
3. Aperte **Ctrl+Shift+P**, digite **Flutter: Launch Emulator** e escolha o emulador criado. Aguarde a tela do Android aparecer.
4. Na **barra de status** (canto inferior direito do VS Code), confirme que o emulador aparece como dispositivo. Se não aparecer, clique no dispositivo atual e escolha o emulador.
5. Abra `lib/main.dart` e aperte **F5** (ou *Run > Start Debugging*). Se pedir o ambiente, escolha **Dart & Flutter**.
6. Aguarde a primeira compilação (pode levar alguns minutos). O app abre no emulador.
7. Para parar, **Shift+F5**. Salvar o código (**Ctrl+S**) aplica a mudança na hora (hot reload).

Pelo terminal:

```bash
flutter emulators
flutter emulators --launch NOME_DO_EMULADOR
flutter run
```

### Opção B: o seu próprio celular Android

1. **Modo desenvolvedor:** *Configurações > Sobre o telefone* e toque 7 vezes em **Número da versão**.
2. **Depuração USB:** *Configurações > Sistema > Opções do desenvolvedor > Depuração USB*.
3. Conecte o celular ao computador com um cabo USB que transfira dados (não só carregue).
4. No celular, aceite a janela **Permitir depuração USB?** (marque *Sempre permitir*).
5. Confirme que o celular foi reconhecido:

   ```bash
   flutter devices
   ```

   O modelo do celular deve aparecer na lista. Se não aparecer, troque o cabo ou a porta USB.
6. No VS Code, clique no dispositivo na **barra de status** e escolha o celular.
7. Abra `lib/main.dart` e aperte **F5**. O app é instalado e abre no celular.
8. Para parar, **Shift+F5**. Com o app aberto, **Ctrl+S** atualiza o celular na hora.

Pelo terminal:

```bash
flutter devices
flutter run -d ID_DO_CELULAR
```

Sem cabo (Android 11 ou mais novo, celular e computador na mesma rede Wi-Fi): em *Opções do desenvolvedor*, ative **Depuração por Wi-Fi**, escolha *Parear dispositivo com código* e rode:

```bash
adb pair IP:PORTA_DE_PAREAMENTO
adb connect IP:PORTA
flutter devices
```

### Confirmar a persistência no Android

1. Adicione três itens, marque um e mude uma quantidade.
2. Pare o app (**Shift+F5**) e rode de novo (**F5**).
3. Os itens, as marcações e as quantidades devem reaparecer.

| Sintoma | Solução |
| --- | --- |
| Celular não aparece em `flutter devices` | conferir a depuração USB, aceitar a janela no celular, trocar o cabo |
| Emulador não aparece na barra de status | `flutter emulators --launch NOME` e esperar a tela do Android carregar |
| Primeira execução muito lenta | normal: o Gradle baixa dependências; as próximas são rápidas |
