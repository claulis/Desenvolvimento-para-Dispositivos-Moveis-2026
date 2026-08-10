# API simulada

`db.json` com 50 pedidos e 50 produtos de exemplo, usado como fonte remota nas atividades das Aulas 11 e 15 (padrão repositório com fonte remota + local). Versionado no repositório para que todas as equipes testem contra os mesmos dados.

## Como rodar

```bash
npx json-server --watch db.json --port 3000
```

Endpoints disponíveis (REST automático do `json-server`):

- `GET http://localhost:3000/pedidos`
- `GET http://localhost:3000/pedidos/:id`
- `GET http://localhost:3000/produtos`
- `GET http://localhost:3000/produtos/:id`

No emulador Android, o host da máquina é acessado por `10.0.2.2` em vez de `localhost` — configure a *base URL* do cliente HTTP (`dio`/`axios`) como `http://10.0.2.2:3000`.

## O que o aluno deve alterar

Nada neste arquivo diretamente — ele é a fonte de dados fixa para testar cache, retry e sincronização. Se precisar de mais volume ou de um cenário específico (ex.: um pedido com status inconsistente para testar tratamento de erro), adicione registros novos, mas não remova os existentes, para manter os testes comparáveis entre equipes.
