# 15 — Repositório com fontes intercambiáveis e conectividade (React Native)

Ponto de partida para a atividade da Aula 15: `PedidoRepository` equivalente ao Flutter da Aula 11, com fonte remota (API simulada), fonte local (MMKV) e sincronização de pendências.

## Como rodar

```bash
# Em um terminal, suba a API simulada:
cd ../../../recursos/api-simulada && npx json-server --watch db.json --port 3000

# Em outro terminal:
cd inicio   # ou solucao
npm install
npx expo start
```

No emulador Android, a API fica acessível em `http://10.0.2.2:3000` (já configurado em `config.ts`).

## O que alterar (`inicio/`)

`inicio/pedidoRepository.ts` está incompleto de duas formas propositais, correspondentes aos bugs discutidos na Aula 15:

1. A interface `PedidoRepository` não declara `enviarAlteracao` (Aula 15 §1) — complete a interface e a implementação.
2. A classe `NetworkError` é referenciada mas não definida (Aula 15 §1) — defina-a em `erros.ts`.

Depois de corrigir a compilação, implemente a sincronização de pendências (Aula 15 §6) e teste sob rede instável com os mesmos comandos `adb` da Aula 11.

`solucao/` contém a implementação de referência já corrigida.
