# Aula 11 — Flutter: modelo de execução e árvore de widgets

**Carga horária:** 4h
**Unidade:** III — Arquitetura de software em Flutter

## Objetivos da aula

- Explicar o modelo de compilação e renderização do Flutter e suas consequências para consistência visual.
- Compor interfaces a partir da árvore de widgets.
- Implementar responsividade com `LayoutBuilder` e `MediaQuery`.

## Organização da aula

Esta aula responde a três perguntas encadeadas: **como** o Flutter transforma código em pixels na tela (§1 e §2), **como** a interface é descrita e atualizada por meio de widgets (§3 e §4) e **como** essa descrição se adapta a telas de tamanhos diferentes (§5 e §6). Em cada seção, o conteúdo segue a sequência: problema, mecanismo e aplicação em código. A compreensão do mecanismo é o que permite, nas aulas seguintes, avaliar o custo de decisões de projeto, em especial o custo de renderização (Aula 22).

## 1. O que torna o Flutter diferente

> **Definição — Flutter**: framework de interface multiplataforma da Google, escrito em Dart, que renderiza sua própria interface pixel a pixel através de um motor gráfico próprio — **Impeller**, o motor padrão desde 2024–2025 (padrão no Android para dispositivos com suporte a Vulkan desde o Flutter 3.29, e padrão no iOS desde antes disso), sucedendo o antigo motor Skia, hoje em remoção — em vez de traduzir seus componentes para os widgets nativos do sistema operacional hospedeiro.

### Problema

Um aplicativo multiplataforma precisa funcionar em sistemas cujos componentes visuais diferem entre si. Existem duas estratégias possíveis. A primeira consiste em **traduzir** a descrição da interface para os componentes nativos de cada sistema (um botão do framework torna-se um `Button` do Android e um `UIButton` do iOS). A segunda consiste em **desenhar** a interface diretamente, sem utilizar componentes nativos. Cada estratégia produz consequências distintas sobre aparência, comportamento e desempenho.

### Mecanismo

O Flutter adota a segunda estratégia. Em vez de solicitar ao Android que crie um `Button`, o framework solicita ao sistema apenas uma superfície de desenho e, sobre ela, o motor gráfico (Impeller) pinta cada elemento da interface, quadro a quadro, com resultado visualmente equivalente ao dos componentes nativos. Trata-se da diferença arquitetural mais importante do Flutter em relação a abordagens como o React Native (Aula 16) ou o desenvolvimento Android nativo: **o Flutter não utiliza os componentes visuais do Android** (`Button`, `TextView` etc.).

As consequências são de duas naturezas:

- **Vantagem**: consistência visual entre plataformas (o mesmo resultado, pixel a pixel, em Android e iOS) e desempenho de renderização previsível, já que o framework não depende da árvore de views nativa do sistema. Como o desenho é controlado integralmente pelo Flutter, uma atualização do sistema operacional não altera a aparência do aplicativo.
- **Custo**: o Flutter precisa reimplementar comportamentos de plataforma que o sistema oferece automaticamente aos componentes nativos (por exemplo, o comportamento exato de rolagem e a seleção de texto). Para aderir ao Material Design (Aula 10), o framework disponibiliza o pacote `Material`, que traduz os tokens de cor, a tipografia e os componentes estudados anteriormente para widgets Flutter.

## 2. Compilação AOT (ahead-of-time) e JIT (just-in-time)

### Problema

Duas necessidades conflitantes orientam a execução de um aplicativo. Em **produção**, o código deve executar com o máximo desempenho, sem sobrecarga de interpretação. Em **desenvolvimento**, o ciclo "alterar o código, observar o resultado" deve ser o mais curto possível, pois o ajuste fino de interface exige dezenas de iterações. Um único modo de compilação dificilmente atende às duas necessidades.

### Mecanismo

O Dart oferece dois modos de execução, e o Flutter emprega cada um onde é mais vantajoso:

| Modo | Quando é usado | Como funciona | Consequência |
|---|---|---|---|
| **AOT** (*ahead-of-time*) | Build de produção | O código Dart é compilado previamente para código de máquina nativo, antes de o aplicativo chegar ao aparelho | Desempenho próximo ao nativo; qualquer mudança exige novo build e reinstalação |
| **JIT** (*just-in-time*) | Desenvolvimento | Uma máquina virtual Dart compila o código durante a execução e aceita injeção de código novo com o aplicativo em funcionamento | Viabiliza o **hot reload** |

