# Aula 5 — Pesquisa breve com usuário e heurísticas de usabilidade

**Carga horária:** 4h
**Unidade:** II — Interface, experiência e responsividade

## Objetivos da aula

- Planejar e conduzir uma pesquisa breve de usuário adequada ao contexto mobile.
- Aplicar as heurísticas de usabilidade de Nielsen a interfaces Android.
- Reconhecer implicações éticas e de proteção de dados na coleta de informação com usuários.

## 1. Por que pesquisar antes de desenhar

Decisões de interface tomadas sem qualquer contato com o usuário real tendem a refletir o modelo mental do próprio desenvolvedor — que, tendo construído o sistema, jamais terá a mesma incerteza que um usuário novo enfrenta ao abri-lo pela primeira vez. Uma pesquisa breve, mesmo pequena e informal, é suficiente para revelar divergências entre o modelo mental do time e o do usuário real, tema introduzido na Aula 4.

> **Definição — Pesquisa de usuário**: conjunto de métodos sistemáticos para coletar informação diretamente de pessoas que usam ou usarão o sistema, com o objetivo de fundamentar decisões de projeto em evidência, e não apenas em suposição.

## 2. Métodos leves adequados a um projeto de disciplina

Não é necessário um laboratório de usabilidade para gerar evidência útil. Métodos leves e apropriados ao prazo de um semestre:

- **Entrevista curta orientada a tarefa** (10–15 minutos): pedir que a pessoa descreva como resolveria hoje o problema que o app pretende resolver, sem mencionar o produto ainda — evita respostas contaminadas pela expectativa de "elogiar a ideia".
- **Observação de uso de um concorrente ou aplicativo análogo**: observar (sem interferir) alguém usando um app já existente que resolve um problema parecido, anotando hesitações, erros e comentários espontâneos.
- **Teste de usabilidade com protótipo de papel ou baixa fidelidade**: pedir que a pessoa tente completar uma tarefa específica usando o protótipo, narrando o que pensa em voz alta (*think-aloud protocol*).

> **Definição — Protocolo de pensar em voz alta (think-aloud)**: técnica em que o participante verbaliza continuamente seus pensamentos enquanto realiza uma tarefa, permitindo ao pesquisador observar não apenas o que a pessoa faz, mas por que ela acredita estar fazendo aquilo.

## 3. Roteiro de entrevista: estrutura mínima

Um roteiro breve e bem construído tem três partes:

1. **Contexto** — perguntas abertas sobre como a pessoa resolve hoje o problema em questão, sem menção ao produto.
2. **Tarefa** — se houver protótipo, pedir que tente completar uma tarefa concreta e específica (não "explore o app à vontade", que produz dados difíceis de comparar entre participantes).
3. **Reflexão** — perguntas sobre o que foi confuso, o que faltou, o que surpreendeu — feitas *depois* da tarefa, nunca durante, para não induzir a resposta.

## 4. Viés na coleta

> **Definição — Viés de confirmação**: tendência do pesquisador a interpretar respostas ambíguas de forma a confirmar a hipótese que já tinha antes da pesquisa.

Formas comuns de introduzir viés em pesquisa de usuário e como evitá-las:

| Fonte de viés | Exemplo | Mitigação |
|---|---|---|
| Pergunta indutiva | "Você achou fácil usar o botão de comprar, não achou?" | Perguntar de forma neutra: "Como foi tentar comprar?" |
| Participante "de conveniência" | Testar apenas com colegas de turma que já entendem o domínio técnico | Buscar ao menos 1–2 pessoas fora do círculo do time, mais próximas do usuário-alvo real |
| Amostra pequena interpretada como conclusiva | "Testamos com 1 pessoa e funcionou, está pronto" | Tratar achados de amostra pequena como hipótese a confirmar, não como validação definitiva |

## 5. As dez heurísticas de usabilidade de Nielsen aplicadas ao Android

Jakob Nielsen propôs, em 1994, dez princípios gerais de usabilidade que permanecem amplamente usados como checklist de avaliação heurística. Adaptadas ao contexto Android:

1. **Visibilidade do estado do sistema** — o app informa o que está acontecendo (indicador de carregamento, confirmação de envio) em vez de deixar o usuário sem retorno.
2. **Correspondência entre o sistema e o mundo real** — linguagem e ícones familiares ao usuário, não jargão técnico interno (ex.: usar "Meus pedidos", não "Consultar registros de transação").
3. **Controle e liberdade do usuário** — sempre existe uma saída clara (botão voltar funcional, cancelar uma ação em andamento) — retoma diretamente a pilha de retorno da Aula 2.
4. **Consistência e padrões** — seguir as convenções do Material Design e do próprio Android (retoma a Aula 4: convenções de plataforma).
5. **Prevenção de erros** — desabilitar um botão de envio até o formulário estar válido, em vez de deixar o usuário errar e só depois avisar.
6. **Reconhecimento em vez de memorização** — mostrar opções disponíveis (ex.: sugestões de busca) em vez de exigir que o usuário lembre um comando ou termo exato.
7. **Flexibilidade e eficiência de uso** — atalhos para usuários experientes (ex.: gestos, favoritos) sem obrigar o usuário novato a usá-los.
8. **Estética e design minimalista** — cada elemento na tela compete por atenção; informação irrelevante à tarefa atual reduz a usabilidade, especialmente relevante na tela pequena do celular.
9. **Ajudar o usuário a reconhecer, diagnosticar e corrigir erros** — mensagens de erro específicas ("O CEP informado não foi encontrado") em vez de genéricas ("Erro 500").
10. **Ajuda e documentação** — quando necessária, deve ser buscável e focada na tarefa, não um manual extenso — em mobile, geralmente substituída por *onboarding* contextual e dicas no próprio fluxo.

