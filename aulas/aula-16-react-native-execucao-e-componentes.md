# Aula 16 — React Native: modelo de execução e componentes

**Carga horária:** 4h
**Unidade:** IV — Arquitetura de software em React Native

## Objetivos da aula

- Explicar o modelo de execução do React Native e o papel da interface JavaScript/renderizador.
- Construir interfaces com componentes funcionais e hooks.
- Implementar responsividade com Flexbox e `useWindowDimensions`.

## Organização da aula

Esta aula apresenta o segundo framework do componente e mantém o método comparativo iniciado na Unidade III: cada conceito do React Native é relacionado ao seu equivalente no Flutter, de modo que as semelhanças e as diferenças fiquem explícitas. A sequência é: como o código é executado e como produz a interface (§1 e §2), como a interface é construída e como reage a mudanças (§3 e §4), e como é organizada e adaptada a diferentes telas (§5 e §6). Em cada tópico, o conteúdo segue a ordem: problema, mecanismo e aplicação.

## 1. O que torna o React Native diferente do Flutter

> **Definição — React Native**: framework de interface multiplataforma que executa código de aplicação escrito em JavaScript/TypeScript sobre uma camada de componentes **nativos reais** do sistema operacional hospedeiro — diferente do Flutter, que desenha sua própria interface, o React Native traduz seus componentes (`View`, `Text`, `Image`) em componentes nativos Android (ou iOS) de fato.

### Problema

Ao retomar a Aula 11, observa-se que o Flutter resolve a diferença entre sistemas operacionais desenhando todos os pixels por conta própria. Essa não é a única solução possível, e cada alternativa implica consequências distintas para a aparência, o comportamento e a integração com o sistema. A compreensão dessa escolha é pré-requisito para a comparação formal que será concluída na Aula 23.

### Mecanismo

O React Native adota a estratégia oposta: o código JavaScript descreve a interface como uma árvore de elementos, e o framework **traduz** cada elemento em um componente nativo correspondente. Um `<Text>` torna-se um `TextView` no Android e um `UILabel` no iOS. A tela exibida é, portanto, composta por componentes que o próprio sistema operacional criou e gerencia. Disso decorrem vantagens (aparência e comportamento idênticos aos do sistema, como a rolagem e a seleção de texto nativas) e custos (a fidelidade entre plataformas depende de cada componente nativo se comportar de forma equivalente).

| Aspecto | Flutter | React Native |
|---|---|---|
| Renderização | Motor próprio (Impeller), desenha cada pixel | Componentes nativos reais da plataforma, via Fabric |
| Linguagem | Dart (compilada para código de máquina, AOT) | JavaScript/TypeScript, executado pelo motor **Hermes**, que pré-compila para bytecode em tempo de build (AOT) e o interpreta — não há JIT em produção |
| Fidelidade visual entre SOs | Idêntica por construção | Depende da fidelidade da ponte com o componente nativo de cada SO |
| Acesso a recursos nativos "de fábrica" | Requer canal de plataforma para o que não está pronto | Mais próximo, mas ainda depende de módulos nativos para APIs não cobertas |

A linha referente à linguagem merece esclarecimento. No Hermes, o código JavaScript é convertido em **bytecode** (instruções intermediárias compactas) durante o build, o que reduz o tempo de inicialização do aplicativo, pois o código não precisa ser analisado na primeira execução. Em tempo de execução, o bytecode é interpretado, sem compilação adicional para código de máquina (JIT). Em contraste, o Dart do Flutter é compilado diretamente para código de máquina em produção.

## 2. Interface JavaScript, renderizador e módulos: a Nova Arquitetura

### Problema

O código JavaScript e os componentes nativos executam em ambientes distintos, com linguagens e threads diferentes. Para que um `setState` em JavaScript resulte em uma alteração na tela, as duas partes precisam se comunicar, e a forma dessa comunicação determina a latência e a fluidez do aplicativo.

### Mecanismo

Desde a versão 0.76 (outubro de 2024), a **Nova Arquitetura** é o padrão de todo projeto React Native novo, e não mais uma migração em andamento. Convém tomá-la como modelo de referência, tratando a arquitetura antiga ("Bridge") como contexto histórico que explica por que certas bibliotecas de animação existem. Seus componentes são:

1. **Thread JavaScript**: executa a lógica da aplicação e decide **o que** deve ser exibido, descrevendo a interface como uma árvore de elementos React (semelhante ao DOM virtual da web).
2. **JSI (JavaScript Interface)**: mecanismo de comunicação entre a thread JavaScript e o código nativo. Permite chamadas **síncronas e tipadas diretamente**, sem serialização em lote, e substitui a antiga Bridge.
3. **Fabric**: o renderizador da Nova Arquitetura, responsável por criar e atualizar os componentes nativos reais na tela a partir da árvore descrita em JavaScript. É o análogo funcional do motor de renderização do Flutter (Aula 11), com a diferença central de que o Fabric produz componentes nativos de fato, e não pixels desenhados por um motor próprio.
4. **TurboModules**: acesso a módulos nativos sob demanda e com JSI, substituindo o antigo `NativeModules` (retomado na Aula 19).

O fluxo de uma atualização pode ser resumido assim: o estado muda em JavaScript; o React calcula a nova árvore de elementos; o Fabric compara a árvore nova com a anterior e aplica ao lado nativo apenas as diferenças; os componentes nativos são atualizados na tela.

> **Definição — Ponte (Bridge)**: mecanismo de comunicação **assíncrona** entre a thread JavaScript e a thread nativa, usado pela arquitetura legada do React Native (anterior à 0.76), baseado em serialização de mensagens em lote — hoje em desativação.

A Bridge explica uma limitação histórica: como toda comunicação era assíncrona e serializada, um gesto contínuo (arrastar um elemento) exigia um ciclo de ida e volta entre as threads, introduzindo atraso perceptível. Esse é o motivo pelo qual animações e gestos complexos se beneficiaram de bibliotecas como `react-native-reanimated` e `react-native-gesture-handler`, que movem parte da lógica de animação para a thread de UI nativa, contornando a latência da ponte. Com o JSI, parte dessa limitação estrutural é reduzida, mas essas bibliotecas continuam sendo a prática recomendada para animações guiadas por gesto.

## 3. Componentes funcionais e hooks

### Problema

Uma interface precisa ser dividida em partes reutilizáveis, e cada parte precisa guardar dados que mudam (como um contador) e executar ações em momentos específicos (como buscar dados ao ser exibida). No React clássico, isso exigia classes, com ciclo de vida disperso em vários métodos e lógica difícil de reaproveitar entre componentes.

### Mecanismo

> **Definição — Componente funcional**: no React (e React Native), uma função JavaScript/TypeScript que recebe propriedades (*props*) e retorna uma descrição declarativa da interface (JSX), sem necessidade de uma classe — o padrão dominante desde a introdução dos hooks, substituindo os componentes de classe usados no React clássico.

> **Definição — Hook**: função especial do React (identificável pelo prefixo `use`) que permite a um componente funcional "conectar-se" a funcionalidades como estado local (`useState`), efeitos colaterais (`useEffect`) ou contexto compartilhado (`useContext`), sem precisar de uma classe.

O componente funcional é uma função que **executa novamente a cada renderização**. Isso levanta a questão de onde os dados persistem entre execuções, já que variáveis locais são recriadas. O hook `useState` resolve essa questão: o React guarda o valor fora da função, associado ao componente, e o devolve a cada execução. Ao chamar a função de atualização (`setQuantidade`), o React agenda uma nova renderização do componente com o valor atualizado.

### Aplicação

```tsx
import { useState } from 'react';
import { View, Text, Pressable, StyleSheet } from 'react-native';

function ContadorFavoritos() {
  const [quantidade, setQuantidade] = useState(0);

  return (
    <Pressable onPress={() => setQuantidade((q) => q + 1)}>
      <Text style={estilos.texto}>
        {quantidade > 0 ? '♥ Favoritado' : '♡ Favoritar'}
      </Text>
    </Pressable>
  );
}

const estilos = StyleSheet.create({
  texto: { fontSize: 16, padding: 12 },
});
```

Leitura do código: `useState(0)` devolve o par `[valor, função de atualização]`, com valor inicial `0`. A forma `setQuantidade((q) => q + 1)` recebe uma função que calcula o novo valor a partir do valor mais recente, o que evita erros quando várias atualizações ocorrem em sequência. A expressão entre chaves no JSX é avaliada a cada renderização, e o texto exibido depende do valor atual.

O exemplo é conceitualmente equivalente ao `StatefulWidget` da Aula 11: `useState` desempenha o papel que `setState()` desempenha no Flutter, que é disparar nova renderização quando o dado muda. A diferença de forma é que o estado, em vez de residir em uma classe `State` separada, é declarado dentro da própria função.

## 4. Tela de detalhe de produto: comparação direta com a Aula 11

Para explicitar a equivalência entre as duas plataformas, central ao método comparativo deste componente, a mesma tela de detalhe de produto construída em Flutter na Aula 11 é reconstruída aqui em React Native.

### Centralização dos valores de tema

