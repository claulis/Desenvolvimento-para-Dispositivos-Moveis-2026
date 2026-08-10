# Aula 9 — Flutter: modelo de execução e árvore de widgets

**Carga horária:** 4h
**Unidade:** III — Arquitetura de software em Flutter

## Objetivos da aula

- Explicar o modelo de compilação e renderização do Flutter e suas consequências para consistência visual.
- Compor interfaces a partir da árvore de widgets.
- Implementar responsividade com `LayoutBuilder` e `MediaQuery`.

## 1. O que torna o Flutter diferente

> **Definição — Flutter**: framework de interface multiplataforma da Google, escrito em Dart, que renderiza sua própria interface pixel a pixel através de um motor gráfico próprio — **Impeller**, o motor padrão desde 2024–2025 (padrão no Android para dispositivos com suporte a Vulkan desde o Flutter 3.29, e padrão no iOS desde antes disso), sucedendo o antigo motor Skia, hoje em remoção — em vez de traduzir seus componentes para os widgets nativos do sistema operacional hospedeiro.

Essa é a diferença arquitetural mais importante do Flutter em relação a abordagens como o React Native (Aula 13) ou o desenvolvimento Android nativo: **o Flutter não usa os componentes visuais do Android** (`Button`, `TextView` etc.). Ele desenha, com seu próprio motor de renderização, algo visualmente idêntico a esses componentes. A consequência é dupla:

- **Vantagem**: consistência visual perfeita entre plataformas (o mesmo pixel exato em Android e iOS) e desempenho de renderização previsível, já que o Flutter não depende da árvore de views nativa do sistema.
- **Custo**: o Flutter precisa reimplementar comportamentos de plataforma que o sistema oferece de graça a componentes nativos (ex.: comportamento exato de rolagem, seleção de texto) — e para aderir ao Material Design (Aula 6), usa o pacote `Material`, que já traduz os tokens de cor, tipografia e componentes estudados anteriormente para widgets Flutter.

## 2. Compilação AOT (ahead-of-time) de Dart

Dart, a linguagem do Flutter, compila para código de máquina nativo (AOT) na build de produção — não é interpretada em tempo de execução como JavaScript costuma ser. Isso dá ao Flutter desempenho próximo do nativo em cálculo e execução de lógica, mas exige rebuild e reinstalação para ver mudanças de código em produção. Durante o desenvolvimento, o Flutter usa uma máquina virtual Dart com compilação JIT (*just-in-time*), o que viabiliza o recurso de **hot reload**: alterações de código de interface aparecem no aparelho em menos de um segundo, sem perder o estado da aplicação em execução — uma produtividade de iteração que muda como se depura uma interface.

## 3. A árvore de widgets

> **Definição — Widget**: no Flutter, a unidade fundamental e universal de construção de interface — **tudo é widget**: um texto, um espaçamento, um alinhamento, uma animação, e até mesmo conceitos estruturais como tema e diretriz de acessibilidade são representados como widgets que envolvem (compõem) outros widgets.

Diferente do Android nativo, onde existe uma distinção entre a `View` visual e conceitos de layout separados, no Flutter tudo — inclusive espaçamento e alinhamento — é resolvido por composição de widgets, formando uma árvore.

> **Nuance importante, que explica a Aula 19**: "tudo é widget" descreve apenas a camada mais externa. Por trás dela, o Flutter mantém **três árvores** sincronizadas: a árvore de **Widgets** (a configuração que você escreve em `build()` — imutável, descartável, recriada a cada reconstrução), a árvore de **Elements** (a instância persistente que conecta um widget ao seu lugar na hierarquia ao longo do tempo) e a árvore de **RenderObjects** (responsável pelo cálculo real de layout e pintura na tela). Um novo widget sendo criado em `build()` **não** significa, por si só, trabalho caro: o Flutter compara o novo widget ao anterior por meio da árvore de Elements e só propaga a mudança para a árvore de RenderObjects quando algo de fato mudou. É exatamente essa distinção — "reconstruir a configuração é barato; recalcular layout/pintura é o que custa" — que sustenta a Aula 19.

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

Note como a malha de espaçamento (`EdgeInsets.all(16.0)`, `SizedBox(height: 8)`) e a escala tipográfica (`Theme.of(context).textTheme.headlineSmall`) discutidas na Aula 6 se traduzem diretamente em código Flutter — o sistema de design não é reinventado por plataforma, apenas expresso na sintaxe de cada uma.

## 4. Widgets com e sem estado

> **Definição — StatelessWidget**: widget cuja aparência depende exclusivamente dos parâmetros recebidos na construção, sem manter dados internos mutáveis — reconstruído inteiramente sempre que seus parâmetros mudam.

> **Definição — StatefulWidget**: widget associado a um objeto de estado (`State`) que pode ser alterado ao longo do tempo (por exemplo, em resposta a um toque), disparando a reconstrução do widget quando `setState()` é chamado.

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

Essa distinção antecipa um tema central da Aula 19 (custo de renderização): `setState()` reconstrói o widget e sua subárvore — entender o escopo dessa reconstrução é o que separa um código Flutter ingênuo de um bem projetado.

