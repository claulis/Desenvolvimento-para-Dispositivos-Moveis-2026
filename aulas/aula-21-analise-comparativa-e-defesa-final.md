# Aula 21 — Análise comparativa Flutter × React Native e defesa arquitetural

**Carga horária:** 4h
**Unidade:** V — Estilos arquiteturais, renderização e análise comparativa

## Objetivos da aula

- Consolidar, com base em evidência medida, a comparação entre implementações Flutter e React Native do mesmo módulo.
- Aplicar atributos de qualidade de software como critério explícito de decisão arquitetural, não como impressão subjetiva.
- Formular uma recomendação de plataforma para um cenário concreto, sustentada por dados e por arquitetura, não por preferência.

## 1. Por que esta aula fecha o curso, e não abre um tópico novo

Das Aulas 10 a 20, Flutter e React Native foram comparados dimensão a dimensão — renderização (Aulas 10/14), estado (Aulas 11/15), dados e conectividade (Aulas 12/16), navegação e integração nativa (Aulas 13/17), desempenho de renderização (Aula 20). Esta aula não introduz teoria nova: **consolida** o que já foi construído, e responde à pergunta que ficou implícita em cada comparação até aqui — dado tudo isso, qual escolher, e sob quais condições?

> **Definição — Atributo de qualidade (quality attribute)**: propriedade mensurável ou observável de um sistema (desempenho, portabilidade, manutenibilidade, testabilidade, segurança, entre outras) usada como critério objetivo para avaliar e comparar decisões de arquitetura, em contraposição a critérios subjetivos como preferência pessoal ou familiaridade da equipe (BASS; CLEMENTS; KAZMAN, retomando a leitura da Aula 1).

## 2. Consolidação do quadro comparativo

A tabela abaixo reúne as comparações feitas ao longo do componente:

| Dimensão | Flutter | React Native | Aula(s) de origem |
|---|---|---|---|
| Renderização | Motor próprio (Impeller), desenha cada pixel | Componentes nativos reais, via Fabric | 10, 14 |
| Linguagem e execução | Dart, compilado AOT | JavaScript/TypeScript sobre Hermes (bytecode AOT + interpretação) | 10, 14 |
| Gerenciamento de estado | Provider/Riverpod/BLoC | Context/Redux/Zustand + TanStack Query | 11, 15 |
| Camada de dados | Repositório + `dio`/`sqflite`/`connectivity_plus` | Repositório + `axios`/MMKV/NetInfo | 12, 16 |
| Navegação | `go_router`, declarativa | React Navigation, `linking` | 13, 17 |
| Integração nativa | Canal de plataforma (`MethodChannel`/`pigeon`) | TurboModules/Codegen (ou Expo Modules) | 13, 17 |
| Custo de renderização de listas | Escopo de `setState`/escuta seletiva, `ListView.builder` | `React.memo`+seletor, `FlatList` | 20 |

## 3. Evidência empírica, não impressão

A comparação de maior valor não é a teórica acima, mas a que se apoia em **números medidos** nas duas implementações do mesmo módulo:

| Métrica | Como medir |
|---|---|
| Tamanho do pacote instalável (APK/IPA) | Build de release de cada módulo |
| Tempo de *cold start* | Medição em aparelho real (ver Aula 1) |
| Tempo de reconstrução/re-renderização de um item de lista, antes e depois da otimização | Ferramentas de perfilamento de cada framework (Aula 20) |
| Linhas de código por camada (apresentação/domínio/dados) | Contagem no código-fonte de cada implementação |
| Número de dependências externas declaradas | `pubspec.yaml` / `package.json` de cada módulo |

Uma recomendação apoiada nesses números — mesmo que a amostra seja de um único módulo — vale mais do que uma opinião sobre "qual framework é melhor" sem nenhuma medição por trás.

## 4. "Não existe melhor, existe melhor para"

Retomando o princípio da Aula 18 (nenhum estilo arquitetural é universalmente superior): o mesmo vale para a escolha entre Flutter e React Native. A recomendação justificada depende do cenário, e não há uma escolha única para todos os casos. Três exemplos:

1. **Startup de 3 pessoas, equipe já proficiente em desenvolvimento web (React/TypeScript)**: o custo de ramp-up (Aula 14 §7) tende a pesar mais que a diferença de desempenho de renderização para a maioria dos produtos.
2. **Aplicativo bancário com requisito forte de biometria, segurança de armazenamento local e certificação de plataforma**: a proximidade com APIs nativas e a maturidade de bibliotecas de segurança em cada ecossistema tornam-se o critério dominante — e o estado atual de suporte a biometria/armazenamento seguro em cada framework precisa ser verificado antes da decisão.
3. **Aplicativo com identidade visual proprietária forte e animações complexas e não padronizadas**: a consistência pixel-a-pixel entre plataformas do Flutter (Aula 10) tende a pesar mais do que a proximidade nativa do React Native.

Em cada cenário, uma recomendação bem fundamentada explicita os dois ou três atributos de qualidade que mais pesaram na decisão e a condição que inverteria a escolha.

## 5. Quando nenhum dos dois é a resposta certa

Honestidade sobre o limite do escopo deste componente: Flutter e React Native não esgotam o espaço de soluções para desenvolvimento mobile multiplataforma. Vale conhecer, ainda que superficialmente, os concorrentes mais relevantes de 2026:

- **Kotlin Multiplatform (KMP) + Compose Multiplatform**: compartilha lógica de negócio (e, com Compose Multiplatform, também a interface) entre Android, iOS e outras plataformas, mantendo Kotlin como linguagem única — interessante para equipes já fortemente investidas no ecossistema Android nativo.
- **PWA (Progressive Web App)**: quando o alcance multiplataforma via navegador é aceitável e o acesso a APIs nativas profundas não é um requisito central — mais barato de manter, mas com limites reais de acesso a hardware e de distribuição em lojas de aplicativo.
- **Desenvolvimento nativo puro (Kotlin/Swift separados)**: ainda a escolha certa quando o produto depende fortemente de recursos de plataforma de ponta, sem tempo de espera por suporte multiplataforma, ao custo de manter duas bases de código completamente distintas.

Nenhuma dessas opções foi tratada neste componente; servem apenas como reconhecimento de que o espaço de decisão é maior do que os dois frameworks estudados, não como recomendação a se aprofundar sem orientação adicional.

## Síntese da aula

| Etapa | Produto |
|---|---|
| Consolidação | Tabela comparativa completa, das Aulas 10-20 |
| Evidência | Métricas medidas nas duas implementações |
| Contextualização | Recomendação justificada para três cenários distintos |
| Limite do escopo | Reconhecimento de alternativas não cobertas pelo curso |

## Leitura recomendada

- BASS, Len; CLEMENTS, Paul; KAZMAN, Rick. *Software Architecture in Practice*, 4. ed. — capítulos sobre atributos de qualidade como critério de decisão arquitetural (retomando a Aula 1).
- RICHARDS, Mark; FORD, Neal. *Fundamentals of Software Architecture* — capítulo sobre análise de trade-offs arquiteturais.
