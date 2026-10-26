# Aula 15 — Flutter: tutorial integrador com SQLite, arquitetura em camadas e distribuição do APK



## Objetivos da aula

- Preparar o ambiente de desenvolvimento Flutter para Android no Windows, com VS Code.
- Construir um aplicativo completo que integre os conceitos das Aulas 11 a 14: árvore de widgets e responsividade, arquitetura em camadas e gerenciamento de estado, camada de dados com SQLite e conectividade intermitente, navegação declarativa, ligação profunda e canal de plataforma.
- Executar e testar o aplicativo por diferentes meios: emulador, dispositivo físico, testes automatizados e roteiro de testes manuais.
- Gerar o APK e instalá-lo por diferentes meios.

## Organização da aula

A Aula 9 construiu uma lista de compras em um único arquivo, com os dados gravados como texto JSON no `shared_preferences`. A solução era adequada para apresentar o Flutter, mas reúne no mesmo `State` a interface, as regras e o armazenamento, exatamente a mistura de responsabilidades criticada na Aula 12. Esta aula reconstrói o mesmo aplicativo com a arquitetura estudada nas Aulas 11 a 14 e com um banco de dados relacional (SQLite).

O tutorial segue a ordem em que um projeto real é montado: ambiente (§1), arquitetura e estrutura de pastas (§2 e §3), criação e identidade do projeto (Passos 1 e 2), camadas de domínio, dados e apresentação (Passos 3 a 9), execução (§4), testes (§5) e distribuição do APK (§6). Cada passo informa o arquivo a criar, o código completo a copiar e a justificativa técnica das decisões.

| Aspecto | Aula 9 | Aula 15 |
|---|---|---|
| Organização do código | Um arquivo (`main.dart`) com tudo | Camadas de apresentação, domínio e dados (Aula 12) |
| Estado | `setState` em um único `StatefulWidget` | Riverpod: `AsyncNotifier`, `Notifier` e `AsyncValue` (Aula 12) |
| Persistência | Lista inteira como texto JSON no `shared_preferences` | Tabela SQLite, com gravação e leitura por registro (Aula 13) |
| Rede | Inexistente | Servidor simulado, sincronização com nova tentativa e detecção de conectividade (Aula 13) |
| Navegação | Uma única tela | Rotas declarativas, ligação profunda e confirmação ao sair de formulário (Aula 14) |
| Integração nativa | Inexistente | Canal de plataforma em Kotlin (Aula 14) |
| Responsividade | Lista de largura única | Grade de 1, 2 ou 3 colunas conforme a largura (Aulas 3 e 11) |
| Testes | Um teste de conversão JSON | Testes de domínio, de repositório com SQLite em memória e de interface |

### Funcionalidades do aplicativo final

- cadastrar itens com nome, categoria, quantidade e observação, com validação dos campos;
- marcar itens como comprados e excluí-los com gesto de arrastar;
- editar um item em uma tela própria, com confirmação antes de descartar alterações não salvas;
- manter os dados em um banco SQLite no aparelho;
- enviar as alterações a um servidor (simulado), com nova tentativa automática e indicação de itens pendentes;
- exibir um aviso quando não há rede e sincronizar automaticamente quando a conexão retorna;
- abrir um item diretamente por um endereço `compras://app/item/<id>`;
- exibir, na tela "Sobre", a identificação do aplicativo e da autoria, dados do aparelho obtidos por código Kotlin e a data de criação do banco local.

### Mapa de conceitos

| Aula | Conceito | Onde aparece no código |
|---|---|---|
| 3 | Pontos de quebra de 600 e 840 dp | `tela_lista.dart` (`LayoutBuilder`), largura máxima dos formulários |
| 4 | Escala de fonte, rótulos para leitor de tela | `MediaQuery.textScalerOf`, `semanticLabel`, `tooltip`, `Semantics(liveRegion:)` |
| 6 | Tema claro e escuro, área segura | `theme` e `darkTheme` em `app.dart`, `SafeArea` |
| 10 | Cor semente e tokens de cor e tipografia | `ColorScheme.fromSeed`, `colorScheme.*`, `textTheme.*` |
| 11 | Árvore de widgets, `LayoutBuilder`, `MediaQuery`, hot reload, DevTools | Telas e componentes; §4 |
| 12 | Camadas, gerenciamento de estado, `AsyncValue`, testes de domínio | `dominio/`, `providers.dart`, `test/dominio/` |
| 13 | Repositório, serialização, persistência local, sincronização, backoff com jitter, estado offline | `dados/`, `faixa_offline.dart` |
| 14 | Rotas declarativas e aninhadas, ligação profunda, `PopScope`, `MethodChannel` | `rotas.dart`, `AndroidManifest.xml`, `tela_item.dart`, `MainActivity.kt` |

## 1. Preparação do ambiente no Windows com VS Code


### 1.1 Requisitos da máquina

| Recurso | Mínimo | Recomendado | Justificativa |
|---|---|---|---|
| Sistema | Windows 10 64 bits | Windows 11 | Ferramentas Android são distribuídas apenas para 64 bits |
| Memória | 8 GB | 16 GB | O emulador reserva de 2 a 4 GB; o Gradle, outros 2 GB |
| Disco livre | 15 GB | 30 GB | SDK Android, imagens do emulador e cache do Gradle |
| Virtualização | Habilitada | Habilitada | Sem ela, o emulador não inicia ou fica inutilizável |

Para conferir a virtualização, abrir o Gerenciador de Tarefas, aba **Desempenho > CPU**, e verificar o campo **Virtualização: Habilitado**. Se constar "Desabilitado", é necessário ativá-la no firmware (BIOS/UEFI) do computador, em uma opção geralmente chamada *Intel VT-x*, *Intel Virtualization Technology* ou *AMD SVM*.

### 1.2 Git

