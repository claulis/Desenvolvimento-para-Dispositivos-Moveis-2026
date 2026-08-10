# Código

Projetos executáveis que acompanham as atividades das Unidades III e IV. Este componente é de desenvolvimento — não bastam slides e trechos de código soltos; cada tópico abaixo tem um projeto que roda de fato.

## Estrutura

```
codigo/
├── flutter/
│   ├── 09-widgets-responsivos/
│   ├── 10-camadas-estado/
│   ├── 11-repositorio-offline/
│   ├── 12-navegacao-deeplink/
│   └── 19-performance-lista/
└── react-native/
    ├── 13-execucao-e-componentes/
    ├── 14-camadas-estado/
    ├── 15-repositorio-offline/
    ├── 16-navegacao-deeplink/
    └── 19-performance-lista/
```

Cada pasta de tópico contém:

- `README.md` — o que é, como rodar, o que alterar na atividade.
- `inicio/` — ponto de partida da atividade (o que a equipe recebe).
- `solucao/` — uma solução de referência (consultar depois de tentar, não antes).

## Pré-requisitos para rodar

- **Flutter**: SDK Flutter instalado (`flutter doctor` sem erros bloqueantes) — ver versão de referência no [README principal](../README.md).
- **React Native**: Node.js LTS + Expo (`npx create-expo-app` já disponível via `npx`).
- **API simulada**: os projetos de 11/15 e 19 esperam a API fake de [`recursos/api-simulada/`](../recursos/api-simulada/) rodando em `localhost:3000` (instruções no README daquela pasta).

## Convenção de branches/commits ao usar em sala

Recomenda-se que cada equipe faça um fork ou copie a pasta `inicio/` do tópico correspondente para o repositório do próprio módulo, em vez de editar diretamente dentro deste repositório de aulas.
