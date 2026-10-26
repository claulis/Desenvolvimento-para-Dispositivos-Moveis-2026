# Aula 10 — Hierarquia visual e Material Design

**Carga horária:** 4h
**Unidade:** II — Interface, experiência e responsividade

## Objetivos da aula

- Aplicar malha de espaçamento, escala tipográfica e sistema de cor segundo o Material Design.
- Usar elevação e iconografia para comunicar hierarquia e estado de componentes.
- Redigir textos de interface (*UX writing*) claros e consistentes com o tom da marca.

## Organização da aula

O conteúdo desta aula articula-se em torno de um problema central: como permitir que o usuário compreenda uma tela em frações de segundo. Cada seção apresenta um instrumento de projeto e segue a mesma sequência: **problema** que o instrumento resolve, **mecanismo** pelo qual opera e **aplicação** em código. A compreensão do problema permite deduzir a regra correspondente, dispensando a memorização.

## 1. O Material Design e a justificativa de sua adoção

> **Definição — Material Design**: sistema de design criado pelo Google que define princípios visuais, comportamentais e de interação para interfaces Android (e multiplataforma), baseado em uma metáfora de superfícies físicas que respondem à luz e ao movimento, com especificações precisas de espaçamento, cor, tipografia e movimento.

### Problema

Caso cada aplicativo definisse de forma independente a aparência e o comportamento de botões, menus, listas e indicadores de erro, o usuário teria de reaprender as convenções básicas de interação a cada aplicativo instalado. Esse esforço constitui carga cognitiva desnecessária e eleva a probabilidade de abandono do aplicativo.

### Mecanismo

O Material Design consiste em um conjunto de regras compartilhadas. Quando diferentes aplicativos as adotam, o conhecimento adquirido em um deles é transferido aos demais. O princípio é análogo ao da sinalização de trânsito: uma placa de "pare" é compreendida em qualquer localidade porque sua forma e sua cor são padronizadas, e não porque houve instrução prévia.

O termo "material" decorre da metáfora central do sistema: a interface é composta por superfícies análogas a folhas de papel, dotadas de espessura, sobrepostas umas às outras, que projetam sombra e se deslocam com inércia. Essa metáfora fundamenta diversas regras apresentadas adiante, em especial a de elevação (§6).

### Relevância para o desenvolvimento

A adoção do Material Design não constitui imposição estética arbitrária. Trata-se da forma mais direta de entregar uma interface compatível com o **modelo mental** do usuário sobre o comportamento esperado de um aplicativo Android (retomando a Aula 7), pois os componentes apresentam o mesmo comportamento de toque, elevação e retorno visual já observado em outros aplicativos do sistema. Adicionalmente, o Jetpack Compose disponibiliza esses componentes já implementados, o que dispensa sua construção manual.

## 2. Hierarquia visual: a orientação do olhar anterior à leitura

> **Definição — Hierarquia visual**: organização deliberada dos elementos de uma interface por meio de tamanho, cor, contraste, posição e espaçamento, de modo a guiar a atenção do usuário na ordem de importância pretendida, antes mesmo da leitura do conteúdo textual.

### Problema

A percepção visual humana não percorre a tela de forma linear, como ocorre na leitura de um livro. Ela opera por **varredura**: em frações de segundo, o olhar se dirige aos elementos que se destacam (maiores, coloridos, contrastantes ou isolados por espaço vazio) e apenas depois se decide pela leitura. Quando todos os elementos possuem o mesmo tamanho, a mesma cor e a mesma distância em relação aos vizinhos, nenhum se destaca, e o usuário precisa ler todo o conteúdo para identificar o que é relevante.

Em dispositivos móveis, a situação é agravada: a tela é reduzida e o uso ocorre frequentemente em contextos de atenção parcial, como deslocamento e operação com uma única mão (Aula 7).

### Mecanismo

A hierarquia visual funciona como uma **disputa por atenção cujo resultado é determinado pelo projetista**. A intensidade com que cada elemento atrai o olhar é controlada por cinco variáveis:

