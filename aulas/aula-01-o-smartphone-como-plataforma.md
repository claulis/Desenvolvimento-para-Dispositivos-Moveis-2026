# O smartphone como plataforma de projeto

## Breve historico

https://en.wikipedia.org/wiki/Motorola_TAC
https://en.wikipedia.org/wiki/Nokia
https://en.wikipedia.org/wiki/BlackBerry
https://en.wikipedia.org/wiki/IPhone


## Comunicações: O princípio comum

Todo rádio no celular faz a mesma coisa: pega bits, monta uma **onda eletromagnética** modulada, e do outro lado desfaz. As diferenças entre as tecnologias vêm de quatro escolhas:

| Escolha | Trade-off |
| :-- | :-- |
| **Frequência** | Baixa (700 MHz) atravessa parede e vai longe; alta (28 GHz) carrega muito mais dado e não passa pela sua mão |
| **Largura de banda** | Mais MHz = mais bits/s
| **Modulação** | QPSK aguenta ruído; 1024-QAM empacota 10 bits por símbolo mas exige sinal limpo |
| **Múltiplo acesso** | Como vários aparelhos dividem o mesmo ar sem se atropelar |

Praticamente tudo hoje usa **OFDM** — o canal é fatiado em centenas de subportadoras estreitas e paralelas. Isso resolve o problema do multipercurso (o sinal chega refletido, com atrasos diferentes) e permite atribuir pedacinhos do espectro a aparelhos diferentes.

E quase tudo usa **MIMO**: várias antenas transmitindo fluxos distintos ao mesmo tempo, na mesma frequência. A matemática separa os fluxos porque cada um percorreu um caminho físico diferente. É por isso que o número de antenas virou spec de marketing.

> **OFDM** *(Orthogonal Frequency-Division Multiplexing)*
> Fatia um canal largo em centenas de subportadoras estreitas e paralelas, ortogonais entre si (não interferem apesar de sobrepostas). Cada uma carrega um fluxo lento de dados. Como cada símbolo dura mais tempo, o eco do multipercurso não o corrompe — e subportadoras degradadas podem ser desligadas isoladamente.

<img width="540" height="325" alt="image" src="https://github.com/user-attachments/assets/44fa34d2-b5b4-41ba-ba43-4a4ed793e912" />


> **MIMO** *(Multiple-Input Multiple-Output)*
> Várias antenas transmitindo fluxos diferentes ao mesmo tempo, na mesma frequência. Como cada fluxo percorre um caminho físico distinto (reflexões diferentes), o receptor consegue separá-los matematicamente. Multiplica a vazão sem gastar mais espectro.

<img width="474" height="326" alt="image" src="https://github.com/user-attachments/assets/83946c6e-52f7-47a2-8acd-f48693835176" />


**A diferença essencial:** OFDM organiza o sinal no **domínio da frequência**; MIMO explora o **domínio do espaço**. São ortogonais entre si — por isso todo padrão moderno usa os dois juntos.

### Rádio celular (WWAN) — quilômetros

O rádio mais complexo do aparelho. Um smartphone moderno fala **4G LTE e 5G NR** simultaneamente, em dezenas de bandas de frequência.

**Como funciona a conexão.** O modem varre as frequências, encontra sinais de sincronização de torres próximas, escolhe a melhor, e faz um *random access* — manda um preâmbulo aleatório num canal compartilhado e espera resposta. A rede então autentica o aparelho contra o **SIM/eSIM** (um chip criptográfico que guarda uma chave secreta compartilhada com a operadora) e aloca recursos.

**Bandas.** Três faixas com propósitos distintos:

- **Sub-1 GHz** (700, 850 MHz): cobertura rural, penetra construção, poucas centenas de Mbps
- **Sub-6 GHz** (1,8–3,5 GHz): o cavalo de batalha, equilíbrio entre alcance e capacidade
- **mmWave** (24–40 GHz): gigabits, alcance de uma quadra, bloqueado por vidro e pelo próprio corpo — no Brasil, quase inexistente na prática

**5G-Advanced** é a fase atual: agregação de portadoras mais agressiva, MIMO massivo, economia de energia na rede e integração com IA para gerenciamento de rádio.

**NTN — satélite direto ao celular.** A novidade dos últimos ciclos. Constelações em órbita baixa (Starlink Direct-to-Cell, AST SpaceMobile) usam bandas celulares comuns, e o satélite se comporta como uma torre voadora. O desafio de engenharia é brutal: o satélite passa a 27.000 km/h, o que gera um Doppler enorme e um atraso variável — o padrão precisou de compensação explícita para isso. Hoje entrega SMS e mensagens; dados ainda são marginais.

