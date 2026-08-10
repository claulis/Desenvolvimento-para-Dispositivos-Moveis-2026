# 16 — Navegação e módulos nativos (React Native)

Ponto de partida para a Entrega 2 (Aula 16): React Navigation com deep link, espelhando o módulo Flutter da Aula 12. Use o [`recursos/checklist-paridade.md`](../../../recursos/checklist-paridade.md) para verificar equivalência antes de entregar.

## Como rodar

```bash
npm install
npx expo start
```

## Testar o deep link

Requer `scheme` configurado em `app.json` (já incluído em `inicio/app.json`):

```bash
adb shell am start -W -a android.intent.action.VIEW -d "meuapp://pedido/42"
```

## O que alterar

- `inicio/navigation.tsx`: configuração de `linking` sem o mapeamento de deep link completo — completar seguindo a Aula 16 §3.
- `inicio/TelaFormulario.tsx`: listener de `beforeRemove` a implementar (Aula 16 §2) — use `useEffect` simples, não `useFocusEffect` (redundante aqui, ver nota da aula).