| Variável | Condição | Efeito |
|---|---|---|
| Tamanho | Maior | O elemento é lido antes |
| Cor | Mais saturada ou contrastante com o fundo | O elemento se destaca |
| Contraste | Alto em relação ao fundo | Maior legibilidade e proeminência |
| Posição | Topo ou centro | O elemento é percebido primeiro |
| Espaçamento | Cercado por espaço vazio | O elemento é isolado e adquire importância |

Se todos os elementos recebem ênfase máxima, a ênfase perde o poder de distinção. O princípio da hierarquia consiste, portanto, em reservar o destaque ao que é essencial (a ação principal, o dado crítico) e manter os demais elementos discretos.

Os instrumentos que o Material Design oferece para controlar essas variáveis são: malha de espaçamento (§3), escala tipográfica (§4), sistema de cor (§5), elevação (§6) e iconografia (§7).

## 3. Malha de espaçamento (spacing grid)

### Problema

Na ausência de uma regra, os valores de margem são escolhidos por estimativa visual (10, 13, 15, 17 etc.). O resultado é uma interface em que os elementos não se alinham de fato, e a percepção de baixa qualidade ocorre mesmo quando o usuário não consegue explicar sua origem. Além disso, quando componentes de origens distintas (como um botão do sistema e um *card* customizado) utilizam espaçamentos diferentes, é necessário realizar ajustes manuais, pixel a pixel.

### Mecanismo

O Material Design adota uma malha base de **8dp**: todo espaçamento (margens, preenchimento interno, distância entre elementos) deve ser múltiplo de 8dp, isto é, 8, 16, 24, 32 etc. Ajustes finos podem utilizar 4dp.

A limitação do conjunto de valores elimina a necessidade de decisão caso a caso: não se escolhe entre 17 e 18, mas entre 16 e 24. Quando todos os componentes seguem a mesma malha, o alinhamento decorre da própria construção.

**Justificativa do valor 8.** Por ser divisível por 2 e por 4, o valor de 8dp converte-se de forma exata em pixels físicos nos baldes de densidade estudados na Aula 6:

| Densidade | Fator de escala | 8dp equivale a |
|---|---|---|
| `mdpi` | 1x | 8 px |
| `hdpi` | 1,5x | 12 px |
| `xhdpi` | 2x | 16 px |

Todos os resultados são números inteiros. Valores que não são múltiplos adequados, como 7dp em `hdpi`, resultam em 10,5 px, o que obriga o sistema a arredondar e produz bordas ligeiramente desalinhadas entre telas de densidades diferentes.

### Aplicação

```kotlin
// Jetpack Compose — espaçamentos múltiplos de 8dp
Column(
    modifier = Modifier.padding(16.dp)          // margem externa: 2 × 8
) {
    Text(texto1, modifier = Modifier.padding(bottom = 8.dp))   // itens relacionados: proximidade (1 × 8)
    Text(texto2, modifier = Modifier.padding(bottom = 24.dp))  // separação entre grupos (3 × 8)
}
```

Os valores possuem significado: espaçamentos pequenos agrupam elementos que pertencem ao mesmo conjunto, ao passo que espaçamentos maiores separam grupos distintos. O espaço vazio é, portanto, um instrumento de hierarquia, e não desperdício de área de tela.

## 4. Escala tipográfica

### Problema

A escolha de tamanhos de texto conforme a conveniência de cada tela (`14.5sp` em uma, `17sp` em outra) acarreta duas consequências indesejáveis. A primeira é a inconsistência visual: um título de seção assume tamanhos diferentes em telas diferentes. A segunda é a dificuldade de manutenção: alterar o tamanho dos títulos de todo o aplicativo exige localizar cada ocorrência de `17sp` no código, com o risco de modificar um valor que não correspondia a um título.

### Mecanismo

O Material Design define uma **escala de estilos nomeados**, cada um associado a um **papel semântico**. Em vez de especificar "22sp", o código declara "título de tela". Tamanho, peso e espaçamento entre letras são definidos uma única vez, no tema, e todos os textos que utilizam aquele papel herdam os valores correspondentes. O princípio é equivalente ao do uso de uma constante nomeada em substituição a um valor numérico repetido: a alteração em um único ponto propaga-se a todo o aplicativo.