<img width="474" height="272" alt="image" src="https://github.com/user-attachments/assets/99ed80f6-ddad-4baf-a31d-9b1dec653897" />


### Wi-Fi (WLAN) — dezenas de metros

**Wi-Fi 6/6E** (802.11ax) e **Wi-Fi 7** (802.11be) são o que está nos aparelhos hoje.

A diferença conceitual em relação ao celular é o **acesso ao meio**: não há uma torre alocando recursos. O Wi-Fi usa **CSMA/CA** — cada aparelho escuta o canal, e se estiver ocupado espera um tempo aleatório antes de tentar. É democrático e ineficiente sob carga; é por isso que sua conexão degrada num aeroporto lotado.

O que o Wi-Fi 6/7 mudou nisso:

- **OFDMA** — o roteador passa a subdividir o canal e servir vários clientes num mesmo instante, em vez de um por vez. Importado direto do LTE.
- **MLO (Multi-Link Operation)**, exclusivo do Wi-Fi 7 — o aparelho mantém conexões simultâneas em 2,4, 5 e 6 GHz e alterna ou agrega. Reduz drasticamente a variação de latência.
- **6 GHz** (Wi-Fi 6E/7) — faixa nova, limpa, canais de 320 MHz. No Brasil está liberada.
- **1024-QAM / 4096-QAM** — mais bits por símbolo, só útil com sinal excelente.

### Bluetooth — metros

Dois protocolos diferentes com o mesmo nome:

**Bluetooth Classic (BR/EDR)** — canal contínuo, usado para áudio de fone e headset. Opera em 2,4 GHz com **frequency hopping**: troca de canal 1600 vezes por segundo dentro de 79 canais, o que o torna resiliente a interferência e difícil de escutar por acidente.

**Bluetooth Low Energy (BLE)** — protocolo distinto, projetado para dormir. Um sensor BLE passa 99,9% do tempo desligado, acorda, transmite alguns bytes em um dos 40 canais, e volta a dormir. É o que faz uma pulseira durar uma semana com pilha de moeda.


### NFC — centímetros

Categoria à parte: **não é rádio de propagação, é acoplamento indutivo**. Em 13,56 MHz, a antena do celular e a do leitor formam, na prática, um transformador com núcleo de ar. Por isso o alcance é de ~4 cm e por isso um cartão passivo funciona sem bateria — ele colhe energia do campo do leitor.

No pagamento, o celular emula um cartão (**HCE**), e a transação é assinada por um elemento seguro — no Android, tipicamente o StrongBox / TEE. O número real do cartão nunca trafega: vai um **token** específico daquele aparelho.


### UWB — centímetros, mas a metros de distância

Ultra-Wideband (IEEE 802.15.4z) resolve um problema que nenhum dos anteriores resolve bem: **onde exatamente**.

Transmite pulsos extremamente curtos (nanossegundos) espalhados por uma banda larguíssima (6,5–8 GHz). Como o pulso é curto, dá para medir o **tempo de voo** com precisão altíssima — daí distância com erro de ~10 cm. Com três antenas, obtém-se também o **ângulo de chegada**, ou seja, direção.

Aplicações: chave digital de carro, achar o objeto perdido apontando o celular, transferência de arquivo mirando no aparelho do colega. Resistente a ataque de repetição justamente porque a física do tempo de voo não pode ser falsificada por um repetidor.


### GNSS — recepção pura

Não é comunicação bidirecional: o celular **só escuta**. GPS (EUA), Galileo (Europa), GLONASS (Rússia) e BeiDou (China) — os aparelhos atuais usam todos ao mesmo tempo.

Cada satélite transmite continuamente a hora do seu relógio atômico e sua posição orbital. O receptor mede a diferença entre a hora recebida e a hora local em quatro satélites e resolve um sistema de quatro equações — três para posição, uma para corrigir o próprio relógio, que é barato e impreciso. Isso é **trilateração**.

Dois detalhes práticos:

- **A-GPS** — os dados orbitais chegam pela rede celular em vez de serem lidos dos satélites, que levariam ~30 s. Sem isso, o primeiro fix seria dolorosamente lento.
- **Dupla frequência (L1 + L5)** — nos aparelhos melhores, corrige o atraso atmosférico e reduz o erro em cidade com prédios altos de ~10 m para ~1 m.

O Android combina isso com Wi-Fi, torres celulares e sensores inerciais — o que o app pede como "localização" é uma fusão, não uma leitura de GPS.


### Resumo comparativo

