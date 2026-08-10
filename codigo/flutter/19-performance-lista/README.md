# 19 — Desempenho de renderização em lista longa (Flutter)

Ponto de partida para a atividade da Aula 19: uma lista de 250 produtos ([`recursos/datasets/produtos.json`](../../../recursos/datasets/produtos.json), já incluída em `assets/produtos.json`), com favoritar/desfavoritar item a item.

## Como rodar

```bash
flutter pub get
flutter run --profile   # sempre em profile para medir — nunca em debug
```

## `inicio/` — versão a medir e corrigir

`inicio/lib/main.dart` implementa a versão **ineficiente** discutida na Aula 19 §2: o estado de `favoritos` vive no widget pai da lista inteira (`Set<String>` em `_TelaCatalogoState`), fazendo com que favoritar **um** item reconstrua a lista inteira.

1. Abra o **Flutter DevTools > Performance** (ou o *Widget Rebuild Profiler*) e favorite um item no meio da lista — observe quantos widgets são reconstruídos.
2. Registre o resultado em `MEDICOES.md`.
3. Refatore aplicando escuta seletiva (Aula 19 §2 — `ref.watch(favoritoProvider(id))`, não mover o dado para dentro do `State` do item, que quebraria ao rolar a lista).
4. Meça novamente e registre o "depois" em `MEDICOES.md`.

## `solucao/`

Implementação de referência já com escuta seletiva por item via Riverpod (`favoritoProvider` como *family provider*) e `ListView.builder` com `ValueKey` estável.
