# Aula 6 — Hierarquia visual e Material Design

**Carga horária:** 4h
**Unidade:** II — Interface, experiência e responsividade

## Objetivos da aula

- Aplicar malha de espaçamento, escala tipográfica e sistema de cor segundo o Material Design.
- Usar elevação e iconografia para comunicar hierarquia e estado de componentes.
- Redigir textos de interface (*UX writing*) claros e consistentes com o tom da marca.

## 1. O que é o Material Design e por que segui-lo

> **Definição — Material Design**: sistema de design criado pelo Google que define princípios visuais, comportamentais e de interação para interfaces Android (e multiplataforma), baseado em uma metáfora de superfícies físicas que respondem à luz e ao movimento, com especificações precisas de espaçamento, cor, tipografia e movimento.

Seguir o Material Design não é uma imposição estética arbitrária: é a forma mais direta de entregar ao usuário uma interface que já corresponde ao seu modelo mental de "como um app Android se comporta" (retomando a Aula 4) — componentes com o mesmo comportamento de toque, elevação e retorno visual que ele já viu em outros aplicativos do sistema.

## 2. Hierarquia visual: por que a tela guia o olho antes de o usuário ler

> **Definição — Hierarquia visual**: organização deliberada dos elementos de uma interface por meio de tamanho, cor, contraste, posição e espaçamento, de modo a guiar a atenção do usuário na ordem de importância pretendida, antes mesmo da leitura do conteúdo textual.

Uma tela sem hierarquia visual clara obriga o usuário a ler tudo para entender o que é importante — o oposto do que se espera de uma interface mobile, onde a atenção é escassa (Aula 4). Os instrumentos de hierarquia visual do Material Design são: malha de espaçamento, escala tipográfica, sistema de cor, elevação e iconografia.

## 3. Malha de espaçamento (spacing grid)

O Material Design recomenda uma malha base de **8dp**: todo espaçamento (margens, preenchimento interno, distância entre elementos) deve ser múltiplo de 8dp (com exceções pontuais de 4dp para ajustes finos). Isso não é estético por si só — é o que garante que elementos de proveniências diferentes (um botão do sistema, um card customizado) se alinhem visualmente sem que o desenvolvedor precise ajustar pixel a pixel. A escolha de 8 também não é arbitrária: por ser divisível por 2 e por 4, um valor em múltiplos de 8dp converte de forma exata para pixels físicos nos principais baldes de densidade estudados na Aula 3 (8dp = 8px em `mdpi`, 12px em `hdpi`, 16px em `xhdpi`...), evitando arredondamentos que produziriam bordas ligeiramente desalinhadas em telas de densidades diferentes.

```kotlin
// Jetpack Compose — espaçamentos múltiplos de 8dp
Column(
    modifier = Modifier.padding(16.dp)
) {
    Text(texto1, modifier = Modifier.padding(bottom = 8.dp))
    Text(texto2, modifier = Modifier.padding(bottom = 24.dp))
}
```

## 4. Escala tipográfica

O Material Design define uma escala de estilos de texto nomeados (não tamanhos soltos escolhidos livremente), cada um com um papel semântico definido: `displayLarge`, `headlineMedium`, `titleLarge`, `bodyLarge`, `bodyMedium`, `labelSmall`, entre outros. Usar a escala, em vez de tamanhos arbitrários (`14.5sp`, `17sp`...), garante consistência entre telas e facilita a manutenção — mudar o tamanho de todos os títulos da aplicação se torna uma alteração em um único lugar, não uma busca por todos os `17sp` espalhados pelo código.

| Papel semântico | Uso típico |
|---|---|
| `displayLarge` | Números ou palavras de destaque máximo (ex.: valor de um saldo) |
| `headlineSmall` | Título de tela |
| `titleMedium` | Título de card ou seção |
| `bodyLarge` | Texto de leitura principal |
| `labelSmall` | Rótulos de botão pequenos, legendas |

## 5. Sistema de cor

> **Definição — Token de cor (color token)**: nome semântico atribuído a uma cor (ex.: "primary", "onPrimary", "surface", "error") que se resolve para um valor RGB concreto diferente conforme o tema (claro/escuro) ativo, permitindo que os componentes referenciem o papel da cor, não o valor bruto.

O Material Design 3 (Material You) define papéis de cor como `primary` (cor de marca, usada em ações principais), `onPrimary` (cor de texto/ícone sobre uma superfície `primary`, garantindo contraste), `surface` (fundo de cards e superfícies elevadas), `error` (estados de erro), entre outros. Referenciar tokens, em vez de valores fixos, é o mecanismo que torna o suporte a tema claro/escuro (Aula 3) possível sem duplicar o código de cada tela.

**Atenção**: o Material 3 **não define um papel de cor `success` nativamente** — apenas `primary/secondary/tertiary/error` (cada um com seu `container` e sua variante `on*`). Para um estado semântico como "entregue com sucesso", a opção correta é definir um papel de cor **customizado** dentro do `ColorScheme` da aplicação (ou gerá-lo com o Material Theme Builder, `m3.material.io/theme-builder`) — nunca esperar encontrar um `colorSuccess` pronto no framework.

