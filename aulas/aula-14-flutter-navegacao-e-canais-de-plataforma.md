# Aula 14 — Flutter: navegação declarativa e canais de plataforma

**Carga horária:** 4h
**Unidade:** III — Arquitetura de software em Flutter

## Objetivos da aula

- Implementar navegação declarativa, rotas e ligações profundas em Flutter.
- Relacionar a navegação Flutter à pilha de retorno do Android.
- Explicar o papel dos canais de plataforma na integração entre Dart e código específico do Android.

## Organização da aula

A aula trata de como o usuário se desloca entre telas (§1 a §4) e de como o código Dart se comunica com o sistema Android quando o Flutter não oferece a funcionalidade necessária (§5). O fio condutor é o **estado**: a navegação declarativa trata a pilha de telas como consequência do estado da aplicação, e o canal de plataforma define a fronteira formal entre dois ambientes de execução. Cada tópico segue a sequência: problema, mecanismo e aplicação.

## 1. Navegação imperativa x declarativa

### Problema

Uma aplicação real precisa abrir telas em resposta a toques, mas também a eventos externos: um link recebido, uma notificação, o término do login, a perda da sessão. Se a navegação for apenas uma sequência de comandos ("empilhe esta tela agora"), o código fica espalhado pelos pontos em que os eventos ocorrem, e a aplicação não consegue **reconstruir** a pilha correta a partir de uma situação arbitrária (por exemplo, abrir diretamente a tela de detalhe de um pedido).

### Mecanismo

> **Definição — Navegação imperativa**: modelo de navegação em que o código instrui explicitamente o sistema a empilhar ou desempilhar uma tela em resposta a um evento (`Navigator.push`, `Navigator.pop`), sem que a pilha de navegação seja, em si, uma representação de estado observável e reconstruível.

> **Definição — Navegação declarativa**: modelo em que a pilha de navegação é derivada de um estado da aplicação (ex.: "usuário autenticado", "id do pedido selecionado"), de forma que mudar esse estado automaticamente reflete a pilha de rotas correta — a navegação é uma função do estado, não uma sequência de comandos imperativos.

A relação é análoga à diferença entre a manipulação imperativa de views e o `build()` declarativo estudados na Aula 12: no modelo declarativo, descreve-se **qual deve ser o resultado** (a pilha correspondente ao estado atual), e o framework determina os passos necessários para alcançá-lo. A vantagem prática é que a mesma descrição serve a qualquer origem de navegação (toque, link, notificação), já que todas convergem para um endereço (rota).

O Flutter suporta os dois modelos.

### Aplicação: modelo imperativo

`Navigator.push` e `Navigator.pop` constituem o modelo imperativo mais simples:

```dart
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => TelaDetalhePedido(id: pedido.id)),
);
```

O código instrui diretamente: "empilhe a tela de detalhe". É adequado a fluxos simples, mas a pilha resultante não pode ser expressa por um endereço nem reconstruída a partir de um link externo.

### Aplicação: modelo declarativo

O pacote `go_router` (recomendado pela equipe do Flutter para projetos que precisam de ligações profundas robustas) implementa o modelo declarativo. As rotas são definidas centralmente, cada uma associada a um caminho (`path`), e a navegação ocorre por mudança de endereço, e não por empilhamento manual:

```dart
final router = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (context, state) => const TelaCatalogo()),
    GoRoute(
      path: '/pedido/:id',
      builder: (context, state) => TelaDetalhePedido(id: state.pathParameters['id']!),
    ),
  ],
);

// Navegar:
context.go('/pedido/42');
```

Leitura do código: o segmento `:id` é um parâmetro de caminho. Ao navegar para `/pedido/42`, o `go_router` localiza a rota correspondente, extrai `42` e o disponibiliza em `state.pathParameters['id']`. Como o endereço contém toda a informação necessária para construir a tela, o mesmo endereço pode ser usado por um toque interno ou por um link externo.

## 2. Relação com a pilha de retorno do Android

### Problema

