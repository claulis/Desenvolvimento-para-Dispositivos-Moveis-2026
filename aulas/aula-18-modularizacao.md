# Aula 18 — Modularização por funcionalidade e por camada

**Carga horária:** 4h
**Unidade:** V — Estilos arquiteturais, renderização e análise comparativa

## Objetivos da aula

- Distinguir modularização por funcionalidade e por camada.
- Avaliar o efeito de cada critério sobre acoplamento, substituição e evolução.
- Definir fronteiras de módulo e dependências permitidas entre eles.

## 1. Por que modularizar

> **Definição — Módulo**: unidade de organização de código com fronteira explícita, que agrupa um conjunto coeso de responsabilidades e expõe uma interface pública deliberada, escondendo detalhes internos de implementação do restante do sistema.

Um projeto que cresce sem fronteiras de módulo explícitas tende a se tornar um emaranhado onde qualquer arquivo pode importar qualquer outro — o que funciona em um projeto de disciplina de algumas semanas, mas se torna insustentável à medida que o número de telas e desenvolvedores cresce, porque não há mais como saber, sem ler todo o código, o efeito colateral de uma mudança localizada.

## 2. Modularização por camada (horizontal)

> **Definição — Modularização por camada**: critério de organização em que módulos são definidos pelo tipo técnico de responsabilidade (ex.: módulo `apresentacao`, módulo `dominio`, módulo `dados`), agrupando, dentro de cada módulo, código de **todas** as funcionalidades da aplicação que compartilham aquele papel técnico.

```
lib/
├── apresentacao/
│   ├── tela_catalogo.dart
│   ├── tela_pedido.dart
│   └── tela_perfil.dart
├── dominio/
│   ├── produto.dart
│   ├── pedido.dart
│   └── usuario.dart
└── dados/
    ├── produto_repository.dart
    ├── pedido_repository.dart
    └── usuario_repository.dart
```

Essa é a organização que resulta "naturalmente" de aplicar a arquitetura em camadas (Aula 17) sem critério adicional: todo o domínio junto, toda a apresentação junta. Funciona bem em projetos pequenos, mas apresenta um problema de escala: para entender ou modificar completamente a funcionalidade "pedido", é preciso navegar por três pastas diferentes e distantes na árvore de diretórios — e não há nada impedindo, estruturalmente, que o módulo de domínio de "produto" acabe referenciando algo de "pedido" de forma não intencional.

## 3. Modularização por funcionalidade (vertical)

> **Definição — Modularização por funcionalidade (feature-based)**: critério de organização em que módulos são definidos por área de funcionalidade do produto (ex.: módulo `catalogo`, módulo `pedidos`, módulo `perfil`), contendo, dentro de cada módulo, todas as camadas técnicas (apresentação, domínio, dados) necessárias para aquela funcionalidade.

```
lib/
├── catalogo/
│   ├── apresentacao/tela_catalogo.dart
│   ├── dominio/produto.dart
│   └── dados/produto_repository.dart
├── pedidos/
│   ├── apresentacao/tela_pedido.dart
│   ├── dominio/pedido.dart
│   └── dados/pedido_repository.dart
└── compartilhado/
    ├── dominio/usuario.dart
    └── ui/componentes_comuns.dart
```

Nessa organização, tudo o que diz respeito a "pedidos" está fisicamente próximo, e a fronteira entre `catalogo` e `pedidos` é explícita — qualquer dependência de um módulo sobre o outro exige uma importação visível entre pastas de funcionalidade, tornando acoplamentos indevidos mais fáceis de notar em revisão de código.

> **O risco do módulo `compartilhado`**: na prática, `compartilhado/` é o modo de falha mais comum dessa estrutura — vira, com o tempo, o depósito de tudo que "parece" reaproveitável, recriando exatamente o acoplamento que a modularização por funcionalidade buscava eliminar (todo módulo termina dependendo de `compartilhado`, e `compartilhado` termina sabendo de tudo). Uma regra prática que ajuda a conter esse crescimento é a **regra dos três**: só promover algo para `compartilhado` quando pelo menos três módulos de funcionalidade genuinamente precisarem dele — duas ocorrências ainda cabem como duplicação aceitável, mais barata do que uma abstração prematura.

## 4. Efeito sobre acoplamento, substituição e evolução

| Critério | Acoplamento | Substituição | Evolução típica |
|---|---|---|---|
| Por camada | Domínio de funcionalidades distintas fica fisicamente próximo, facilitando acoplamento acidental | Difícil remover uma funcionalidade inteira sem tocar as três pastas técnicas | Adequado quando a equipe é pequena e organizada por especialidade técnica |
| Por funcionalidade | Fronteiras entre funcionalidades mais visíveis, acoplamento indevido mais fácil de identificar | Uma funcionalidade inteira pode, em princípio, ser removida ou extraída apagando uma única pasta | Adequado quando a equipe cresce e se organiza por squads/funcionalidade, ou quando módulos podem evoluir e ser versionados/removidos independentemente |

