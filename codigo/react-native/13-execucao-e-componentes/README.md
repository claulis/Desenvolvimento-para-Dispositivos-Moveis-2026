# 13 — Execução e componentes (React Native/Expo)

Ponto de partida para a atividade da Aula 13: a mesma tela de detalhe de produto construída em Flutter na Aula 9, agora em React Native/Expo, com `tema.ts` centralizando tokens de cor e tipografia (Aula 13 §4).

## Como rodar

```bash
npx create-expo-app . --template blank-typescript   # se ainda não inicializado
npm install react-native-safe-area-context
npx expo start
```

## O que alterar

- `inicio/tema.ts`: tokens de cor e tipografia — não deixe cores soltas em `StyleSheet.create` fora daqui.
- `inicio/TelaProduto.tsx`: tela sem responsividade — adicionar `useWindowDimensions` para alternar entre `LayoutCompacto`/`LayoutMedio`/`LayoutExpandido` nos mesmos pontos de quebra (600/840) da versão Flutter.
- `solucao/`: referência com responsividade e tema já aplicados.
