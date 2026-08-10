# Aula 1 — O smartphone como plataforma de projeto

**Carga horária:** 4h
**Unidade:** I — O smartphone e a plataforma Android como condicionantes de projeto

## Objetivos da aula

Ao final desta aula, o estudante deve ser capaz de:

- Explicar por que o smartphone não é "um computador pequeno", mas uma plataforma com restrições próprias que devem orientar decisões de projeto desde o início.
- Relacionar hardware, sensores, energia, memória e temperatura às decisões de arquitetura e de interface.
- Descrever o panorama de fragmentação de aparelhos Android no Brasil e suas consequências práticas.

## 1. Por que o celular exige um jeito diferente de projetar

Um sistema web roda em uma máquina com energia praticamente ilimitada (a tomada), tela grande, mouse e teclado, e uma única versão de navegador dominante por vez. Um aplicativo Android roda numa bateria de capacidade finita, numa tela pequena tocada por dedos, sujeito a interrupções constantes (ligações, notificações, o usuário trocando de aplicativo), e precisa funcionar em milhares de combinações diferentes de fabricante, versão de sistema operacional e capacidade de hardware.

Essa diferença não é de grau, é de natureza: **as restrições do aparelho não são detalhes de implementação a resolver depois — são condicionantes que devem orientar a decisão de projeto desde a primeira linha**. Um projeto que ignora bateria, memória e fragmentação de tela na concepção tende a precisar de retrabalho estrutural mais tarde, não apenas de ajuste fino.

> **Definição — Condicionante de projeto**: restrição do ambiente de execução (hardware, sistema operacional, rede, aparelho do usuário) que limita o espaço de soluções aceitáveis e que, por isso, deve ser considerada durante a concepção da solução, e não apenas na fase de implementação.

## 2. Arquitetura de hardware do smartphone

Um smartphone típico é composto por várias categorias de componentes, cada uma com tecnologias concorrentes no mercado e com implicações de projeto próprias. Entender *o que* existe dentro do aparelho — não em profundidade de engenharia eletrônica, mas o suficiente para raciocinar sobre desempenho e consumo — é o que torna concreto o argumento da §1.

### SoC (System on Chip)

> **Definição — SoC (System on Chip)**: chip único que integra CPU, GPU, controlador de memória, modem de rádio (celular, Wi-Fi, Bluetooth), processador de sinal de imagem (ISP) e, em SoCs recentes, um acelerador dedicado de inteligência artificial (NPU), substituindo o conjunto de chips separados que um computador de mesa usa para as mesmas funções.

O SoC é a razão pela qual smartphones diferentes têm desempenho tão distinto mesmo rodando o mesmo sistema operacional — ele determina, de uma vez só, o teto de CPU, GPU e eficiência energética do aparelho. Os principais fabricantes de SoC para Android:

| Fabricante | Linha | Observação |
|---|---|---|
| Qualcomm | Snapdragon (8 Elite, 8, 7, 6, 4 séries) | Líder de mercado em volume; a série numérica (8 > 7 > 6 > 4) indica o segmento, do topo de linha à entrada |
| MediaTek | Dimensity | Forte em custo-benefício, hoje presente também em aparelhos topo de linha |
| Samsung | Exynos | Usado principalmente em aparelhos Galaxy, concorrendo internamente com versões Snapdragon do mesmo modelo em mercados diferentes |
| Google | Tensor | Desenvolvido com foco em recursos de IA on-device (linha Pixel), não necessariamente o mais rápido em benchmarks brutos |

Um dado técnico relevante para projeto: o **processo de fabricação** do SoC (medido em nanômetros — ex.: 4nm, 3nm) afeta diretamente eficiência energética e geração de calor. Processos mais finos permitem mais transistores no mesmo espaço físico, consumindo menos energia por operação — o que explica por que um SoC "mais moderno" pode ter desempenho comparável a um antigo consumindo bem menos bateria.

### CPU

Normalmente de arquitetura **ARM** (conjunto de instruções RISC, licenciado pela ARM Holdings — não x86/x86-64, usado pela maioria dos notebooks e desktops), atualmente na versão de 64 bits **ARMv8/ARMv9**. A CPU de um SoC moderno não tem núcleos idênticos: usa uma arquitetura de **núcleos heterogêneos**, historicamente chamada *big.LITTLE* e hoje evoluída para o esquema **DynamIQ** da ARM, com três (ou mais) categorias de núcleo no mesmo chip:

