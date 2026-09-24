# Responsividade em HTML e CSS

## Introdução

Design responsivo é a abordagem de desenvolvimento em que um único documento HTML se adapta a diferentes dimensões de *viewport* (smartphones, tablets e desktops). A adaptação é realizada exclusivamente pela camada de apresentação (CSS), que reorganiza, redimensiona ou oculta elementos conforme o espaço disponível, sem alteração da estrutura semântica do documento.

Este documento descreve as técnicas fundamentais de responsividade e referencia, ao final, quatro implementações de uma mesma página. Todas compartilham o mesmo `index.html` e o mesmo `visual.css` (cores e tipografia); apenas o `index.css`, responsável pelo layout, difere entre elas.

---

## 1. Meta viewport

Na ausência de configuração explícita, navegadores móveis renderizam a página em uma *viewport* virtual de aproximadamente 980px e a reduzem para caber na tela física. A declaração a seguir, no elemento `<head>`, desativa esse comportamento:

```html
<meta name="viewport" content="width=device-width, initial-scale=1">
```

| Parâmetro | Efeito |
|---|---|
| `width=device-width` | Define a largura da *viewport* como a largura real do dispositivo, em pixels CSS. |
| `initial-scale=1` | Define o nível de zoom inicial como 1:1. |

Essa declaração é pré-requisito para o funcionamento correto de media queries e de unidades relativas em dispositivos móveis.

---

## 2. Unidades de medida

As unidades CSS dividem-se em **absolutas**, cujo valor independe do contexto, e **relativas**, cujo valor é calculado em função de outra referência. Layouts responsivos utilizam predominantemente unidades relativas.

| Unidade | Referência | Aplicação recomendada |
|---|---|---|
| `px` | Absoluta | Bordas, sombras e detalhes de dimensão fixa |
| `%` | Dimensão correspondente do elemento pai | Larguras de colunas e contêineres |
| `em` | `font-size` do próprio elemento | Espaçamentos proporcionais ao texto do componente |
| `rem` | `font-size` do elemento raiz (`<html>`) | Tipografia e espaçamentos globais |
| `vw` / `vh` | 1% da largura / altura da *viewport* | Seções de altura total e tipografia fluida |
| `fr` | Fração do espaço livre do contêiner (exclusiva do Grid) | Definição de trilhas de grid |

### Funções de cálculo

```css
.container { width: 90%; max-width: 1100px; margin: 0 auto; }
h1         { font-size: clamp(1.6rem, 4vw, 2.5rem); }
.coluna    { width: calc(50% - 16px); }
.caixa     { width: min(100%, 600px); }
img        { max-width: 100%; height: auto; }
```

| Função / propriedade | Comportamento |
|---|---|
| `max-width` | Limita a largura máxima sem impedir a redução em telas menores. Preferível a `width` com valor fixo. |
| `clamp(min, ideal, max)` | Retorna o valor ideal, restrito ao intervalo entre mínimo e máximo. |
| `calc()` | Permite operações aritméticas entre unidades distintas. |
| `min()` / `max()` | Retornam, respectivamente, o menor ou o maior entre os valores informados. |
| `max-width: 100%` em mídias | Impede que imagens e vídeos excedam a largura do contêiner. |

---

## 3. Box model

Todo elemento renderizado é representado por uma caixa composta por quatro camadas: conteúdo, *padding*, borda e margem.

```
┌───────────── margin ─────────────┐
│  ┌────────── border ──────────┐  │
│  │  ┌─────── padding ──────┐  │  │
│  │  │       conteúdo       │  │  │
│  │  └──────────────────────┘  │  │
│  └────────────────────────────┘  │
└──────────────────────────────────┘
```

A propriedade `box-sizing` determina a quais camadas as propriedades `width` e `height` se aplicam:

| Valor | Largura total do elemento |
|---|---|
| `content-box` (padrão) | `width` + `padding` + `border` |
| `border-box` | `width` (já inclui `padding` e `border`) |

Com o valor padrão, um elemento declarado com `width: 50%` e `padding: 20px` ocupa mais de 50% do contêiner, o que provoca quebra indevida de colunas. A regra a seguir, aplicada em todas as implementações de referência, torna as larguras percentuais previsíveis:

```css
*, *::before, *::after { box-sizing: border-box; }
```

---

## 4. Media queries

Media queries são regras condicionais (`@media`) que aplicam um bloco de declarações apenas quando as características do dispositivo satisfazem uma condição, geralmente a largura da *viewport*.

```css
.card { width: 100%; }

@media (min-width: 600px) {
  .card { width: 50%; }
}

@media (min-width: 900px) {
  .card { width: 33.333%; }
}
```

### Estratégias de implementação

| Estratégia | Estilo base | Operador | Característica |
|---|---|---|---|
| Mobile-first | Telas pequenas | `min-width` | Regras são acrescentadas progressivamente. Menor volume de sobrescritas. Abordagem recomendada. |
| Desktop-first | Telas grandes | `max-width` | Regras são desfeitas progressivamente. Maior volume de sobrescritas. |

### Breakpoints

*Breakpoints* são os limites de largura nos quais o layout é alterado. Devem ser definidos em função do ponto em que o conteúdo deixa de ser apresentado adequadamente, e não de modelos específicos de dispositivos. Valores usuais: 600px (tablet) e 900px a 1024px (desktop).

### Outras características consultáveis

```css
@media (orientation: landscape) { }
@media (prefers-color-scheme: dark) { }
@media (hover: none) { }
@media (prefers-reduced-motion: reduce) { }
```

---

## 5. Flexbox

