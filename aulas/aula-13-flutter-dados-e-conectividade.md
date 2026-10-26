# Aula 13 — Flutter: camada de dados e conectividade intermitente

**Carga horária:** 4h
**Unidade:** III — Arquitetura de software em Flutter

## Objetivos da aula

- Implementar o padrão repositório com fontes de dados local e remota.
- Projetar comportamento de cache, sincronização e nova tentativa sob conectividade intermitente.
- Exibir estados de rede na interface de forma coerente com os princípios da Aula 4.

## Organização da aula

A aula percorre a camada de dados da arquitetura estudada na Aula 12. Parte-se da abstração que isola a origem dos dados (§1), passa-se aos mecanismos de acesso e armazenamento (§2 e §3) e, então, ao problema que distingue o desenvolvimento móvel: a rede não é confiável (§4). As estratégias de resiliência (§5) e sua expressão na interface (§6) respondem a esse problema. Cada tópico segue a sequência: problema, mecanismo e aplicação.

## 1. O padrão repositório

> **Definição — Padrão repositório (Repository Pattern)**: abstração que isola o domínio da aplicação dos detalhes de onde e como os dados são efetivamente obtidos ou persistidos (API remota, banco local, cache em memória), expondo à camada de domínio uma interface única e independente da fonte concreta.

### Problema

Se o domínio ou a interface acessam diretamente a API, cada tela passa a conhecer o endereço do servidor, o formato da resposta e o tratamento de falhas. Qualquer mudança nesses detalhes propaga-se por todo o código. Em aplicações móveis o problema é agravado, porque a fonte de dados **muda de fato em tempo de execução**: às vezes há rede, às vezes não; às vezes os dados devem vir do cache local por velocidade, às vezes precisam ser buscados novamente.

### Mecanismo

O repositório é o **único lugar** que decide de onde os dados vêm. O domínio (Aula 12) apenas pergunta "quais são os pedidos deste usuário" e recebe a resposta, sem saber se ela veio de uma API ou de um banco local. A separação é obtida em duas partes:

- uma **interface abstrata** (`PedidoRepository`), que define o contrato visível ao domínio;
- uma **implementação** (`PedidoRepositoryImpl`), que coordena as fontes concretas (remota e local).

Como o domínio depende apenas da interface, a implementação pode ser trocada (por exemplo, por uma versão falsa em testes) sem alterar nenhuma linha do domínio.

### Aplicação

```dart
abstract class PedidoRepository {
  Future<List<Pedido>> obterPedidos();
  Future<void> salvarPedido(Pedido pedido);
}

class PedidoRepositoryImpl implements PedidoRepository {
  final PedidoRemoteDataSource _remoto;
  final PedidoLocalDataSource _local;

  PedidoRepositoryImpl(this._remoto, this._local);

  @override
  Future<List<Pedido>> obterPedidos() async {
    try {
      final pedidos = await _remoto.buscarPedidos();
      await _local.salvarCache(pedidos); // atualiza cache local
      return pedidos;
    } on DioException catch (e) {
      // dio embrulha falhas de conexão em DioException — NUNCA em SocketException,
      // mesmo quando a causa raiz é a mesma ausência de rede. Capturar
      // SocketException aqui deixaria esse catch morto e o fallback de cache nunca dispararia.
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        return _local.obterCache(); // sem rede: usa o que já foi salvo
      }
      rethrow; // erro de servidor (4xx/5xx): não é um problema de conectividade, propaga
    }
  }
}
```

Leitura do fluxo: o repositório tenta primeiro a fonte remota. Em caso de sucesso, atualiza o cache local e devolve os dados recentes. Se a falha for de **conectividade**, devolve o último cache salvo. Se a falha for de outra natureza (resposta 4xx ou 5xx do servidor), propaga o erro com `rethrow`, pois a ausência de rede não explica o problema, e disfarçá-lo com dados antigos ocultaria uma falha real.

## 2. Cliente HTTP e serialização

### Cliente HTTP

O Flutter não inclui um cliente HTTP completo por padrão, além do pacote básico `http`. Pacotes como o `dio` são amplamente usados por oferecerem interceptadores (código que atua em toda requisição, como a inclusão de um token), cancelamento de requisição e tratamento de erro mais estruturado.