- **Núcleos "Prime"/de altíssimo desempenho**: 1 núcleo, usado para picos de carga curtos (abrir um app, um cálculo pesado pontual).
- **Núcleos de desempenho ("big")**: 3–5 núcleos, usados para tarefas que exigem CPU sustentada.
- **Núcleos de eficiência ("LITTLE")**: 2–4 núcleos, usados para a maior parte do tempo de uso comum (rolar uma lista, checar notificações) — o que realmente preserva a bateria no dia a dia.

O sistema operacional (o *scheduler* do kernel Linux) decide dinamicamente em qual núcleo executar cada tarefa, com base em prioridade e carga — uma decisão invisível ao desenvolvedor, mas cujo efeito é sentido diretamente: uma thread de interface mal escrita, presa em um núcleo de eficiência por uma tarefa que deveria ter sido leve, produz o mesmo travamento visual (Aula 19) que veria em um aparelho genuinamente mais fraco.

### GPU

Assim como a CPU, a GPU também tem fabricantes concorrentes, cada um com uma arquitetura própria integrada ao SoC do mesmo fabricante:

| Fabricante de GPU | Usada em | Observação |
|---|---|---|
| Qualcomm Adreno | SoCs Snapdragon | Historicamente referência de desempenho gráfico no Android |
| ARM Mali / Immortalis | SoCs MediaTek, Exynos, muitos outros | Presente na maior parte dos aparelhos de entrada e médio porte do mundo, por volume |
| Imagination PowerVR | Alguns SoCs MediaTek e chips especializados | Menos comum em topo de linha atual |

A GPU renderiza a interface. No Android, a interface tradicional é desenhada por composição de camadas (*layers*) que a GPU combina; no Flutter, o próprio motor de renderização (Impeller — ver nota de atualização na Aula 9) desenha diretamente na GPU, sem passar pelos widgets nativos do Android. Duas APIs gráficas de baixo nível dominam o acesso à GPU no Android: **OpenGL ES** (mais antiga, ainda amplamente suportada) e **Vulkan** (mais moderna, com controle mais direto sobre a GPU e menor sobrecarga da CPU para emitir comandos gráficos) — o Impeller do Flutter, por exemplo, usa Vulkan no Android quando disponível.

### RAM

> **Definição — RAM (Random Access Memory)**: memória volátil de acesso rápido usada para manter em execução o sistema operacional, os aplicativos ativos e os dados que estão sendo processados no momento — perdida integralmente quando o aparelho desliga, diferente do armazenamento.

Tipicamente entre 4 GB e 16 GB em aparelhos de 2024–2026, usando tecnologia **LPDDR4X** ou **LPDDR5/LPDDR5X** (*Low Power Double Data Rate* — variantes de baixo consumo da memória DDR usada em computadores), mas compartilhada entre sistema operacional, aplicativos em segundo plano e o aplicativo em uso. Diferente de um servidor, o app não "pede" memória livremente: o sistema pode encerrar processos em segundo plano sem aviso para liberar RAM (aprofundado na §4).

### Armazenamento

Memória flash **NAND**, não volátil (mantém os dados sem energia), mas ordens de grandeza mais lenta que a RAM para escrita aleatória — relevante para decisões de persistência local (banco de dados local, cache de imagens). A tecnologia de controle de acesso a essa memória evoluiu por gerações:

| Tecnologia | Onde aparece | Observação |
|---|---|---|
| eMMC | Aparelhos de entrada mais antigos/atuais de baixíssimo custo | Mais lenta, interface compartilhada de leitura/escrita |
| UFS 2.x | Aparelhos de entrada e médio porte atuais | Leitura e escrita simultâneas, ganho relevante sobre eMMC |
| UFS 3.x/4.x | Aparelhos topo de linha | Velocidades comparáveis a SSDs de notebook de poucos anos atrás |

### Modem e conectividade

O modem (celular 4G/5G, Wi-Fi, Bluetooth, NFC) frequentemente está integrado ao próprio SoC nos smartphones atuais. A geração de rede celular disponível (Aula 11 aprofunda o efeito disso na aplicação) e o padrão Wi-Fi suportado (Wi-Fi 5/6/6E/7) variam por faixa de preço do aparelho, e não apenas por ano de lançamento — um aparelho de entrada lançado em 2026 pode não ter 5G, enquanto um topo de linha de dois anos antes já tinha.