O código Dart de produção, portanto, não é interpretado em tempo de execução, diferentemente do que ocorre com JavaScript em muitos contextos.

O **hot reload** decorre diretamente do modo JIT: o código alterado é enviado à máquina virtual em execução, os widgets afetados são reconstruídos e o **estado da aplicação é preservado**. Alterações de interface aparecem no aparelho em menos de um segundo, sem reiniciar o aplicativo nem retornar à tela em que o desenvolvedor se encontrava. Essa produtividade de iteração modifica a forma de depurar e refinar uma interface.

## 3. A árvore de widgets

> **Definição — Widget**: no Flutter, a unidade fundamental e universal de construção de interface — **tudo é widget**: um texto, um espaçamento, um alinhamento, uma animação, e até mesmo conceitos estruturais como tema e diretriz de acessibilidade são representados como widgets que envolvem (compõem) outros widgets.

### Problema

No Android nativo, a descrição de uma tela distribui-se por conceitos diferentes: a `View` visual, parâmetros de layout em arquivos XML, estilos, margens e alinhamentos configurados como atributos. Cada conceito possui regras próprias, o que amplia o número de elementos a aprender e dificulta a reutilização.

### Mecanismo

No Flutter, a interface é descrita exclusivamente por **composição de widgets**: um widget recebe outros widgets como filhos e define como eles são dispostos. Inclusive o espaçamento (`Padding`, `SizedBox`) e o alinhamento (`Align`, `Center`) são widgets. O resultado é uma estrutura hierárquica, a **árvore de widgets**, na qual cada nó envolve seus filhos. Um único conceito (compor widgets) substitui a multiplicidade de mecanismos do modelo nativo.

#### As três árvores internas

A afirmação "tudo é widget" descreve apenas a camada mais externa. Por trás dela, o Flutter mantém **três árvores** sincronizadas, fundamentais para a compreensão do custo de renderização tratado na Aula 22:

| Árvore | Natureza | Função |
|---|---|---|
| **Widgets** | Configuração imutável e descartável, recriada a cada chamada de `build()` | Descreve **o que** deve ser exibido |
| **Elements** | Instância persistente que conecta um widget à sua posição na hierarquia ao longo do tempo | Compara a configuração nova à anterior e decide o que precisa mudar |
| **RenderObjects** | Objetos que calculam o layout e realizam a pintura efetiva | Determina **onde e como** desenhar na tela |

A criação de um novo widget em `build()` **não** implica, por si só, trabalho dispendioso. O Flutter compara o novo widget ao anterior por meio da árvore de Elements e só propaga a alteração à árvore de RenderObjects quando algo efetivamente mudou. Esta é a distinção que sustenta a Aula 22: **reconstruir a configuração é barato; recalcular layout e pintura é o que custa**.

### Aplicação

```dart
class TelaProduto extends StatelessWidget {
  const TelaProduto({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalhe do produto')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Smartphone XYZ',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'R\$ 1.500,00',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () {},
              child: const Text('Comprar'),
            ),
          ],
        ),
      ),
    );
  }
}
```

Leitura do código, de fora para dentro: `Scaffold` fornece a estrutura da tela (barra superior e corpo); `Padding` afasta o conteúdo das bordas; `Column` empilha os filhos verticalmente; `Spacer` ocupa o espaço restante e empurra o botão para a parte inferior. Cada elemento é um widget e cada um envolve ou é envolvido por outro.

Observa-se que a malha de espaçamento (`EdgeInsets.all(16.0)`, `SizedBox(height: 8)`) e a escala tipográfica (`Theme.of(context).textTheme.headlineSmall`) discutidas na Aula 10 traduzem-se diretamente em código Flutter. O sistema de design não é reinventado por plataforma; é apenas expresso na sintaxe de cada uma.

## 4. Widgets com e sem estado

### Problema

Parte da interface é fixa: um título, um rótulo. Outra parte reage a eventos: um contador, um ícone de favorito que alterna entre preenchido e vazio. A estrutura precisa distinguir esses dois casos para que o framework reconstrua apenas o que pode mudar.

### Mecanismo

> **Definição — StatelessWidget**: widget cuja aparência depende exclusivamente dos parâmetros recebidos na construção, sem manter dados internos mutáveis — reconstruído inteiramente sempre que seus parâmetros mudam.

> **Definição — StatefulWidget**: widget associado a um objeto de estado (`State`) que pode ser alterado ao longo do tempo (por exemplo, em resposta a um toque), disparando a reconstrução do widget quando `setState()` é chamado.

