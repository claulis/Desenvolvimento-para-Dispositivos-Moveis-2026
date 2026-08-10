# 11 — Repositório com fontes intercambiáveis e conectividade intermitente (Flutter)

Ponto de partida para a atividade da Aula 11: `PedidoRepository` com fonte remota (a API simulada de [`recursos/api-simulada/`](../../../recursos/api-simulada/)) e fonte local (cache), aplicando cache-then-network e nova tentativa com espera progressiva.

## Como rodar

```bash
# Em um terminal, suba a API simulada:
cd ../../../recursos/api-simulada && npx json-server --watch db.json --port 3000

# Em outro terminal:
cd inicio   # ou solucao
flutter pub get
flutter run
```

No emulador Android, a API fica acessível em `http://10.0.2.2:3000` (já configurado em `lib/config.dart`).

## O que alterar (`inicio/`)

`inicio/lib/pedido_repository.dart` contém um bug proposital, correspondente ao erro mais comum discutido na Aula 11 §1: captura `SocketException` em vez de `DioException`, o que faz o fallback para cache **nunca disparar** quando a rede cai. Corrija seguindo o padrão da Aula 11 §1, e implemente:

1. Captura correta de `DioException` (`connectionError`/`connectionTimeout`) para o fallback de cache.
2. Nova tentativa com espera progressiva **e jitter**, repetindo apenas erros transitórios (Aula 11 §5).
3. Uma faixa "Sem conexão — exibindo dados salvos" na interface quando o repositório cair no cache.

## Testar sob rede instável

```bash
adb shell settings put global airplane_mode_on 1
adb shell am broadcast -a android.intent.action.AIRPLANE_MODE
```

`solucao/` contém a implementação de referência já corrigida — consulte depois de tentar.