| Papel semântico | Uso típico |
|---|---|
| `displayLarge` | Números ou palavras de destaque máximo (ex.: valor de um saldo) |
| `headlineSmall` | Título de tela |
| `titleMedium` | Título de card ou seção |
| `bodyLarge` | Texto de leitura principal |
| `labelSmall` | Rótulos de botão pequenos, legendas |

A escala também **produz hierarquia por si mesma**: como os papéis possuem tamanhos escalonados, o emprego de `titleMedium` para o título e de `bodyMedium` para o detalhe estabelece a distinção entre ambos sem configuração adicional.

### Aplicação

```kotlin
// Incorreto: tamanho avulso, não vinculado ao tema
Text("Pedido #123", fontSize = 17.sp)

// Correto: papel semântico, com tamanho definido pelo tema
Text("Pedido #123", style = MaterialTheme.typography.titleMedium)
```

## 5. Sistema de cor

> **Definição — Token de cor (color token)**: nome semântico atribuído a uma cor (ex.: "primary", "onPrimary", "surface", "error") que se resolve para um valor RGB concreto diferente conforme o tema (claro/escuro) ativo, permitindo que os componentes referenciem o papel da cor, não o valor bruto.

### Problema

Considere um *card* com fundo branco (`#FFFFFF`) e texto preto (`#000000`). A configuração é adequada no tema claro, mas, ao se ativar o **tema escuro**, o restante do aplicativo escurece, enquanto o *card* permanece branco, causando ofuscamento, e qualquer texto preto torna-se ilegível sobre fundos escuros. A correção exigiria duplicar a lógica de cada tela ("se tema escuro, utilizar determinada cor; caso contrário, outra").

### Mecanismo

Em lugar de referenciar **uma cor específica**, o código referencia **uma função**. O token de cor é um nome que descreve a finalidade da cor, cabendo ao tema determinar o valor concreto que ela assume:

| Token | Papel | Tema claro (exemplo) | Tema escuro (exemplo) |
|---|---|---|---|
| `surface` | Fundo de cards e superfícies | Branco | Cinza muito escuro |
| `primary` | Cor de marca, ações principais | Roxo médio | Roxo claro |
| `onPrimary` | Texto ou ícone **sobre** `primary` | Branco | Roxo muito escuro |
| `error` | Estados de erro | Vermelho | Vermelho mais claro |

Os valores da tabela são ilustrativos; os valores efetivos dependem do tema definido.

O prefixo **`on`** significa "o que é posicionado sobre". `onPrimary` é a cor projetada para manter contraste adequado sobre `primary` em ambos os temas, o que dispensa a escolha manual de "texto branco" e evita ilegibilidade quando a cor de fundo se altera.

Esse mecanismo viabiliza o suporte a tema claro e escuro (Aula 6) **sem duplicação do código de cada tela**: o código declara o uso de `surface`, e o tema substitui o valor automaticamente.

### Aplicação

```kotlin
// Incorreto: cor fixa, ignora o tema
Modifier.background(Color(0xFFFFFFFF))

// Correto: token de cor resolvido pelo tema ativo (Jetpack Compose)
Modifier.background(MaterialTheme.colorScheme.surface)
```

### Ressalva: inexistência de um papel `success`

O Material Design 3 (Material You) define apenas os papéis `primary`, `secondary`, `tertiary` e `error`, cada um acompanhado de seu `container` e de sua variante `on*`. **Não há papel `success` nativo.** Para representar um estado como "entregue com sucesso", deve-se definir um papel de cor **customizado** no `ColorScheme` da aplicação, ou gerá-lo por meio do Material Theme Builder (`m3.material.io/theme-builder`). Não se deve esperar a existência de um `colorSuccess` pronto no framework.

A customização é adequada desde que preserve o princípio dos tokens: o novo papel deve possuir valores para os temas claro e escuro, além de uma variante `on*` com contraste suficiente.

## 6. Elevação

> **Definição — Elevação (elevation)**: distância simulada de uma superfície em relação ao plano de fundo, comunicada visualmente por sombra e, no Material 3, também por uma leve variação de tom de cor da superfície — usada para indicar hierarquia entre componentes sobrepostos (ex.: um card "flutua" sobre o fundo; um diálogo modal "flutua" sobre tudo).

