<div align="center">

# Desenvolvimento para Dispositivos Móveis

### Do smartphone como plataforma de projeto às arquiteturas Flutter e React Native

<br/>

![Android](https://img.shields.io/badge/Android-3DDC84?style=plastic&logo=android&logoColor=white)
![Kotlin](https://img.shields.io/badge/Kotlin-7F52FF?style=plastic&logo=kotlin&logoColor=white)
![Flutter](https://img.shields.io/badge/Flutter-02569B?style=plastic&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=plastic&logo=dart&logoColor=white)
![React Native](https://img.shields.io/badge/React_Native-20232A?style=plastic&logo=react&logoColor=61DAFB)
![TypeScript](https://img.shields.io/badge/TypeScript-3178C6?style=plastic&logo=typescript&logoColor=white)
![Material Design](https://img.shields.io/badge/Material_Design-757575?style=plastic&logo=materialdesign&logoColor=white)
![Figma](https://img.shields.io/badge/Figma-F24E1E?style=plastic&logo=figma&logoColor=white)

</div>

---

## 📖 Introdução

Este repositório reúne o material da disciplina **Desenvolvimento para Dispositivos Móveis**, um componente de 80h organizado em 20 aulas que percorre o ciclo completo de concepção de aplicativos móveis: desde as restrições impostas pelo **smartphone como plataforma de projeto** — ciclo de vida, permissões, fragmentação de telas e ergonomia — passando pela **experiência do usuário e a responsividade de interfaces** com base no Material Design, até a **construção de arquiteturas de software reais** com **Flutter** e **React Native**, encerrando com uma **análise comparativa de estilos arquiteturais, modularização, desempenho de renderização e defesa arquitetural** entre as duas plataformas.

Cada aula tem carga horária de 4h e está disponível como um arquivo Markdown individual na pasta [`aulas/`](aulas/). Além das aulas, o repositório inclui:

- [`codigo/`](codigo/) — projetos Flutter e React Native executáveis que acompanham as atividades das Unidades III e IV, cada um com ponto de partida (`inicio/`) e solução de referência (`solucao/`).
- [`recursos/`](recursos/) — rubricas de avaliação, templates, anexos de nivelamento em Dart/TypeScript, e uma API simulada com dados de exemplo.

## 🎯 Público e pré-requisitos

Componente de 80h. Pré-requisitos: programação orientada a objetos, lógica de programação e noções de JavaScript/ES6. Não exige experiência prévia com desenvolvimento mobile. Quem não tiver familiaridade recente com Dart ou TypeScript pode usar os anexos de nivelamento antes das Unidades III e IV: [`recursos/dart-em-30-minutos.md`](recursos/dart-em-30-minutos.md) e [`recursos/typescript-em-30-minutos.md`](recursos/typescript-em-30-minutos.md).

## 🔭 Escopo

Foco em **Android** como plataforma de referência (maioria do mercado brasileiro — confira a fatia atual no [StatCounter GlobalStats](https://gs.statcounter.com/os-market-share/mobile/brazil), pois o número muda a cada semestre). Os exemplos ilustrativos de Android nativo usam **Jetpack Compose**, não o sistema legado de Views/XML — o componente não ensina Kotlin nem entrega nada em Android nativo; o badge de Kotlin acima marca contexto ilustrativo, não conteúdo avaliado. Flutter e React Native são multiplataforma; iOS é mencionado como contexto, não avaliado.

## ⚙️ Ambiente e versões de referência (2026.1)

Revalide estas versões no início de cada semestre — o próprio nome do repositório ("2026") deixa de ser preciso se as versões não forem mantidas atualizadas.

| Ferramenta | Versão de referência |
|---|---|
| Flutter / Dart | Canal stable mais recente na data de início do semestre |
| React Native (via Expo) | Expo SDK mais recente / React Native com Nova Arquitetura (padrão desde a 0.76) |
| Android Studio | Versão estável mais recente |
| `minSdk` / `targetSdk` | 24 / o mais recente disponível no Android Studio no início do semestre |
| Node.js | LTS ativo |

## 📝 Avaliação

| Instrumento | Aula | Peso |
|---|---|---|
| Avaliação 1 — Contexto de uso e restrições de plataforma | 4 | 15% |
| Entrega 1 — Interface responsiva e acessível | 8 | 15% |
| Avaliação 2 — Módulo Flutter + arguição individual | 12 | 20% |
| Entrega 2 — Módulo React Native | 16 | 20% |
| Avaliação 3 — Análise comparativa e defesa final | 20 | 30% |
| **Total** | | **100%** |

Rubricas detalhadas em [`recursos/rubricas/`](recursos/rubricas/).

## 📄 Licença

Conteúdo das aulas sob [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/deed.pt-BR); exemplos de código em [`codigo/`](codigo/) sob licença MIT.

---

## 📑 Índice

### Unidade I — O smartphone e a plataforma Android como condicionantes de projeto
1. [O smartphone como plataforma de projeto](aulas/aula-01-o-smartphone-como-plataforma.md)
2. [Android para quem projeta: ciclo de vida, pilha de retorno e permissões](aulas/aula-02-ciclo-de-vida-pilha-de-retorno-permissoes.md)
3. [Ecossistema de telas Android](aulas/aula-03-ecossistema-de-telas-android.md)
4. [Contexto de uso móvel e ergonomia de alcance](aulas/aula-04-contexto-de-uso-movel-e-ergonomia.md)

### Unidade II — Interface, experiência e responsividade
5. [Pesquisa breve com usuário e heurísticas de usabilidade](aulas/aula-05-pesquisa-com-usuario-e-heuristicas.md)
6. [Hierarquia visual e Material Design](aulas/aula-06-material-design-e-hierarquia-visual.md)
7. [Responsividade I: unidades, pontos de quebra e classes de tamanho de janela](aulas/aula-07-responsividade-I.md)
8. [Responsividade II e acessibilidade](aulas/aula-08-responsividade-II-e-acessibilidade.md)

### Unidade III — Arquitetura de software em Flutter
9. [Flutter: modelo de execução e árvore de widgets](aulas/aula-09-flutter-execucao-e-widgets.md)
10. [Flutter: arquitetura em camadas e gerenciamento de estado](aulas/aula-10-flutter-arquitetura-e-estado.md)
11. [Flutter: camada de dados e conectividade intermitente](aulas/aula-11-flutter-dados-e-conectividade.md)
12. [Flutter: navegação declarativa e canais de plataforma](aulas/aula-12-flutter-navegacao-e-canais-de-plataforma.md)

### Unidade IV — Arquitetura de software em React Native
13. [React Native: modelo de execução e componentes](aulas/aula-13-react-native-execucao-e-componentes.md)
14. [React Native: arquitetura em camadas e gerenciamento de estado](aulas/aula-14-react-native-arquitetura-e-estado.md)
15. [React Native: camada de dados e conectividade](aulas/aula-15-react-native-dados-e-conectividade.md)
16. [React Native: navegação e módulos nativos](aulas/aula-16-react-native-navegacao-e-modulos-nativos.md)

### Unidade V — Estilos arquiteturais, renderização e análise comparativa
17. [Estilos arquiteturais aplicados a aplicações móveis](aulas/aula-17-estilos-arquiteturais.md)
18. [Modularização por funcionalidade e por camada](aulas/aula-18-modularizacao.md)
19. [Arquitetura da camada de apresentação e desempenho de renderização](aulas/aula-19-performance-de-renderizacao.md)
20. [Análise comparativa Flutter × React Native e defesa arquitetural](aulas/aula-20-analise-comparativa-e-defesa-final.md)

---

## 📁 Como usar o repositório

- **Estudando uma aula**: abra o arquivo correspondente em [`aulas/`](aulas/) — cada uma segue o mesmo formato (objetivos → conteúdo → exemplo real → síntese → leitura recomendada → atividade).
- **Fazendo uma atividade prática**: verifique se a aula referencia uma pasta em [`codigo/`](codigo/) — a maioria das atividades das Unidades III e IV tem um projeto executável correspondente, com `inicio/` (ponto de partida) e `solucao/` (referência, consultar depois de tentar).
- **Preparando uma entrega/avaliação**: consulte a rubrica correspondente em [`recursos/rubricas/`](recursos/rubricas/) antes de começar, não depois de terminar.
