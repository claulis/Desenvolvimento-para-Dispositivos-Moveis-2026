# Aula 20 — Análise comparativa Flutter × React Native e defesa arquitetural

**Carga horária:** 4h
**Unidade:** V — Estilos arquiteturais, renderização e análise comparativa

## Objetivos da aula

- Consolidar, com evidência coletada pela própria equipe, a comparação entre as implementações Flutter e React Native do mesmo módulo.
- Aplicar atributos de qualidade de software como critério explícito de decisão arquitetural, não como impressão subjetiva.
- Defender oralmente uma recomendação de plataforma para um cenário concreto, sustentada por dados e por arquitetura, não por preferência.

## 1. Por que esta aula fecha o curso, e não abre um tópico novo

Desde a Aula 13, este componente vem construindo, aula a aula, uma tabela comparativa entre Flutter e React Native — renderização (Aulas 9/13), estado (Aulas 10/14), dados e conectividade (Aulas 11/15), navegação e integração nativa (Aulas 12/16), desempenho de renderização (Aula 19). Esta aula não introduz teoria nova: **consolida** o que já foi construído, e responde à pergunta que ficou implícita em cada comparação até aqui — dado tudo isso, qual escolher, e sob quais condições?

> **Definição — Atributo de qualidade (quality attribute)**: propriedade mensurável ou observável de um sistema (desempenho, portabilidade, manutenibilidade, testabilidade, segurança, entre outras) usada como critério objetivo para avaliar e comparar decisões de arquitetura, em contraposição a critérios subjetivos como preferência pessoal ou familiaridade da equipe (BASS; CLEMENTS; KAZMAN, retomando a leitura da Aula 1).

## 2. Consolidação do quadro comparativo

Reúna, em uma única tabela, as comparações já produzidas ao longo do componente:

| Dimensão | Flutter | React Native | Aula(s) de origem |
|---|---|---|---|
| Renderização | Motor próprio (Impeller), desenha cada pixel | Componentes nativos reais, via Fabric | 9, 13 |
| Linguagem e execução | Dart, compilado AOT | JavaScript/TypeScript sobre Hermes (bytecode AOT + interpretação) | 9, 13 |
| Gerenciamento de estado | Provider/Riverpod/BLoC | Context/Redux/Zustand + TanStack Query | 10, 14 |
| Camada de dados | Repositório + `dio`/`sqflite`/`connectivity_plus` | Repositório + `axios`/MMKV/NetInfo | 11, 15 |
| Navegação | `go_router`, declarativa | React Navigation, `linking` | 12, 16 |
| Integração nativa | Canal de plataforma (`MethodChannel`/`pigeon`) | TurboModules/Codegen (ou Expo Modules) | 12, 16 |
| Custo de renderização de listas | Escopo de `setState`/escuta seletiva, `ListView.builder` | `React.memo`+seletor, `FlatList` | 19 |

Se sua equipe manteve a tabela recomendada na Aula 13 §7, esta etapa é apenas revisão e organização — não reconstrução.

## 3. Evidência empírica, não impressão

A comparação de maior valor não é a teórica acima, mas os **números que sua própria equipe já mediu** ao longo do semestre. Reúna, das entregas anteriores:

| Métrica | Onde foi medida |
|---|---|
| Tamanho do pacote instalável (APK/IPA) | Build de release de cada módulo |
| Tempo de *cold start* | Observação de aula (Aula 1) e medição em aparelho real |
| Tempo de reconstrução/re-renderização de um item de lista, antes e depois da correção | Aula 19 |
| Linhas de código por camada (apresentação/domínio/dados) | Módulos das Aulas 10-12 e 14-16 |
| Número de dependências externas declaradas | `pubspec.yaml` / `package.json` de cada módulo |

Uma recomendação apoiada nesses números — mesmo que a amostra seja de uma única equipe, um único módulo — vale mais nesta aula do que uma opinião sobre "qual framework é melhor" sem nenhuma medição por trás.

## 4. "Não existe melhor, existe melhor para"

