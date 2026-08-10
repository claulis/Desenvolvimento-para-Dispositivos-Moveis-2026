# Aula 12 — Flutter: navegação declarativa e canais de plataforma

**Carga horária:** 4h
**Unidade:** III — Arquitetura de software em Flutter

## Objetivos da aula

- Implementar navegação declarativa, rotas e ligações profundas em Flutter.
- Relacionar a navegação Flutter à pilha de retorno do Android.
- Explicar o papel dos canais de plataforma na integração entre Dart e código específico do Android.

## 1. Navegação imperativa x declarativa

> **Definição — Navegação imperativa**: modelo de navegação em que o código instrui explicitamente o sistema a empilhar ou desempilhar uma tela em resposta a um evento (`Navigator.push`, `Navigator.pop`), sem que a pilha de navegação seja, em si, uma representação de estado observável e reconstruível.

> **Definição — Navegação declarativa**: modelo em que a pilha de navegação é derivada de um estado da aplicação (ex.: "usuário autenticado", "id do pedido selecionado"), de forma que mudar esse estado automaticamente reflete a pilha de rotas correta — a navegação é uma função do estado, não uma sequência de comandos imperativos.

O Flutter suporta os dois modelos. `Navigator.push`/`pop` é o modelo imperativo mais simples:

```dart
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => TelaDetalhePedido(id: pedido.id)),
);
```

O pacote `go_router` (recomendado pela equipe do Flutter para projetos que precisam de deep links robustos) implementa o modelo declarativo, onde rotas são definidas centralmente e a navegação ocorre por mudança de URL/estado, não por empilhamento manual:

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

## 2. Relação com a pilha de retorno do Android

Retomando a Aula 2: independentemente do modelo escolhido, o Flutter precisa manter coerência com a pilha de retorno nativa do Android — o gesto/botão voltar do sistema deve desempilhar a rota Flutter do topo, exatamente como esperado pelo modelo mental do usuário Android (Aula 4). O widget `PopScope` (substituto do antigo `WillPopScope`) permite interceptar essa tentativa de voltar, por exemplo para exibir um diálogo de confirmação antes de descartar um formulário não salvo:

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

## 3. Ligações profundas (deep links)

> **Definição — Ligação profunda (deep link)**: URL ou notificação que, ao ser aberta, leva o usuário diretamente a uma tela específica dentro do aplicativo — não apenas à tela inicial — reconstruindo, se necessário, uma pilha de retorno sintética coerente até aquele ponto.

Um deep link mal implementado abre a tela de destino sem nenhuma pilha por trás dela: o usuário toca em voltar e o app fecha inesperadamente, ou fica preso sem rota de saída clara — violação direta da heurística "controle e liberdade do usuário" (Aula 5). O `go_router` resolve isso reconstruindo os ancestrais lógicos da rota de destino, mas isso exige declarar a rota como filha (rota aninhada) do ancestral desejado — não acontece "sozinho" apenas por declarar a rota isoladamente:

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

Além da rota Dart, um deep link só funciona de fato com a configuração de plataforma correspondente — no `AndroidManifest.xml`:

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

E testado com:

```bash
adb shell am start -W -a android.intent.action.VIEW -d "meuapp://pedido/42"
```

Sem essa configuração de manifesto, nenhuma rota Dart de deep link é alcançável a partir de fora do app — um requisito frequentemente esquecido ao validar a Avaliação 2.

## 4. Sessão e persistência de rota

Aplicativos que exigem autenticação precisam decidir, a cada abertura, para qual rota inicial navegar com base no estado de sessão (usuário autenticado ou não) — uma decisão que também se beneficia do modelo declarativo, expressando a rota inicial como função do estado de autenticação, e não como uma sequência fixa de telas de splash/login codificada imperativamente.

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

## 5. Canais de plataforma (platform channels)

> **Definição — Canal de plataforma (platform channel)**: mecanismo de comunicação assíncrona e tipada entre o código Dart do Flutter e o código nativo do Android (Kotlin/Java) ou iOS (Swift/Objective-C), usado quando uma funcionalidade não está disponível em Dart puro ou em um pacote existente, exigindo acesso direto a uma API nativa da plataforma.

Apesar de o Flutter cobrir a grande maioria das necessidades de interface e lógica sem sair de Dart, algumas integrações exigem código nativo — por exemplo, um SDK de pagamento fornecido apenas em Kotlin, ou uma funcionalidade de hardware muito específica sem pacote Flutter maduro. O canal de plataforma é a fronteira formal entre os dois mundos.

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

> **Observação de arquitetura**: o canal de plataforma é, por natureza, assíncrono — a chamada de Dart para nativo não é uma chamada de função direta, é uma mensagem serializada e enviada por um canal de mensagens. Isso tem custo de desempenho perceptível se usado em alta frequência (ex.: chamado a cada quadro de animação), e deve ser reservado para operações pontuais, não para lógica de tempo real.

> **Ferramentas complementares**: para chamadas pontuais como a acima, o pacote `pigeon` gera a interface `MethodChannel` de forma tipada a partir de uma especificação Dart, eliminando o risco de erro de digitação nos nomes de método e no formato dos argumentos — hoje recomendado no lugar de escrever `MethodChannel` manualmente em projetos novos. Para fluxos contínuos de dados (ex.: leitura de um sensor a cada intervalo), o mecanismo equivalente é o `EventChannel`, que expõe um `Stream` em vez de uma chamada única.

## 6. Exemplo real: por que apps de e-commerce usam deep links em notificações push

Quando um aplicativo de e-commerce envia uma notificação "Seu pedido saiu para entrega", tocar nela deve levar diretamente à tela de acompanhamento daquele pedido específico — não à tela inicial do app, obrigando o usuário a navegar manualmente até encontrar o pedido certo. Essa é a aplicação mais comum de deep link em produção: a notificação carrega um identificador de pedido, que o `go_router` traduz em uma rota `/pedido/:id`, reconstruindo a pilha de retorno de forma que o usuário, ao tocar em voltar, chegue a uma tela de lista de pedidos coerente — não a um estado vazio ou inesperado.

## Síntese da aula

| Conceito | Ferramenta Flutter |
|---|---|
| Navegação declarativa | `go_router`, rotas como função de estado |
| Coerência com pilha de retorno nativa | `PopScope` |
| Deep link | Rota nomeada com reconstrução de ancestrais |
| Integração nativa | Canal de plataforma (`MethodChannel`) |

## Leitura recomendada

- Documentação oficial: [go_router](https://pub.dev/packages/go_router) e [Platform channels](https://docs.flutter.dev/platform-integration/platform-channels).

## Atividade da aula

**Avaliação 2 — Módulo em Flutter (peso 20%)**: cada equipe entrega um módulo funcional em Flutter contendo: arquitetura em camadas (Aula 10), repositório com fonte remota e local (Aula 11), gerenciamento de estado justificado, navegação declarativa com ao menos uma rota acessível por deep link (testável com o comando `adb` acima), e comportamento correto sob conectividade intermitente. A entrega é seguida de arguição individual, na qual cada integrante deve justificar oralmente as decisões de arquitetura e de interface tomadas no módulo — não pontua no critério de arquitetura quem não sustentar a decisão adotada. Roteiro-padrão de perguntas de arguição (para isonomia entre equipes) em [`recursos/rubricas/roteiro-arguicao.md`](../recursos/rubricas/roteiro-arguicao.md).