**Atenção**: a exceção lançada pelo `dio` em falha de rede é `DioException`, e não a `SocketException` nativa do Dart, usada pelo pacote `http`. Se o projeto utiliza `dio` (recomendado), todo `catch` de erro de conectividade deve capturar `DioException`, como no exemplo da §1. Capturar `SocketException` com `dio` é um erro silencioso, porque o `catch` simplesmente nunca dispara e o tratamento de erro parece existir sem funcionar.

### Serialização

> **Definição — Serialização**: processo de converter um objeto Dart em um formato de intercâmbio (tipicamente JSON) para transmissão em rede ou persistência, e o processo inverso (desserialização) para reconstruir o objeto a partir desse formato.

**Problema.** A rede e o armazenamento trafegam texto e bytes, não objetos Dart. É necessário um mapeamento explícito entre as duas representações.

**Mecanismo.** O JSON recebido é decodificado em um `Map<String, dynamic>`, e o construtor de fábrica `fromJson` converte esse mapa em um objeto tipado. O caminho inverso é realizado por `toJson`. As conversões explícitas (`as String`, `as num`) validam o tipo no momento da leitura, de modo que um dado em formato inesperado falha de imediato, e não em um ponto distante do código.

```dart
class Pedido {
  final String id;
  final double total;

  Pedido({required this.id, required this.total});

  factory Pedido.fromJson(Map<String, dynamic> json) => Pedido(
        id: json['id'] as String,
        total: (json['total'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {'id': id, 'total': total};
}
```

O valor `total` é lido como `num` e convertido com `toDouble()` porque o JSON não distingue inteiros de decimais: um total de `100` pode chegar como `int`, e a conversão direta para `double` falharia.

Em projetos de maior porte, a geração de código (`json_serializable`, `freezed`) elimina a escrita manual repetitiva de `fromJson` e `toJson`, reduzindo o erro humano na digitação das chaves. O conceito subjacente (mapear entre a representação de rede e o objeto de domínio) permanece o mesmo.

## 3. Persistência local

### Problema

Para operar sem rede, a aplicação precisa guardar dados no aparelho. Os dados, porém, variam em volume e estrutura: uma preferência de tema é um valor isolado, ao passo que um catálogo de produtos possui milhares de registros relacionados. Uma única ferramenta não é adequada a todos os casos.

### Mecanismo e critério de escolha

| Ferramenta | Modelo de armazenamento | Uso adequado |
|---|---|---|
| `shared_preferences` | Pares chave-valor simples | Preferência de tema, token de sessão (observando os cuidados de segurança) |
| `sqflite` / `drift` | Banco relacional (SQL) | Dados estruturados e relacionais (ex.: catálogo de produtos com relações) |
| `hive` / `isar` | Banco de objetos Dart | Armazenamento de objetos rápido, sem necessidade de SQL |

A escolha depende da complexidade e do volume dos dados. Armazenar uma lista extensa de pedidos com relações em `shared_preferences` seria arquiteturalmente inadequado, mesmo que "funcione" em um protótipo pequeno, porque esse pacote serializa tudo como texto simples: cada alteração regrava o conjunto inteiro, e não há consulta nem filtragem sem leitura completa. Um banco relacional, ao contrário, permite consultar e atualizar apenas os registros necessários.

## 4. Conectividade intermitente: o problema central de mobile

### Problema

Retomando o contexto de uso móvel (Aula 7), o usuário está em movimento, entrando e saindo de áreas de cobertura e alternando entre Wi-Fi e dados móveis. Um aplicativo que presume conexão estável e contínua (modelo mental típico de quem vem do desenvolvimento web ou desktop) falha de forma visível e frequente em uso real.

> **Definição — Conectividade intermitente**: condição normal de operação de um aplicativo móvel em que a disponibilidade e a qualidade da conexão de rede variam ao longo do tempo, exigindo que o aplicativo seja projetado para operar de forma aceitável mesmo sob rede instável, lenta ou ausente — não apenas para "tratar o erro" quando a rede falha.

### Mecanismo de raciocínio

A palavra decisiva na definição é **normal**. A falha de rede em dispositivos móveis não é exceção rara a ser tratada em um bloco `catch`; é uma condição previsível de operação. A consequência para o projeto é que o comportamento sem rede deve ser **planejado desde o início** como parte do fluxo principal, e não acrescentado depois como tratamento de erro. As estratégias da seção seguinte materializam essa premissa.

## 5. Estratégias de resiliência

### Cache