### NPU (Neural Processing Unit)

> **Definição — NPU (Neural Processing Unit)**: bloco de hardware dedicado dentro do SoC, especializado em executar operações de multiplicação de matrizes típicas de redes neurais com muito mais eficiência energética do que a CPU ou a GPU fariam a mesma tarefa — usado para recursos como desfoque de fundo em câmera, reconhecimento facial, tradução e sugestões de teclado, e cada vez mais para execução de modelos de IA diretamente no aparelho (*on-device AI*), sem depender de um servidor remoto.

### Síntese: categorias de hardware e principais tecnologias de mercado

| Categoria | Função | Principais tecnologias/fabricantes |
|---|---|---|
| SoC | Integra os demais componentes num único chip | Snapdragon (Qualcomm), Dimensity (MediaTek), Exynos (Samsung), Tensor (Google) |
| CPU | Executa lógica de propósito geral | Núcleos ARM heterogêneos (DynamIQ/big.LITTLE), ARMv8/v9 |
| GPU | Renderiza gráficos e interface | Adreno (Qualcomm), Mali/Immortalis (ARM), PowerVR (Imagination) |
| RAM | Memória de trabalho volátil | LPDDR4X, LPDDR5/5X |
| Armazenamento | Persistência não volátil | eMMC, UFS 2.x/3.x/4.x |
| NPU | Aceleração de IA on-device | Blocos dedicados integrados ao SoC (nome varia por fabricante) |
| Modem/rede | Conectividade celular e sem fio | 4G/5G, Wi-Fi 5/6/6E/7, Bluetooth, NFC |

### Sensores

Sensores comuns, o princípio físico por trás de cada um, e seu efeito em projeto:

| Sensor | Princípio de funcionamento | Uso típico | Implicação de projeto |
|---|---|---|---|
| Acelerômetro | MEMS (*Micro-Electro-Mechanical Systems*) capacitivo: uma massa microscópica suspensa se desloca sob aceleração, e esse deslocamento altera uma capacitância medida eletricamente | Detecção de orientação, contagem de passos | Rotação de tela, jogos |
| Giroscópio | MEMS de estrutura vibrante: mede a taxa de rotação a partir da deflexão de Coriolis sobre uma massa vibrando em ressonância | Realidade aumentada, estabilização | Maior precisão de movimento, maior consumo de energia |
| GPS/GNSS | Triangulação por tempo de chegada de sinais de rádio emitidos por constelações de satélites (GPS americano, GLONASS russo, Galileo europeu, BeiDou chinês); receptores multi-constelação combinam vários sistemas para maior precisão e aquisição mais rápida | Localização | Alto consumo de bateria; requer permissão em tempo de execução |
| Proximidade | Emissor/receptor infravermelho: mede a luz infravermelha refletida por um objeto próximo (ex.: o rosto do usuário durante uma ligação) | Apagar tela durante ligação | Evita toques acidentais |
| Luz ambiente | Fotodiodo que converte intensidade de luz incidente em corrente elétrica | Brilho automático | Afeta legibilidade da interface — tema claro/escuro |
| Magnetômetro (bússola) | Efeito Hall ou magnetorresistência: mede a intensidade e direção do campo magnético terrestre nos três eixos | Orientação em mapas, bússola | Precisa de calibração periódica; sofre interferência de metais próximos |
| Barômetro | Célula capacitiva ou piezorresistiva sensível à pressão atmosférica | Altitude relativa, melhora do tempo de aquisição de GPS em elevação | Uso mais raro em apps comuns, relevante em apps de saúde/esporte |
| Impressão digital | Capacitivo (mede a diferença de capacitância entre cristas e vales da digital), óptico (foto da digital sob a tela) ou ultrassônico (mapa 3D da digital via ondas sonoras, mais resistente a dedos molhados/sujos) | Biometria | Autenticação sem senha, mas exige tratamento de fallback |
| Câmera de rosto (Face ID/reconhecimento facial) | Câmera 2D simples (menos segura) ou sistema com projeção de pontos infravermelhos para mapa de profundidade 3D (mais seguro, mais caro) | Biometria | Mesma exigência de fallback; variação grande de segurança entre implementações |