## 6. Avaliação heurística: método

> **Definição — Avaliação heurística**: método de inspeção de usabilidade em que avaliadores examinam sistematicamente uma interface confrontando-a contra um conjunto conhecido de princípios (heurísticas), identificando violações e classificando sua severidade — sem necessidade de recrutar usuários reais.

Processo recomendado para a atividade desta aula:

1. Definir 3 a 5 tarefas representativas no aplicativo avaliado.
2. Percorrer cada tarefa observando violações a cada uma das dez heurísticas.
3. Classificar cada achado por severidade, usando a escala de Nielsen (1994) — os cinco níveis abaixo, sempre com os mesmos descritores para toda a turma, garantindo que os laudos sejam comparáveis entre estudantes:

| Nível | Descrição |
|---|---|
| 0 | Não é um problema de usabilidade |
| 1 | Problema cosmético — corrigir apenas se houver tempo sobrando |
| 2 | Problema menor — prioridade baixa de correção |
| 3 | Problema maior — importante corrigir, prioridade alta |
| 4 | Catástrofe de usabilidade — impede ou bloqueia o uso, corrigir antes do lançamento |

4. Registrar cada achado com: heurística violada, local exato na interface, descrição do problema, severidade (0–4, escala acima) e sugestão de correção.

## 7. Ética e proteção de dados na coleta

Mesmo em pesquisa informal de disciplina, princípios éticos básicos se aplicam:

- **Consentimento informado**: explicar ao participante o que será observado/gravado e como será usado, antes de começar.
- **Minimização de dados**: coletar apenas o necessário para a pesquisa — não gravar áudio/vídeo se anotações escritas já bastam.
- **Anonimização em relatórios**: ao reportar achados (inclusive nas entregas desta disciplina), evitar identificar participantes por nome completo sem consentimento explícito para tal.
- Essas práticas dialogam diretamente com a Lei Geral de Proteção de Dados (Lei nº 13.709/2018), que trata dados pessoais coletados mesmo em contexto de pesquisa.

## 8. Exemplo real: o que uma avaliação heurística revela que uma opinião não revela

Um time de estudantes desenhando um aplicativo de agendamento de serviços pode, por convicção própria, acreditar que o fluxo de cadastro é claro. Uma avaliação heurística estruturada, no entanto, frequentemente revela violações específicas e acionáveis — por exemplo, um campo de telefone sem máscara de formatação (violação da heurística 5, prevenção de erros) ou uma mensagem de erro genérica "Erro ao salvar" sem indicar qual campo está incorreto (violação da heurística 9). A diferença entre "achamos que está bom" e um relatório de avaliação heurística é que o segundo aponta o local exato, a heurística violada e uma ação corretiva concreta — exatamente o padrão de rigor exigido nas entregas desta disciplina.

## Síntese da aula

| Etapa | Instrumento |
|---|---|
| Coletar evidência | Entrevista curta, observação, teste com protótipo |
| Evitar viés | Perguntas neutras, amostra além do círculo do time |
| Avaliar interface existente | Avaliação heurística contra as 10 heurísticas de Nielsen |
| Documentar achado | Heurística, local, severidade, sugestão |

## Leitura recomendada

- PREECE; ROGERS; SHARP. *Design de Interação*, 3. ed. — capítulos sobre métodos de pesquisa e avaliação de usabilidade.
- NIELSEN, Jakob. "10 Usability Heuristics for User Interface Design" (Nielsen Norman Group).

## Atividade da aula

**Avaliação heurística de um aplicativo Android existente, com laudo de achados (atividade formativa, sem peso na nota)**: cada estudante escolhe um aplicativo Android popular (não o próprio produto da equipe), define três tarefas representativas, percorre-as e produz um laudo estruturado com no mínimo 8 achados classificados por heurística violada, severidade e sugestão de correção. Use o modelo pronto em [`recursos/template-laudo-heuristico.md`](../recursos/template-laudo-heuristico.md), com colunas fixas (`# | Heurística | Tela/local | Descrição | Severidade | Correção proposta | Evidência`), para padronizar a correção. Os achados de acessibilidade encontrados aqui devem alimentar o laudo de acessibilidade da Entrega 1 (Aula 8) — as duas atividades tratam do mesmo produto de análise sempre que possível.
