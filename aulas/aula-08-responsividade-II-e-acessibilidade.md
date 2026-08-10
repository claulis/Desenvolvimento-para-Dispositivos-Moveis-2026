# Aula 8 — Responsividade II e acessibilidade

**Carga horária:** 4h
**Unidade:** II — Interface, experiência e responsividade

## Objetivos da aula

- Projetar interfaces que respeitem a escala de fonte definida pelo usuário e o contraste mínimo exigido.
- Implementar suporte a leitor de tela e ordem de foco coerente.
- Projetar estados de vazio, carregamento e erro como parte integrante da interface, não como exceção.

## 1. Acessibilidade não é um recurso opcional

> **Definição — Acessibilidade digital**: propriedade de um sistema que permite seu uso efetivo por pessoas com as mais diversas capacidades sensoriais, motoras e cognitivas, sem depender de adaptações externas ao próprio sistema.

Tratar acessibilidade como "algo a adicionar depois, se der tempo" é uma decisão de projeto com consequência direta: retrofitting de acessibilidade em uma interface já construída sem essa preocupação costuma exigir revisão estrutural, não apenas ajustes cosméticos — motivo pelo qual este componente trata acessibilidade na mesma unidade em que trata responsividade, e não como tópico isolado ao final. No Brasil, a Lei Brasileira de Inclusão (Lei nº 13.146/2015) reforça o caráter de direito, não de cortesia, do acesso digital.

## 2. Escala de fonte definida pelo sistema

Usuários com baixa visão frequentemente aumentam a escala de fonte global do sistema Android (Configurações > Acessibilidade > Tamanho da fonte), esperando que **todos** os aplicativos respeitem essa preferência. Retomando a Aula 3: usar `sp` (não `dp`) para texto é o que garante essa obediência automática.

> **Falha comum**: definir alturas fixas de contêiner que dependem do texto caber em uma única linha com o tamanho de fonte padrão. Quando o usuário aumenta a escala de fonte, o texto quebra em múltiplas linhas e é cortado, porque o contêiner não pode crescer.

```xml
<!-- Errado: altura fixa não acomoda fonte ampliada -->
<TextView
    android:layout_height="24dp"
    android:text="Confirmar pedido" />

<!-- Correto: altura calculada a partir do conteúdo -->
<TextView
    android:layout_height="wrap_content"
    android:minHeight="24dp"
    android:text="Confirmar pedido" />
```

## 3. Contraste

As diretrizes WCAG (Web Content Accessibility Guidelines, também aplicáveis a interfaces móveis) recomendam uma razão de contraste mínima de **4,5:1** entre texto e fundo para texto normal, e **3:1** para texto grande (≥18pt ou ≥14pt em negrito). Esses valores de "pt" são **pontos CSS**, a unidade em que o WCAG é definido — não confundir com `sp` do Android. Na prática, a equivalência aproximada usada no Android é **~24sp normal / ~18sp em negrito** como limiar de "texto grande"; use essa referência ao aplicar o critério de contraste a um projeto Android/Flutter/React Native, não o valor em pontos diretamente. Combinações de cor esteticamente agradáveis, mas de baixo contraste (ex.: cinza claro sobre branco), são uma causa frequente de violação — e afetam não apenas usuários com baixa visão, mas qualquer usuário sob luz solar direta, retomando o contexto de uso móvel discutido na Aula 4.

> **Definição — Razão de contraste**: medida numérica da diferença de luminância entre duas cores, calculada segundo fórmula padronizada pelo W3C, usada para verificar objetivamente se um par de cores (texto/fundo) é suficientemente legível.

## 4. Leitor de tela e rótulos acessíveis

> **Definição — Leitor de tela (screen reader)**: software assistivo (TalkBack no Android) que converte o conteúdo e a estrutura da interface em fala ou saída em braile, permitindo que uma pessoa cega ou com baixa visão opere o aplicativo sem depender da visualização da tela.

Para que o TalkBack funcione corretamente, cada elemento interativo precisa de um **rótulo acessível** — uma descrição textual do seu propósito, mesmo quando visualmente representado apenas por um ícone.

```kotlin
// Jetpack Compose
IconButton(onClick = { excluirItem() }) {
    Icon(
        imageVector = Icons.Default.Delete,
        contentDescription = "Excluir item do carrinho"
    )
}
```

Elementos puramente decorativos (um ícone sem função própria, ao lado de um texto que já descreve a mesma informação) devem ser marcados como não importantes para acessibilidade, evitando que o leitor de tela leia informação redundante e cansativa. Em Compose, `Icon(imageVector = ..., contentDescription = null)` já sinaliza isso para um ícone isolado; para agrupar um conjunto de elementos (ícone + texto) como um único alvo de leitura, descartando a leitura individual dos filhos, usa-se `Modifier.clearAndSetSemantics { }`.

## 5. Ordem de foco

> **Definição — Ordem de foco**: sequência em que os elementos interativos de uma tela recebem foco ao navegar por teclado externo, controle de acessibilidade por varredura, ou leitor de tela — deve corresponder à ordem lógica de leitura esperada pelo usuário, tipicamente de cima para baixo e da esquerda para a direita (em idiomas ocidentais).

Layouts construídos com posicionamento absoluto ou reordenação puramente visual (um elemento posicionado visualmente no topo, mas declarado depois na árvore de código) podem produzir uma ordem de foco confusa — o leitor de tela anuncia os elementos fora da ordem que o usuário vidente veria. A ordem de foco deve ser verificada explicitamente, não presumida a partir do resultado visual.