O `StatefulWidget` separa duas responsabilidades em duas classes. O widget em si é imutável e descartável, como qualquer outro; o objeto `State` é **persistente**: sobrevive às reconstruções e guarda os dados mutáveis. Esse é o motivo de o estado não se perder quando o widget é recriado em `build()`.

O fluxo de uma atualização é o seguinte:

1. O usuário toca no ícone; o `onPressed` é executado.
2. O código chama `setState()`, alterando o dado dentro da função recebida.
3. O `setState()` marca o widget como "sujo" e agenda uma nova chamada de `build()`.
4. O Flutter reconstrói o widget e sua subárvore, compara o resultado ao anterior (via Elements) e atualiza apenas o que mudou.

### Aplicação

```dart
class ContadorFavoritos extends StatefulWidget {
  const ContadorFavoritos({super.key});

  @override
  State<ContadorFavoritos> createState() => _ContadorFavoritosState();
}

class _ContadorFavoritosState extends State<ContadorFavoritos> {
  int _quantidade = 0;

  void _incrementar() {
    setState(() => _quantidade++); // dispara reconstrução do widget
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(_quantidade > 0 ? Icons.favorite : Icons.favorite_border),
      onPressed: _incrementar,
    );
  }
}
```

Uma alteração em `_quantidade` **fora** de `setState()` mudaria o valor, mas não agendaria a reconstrução, e a tela permaneceria desatualizada. Essa distinção antecipa um tema central da Aula 22: `setState()` reconstrói o widget e **toda a sua subárvore**, de modo que compreender o escopo dessa reconstrução é o que separa um código Flutter ingênuo de um código bem projetado.

## 5. Responsividade com `LayoutBuilder` e `MediaQuery`

### Problema

O mesmo aplicativo executa em celulares compactos, tablets e dobráveis, em orientação retrato ou paisagem, e também em janelas redimensionáveis. Um layout projetado para uma largura fixa torna-se ilegível ou desperdiça espaço nas demais. É necessário que o código **consulte o espaço disponível** e escolha a estrutura adequada.

### Mecanismo

O Flutter oferece duas fontes de informação, que respondem a perguntas diferentes:

> **Definição — `MediaQuery`**: widget do Flutter que expõe informações sobre o ambiente de exibição atual (tamanho da tela, densidade, orientação, tema claro/escuro, escala de fonte do sistema) para qualquer widget descendente na árvore.

> **Definição — `LayoutBuilder`**: widget que expõe as restrições de espaço (`BoxConstraints`) efetivamente disponíveis para ele **no ponto da árvore onde está posicionado** — diferente do `MediaQuery`, que sempre reporta o tamanho da tela inteira, o `LayoutBuilder` reporta o espaço realmente disponível para aquele widget específico, essencial quando ele está aninhado dentro de outro layout que já reduziu o espaço disponível (ex.: dentro de um painel lateral).

A diferença pode ser resumida em uma pergunta para cada widget:

| Widget | Pergunta que responde | Exemplo de uso |
|---|---|---|
| `MediaQuery` | "Qual é o tamanho da **tela**?" | Decidir a estrutura da tela inteira |
| `LayoutBuilder` | "Quanto espaço o **meu pai** me concedeu?" | Adaptar um card que pode estar em um painel estreito |

A razão de existirem duas fontes é que, no Flutter, o tamanho de um widget é determinado por um protocolo em que o pai impõe restrições ao filho. Um card dentro de um painel lateral de 300dp recebe 300dp de largura máxima, ainda que a tela tenha 1000dp. Nessa situação, o tamanho da tela é uma informação irrelevante, e apenas o `LayoutBuilder` fornece a informação correta.

### Aplicação

```dart
class TelaResponsiva extends StatelessWidget {
  const TelaResponsiva({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return const _LayoutCompacto();   // classe compacta, Aula 3
        } else if (constraints.maxWidth < 840) {
          return const _LayoutMedio();      // classe média
        } else {
          return const _LayoutExpandido();  // classe expandida
        }
      },
    );
  }
}
```

A comparação direta com os pontos de quebra de 600dp e 840dp estudados na Aula 3 evidencia que a teoria de responsividade não se altera entre Android nativo e Flutter; apenas a API usada para aplicá-la é diferente.

