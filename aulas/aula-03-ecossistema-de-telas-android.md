# Aula 3 — Ecossistema de telas Android

**Carga horária:** 4h
**Unidade:** I — O smartphone e a plataforma Android como condicionantes de projeto

## Objetivos da aula

- Diferenciar densidade, tamanho e proporção de tela e calcular medidas independentes de densidade.
- Projetar considerando área segura, recortes de câmera e barras do sistema.
- Reconhecer o efeito do tema claro/escuro e de aparelhos dobráveis sobre a interface.

> **Nota sobre os exemplos de Android nativo desta unidade**: o Android possui dois sistemas de construção de interface — o sistema tradicional de **Views/XML** (`TextView`, `ImageButton`, layouts XML) e o **Jetpack Compose**, declarativo, que é o padrão recomendado pelo Google desde 2023. Este componente não ensina Kotlin nem entrega nada em Android nativo — os trechos de código nativo são apenas ilustrativos, para ancorar conceitos que valem para a plataforma como um todo. Por isso, e porque Compose é declarativo como Flutter e React Native (reduzindo o salto conceitual até a Unidade III), **os exemplos ilustrativos de Android nativo desta unidade usam Jetpack Compose**. A teoria (dp/sp, área segura, tokens de cor, classes de tamanho) se aplica igualmente a Views/XML, que você encontrará em código legado.

## 1. Por que "tamanho de tela em pixels" é a métrica errada

Dois aparelhos podem ter a mesma resolução em pixels (por exemplo, 1080×2400) e, ainda assim, exibir uma interface com tamanho físico completamente diferente, porque um tem uma tela fisicamente maior e a outra menor — a diferença está na **densidade de pixels**: quantos pixels cabem por polegada física de tela.

> **Definição — Densidade de tela (DPI)**: número de pixels físicos por polegada linear da tela. O Android agrupa densidades em baldes nominais (`ldpi`, `mdpi`, `hdpi`, `xhdpi`, `xxhdpi`, `xxxhdpi`), cuja escala segue aproximadamente **0,75 / 1 / 1,5 / 2 / 3 / 4** em relação ao `mdpi` de referência (160 dpi) — a razão entre baldes vizinhos não é constante (mdpi→hdpi é 1,5×; hdpi→xhdpi é 1,33×; xhdpi→xxhdpi é 1,5×), por isso a escala correta é a lista de multiplicadores acima, não "cada um 1,5× o anterior".

Se um projeto usar pixels físicos diretamente para definir o tamanho de um botão, esse botão parecerá minúsculo em uma tela de alta densidade e enorme em uma de baixa densidade. A solução do Android — e replicada conceitualmente por Flutter e React Native — é uma unidade **independente de densidade**.

## 2. dp e sp: as unidades corretas

> **Definição — dp (density-independent pixel)**: unidade de medida que se ajusta automaticamente à densidade da tela, de forma que 1 dp ocupe aproximadamente o mesmo tamanho físico em qualquer aparelho. A conversão é `pixels = dp × (densidade_do_aparelho / 160)`.

> **Definição — sp (scale-independent pixel)**: como o dp, mas que também respeita a preferência de escala de fonte definida pelo usuário nas configurações de acessibilidade do sistema. Deve ser usado exclusivamente para tamanho de texto.

Erro comum de quem começa no Android: usar `dp` para tamanho de fonte. Isso ignora a preferência de acessibilidade do usuário que aumentou a fonte do sistema — um requisito que será aprofundado na Aula 8.

```kotlin
// Jetpack Compose
Text(
    text = "Confirmar pedido",
    fontSize = 16.sp,                       // sp: respeita a escala de fonte do usuário
    modifier = Modifier.padding(12.dp)       // dp: dimensão, não depende da escala de fonte
)
```

Em Jetpack Compose, Flutter e React Native, o próprio framework aplica essa conversão internamente — mas o conceito matemático subjacente é o mesmo e deve ser compreendido para depurar problemas de layout entre aparelhos. Para fixar a escala: um botão de 48dp ocupa 48 px físicos num aparelho `mdpi`, 96 px num `xhdpi` e 192 px num `xxxhdpi` — o mesmo tamanho físico sob o dedo do usuário nos três casos, apesar do número de pixels crescer.

## 3. Tamanho, proporção e classes de janela

Além da densidade, telas variam em **tamanho físico** (de ~5 polegadas a tablets de 13 polegadas) e em **proporção** (de 16:9 a proporções mais alongadas, comuns em aparelhos recentes). Um layout fixo, pensado para uma única proporção, quebra visualmente em qualquer aparelho fora dessa faixa. Esse tema — resolvido por meio de classes de tamanho de janela — é tratado em profundidade na Aula 7; aqui cabe reconhecer que **a variação existe e é normal**, não uma exceção a ser tratada como caso extremo.

## 4. Área segura, recortes de câmera e barras do sistema

Aparelhos modernos frequentemente têm:

- **Recorte de câmera (notch/punch-hole)**: uma área da tela ocupada fisicamente pela câmera frontal, que a interface não deve cobrir com conteúdo interativo crítico.
- **Cantos arredondados**: conteúdo posicionado exatamente no canto pode ser visualmente cortado.
- **Barra de status** (topo) e **barra de navegação/área de gesto** (base): áreas do sistema que sobrepõem ou compartilham espaço com o conteúdo do app, especialmente relevante desde que os apps passaram a poder desenhar conteúdo "por trás" dessas barras (*edge-to-edge*, obrigatório a partir do Android 15 **para apps com `targetSdk 35` ou superior** — um app com `targetSdk` menor continua no comportamento anterior mesmo rodando num aparelho Android 15; a obrigatoriedade é do app declarado, não do aparelho).