```tsx
// tema.ts — tokens de cor e tipografia, único lugar que conhece valores brutos
// (a mesma paleta gerada no Material Theme Builder, Aula 10, reaproveitada aqui)
export const cores = {
  primary: '#6750A4',
  onPrimary: '#FFFFFF',
} as const;

export const tipografia = {
  headlineSmall: { fontSize: 24, fontWeight: '600' as const },
  titleLarge: { fontSize: 20, fontWeight: '400' as const },
};
```

O arquivo `tema.ts` cumpre o papel dos tokens da Aula 10: os componentes referenciam `cores.primary`, e somente este arquivo conhece o valor `#6750A4`. A anotação `as const` faz o TypeScript tratar os valores como literais imutáveis, o que impede a alteração acidental e habilita a verificação de tipos precisa.

### A tela

```tsx
import { View, Text, Pressable, StyleSheet } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { cores, tipografia } from './tema';

function TelaProduto() {
  const insets = useSafeAreaInsets(); // Aula 6: SafeAreaView do core é legado e
  return (                            // não se comporta bem no Android; usa-se o hook
    <View style={[estilos.container, { paddingTop: insets.top, paddingBottom: insets.bottom }]}>
      <Text style={[estilos.titulo, tipografia.headlineSmall]}>Smartphone XYZ</Text>
      <Text style={[estilos.preco, tipografia.titleLarge]}>R$ 1.500,00</Text>
      <View style={estilos.espacador} />
      <Pressable style={estilos.botao} onPress={() => {}}>
        <Text style={estilos.textoBotao}>Comprar</Text>
      </Pressable>
    </View>
  );
}

const estilos = StyleSheet.create({
  container: { flex: 1, padding: 16 },
  titulo: { color: '#000000' },
  preco: { marginTop: 8 },
  espacador: { flex: 1 },
  botao: { backgroundColor: cores.primary, padding: 16, borderRadius: 8 },
  textoBotao: { color: cores.onPrimary, textAlign: 'center', fontWeight: '600' },
});
```

Leitura do código e correspondência com a Aula 11:

| Flutter (Aula 11) | React Native (esta aula) |
|---|---|
| `Scaffold` + `SafeArea` | `View` + `useSafeAreaInsets()` aplicados como `padding` |
| `Column` | `View` (o `flexDirection` padrão é `column`) |
| `Spacer` | `View` com `flex: 1`, que ocupa o espaço restante |
| `ElevatedButton` | `Pressable` estilizado |
| `Theme.of(context).textTheme` | Objeto `tipografia` importado de `tema.ts` |

A malha de espaçamento (múltiplos de 8, Aula 10) e os tokens de cor continuam se aplicando, expressos em `StyleSheet` do React Native em vez de widgets do Flutter. Observa-se que o `titulo` ainda contém a cor fixa `'#000000'`, e **cores e tamanhos de fonte fixos diretamente no `StyleSheet`, como `'#6750A4'` espalhado pelos componentes, constituem exatamente o antipadrão "cor fixa, ignora tema" apontado na Aula 10**. Centralizar os valores em `tema.ts` (ou em um equivalente que resolva claro e escuro) é o que preserva, em React Native, o mesmo princípio já estabelecido para Android nativo.

## 5. Layout por Flexbox

### Problema

Todo framework precisa de um modelo para posicionar elementos em relação uns aos outros e ao espaço disponível. O Flutter utiliza seu próprio sistema de composição (`Row`, `Column`, `Expanded`). O React Native adota um modelo preexistente e amplamente conhecido.

### Mecanismo

O React Native utiliza diretamente o modelo **Flexbox** da web, com algumas diferenças de valores padrão. A mais relevante é que o `flexDirection` padrão é `column`, e não `row` como na web, o que reflete o uso predominante em telas de celular, organizadas verticalmente.

> **Definição — Flexbox**: modelo de layout unidimensional em que um contêiner distribui espaço entre seus filhos ao longo de um eixo principal (`flexDirection`), com propriedades como `flex` (proporção de espaço a ocupar), `justifyContent` (alinhamento ao longo do eixo principal) e `alignItems` (alinhamento no eixo cruzado).

O raciocínio fundamental é o de dois eixos: o **eixo principal**, definido por `flexDirection`, e o **eixo cruzado**, perpendicular a ele. `justifyContent` controla a distribuição ao longo do eixo principal, ao passo que `alignItems` controla o alinhamento no eixo cruzado. A propriedade `flex` define quanto do espaço restante cada filho ocupa, de forma proporcional.

### Aplicação

```tsx
<View style={{ flexDirection: 'row', justifyContent: 'space-between', padding: 16 }}>
  <Text>Produto</Text>
  <Text>R$ 1.500,00</Text>
</View>
```