> **Critério de escolha**: para uma decisão estrutural de **tela inteira**, baseada na classe de tamanho de janela, o idiomático é `MediaQuery.sizeOf(context)`. Desde o Flutter 3.10, essa chamada evita reconstruções desnecessárias de widgets que não dependem do tamanho (diferentemente de `MediaQuery.of(context)`, que notifica o widget a cada mudança de qualquer propriedade do ambiente). O pacote oficial `flutter_adaptive_scaffold` é uma alternativa para essa finalidade. Reserva-se o `LayoutBuilder` para o caso em que o widget está aninhado em outro layout que já reduziu o espaço disponível (por exemplo, um card dentro de um painel lateral), situação para a qual o widget foi projetado e em que o tamanho da tela inteira não é a informação relevante.

> **Nota**: a `TelaProduto` construída na §3 é a "tela âncora" deste componente. A mesma tela será reconstruída em React Native na Aula 16 e comparada formalmente na Aula 23, de modo que convém preservá-la.

#### Observação da árvore em execução

Para tornar concreta a metáfora da árvore, recomenda-se abrir o **Flutter DevTools > Widget Inspector** durante o desenvolvimento desta tela. A ferramenta exibe a hierarquia real de widgets, permite selecionar um elemento na tela e localizá-lo na árvore, e deve ser usada desde esta aula, e não apenas na Aula 22.

## 6. `SafeArea` no Flutter

### Problema

Retomando a Aula 6, telas modernas possuem recortes de câmera, cantos arredondados e barras do sistema (status e navegação). Conteúdo posicionado nessas regiões fica parcialmente oculto ou inacessível ao toque.

### Mecanismo e aplicação

O Flutter resolve a área segura com o widget declarativo `SafeArea`. Ele consulta o `MediaQuery` para obter as regiões ocupadas pelo sistema e aplica automaticamente, ao seu filho, o preenchimento necessário para evitá-las. Como o resultado depende do aparelho, o mesmo código produz margens diferentes em dispositivos diferentes, sem que o desenvolvedor precise conhecer os valores.

```dart
Scaffold(
  body: SafeArea(
    child: ConteudoDaTela(),
  ),
)
```

## 7. Exemplo real: hot reload como resposta ao custo de iteração em mobile

Antes de frameworks com hot reload, ajustar um valor de espaçamento em uma tela Android nativa exigia recompilar e reinstalar o aplicativo inteiro no aparelho ou no emulador, ciclo que, em projetos maiores, chega a consumir dezenas de segundos ou minutos. Esse custo de iteração desincentiva o ajuste fino de interface, justamente a atividade mais frequente ao aplicar hierarquia visual (Aula 10) e responsividade (Aula 3).

O hot reload do Flutter, ao preservar o estado da aplicação e aplicar apenas a mudança de código em menos de um segundo, reduz esse custo a praticamente zero. Trata-se de uma decisão arquitetural do framework (máquina virtual Dart com JIT durante o desenvolvimento, conforme a §2) com efeito direto e mensurável sobre a produtividade de quem projeta interface.

## Síntese da aula

| Conceito | Problema que resolve | Papel |
|---|---|---|
| Motor de renderização próprio | Diferenças visuais entre plataformas | Consistência visual, sem depender de views nativas |
| Compilação AOT / JIT | Conflito entre desempenho e velocidade de iteração | Desempenho em produção / hot reload em desenvolvimento |
| Árvore de widgets | Multiplicidade de conceitos de layout | Tudo é widget, inclusive espaçamento e tema |
| Três árvores (Widget, Element, RenderObject) | Custo de reconstruir a interface | Reconstruir a configuração é barato; recalcular layout e pintura é caro |
| `StatelessWidget` / `StatefulWidget` | Distinção entre interface fixa e reativa | Aparência fixa x aparência que reage a mudança de estado |
| `LayoutBuilder` / `MediaQuery` | Adaptação a espaços variáveis | Responsividade a partir do espaço disponível local / global |
| `SafeArea` | Conteúdo oculto por recortes e barras | Preenchimento automático conforme o aparelho |

## Leitura recomendada

- Documentação oficial: [Flutter architectural overview](https://docs.flutter.dev/resources/architectural-overview) e [Flutter — Get started](https://docs.flutter.dev/get-started).
- SMYTH, Neil. *Flutter Apprentice*. Kodeco (atualizado continuamente) — cobre Dart moderno com null safety e Material 3.

> Recomenda-se evitar bibliografia de Flutter anterior a 2022: o framework mudou substancialmente com a chegada de null safety obrigatório e do Material 3, tornando exemplos de livros mais antigos incompatíveis com projetos novos.