### Problema

Uma tela é composta por camadas: o fundo, os *cards* sobre ele, um botão flutuante, um diálogo sobreposto a todos os demais elementos. É necessário que o usuário identifique, sem recorrer à leitura, **quais elementos estão em primeiro plano e quais podem ser acionados naquele momento**.

### Mecanismo

A metáfora do papel é aplicada diretamente. No mundo físico, um objeto situado a maior altura projeta sombra maior e mais difusa. O Material reproduz esse comportamento: quanto maior a elevação, expressa em dp, maior e mais difusa a sombra. No Material 3, como a sombra isolada é pouco perceptível em tema escuro (sombra escura sobre fundo escuro), a superfície também recebe um **tom ligeiramente mais claro** à medida que sua elevação aumenta.

O usuário interpreta esse sinal de forma intuitiva: o elemento situado acima é o relevante no momento. Um diálogo de elevação alta indica que o conteúdo subjacente está temporariamente inativo, ainda que nenhum texto o declare.

A elevação comunica **relações entre camadas**, e não função decorativa. Quando todos os elementos apresentam sombra intensa, recai-se no problema descrito na §2: a ênfase generalizada elimina a distinção.

### Aplicação

```kotlin
// Card com elevação do Material 3
Card(elevation = CardDefaults.cardElevation(defaultElevation = 4.dp)) {
    Text("Pedido #123", style = MaterialTheme.typography.titleMedium)
}
```

## 7. Iconografia

### Problema

O ícone economiza espaço e esforço de leitura: uma lupa substitui a palavra "Pesquisar" em uma barra de espaço reduzido. Entretanto, esse benefício depende de que o símbolo seja **reconhecido** pelo usuário. Um ícone inventado exige que o significado seja descoberto por tentativa e erro.

### Mecanismo

Os ícones padrão do Material (carrinho de compras, lupa de busca, coração de favorito) operam como a sinalização de trânsito mencionada na §1: o usuário já os aprendeu em outros aplicativos, e seu emprego aproveita esse conhecimento prévio. Ícones excessivamente criativos, sem correspondência com convenções estabelecidas, aumentam a carga cognitiva e violam diretamente a heurística "reconhecimento em vez de memorização" (Aula 8).

### Requisito de acessibilidade

Todo ícone deve possuir `contentDescription`, texto lido em voz alta pelo leitor de tela (TalkBack) para usuários com deficiência visual. Na ausência desse atributo, o ícone é inacessível a esse público. O tema é retomado com maior profundidade na Aula 4.

```kotlin
Icon(
    imageVector = Icons.Default.Search,
    contentDescription = "Pesquisar"   // lido pelo leitor de tela
)
```

## 8. Escrita de interface (UX writing)

> **Definição — UX writing**: prática de redigir os textos que aparecem na interface (rótulos de botão, mensagens de erro, textos de estado vazio, confirmações) de forma clara, concisa e consistente com o tom da marca, priorizando a compreensão imediata do usuário sobre a elegância literária.

### Problema

O texto integra a hierarquia da interface: é o recurso a que o usuário recorre quando o elemento visual é insuficiente. Textos vagos, inconsistentes ou excessivamente criativos geram hesitação precisamente nos momentos de maior consequência, como pagamento, exclusão e envio. Em dispositivos móveis, o espaço é escasso e a atenção, fragmentada (Aula 7), de modo que cada palavra deve cumprir uma função.

### Princípios práticos

- **Clareza antes de criatividade.** O rótulo "Confirmar compra" é preferível a "Vamos lá!" quando a ação possui consequência financeira, pois o usuário precisa saber exatamente o que ocorrerá ao tocar o botão. A ambiguidade em ações irreversíveis constitui risco, e não traço de personalidade da marca.
- **Mensagens de erro específicas e acionáveis.** "Não foi possível conectar à internet. Verifique sua conexão e tente novamente" informa o que ocorreu e qual providência tomar. "Ocorreu um erro" não oferece ao usuário nenhum caminho de resolução.
- **Consistência terminológica.** Se a tela de listagem denomina um conceito "Pedido", a tela de detalhe não deve denominá-lo "Compra". O usuário pode inferir que se trata de entidades distintas, e a inconsistência compromete o modelo mental em construção (Aula 7).
- **Botões com verbo de ação.** Preferem-se "Salvar", "Enviar" e "Confirmar" a "OK" sempre que for possível uma ação mais específica, pois o verbo descreve o resultado e dispensa a releitura da pergunta do diálogo para interpretar o significado do botão.