Retomando o princípio da Aula 17 (nenhum estilo arquitetural é universalmente superior): o mesmo vale para a escolha entre Flutter e React Native. Cada equipe deve produzir uma recomendação justificada — não uma escolha única para todos os casos — para três cenários:

1. **Startup de 3 pessoas, equipe já proficiente em desenvolvimento web (React/TypeScript)**: o custo de ramp-up (Aula 13 §7) tende a pesar mais que a diferença de desempenho de renderização para a maioria dos produtos.
2. **Aplicativo bancário com requisito forte de biometria, segurança de armazenamento local e certificação de plataforma**: a proximidade com APIs nativas e a maturidade de bibliotecas de segurança em cada ecossistema tornam-se o critério dominante — pesquise o estado atual de suporte a biometria/armazenamento seguro em cada framework antes de decidir.
3. **Aplicativo com identidade visual proprietária forte e animações complexas e não padronizadas**: a consistência pixel-a-pixel entre plataformas do Flutter (Aula 9) tende a pesar mais do que a proximidade nativa do React Native.

Para cada cenário, a equipe apresenta: a recomendação, os dois ou três atributos de qualidade que mais pesaram na decisão, e o que faria a equipe mudar de recomendação (qual condição inverteria a escolha).

## 5. Quando nenhum dos dois é a resposta certa

Honestidade sobre o limite do escopo deste componente: Flutter e React Native não esgotam o espaço de soluções para desenvolvimento mobile multiplataforma. Vale conhecer, ainda que superficialmente, os concorrentes mais relevantes de 2026:

- **Kotlin Multiplatform (KMP) + Compose Multiplatform**: compartilha lógica de negócio (e, com Compose Multiplatform, também a interface) entre Android, iOS e outras plataformas, mantendo Kotlin como linguagem única — interessante para equipes já fortemente investidas no ecossistema Android nativo.
- **PWA (Progressive Web App)**: quando o alcance multiplataforma via navegador é aceitável e o acesso a APIs nativas profundas não é um requisito central — mais barato de manter, mas com limites reais de acesso a hardware e de distribuição em lojas de aplicativo.
- **Desenvolvimento nativo puro (Kotlin/Swift separados)**: ainda a escolha certa quando o produto depende fortemente de recursos de plataforma de ponta, sem tempo de espera por suporte multiplataforma, ao custo de manter duas bases de código completamente distintas.

Nenhuma dessas opções foi ensinada neste componente — cite-as na apresentação apenas como reconhecimento de que o espaço de decisão é maior do que os dois frameworks estudados, não como recomendação a se aprofundar sem orientação adicional.

## Síntese da aula

| Etapa | Produto |
|---|---|
| Consolidação | Tabela comparativa completa, das Aulas 9-19 |
| Evidência | Métricas reais medidas pela própria equipe |
| Contextualização | Recomendação justificada para três cenários distintos |
| Limite do escopo | Reconhecimento de alternativas não cobertas pelo curso |

## Leitura recomendada

- BASS, Len; CLEMENTS, Paul; KAZMAN, Rick. *Software Architecture in Practice*, 4. ed. — capítulos sobre atributos de qualidade como critério de decisão arquitetural (retomando a Aula 1).
- RICHARDS, Mark; FORD, Neal. *Fundamentals of Software Architecture* — capítulo sobre análise de trade-offs arquiteturais.

## Atividade da aula

**Avaliação 3 — Análise comparativa e defesa final (peso 30%)**: cada equipe entrega um relatório comparativo baseado nas duas implementações da própria equipe (Flutter e React Native do mesmo módulo), cobrindo a tabela consolidada da §2, a evidência empírica da §3 e a recomendação justificada para os três cenários da §4. A entrega é seguida de defesa oral, na qual a banca (docente e colegas) desafia a recomendação apresentada — questionando se a decisão está de fato ancorada em evidência medida pela equipe, ou em preferência não justificada. Esse é o critério central de avaliação desta etapa: **evidência sustenta a recomendação, ou apenas a acompanha?**

Com esta entrega, fecham-se os 100% da avaliação do componente e as 80h de carga horária previstas.