**Problema.** Aguardar a resposta da rede a cada abertura de tela deixa o usuário diante de um indicador de carregamento e, sem rede, de uma tela inutilizável.

**Mecanismo.** Mantém-se uma cópia local dos dados já obtidos, servida imediatamente enquanto uma atualização em segundo plano ocorre. Essa estratégia denomina-se *stale-while-revalidate* ("servir o dado possivelmente desatualizado enquanto se revalida"). A interface exibe conteúdo instantaneamente, mesmo sem rede disponível no momento, e o substitui pelo dado recente quando este chega.

### Sincronização

> **Definição — Sincronização**: processo de reconciliar mudanças feitas localmente (possivelmente offline) com o estado no servidor, quando a conectividade é restabelecida.

**Problema.** O usuário pode realizar ações (criar ou alterar um pedido) sem rede. Essas alterações precisam chegar ao servidor posteriormente, sem perda.

**Mecanismo.** As alterações são registradas localmente como **pendentes**. Quando a rede retorna, cada alteração pendente é enviada ao servidor e, somente após a confirmação, marcada como sincronizada. Marcar apenas após a confirmação garante que uma falha no meio do processo não faça a alteração ser considerada enviada sem ter sido.

```dart
class SincronizadorPedidos {
  Future<void> sincronizar() async {
    final pendentes = await _local.obterAlteracoesPendentes();
    for (final alteracao in pendentes) {
      try {
        await _remoto.enviar(alteracao);
        await _local.marcarComoSincronizado(alteracao);
      } on DioException catch (e) {
        if (e.type == DioExceptionType.connectionError) break; // ainda sem rede: tenta o restante depois
        rethrow; // erro do servidor não deve ser silenciosamente ignorado
      }
    }
  }
}
```

> **Simplificação assumida**: o laço acima interrompe a sincronização inteira ao primeiro erro de conectividade e não trata **conflito**, isto é, o que acontece se o mesmo pedido foi alterado no servidor e localmente, de forma divergente. Estratégias reais incluem *last-write-wins* (a alteração mais recente, por timestamp, prevalece), mesclagem de campos não conflitantes, ou uma fila com versionamento explícito que rejeita a alteração e sinaliza o conflito ao usuário. Reconhecer essa simplificação é importante: implementar *cache-then-network* **não** equivale, por si só, a ter resolvido a sincronização offline.

### Nova tentativa com espera progressiva (retry with backoff)

> **Definição — Espera exponencial progressiva (exponential backoff)**: estratégia de nova tentativa em que o intervalo entre tentativas sucessivas cresce exponencialmente (ex.: 1s, 2s, 4s, 8s...), evitando sobrecarregar um servidor já instável ou esgotar rapidamente a bateria com tentativas em sequência muito próxima.

**Problema.** Muitas falhas são transitórias: uma oscilação de rede ou uma sobrecarga momentânea do servidor. Repetir a requisição costuma resolver. Contudo, repetir de imediato e indefinidamente agrava o problema: sobrecarrega o servidor e consome bateria.

**Mecanismo.** Três decisões compõem uma estratégia adequada:

1. **Repetir apenas falhas transitórias** (rede, *timeout*, erros 5xx e 429). Um 401 ou 404 não melhora em nova tentativa.
2. **Aumentar o intervalo** a cada tentativa (espera exponencial), concedendo tempo para a recuperação.
3. **Adicionar variação aleatória (*jitter*)** ao intervalo. Sem ela, milhares de clientes que perderam a conexão simultaneamente (por exemplo, por queda de uma torre) tentariam novamente em sincronia exata, produzindo um pico de carga (*thundering herd*) que pode derrubar o servidor no momento em que a rede retorna.

```dart
Future<T> comNovaTentativa<T>(Future<T> Function() operacao, {int maxTentativas = 4}) async {
  var tentativa = 0;
  while (true) {
    try {
      return await operacao();
    } on DioException catch (e) {
      // Repetir apenas falhas transitórias: rede, timeout ou 5xx/429 do servidor.
      // Um 401/404 não vai "melhorar" numa nova tentativa — repeti-lo só
      // queima bateria e pode até disparar limitação de taxa (rate limit).
      final transitorio = e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          (e.response?.statusCode ?? 0) >= 500 ||
          e.response?.statusCode == 429;
      tentativa++;
      if (!transitorio || tentativa >= maxTentativas) rethrow;

      // Espera exponencial + jitter aleatório: sem o jitter, milhares de
      // clientes que perderam conexão ao mesmo tempo (ex.: queda de uma
      // torre) tentariam de novo em sincronia exata (2s, 4s, 8s...), um
      // pico de carga simultâneo (thundering herd) que pode derrubar o
      // servidor justamente no momento em que a rede volta.
      final espera = Duration(
        milliseconds: (1000 * (1 << tentativa)) + Random().nextInt(1000),
      );
      await Future.delayed(espera);
    }
  }
}
```

