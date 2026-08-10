# Aula 11 — Flutter: camada de dados e conectividade intermitente

**Carga horária:** 4h
**Unidade:** III — Arquitetura de software em Flutter

## Objetivos da aula

- Implementar o padrão repositório com fontes de dados local e remota.
- Projetar comportamento de cache, sincronização e nova tentativa sob conectividade intermitente.
- Exibir estados de rede na interface de forma coerente com os princípios da Aula 8.

## 1. O padrão repositório

> **Definição — Padrão repositório (Repository Pattern)**: abstração que isola o domínio da aplicação dos detalhes de onde e como os dados são efetivamente obtidos ou persistidos (API remota, banco local, cache em memória), expondo à camada de domínio uma interface única e independente da fonte concreta.

O valor do padrão repositório em mobile é ainda maior do que em backend, porque a fonte de dados **muda de fato em tempo de execução**: às vezes há rede, às vezes não; às vezes os dados devem vir do cache local por velocidade, às vezes precisam ser buscados novamente. O repositório é o único lugar que decide isso — o domínio (Aula 10) apenas pergunta "quais são os pedidos deste usuário" sem saber se a resposta veio de uma API ou de um banco local.

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
    } on SocketException {
      return _local.obterCache(); // sem rede: usa o que já foi salvo
    }
  }
}
```

## 2. Cliente HTTP e serialização

O Flutter não inclui um cliente HTTP completo por padrão fora do pacote básico `http`; pacotes como `dio` são amplamente usados por oferecerem interceptadores, cancelamento de requisição e tratamento de erro mais estruturado.

> **Definição — Serialização**: processo de converter um objeto Dart em um formato de intercâmbio (tipicamente JSON) para transmissão em rede ou persistência, e o processo inverso (desserialização) para reconstruir o objeto a partir desse formato.

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

Em projetos de maior porte, geração de código (`json_serializable`, `freezed`) elimina a escrita manual repetitiva de `fromJson`/`toJson`, reduzindo erro humano de digitação de chave — mas o conceito subjacente (mapear entre representação de rede e objeto de domínio) é o mesmo.

## 3. Persistência local

Opções comuns no Flutter, cada uma adequada a um tipo de dado:

| Ferramenta | Uso adequado |
|---|---|
| `shared_preferences` | Pares chave-valor simples (ex.: preferência de tema, token de sessão) |
| `sqflite` / `drift` | Dados estruturados e relacionais (ex.: catálogo de produtos com relações) |
| `hive` / `isar` | Armazenamento de objetos Dart rápido, sem necessidade de SQL |

A escolha depende da complexidade e do volume dos dados a persistir — armazenar uma lista extensa de pedidos com relações em `shared_preferences` (que serializa tudo como texto simples) seria uma escolha arquiteturalmente inadequada, mesmo que "funcione" em um protótipo pequeno.

## 4. Conectividade intermitente: o problema central de mobile

Retomando o contexto de uso móvel (Aula 4): o usuário está em movimento, entrando e saindo de áreas de cobertura, alternando entre Wi-Fi e dados móveis. Um aplicativo que presume conexão estável e contínua (modelo mental típico de quem vem do desenvolvimento web/desktop) falha de forma visível e frequente em uso real.

> **Definição — Conectividade intermitente**: condição normal de operação de um aplicativo móvel em que a disponibilidade e a qualidade da conexão de rede variam ao longo do tempo, exigindo que o aplicativo seja projetado para operar de forma aceitável mesmo sob rede instável, lenta ou ausente — não apenas para "tratar o erro" quando a rede falha.

## 5. Estratégias de resiliência

### Cache

Manter uma cópia local dos dados já obtidos, servida imediatamente enquanto uma atualização em segundo plano ocorre (estratégia *stale-while-revalidate*), permite que a interface exiba conteúdo instantaneamente mesmo sem rede disponível no momento.

### Sincronização

> **Definição — Sincronização**: processo de reconciliar mudanças feitas localmente (possivelmente offline) com o estado no servidor, quando a conectividade é restabelecida.

```dart
class SincronizadorPedidos {
  Future<void> sincronizar() async {
    final pendentes = await _local.obterAlteracoesPendentes();
    for (final alteracao in pendentes) {
      try {
        await _remoto.enviar(alteracao);
        await _local.marcarComoSincronizado(alteracao);
      } on SocketException {
        break; // ainda sem rede: tenta o restante depois
      }
    }
  }
}
```

### Nova tentativa com espera progressiva (retry with backoff)

> **Definição — Espera exponencial progressiva (exponential backoff)**: estratégia de nova tentativa em que o intervalo entre tentativas sucessivas cresce exponencialmente (ex.: 1s, 2s, 4s, 8s...), evitando sobrecarregar um servidor já instável ou esgotar rapidamente a bateria com tentativas em sequência muito próxima.

```dart
Future<T> comNovaTentativa<T>(Future<T> Function() operacao, {int maxTentativas = 4}) async {
  var tentativa = 0;
  while (true) {
    try {
      return await operacao();
    } catch (e) {
      tentativa++;
      if (tentativa >= maxTentativas) rethrow;
      await Future.delayed(Duration(seconds: 1 << tentativa)); // 2, 4, 8...
    }
  }
}
```

### Detecção de estado de conectividade

O pacote `connectivity_plus` permite observar mudanças no estado de conectividade em tempo real, possibilitando que a interface reaja (ex.: exibir uma faixa "Sem conexão — mostrando dados salvos") em vez de simplesmente falhar silenciosamente ou travar em estado de carregamento indefinido.

## 6. Estados de rede na interface

Retomando diretamente a Aula 8 (estados de vazio, carregamento e erro): sob conectividade intermitente, esses estados se tornam ainda mais críticos, e ganham uma variação adicional — o **estado offline com dados em cache**, que não é nem "carregando" nem "erro": é um terceiro estado legítimo, em que a interface exibe dados possivelmente desatualizados, com indicação clara dessa condição, em vez de bloquear o usuário.

## 7. Exemplo real: por que apps de transporte funcionam em túnel de metrô

Aplicativos de transporte urbano usados no Brasil (bilhete único digital, apps de mobilidade) frequentemente precisam continuar minimamente funcionais em áreas de conectividade ausente, como túneis de metrô. A estratégia típica: o saldo e os últimos dados de viagem ficam em cache local, exibidos com indicação de "última atualização há X minutos", e qualquer ação que dependa de rede (comprar novo bilhete) é bloqueada apenas no momento da ação, não na abertura do app — uma aplicação direta do padrão repositório combinado com cache e detecção de estado de conectividade estudados nesta aula.

## Síntese da aula

| Mecanismo | Papel |
|---|---|
| Repositório | Isola domínio da fonte de dados concreta |
| Cache local | Exibição instantânea, tolerância a ausência de rede |
| Sincronização | Reconcilia mudanças offline ao restabelecer conexão |
| Backoff progressivo | Evita sobrecarga em nova tentativa repetida |
| Estado offline na interface | Terceiro estado, distinto de carregando/erro |

## Leitura recomendada

- Documentação oficial: [connectivity_plus](https://pub.dev/packages/connectivity_plus) e [Introduction to Isolates / networking](https://docs.flutter.dev/data-and-backend/networking).

## Atividade da aula

**Prática: repositório com duas fontes intercambiáveis, testado com banda limitada e perda de conexão no emulador**: implementar um `PedidoRepository` com fonte remota (API simulada) e fonte local (cache), aplicando a estratégia de cache-then-network e nova tentativa com espera progressiva. Testar o comportamento usando o controle de rede do emulador Android (banda limitada e modo avião) e registrar o comportamento observado da interface em cada condição.