Retomando a Aula 2, o Android mantém uma pilha de retorno, e o usuário espera que o gesto ou botão "voltar" do sistema desfaça a última navegação. Se o Flutter ignorasse essa expectativa, o aplicativo violaria o modelo mental do usuário Android (Aula 7). Há ainda situações em que o retorno imediato é indesejável, como descartar um formulário preenchido e não salvo.

### Mecanismo

Independentemente do modelo escolhido, o Flutter mantém coerência com a pilha nativa: o "voltar" do sistema desempilha a rota Flutter do topo. O widget `PopScope` (substituto do antigo `WillPopScope`) permite **interceptar** essa tentativa de retorno e decidir se ela prossegue. A propriedade `canPop` informa se a saída é permitida; quando é `false`, o retorno é bloqueado e o callback `onPopInvokedWithResult` é acionado, permitindo, por exemplo, exibir um diálogo de confirmação.

### Aplicação

```dart
PopScope(
  // podeSairSemConfirmar (não "canPop" isolado): nome escolhido para deixar
  // explícito o que a flag realmente decide — nomear bem é conteúdo, não
  // estética, num curso que ensina arquitetura.
  canPop: podeSairSemConfirmar,
  onPopInvokedWithResult: (didPop, result) async {
    if (didPop) return; // já saiu (canPop era true): nada a fazer
    final confirmar = await exibirDialogoDescartar(context);
    if (confirmar && context.mounted) {
      // Com canPop: false, chamar Navigator.pop() aqui seria bloqueado de
      // novo pelo próprio PopScope — o pitfall mais comum da migração
      // WillPopScope -> PopScope. É preciso liberar a saída primeiro,
      // atualizando o estado que alimenta `canPop`, e só então tentar sair.
      setState(() => podeSairSemConfirmar = true);
      if (context.mounted) Navigator.of(context).pop();
    }
  },
  child: TelaFormulario(),
)
```

Sequência de eventos: (1) o usuário aciona "voltar"; (2) como `canPop` é `false`, o retorno é bloqueado e o callback é chamado com `didPop` igual a `false`; (3) o diálogo é exibido; (4) se o usuário confirma, o estado é atualizado para liberar a saída; (5) somente então `Navigator.pop()` é chamado. O passo 4 é necessário porque, enquanto `canPop` for `false`, qualquer tentativa de sair, inclusive a programática, é bloqueada novamente pelo próprio `PopScope`. A verificação `context.mounted` evita o uso do contexto após a tela ter sido removida durante a espera do diálogo.

## 3. Ligações profundas (deep links)

> **Definição — Ligação profunda (deep link)**: URL ou notificação que, ao ser aberta, leva o usuário diretamente a uma tela específica dentro do aplicativo — não apenas à tela inicial — reconstruindo, se necessário, uma pilha de retorno sintética coerente até aquele ponto.

### Problema

Ao abrir um deep link, o aplicativo não percorreu as telas anteriores; ele "nasce" já na tela de destino. Se a pilha contiver apenas essa tela, o usuário que tocar em "voltar" fecha o aplicativo inesperadamente ou fica sem rota de saída clara. Trata-se de violação direta da heurística "controle e liberdade do usuário" (Aula 8).

### Mecanismo

O `go_router` resolve o problema reconstruindo os **ancestrais lógicos** da rota de destino. Esse comportamento, porém, exige declarar a rota como **filha** (rota aninhada) do ancestral desejado. Ele não ocorre automaticamente apenas por declarar a rota de forma isolada, pois o roteador só conhece a hierarquia que lhe é informada.

```dart
final router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const TelaCatalogo(),
      routes: [
        // Rota aninhada: ao abrir '/pedido/42' via deep link, o go_router
        // reconstrói TelaCatalogo como ancestral na pilha antes de exibir
        // TelaDetalhePedido — "voltar" leva ao catálogo, não fecha o app.
        GoRoute(
          path: 'pedido/:id',
          builder: (context, state) =>
              TelaDetalhePedido(id: state.pathParameters['id']!),
        ),
      ],
    ),
  ],
);
```