Leitura do código: a expressão `1 << tentativa` desloca bits e equivale a `2^tentativa`, produzindo a progressão 2s, 4s, 8s (após o incremento de `tentativa`). O limite `maxTentativas` impede a repetição infinita: esgotado o número de tentativas, o erro é propagado com `rethrow` para que a camada superior o trate.

### Detecção de estado de conectividade

O pacote `connectivity_plus` permite observar mudanças no estado de conectividade em tempo real. A interface pode reagir (por exemplo, exibindo uma faixa "Sem conexão — mostrando dados salvos") em vez de falhar silenciosamente ou permanecer em estado de carregamento indefinido.

> **Elo com a Aula 2**: sincronizar pendências exige execução mesmo quando o aplicativo está fechado ou em segundo plano, que é precisamente o caso de uso do `WorkManager`, apresentado na Aula 2 como resposta ao limite de execução em segundo plano do Android. O pacote Flutter `workmanager` expõe essa mesma API: agenda-se `SincronizadorPedidos.sincronizar()` como tarefa adiável e garantida, delegando ao sistema operacional a decisão de *quando* executar.

## 6. Estados de rede na interface

### Problema

Retomando a Aula 4 (estados de vazio, carregamento e erro), os três estados são insuficientes para representar a situação do usuário sem rede que ainda possui dados salvos. Classificá-la como "erro" bloquearia o usuário sem necessidade; classificá-la como "carregando" criaria uma espera sem fim.

### Mecanismo

Sob conectividade intermitente, esses estados tornam-se ainda mais críticos e ganham uma variação adicional: o **estado offline com dados em cache**. Não é "carregando" nem "erro", mas um terceiro estado legítimo, em que a interface exibe dados possivelmente desatualizados, **com indicação clara dessa condição**, em vez de bloquear o usuário. A indicação (por exemplo, "última atualização há 10 minutos") é indispensável: ela permite ao usuário julgar a confiabilidade do que vê.

## 7. Exemplo real: por que apps de transporte funcionam em túnel de metrô

Aplicativos de transporte urbano usados no Brasil (bilhete único digital, apps de mobilidade) frequentemente precisam permanecer minimamente funcionais em áreas sem conectividade, como túneis de metrô. A estratégia típica combina os mecanismos da aula:

- o saldo e os últimos dados de viagem ficam em **cache local**, exibidos com indicação de "última atualização há X minutos" (§5 e §6);
- qualquer ação que dependa de rede (comprar novo bilhete) é bloqueada **apenas no momento da ação**, e não na abertura do aplicativo;
- a **detecção de conectividade** informa o usuário sobre a condição atual.

Trata-se de uma aplicação direta do padrão repositório combinado com cache e detecção de estado de conectividade estudados nesta aula.

## Síntese da aula

| Mecanismo | Problema que resolve | Papel |
|---|---|---|
| Repositório | Domínio acoplado à fonte de dados | Isola domínio da fonte de dados concreta |
| Serialização | Divergência entre formato de rede e objeto Dart | Mapeia JSON para objetos tipados e vice-versa |
| Persistência local adequada | Dados que não cabem na ferramenta escolhida | Escolha conforme volume e estrutura |
| Cache local | Espera pela rede, tela inútil sem conexão | Exibição instantânea, tolerância a ausência de rede |
| Sincronização | Perda de alterações feitas offline | Reconcilia mudanças offline ao restabelecer conexão |
| Backoff progressivo com jitter | Sobrecarga por tentativas repetidas e sincronizadas | Evita sobrecarga em nova tentativa repetida |
| Estado offline na interface | Usuário bloqueado sem necessidade | Terceiro estado, distinto de carregando/erro |

## Leitura recomendada

- Documentação oficial: [connectivity_plus](https://pub.dev/packages/connectivity_plus) e [Introduction to Isolates / networking](https://docs.flutter.dev/data-and-backend/networking).