| Tecnologia | Frequência | Alcance | Vazão típica | Consumo | Serve para |
| :-- | :-- | :-- | :-- | :-- | :-- |
| **5G NR** | 0,6–40 GHz | km | 50 Mbps–1 Gbps | Alto | Internet em movimento |
| **Wi-Fi 7** | 2,4/5/6 GHz | ~30 m | 0,5–2 Gbps | Médio-alto | Internet fixa, alta banda |
| **BT Classic** | 2,4 GHz | ~10 m | ~2 Mbps | Médio | Áudio |
| **BLE** | 2,4 GHz | ~10 m | ~0,1 Mbps | Muito baixo | Sensores, wearables |
| **NFC** | 13,56 MHz | ~4 cm | ~0,4 Mbps | Baixo | Pagamento, identificação |
| **UWB** | 6,5–8 GHz | ~10 m | baixa | Baixo | Posição precisa |
| **GNSS** | 1,2/1,5 GHz | orbital | só recepção | Alto | Localização |

---

## SIM

<img width="500" height="305" alt="image" src="https://github.com/user-attachments/assets/6abd6076-8dd9-4bf9-bf5f-905a701850f5" />


**Subscriber Identity Module.** Apesar da aparência, não é um cartão de memória — é um **computador completo**: microcontrolador, memória e um sistema operacional próprio (Java Card, na maioria). Formalmente chama-se **UICC**, e o "SIM" é apenas uma das aplicações que rodam dentro dele.

<img width="250" height="107" alt="image" src="https://github.com/user-attachments/assets/4f0e5e12-1d3d-4fde-b327-2915b32bf787" />


**O que ele guarda:**

| Item | Papel |
| :-- | :-- |
| **IMSI** | Identidade permanente do assinante na rede |
| **Ki** | Chave secreta de 128 bits, compartilhada só com a operadora |
| **ICCID** | Número de série do próprio chip |
| Agenda, SMS, dados de rede | Legado, hoje quase sem uso |

**Como autentica.**:

1. A rede envia um número aleatório (`RAND`) para o celular
2. O celular repassa ao SIM — que apenas encaminha, não sabe o segredo
3. O SIM calcula `RES = f(RAND, Ki)` internamente, com o algoritmo MILENAGE
4. Devolve só o `RES`
5. A rede faz a mesma conta do seu lado e compara

Se bate, o assinante é legítimo. Do mesmo cálculo saem as **chaves de sessão** que cifram a chamada e os dados no ar. Nem o sistema operacional do celular, nem um app, nem um malware conseguem ler o Ki — para extraí-lo seria preciso atacar fisicamente o silício.

**Formatos** — sempre o mesmo circuito, só o plástico ao redor encolheu:

`Full-size (1FF)` → `Mini / 2FF` → `Micro / 3FF` → `Nano / 4FF` → `eSIM / MFF2`

## eSIM

**embedded SIM**, tecnicamente **eUICC**. É o mesmo chip, **soldado à placa** do aparelho — mas a mudança relevante não é física, é **de provisionamento**.

O SIM tradicional sai da fábrica com um único perfil gravado, imutável. O eUICC sai **vazio e reprogramável**: consegue baixar, armazenar e alternar entre vários perfis de operadora ao longo da vida do aparelho.

**Como o perfil chega lá** (padrão GSMA **RSP** — Remote SIM Provisioning):

1. Você lê um QR code, que contém apenas um endereço de servidor + um código de ativação
2. O aparelho contata o **SM-DP+** da operadora (*Subscription Manager – Data Preparation*)
3. O servidor prepara um perfil — IMSI, Ki, regras, nome da rede — e o envia **cifrado ponta a ponta**
4. Só o eUICC, com sua chave de fábrica, consegue decifrar e instalar
5. O perfil é ativado; o Ki é gravado internamente e, a partir daí, funciona exatamente como um SIM físico

O download é seguro mesmo passando por Wi-Fi público: o canal é protegido por certificados de uma cadeia de confiança da GSMA. Uma operadora não consegue instalar perfil no chip sem autorização, e o aparelho não consegue extrair o perfil para clonar em outro.

**iSIM** é o passo seguinte: o mesmo eUICC integrado dentro do próprio SoC, sem chip dedicado. Já existe em wearables e IoT.


### Aspectos de segurança

**Privacidade — SUCI no 5G.** Em 2G/3G/4G, o IMSI trafegava em claro no primeiro contato com a torre, o que permitia os *IMSI catchers* (falsas antenas que mapeiam quem está por perto). O 5G corrigiu: o SIM cifra a identidade permanente com a **chave pública da operadora** antes de transmitir. O que vai no ar é o **SUCI**, um identificador diferente a cada tentativa. Só a operadora decifra.