## 5. Responsividade com `LayoutBuilder` e `MediaQuery`

> **Definição — `MediaQuery`**: widget do Flutter que expõe informações sobre o ambiente de exibição atual (tamanho da tela, densidade, orientação, tema claro/escuro, escala de fonte do sistema) para qualquer widget descendente na árvore.

> **Definição — `LayoutBuilder`**: widget que expõe as restrições de espaço (`BoxConstraints`) efetivamente disponíveis para ele **no ponto da árvore onde está posicionado** — diferente do `MediaQuery`, que sempre reporta o tamanho da tela inteira, o `LayoutBuilder` reporta o espaço realmente disponível para aquele widget específico, essencial quando ele está aninhado dentro de outro layout que já reduziu o espaço disponível (ex.: dentro de um painel lateral).

```dart
class TelaResponsiva extends StatelessWidget {
  const TelaResponsiva({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return const _LayoutCompacto();   // classe compacta, Aula 7
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

Essa comparação direta com os pontos de quebra de 600dp e 840dp estudados na Aula 7 mostra que a teoria de responsividade não muda entre Android nativo e Flutter — apenas a API usada para aplicá-la.

> **Quando usar cada um**: para uma decisão estrutural de **tela inteira** baseada na classe de tamanho de janela (como no exemplo acima), o idiomático é `MediaQuery.sizeOf(context)` — desde o Flutter 3.10, essa chamada evita reconstruções desnecessárias de widgets que não dependem do tamanho — ou o pacote oficial `flutter_adaptive_scaffold`. Reserve `LayoutBuilder` para quando o widget está aninhado dentro de outro layout que já reduziu o espaço disponível (ex.: um card dentro de um painel lateral), onde o tamanho da tela inteira não é a informação relevante — que é o caso de uso que o widget foi desenhado para resolver, e continua válido.

> **Nota**: a `TelaProduto` construída acima é a "tela âncora" deste componente — a mesma tela será reconstruída em React Native na Aula 13 e comparada formalmente na Aula 20. Vale a pena guardá-la.

Para ver a árvore de widgets renderizada ao vivo — e tornar a metáfora "árvore" concreta, não apenas textual — abra o **Flutter DevTools > Widget Inspector** durante o desenvolvimento desta tela, não apenas na Aula 19.

## 6. `SafeArea` no Flutter

Retomando a Aula 3, o Flutter resolve área segura com o widget declarativo `SafeArea`, que aplica automaticamente o preenchimento necessário para evitar recortes de câmera e barras do sistema:

```dart
Scaffold(
  body: SafeArea(
    child: ConteudoDaTela(),
  ),
)
```

## 7. Exemplo real: hot reload como resposta ao custo de iteração em mobile

Antes de frameworks com hot reload, ajustar um valor de espaçamento em uma tela Android nativa exigia recompilar e reinstalar o aplicativo inteiro no aparelho ou emulador — um ciclo que, em projetos maiores, chega a levar dezenas de segundos ou minutos. Esse custo de iteração desincentiva ajuste fino de interface, justamente a atividade mais frequente ao aplicar hierarquia visual (Aula 6) e responsividade (Aula 7). O hot reload do Flutter, ao preservar o estado da aplicação e aplicar apenas a mudança de código em menos de um segundo, reduz esse custo a praticamente zero — uma decisão arquitetural do framework (máquina virtual Dart com JIT durante o desenvolvimento) com efeito direto e mensurável sobre a produtividade de quem projeta interface.

## Síntese da aula

| Conceito | Papel |
|---|---|
| Motor de renderização próprio | Consistência visual entre plataformas, sem depender de views nativas |
| Compilação AOT / JIT | Desempenho em produção / hot reload em desenvolvimento |
| Árvore de widgets | Tudo é widget, inclusive espaçamento e tema |
| `StatelessWidget` / `StatefulWidget` | Distinção entre aparência fixa e aparência que reage a mudança de estado |
| `LayoutBuilder` / `MediaQuery` | Responsividade a partir do espaço disponível local / global |

## Leitura recomendada

- Documentação oficial: [Flutter architectural overview](https://docs.flutter.dev/resources/architectural-overview) e [Flutter — Get started](https://docs.flutter.dev/get-started).
- SMYTH, Neil. *Flutter Apprentice*. Kodeco (atualizado continuamente) — cobre Dart moderno com null safety e Material 3.

> Evite bibliografia de Flutter anterior a 2022: o framework mudou substancialmente com a chegada de null safety obrigatório e do Material 3, tornando exemplos de livros mais antigos incompatíveis com projetos novos.

## Atividade da aula

**Configuração do ambiente Flutter e implementação responsiva da tela projetada na semana 7**: instalar o Flutter SDK, criar um novo projeto (ponto de partida disponível em [`codigo/flutter/09-widgets-responsivos/`](../codigo/flutter/09-widgets-responsivos/)), e implementar em código Dart a tela cujas três variações de classe de tamanho foram prototipadas na Aula 7, usando `LayoutBuilder` para alternar entre elas nos mesmos pontos de quebra (600dp e 840dp) definidos anteriormente.