Observa-se que o caminho da rota filha é `pedido/:id`, sem barra inicial: ele é concatenado ao caminho do pai (`/`), resultando em `/pedido/:id`. A pilha construída para esse endereço é `[TelaCatalogo, TelaDetalhePedido]`.

### Configuração de plataforma

Uma rota Dart de deep link só é alcançável de fato com a configuração correspondente no sistema operacional. O motivo é que o Android decide qual aplicativo recebe determinada URL com base nos *intent filters* declarados no `AndroidManifest.xml`. Sem o filtro, o sistema desconhece que o aplicativo é capaz de tratar aquele endereço:

```xml
<activity android:name=".MainActivity" android:exported="true">
    <intent-filter>
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <data android:scheme="meuapp" android:host="pedido" />
    </intent-filter>
</activity>
```

Significado dos elementos: `VIEW` indica a intenção de exibir um conteúdo; `DEFAULT` permite que a atividade receba intents implícitas; `BROWSABLE` permite que links acionados de um navegador a abram; e `data` restringe o filtro ao esquema `meuapp` e ao `host` `pedido`.

O teste pode ser realizado pela linha de comando, simulando a abertura do link:

```bash
adb shell am start -W -a android.intent.action.VIEW -d "meuapp://pedido/42"
```

Sem a configuração de manifesto, nenhuma rota Dart de deep link é alcançável a partir de fora do aplicativo, requisito frequentemente esquecido na validação da Avaliação 2.

## 4. Sessão e persistência de rota

### Problema

Aplicativos que exigem autenticação precisam decidir, a cada abertura, para qual rota navegar com base no estado da sessão (usuário autenticado ou não). Codificar essa decisão como sequência fixa de telas de *splash* e login é frágil: cada nova origem de navegação (deep link, notificação) precisaria repetir a verificação.

### Mecanismo

O modelo declarativo permite expressar a rota inicial como **função do estado de autenticação**. O `go_router` oferece o callback `redirect`, executado a cada tentativa de navegação: se devolver um caminho, a navegação é desviada para ele; se devolver `null`, prossegue normalmente.

```dart
final router = GoRouter(
  redirect: (context, state) {
    final autenticado = AuthState.of(context).estaAutenticado;
    if (!autenticado && state.matchedLocation != '/login') return '/login';
    return null;
  },
  routes: [ /* ... */ ],
);
```

Leitura do código: se o usuário não está autenticado e o destino não é a própria tela de login, a navegação é redirecionada para `/login`. A condição `state.matchedLocation != '/login'` é indispensável, pois sem ela o redirecionamento ocorreria também a partir de `/login`, produzindo um laço infinito. Como a verificação reside em um único ponto, aplica-se a qualquer origem de navegação, inclusive a deep links.

## 5. Canais de plataforma (platform channels)

> **Definição — Canal de plataforma (platform channel)**: mecanismo de comunicação assíncrona e tipada entre o código Dart do Flutter e o código nativo do Android (Kotlin/Java) ou iOS (Swift/Objective-C), usado quando uma funcionalidade não está disponível em Dart puro ou em um pacote existente, exigindo acesso direto a uma API nativa da plataforma.

### Problema

O código Dart executa na máquina virtual do Flutter e não tem acesso direto às APIs do Android, que são escritas em Kotlin ou Java. Embora o Flutter cubra a grande maioria das necessidades de interface e lógica sem sair de Dart, algumas integrações exigem código nativo: por exemplo, um SDK de pagamento fornecido apenas em Kotlin, ou uma funcionalidade de hardware específica sem pacote Flutter maduro.

### Mecanismo

O canal de plataforma é a **fronteira formal** entre os dois ambientes. Ele funciona como um sistema de mensagens com um nome que identifica o canal: o lado Dart envia uma mensagem contendo o nome de um método (e, opcionalmente, argumentos); o lado nativo, que registrou um manipulador para o mesmo nome de canal, executa a operação e devolve o resultado ou um erro. A correspondência entre os dois lados depende de **coincidência exata** do nome do canal (`com.exemplo.app/bateria`) e do nome do método (`getBatteryLevel`); qualquer divergência impede que a mensagem seja tratada.

