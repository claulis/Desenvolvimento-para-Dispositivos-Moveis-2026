# Checklist de paridade — Módulo Flutter × React Native

Use antes de entregar a Entrega 2 (Aula 16), para que a comparação da Aula 20 seja sobre arquitetura, não sobre diferenças acidentais de implementação entre as duas versões do mesmo módulo.

## Rotas e navegação

- [ ] Mesmas rotas nomeadas nas duas implementações (mesmo conjunto de telas)
- [ ] Mesma rota acessível por deep link, testada com o mesmo comando `adb` nas duas
- [ ] Mesmo comportamento de confirmação ao tentar sair de um formulário não salvo (`PopScope` / `beforeRemove`)

## Estado e arquitetura

- [ ] Mesma separação de camadas (apresentação/domínio/dados) nas duas implementações
- [ ] Gerenciador de estado justificado individualmente em cada uma (não precisa ser "o mesmo nome", mas o critério de escolha deve ser comparável)
- [ ] Nenhuma lógica de negócio dentro de widget/componente em nenhuma das duas

## Dados e conectividade

- [ ] Mesmo comportamento de cache (cache-then-network) nas duas
- [ ] Mesma estratégia de nova tentativa com espera progressiva
- [ ] Mesmo comportamento observável ao perder conexão (testado com o mesmo procedimento de emulador)

## Estados de interface

- [ ] Estado de carregamento presente e visualmente equivalente nas duas
- [ ] Estado de erro presente, com mensagem específica (não genérica) nas duas
- [ ] Estado de vazio presente nas duas
- [ ] Estado "offline com dados em cache" presente e visualmente equivalente nas duas

## Responsividade e acessibilidade

- [ ] As três classes de tamanho de janela tratadas nas duas
- [ ] Rótulos acessíveis presentes em todos os elementos interativos, nas duas
- [ ] Contraste mínimo verificado nas duas
