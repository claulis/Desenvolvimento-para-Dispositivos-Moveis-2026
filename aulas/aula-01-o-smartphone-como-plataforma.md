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

Um smartphone típico é composto por:

- **SoC (System on Chip)**: integra CPU, GPU, controlador de memória, modem de rádio e processador de sinal de imagem em um único chip. É a razão pela qual smartphones diferentes têm desempenho tão distinto mesmo rodando o mesmo sistema operacional.
- **CPU**: normalmente de arquitetura ARM (não x86, como a maioria dos notebooks), com núcleos heterogêneos — alguns rápidos e famintos por energia, outros lentos e eficientes (arquitetura *big.LITTLE*). O sistema operacional decide dinamicamente em qual núcleo executar cada tarefa.
- **GPU**: renderiza a interface. No Android, a interface é desenhada por composição de camadas (*layers*) que a GPU combina; no Flutter, o próprio motor de renderização (Skia/Impeller) desenha diretamente na GPU, sem passar pelos widgets nativos do Android.
- **RAM**: tipicamente entre 3 GB e 12 GB em aparelhos de 2024–2026, mas compartilhada entre sistema operacional, aplicativos em segundo plano e o aplicativo em uso. Diferente de um servidor, o app não "pede" memória livremente: o sistema pode encerrar processos em segundo plano sem aviso para liberar RAM.
- **Armazenamento**: flash NAND, mais lento que a RAM em ordens de grandeza para escrita aleatória — relevante para decisões de persistência local (banco de dados local, cache de imagens).

### Sensores

Sensores comuns e seu efeito em projeto:

| Sensor | Uso típico | Implicação de projeto |
|---|---|---|
| Acelerômetro | Detecção de orientação, contagem de passos | Rotação de tela, jogos |
| Giroscópio | Realidade aumentada, estabilização | Maior precisão de movimento, maior consumo de energia |
| GPS/GNSS | Localização | Alto consumo de bateria; requer permissão em tempo de execução |
| Proximidade | Apagar tela durante ligação | Evita toques acidentais |
| Luz ambiente | Brilho automático | Afeta legibilidade da interface — tema claro/escuro |
| Impressão digital / câmera de rosto | Biometria | Autenticação sem senha, mas exige tratamento de fallback |

Sensores não são apenas "fontes de dados": cada um tem um custo energético e um custo de latência que deve ser considerado. Ler o GPS continuamente para uma tela de mapa é uma decisão de arquitetura, não um detalhe de implementação.

## 3. Energia como restrição de arquitetura

A bateria é o recurso mais escasso do smartphone. Diferente de CPU e memória, ela não pode ser "alocada sob demanda" — uma vez gasta, o aparelho desliga. Por isso, o Android trata o consumo de energia como uma preocupação de primeira classe do sistema operacional, e não do aplicativo isoladamente:

- **Doze mode e App Standby**: a partir do Android 6.0, o sistema agrupa e atrasa tarefas em segundo plano de aplicativos ociosos para reduzir o consumo de bateria coletivo do aparelho.
- **Restrições de execução em segundo plano**: desde o Android 8.0, aplicativos em segundo plano têm limites severos para iniciar serviços e localização contínua, forçando o uso de mecanismos como `WorkManager` para tarefas adiáveis.
- **Otimização de bateria por fabricante**: fabricantes como Xiaomi, Samsung e Huawei aplicam camadas próprias de gestão de energia além do Android puro — um app que funciona perfeitamente no emulador pode ser "morto" agressivamente em segundo plano num aparelho real de certas marcas.

Essa é uma das razões pelas quais **testar exclusivamente em emulador é insuficiente**: o comportamento de gestão de energia de fabricantes específicos só aparece em aparelho físico.

## 4. Memória e comportamento sob pressão

O Android não permite que um aplicativo simplesmente "use toda a memória que precisar". Quando a memória do sistema fica escassa, o *Low Memory Killer* do kernel Linux (e o `ActivityManager` no nível de sistema) encerra processos em segundo plano, começando pelos de menor prioridade. Consequências de projeto:

- Um aplicativo pode ser encerrado enquanto está em segundo plano e precisa **restaurar seu estado** quando o usuário volta a ele — não pode presumir que seu processo continuará vivo indefinidamente.
- Listas longas de imagens exigem estratégias de reciclagem de visualização (`RecyclerView` no Android nativo; `ListView.builder` no Flutter; `FlatList` no React Native) em vez de renderizar tudo de uma vez.
- Vazamentos de memória (referências a `Activity` ou `Context` mantidas por objetos de vida longa) são um problema mais grave em mobile do que em backend, porque o orçamento total de memória é pequeno e não elástico.

## 5. Restrição térmica

Smartphones não têm ventoinha. Quando a CPU/GPU trabalha intensamente por tempo prolongado (renderização pesada, mineração, jogos 3D, GPS contínuo com tela ligada), o aparelho esquenta e o sistema operacional reduz a frequência do processador (*thermal throttling*) para proteger o hardware — o app fica mais lento sem que haja nenhum "bug" no código. Isso é relevante para decisões como: com que frequência recalcular um layout complexo, ou se uma tarefa de processamento de imagem deve rodar no dispositivo ou ser delegada a um servidor.

## 6. Panorama do Android e fragmentação de aparelhos no Brasil

O Android é o sistema operacional móvel dominante no Brasil, presente em mais de 80% dos smartphones em uso, segundo levantamentos de mercado (StatCounter, 2024–2025). Isso o torna a plataforma de referência natural para este componente. Mas "Android" não é uma plataforma homogênea:

- **Fragmentação de versão**: no Brasil, é comum encontrar em uso simultâneo aparelhos rodando desde Android 9 até a versão mais recente — cada versão com APIs, permissões e comportamentos de segundo plano diferentes.
- **Fragmentação de fabricante**: Samsung (One UI), Xiaomi (MIUI/HyperOS), Motorola e outros aplicam customizações sobre o Android puro (AOSP), incluindo políticas próprias de gestão de bateria, que afetam diretamente o comportamento de apps em segundo plano.
- **Fragmentação de hardware**: de aparelhos de entrada com 2–3 GB de RAM e telas de baixa densidade a aparelhos topo de linha com 12 GB de RAM e telas de altíssima densidade — o mesmo aplicativo precisa se comportar aceitavelmente em todo esse espectro.

> **Consequência prática para este componente**: toda decisão de interface e de arquitetura tomada nas próximas 19 aulas deve ser verificada mentalmente contra a pergunta: *"isso ainda funciona bem no aparelho de entrada mais comum do meu usuário, não apenas no meu aparelho de desenvolvimento?"*

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

## Leitura recomendada para esta semana

- BASS; CLEMENTS; KAZMAN. *Software Architecture in Practice*, 4. ed., capítulo introdutório sobre atributos de qualidade — para relacionar restrição de hardware a atributo de qualidade de arquitetura.
- Documentação oficial: [Visão geral de gerenciamento de energia no Android](https://developer.android.com/topic/performance/power).

## Atividade da aula

**Avaliação diagnóstica** (individual, sem consulta prévia): questionário curto sobre experiência anterior com programação orientada a objetos, desenvolvimento web e uso de emulador/aparelho Android, usado para calibrar o ritmo das próximas aulas.

**Execução de projeto inicial em emulador Android**: criar um projeto "Empty Activity" no Android Studio, executá-lo em dois perfis de emulador com RAM distinta, e registrar em uma folha de observação: tempo de inicialização, uso de memória inicial e comportamento ao alternar para segundo plano.