### Aplicação

```dart
// Lado Dart
class BateriaNativa {
  static const _canal = MethodChannel('com.exemplo.app/bateria');

  static Future<int> obterNivelBateria() async {
    final int nivel = await _canal.invokeMethod('getBatteryLevel');
    return nivel;
  }
}
```

```kotlin
// Lado Android (Kotlin), na MainActivity
class MainActivity : FlutterActivity() {
    private val CANAL = "com.exemplo.app/bateria"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CANAL)
            .setMethodCallHandler { call, result ->
                if (call.method == "getBatteryLevel") {
                    result.success(obterNivelBateriaReal())
                } else {
                    result.notImplemented()
                }
            }
    }
}
```

Leitura do fluxo: (1) o Dart chama `invokeMethod('getBatteryLevel')`, que retorna um `Future`; (2) a chamada é serializada e enviada pelo `binaryMessenger`; (3) no lado Kotlin, o manipulador recebe `call`, verifica o nome do método e responde com `result.success(...)`; (4) a resposta é serializada de volta e completa o `Future` em Dart. Métodos desconhecidos recebem `result.notImplemented()`, o que evita que o lado Dart aguarde indefinidamente.

> **Observação de arquitetura**: o canal de plataforma é, por natureza, assíncrono. A chamada de Dart para o código nativo não é uma chamada de função direta, mas uma mensagem serializada enviada por um canal de mensagens. Isso acarreta custo de desempenho perceptível se usado em alta frequência (por exemplo, a cada quadro de animação), de modo que o mecanismo deve ser reservado para operações pontuais, e não para lógica de tempo real.

> **Ferramentas complementares**: para chamadas pontuais como a acima, o pacote `pigeon` gera a interface do canal de forma tipada a partir de uma especificação Dart, eliminando o risco de erro de digitação nos nomes de método e no formato dos argumentos. Em projetos novos, é hoje recomendado em lugar da escrita manual de `MethodChannel`. Para fluxos contínuos de dados (por exemplo, a leitura de um sensor a cada intervalo), o mecanismo equivalente é o `EventChannel`, que expõe um `Stream` em vez de uma chamada única.

## 6. Exemplo real: por que apps de e-commerce usam deep links em notificações push

Quando um aplicativo de e-commerce envia a notificação "Seu pedido saiu para entrega", tocar nela deve levar diretamente à tela de acompanhamento daquele pedido específico, e não à tela inicial, o que obrigaria o usuário a navegar manualmente até encontrar o pedido correto.

Esta é a aplicação mais comum de deep link em produção, e o fluxo reúne os conceitos da aula:

1. A notificação carrega um identificador de pedido.
2. O `go_router` traduz o identificador em uma rota `/pedido/:id` (§1).
3. Por ser rota aninhada, a pilha de retorno é reconstruída (§3).
4. O usuário, ao tocar em voltar, chega a uma tela coerente (a lista de pedidos), e não a um estado vazio ou inesperado.
5. O `redirect` (§4) garante que, se a sessão tiver expirado, o usuário seja conduzido ao login antes de acessar o pedido.

## Síntese da aula

| Conceito | Problema que resolve | Ferramenta Flutter |
|---|---|---|
| Navegação declarativa | Pilha não reconstruível a partir de eventos externos | `go_router`, rotas como função de estado |
| Coerência com pilha de retorno nativa | Violação do modelo mental do usuário Android; perda de dados não salvos | `PopScope` |
| Deep link | Abertura em tela de destino sem pilha de retorno | Rota aninhada com reconstrução de ancestrais, mais intent filter no manifesto |
| Redirecionamento por sessão | Verificação de autenticação repetida em cada origem de navegação | `redirect` do `go_router` |
| Integração nativa | Código Dart sem acesso às APIs do Android | Canal de plataforma (`MethodChannel`) |

## Leitura recomendada

- Documentação oficial: [go_router](https://pub.dev/packages/go_router) e [Platform channels](https://docs.flutter.dev/platform-integration/platform-channels).