**O que se considera "melhor" no mercado, por categoria, muda a cada geração de aparelho** — não é um ranking fixo a memorizar, e sim um critério a pesquisar no momento do projeto. Como referência de raciocínio: sensores inerciais (acelerômetro/giroscópio) de fabricantes como Bosch Sensortec e STMicroelectronics são amplamente considerados de alta precisão e baixo consumo; em biometria, o sensor ultrassônico de impressão digital (usado por exemplo em linhas Snapdragon com o Qualcomm 3D Sonic) é tido como mais robusto que o óptico por funcionar com o dedo molhado; em GNSS, chips multi-constelação e multi-banda (que recebem sinal em mais de uma frequência do mesmo satélite) reduzem o erro de localização em ambientes urbanos com prédios altos (efeito *multipath*).

Sensores não são apenas "fontes de dados": cada um tem um custo energético e um custo de latência que deve ser considerado. Ler o GPS continuamente para uma tela de mapa é uma decisão de arquitetura, não um detalhe de implementação — e a Aula 2 volta a este ponto ao tratar de permissões em tempo de execução.

## 3. Energia como restrição de arquitetura

A bateria é o recurso mais escasso do smartphone. Diferente de CPU e memória, ela não pode ser "alocada sob demanda" — uma vez gasta, o aparelho desliga.

### A bateria em si

> **Definição — Bateria de íons de lítio (Li-ion) / polímero de lítio (Li-Po)**: tecnologia química de armazenamento de energia recarregável dominante em smartphones, escolhida pela alta densidade de energia por volume/peso — a Li-Po (mais flexível fisicamente, permite formatos irregulares que aproveitam melhor o espaço interno do aparelho) é hoje a variante mais comum em smartphones modernos.

Capacidade medida em **mAh** (miliampère-hora) — tipicamente entre 4.000 e 6.000 mAh em smartphones de 2024–2026, embora o número isolado diga pouco sobre autonomia real: um SoC mais eficiente com bateria menor pode durar mais que um SoC ineficiente com bateria maior. Duas propriedades da química de lítio importam para quem projeta:

- **Degradação por ciclo**: a bateria perde capacidade de armazenamento a cada ciclo completo de carga/descarga — é por isso que otimizar o consumo do próprio aplicativo (menos wake locks, menos GPS desnecessário) tem efeito cumulativo na vida útil da bateria do usuário, não apenas na autonomia do dia.
- **Carregamento rápido (fast charging)**: padrões como Qualcomm Quick Charge, USB Power Delivery (USB-PD) e implementações proprietárias de fabricantes (ex.: Samsung Super Fast Charging, Xiaomi HyperCharge) entregam mais watts de potência ao aparelho, reduzindo o tempo de carga à custa de mais geração de calor — o que reconecta com a restrição térmica da §5.

### Como o sistema operacional gerencia energia

O Android trata o consumo de energia como uma preocupação de primeira classe do sistema operacional, e não do aplicativo isoladamente:

- **Doze mode e App Standby**: a partir do Android 6.0, o sistema agrupa e atrasa tarefas em segundo plano de aplicativos ociosos para reduzir o consumo de bateria coletivo do aparelho. O Doze mode entra em vigor quando o aparelho fica parado e sem uso por um período (ex.: durante a noite), suspendendo acesso à rede e adiando alarmes e sincronizações para janelas de manutenção periódicas.
- **Restrições de execução em segundo plano**: desde o Android 8.0, aplicativos em segundo plano têm limites severos para iniciar serviços e localização contínua, forçando o uso de mecanismos como `WorkManager` para tarefas adiáveis.
- **Grupos de standby de app (*App Standby Buckets*)**: desde o Android 9, cada aplicativo é classificado pelo sistema em um "balde" (ativo, em uso frequente, em uso raro, restrito) com base no padrão de uso real daquele usuário específico — um app raramente aberto recebe menos janelas de execução em segundo plano do que um usado todos os dias, uma adaptação por comportamento, não apenas por regra fixa.
- **Otimização de bateria por fabricante**: fabricantes como Xiaomi, Samsung, Huawei e outros aplicam camadas próprias de gestão de energia além do Android puro (AOSP) — um app que funciona perfeitamente no emulador pode ser "morto" agressivamente em segundo plano num aparelho real de certas marcas, independentemente de o código seguir todas as recomendações do Android puro.

