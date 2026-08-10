# 19 — Desempenho de renderização em lista longa (React Native)

Ponto de partida para a atividade da Aula 19: uma lista de 250 produtos ([`recursos/datasets/produtos.json`](../../../recursos/datasets/produtos.json), já incluída como `produtos.json` em cada projeto), com favoritar/desfavoritar item a item.

## Como rodar

```bash
npm install
npx expo start
```

Meça sempre em build de produção/release, nunca em modo de desenvolvimento com Hot Reload ativo — o overhead de desenvolvimento distorce os números.

## `inicio/` — versão a medir e corrigir

`inicio/App.tsx` implementa a versão **ineficiente** discutida na Aula 19 §3: o estado de `favoritos` vive no componente pai, e `renderItem` é uma função inline recriada a cada render, anulando qualquer `React.memo` no item.

1. Abra o **React DevTools Profiler** e favorite um item no meio da lista — observe quantos componentes re-renderizam.
2. Registre o resultado em `MEDICOES.md`.
3. Refatore aplicando `React.memo` + `renderItem` estável (`useCallback`, não inline) + `keyExtractor` (não `key` — `FlatList` não usa a prop `key`, ver Aula 19 §5).
4. Meça novamente e registre o "depois" em `MEDICOES.md`.

## `solucao/`

Implementação de referência já com `React.memo`, `renderItem`/`alternarFavorito` estáveis via `useCallback`, `keyExtractor`, e as props de configuração de `FlatList` discutidas na Aula 19 §4 (`initialNumToRender`, `windowSize`, `removeClippedSubviews`).