```kotlin
// Errado: cor fixa, ignora tema
Modifier.background(Color(0xFFFFFFFF))

// Correto: token de cor resolvido pelo tema ativo (Jetpack Compose)
Modifier.background(MaterialTheme.colorScheme.surface)
```

## 6. Elevação

> **Definição — Elevação (elevation)**: distância simulada de uma superfície em relação ao plano de fundo, comunicada visualmente por sombra e, no Material 3, também por uma leve variação de tom de cor da superfície — usada para indicar hierarquia entre componentes sobrepostos (ex.: um card "flutua" sobre o fundo; um diálogo modal "flutua" sobre tudo).

Elevação não é apenas estética: comunica ao usuário, sem necessidade de texto, **o que está em primeiro plano e pode ser interagido agora** — um diálogo com elevação alta sinaliza claramente que o conteúdo abaixo dele está temporariamente inativo.

## 7. Iconografia

Ícones devem ser reconhecíveis (seguir o conjunto de ícones padrão do Material quando possível, como carrinho de compras, lupa de busca, coração de favorito) e sempre acompanhados de `contentDescription` para leitores de tela — tema retomado com profundidade na Aula 8. Ícones criativos demais, sem correspondência com convenções já estabelecidas, aumentam a carga cognitiva (violação direta da heurística "reconhecimento em vez de memorização", Aula 5).

## 8. Escrita de interface (UX writing)

> **Definição — UX writing**: prática de redigir os textos que aparecem na interface (rótulos de botão, mensagens de erro, textos de estado vazio, confirmações) de forma clara, concisa e consistente com o tom da marca, priorizando a compreensão imediata do usuário sobre a elegância literária.

Princípios práticos de UX writing para interfaces móveis, onde o espaço é escasso e a atenção é fragmentada (Aula 4):

- **Clareza antes de criatividade**: um botão "Confirmar compra" é preferível a "Vamos lá!" quando a ação tem consequência financeira — ambiguidade em ações irreversíveis é um risco, não um traço de personalidade da marca.
- **Voz ativa e específica em mensagens de erro**: "Não foi possível conectar à internet. Verifique sua conexão e tente novamente" é acionável; "Ocorreu um erro" não é.
- **Consistência de termos**: se a tela de listagem chama algo de "Pedido", a tela de detalhe não deve chamar o mesmo conceito de "Compra" — inconsistência terminológica quebra o modelo mental que o usuário está construindo (Aula 4).
- **Textos de botão como verbo de ação**: "Salvar", "Enviar", "Confirmar" — não "OK" quando uma ação mais específica é possível.

## 9. Exemplo real: o mesmo componente, dois tratamentos de hierarquia

Considere uma tela de listagem de pedidos com status "Entregue", "A caminho" e "Cancelado". Um tratamento sem hierarquia visual mostra os três em texto preto do mesmo tamanho, obrigando o usuário a ler cada linha. Um tratamento com hierarquia visual adequada usa: cor (um token customizado `success`, definido no `ColorScheme` da aplicação — retomando a ressalva da §5 — para "Entregue"; `primary` para "A caminho"; `error`, nativo do M3, para "Cancelado"), peso tipográfico (`titleMedium` para o status, `bodyMedium` para os detalhes secundários) e um ícone reconhecível por status — permitindo que o usuário escaneie a lista inteira e identifique pedidos com problema (cancelados) sem ler palavra por palavra. Esse é o valor prático e mensurável da hierarquia visual bem aplicada.

> **Nota de atualização (2025)**: a revisão *Material 3 Expressive* trouxe maior ênfase a movimento, forma e tipografia dentro do mesmo sistema de design — os princípios desta aula (malha, escala, tokens, elevação) permanecem válidos; consulte [m3.material.io](https://m3.material.io/) para as adições mais recentes de forma e movimento antes de aplicar em um projeto novo.

## Síntese da aula

| Instrumento | Papel |
|---|---|
| Malha de 8dp | Consistência de espaçamento entre componentes |
| Escala tipográfica | Papéis semânticos de texto, não tamanhos soltos |
| Tokens de cor | Suporte a tema e comunicação de estado/hierarquia |
| Elevação | Comunica o que está em primeiro plano |
| UX writing | Clareza e consistência terminológica |

## Leitura recomendada

- Documentação oficial: [Material Design 3](https://m3.material.io/) — seções de "Foundations" (cor, tipografia, layout).
- PREECE; ROGERS; SHARP. *Design de Interação*, 3. ed. — capítulo sobre design visual de interfaces.

## Atividade da aula

**Exercício: redesenho de tela aplicando malha, escala tipográfica e sistema de cor**: a partir de uma tela existente sem hierarquia visual clara (fornecida pelo docente ou escolhida pela equipe), redesenhar aplicando malha de 8dp, no mínimo três níveis da escala tipográfica, tokens de cor para dois estados distintos (ex.: sucesso/erro) e revisão dos textos de interface segundo os princípios de UX writing apresentados. Gere o `ColorScheme` completo (claro e escuro) em minutos com o [Material Theme Builder](https://m3.material.io/theme-builder) — o resultado alimenta diretamente a implementação em Flutter na Aula 9. Registre o antes/depois com duas capturas de tela lado a lado: é a evidência mais direta de que a hierarquia visual foi aplicada.