Essa é uma das razões pelas quais **testar exclusivamente em emulador é insuficiente**: o comportamento de gestão de energia de fabricantes específicos só aparece em aparelho físico. Um recurso útil para diagnosticar consumo em desenvolvimento é o **Battery Historian**, ferramenta do próprio Google que analisa o log de bateria do aparelho e aponta quais componentes (rede, GPS, wake locks) mais consumiram energia num intervalo de uso.

## 4. Memória e comportamento sob pressão

O Android não permite que um aplicativo simplesmente "use toda a memória que precisar". Cada processo de aplicativo roda em sua própria instância da máquina virtual **ART** (*Android Runtime*, sucessora da antiga Dalvik), com um limite de heap definido pelo sistema por classe de aparelho — tipicamente entre 192 MB e 512 MB por app em condições normais (consultável em tempo de execução via `ActivityManager.getMemoryClass()`), podendo ser ampliado com a flag `android:largeHeap="true"` no manifesto para casos excepcionais, embora isso não seja uma solução recomendada para uso indiscriminado, apenas um alívio pontual.

### O mecanismo de encerramento por pressão de memória

Quando a memória do sistema fica escassa, dois mecanismos atuam em conjunto:

- **Low Memory Killer / LMKD** (*Low Memory Killer Daemon*, evolução em espaço de usuário do antigo mecanismo em kernel): monitora continuamente os níveis de memória livre do sistema e, ao cruzar limiares configurados, seleciona processos para encerrar.
- **`ActivityManager`**, no nível de sistema Android: mantém uma classificação de prioridade dos processos em segundo plano (processos vazios > em cache > serviços > visíveis > em primeiro plano), e o LMKD encerra primeiro os de menor prioridade — o processo do seu app em segundo plano é, do ponto de vista do sistema, um dos primeiros candidatos a ser sacrificado para liberar espaço para o app que o usuário está usando agora.

> **Definição — `zRAM`**: área de memória comprimida, mantida na própria RAM, usada pelo Android como uma espécie de memória de troca (*swap*) rápida — páginas de memória pouco usadas são comprimidas e mantidas em `zRAM` em vez de descartadas imediatamente, adiando (mas não eliminando) a necessidade de encerrar processos. Não deve ser confundida com um SSD de swap de computador: é mais rápida, mas ainda tem um custo de CPU para compressão/descompressão.

Consequências de projeto:

- Um aplicativo pode ser encerrado enquanto está em segundo plano e precisa **restaurar seu estado** quando o usuário volta a ele — não pode presumir que seu processo continuará vivo indefinidamente (retomado em profundidade, com o comando `adb shell am kill` para simular esse cenário, na Aula 2).
- Listas longas de imagens exigem estratégias de reciclagem de visualização (`RecyclerView`/`LazyColumn` no Android nativo; `ListView.builder` no Flutter; `FlatList` no React Native) em vez de renderizar tudo de uma vez.
- Vazamentos de memória (referências a `Activity` ou `Context` mantidas por objetos de vida longa, como um `Listener` estático nunca removido) são um problema mais grave em mobile do que em backend, porque o orçamento total de memória é pequeno, não elástico, e o vazamento se acumula silenciosamente ao longo de uma sessão de uso prolongada, sem o "respiro" de reinicializações periódicas que um servidor costuma ter.
- Imagens em alta resolução, carregadas sem redimensionamento para o tamanho real exibido em tela, são a causa mais comum e mais facilmente evitável de pressão de memória em apps com conteúdo visual — bibliotecas de carregamento de imagem (`Glide`/`Coil` no Android nativo, `cached_network_image` no Flutter, `expo-image`/`FastImage` no React Native) já resolvem redimensionamento e cache por padrão, e reinventar esse carregamento manualmente é uma fonte comum de bugs de memória em projetos de disciplina.

> **Nota de terminologia**: `RecyclerView` é a API de lista reciclada do sistema de Views do Android nativo. Este componente adota o Jetpack Compose como referência para os trechos ilustrativos de Android nativo (ver Aula 3) — o equivalente em Compose é `LazyColumn`. Os três (`LazyColumn`, `ListView.builder` do Flutter, `FlatList` do React Native) resolvem o mesmo problema: nunca manter em memória mais itens renderizados do que os visíveis na tela.

## 5. Restrição térmica