**SIM swap.** Toda a segurança criptográfica descrita acima pode ser contornada socialmente: alguém convence o atendimento da operadora a emitir um novo chip com o seu número. O elo fraco não é o silício, é o processo humano. Por isso **SMS é um segundo fator fraco** — vale a pena mencionar quando os alunos forem projetar autenticação nos aplicativos deles.

---
## Arquitetura de hardware do smartphone

Um smartphone típico é composto por várias categorias de componentes, cada uma com tecnologias concorrentes no mercado e com implicações de projeto próprias. Entender *o que* existe dentro do aparelho — não em profundidade de engenharia eletrônica, mas o suficiente para raciocinar sobre desempenho e consumo — é o que torna concreto o argumento

### SoC (System on Chip)

> **Definição — SoC (System on Chip)**: chip único que integra CPU, GPU, controlador de memória, modem de rádio (celular, Wi-Fi, Bluetooth), processador de sinal de imagem (ISP) e, em SoCs recentes, um acelerador dedicado de inteligência artificial (NPU), substituindo o conjunto de chips separados que um computador de mesa usa para as mesmas funções.

<img width="320" height="240" alt="image" src="https://github.com/user-attachments/assets/9a405538-945a-4b31-adda-6283bd4a7560" />


O SoC é a razão pela qual smartphones diferentes têm desempenho tão distinto mesmo rodando o mesmo sistema operacional — ele determina, de uma vez só, o teto de CPU, GPU e eficiência energética do aparelho. Os principais fabricantes de SoC para Android:

| Fabricante | Linha | Observação |
|---|---|---|
| Qualcomm | Snapdragon (8 Elite, 8, 7, 6, 4 séries) | Líder de mercado em volume; a série numérica (8 > 7 > 6 > 4) indica o segmento, do topo de linha à entrada |
| MediaTek | Dimensity | Forte em custo-benefício, hoje presente também em aparelhos topo de linha |
| Samsung | Exynos | Usado principalmente em aparelhos Galaxy, concorrendo internamente com versões Snapdragon do mesmo modelo em mercados diferentes |
| Google | Tensor | Desenvolvido com foco em recursos de IA on-device (linha Pixel), não necessariamente o mais rápido em benchmarks brutos |

Um dado técnico relevante para projeto: o **processo de fabricação** do SoC (medido em nanômetros — ex.: 4nm, 3nm) afeta diretamente eficiência energética e geração de calor. Processos mais finos permitem mais transistores no mesmo espaço físico, consumindo menos energia por operação — o que explica por que um SoC "mais moderno" pode ter desempenho comparável a um antigo consumindo bem menos bateria.

### CPU

<img width="250" height="250" alt="image" src="https://github.com/user-attachments/assets/f6bf7593-103c-4657-bd92-713c96aec1ca" />


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

A GPU renderiza a interface. No Android, a interface tradicional é desenhada por composição de camadas (*layers*) que a GPU combina; no Flutter, o próprio motor de renderização (Impeller) desenha diretamente na GPU, sem passar pelos widgets nativos do Android. Duas APIs gráficas de baixo nível dominam o acesso à GPU no Android: **OpenGL ES** (mais antiga, ainda amplamente suportada) e **Vulkan** (mais moderna, com controle mais direto sobre a GPU e menor sobrecarga da CPU para emitir comandos gráficos) — o Impeller do Flutter, por exemplo, usa Vulkan no Android quando disponível.

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

## Energia como restrição de arquitetura

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

## Memória e comportamento sob pressão

O Android não permite que um aplicativo simplesmente "use toda a memória que precisar". Cada processo de aplicativo roda em sua própria instância da máquina virtual **ART** (*Android Runtime*, sucessora da antiga Dalvik), com um limite de heap definido pelo sistema por classe de aparelho — tipicamente entre 192 MB e 512 MB por app em condições normais.

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

## Restrição térmica

Smartphones não têm ventoinha. Quando a CPU/GPU trabalha intensamente por tempo prolongado (renderização pesada, mineração, jogos 3D, GPS contínuo com tela ligada), o aparelho esquenta e o sistema operacional reduz a frequência do processador (*thermal throttling*) para proteger o hardware — o app fica mais lento sem que haja nenhum "bug" no código. Isso é relevante para decisões como: com que frequência recalcular um layout complexo, ou se uma tarefa de processamento de imagem deve rodar no dispositivo ou ser delegada a um servidor.

## Panorama do Android e fragmentação de aparelhos no Brasil

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