O Flutter usa o Git para se atualizar e para baixar alguns pacotes. Instalar o [Git para Windows](https://git-scm.com/download/win) ou, pelo terminal:

```powershell
winget install --id Git.Git -e
```

### 1.3 VS Code e extensões

1. Instalar o [VS Code](https://code.visualstudio.com/).
2. Na barra lateral, abrir **Extensões** (`Ctrl+Shift+X`), procurar **Flutter** (publicador *Dart Code*) e instalar. A extensão **Dart** é instalada junto.
3. Recomenda-se ativar a formatação ao salvar: `Ctrl+,`, procurar **Format On Save** e marcar a opção. O formatador do Dart usa as vírgulas finais para quebrar as linhas, o que mantém o código legível sem ajuste manual.

### 1.4 SDK do Flutter

Há duas formas de instalação:

- **Pelo VS Code:** `Ctrl+Shift+P`, comando **Flutter: New Project**. Como o SDK ainda não existe, a extensão oferece **Download SDK**. Escolher uma pasta como `C:\dev` e aceitar a opção **Add SDK to PATH** ao final.
- **Manual:** baixar o arquivo `.zip` em [docs.flutter.dev/install](https://docs.flutter.dev/install), extrair em `C:\dev\flutter` e incluir `C:\dev\flutter\bin` na variável `Path` do usuário (menu Iniciar, "Editar as variáveis de ambiente para sua conta").

Em qualquer caso, convém evitar caminhos com espaços, acentos ou que exijam permissão de administrador (como `C:\Program Files`). O mesmo vale para a pasta dos projetos: o Gradle, ferramenta de build do Android, falha em caminhos com caracteres especiais. Recomenda-se `C:\dev\projetos`.

Para confirmar a instalação, abrir um **novo** terminal (as variáveis de ambiente só são lidas na abertura) e executar:

```powershell
flutter --version
```

### 1.5 Android Studio, SDK e emulador

O Android Studio não será o editor, mas é a forma mais simples de obter o SDK do Android, o emulador e as ferramentas de linha de comando.

1. Instalar o [Android Studio](https://developer.android.com/studio) e abri-lo uma vez. O assistente inicial (*Setup Wizard*, modo *Standard*) baixa o SDK, o emulador e as *platform-tools* (que incluem o `adb`).
2. Em **More Actions > SDK Manager**, aba **SDK Tools**, marcar **Android SDK Command-line Tools (latest)** e aplicar. Sem esse componente, o `flutter doctor` não consegue aceitar as licenças.
3. Aceitar as licenças do SDK, respondendo `y` a cada pergunta:

   ```powershell
   flutter doctor --android-licenses
   ```

4. Para usar o `adb` diretamente no terminal (necessário nas §5 e §6), incluir no `Path` do usuário a pasta `%LOCALAPPDATA%\Android\Sdk\platform-tools`.

### 1.6 Modo de desenvolvedor do Windows

Projetos com *plugins* (pacotes que contêm código nativo, como `sqflite` e `connectivity_plus`) exigem que o Windows permita links simbólicos. Sem essa permissão, o build falha com a mensagem *Building with plugins requires symlink support*. Para ativar:

```powershell
start ms-settings:developers
```

Na janela aberta, ligar a opção **Modo de Desenvolvedor**.

### 1.7 Aceleração do emulador

O emulador Android executa um sistema operacional completo e depende de aceleração por hardware. No Windows, ativar o recurso **Plataforma do Hipervisor do Windows** em "Ativar ou desativar recursos do Windows" e reiniciar o computador. Como alternativa, o SDK Manager oferece o componente **Android Emulator hypervisor driver**, indicado para processadores AMD sem esse recurso.

### 1.8 Verificação final do ambiente

```powershell
flutter doctor -v
```

Para este projeto, as seções **Flutter**, **Android toolchain**, **Android Studio** e **VS Code** devem estar marcadas com `[√]`. A seção **Visual Studio** é necessária apenas para gerar aplicativos de desktop Windows, e **Chrome**, para a web; nenhuma das duas é usada aqui.

## 2. Arquitetura do aplicativo

### 2.1 Camadas e direção das dependências

O aplicativo segue a arquitetura em camadas da Aula 12:

```text
┌──────────────────────── Apresentação ────────────────────────┐
│ telas e componentes (widgets)                                │
│ providers.dart: estado observado pela interface e montagem   │
│                 das dependências                             │
└───────────────┬──────────────────────────────────────────────┘
                │ usa
┌───────────────▼──────────────────────────────────────────────┐
│ Domínio: Item, regras de validação e ordenação,              │
│          contrato ItemRepository                             │
└───────────────▲──────────────────────────────────────────────┘
                │ implementa
┌───────────────┴──────────────────────────────────────────────┐
│ Dados: SQLite, servidor simulado, sincronização,             │
│        canal de plataforma                                   │
└──────────────────────────────────────────────────────────────┘
```

Dois pontos merecem atenção:

- **O domínio não depende de nada.** Ele declara o contrato `ItemRepository` (o que precisa), e a camada de dados o implementa (como faz). A seta entre domínio e dados, portanto, aponta para cima: os dados dependem do domínio, e não o contrário. Essa inversão é o princípio central dos estilos arquiteturais da Aula 20 (portas e adaptadores, arquitetura limpa) e é o que permite testar as regras sem banco de dados.
- **Um único arquivo conhece as classes concretas.** `providers.dart` é o ponto de montagem (*composition root*): é ali que se decide que o `ItemRepository` usado em produção é o `ItemRepositorySqlite`. As telas pedem um `ItemRepository` e não sabem que existe SQLite. Nos testes, basta substituir esse provider por uma implementação em memória.

### 2.2 Fluxo de uma ação

O caminho percorrido quando o usuário marca um item como comprado ilustra a colaboração entre as camadas:

1. O `Checkbox` do `CartaoItem` chama `ItensNotifier.alternarComprado(item)`.
2. O notifier cria uma cópia do item com `comprado` invertido (o objeto original é imutável) e chama `ItemRepository.salvar`.
3. A implementação SQLite executa um `UPDATE`, marca o item como pendente de envio (`sincronizado = 0`) e registra o horário da alteração.
4. O notifier relê a tabela, ordena os itens pela regra de domínio `ordenarParaExibicao` e publica o resultado em `state`.
5. Todo widget que observa `itensProvider` com `ref.watch` é reconstruído. O cartão aparece riscado, desce para o fim da lista e mostra o ícone de "aguardando envio".

### 2.3 Fluxo de sincronização

1. O usuário toca no ícone de envio, ou a conexão retorna depois de um período offline.
2. `SincronizacaoNotifier` consulta o estado da rede. Sem conexão, informa o usuário e encerra, sem perder nada: os dados continuam no SQLite.
3. Com conexão, o `Sincronizador` lê os itens pendentes e envia cada um ao servidor simulado. Falhas transitórias são repetidas com espera exponencial e variação aleatória (*jitter*), conforme a Aula 13.
4. Cada item confirmado pelo servidor é marcado como enviado, **desde que não tenha sido alterado durante o envio**. A condição evita que uma edição feita nesse intervalo seja considerada enviada sem ter sido.
5. Ao final, a lista é relida e uma mensagem resume o resultado.

### 2.4 Simplificações assumidas

| Simplificação | Consequência | Solução em um sistema real |
|---|---|---|
| Servidor simulado em memória | Nada é de fato transmitido | Substituir `ServicoRemotoSimulado` por um cliente HTTP (Aula 13), sem alterar as demais camadas |
| Exclusões não são enviadas | O servidor não saberia de um item excluído offline | Exclusão lógica (coluna `excluido`) enviada como alteração |
| Sem tratamento de conflito | A versão local sempre prevalece | *Last-write-wins* por data, mesclagem de campos ou rejeição com aviso (Aula 13) |
| Banco na versão 1 | Não há migração de esquema | `onUpgrade` com `ALTER TABLE`, exemplificado no Passo 4 |

## 3. Estrutura do projeto

```text
compras/
├── android/
│   └── app/
│       ├── build.gradle.kts            ← applicationId e versão do Android
│       └── src/main/
│           ├── AndroidManifest.xml     ← nome no inicializador e ligação profunda
│           └── kotlin/.../MainActivity.kt  ← lado nativo do canal de plataforma
├── lib/
│   ├── main.dart                       ← ponto de entrada
│   ├── app.dart                        ← MaterialApp, temas e roteador
│   ├── config/
│   │   └── identidade.dart             ← nome, autoria, cor e categorias
│   ├── dominio/                        ← sem dependência de Flutter ou SQLite
│   │   ├── item.dart
│   │   ├── regras_item.dart
│   │   └── item_repository.dart
│   ├── dados/
│   │   ├── local/
│   │   │   ├── banco_de_dados.dart     ← abertura e esquema SQLite
│   │   │   ├── item_mapper.dart        ← Item ↔ linha da tabela
│   │   │   └── item_repository_sqlite.dart
│   │   ├── remoto/
│   │   │   ├── nova_tentativa.dart     ← backoff exponencial com jitter
│   │   │   └── servico_remoto_simulado.dart
│   │   ├── plataforma/
│   │   │   └── dispositivo_nativo.dart ← lado Dart do canal de plataforma
│   │   └── sincronizador.dart
│   └── apresentacao/
│       ├── providers.dart              ← estado e montagem das dependências
│       ├── rotas.dart
│       ├── telas/
│       │   ├── tela_lista.dart
│       │   ├── tela_item.dart
│       │   ├── tela_sobre.dart
│       │   └── tela_nao_encontrada.dart
│       └── componentes/
│           ├── cartao_item.dart
│           └── faixa_offline.dart
├── test/
│   ├── apoio/repositorio_em_memoria.dart
│   ├── dominio/regras_item_test.dart
│   ├── dados/nova_tentativa_test.dart
│   ├── dados/item_repository_sqlite_test.dart
│   └── apresentacao/fluxo_da_lista_test.dart
└── pubspec.yaml
```

As pastas de `lib/` correspondem às camadas. Essa organização por camada é a mais direta para um aplicativo com uma única funcionalidade; a Aula 21 discute a alternativa de organizar por funcionalidade, mais adequada quando o aplicativo cresce.

## Passo 1: Criar o projeto e instalar as dependências

### 1.1 Criar o projeto

Abrir um terminal na pasta de projetos e executar, substituindo `equipeexemplo` pelo identificador escolhido (ver Passo 2):

```powershell
cd C:\dev\projetos
flutter create --org br.com.equipeexemplo --platforms android compras
cd compras
code .
```

| Parâmetro | Efeito |
|---|---|
| `--org br.com.equipeexemplo` | Prefixo do identificador do aplicativo no Android. O `applicationId` resultante é `br.com.equipeexemplo.compras` |
| `--platforms android` | Gera apenas a pasta `android/`. Evita pastas de plataformas não suportadas pelo `sqflite` (web) e reduz o projeto |
| `compras` | Nome da pasta e do pacote Dart. Deve usar letras minúsculas e `_` |

O identificador passado em `--org` segue as regras de pacotes Java: segmentos separados por ponto, apenas letras minúsculas sem acento, dígitos e `_`, e cada segmento iniciando por letra. Exemplos válidos: `br.com.mariasilva`, `br.com.grupo07`. Exemplos inválidos: `br.com.maria-silva` (hífen), `br.com.7grupo` (inicia com dígito), `br.com.joão` (acento).

Apagar o teste de exemplo gerado, que testa um contador inexistente neste projeto e falharia:

```powershell
del test\widget_test.dart
```

### 1.2 Instalar as dependências

```powershell
flutter pub add flutter_riverpod go_router sqflite path connectivity_plus
flutter pub add dev:sqflite_common_ffi
```

| Pacote | Camada | Finalidade |
|---|---|---|
| `flutter_riverpod` | Apresentação | Gerenciamento de estado e injeção de dependências (Aula 12) |
| `go_router` | Apresentação | Rotas declarativas e ligação profunda (Aula 14) |
| `sqflite` | Dados | Acesso ao SQLite do Android (Aula 13) |
| `path` | Dados | Montagem do caminho do arquivo do banco, independente do sistema |
| `connectivity_plus` | Dados/apresentação | Observação do estado da rede (Aula 13) |
| `sqflite_common_ffi` (`dev:`) | Testes | SQLite executado no computador, para testar o repositório sem emulador |

O prefixo `dev:` registra o pacote em `dev_dependencies`: ele é usado apenas nos testes e não entra no APK. Ao final, o `pubspec.yaml` contém trechos semelhantes aos abaixo (os números de versão podem ser mais recentes):

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^3.3.2
  go_router: ^17.5.0
  sqflite: ^2.4.2+1
  path: ^1.9.1
  connectivity_plus: ^7.3.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
  sqflite_common_ffi: ^2.4.0+3
```

> **Sobre o Riverpod sem geração de código.** A Aula 12 apresentou a anotação `@riverpod`, que exige o gerador `build_runner`. Este tutorial usa as classes `AsyncNotifier`, `Notifier` e `Provider` escritas diretamente, que oferecem o mesmo comportamento sem a etapa de geração. A escolha reduz o número de ferramentas no primeiro projeto completo; a migração para `@riverpod` não altera a arquitetura.

## Passo 2: Identidade do aplicativo

### 2.1 Por que o aplicativo precisa de identidade

Um aplicativo distribuído precisa ser identificável em três níveis:

- **Pelo sistema operacional.** O Android identifica cada aplicativo instalado pelo `applicationId`. Dois aplicativos com o mesmo identificador não coexistem no aparelho: instalar o segundo tenta substituir o primeiro e falha. Por isso, o identificador gerado por padrão (`com.example`) não deve ser mantido, e o `--org` do Passo 1 deve conter um identificador próprio da pessoa ou da equipe responsável.
- **Pelo usuário.** O nome exibido no inicializador do Android e na barra superior, a cor do tema e as categorias oferecidas devem corresponder ao público e ao contexto de uso (Aula 7). Uma lista de compras para uma república estudantil, para uma cantina ou para uma família tende a ter categorias diferentes.
- **Pela equipe.** A tela "Sobre" registra a autoria e a turma, prática comum em software para créditos e contato.

Todos esses dados ficam concentrados em um único arquivo, `identidade.dart`. Concentrá-los segue o mesmo princípio dos tokens de cor da Aula 10: o restante do código referencia `Identidade.nomeDoApp`, e não o texto literal.

### 2.2 Arquivo `lib/config/identidade.dart`

Criar a pasta `lib/config/` e o arquivo abaixo. Em seguida, **substituir os valores de exemplo** pelos dados reais: nome do aplicativo, descrição, nome completo e matrícula de cada integrante (um ou mais), turma, cor semente e categorias adequadas ao contexto de uso escolhido.

```dart
import 'package:flutter/material.dart';

/// Pessoa responsável pelo aplicativo.
class Integrante {
  const Integrante({required this.nome, required this.matricula});

  final String nome;
  final String matricula;
}

/// Identificação do aplicativo e da autoria. É o único arquivo a editar para
/// definir nome, créditos, cor do tema e categorias da lista.
abstract final class Identidade {
  /// Nome exibido na barra superior e na tela "Sobre".
  static const nomeDoApp = 'Compras da Equipe Exemplo';

  /// Frase curta que descreve o propósito do aplicativo.
  static const descricao =
      'Lista de compras com armazenamento local em SQLite e envio posterior '
      'ao servidor.';

  static const turma = 'Desenvolvimento para Dispositivos Móveis — 2026';

  static const integrantes = [
    Integrante(nome: 'Nome Completo da Pessoa 1', matricula: '000000000'),
  ];

  /// Cor semente do tema (Aula 10): o Material 3 deriva a paleta a partir dela.
  static const corSemente = Color(0xFF2E7D32);

  /// Categorias oferecidas no formulário. A primeira é o valor padrão.
  static const categorias = ['Hortifrúti', 'Mercearia', 'Limpeza', 'Higiene'];
}
```

- `abstract final class` impede que a classe seja instanciada ou estendida: ela serve apenas para agrupar constantes.
- A cor semente é escrita como `Color(0xAARRGGBB)`. `0xFF` no início é a opacidade total. Após a escolha, convém verificar o contraste da paleta gerada nos temas claro e escuro (Aula 10).
- A primeira categoria da lista é o valor inicial do formulário.

### 2.3 Nome no inicializador do Android

O nome exibido abaixo do ícone, na tela inicial do aparelho, não vem do código Dart: ele é lido do manifesto do Android antes de o Flutter iniciar. Em `android/app/src/main/AndroidManifest.xml`, alterar o atributo `android:label`:

```xml
    <application
        android:label="Compras"
        ...
```

O inicializador exibe por volta de 12 caracteres, de modo que convém uma versão curta do nome do aplicativo.

### 2.4 Conferência do identificador

Abrir `android/app/build.gradle.kts` e localizar, em `defaultConfig`, a linha:

```kotlin
applicationId = "br.com.equipeexemplo.compras"
```

O valor deve refletir o identificador escolhido no Passo 1. Caso o projeto tenha sido criado sem `--org`, é possível corrigir apenas essa linha; o `namespace`, logo acima, pode permanecer como está, pois define o pacote das classes Kotlin, e não a identidade do aplicativo instalado.

## Passo 3: Camada de domínio

O domínio contém o que o aplicativo **é**, independentemente de como é exibido ou armazenado. Nenhum arquivo desta pasta importa Flutter, SQLite ou pacotes de rede, e por isso todos podem ser testados com Dart puro (Aula 12).

### 3.1 Entidade `lib/dominio/item.dart`

```dart
/// Entidade de domínio: não conhece Flutter, SQLite nem formato de rede.
class Item {
  const Item({
    this.id,
    required this.nome,
    this.quantidade = 1,
    required this.categoria,
    this.observacao = '',
    this.comprado = false,
    this.sincronizado = false,
    required this.criadoEm,
    required this.atualizadoEm,
  });

  /// Nulo enquanto o item não foi gravado no banco.
  final int? id;
  final String nome;
  final int quantidade;
  final String categoria;
  final String observacao;
  final bool comprado;

  /// Verdadeiro quando a versão atual já foi enviada ao servidor.
  final bool sincronizado;
  final DateTime criadoEm;
  final DateTime atualizadoEm;

  /// Cria uma cópia com alguns campos trocados. O objeto original não muda.
  Item copyWith({
    int? id,
    String? nome,
    int? quantidade,
    String? categoria,
    String? observacao,
    bool? comprado,
    bool? sincronizado,
    DateTime? atualizadoEm,
  }) {
    return Item(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      quantidade: quantidade ?? this.quantidade,
      categoria: categoria ?? this.categoria,
      observacao: observacao ?? this.observacao,
      comprado: comprado ?? this.comprado,
      sincronizado: sincronizado ?? this.sincronizado,
      criadoEm: criadoEm,
      atualizadoEm: atualizadoEm ?? this.atualizadoEm,
    );
  }
}
```

- Todos os campos são `final`: um `Item` não muda depois de criado. Para "alterar" um item, cria-se uma cópia com `copyWith`. A imutabilidade é o que permite ao Riverpod detectar mudanças por comparação de objetos e evita que uma tela altere um item que outra tela está exibindo.
- `id` é anulável porque um item recém-criado ainda não foi gravado; o banco atribui o número na inserção.
- `sincronizado` é um dado de domínio porque a interface o exibe (ícone de nuvem) e a regra de resumo o contabiliza.
- `copyWith` não permite trocar `criadoEm`: a data de criação, por definição, não muda.

### 3.2 Regras `lib/dominio/regras_item.dart`

```dart
import 'item.dart';

const tamanhoMinimoNome = 2;
const tamanhoMaximoNome = 40;
const quantidadeMinima = 1;
const quantidadeMaxima = 99;

/// Devolve a mensagem de erro, ou null quando o nome é válido.
String? validarNome(String nome) {
  final texto = nome.trim();
  if (texto.isEmpty) return 'Informe o nome do item.';
  if (texto.length < tamanhoMinimoNome) {
    return 'Use ao menos $tamanhoMinimoNome caracteres.';
  }
  if (texto.length > tamanhoMaximoNome) {
    return 'Use no máximo $tamanhoMaximoNome caracteres.';
  }
  return null;
}

/// Soma a variação à quantidade, sem sair do intervalo permitido.
int ajustarQuantidade(int atual, int variacao) =>
    (atual + variacao).clamp(quantidadeMinima, quantidadeMaxima);

/// Itens a comprar primeiro; dentro de cada grupo, por categoria e por nome.
List<Item> ordenarParaExibicao(Iterable<Item> itens) {
  final lista = itens.toList();
  lista.sort((a, b) {
    if (a.comprado != b.comprado) return a.comprado ? 1 : -1;
    final porCategoria = a.categoria.toLowerCase().compareTo(
      b.categoria.toLowerCase(),
    );
    if (porCategoria != 0) return porCategoria;
    return a.nome.toLowerCase().compareTo(b.nome.toLowerCase());
  });
  return lista;
}

class Resumo {
  const Resumo({
    required this.total,
    required this.comprados,
    required this.aguardandoEnvio,
  });

  final int total;
  final int comprados;
  final int aguardandoEnvio;

  double get progresso => total == 0 ? 0.0 : comprados / total;
}

Resumo resumir(Iterable<Item> itens) {
  var total = 0, comprados = 0, aguardandoEnvio = 0;
  for (final item in itens) {
    total++;
    if (item.comprado) comprados++;
    if (!item.sincronizado) aguardandoEnvio++;
  }
  return Resumo(
    total: total,
    comprados: comprados,
    aguardandoEnvio: aguardandoEnvio,
  );
}
```

- `validarNome` devolve `null` quando o valor é válido e a mensagem de erro caso contrário. É exatamente o formato esperado pelo parâmetro `validator` dos campos de formulário do Flutter, o que permite usar a regra de domínio diretamente na interface sem duplicá-la.
- `clamp` limita o resultado ao intervalo, de modo que nenhum chamador consegue produzir quantidade 0 ou 100.
- A ordenação é regra de negócio (o que o usuário vê primeiro), e não detalhe de banco de dados. Por isso fica no domínio, e não em uma cláusula `ORDER BY`.

### 3.3 Contrato `lib/dominio/item_repository.dart`

```dart
import 'item.dart';

/// Contrato que a camada de dados deve cumprir. O domínio define o que
/// precisa; a camada de dados decide como (SQLite, memória, rede).
abstract interface class ItemRepository {
  Future<List<Item>> listar();

  /// Insere (quando id é nulo) ou atualiza. Devolve o item com id preenchido.
  Future<Item> salvar(Item item);

  Future<void> excluir(int id);

  Future<List<Item>> listarNaoSincronizados();

  /// Marca como enviada a versão informada, se ela ainda for a atual.
  Future<void> marcarComoSincronizado(Item item);
}
```

`abstract interface class` declara apenas assinaturas: quem implementa o contrato precisa fornecer todos os métodos, e ninguém pode instanciá-lo diretamente. O domínio e a apresentação dependem somente deste contrato.

## Passo 4: Camada de dados — SQLite

### 4.1 Por que SQLite

O `shared_preferences` da Aula 9 grava a lista inteira como um único texto a cada alteração e precisa ler tudo para encontrar um item. O SQLite é um banco de dados relacional completo, armazenado em um único arquivo no aparelho e embutido no próprio Android. Ele permite:

- gravar e ler **um registro por vez**, com custo que não cresce com o tamanho da lista;
- **consultar** por condição (por exemplo, apenas os itens não enviados), com o auxílio de índices;
- impor **restrições** de integridade no próprio banco (`NOT NULL`, `CHECK`);
- **evoluir o esquema** de forma controlada, por versões.

| Conceito SQL | Uso neste projeto |
|---|---|
| Tabela | `itens` guarda um item por linha; `metadados`, pares chave-valor |
| `PRIMARY KEY AUTOINCREMENT` | O banco atribui um `id` único e crescente a cada inserção |
| `NOT NULL`, `DEFAULT` | Colunas obrigatórias e valores padrão |
| `CHECK` | A quantidade fica entre 1 e 99 mesmo que algum código ignore a regra de domínio |
| Índice | `idx_itens_sincronizado` acelera a consulta de itens pendentes |

A restrição `CHECK` repete a regra de `ajustarQuantidade`. A duplicação é intencional: a regra de domínio produz uma mensagem amigável na interface, ao passo que a restrição no banco é uma **defesa em profundidade**, que impede dados inválidos mesmo diante de um erro de programação.

### 4.2 Abertura e esquema `lib/dados/local/banco_de_dados.dart`

```dart
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Abre o arquivo SQLite e cria as tabelas na primeira execução.
class BancoDeDados {
  BancoDeDados({required DatabaseFactory fabrica, String? caminho})
    : _fabrica = fabrica,
      _caminho = caminho;

  static const versaoDoEsquema = 1;
  static const nomeDoArquivo = 'compras.db';

  final DatabaseFactory _fabrica;
  final String? _caminho;
  Future<Database>? _abertura;

  /// Abre uma única vez; chamadas seguintes reutilizam a mesma conexão.
  Future<Database> abrir() => _abertura ??= _abrir();

  Future<Database> _abrir() async {
    final caminho =
        _caminho ?? p.join(await _fabrica.getDatabasesPath(), nomeDoArquivo);
    return _fabrica.openDatabase(
      caminho,
      options: OpenDatabaseOptions(
        version: versaoDoEsquema,
        onCreate: _criarEsquema,
      ),
    );
  }

  Future<void> _criarEsquema(Database db, int versao) async {
    await db.execute('''
      CREATE TABLE itens (
        id            INTEGER PRIMARY KEY AUTOINCREMENT,
        nome          TEXT    NOT NULL,
        quantidade    INTEGER NOT NULL CHECK (quantidade BETWEEN 1 AND 99),
        categoria     TEXT    NOT NULL,
        observacao    TEXT    NOT NULL DEFAULT '',
        comprado      INTEGER NOT NULL DEFAULT 0,
        sincronizado  INTEGER NOT NULL DEFAULT 0,
        criado_em     INTEGER NOT NULL,
        atualizado_em INTEGER NOT NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_itens_sincronizado ON itens (sincronizado)',
    );
    await db.execute('''
      CREATE TABLE metadados (
        chave TEXT PRIMARY KEY,
        valor TEXT NOT NULL
      )
    ''');
    await db.insert('metadados', {
      'chave': 'criado_em',
      'valor': DateTime.now().toIso8601String(),
    });
  }

  Future<String?> lerMetadado(String chave) async {
    final db = await abrir();
    final linhas = await db.query(
      'metadados',
      columns: ['valor'],
      where: 'chave = ?',
      whereArgs: [chave],
      limit: 1,
    );
    return linhas.isEmpty ? null : linhas.first['valor'] as String;
  }

  Future<void> fechar() async {
    final abertura = _abertura;
    _abertura = null;
    if (abertura != null) await (await abertura).close();
  }
}
```

- **Fábrica injetada.** O construtor recebe uma `DatabaseFactory` em vez de usar diretamente a do plugin. No aplicativo, recebe a fábrica do Android; nos testes, a do `sqflite_common_ffi`, que roda no computador. Sem essa injeção, o repositório só poderia ser testado no emulador.
- **Abertura única.** `_abertura ??= _abrir()` guarda o `Future` da primeira abertura. Se duas partes do aplicativo pedirem o banco ao mesmo tempo, ambas recebem a mesma conexão, em vez de abrir o arquivo duas vezes.
- **`onCreate`** é executado somente quando o arquivo ainda não existe, isto é, na primeira execução após a instalação ou após a limpeza dos dados do aplicativo. O registro `criado_em` na tabela `metadados` guarda esse momento e é exibido na tela "Sobre".
- **Tipos.** O SQLite não possui tipo booleano nem tipo data: usam-se `INTEGER` com 0 e 1 e `INTEGER` com milissegundos desde 1970.
- **Onde fica o arquivo.** No Android, `getDatabasesPath()` aponta para `/data/data/<applicationId>/databases/`, área privada do aplicativo.

**Evolução do esquema.** Quando uma versão futura precisar de uma coluna nova, incrementa-se `versaoDoEsquema` e acrescenta-se `onUpgrade`, que o `sqflite` executa nos aparelhos que já possuem a versão anterior do banco. Exemplo, a título de referência (não faz parte deste tutorial):

```dart
options: OpenDatabaseOptions(
  version: 2,
  onCreate: _criarEsquema, // deve criar já o esquema da versão 2
  onUpgrade: (db, versaoAntiga, versaoNova) async {
    if (versaoAntiga < 2) {
      await db.execute(
        'ALTER TABLE itens ADD COLUMN preco_centavos INTEGER NOT NULL DEFAULT 0',
      );
    }
  },
),
```

### 4.3 Conversão `lib/dados/local/item_mapper.dart`

```dart
import '../../dominio/item.dart';

// Conversão entre a entidade de domínio e uma linha da tabela "itens".
// SQLite não tem tipos booleano nem data: usam-se 0/1 e milissegundos.

Map<String, Object?> itemParaLinha(Item item) => {
  if (item.id != null) 'id': item.id,
  'nome': item.nome,
  'quantidade': item.quantidade,
  'categoria': item.categoria,
  'observacao': item.observacao,
  'comprado': item.comprado ? 1 : 0,
  'sincronizado': item.sincronizado ? 1 : 0,
  'criado_em': item.criadoEm.millisecondsSinceEpoch,
  'atualizado_em': item.atualizadoEm.millisecondsSinceEpoch,
};

Item itemDeLinha(Map<String, Object?> linha) => Item(
  id: linha['id'] as int,
  nome: linha['nome'] as String,
  quantidade: linha['quantidade'] as int,
  categoria: linha['categoria'] as String,
  observacao: linha['observacao'] as String,
  comprado: linha['comprado'] == 1,
  sincronizado: linha['sincronizado'] == 1,
  criadoEm: DateTime.fromMillisecondsSinceEpoch(linha['criado_em'] as int),
  atualizadoEm: DateTime.fromMillisecondsSinceEpoch(
    linha['atualizado_em'] as int,
  ),
);
```

O mapeador é a serialização da Aula 13 aplicada ao banco: converte a entidade de domínio no formato de armazenamento e vice-versa. Mantê-lo fora de `Item` preserva o domínio livre de detalhes de persistência: se a tabela mudar de nome de coluna, apenas este arquivo muda. A entrada `if (item.id != null) 'id': item.id` omite o `id` na inserção, deixando o banco atribuí-lo.

### 4.4 Repositório `lib/dados/local/item_repository_sqlite.dart`

```dart
import '../../dominio/item.dart';
import '../../dominio/item_repository.dart';
import 'banco_de_dados.dart';
import 'item_mapper.dart';

class ItemRepositorySqlite implements ItemRepository {
  ItemRepositorySqlite(this._banco);

  final BancoDeDados _banco;
  static const _tabela = 'itens';

  @override
  Future<List<Item>> listar() async {
    final db = await _banco.abrir();
    final linhas = await db.query(_tabela);
    return linhas.map(itemDeLinha).toList();
  }

  @override
  Future<Item> salvar(Item item) async {
    final db = await _banco.abrir();
    // Toda gravação local deixa o item pendente de envio ao servidor.
    final pendente = item.copyWith(
      sincronizado: false,
      atualizadoEm: DateTime.now(),
    );
    final id = pendente.id;
    if (id == null) {
      final novoId = await db.insert(_tabela, itemParaLinha(pendente));
      return pendente.copyWith(id: novoId);
    }
    await db.update(
      _tabela,
      itemParaLinha(pendente),
      where: 'id = ?',
      whereArgs: [id],
    );
    return pendente;
  }

  @override
  Future<void> excluir(int id) async {
    final db = await _banco.abrir();
    await db.delete(_tabela, where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<List<Item>> listarNaoSincronizados() async {
    final db = await _banco.abrir();
    final linhas = await db.query(_tabela, where: 'sincronizado = 0');
    return linhas.map(itemDeLinha).toList();
  }

  @override
  Future<void> marcarComoSincronizado(Item item) async {
    final db = await _banco.abrir();
    // A condição em atualizado_em impede marcar como enviada uma versão que
    // foi alterada enquanto o envio estava em andamento.
    await db.update(
      _tabela,
      {'sincronizado': 1},
      where: 'id = ? AND atualizado_em = ?',
      whereArgs: [item.id, item.atualizadoEm.millisecondsSinceEpoch],
    );
  }
}
```

- **Parâmetros `?`.** Os valores nunca são concatenados ao texto SQL: são passados em `whereArgs`, e o SQLite os trata como dados. Essa prática impede a injeção de SQL, em que um texto digitado pelo usuário seria interpretado como comando.
- **`salvar` decide entre inserir e atualizar** pela presença do `id`, e em ambos os casos marca o item como pendente de envio e atualiza `atualizado_em`.
- **`marcarComoSincronizado` usa concorrência otimista.** A atualização só ocorre se `atualizado_em` ainda for o mesmo da versão enviada. Se o usuário editar o item enquanto o envio está em andamento, o `UPDATE` não encontra a linha com a data antiga e não faz nada, e o item continua pendente para o próximo envio. Um teste do Passo 10 verifica esse comportamento.

## Passo 5: Camada de dados — conectividade intermitente

### 5.1 Nova tentativa `lib/dados/remoto/nova_tentativa.dart`

```dart
import 'dart:math';

/// Falha que tende a desaparecer sozinha: rede instável, servidor sobrecarregado.
class FalhaTransitoria implements Exception {
  const FalhaTransitoria(this.mensagem);

  final String mensagem;

  @override
  String toString() => 'FalhaTransitoria: $mensagem';
}

/// Repete [operacao] em caso de [FalhaTransitoria], com espera exponencial
/// (base, 2 × base, 4 × base...) somada a um intervalo aleatório (jitter).
Future<T> comNovaTentativa<T>(
  Future<T> Function() operacao, {
  int maxTentativas = 3,
  Duration esperaBase = const Duration(milliseconds: 500),
  Random? aleatorio,
}) async {
  final sorteio = aleatorio ?? Random();
  var tentativa = 0;
  while (true) {
    try {
      return await operacao();
    } on FalhaTransitoria {
      tentativa++;
      if (tentativa >= maxTentativas) rethrow;
      final exponencial = esperaBase * (1 << (tentativa - 1));
      final limiteDoJitter = esperaBase.inMilliseconds;
      final jitter = Duration(
        milliseconds: limiteDoJitter > 0 ? sorteio.nextInt(limiteDoJitter) : 0,
      );
      await Future<void>.delayed(exponencial + jitter);
    }
  }
}
```

O algoritmo é o da Aula 13. Com a espera base de 500 ms, a segunda tentativa ocorre após 0,5 s a 1 s, e a terceira, após 1 s a 1,5 s. `1 << (tentativa - 1)` é a potência de 2 (1, 2, 4...) calculada por deslocamento de bits. O *jitter* aleatório evita que muitos aparelhos que perderam a conexão ao mesmo tempo tentem novamente no mesmo instante. Apenas `FalhaTransitoria` é repetida: qualquer outro erro é propagado imediatamente, pois repetir uma falha permanente apenas consome bateria.

Os parâmetros `esperaBase` e `aleatorio` existem para os testes, que usam espera zero e não precisam aguardar segundos.

### 5.2 Servidor simulado `lib/dados/remoto/servico_remoto_simulado.dart`

```dart
import 'dart:math';

import '../../dominio/item.dart';
import 'nova_tentativa.dart';

/// Ocupa o lugar de uma API real: demora a responder e falha em parte das
/// chamadas, o que permite observar nova tentativa e sincronização sem servidor.
class ServicoRemotoSimulado {
  ServicoRemotoSimulado({this.taxaDeFalha = 0.3, Random? aleatorio})
    : _aleatorio = aleatorio ?? Random();

  /// Fração das chamadas que falham (0.0 = nunca, 1.0 = sempre).
  final double taxaDeFalha;
  final Random _aleatorio;

  Future<void> enviar(Item item) async {
    await Future<void>.delayed(
      Duration(milliseconds: 200 + _aleatorio.nextInt(600)),
    );
    if (_aleatorio.nextDouble() < taxaDeFalha) {
      throw const FalhaTransitoria('Servidor indisponível (simulação).');
    }
  }
}
```

O serviço reproduz duas características de uma rede móvel real: latência variável (200 a 800 ms) e falhas ocasionais (30% das chamadas). Alterar `taxaDeFalha` para `1.0` em `providers.dart` permite observar itens que permanecem pendentes; `0.0` simula um servidor sempre disponível.

### 5.3 Sincronizador `lib/dados/sincronizador.dart`

```dart
import '../dominio/item_repository.dart';
import 'remoto/nova_tentativa.dart';
import 'remoto/servico_remoto_simulado.dart';

class ResultadoSincronizacao {
  const ResultadoSincronizacao({required this.enviados, required this.falhas});

  final int enviados;
  final int falhas;
}

/// Envia ao servidor tudo o que foi alterado localmente e ainda não foi enviado.
class Sincronizador {
  Sincronizador(this._repositorio, this._remoto);

  final ItemRepository _repositorio;
  final ServicoRemotoSimulado _remoto;

  Future<ResultadoSincronizacao> sincronizar() async {
    final pendentes = await _repositorio.listarNaoSincronizados();
    var enviados = 0, falhas = 0;
    for (final item in pendentes) {
      try {
        await comNovaTentativa(() => _remoto.enviar(item));
        await _repositorio.marcarComoSincronizado(item);
        enviados++;
      } on FalhaTransitoria {
        falhas++; // continua pendente e será reenviado na próxima vez
      }
    }
    return ResultadoSincronizacao(enviados: enviados, falhas: falhas);
  }
}
```

Cada item é tratado de forma independente: a falha de um não impede o envio dos demais. Um item só é marcado como enviado **depois** da confirmação do servidor; se o aplicativo for encerrado no meio do processo, o item permanece pendente e é reenviado na próxima sincronização. O envio repetido de um mesmo item é inofensivo desde que o servidor real trate o envio como substituição (operação idempotente).

## Passo 6: Canal de plataforma

O Flutter não oferece, em Dart, acesso ao modelo do aparelho nem ao nível da bateria. Esses dados são obtidos pelo código Kotlin e entregues ao Dart por um `MethodChannel` (Aula 14).

### 6.1 Lado Dart `lib/dados/plataforma/dispositivo_nativo.dart`

```dart
import 'package:flutter/services.dart';

class InfoDispositivo {
  const InfoDispositivo({
    required this.fabricante,
    required this.modelo,
    required this.versaoAndroid,
    required this.nivelBateria,
  });

  final String fabricante;
  final String modelo;
  final String versaoAndroid;
  final int nivelBateria;
}

/// Lado Dart do canal de plataforma (Aula 14). O lado Kotlin fica na MainActivity.
class DispositivoNativo {
  static const _canal = MethodChannel('compras/dispositivo');

  /// Devolve null quando a plataforma não implementa o canal.
  Future<InfoDispositivo?> obterInformacoes() async {
    try {
      final mapa = await _canal.invokeMapMethod<String, Object?>(
        'obterInformacoes',
      );
      if (mapa == null) return null;
      return InfoDispositivo(
        fabricante: mapa['fabricante'] as String,
        modelo: mapa['modelo'] as String,
        versaoAndroid: mapa['versaoAndroid'] as String,
        nivelBateria: mapa['bateria'] as int,
      );
    } on MissingPluginException {
      return null; // canal não registrado nesta plataforma
    } on PlatformException {
      return null; // o código nativo respondeu com erro
    }
  }
}
```

`invokeMapMethod` envia o nome do método pelo canal e aguarda um mapa como resposta. Os dois `catch` tornam a função tolerante: nos testes automatizados não existe lado nativo, e a chamada lança `MissingPluginException`. Nesse caso a tela "Sobre" exibe "Informação indisponível", em vez de falhar.

### 6.2 Lado Kotlin `MainActivity.kt`

Abrir `android/app/src/main/kotlin/br/com/<identificador>/compras/MainActivity.kt`. **Manter a primeira linha (`package ...`) exatamente como foi gerada**, pois ela corresponde ao identificador escolhido, e substituir o restante do arquivo pelo conteúdo abaixo:

```kotlin
package br.com.equipeexemplo.compras

import android.content.Context
import android.os.BatteryManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    // Mesmo nome usado em lib/dados/plataforma/dispositivo_nativo.dart.
    private val canal = "compras/dispositivo"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, canal)
            .setMethodCallHandler { chamada, resultado ->
                when (chamada.method) {
                    "obterInformacoes" -> resultado.success(obterInformacoes())
                    else -> resultado.notImplemented()
                }
            }
    }

    private fun obterInformacoes(): Map<String, Any> {
        val bateria = getSystemService(Context.BATTERY_SERVICE) as BatteryManager
        return mapOf(
            "fabricante" to Build.MANUFACTURER,
            "modelo" to Build.MODEL,
            "versaoAndroid" to Build.VERSION.RELEASE,
            "bateria" to bateria.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY),
        )
    }
}
```

- O nome do canal (`compras/dispositivo`) e o nome do método (`obterInformacoes`) precisam coincidir exatamente com os do lado Dart.
- `Build.MANUFACTURER`, `Build.MODEL` e `Build.VERSION.RELEASE` são constantes do Android; o `BatteryManager` informa a carga em porcentagem. Nenhum desses dados exige permissão especial.
- `notImplemented()` responde a métodos desconhecidos, evitando que o lado Dart aguarde indefinidamente.

> **Hot reload não recarrega código nativo.** Alterações em arquivos Kotlin, no `AndroidManifest.xml` ou no `build.gradle.kts`, assim como a inclusão de plugins, exigem parar o aplicativo e executá-lo novamente.

## Passo 7: Estado e montagem das dependências

### 7.1 Arquivo `lib/apresentacao/providers.dart`

```dart
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart' show databaseFactory;

import '../dados/local/banco_de_dados.dart';
import '../dados/local/item_repository_sqlite.dart';
import '../dados/plataforma/dispositivo_nativo.dart';
import '../dados/remoto/servico_remoto_simulado.dart';
import '../dados/sincronizador.dart';
import '../dominio/item.dart';
import '../dominio/item_repository.dart';
import '../dominio/regras_item.dart';

// ---------------------------------------------------------------------------
// Dependências: o único ponto do aplicativo que conhece as classes concretas
// da camada de dados. Nos testes, cada uma pode ser substituída (override).
// ---------------------------------------------------------------------------

final bancoDeDadosProvider = Provider<BancoDeDados>((ref) {
  final banco = BancoDeDados(fabrica: databaseFactory);
  ref.onDispose(banco.fechar);
  return banco;
});

final itemRepositoryProvider = Provider<ItemRepository>(
  (ref) => ItemRepositorySqlite(ref.watch(bancoDeDadosProvider)),
);

final servicoRemotoProvider = Provider<ServicoRemotoSimulado>(
  (ref) => ServicoRemotoSimulado(),
);

final sincronizadorProvider = Provider<Sincronizador>(
  (ref) => Sincronizador(
    ref.watch(itemRepositoryProvider),
    ref.watch(servicoRemotoProvider),
  ),
);

final dispositivoNativoProvider = Provider<DispositivoNativo>(
  (ref) => DispositivoNativo(),
);

// ---------------------------------------------------------------------------
// Estado observado pela interface.
// ---------------------------------------------------------------------------

/// Verdadeiro quando há alguma rede ativa. Emite um novo valor a cada mudança.
final conectividadeProvider = StreamProvider<bool>((ref) async* {
  final conectividade = Connectivity();
  yield _estaOnline(await conectividade.checkConnectivity());
  yield* conectividade.onConnectivityChanged.map(_estaOnline);
});

bool _estaOnline(List<ConnectivityResult> resultados) =>
    resultados.isNotEmpty && !resultados.contains(ConnectivityResult.none);

final infoDispositivoProvider = FutureProvider<InfoDispositivo?>(
  (ref) => ref.watch(dispositivoNativoProvider).obterInformacoes(),
);

final bancoCriadoEmProvider = FutureProvider<DateTime?>((ref) async {
  final valor = await ref.watch(bancoDeDadosProvider).lerMetadado('criado_em');
  return valor == null ? null : DateTime.parse(valor);
});

/// Lista de itens exibida na tela principal.
final itensProvider = AsyncNotifierProvider<ItensNotifier, List<Item>>(
  ItensNotifier.new,
);

class ItensNotifier extends AsyncNotifier<List<Item>> {
  ItemRepository get _repositorio => ref.read(itemRepositoryProvider);

  @override
  Future<List<Item>> build() async {
    final itens = await ref.watch(itemRepositoryProvider).listar();
    return ordenarParaExibicao(itens);
  }

  Future<void> salvar(Item item) async {
    await _repositorio.salvar(item);
    await _recarregar();
  }

  Future<void> alternarComprado(Item item) =>
      salvar(item.copyWith(comprado: !item.comprado));

  Future<void> excluir(Item item) async {
    final id = item.id;
    if (id == null) return;
    // Remoção otimista: a lista muda de imediato, como o Dismissible exige.
    if (state case AsyncData(:final value)) {
      state = AsyncData([
        for (final i in value)
          if (i.id != id) i,
      ]);
    }
    try {
      await _repositorio.excluir(id);
    } catch (_) {
      await _recarregar(); // desfaz a remoção otimista
      rethrow;
    }
  }

  Future<void> _recarregar() async {
    state = AsyncData(ordenarParaExibicao(await _repositorio.listar()));
  }
}

class EstadoSincronizacao {
  const EstadoSincronizacao({this.emAndamento = false, this.mensagem});

  final bool emAndamento;

  /// Resultado da última tentativa, exibido em uma SnackBar.
  final String? mensagem;
}

final sincronizacaoProvider =
    NotifierProvider<SincronizacaoNotifier, EstadoSincronizacao>(
      SincronizacaoNotifier.new,
    );

class SincronizacaoNotifier extends Notifier<EstadoSincronizacao> {
  @override
  EstadoSincronizacao build() => const EstadoSincronizacao();

  Future<void> sincronizar() async {
    if (state.emAndamento) return;

    final online = switch (ref.read(conectividadeProvider)) {
      AsyncData(:final value) => value,
      _ => false,
    };
    if (!online) {
      state = const EstadoSincronizacao(
        mensagem: 'Sem conexão. As alterações continuam salvas no aparelho.',
      );
      return;
    }

    state = const EstadoSincronizacao(emAndamento: true);
    try {
      final resultado = await ref.read(sincronizadorProvider).sincronizar();
      state = EstadoSincronizacao(
        mensagem: resultado.falhas == 0
            ? 'Enviado(s) ${resultado.enviados} item(ns).'
            : 'Enviado(s) ${resultado.enviados}; ${resultado.falhas} '
                  'continua(m) pendente(s).',
      );
    } catch (erro) {
      state = EstadoSincronizacao(mensagem: 'Falha inesperada: $erro');
    }
    // Relê a lista para atualizar os ícones de "enviado".
    ref.invalidate(itensProvider);
  }
}
```

| Provider | Tipo | Papel |
|---|---|---|
| `bancoDeDadosProvider`, `itemRepositoryProvider`, `servicoRemotoProvider`, `sincronizadorProvider`, `dispositivoNativoProvider` | `Provider` | Criam uma única instância de cada dependência. `ref.onDispose` fecha o banco quando o `ProviderScope` é descartado |
| `conectividadeProvider` | `StreamProvider<bool>` | Emite o estado inicial da rede e cada mudança posterior |
| `infoDispositivoProvider`, `bancoCriadoEmProvider` | `FutureProvider` | Consultas executadas uma vez e guardadas em cache |
| `itensProvider` | `AsyncNotifierProvider` | Lista de itens, com carregamento assíncrono e métodos de alteração |
| `sincronizacaoProvider` | `NotifierProvider` | Estado do envio: em andamento e mensagem de resultado |

Pontos de funcionamento:

- **`ref.watch` em `build`** cria uma dependência: se o repositório mudar (por exemplo, substituído em um teste), a lista é recarregada. **`ref.read`** apenas obtém o valor no momento, adequado dentro de métodos que respondem a ações.
- **`AsyncNotifier`** começa no estado `loading`, executa `build` e passa a `data` ou `error`. A interface trata os três estados com `.when` (Aula 12).
- **Remoção otimista em `excluir`.** O componente `Dismissible` exige que o item arrastado saia da lista imediatamente. Por isso, o notifier remove o item do estado antes de concluir a exclusão no banco e, se o banco falhar, recarrega a lista para desfazer a remoção.
- **`switch` com padrões** (`AsyncData(:final value) => value`) extrai o valor quando o estado é `data` e usa um valor padrão nos demais casos. Por precaução, sem informação sobre a rede, a sincronização não é tentada.
- **`ref.invalidate(itensProvider)`** descarta o valor em cache e força uma nova leitura. Como o `.when` mantém os dados anteriores durante a recarga, a lista não pisca.

## Passo 8: Navegação e ligação profunda

### 8.1 Rotas `lib/apresentacao/rotas.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'telas/tela_item.dart';
import 'telas/tela_lista.dart';
import 'telas/tela_nao_encontrada.dart';
import 'telas/tela_sobre.dart';

/// Rotas declaradas em um único lugar (Aula 14). Por serem filhas de '/', as
/// rotas de item e "sobre" mantêm a lista abaixo delas na pilha, inclusive
/// quando abertas por ligação profunda.
final roteadorProvider = Provider<GoRouter>((ref) {
  final roteador = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const TelaLista(),
        routes: [
          // 'item/novo' vem antes de 'item/:id' para "novo" não ser lido como id.
          GoRoute(
            path: 'item/novo',
            builder: (context, state) => const TelaItem(),
          ),
          GoRoute(
            path: 'item/:id',
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '');
              return id == null ? const TelaNaoEncontrada() : TelaItem(id: id);
            },
          ),
          GoRoute(
            path: 'sobre',
            builder: (context, state) => const TelaSobre(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => const TelaNaoEncontrada(),
  );
  ref.onDispose(roteador.dispose);
  return roteador;
});
```

- As rotas `item/novo`, `item/:id` e `sobre` são **filhas** de `/`. Ao abrir `/item/7` por qualquer meio, o go_router monta a pilha `[lista, item 7]`, e "voltar" conduz à lista em vez de fechar o aplicativo (Aula 14).
- A ordem importa: `item/novo` é declarada antes de `item/:id`; caso contrário, "novo" seria capturado como valor de `:id`.
- Um `id` não numérico ou um caminho inexistente levam à `TelaNaoEncontrada`, em vez de uma exceção.
- O roteador é criado dentro de um provider. Assim, cada teste recebe um roteador novo, começando em `/`, e o roteador é descartado com o `ProviderScope`.

### 8.2 Manifesto: registro do endereço `compras://`

Para que o Android entregue ao aplicativo os endereços `compras://app/...`, acrescentar ao `AndroidManifest.xml` um segundo `<intent-filter>`, **dentro** do elemento `<activity android:name=".MainActivity" ...>`, logo após o filtro `MAIN`/`LAUNCHER` existente:

```xml
            <!-- Ligação profunda: compras://app/item/7 abre o item 7. -->
            <intent-filter>
                <action android:name="android.intent.action.VIEW" />
                <category android:name="android.intent.category.DEFAULT" />
                <category android:name="android.intent.category.BROWSABLE" />
                <data android:scheme="compras" android:host="app" />
            </intent-filter>
```

**Esquema, host e caminho.** No endereço `compras://app/item/7`, `compras` é o esquema, `app` é o host e `/item/7` é o caminho. O Android usa esquema e host para decidir qual aplicativo abre o endereço; o Flutter entrega ao go_router **apenas o caminho**. Por isso as rotas são declaradas como `/item/:id`, sem o host. Desde o Flutter 3.27, o repasse de ligações profundas ao roteador vem habilitado por padrão; em versões anteriores, era preciso declarar `<meta-data android:name="flutter_deeplinking_enabled" android:value="true" />` na mesma `<activity>`.

## Passo 9: Camada de apresentação

### 9.1 Ponto de entrada `lib/main.dart`

Substituir todo o conteúdo do arquivo gerado:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

void main() {
  // ProviderScope guarda o estado de todos os providers do aplicativo.
  runApp(const ProviderScope(child: AppCompras()));
}
```

### 9.2 Aplicativo `lib/app.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'apresentacao/rotas.dart';
import 'config/identidade.dart';

class AppCompras extends ConsumerWidget {
  const AppCompras({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: Identidade.nomeDoApp,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Identidade.corSemente),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Identidade.corSemente,
          brightness: Brightness.dark,
        ),
      ),
      routerConfig: ref.watch(roteadorProvider),
    );
  }
}
```

`MaterialApp.router` delega a navegação ao go_router. `theme` e `darkTheme` derivam da mesma cor semente; o Flutter escolhe entre eles conforme a configuração do aparelho (Aula 6), sem nenhuma condição no código.

### 9.3 Tela principal `lib/apresentacao/telas/tela_lista.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/identidade.dart';
import '../../dominio/item.dart';
import '../../dominio/regras_item.dart';
import '../componentes/cartao_item.dart';
import '../componentes/faixa_offline.dart';
import '../providers.dart';

class TelaLista extends ConsumerWidget {
  const TelaLista({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itensAsync = ref.watch(itensProvider);
    final online = switch (ref.watch(conectividadeProvider)) {
      AsyncData(:final value) => value,
      _ => true, // enquanto o estado da rede é desconhecido, não há alerta
    };
    // select: esta tela só é reconstruída quando "emAndamento" muda.
    final sincronizando = ref.watch(
      sincronizacaoProvider.select((estado) => estado.emAndamento),
    );

    // Ao recuperar a conexão, envia automaticamente o que ficou pendente.
    ref.listen(conectividadeProvider, (anterior, atual) {
      final reconectou =
          anterior is AsyncData<bool> &&
          !anterior.value &&
          atual is AsyncData<bool> &&
          atual.value;
      if (reconectou) {
        ref.read(sincronizacaoProvider.notifier).sincronizar();
      }
    });

    // Exibe o resultado de cada sincronização.
    ref.listen(sincronizacaoProvider, (anterior, atual) {
      final mensagem = atual.mensagem;
      if (!atual.emAndamento && mensagem != null) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(mensagem)));
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text(Identidade.nomeDoApp),
        actions: [
          IconButton(
            tooltip: 'Enviar alterações',
            onPressed: sincronizando
                ? null
                : () => ref.read(sincronizacaoProvider.notifier).sincronizar(),
            icon: sincronizando
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.cloud_upload_outlined),
          ),
          IconButton(
            tooltip: 'Sobre o aplicativo',
            onPressed: () => context.go('/sobre'),
            icon: const Icon(Icons.info_outline),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/item/novo'),
        icon: const Icon(Icons.add),
        label: const Text('Novo item'),
      ),
      body: Column(
        children: [
          if (!online) const FaixaOffline(),
          Expanded(
            child: itensAsync.when(
              data: (itens) => _Conteudo(itens: itens),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (erro, _) => _Falha(
                erro: erro,
                aoTentarNovamente: () => ref.invalidate(itensProvider),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Conteudo extends StatelessWidget {
  const _Conteudo({required this.itens});

  final List<Item> itens;

  @override
  Widget build(BuildContext context) {
    if (itens.isEmpty) return const _EstadoVazio();

    final resumo = resumir(itens);
    // A altura do cartão acompanha a escala de fonte do sistema (Aula 4).
    final alturaDoCartao = MediaQuery.textScalerOf(context).scale(80);

    return LayoutBuilder(
      builder: (context, restricoes) {
        // Pontos de quebra de 600 e 840 dp (Aula 3).
        final colunas = restricoes.maxWidth < 600
            ? 1
            : restricoes.maxWidth < 840
            ? 2
            : 3;
        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _CabecalhoResumo(resumo: resumo)),
            SliverPadding(
              // 96 dp no fim: o botão flutuante não cobre o último item.
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              sliver: SliverGrid.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: colunas,
                  mainAxisExtent: alturaDoCartao,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                itemCount: itens.length,
                itemBuilder: (context, i) => CartaoItem(item: itens[i]),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CabecalhoResumo extends StatelessWidget {
  const _CabecalhoResumo({required this.resumo});

  final Resumo resumo;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${resumo.comprados} de ${resumo.total} itens comprados',
            style: textos.titleMedium,
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: resumo.progresso),
          if (resumo.aguardandoEnvio > 0) ...[
            const SizedBox(height: 8),
            Text(
              '${resumo.aguardandoEnvio} alteração(ões) aguardando envio',
              style: textos.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

class _EstadoVazio extends StatelessWidget {
  const _EstadoVazio();

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.shopping_basket_outlined,
              size: 64,
              color: tema.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text('A lista está vazia.', style: tema.textTheme.titleMedium),
            const SizedBox(height: 8),
            const Text(
              'Toque em "Novo item" para começar.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _Falha extends StatelessWidget {
  const _Falha({required this.erro, required this.aoTentarNovamente});

  final Object erro;
  final VoidCallback aoTentarNovamente;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Não foi possível ler a lista salva no aparelho.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text('$erro', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: aoTentarNovamente,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}
```

- **Três estados (Aula 4).** `itensAsync.when` exibe o indicador de carregamento, a mensagem de falha com opção de nova tentativa, ou o conteúdo. Dentro do conteúdo, a lista vazia tem estado próprio, com orientação sobre o que fazer.
- **Estado offline (Aula 13).** A faixa de aviso aparece acima da lista quando não há rede, sem bloquear o uso: os dados continuam sendo gravados no SQLite.
- **`ref.listen`** executa uma ação em resposta a uma mudança, sem reconstruir a tela. É usado para sincronizar quando a rede retorna e para exibir a `SnackBar` com o resultado.
- **`select`** faz a tela observar apenas o campo `emAndamento` do estado de sincronização. Mudanças apenas na mensagem não reconstroem a tela, o que antecipa as técnicas de redução de reconstruções da Aula 22.
- **Responsividade (Aulas 3 e 11).** O `LayoutBuilder` informa a largura disponível e define 1, 2 ou 3 colunas. A altura de cada cartão é multiplicada pela escala de fonte do sistema (`textScalerOf`); com altura fixa, um usuário com fonte ampliada (Aula 4) teria o texto cortado.
- **`CustomScrollView` com *slivers*** permite que o cabeçalho de resumo e a grade rolem juntos, como uma única lista.

### 9.4 Formulário `lib/apresentacao/telas/tela_item.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/identidade.dart';
import '../../dominio/item.dart';
import '../../dominio/regras_item.dart';
import '../providers.dart';
import 'tela_nao_encontrada.dart';

/// Localiza o item a editar (ou nenhum, para criar) e entrega ao formulário.
class TelaItem extends ConsumerWidget {
  const TelaItem({super.key, this.id});

  /// Nulo indica a criação de um item novo.
  final int? id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = this.id;
    if (id == null) return const FormularioItem();

    // Aberta por ligação profunda, esta tela pode surgir antes da lista carregar.
    return ref
        .watch(itensProvider)
        .when(
          loading: () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (erro, _) => Scaffold(
            appBar: AppBar(),
            body: Center(child: Text('Falha ao carregar: $erro')),
          ),
          data: (itens) {
            final item = itens.where((i) => i.id == id).firstOrNull;
            return item == null
                ? const TelaNaoEncontrada()
                : FormularioItem(item: item);
          },
        );
  }
}

class FormularioItem extends ConsumerStatefulWidget {
  const FormularioItem({super.key, this.item});

  final Item? item;

  @override
  ConsumerState<FormularioItem> createState() => _FormularioItemState();
}

class _FormularioItemState extends ConsumerState<FormularioItem> {
  final _chaveDoFormulario = GlobalKey<FormState>();
  late final TextEditingController _nome;
  late final TextEditingController _observacao;
  late String _categoria;
  late int _quantidade;
  bool _alterado = false;
  bool _salvando = false;

  bool get _editando => widget.item != null;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _nome = TextEditingController(text: item?.nome ?? '');
    _observacao = TextEditingController(text: item?.observacao ?? '');
    _categoria = item?.categoria ?? Identidade.categorias.first;
    _quantidade = item?.quantidade ?? 1;
  }

  @override
  void dispose() {
    _nome.dispose();
    _observacao.dispose();
    super.dispose();
  }

  void _marcarAlterado() {
    if (!_alterado) setState(() => _alterado = true);
  }

  void _mudarQuantidade(int variacao) {
    setState(() {
      _quantidade = ajustarQuantidade(_quantidade, variacao);
      _alterado = true;
    });
  }

  Future<void> _salvar() async {
    if (!_chaveDoFormulario.currentState!.validate()) return;
    setState(() => _salvando = true);

    final agora = DateTime.now();
    final original = widget.item;
    final item = original == null
        ? Item(
            nome: _nome.text.trim(),
            quantidade: _quantidade,
            categoria: _categoria,
            observacao: _observacao.text.trim(),
            criadoEm: agora,
            atualizadoEm: agora,
          )
        : original.copyWith(
            nome: _nome.text.trim(),
            quantidade: _quantidade,
            categoria: _categoria,
            observacao: _observacao.text.trim(),
          );

    try {
      await ref.read(itensProvider.notifier).salvar(item);
      if (!mounted) return;
      // Um pop explícito não é bloqueado pelo PopScope, que intercepta apenas
      // o "voltar" do sistema e o botão de voltar da AppBar.
      context.pop();
    } catch (erro) {
      if (!mounted) return;
      setState(() => _salvando = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Não foi possível salvar: $erro')));
    }
  }

  Future<bool> _confirmarDescarte() async {
    final descartar = await showDialog<bool>(
      context: context,
      builder: (contextoDoDialogo) => AlertDialog(
        title: const Text('Descartar alterações?'),
        content: const Text(
          'As alterações feitas neste formulário serão perdidas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(contextoDoDialogo).pop(false),
            child: const Text('Continuar editando'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(contextoDoDialogo).pop(true),
            child: const Text('Descartar'),
          ),
        ],
      ),
    );
    return descartar ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    // Mantém a categoria atual entre as opções, mesmo que a lista de
    // Identidade.categorias tenha mudado depois de o item ser salvo.
    final categorias = {...Identidade.categorias, _categoria}.toList();

    return PopScope(
      canPop: !_alterado,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final descartar = await _confirmarDescarte();
        if (descartar && context.mounted) context.pop();
      },
      child: Scaffold(
        appBar: AppBar(title: Text(_editando ? 'Editar item' : 'Novo item')),
        body: SafeArea(
          top: false,
          child: Center(
            child: ConstrainedBox(
              // Em telas largas, o formulário não passa de 600 dp (Aula 3).
              constraints: const BoxConstraints(maxWidth: 600),
              child: Form(
                key: _chaveDoFormulario,
                onChanged: _marcarAlterado,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    TextFormField(
                      controller: _nome,
                      autofocus: !_editando,
                      textCapitalization: TextCapitalization.sentences,
                      maxLength: tamanhoMaximoNome,
                      decoration: const InputDecoration(
                        labelText: 'Nome do item',
                        border: OutlineInputBorder(),
                      ),
                      validator: (valor) => validarNome(valor ?? ''),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _categoria,
                      decoration: const InputDecoration(
                        labelText: 'Categoria',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        for (final categoria in categorias)
                          DropdownMenuItem(
                            value: categoria,
                            child: Text(categoria),
                          ),
                      ],
                      onChanged: (valor) {
                        if (valor != null) setState(() => _categoria = valor);
                      },
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: Text('Quantidade', style: textos.titleMedium),
                        ),
                        IconButton.outlined(
                          tooltip: 'Diminuir quantidade',
                          onPressed: _quantidade > quantidadeMinima
                              ? () => _mudarQuantidade(-1)
                              : null,
                          icon: const Icon(Icons.remove),
                        ),
                        ConstrainedBox(
                          constraints: const BoxConstraints(minWidth: 56),
                          child: Text(
                            '$_quantidade',
                            textAlign: TextAlign.center,
                            style: textos.titleLarge,
                          ),
                        ),
                        IconButton.outlined(
                          tooltip: 'Aumentar quantidade',
                          onPressed: _quantidade < quantidadeMaxima
                              ? () => _mudarQuantidade(1)
                              : null,
                          icon: const Icon(Icons.add),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _observacao,
                      minLines: 2,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Observação (opcional)',
                        hintText: 'Marca, tamanho, sabor...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 32),
                    FilledButton.icon(
                      onPressed: _salvando ? null : _salvar,
                      icon: const Icon(Icons.check),
                      label: Text(
                        _editando ? 'Salvar alterações' : 'Adicionar à lista',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

- **Separação entre localizar e editar.** `TelaItem` resolve qual item exibir, inclusive quando aberta por ligação profunda antes de a lista carregar. `FormularioItem` cuida apenas da edição, e seus controladores são inicializados uma única vez em `initState`.
- **Validação pelo domínio.** `validator: (valor) => validarNome(valor ?? '')` reaproveita a regra do Passo 3. A interface não repete a lógica de validação.
- **`PopScope` (Aula 14).** Enquanto houver alteração não salva, `canPop` é falso: o "voltar" do sistema e o botão de voltar da barra superior são interceptados, e um diálogo pergunta se as alterações devem ser descartadas. Após salvar, `context.pop()` fecha a tela diretamente, porque uma chamada explícita de `pop` não é bloqueada pelo `PopScope`.
- **`Form.onChanged`** é chamado a cada alteração nos campos de texto e na lista de categorias; a quantidade, controlada por botões, marca a alteração em `_mudarQuantidade`.
- **Categoria preservada.** O conjunto `{...Identidade.categorias, _categoria}` garante que a categoria de um item antigo continue disponível mesmo que a lista de categorias tenha sido alterada em `identidade.dart`. Sem isso, o `DropdownButtonFormField` encerraria o aplicativo com um erro de valor inexistente.
- **UX writing (Aula 10).** Os botões descrevem a ação ("Adicionar à lista", "Salvar alterações", "Descartar", "Continuar editando"), e não "OK" ou "Cancelar".

### 9.5 Tela "Sobre" `lib/apresentacao/telas/tela_sobre.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/identidade.dart';
import '../providers.dart';

class TelaSobre extends ConsumerWidget {
  const TelaSobre({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textos = Theme.of(context).textTheme;
    final dispositivo = ref.watch(infoDispositivoProvider);
    final bancoCriadoEm = ref.watch(bancoCriadoEmProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Sobre')),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(Identidade.nomeDoApp, style: textos.headlineSmall),
                const SizedBox(height: 8),
                Text(Identidade.descricao, style: textos.bodyLarge),
                const Divider(height: 32),
                Text('Autoria', style: textos.titleMedium),
                for (final integrante in Identidade.integrantes)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.person_outline),
                    title: Text(integrante.nome),
                    subtitle: Text('Matrícula ${integrante.matricula}'),
                  ),
                const ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.school_outlined),
                  title: Text(Identidade.turma),
                ),
                const Divider(height: 32),
                Text(
                  'Dispositivo (canal de plataforma)',
                  style: textos.titleMedium,
                ),
                const SizedBox(height: 8),
                dispositivo.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (erro, _) => Text('Falha na consulta: $erro'),
                  data: (info) => Text(
                    info == null
                        ? 'Informação indisponível nesta plataforma.'
                        : '${info.fabricante} ${info.modelo}\n'
                              'Android ${info.versaoAndroid} · '
                              'bateria em ${info.nivelBateria}%',
                  ),
                ),
                const Divider(height: 32),
                Text('Banco de dados local', style: textos.titleMedium),
                const SizedBox(height: 8),
                Text(
                  bancoCriadoEm.when(
                    loading: () => 'Consultando...',
                    error: (erro, _) => 'Falha na consulta: $erro',
                    data: (data) => data == null
                        ? 'Data de criação não registrada.'
                        : 'Criado neste aparelho em ${_formatar(data)}.',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _formatar(DateTime data) {
  String dois(int n) => n.toString().padLeft(2, '0');
  return '${dois(data.day)}/${dois(data.month)}/${data.year} '
      'às ${dois(data.hour)}:${dois(data.minute)}';
}
```

A tela reúne três fontes de dados de naturezas diferentes: constantes de `identidade.dart`, uma chamada ao código Kotlin pelo canal de plataforma e uma consulta ao banco SQLite. Cada consulta assíncrona é tratada com `.when`, de modo que a tela é exibida imediatamente e cada parte é preenchida quando o respectivo dado chega.

### 9.6 Tela de endereço inválido `lib/apresentacao/telas/tela_nao_encontrada.dart`

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class TelaNaoEncontrada extends StatelessWidget {
  const TelaNaoEncontrada({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Página não encontrada')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'O endereço solicitado não corresponde a nenhum item da lista.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.go('/'),
                child: const Text('Ir para a lista'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

### 9.7 Cartão `lib/apresentacao/componentes/cartao_item.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../dominio/item.dart';
import '../providers.dart';

class CartaoItem extends ConsumerWidget {
  const CartaoItem({super.key, required this.item});

  final Item item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cores = Theme.of(context).colorScheme;
    final notifier = ref.read(itensProvider.notifier);

    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: cores.errorContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.delete_outline, color: cores.onErrorContainer),
      ),
      onDismissed: (_) => notifier.excluir(item),
      child: Card(
        margin: EdgeInsets.zero,
        child: ListTile(
          onTap: () => context.go('/item/${item.id}'),
          leading: Checkbox(
            value: item.comprado,
            onChanged: (_) => notifier.alternarComprado(item),
          ),
          title: Text(
            item.nome,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: item.comprado
                ? const TextStyle(decoration: TextDecoration.lineThrough)
                : null,
          ),
          subtitle: Text(
            '${item.categoria} · ${item.quantidade} un.',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Icon(
            item.sincronizado
                ? Icons.cloud_done_outlined
                : Icons.cloud_upload_outlined,
            color: item.sincronizado ? cores.primary : cores.outline,
            semanticLabel: item.sincronizado
                ? 'Enviado ao servidor'
                : 'Aguardando envio',
          ),
        ),
      ),
    );
  }
}
```

- `ValueKey(item.id)` identifica o cartão de forma estável, requisito do `Dismissible` para saber qual item foi arrastado.
- O estado de envio é comunicado por **dois canais** (Aula 10): o ícone muda de forma (nuvem com seta ou com marca de confirmação) e de cor. `semanticLabel` descreve o ícone para o leitor de tela (Aula 4).
- O cartão usa os tokens do tema (`errorContainer`, `onErrorContainer`, `primary`, `outline`), e não cores fixas, de modo que funciona nos temas claro e escuro.

### 9.8 Aviso de ausência de rede `lib/apresentacao/componentes/faixa_offline.dart`

```dart
import 'package:flutter/material.dart';

/// Aviso de ausência de rede. liveRegion faz o leitor de tela anunciá-lo.
class FaixaOffline extends StatelessWidget {
  const FaixaOffline({super.key});

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      child: Material(
        color: cores.secondaryContainer,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.wifi_off, size: 20, color: cores.onSecondaryContainer),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Sem conexão. As alterações ficam salvas no aparelho e '
                  'serão enviadas depois.',
                  style: TextStyle(color: cores.onSecondaryContainer),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

`Semantics(liveRegion: true)` faz o leitor de tela anunciar o aviso quando ele aparece, sem que o usuário precise navegar até ele.

## Passo 10: Testes automatizados

### 10.1 Apoio `test/apoio/repositorio_em_memoria.dart`

Implementação do contrato `ItemRepository` em memória, usada no teste de interface no lugar do SQLite:

```dart
import 'package:compras/dominio/item.dart';
import 'package:compras/dominio/item_repository.dart';

/// Implementação do contrato só em memória, para testes de interface.
class RepositorioEmMemoria implements ItemRepository {
  RepositorioEmMemoria([List<Item> iniciais = const []]) {
    for (final item in iniciais) {
      _itens[item.id!] = item;
    }
    _proximoId =
        _itens.keys.fold<int>(0, (maior, id) => id > maior ? id : maior) + 1;
  }

  final _itens = <int, Item>{};
  late int _proximoId;

  @override
  Future<List<Item>> listar() async => _itens.values.toList();

  @override
  Future<Item> salvar(Item item) async {
    final salvo = item.copyWith(
      id: item.id ?? _proximoId++,
      sincronizado: false,
    );
    _itens[salvo.id!] = salvo;
    return salvo;
  }

  @override
  Future<void> excluir(int id) async {
    _itens.remove(id);
  }

  @override
  Future<List<Item>> listarNaoSincronizados() async =>
      _itens.values.where((item) => !item.sincronizado).toList();

  @override
  Future<void> marcarComoSincronizado(Item item) async {
    final atual = _itens[item.id];
    if (atual != null) _itens[atual.id!] = atual.copyWith(sincronizado: true);
  }
}
```

### 10.2 Regras de domínio `test/dominio/regras_item_test.dart`

```dart
import 'package:compras/dominio/item.dart';
import 'package:compras/dominio/regras_item.dart';
import 'package:flutter_test/flutter_test.dart';

Item _item(
  String nome,
  String categoria, {
  bool comprado = false,
  bool sincronizado = true,
}) {
  final data = DateTime(2026);
  return Item(
    nome: nome,
    categoria: categoria,
    comprado: comprado,
    sincronizado: sincronizado,
    criadoEm: data,
    atualizadoEm: data,
  );
}

void main() {
  group('validarNome', () {
    test('recusa nome vazio ou só com espaços', () {
      expect(validarNome('   '), isNotNull);
    });

    test('recusa nome curto demais', () {
      expect(validarNome('a'), isNotNull);
    });

    test('recusa nome longo demais', () {
      expect(validarNome('x' * (tamanhoMaximoNome + 1)), isNotNull);
    });

    test('aceita nome válido, ignorando espaços nas pontas', () {
      expect(validarNome('  Café  '), isNull);
    });
  });

  group('ajustarQuantidade', () {
    test('soma e subtrai dentro dos limites', () {
      expect(ajustarQuantidade(3, 1), 4);
      expect(ajustarQuantidade(3, -1), 2);
    });

    test('não ultrapassa os limites', () {
      expect(ajustarQuantidade(quantidadeMinima, -1), quantidadeMinima);
      expect(ajustarQuantidade(quantidadeMaxima, 1), quantidadeMaxima);
    });
  });

  test('ordena itens a comprar primeiro, depois por categoria e nome', () {
    final ordenados = ordenarParaExibicao([
      _item('Sabão', 'Limpeza', comprado: true),
      _item('Feijão', 'Mercearia'),
      _item('Alface', 'Hortifrúti'),
      _item('Arroz', 'Mercearia'),
    ]);
    expect(ordenados.map((item) => item.nome).toList(), [
      'Alface',
      'Arroz',
      'Feijão',
      'Sabão',
    ]);
  });

  test('resumo conta comprados e alterações aguardando envio', () {
    final resumo = resumir([
      _item('A', 'X', comprado: true),
      _item('B', 'X', sincronizado: false),
      _item('C', 'X'),
    ]);
    expect(resumo.total, 3);
    expect(resumo.comprados, 1);
    expect(resumo.aguardandoEnvio, 1);
    expect(resumo.progresso, closeTo(1 / 3, 0.001));
  });
}
```

### 10.3 Nova tentativa `test/dados/nova_tentativa_test.dart`

```dart
import 'package:compras/dados/remoto/nova_tentativa.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('repete falhas transitórias até obter sucesso', () async {
    var chamadas = 0;
    final resultado = await comNovaTentativa(() async {
      chamadas++;
      if (chamadas < 3) throw const FalhaTransitoria('rede instável');
      return 'ok';
    }, esperaBase: Duration.zero);
    expect(resultado, 'ok');
    expect(chamadas, 3);
  });

  test('desiste após o número máximo de tentativas', () async {
    var chamadas = 0;
    await expectLater(
      comNovaTentativa<void>(
        () async {
          chamadas++;
          throw const FalhaTransitoria('servidor fora do ar');
        },
        maxTentativas: 2,
        esperaBase: Duration.zero,
      ),
      throwsA(isA<FalhaTransitoria>()),
    );
    expect(chamadas, 2);
  });
}
```

### 10.4 Repositório com SQLite real `test/dados/item_repository_sqlite_test.dart`

```dart
import 'package:compras/dados/local/banco_de_dados.dart';
import 'package:compras/dados/local/item_repository_sqlite.dart';
import 'package:compras/dominio/item.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late BancoDeDados banco;
  late ItemRepositorySqlite repositorio;

  setUpAll(sqfliteFfiInit);

  setUp(() {
    // Banco em memória: cada teste começa vazio e nada é gravado em disco.
    banco = BancoDeDados(
      fabrica: databaseFactoryFfi,
      caminho: inMemoryDatabasePath,
    );
    repositorio = ItemRepositorySqlite(banco);
  });

  tearDown(() => banco.fechar());

  Item novo(String nome) {
    final data = DateTime(2026, 3, 1);
    return Item(
      nome: nome,
      categoria: 'Mercearia',
      criadoEm: data,
      atualizadoEm: data,
    );
  }

  test('insere e lê de volta todos os campos', () async {
    final salvo = await repositorio.salvar(
      novo('Café').copyWith(quantidade: 2, observacao: 'Torra média'),
    );
    expect(salvo.id, isNotNull);

    final lido = (await repositorio.listar()).single;
    expect(lido.id, salvo.id);
    expect(lido.nome, 'Café');
    expect(lido.quantidade, 2);
    expect(lido.observacao, 'Torra média');
    expect(lido.comprado, isFalse);
    expect(lido.sincronizado, isFalse);
  });

  test('atualiza um item existente sem duplicá-lo', () async {
    final salvo = await repositorio.salvar(novo('Leite'));
    await repositorio.salvar(salvo.copyWith(comprado: true));

    final itens = await repositorio.listar();
    expect(itens, hasLength(1));
    expect(itens.single.comprado, isTrue);
  });

  test('exclui pelo id', () async {
    final salvo = await repositorio.salvar(novo('Pão'));
    await repositorio.excluir(salvo.id!);
    expect(await repositorio.listar(), isEmpty);
  });

  test('marca como enviada a versão que foi enviada', () async {
    await repositorio.salvar(novo('Sal'));
    final enviado = (await repositorio.listarNaoSincronizados()).single;
    await repositorio.marcarComoSincronizado(enviado);
    expect(await repositorio.listarNaoSincronizados(), isEmpty);
  });

  test('não marca como enviada uma versão alterada durante o envio', () async {
    final salvo = await repositorio.salvar(novo('Ovos'));
    final enviado = (await repositorio.listarNaoSincronizados()).single;

    // Alteração feita depois da leitura para envio e antes da confirmação.
    await Future<void>.delayed(const Duration(milliseconds: 5));
    await repositorio.salvar(salvo.copyWith(quantidade: 12));
    await repositorio.marcarComoSincronizado(enviado);

    expect(await repositorio.listarNaoSincronizados(), hasLength(1));
  });
}
```

`sqfliteFfiInit` carrega o SQLite do próprio computador, e `inMemoryDatabasePath` cria o banco apenas na memória, de modo que cada teste começa com um banco vazio e nada é gravado em disco. O teste executa o mesmo código SQL que roda no Android, sem emulador.

### 10.5 Interface `test/apresentacao/fluxo_da_lista_test.dart`

```dart
import 'package:compras/app.dart';
import 'package:compras/apresentacao/providers.dart';
import 'package:compras/dominio/item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../apoio/repositorio_em_memoria.dart';

void main() {
  testWidgets('lista os itens salvos e adiciona um item novo', (tester) async {
    final data = DateTime(2026, 1, 1);
    final repositorio = RepositorioEmMemoria([
      Item(
        id: 1,
        nome: 'Arroz',
        categoria: 'Mercearia',
        criadoEm: data,
        atualizadoEm: data,
      ),
    ]);

    await tester.pumpWidget(
      ProviderScope(
        // Substitui o SQLite e o plugin de conectividade por versões de teste.
        overrides: [
          itemRepositoryProvider.overrideWithValue(repositorio),
          conectividadeProvider.overrideWith((ref) => Stream.value(true)),
        ],
        child: const AppCompras(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Arroz'), findsOneWidget);

    // Salvar sem nome: a regra de domínio recusa e a mensagem aparece.
    await tester.tap(find.text('Novo item'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Adicionar à lista'));
    await tester.pump();
    expect(find.text('Informe o nome do item.'), findsOneWidget);

    // Com nome preenchido, o item é salvo e a lista volta a ser exibida.
    await tester.enterText(find.byType(TextFormField).first, 'Café');
    await tester.tap(find.text('Adicionar à lista'));
    await tester.pumpAndSettle();
    expect(find.text('Café'), findsOneWidget);
    expect(find.text('Arroz'), findsOneWidget);
  });
}
```

O `ProviderScope` do teste substitui duas dependências por versões controladas: o repositório SQLite pelo repositório em memória e o plugin de conectividade por um fluxo que informa "conectado". Nenhuma outra linha do aplicativo foi escrita pensando no teste; a substituição é possível porque as telas dependem de providers, e não de classes concretas (§2.1).

## 4. Formas de executar

### 4.1 Primeira execução

Com um emulador aberto ou um celular conectado (ver adiante), abrir `lib/main.dart` no VS Code e pressionar **F5**. A primeira compilação Android leva alguns minutos, pois o Gradle baixa dependências; as seguintes são muito mais rápidas.

**Resultado esperado:** a tela "A lista está vazia", com o nome definido em `identidade.dart` na barra superior. Cadastrar alguns itens, marcar um como comprado, fechar o aplicativo pelo botão de aplicativos recentes do Android e abri-lo de novo: os itens devem permanecer.

### 4.2 Emulador Android

1. No Android Studio, **More Actions > Virtual Device Manager > Create Virtual Device**.
2. Escolher um modelo (por exemplo, *Medium Phone* ou *Pixel 8*) e uma imagem de sistema **x86_64** recente, baixando-a se necessário. Imagens x86_64 executam com aceleração de hardware nos processadores Intel e AMD.
3. No VS Code, `Ctrl+Shift+P` > **Flutter: Launch Emulator**, ou clicar no nome do dispositivo na barra de status (canto inferior direito) e escolher o emulador.
4. Pressionar **F5**.

Pelo terminal:

```powershell
flutter emulators
flutter emulators --launch <id_do_emulador>
flutter run
```

Para testar a responsividade, criar também um emulador de tablet (*Pixel Tablet*) ou um dobrável (*Pixel Fold*), ou usar o emulador *Resizable*, que alterna entre tamanhos de tela sem reiniciar.

### 4.3 Celular Android por cabo USB

1. No celular, ativar as **Opções do desenvolvedor**: *Configurações > Sobre o telefone*, tocar sete vezes em **Número da versão**.
2. Em *Configurações > Sistema > Opções do desenvolvedor*, ativar **Depuração USB**.
3. Conectar o cabo (que precisa transmitir dados, e não apenas carregar) e aceitar a janela **Permitir depuração USB?** no celular.
4. Confirmar o reconhecimento com `flutter devices`. No Windows, alguns fabricantes exigem o driver USB próprio, disponível no site do fabricante; aparelhos Pixel usam o *Google USB Driver*, instalável pelo SDK Manager.
5. Escolher o celular na barra de status do VS Code e pressionar **F5**, ou executar `flutter run -d <id>`.

### 4.4 Celular Android por Wi-Fi

Disponível no Android 11 ou posterior, com computador e celular na mesma rede:

1. Em *Opções do desenvolvedor*, ativar **Depuração por Wi-Fi** e tocar em **Parear dispositivo com código de pareamento**.
2. No computador:

   ```powershell
   adb pair <ip>:<porta_de_pareamento>
   adb connect <ip>:<porta>
   flutter devices
   ```

   A porta de pareamento e a porta de conexão são diferentes; ambas aparecem na tela do celular.

### 4.5 Modos de compilação

| Modo | Comando | Compilação | Uso |
|---|---|---|---|
| Debug | `flutter run` ou **F5** | JIT (Aula 11) | Desenvolvimento: hot reload, depurador, verificações (`assert`) ativas |
| Profile | `flutter run --profile` | AOT, com instrumentação | Medição de desempenho com o DevTools (Aula 22). Recomenda-se dispositivo físico, pois o emulador não representa o desempenho real |
| Release | `flutter run --release` | AOT, otimizado | Comportamento e desempenho finais; sem depurador nem hot reload |

No VS Code, os três modos podem ser oferecidos no menu de execução por meio do arquivo `.vscode/launch.json`:

```json
{
  "version": "0.2.0",
  "configurations": [
    { "name": "compras (debug)", "request": "launch", "type": "dart" },
    { "name": "compras (profile)", "request": "launch", "type": "dart", "flutterMode": "profile" },
    { "name": "compras (release)", "request": "launch", "type": "dart", "flutterMode": "release" }
  ]
}
```

### 4.6 Hot reload, hot restart e reinício completo

| Ação | Atalho | O que preserva | Quando usar |
|---|---|---|---|
| Hot reload | `Ctrl+S` no VS Code; `r` no terminal | Estado da tela e dos providers | Alterações em `build`, estilos, textos |
| Hot restart | `Ctrl+Shift+F5`; `R` no terminal | Apenas o banco SQLite, que está em disco | Alterações em `main`, em `initState` ou no estado inicial de providers |
| Parar e executar | `Shift+F5`, depois `F5` | Apenas o banco SQLite | Alterações em Kotlin, manifesto, Gradle ou inclusão de pacotes |

### 4.7 Flutter DevTools

Com o aplicativo em execução, `Ctrl+Shift+P` > **Flutter: Open DevTools**. O **Widget Inspector** exibe a árvore de widgets real (Aula 11) e permite selecionar um elemento na tela para localizá-lo no código; a aba **Performance**, em modo *profile*, mostra o tempo de cada quadro (Aula 22).

## 5. Formas de testar

### 5.1 Análise estática

```powershell
flutter analyze
```

Verifica tipos, importações não usadas e as regras do pacote `flutter_lints`, sem executar o código. O resultado esperado é `No issues found!`.

### 5.2 Testes automatizados

```powershell
flutter test                              # todos os testes
flutter test test/dominio                 # apenas uma pasta
flutter test --name "ordena"              # apenas testes cujo nome contém "ordena"
flutter test --coverage                   # gera coverage/lcov.info
```

O resultado esperado é `All tests passed!`, com 16 testes. No VS Code, o painel **Testing** (ícone de frasco na barra lateral) lista cada teste e permite executá-lo ou depurá-lo individualmente; os mesmos comandos aparecem como links **Run | Debug** acima de cada `test(` no editor.

| Nível | Arquivo | O que verifica | Depende de |
|---|---|---|---|
| Unidade (domínio) | `regras_item_test.dart` | Validação, limites de quantidade, ordenação, resumo | Apenas Dart |
| Unidade (dados) | `nova_tentativa_test.dart` | Repetição de falhas transitórias e desistência | Apenas Dart |
| Integração (dados) | `item_repository_sqlite_test.dart` | SQL real: inserção, atualização, exclusão, concorrência otimista | SQLite do computador |
| Interface | `fluxo_da_lista_test.dart` | Lista, navegação, validação e gravação de ponta a ponta | Flutter, sem emulador |

Se o teste de repositório falhar ao carregar a biblioteca do SQLite no computador (mensagem mencionando `sqlite3.dll`), baixar o pacote *Precompiled Binaries for Windows* (64 bits) em [sqlite.org/download.html](https://sqlite.org/download.html), extrair `sqlite3.dll` em uma pasta incluída no `Path` (por exemplo, `C:\dev\sqlite`) e abrir um novo terminal.

### 5.3 Inspeção do banco no aparelho

Com o aplicativo em execução em modo debug:

- **Database Inspector:** abrir a pasta `android/` do projeto no Android Studio e acessar **View > Tool Windows > App Inspection**, aba **Database Inspector**. As tabelas `itens` e `metadados` aparecem com os dados atuais, e é possível executar consultas SQL como `SELECT * FROM itens WHERE sincronizado = 0`.
- **Cópia do arquivo:** no Prompt de Comando (`cmd`), e não no PowerShell, cujo redirecionamento `>` corrompe arquivos binários:

  ```bat
  adb exec-out run-as br.com.equipeexemplo.compras cat databases/compras.db > compras.db
  ```

  O arquivo copiado pode ser aberto no [DB Browser for SQLite](https://sqlitebrowser.org/). Como o Android pode manter alterações recentes em um arquivo auxiliar (`compras.db-wal`), o Database Inspector é a forma mais confiável de ver o estado atual.

### 5.4 Roteiro de testes manuais

| Cenário | Procedimento | Resultado esperado |
|---|---|---|
| Persistência | Cadastrar itens, encerrar o aplicativo pela tela de recentes, abrir de novo | Itens, marcações e quantidades preservados |
| Validação | Tentar salvar com nome vazio ou de 1 caractere | Mensagem de erro abaixo do campo; nada é gravado |
| Descarte | Abrir um item, alterar o nome e tocar em voltar | Diálogo "Descartar alterações?"; "Continuar editando" mantém o formulário |
| Exclusão | Arrastar um cartão para a esquerda | Item removido; continua removido após reabrir |
| Offline | Ativar o modo avião, cadastrar um item | Faixa "Sem conexão"; ícone de envio pendente no cartão |
| Retorno da rede | Desativar o modo avião | Sincronização automática e mensagem com o resultado; ícones de confirmação nos itens enviados |
| Falhas do servidor | Tocar em "Enviar alterações" várias vezes | Alguns envios falham e são repetidos; itens não enviados continuam pendentes |
| Ligação profunda | `adb shell am start -W -a android.intent.action.VIEW -d "compras://app/item/1" br.com.equipeexemplo.compras` | Abre o item 1; "voltar" leva à lista |
| Endereço inválido | Mesmo comando com `compras://app/item/abc` ou um id inexistente | Tela "Página não encontrada" |
| Canal de plataforma | Abrir "Sobre" | Fabricante, modelo, versão do Android e bateria do aparelho |
| Responsividade | Girar o aparelho; usar emulador de tablet ou dobrável | 1 coluna abaixo de 600 dp, 2 até 840 dp, 3 acima |
| Escala de fonte | *Configurações > Tela > Tamanho da fonte* no máximo | Textos legíveis, sem cortes nem sobreposição |
| Tema escuro | Ativar o tema escuro do sistema | Cores adaptadas; contraste adequado em todos os textos |
| Leitor de tela | Ativar o TalkBack e percorrer a lista | Ícones e botões com descrição falada |

O último parâmetro do comando `adb` de ligação profunda é o `applicationId`. Ele restringe a entrega ao aplicativo indicado, o que evita a janela de escolha quando mais de um aplicativo instalado registra o esquema `compras://`.

## 6. Geração e instalação do APK

### 6.1 O que é o APK e como é gerado

O APK (*Android Package*) é o arquivo instalável de um aplicativo Android: um pacote compactado com o código compilado, os recursos e o manifesto, **assinado digitalmente**. O Android só instala APKs assinados e só permite atualizar um aplicativo instalado com um APK assinado pela **mesma chave**.

Antes de cada versão distribuída, convém ajustar a versão em `pubspec.yaml`:

```yaml
version: 1.0.0+1
```

`1.0.0` é o nome da versão, exibido ao usuário (`versionName`); `1`, após o `+`, é o número interno (`versionCode`), que precisa crescer a cada atualização instalada sobre a anterior.

| Comando | Resultado em `build\app\outputs\flutter-apk\` | Uso |
|---|---|---|
| `flutter build apk` | `app-release.apk` (APK universal) | Distribuição simples: funciona em qualquer arquitetura de processador |
| `flutter build apk --split-per-abi` | `app-arm64-v8a-release.apk`, `app-armeabi-v7a-release.apk`, `app-x86_64-release.apk` | Arquivos menores, um por arquitetura |
| `flutter build apk --debug` | `app-debug.apk` | Testes rápidos; maior e mais lento |

O APK universal contém o código nativo das três arquiteturas e por isso é maior. Os APKs separados são menores, mas exigem escolher o arquivo correto: celulares atuais usam `arm64-v8a`; emuladores em computadores Intel e AMD usam `x86_64`. A arquitetura de um aparelho conectado é informada por:

```powershell
adb shell getprop ro.product.cpu.abi
```

**Assinatura.** O projeto gerado pelo `flutter create` assina o build de release com a **chave de depuração** do computador (`%USERPROFILE%\.android\debug.keystore`), conforme o comentário `TODO` em `android/app/build.gradle.kts`. Isso basta para instalar e testar o APK, mas tem duas consequências:

- cada computador possui uma chave de depuração diferente. Um APK gerado em outro computador **não atualiza** a instalação anterior; é preciso desinstalar primeiro;
- a Google Play não aceita a chave de depuração. A publicação exige uma chave própria, criada com `keytool` e configurada no Gradle, conforme o guia [Build and release an Android app](https://docs.flutter.dev/deployment/android).

Para distribuição, recomenda-se renomear o arquivo com o identificador e a versão, por exemplo `compras-equipeexemplo-v1.0.0.apk`. O nome do arquivo não afeta a instalação, mas permite identificar a origem e a versão quando vários APKs circulam.

### 6.2 Formas de instalação

| Forma | Procedimento | Requisito |
|---|---|---|
| `flutter install` | Após `flutter build apk`, executar `flutter install` (ou `flutter install -d <id>`) | Aparelho conectado e reconhecido pelo `flutter devices` |
| `adb install` | `adb install -r build\app\outputs\flutter-apk\app-release.apk`. O `-r` substitui uma instalação existente, preservando os dados. Com vários aparelhos, `adb -s <id> install ...` | `adb` no `Path`; depuração USB ou Wi-Fi ativa |
| Arrastar para o emulador | Arrastar o arquivo `.apk` do Explorador de Arquivos para a janela do emulador | Emulador em execução |
| Cópia por cabo | Conectar o celular no modo **Transferência de arquivos**, copiar o APK para a pasta `Download` e abri-lo pelo aplicativo **Arquivos** | Permissão "Instalar apps desconhecidos" para o aplicativo Arquivos |
| Link de download | Enviar o APK a um serviço de armazenamento (Google Drive, OneDrive), anexá-lo a uma *release* do GitHub ou enviá-lo por e-mail ou mensageiro; abrir o link no celular | Permissão "Instalar apps desconhecidos" para o navegador ou aplicativo usado |
| Código QR | Gerar um código QR com o link de download e lê-lo com a câmera do celular | Mesmo da forma anterior |
| Plataforma de distribuição de testes | Enviar o APK ao Firebase App Distribution, que notifica os testadores por e-mail | Conta no Firebase; testadores cadastrados |
| Google Play (teste interno) | Gerar o pacote com `flutter build appbundle` e publicá-lo em uma faixa de teste interno no Play Console | Conta de desenvolvedor e chave de assinatura própria; usa o formato AAB, e não APK |

**Instalação de fontes desconhecidas.** Ao abrir um APK fora da loja, o Android solicita que o aplicativo usado para abri-lo (Arquivos, navegador, mensageiro) seja autorizado a instalar aplicativos. A autorização é concedida por aplicativo, em *Configurações > Apps > Acesso especial > Instalar apps desconhecidos*. O Google Play Protect pode exibir um alerta sobre aplicativo de desenvolvedor não verificado; o detalhamento do alerta oferece a opção de prosseguir com a instalação.

**Verificação da instalação:**

```powershell
adb shell pm list packages | findstr compras
```

O resultado `package:br.com.equipeexemplo.compras` (com o identificador escolhido) confirma a instalação. Para remover o aplicativo e seus dados:

```powershell
adb uninstall br.com.equipeexemplo.compras
```

### 6.3 Falhas de instalação

| Mensagem | Causa | Solução |
|---|---|---|
| `INSTALL_FAILED_UPDATE_INCOMPATIBLE` ou "App não instalado" | O aplicativo instalado foi assinado com outra chave (por exemplo, gerado em outro computador) | `adb uninstall <applicationId>` e instalar de novo |
| `INSTALL_FAILED_VERSION_DOWNGRADE` | O `versionCode` do APK é menor que o do instalado | Incrementar o número após o `+` em `version` no `pubspec.yaml` |
| `INSTALL_FAILED_NO_MATCHING_ABIS` | APK separado de arquitetura diferente da do aparelho | Usar o APK correto (`adb shell getprop ro.product.cpu.abi`) ou o universal |
| "Aplicativo bloqueado para sua proteção" | Play Protect | Abrir os detalhes do alerta e prosseguir |

## Erros comuns

| Sintoma | Causa provável | Solução |
|---|---|---|
| `Building with plugins requires symlink support` | Modo de desenvolvedor do Windows desativado | §1.6 |
| `Android sdkmanager not found` ou licenças não aceitas | *Command-line Tools* ausentes | §1.5, itens 2 e 3 |
| Emulador não inicia ou fica extremamente lento | Virtualização desativada ou sem hipervisor | §1.1 e §1.7 |
| Falha do Gradle com caminho "inválido" ou "não encontrado" | Projeto em pasta com espaço ou acento | Mover o projeto para `C:\dev\projetos` |
| `Failed to open output file ... The parent directory may not exist` seguido de `Font subsetting failed` no `flutter build apk` | Caminho do projeto longo demais: o Windows limita caminhos a 260 caracteres, e o build cria subpastas profundas | Mover o projeto para uma pasta curta, como `C:\dev\projetos` |
| `'adb' não é reconhecido como um comando` | `platform-tools` fora do `Path` | §1.5, item 4, e abrir novo terminal |
| `MissingPluginException` ao abrir o banco ou consultar a rede | Pacote incluído com o aplicativo em execução | Parar e executar de novo; hot reload não carrega plugins |
| `No ProviderScope found` | `runApp` sem `ProviderScope` | Conferir `main.dart` (Passo 9.1) |
| `No named parameter with the name 'initialValue'` | Flutter anterior à 3.35 | Atualizar o Flutter (`flutter upgrade`) ou trocar por `value:` |
| Erro de pacote na primeira linha de `MainActivity.kt` | Linha `package` substituída pela do exemplo | Restaurar o `package` correspondente ao caminho do arquivo |
| "Informação indisponível" em "Sobre", no aparelho | Nome do canal ou do método diferente entre Dart e Kotlin | Conferir `compras/dispositivo` e `obterInformacoes` nos dois lados |
| Ligação profunda abre o aplicativo, mas mostra "Página não encontrada" | Caminho da URL não corresponde às rotas | Usar `compras://app/item/<id>`; o host `app` não faz parte do caminho |
| Ligação profunda abre o navegador ou nada acontece | `intent-filter` fora da `<activity>` ou aplicativo não reinstalado | Conferir o Passo 8.2 e executar de novo |
| `CHECK constraint failed` | Quantidade fora de 1 a 99 gravada sem passar pela regra de domínio | Usar `ajustarQuantidade` em toda alteração de quantidade |
| `A dismissed Dismissible widget is still part of the tree` | Item não removido do estado de forma imediata | Manter a remoção otimista de `ItensNotifier.excluir` |
| Dados antigos após alterar o esquema | `onCreate` só executa em banco novo | Desinstalar o aplicativo durante o desenvolvimento, ou implementar `onUpgrade` |
| API real funciona em debug, mas não no APK | Permissão de internet declarada apenas no manifesto de debug | Ao trocar o servidor simulado por um real, incluir `<uses-permission android:name="android.permission.INTERNET" />` em `src/main/AndroidManifest.xml` |

## Verificação final

Antes de considerar o aplicativo concluído e gerar o APK de distribuição, conferir:

- [ ] `flutter analyze` sem problemas e `flutter test` com todos os testes aprovados;
- [ ] `identidade.dart` com nome do aplicativo, descrição, integrantes com nome completo e matrícula, turma, cor semente e categorias próprios, sem nenhum valor de exemplo remanescente;
- [ ] `applicationId` com identificador próprio, e não `br.com.equipeexemplo` nem `com.example`;
- [ ] nome curto do aplicativo no inicializador do Android (`android:label`);
- [ ] tela "Sobre" exibindo a autoria, os dados do aparelho e a data de criação do banco;
- [ ] dados preservados após encerrar e reabrir o aplicativo;
- [ ] faixa de aviso offline e sincronização automática ao retornar a rede;
- [ ] ligação profunda abrindo o item correto, com "voltar" conduzindo à lista;
- [ ] diálogo de descarte ao sair de um formulário alterado;
- [ ] grade com 1, 2 e 3 colunas conforme a largura, e textos íntegros com fonte ampliada;
- [ ] APK de release gerado, renomeado com identificador e versão, instalado em um aparelho diferente do usado no desenvolvimento e funcionando.

## Síntese da aula

| Camada ou recurso | Arquivos | Conceito (aula) |
|---|---|---|
| Domínio | `item.dart`, `regras_item.dart`, `item_repository.dart` | Entidade imutável, regras puras, contrato (12) |
| Dados locais | `banco_de_dados.dart`, `item_mapper.dart`, `item_repository_sqlite.dart` | Repositório, serialização, SQLite, concorrência otimista (13) |
| Dados remotos | `nova_tentativa.dart`, `servico_remoto_simulado.dart`, `sincronizador.dart` | Backoff com jitter, sincronização de pendências (13) |
| Integração nativa | `dispositivo_nativo.dart`, `MainActivity.kt` | Canal de plataforma (14) |
| Estado | `providers.dart` | `AsyncNotifier`, `Notifier`, `AsyncValue`, injeção por providers (12) |
| Navegação | `rotas.dart`, `AndroidManifest.xml` | Rotas aninhadas, ligação profunda, `PopScope` (14) |
| Interface | `tela_*.dart`, `cartao_item.dart`, `faixa_offline.dart` | Árvore de widgets, `LayoutBuilder`, `MediaQuery`, estados de interface (4, 10, 11) |
| Qualidade | `test/` | Testes de domínio, de dados com SQLite real e de interface |
| Distribuição | APK | Assinatura, versão, arquiteturas e formas de instalação |

## Leitura recomendada

- Documentação oficial: [Persist data with SQLite](https://docs.flutter.dev/cookbook/persistence/sqlite), [Build and release an Android app](https://docs.flutter.dev/deployment/android) e [Deep linking](https://docs.flutter.dev/ui/navigation/deep-linking).
- Documentação dos pacotes: [sqflite](https://pub.dev/packages/sqflite), [Riverpod](https://riverpod.dev/), [go_router](https://pub.dev/packages/go_router) e [connectivity_plus](https://pub.dev/packages/connectivity_plus).
- Documentação do Android: [App Inspection — Database Inspector](https://developer.android.com/studio/inspect/database) e [Configure the app module — applicationId](https://developer.android.com/build/configure-app-module).
