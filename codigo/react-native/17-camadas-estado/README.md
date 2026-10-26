# 16 — Camadas e gerenciamento de estado (React Native)

Ponto de partida para a atividade da Aula 17: identificar violações de camada e reorganizar, com um hook customizado e um gerenciador de estado à escolha da equipe.

## Como rodar

```bash
npm install
npm test   # roda os testes de domínio já preparados em solucao/
```

## O que alterar

- `inicio/TelaPedidosRuim.tsx`: mesmo padrão de violação de camada da Aula 17 §1 — reorganizar em `usePedidos` (hook customizado) + domínio puro.
- Considere usar TanStack Query para o *server state* (Aula 17 §2.1) em vez de reimplementar loading/erro/cache manualmente.
- `solucao/`: referência com `useCarrinho()` (não `useContext(...)!`, ver Aula 17 §3) e um teste de domínio puro.