Neste exemplo, `flexDirection: 'row'` coloca os textos lado a lado, e `justifyContent: 'space-between'` distribui o espaço livre entre eles, empurrando o primeiro para o início e o segundo para o fim da linha.

Para quem já programa para a web, o Flexbox do React Native representa reaproveitamento direto de conhecimento, uma das razões práticas de sua adoção por equipes com experiência predominante em web.

## 6. Responsividade com `useWindowDimensions`

### Problema

Retomando a Aula 3 e a Aula 11, o aplicativo deve adaptar sua estrutura ao tamanho da janela, que varia entre aparelhos, orientações e modos de janela em telas grandes ou dobráveis.

### Mecanismo

> **Definição — `useWindowDimensions`**: hook do React Native que retorna a largura e a altura atuais da janela disponível, atualizando automaticamente o componente que o utiliza quando a tela gira ou (em telas grandes/dobráveis) quando o tamanho de janela muda.

A atualização automática decorre da própria natureza dos hooks: quando as dimensões mudam, o React renderiza novamente o componente, e o novo valor de `width` conduz à escolha de outro layout. Não é necessário registrar nem remover manualmente um ouvinte de eventos.

### Aplicação

```tsx
import { useWindowDimensions, View } from 'react-native';

function TelaResponsiva() {
  const { width } = useWindowDimensions();

  if (width < 600) {
    return <LayoutCompacto />;
  } else if (width < 840) {
    return <LayoutMedio />;
  } else {
    return <LayoutExpandido />;
  }
}
```

A comparação direta com o `LayoutBuilder` do Flutter (Aula 11) é intencional: os mesmos pontos de quebra de 600dp e 840dp (Aula 3) se aplicam, apenas expressos por um hook em vez de um widget. Isso reforça que a **teoria de responsividade pertence à plataforma Android, e não ao framework**.

Uma ressalva de equivalência: `useWindowDimensions` reporta o tamanho da **janela inteira**, assemelhando-se mais ao `MediaQuery` do Flutter do que ao `LayoutBuilder`, que informa o espaço concedido pelo widget pai. Para adaptar um componente ao espaço do seu contêiner, o React Native oferece o evento `onLayout` das views, que informa as dimensões efetivamente medidas.

## 7. Exemplo real: por que equipes com background web escolhem React Native

Uma razão de mercado frequentemente citada para a adoção do React Native é a reutilização de conhecimento de equipes já proficientes em JavaScript/TypeScript e React para web. Conceitos como componentes, hooks, Flexbox e gerenciamento de estado (Context, Redux; Aula 17) transferem-se quase diretamente.

Esse fator reduz o tempo de adaptação de uma equipe web à produção mobile, aspecto relevante na análise comparativa de custo de implementação que será feita na Aula 23. Ele não elimina, contudo, a necessidade de compreender os condicionantes da plataforma Android estudados na Unidade I, que continuam se aplicando integralmente.

## Síntese da aula

| Conceito | Problema que resolve | Papel |
|---|---|---|
| Componentes nativos via Fabric | Diferenças entre sistemas operacionais | Interface composta por componentes nativos reais |
| JSI / Nova Arquitetura | Latência da comunicação assíncrona da Bridge | Comunicação síncrona e tipada entre JavaScript e código nativo |
| Componente funcional + hooks | Lógica de interface dispersa em classes | Unidade de construção de interface e estado |
| Tokens em `tema.ts` | Cores e tamanhos fixos espalhados | Valores brutos em um único ponto, resolúveis por tema |
| Flexbox | Necessidade de um modelo de layout | Modelo de layout reaproveitado da web |
| `useWindowDimensions` | Adaptação a janelas de tamanhos diferentes | Responsividade a partir do tamanho da janela |

## Leitura recomendada

- Documentação oficial: [React Native architecture overview](https://reactnative.dev/architecture/overview) e [Expo documentation](https://docs.expo.dev/).

> Recomenda-se evitar bibliografia de React Native anterior a 2019: livros como *Learning React Native* (Eisenman, 2ª ed., 2017) antecedem os hooks e ensinam componentes de classe como padrão, o que é incompatível com o código desta aula e do restante do componente.

## Uso de Expo

Este componente adota **Expo** como caminho padrão de projeto novo, em vez de React Native CLI puro. Trata-se da recomendação atual da própria equipe do React Native para a maioria dos projetos. A escolha evita consumir uma aula inteira apenas com a configuração do ambiente Android nativo (SDK, variáveis de ambiente, emulador) antes da escrita da primeira tela, tempo que é mais bem investido em arquitetura, tema central deste componente.