Nenhum dos dois é "correto" isoladamente — a escolha depende de como a equipe está organizada e de como o produto tende a evoluir. Times organizados por especialidade técnica (um time de "apresentação", um de "dados") tendem a se beneficiar mais da estrutura por camada, ao custo de maior risco de acoplamento acidental entre domínios distintos; times organizados por funcionalidade (comum em produtos mobile de médio a grande porte) tendem a se beneficiar da estrutura vertical.

## 5. Fronteiras e substituibilidade

> **Definição — Fronteira de módulo (module boundary)**: limite deliberado entre módulos, através do qual apenas uma interface pública explicitamente exposta pode ser acessada — detalhes internos de implementação permanecem inacessíveis a outros módulos, reforçando o encapsulamento no nível de organização de projeto, não apenas no nível de classe.

Em Dart (Flutter), a fronteira real é reforçada com um arquivo de biblioteca (`src/` interno ao módulo, mais um único arquivo barril público na raiz, seguindo a convenção do `pub`) ou, em projetos maiores, com um **pacote Dart separado** por módulo dentro de um monorepositório — o `melos` é apenas o orquestrador que facilita trabalhar com múltiplos pacotes ao mesmo tempo (versionamento, publicação, scripts), não o mecanismo que impõe a fronteira em si. Em TypeScript (React Native), fronteiras podem ser reforçadas por regras de lint como `eslint-plugin-boundaries`, que **falham o build** quando há importação direta entre pastas de funcionalidades distintas, exigindo passar por um índice público (`index.ts`) de cada módulo — a diferença entre uma convenção combinada e uma regra verificada automaticamente.

```ts
// pedidos/index.ts — interface pública do módulo, único ponto de importação externa
export { TelaPedidos } from './apresentacao/TelaPedidos';
export type { Pedido } from './dominio/Pedido';
```

O ponto mais importante deste exemplo, fácil de passar despercebido por estar apenas em comentário: `PedidoRepository` e os demais detalhes internos do módulo **não são exportados** por este índice — permanecem privados a `pedidos/`, mesmo sendo tecnicamente importáveis por um caminho de arquivo direto (`pedidos/dados/PedidoRepository`) enquanto uma regra de lint como a citada acima não estiver configurada para bloquear esse acesso. A interface pública deliberada é o que faz a fronteira existir de fato, não apenas a organização de pastas.

## 6. Dependências permitidas entre módulos de funcionalidade

Uma regra frequentemente adotada em projetos modularizados por funcionalidade: módulos de funcionalidade (`catalogo`, `pedidos`) podem depender de um módulo `compartilhado` (com entidades e componentes verdadeiramente comuns), mas **não devem depender diretamente uns dos outros** — se `pedidos` precisa de informação de `catalogo`, essa comunicação deve passar por uma interface explícita (ex.: um caso de uso em `compartilhado`, ou um evento observável), evitando que uma cadeia de dependências diretas entre módulos de funcionalidade torne qualquer um deles impossível de extrair ou substituir isoladamente.

## 7. Exemplo real: por que grandes aplicativos migram para modularização por funcionalidade

Aplicativos de grande porte mantidos por múltiplas equipes (bancos digitais, marketplaces) frequentemente relatam a migração de uma estrutura inicial por camada para uma estrutura por funcionalidade, à medida que o número de desenvolvedores cresce e squads passam a ser organizados por área de produto (ex.: um squad de "pagamentos", outro de "catálogo"). Nessa migração, o critério técnico de organização (camada) deixa de refletir o critério real de propriedade e evolução do código (funcionalidade/squad), e a estrutura por camada passa a gerar atrito: dois squads diferentes frequentemente precisam editar arquivos na mesma pasta técnica (`apresentacao/`), aumentando conflitos de integração sem relação real de dependência entre as funcionalidades.

Esse fenômeno tem nome: a **Lei de Conway** observa que a estrutura de um sistema tende a espelhar a estrutura de comunicação da organização que o constrói — uma equipe organizada por squads de produto tende, mais cedo ou mais tarde, a produzir (ou exigir) um código organizado por funcionalidade, e resistir a uma estrutura por camada que não corresponde a como o trabalho é de fato dividido entre pessoas.

## Síntese da aula

| Critério | Melhor quando |
|---|---|
| Por camada | Equipe pequena, organizada por especialidade técnica |
| Por funcionalidade | Equipe organizada por área de produto, necessidade de extrair/substituir funcionalidades isoladamente |
| Fronteira reforçada | Interface pública explícita por módulo, detalhes internos inacessíveis externamente |

## Leitura recomendada

- RICHARDS; FORD. *Fundamentals of Software Architecture* — capítulo sobre modularidade e particionamento de componentes.

## Atividade da aula

**Prática: definição das fronteiras de módulo das duas implementações e verificação das dependências entre elas**: cada equipe reorganiza as implementações Flutter e React Native já entregues segundo modularização por funcionalidade, definindo explicitamente a interface pública de cada módulo (o que é exportado) e verificando, por inspeção do código, se alguma dependência direta indevida entre módulos de funcionalidade distintos existe — corrigindo as encontradas.