Smartphones não têm ventoinha. Quando a CPU/GPU trabalha intensamente por tempo prolongado (renderização pesada, mineração, jogos 3D, GPS contínuo com tela ligada), o aparelho esquenta e o sistema operacional reduz a frequência do processador (*thermal throttling*) para proteger o hardware — o app fica mais lento sem que haja nenhum "bug" no código. Isso é relevante para decisões como: com que frequência recalcular um layout complexo, ou se uma tarefa de processamento de imagem deve rodar no dispositivo ou ser delegada a um servidor.

## 6. Panorama do Android e fragmentação de aparelhos no Brasil

O Android é o sistema operacional móvel dominante no Brasil, presente em mais de 80% dos smartphones em uso segundo o [StatCounter GlobalStats — Mobile Operating System Market Share Brazil](https://gs.statcounter.com/os-market-share/mobile/brazil) (consultado em 2026). Como o número muda a cada semestre, **revalide-o na fonte antes de cada oferta da disciplina** em vez de citar o valor fixo aqui. Isso o torna a plataforma de referência natural para este componente. Mas "Android" não é uma plataforma homogênea:

- **Fragmentação de versão**: o painel de distribuição de versões do Android Studio (Ferramentas > Assistente do SDK > painel de distribuição) mostra a fatia de mercado de cada versão em uso e se atualiza automaticamente a cada release do próprio Android Studio — prefira consultá-lo a fixar um número de versão neste texto, que fica desatualizado a cada ano. Em qualquer momento, é comum haver no Brasil um intervalo de 4 a 5 versões majoritárias em uso simultâneo, cada uma com APIs, permissões e comportamentos de segundo plano diferentes.
- **Fragmentação de fabricante**: Samsung (One UI), Xiaomi (MIUI/HyperOS), Motorola e outros aplicam customizações sobre o Android puro (AOSP), incluindo políticas próprias de gestão de bateria, que afetam diretamente o comportamento de apps em segundo plano.
- **Fragmentação de hardware**: de aparelhos de entrada com 2–3 GB de RAM e telas de baixa densidade a aparelhos topo de linha com 12 GB de RAM e telas de altíssima densidade — o mesmo aplicativo precisa se comportar aceitavelmente em todo esse espectro.

> **Consequência prática para este componente**: toda decisão de interface e de arquitetura tomada nas próximas 19 aulas deve ser verificada mentalmente contra a pergunta: *"isso ainda funciona bem no aparelho de entrada mais comum do meu usuário, não apenas no meu aparelho de desenvolvimento?"*

### Estatísticas de mercado (verificar e atualizar a cada semestre)

Os números abaixo servem para dar escala ao argumento desta aula — não devem ser citados de cor em avaliação sem antes conferir a fonte, exatamente pelo motivo já apontado: eles mudam.

| Estatística | Onde consultar |
|---|---|
| Participação de mercado do Android por país/globalmente | [StatCounter GlobalStats — Mobile OS Market Share](https://gs.statcounter.com/os-market-share/mobile/worldwide) |
| Distribuição de versões Android em uso | Painel de distribuição no próprio Android Studio (SDK Manager) |
| Número de aplicativos publicados na Google Play | [Google Play Console — dados públicos de mercado](https://play.google.com/console/about/) e relatórios de terceiros como [Statista — Google Play Store](https://www.statista.com/statistics/266210/number-of-available-applications-in-the-google-play-store/) |
| Distribuição de tamanho de tela e densidade em uso real | Documentação oficial: [Distribution dashboard](https://developer.android.com/about/dashboards) |
| Fabricantes líderes de smartphones no Brasil | [Canalys](https://www.canalys.com/) e [IDC Brasil](https://www.idc.com/br) publicam relatórios trimestrais de participação de mercado |

### Curiosidades históricas

- O primeiro aparelho Android comercialmente lançado foi o **HTC Dream** (também vendido como T-Mobile G1), em setembro de 2008 — menos de um ano após o lançamento do primeiro iPhone.
- O Android foi originalmente desenvolvido pela **Android Inc.**, comprada pelo Google em 2005, dois anos antes do lançamento da primeira versão pública do sistema.
- Até a versão 9 (Pie, 2018), as versões do Android eram nomeadas publicamente com sobremesas em ordem alfabética (Cupcake, Donut, Eclair, Froyo, Gingerbread... Oreo, Pie) — prática interna à Google que persiste até hoje em nomes de código, mesmo sem o anúncio público de sobremesa desde a versão 10.
- O Android é construído sobre o **kernel Linux**, e o projeto de código aberto que o mantém — o **AOSP** (*Android Open Source Project*) — é a base que qualquer fabricante pode customizar para criar sua própria variante (One UI, MIUI/HyperOS, e outras), o que é justamente a origem da fragmentação de fabricante discutida acima.
- O nome de código de cada versão principal do Android também corresponde a um número de API level, usado em projeto para declarar `minSdk`/`targetSdk` — a documentação oficial mantém a [tabela de correspondência entre versão, nome e API level](https://developer.android.com/tools/releases/platforms).

## 7. Exemplo real: por que um app "trava" só em alguns aparelhos

Cenário comum relatado por equipes de desenvolvimento brasileiras: um aplicativo de delivery funciona perfeitamente no aparelho do desenvolvedor (um smartphone de ponta, 8 GB de RAM, Android puro) mas é relatado como "trava e fecha sozinho" por usuários com aparelhos de entrada de uma marca com gestão agressiva de bateria. A causa raiz típica: o app mantém uma conexão de rede em segundo plano para atualizar o status do pedido, mas o sistema opera de forma tão agressiva na gestão de energia que mata o processo antes de o serviço terminar. A solução não é "otimizar o código" no sentido tradicional — é **redesenhar a arquitetura de atualização de status** para usar notificações por push (que acordam o app sob demanda) em vez de manter um processo ativo continuamente.

Esse exemplo ilustra o argumento central da unidade: decisões que parecem de implementação (como manter uma conexão viva) são, na verdade, decisões de arquitetura condicionadas pelo hardware e pelo sistema operacional do aparelho do usuário — não do desenvolvedor.

## 8. Um primeiro contato com o projeto Android (prática da aula)

Não é objetivo desta aula ensinar a programar — isso vem nas unidades III e IV. O objetivo é **executar e observar** um projeto padrão para reconhecer, na prática, os elementos discutidos:

```bash
# Verificar os dispositivos/emuladores disponíveis
adb devices

# Instalar e rodar o projeto padrão criado pelo Android Studio
# (Novo Projeto > Empty Activity)
```

Ao rodar o projeto padrão em um emulador configurado com pouca RAM (por exemplo, um perfil "Pixel 3a" com 2 GB) e depois em um perfil de ponta, observar:

- Tempo de inicialização (*cold start*) em cada perfil.
- Uso de memória reportado pelo *Android Studio Profiler* (aba **Profiler**).
- Comportamento ao pressionar o botão **Home** e voltar ao app (o processo permanece ativo? o estado da tela é preservado?).

## Síntese da aula

| Restrição | Efeito sobre o projeto |
|---|---|
| CPU/GPU heterogênea e limitada | Evitar processamento desnecessário na thread principal |
| Energia finita | Preferir push a polling; respeitar limites de segundo plano |
| Memória não elástica | Processos podem ser encerrados; reciclar listas longas |
| Ausência de ventoinha (térmica) | Evitar cargas de CPU/GPU sustentadas sem necessidade |
| Fragmentação de aparelhos | Testar em múltiplos perfis, não apenas no aparelho do desenvolvedor |
| Rede instável/ausente | Projetar para conectividade intermitente desde o início (aprofundado na Aula 11) |

## Leitura recomendada para esta semana

- BASS; CLEMENTS; KAZMAN. *Software Architecture in Practice*, 4. ed., capítulo introdutório sobre atributos de qualidade — para relacionar restrição de hardware a atributo de qualidade de arquitetura.
- Documentação oficial: [Visão geral de gerenciamento de energia no Android](https://developer.android.com/topic/performance/power).

## Atividade da aula

**Avaliação diagnóstica** (individual, sem consulta prévia): questionário curto sobre experiência anterior com programação orientada a objetos, desenvolvimento web e uso de emulador/aparelho Android, usado para calibrar o ritmo das próximas aulas.

**Execução de projeto inicial em emulador Android**: criar um projeto "Empty Activity" no Android Studio, executá-lo em dois perfis de emulador com RAM distinta, e registrar em uma folha de observação: tempo de inicialização, uso de memória inicial e comportamento ao alternar para segundo plano. Use o modelo pronto em [`recursos/aula01-folha-observacao.md`](../recursos/aula01-folha-observacao.md) para padronizar a coleta entre equipes.
