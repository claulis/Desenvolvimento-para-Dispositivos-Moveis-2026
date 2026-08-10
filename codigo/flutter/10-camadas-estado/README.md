# 10 — Camadas e gerenciamento de estado (Flutter)

Ponto de partida para a atividade da Aula 10: um trecho de código com chamada de rede, validação e construção de widget misturados em um único `StatefulWidget`, para identificar violações de camada e reorganizar.

## Como rodar

```bash
flutter pub get
flutter test   # roda os testes de domínio já preparados em solucao/test/
```

## O que alterar

- `inicio/lib/tela_pedidos_ruim.dart`: código com violações de camada propositais (mesmo padrão da Aula 10 §2) — identifique cada uma e reescreva separando apresentação, domínio e dados.
- Adote um dos três gerenciadores de estado apresentados na aula (Provider, Riverpod ou BLoC) e justifique a escolha no `README` da própria entrega.
- `solucao/`: referência com Riverpod (`@riverpod`, API atual — não a `StateNotifierProvider` legada) já separado em camadas, incluindo um teste de domínio puro (Aula 10 §6).