## 6. Alvo mínimo e redução de movimento

- **Alvo mínimo de toque**: retomando a Aula 4, 48dp × 48dp é também um requisito de acessibilidade motora — usuários com tremor ou controle motor reduzido têm taxa de erro de toque ainda maior em alvos pequenos.
- **Redução de movimento**: o sistema permite ao usuário ativar "Remover animações" (Configurações > Acessibilidade), relevante para pessoas com sensibilidade vestibular a movimento na tela. Aplicativos devem consultar essa preferência antes de disparar animações não essenciais — a API varia por plataforma/framework:

| Plataforma/framework | Como consultar a preferência |
|---|---|
| Android nativo (Views) | `Settings.Global.ANIMATOR_DURATION_SCALE` |
| Jetpack Compose | `LocalAccessibilityManager` |
| Flutter | `MediaQuery.disableAnimationsOf(context)` |
| React Native | `AccessibilityInfo.isReduceMotionEnabled()` |

## 7. Estados de vazio, carregamento e erro como parte do design

Um erro recorrente em protótipos de estudantes é desenhar apenas o "caminho feliz" — a tela com dados preenchidos e tudo funcionando — deixando estados de vazio, carregamento e erro para serem "resolvidos na implementação". Isso é uma falha de projeto, não de implementação: esses três estados ocorrem com frequência real de uso igual ou maior que o estado "ideal".

> **Definição — Estado vazio (empty state)**: condição da interface em que não há dados a exibir (ex.: uma lista de pedidos para um usuário novo), que deve comunicar claramente a ausência de dados e, quando aplicável, orientar a próxima ação possível — não deve ser simplesmente uma tela em branco, que o usuário interpreta como falha.

| Estado | O que a interface deve comunicar |
|---|---|
| Vazio | Por que não há conteúdo, e o que fazer a respeito (ex.: "Você ainda não tem pedidos — explore o catálogo") |
| Carregando | Que uma operação está em andamento, sem bloquear percepção de progresso além do razoável |
| Erro | O que deu errado, em linguagem específica (retomando o UX writing da Aula 6), e uma ação de recuperação (tentar novamente) |

## 8. Exemplo real: por que o contraste importa mais do que parece

Um estudo de caso comum em avaliações de acessibilidade de aplicativos brasileiros é o de telas com texto cinza claro (`#AAAAAA`) sobre fundo branco, usado por escolha estética para "suavizar" informação secundária — uma combinação com razão de contraste próxima de 2,3:1, bem abaixo do mínimo de 4,5:1. Em condições de uso real (sol forte, tela com brilho reduzido para economizar bateria, usuário com fadiga visual ao final do dia), esse texto se torna praticamente ilegível para uma parcela relevante de usuários, não apenas para quem tem deficiência visual diagnosticada — evidenciando que acessibilidade bem projetada melhora a experiência de todos, não apenas de uma minoria.

## Síntese da aula

| Requisito | Verificação prática |
|---|---|
| Escala de fonte | Usar `sp`; alturas com `wrap_content`/`minHeight`, não fixas |
| Contraste | Mínimo 4,5:1 (texto normal), 3:1 (texto grande) |
| Leitor de tela | `contentDescription` em todo elemento interativo |
| Ordem de foco | Corresponder à ordem visual de leitura |
| Estados de vazio/carregamento/erro | Desenhados como parte do fluxo, não como exceção |

## Ferramentas de verificação

Duas ferramentas gratuitas eliminam a necessidade de verificar contraste e alvo de toque manualmente:

- **Accessibility Scanner** (Google, app Android): varre a tela em execução e reporta automaticamente violações de contraste e de tamanho de alvo de toque.
- **Verificador de contraste do WebAIM** ([webaim.org/resources/contrastchecker](https://webaim.org/resources/contrastchecker/)): informa a razão de contraste exata entre dois valores de cor e se atende AA/AAA.

## Leitura recomendada

- WORLD WIDE WEB CONSORTIUM. *Web Content Accessibility Guidelines (WCAG) 2.2*.
- Documentação oficial: [Torne seus apps mais acessíveis](https://developer.android.com/guide/topics/ui/accessibility).

## Atividade da aula

**Atividade de sensibilização (20 min, recomendada antes da entrega)**: cada estudante ativa o TalkBack, veda os próprios olhos e tenta completar uma tarefa simples no aplicativo de banco que já usa no dia a dia. É a forma mais eficaz de converter acessibilidade de tópico de prova em convicção — poucos minutos costumam revelar mais violações do que uma hora de leitura.

**Entrega 1 — Interface responsiva e acessibilidade (peso 15%)**: cada equipe entrega o protótipo de alta fidelidade da tela trabalhada nas Aulas 6 e 7, agora nas três classes de tamanho de janela, acompanhado de um laudo de acessibilidade cobrindo: verificação de contraste de todos os pares texto/fundo usados (com o verificador do WebAIM ou o Accessibility Scanner), rótulos acessíveis definidos para cada elemento interativo, ordem de foco documentada, e desenho explícito dos estados de vazio, carregamento e erro da tela escolhida. Rubrica detalhada em [`recursos/rubricas/entrega-1-interface-acessivel.md`](../recursos/rubricas/entrega-1-interface-acessivel.md) — cada critério (responsividade nas três classes, contraste, rótulos, ordem de foco, estados) é avaliado separadamente.