> **Definição — Área segura (safe area)**: região retangular da tela garantida livre de recortes de hardware e de sobreposição pelas barras do sistema, dentro da qual o conteúdo essencial da interface deve ser posicionado.

```kotlin
// Jetpack Compose: respeitando os insets do sistema com edge-to-edge
Scaffold(
    modifier = Modifier.windowInsetsPadding(WindowInsets.systemBars)
) { padding ->
    ConteudoDaTela(modifier = Modifier.padding(padding))
}
```

Em Flutter, o widget `SafeArea` resolve o mesmo problema de forma declarativa; em React Native, o hook `useSafeAreaInsets` da biblioteca `react-native-safe-area-context` cumpre papel equivalente. Os três resolvem o mesmo condicionante de plataforma, cada um à sua maneira — o que será comparado nas Aulas 9 e 13.

## 5. Tema claro e escuro

Desde o Android 10, o sistema oferece um tema escuro em nível de sistema operacional, que o usuário pode ativar manualmente, agendar por horário, ou vincular à economia de bateria. Um aplicativo que **não** oferece suporte a tema escuro:

- Ignora uma preferência explícita do usuário, o que é uma falha de usabilidade, não apenas estética.
- Pode causar desconforto visual real em ambientes de pouca luz (contraste excessivo do tema claro).
- Consome mais bateria em telas AMOLED (comuns na maioria dos aparelhos Android), já que pixels escuros consomem menos energia nesse tipo de tela.

> **Implicação de projeto**: cores não devem ser codificadas de forma fixa nos componentes (*hardcoded*) — devem referenciar um sistema de tokens de cor (ex.: "cor de superfície", "cor de texto primário") que se resolve de forma diferente conforme o tema ativo. Esse princípio é a base do sistema de cor do Material Design, estudado na Aula 6.

## 6. Aparelhos dobráveis

Aparelhos dobráveis (ex.: Samsung Galaxy Z Fold) introduzem um condicionante adicional: a mesma `Activity`/tela pode, em tempo de execução, passar de uma proporção de smartphone para uma proporção de tablet, ou ser exibida ao redor de uma dobradiça física que corta parte do conteúdo (*hinge*). A API `WindowManager` (Jetpack) expõe essas informações via `FoldingFeature`, permitindo que a interface reaja — por exemplo, exibindo duas colunas de conteúdo separadas pela dobradiça, ao invés de uma coluna cortada ao meio por ela.

Esse não é ainda o segmento dominante do mercado brasileiro, mas representa o caso-limite que valida se um projeto responsivo foi de fato bem-feito: se a interface se adapta corretamente a uma mudança de proporção **em tempo real, sem recriar a tela**, ela provavelmente também se adaptará bem a orientação retrato/paisagem e a diferentes tamanhos fixos.

## 7. Exemplo real: o mesmo aplicativo, quatro telas diferentes

Considere uma tela de detalhe de produto de um aplicativo de e-commerce. Em quatro perfis de aparelho, a mesma árvore de informação (imagem, nome, preço, descrição, botão comprar) deve se comportar assim:

| Perfil | Comportamento esperado |
|---|---|
| Smartphone de entrada, tela pequena, densidade média | Coluna única, imagem reduzida, botão fixo na base acima da barra de navegação |
| Smartphone topo de linha, tela grande, densidade alta, com recorte de câmera | Coluna única, mas com mais espaço de respiro; conteúdo respeita a área segura ao redor do recorte |
| Tablet em paisagem | Duas colunas: imagem à esquerda, informações e botão à direita |
| Dobrável aberto, com dobradiça central | Duas colunas separadas exatamente pela dobradiça, evitando que texto ou botões fiquem partidos por ela |

A prática desta aula consiste exatamente em observar essa variação, ainda sem escrever a lógica de adaptação (que virá na Aula 7) — o objetivo aqui é **reconhecer visualmente as quebras**.

## Síntese da aula

| Conceito | Unidade/ferramenta |
|---|---|
| Densidade | dp para dimensões, sp para texto |
| Área segura | `SafeArea` (Flutter), insets (Android nativo), `useSafeAreaInsets` (RN) |
| Tema | Tokens de cor, nunca cor fixa |
| Dobrável | `FoldingFeature`/`WindowManager`, duas colunas ao redor da dobradiça |

## Leitura recomendada

- Documentação oficial: [Suporte a diferentes densidades de tela](https://developer.android.com/training/multiscreen/screendensities) e [Suporte a telas grandes e dobráveis](https://developer.android.com/guide/topics/large-screens).

## Atividade da aula

**Prática em emulador**: configurar quatro perfis de emulador no Android Studio (smartphone pequeno de densidade média, smartphone grande com recorte de câmera simulado, tablet 10", dobrável) e executar o mesmo projeto padrão nos quatro. Capturar uma imagem de cada e registrar, em uma tabela, todas as quebras visuais observadas (elementos cortados pela área segura, texto desproporcional, botões fora de alcance) — essa tabela será a base da Avaliação 1, na Aula 4.