O módulo Flexible Box Layout distribui itens ao longo de **um único eixo** (linha ou coluna) e gerencia o espaço disponível entre eles. Quando combinado com `flex-wrap`, permite que os itens quebrem de linha automaticamente, o que reduz ou elimina a necessidade de media queries.

### Propriedades do contêiner

```css
.contêiner {
  display: flex;
  flex-direction: row;
  flex-wrap: wrap;
  justify-content: space-between;
  align-items: center;
  gap: 16px;
}
```

| Propriedade | Função |
|---|---|
| `flex-direction` | Define o eixo principal (`row`, `column`). |
| `flex-wrap` | Permite a quebra de itens em múltiplas linhas. |
| `justify-content` | Alinha os itens no eixo principal. |
| `align-items` | Alinha os itens no eixo transversal. |
| `gap` | Define o espaçamento entre itens. |

### Propriedades dos itens

```css
.item { flex: 1 1 200px; }
```

A propriedade abreviada `flex` corresponde a `flex-grow`, `flex-shrink` e `flex-basis`:

| Componente | Função |
|---|---|
| `flex-grow` | Proporção de crescimento quando há espaço excedente. |
| `flex-shrink` | Proporção de redução quando há espaço insuficiente. |
| `flex-basis` | Dimensão inicial do item antes da distribuição do espaço. |

Quando a soma dos `flex-basis` excede a largura do contêiner, os itens excedentes passam para a linha seguinte, produzindo comportamento responsivo sem *breakpoints*. Complementarmente, `align-self` altera o alinhamento de um item isolado, e `margin-top: auto` desloca um elemento para a extremidade final do contêiner.

---

## 6. Grid Layout

O módulo CSS Grid Layout organiza elementos em **dois eixos simultâneos** (linhas e colunas) e é indicado para a estrutura macro da página.

### Definição de trilhas

```css
.contêiner {
  display: grid;
  grid-template-columns: 3fr 1fr;
  gap: 16px;
}
```

### Trilhas automáticas

```css
.cards {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
}
```

A expressão cria tantas colunas quantas couberem no contêiner, cada uma com largura mínima de 200px, distribuindo o espaço remanescente igualmente. O número de colunas varia conforme a *viewport*, sem uso de media queries.

### Áreas nomeadas

A propriedade `grid-template-areas` descreve o layout de forma declarativa. A adaptação a diferentes telas consiste apenas em redefinir o mapa de áreas:

```css
.pagina {
  display: grid;
  grid-template-areas:
    "topo"
    "hero"
    "principal"
    "avisos"
    "rodape";
}
.topo { grid-area: topo; }

@media (min-width: 768px) {
  .pagina {
    grid-template-columns: 3fr 1fr;
    grid-template-areas:
      "topo      topo"
      "hero      hero"
      "principal avisos"
      "rodape    rodape";
  }
}
```

### Comparativo entre Flexbox e Grid

| Critério | Flexbox | Grid |
|---|---|---|
| Dimensões | Unidimensional | Bidimensional |
| Orientação do projeto | Orientado ao conteúdo | Orientado ao layout |
| Aplicação típica | Menus, barras de ferramentas, alinhamento interno de componentes | Estrutura da página, galerias, conjuntos de cards alinhados |

As duas técnicas são complementares e frequentemente combinadas: Grid na estrutura da página e Flexbox no interior dos componentes.

---

## 7. Implementações de referência

As quatro implementações abaixo renderizam a mesma página com técnicas distintas de layout. O comportamento pode ser verificado redimensionando a janela do navegador ou pelo modo de emulação de dispositivos das ferramentas de desenvolvedor.

| Versão | Diretório | Técnica | Características |
|---|---|---|---|
| 1 | [`semresponsividade/`](./semresponsividade/) | Unidades absolutas (`px`) e `float` | Largura fixa de 960px. Ausência de meta viewport. Rolagem horizontal em telas menores que a largura definida. |
| 2 | [`flexbox/`](./flexbox/) | Flexbox | Nenhuma media query. Adaptação obtida por `flex-wrap` e `flex: grow shrink basis`. |
| 3 | [`grid/`](./grid/) | Grid Layout | Abordagem mobile-first com `grid-template-areas`. Uma media query para redefinição das áreas. Cards com `repeat(auto-fit, minmax())`. |
| 4 | [`mediaqueries/`](./mediaqueries/) | Media queries, `%` e `float` | Técnica anterior ao Flexbox. Dois *breakpoints* (600px e 900px). Espaçamentos controlados por `calc()` e margem negativa. |

### Folhas de estilo de layout

- [Versão 1 — `semresponsividade/index.css`](./semresponsividade/index.css)
- [Versão 2 — `flexbox/index.css`](./flexbox/index.css)
- [Versão 3 — `grid/index.css`](./grid/index.css)
- [Versão 4 — `mediaqueries/index.css`](./mediaqueries/index.css)

### Folha de estilo visual compartilhada

- [`visual.css`](./flexbox/visual.css) — cores, tipografia e componentes visuais, idêntica nas quatro versões.

---

## Referências

- MDN Web Docs. *Responsive design*. https://developer.mozilla.org/pt-BR/docs/Learn/CSS/CSS_layout/Responsive_Design
- MDN Web Docs. *Flexbox*. https://developer.mozilla.org/pt-BR/docs/Learn/CSS/CSS_layout/Flexbox
- MDN Web Docs. *Grids*. https://developer.mozilla.org/pt-BR/docs/Learn/CSS/CSS_layout/Grids
- W3C. *Media Queries Level 4*. https://www.w3.org/TR/mediaqueries-4/