| Evitar | Preferir | Justificativa |
|---|---|---|
| "Ocorreu um erro" | "Não foi possível salvar. Tente novamente." | Informa a falha e a providência cabível |
| "OK" | "Excluir pedido" | O botão descreve a consequência da ação |
| "Compra" em uma tela e "Pedido" em outra | "Pedido" em todas | Mesmo conceito, mesmo termo |

## 9. Exemplo real: o mesmo componente sob dois tratamentos de hierarquia

Considere uma tela de listagem de pedidos com os status "Entregue", "A caminho" e "Cancelado".

**Sem hierarquia visual:** os três status são exibidos em texto preto, de mesmo tamanho. A identificação de um pedido com problema exige a leitura de cada linha.

**Com hierarquia visual adequada:** combinam-se os instrumentos apresentados na aula.

| Instrumento | Aplicação | Efeito |
|---|---|---|
| Cor (§5) | `success` customizado para "Entregue"; `primary` para "A caminho"; `error` (nativo do M3) para "Cancelado" | Estado identificável pela cor, sem leitura |
| Escala tipográfica (§4) | `titleMedium` no status; `bodyMedium` nos detalhes | O status se destaca dos detalhes |
| Iconografia (§7) | Ícone reconhecível por status | Segunda pista visual, também útil a usuários com dificuldade de distinguir cores |
| Malha (§3) | Espaçamentos de 8dp e 16dp entre linhas e internamente | Linhas bem delimitadas, favorecendo a varredura |

O resultado é que o usuário percorre a lista com o olhar e identifica os pedidos cancelados **sem ler palavra por palavra**. Esse é o valor prático e mensurável da hierarquia visual bem aplicada: redução do tempo e do esforço necessários para alcançar a informação.

Observa-se que o ícone não substitui a cor. A utilização de **mais de um canal** (cor, ícone e texto) garante que a informação seja transmitida inclusive a usuários com daltonismo.

> **Nota de atualização (2025)**: a revisão *Material 3 Expressive* trouxe maior ênfase a movimento, forma e tipografia dentro do mesmo sistema de design. Os princípios desta aula (malha, escala, tokens, elevação) permanecem válidos; recomenda-se consultar [m3.material.io](https://m3.material.io/) para as adições mais recentes de forma e movimento antes de aplicá-las em um projeto novo.

## Síntese da aula

| Instrumento | Problema que resolve | Papel |
|---|---|---|
| Malha de 8dp | Espaçamentos estimados que não se alinham | Consistência de espaçamento entre componentes |
| Escala tipográfica | Tamanhos avulsos e manutenção difícil | Papéis semânticos de texto, não tamanhos soltos |
| Tokens de cor | Cores fixas incompatíveis com o tema escuro | Suporte a tema e comunicação de estado e hierarquia |
| Elevação | Indefinição sobre o que está em primeiro plano | Comunica o que está em primeiro plano |
| Iconografia | Símbolos não reconhecidos pelo usuário | Reconhecimento rápido, com `contentDescription` |
| UX writing | Texto vago ou inconsistente | Clareza e consistência terminológica |

**Ideia central:** todos os instrumentos apresentados substituem decisões avulsas por papéis nomeados e regras compartilhadas, o que torna a interface previsível para o usuário e de manutenção econômica para a equipe de desenvolvimento.

## Leitura recomendada

- Documentação oficial: [Material Design 3](https://m3.material.io/) — seções de "Foundations" (cor, tipografia, layout).
- PREECE; ROGERS; SHARP. *Design de Interação*, 3. ed. — capítulo sobre design visual de interfaces.
