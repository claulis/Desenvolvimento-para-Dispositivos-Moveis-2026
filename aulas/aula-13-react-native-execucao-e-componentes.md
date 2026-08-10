# Aula 13 — React Native: modelo de execução e componentes

**Carga horária:** 4h
**Unidade:** IV — Arquitetura de software em React Native

## Objetivos da aula

- Explicar o modelo de execução do React Native e o papel da interface JavaScript/renderizador.
- Construir interfaces com componentes funcionais e hooks.
- Implementar responsividade com Flexbox e `useWindowDimensions`.

## 1. O que torna o React Native diferente do Flutter

> **Definição — React Native**: framework de interface multiplataforma que executa código de aplicação escrito em JavaScript/TypeScript sobre uma camada de componentes **nativos reais** do sistema operacional hospedeiro — diferente do Flutter, que desenha sua própria interface, o React Native traduz seus componentes (`View`, `Text`, `Image`) em componentes nativos Android (ou iOS) de fato.

Essa é a diferença arquitetural central entre as duas plataformas estudadas no componente, e a base da comparação que será concluída na Aula 20:

| Aspecto | Flutter | React Native |
|---|---|---|
| Renderização | Motor próprio (Skia/Impeller), desenha cada pixel | Componentes nativos reais da plataforma |
| Linguagem | Dart (compilada para código de máquina) | JavaScript/TypeScript (interpretada/JIT em runtime) |
| Fidelidade visual entre SOs | Idêntica por construção | Depende da fidelidade da ponte com o componente nativo de cada SO |
| Acesso a recursos nativos "de fábrica" | Requer canal de plataforma para o que não está pronto | Mais próximo, mas ainda depende de módulos nativos para APIs não cobertas |

## 2. Interface JavaScript, renderizador e módulos síncronos

O modelo de execução tradicional do React Native (arquitetura "Bridge", ainda em uso em muitos projetos, embora a "Nova Arquitetura" com JSI venha substituindo-a) funciona em três partes:

1. **Thread JavaScript**: executa a lógica da aplicação e decide **o que** deve ser exibido, descrevendo a interface como uma árvore de elementos React (semelhante ao DOM virtual da web).
2. **Ponte (Bridge) / JSI**: serializa mensagens entre a thread JavaScript e a thread nativa — historicamente de forma assíncrona e em lotes (Bridge, formato JSON); na Nova Arquitetura, via JSI (JavaScript Interface), permitindo chamadas síncronas e tipadas diretamente, reduzindo a sobrecarga de serialização.
3. **Thread de UI nativa**: recebe as instruções e efetivamente cria/atualiza os componentes nativos Android na tela.

> **Definição — Ponte (Bridge)**: mecanismo de comunicação assíncrona entre a thread JavaScript e a thread nativa no React Native, historicamente baseado em serialização de mensagens em lote — um ponto de atenção arquitetural, já que operações que exigem comunicação intensa entre as duas threads (ex.: animações complexas guiadas por gesto) podem sofrer perda de fluidez se toda comunicação passar por esse canal serializado.

Esse modelo em camadas explica por que, historicamente, animações e gestos complexos em React Native se beneficiam de bibliotecas como `react-native-reanimated` e `react-native-gesture-handler`, que movem parte da lógica de animação para a thread de UI nativa, contornando a latência da ponte tradicional.

## 3. Componentes funcionais e hooks

> **Definição — Componente funcional**: no React (e React Native), uma função JavaScript/TypeScript que recebe propriedades (*props*) e retorna uma descrição declarativa da interface (JSX), sem necessidade de uma classe — o padrão dominante desde a introdução dos hooks, substituindo os componentes de classe usados no React clássico.

> **Definição — Hook**: função especial do React (identificável pelo prefixo `use`) que permite a um componente funcional "conectar-se" a funcionalidades como estado local (`useState`), efeitos colaterais (`useEffect`) ou contexto compartilhado (`useContext`), sem precisar de uma classe.

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

Esse exemplo é conceitualmente equivalente ao `StatefulWidget` da Aula 9: `useState` desempenha o papel que `setState()` desempenha no Flutter — disparar nova renderização quando o dado muda.

## 4. Tela de detalhe de produto: comparação direta com a Aula 9

Para explicitar a equivalência entre as duas plataformas — central ao método comparativo deste componente — a mesma tela de detalhe de produto construída em Flutter na Aula 9 é reconstruída aqui em React Native:

```tsx
import { View, Text, Pressable, StyleSheet, SafeAreaView } from 'react-native';

function TelaProduto() {
  return (
    <SafeAreaView style={estilos.container}>
      <Text style={estilos.titulo}>Smartphone XYZ</Text>
      <Text style={estilos.preco}>R$ 1.500,00</Text>
      <View style={estilos.espacador} />
      <Pressable style={estilos.botao} onPress={() => {}}>
        <Text style={estilos.textoBotao}>Comprar</Text>
      </Pressable>
    </SafeAreaView>
  );
}

const estilos = StyleSheet.create({
  container: { flex: 1, padding: 16 },
  titulo: { fontSize: 24, fontWeight: '600' },
  preco: { fontSize: 20, marginTop: 8 },
  espacador: { flex: 1 },
  botao: { backgroundColor: '#6750A4', padding: 16, borderRadius: 8 },
  textoBotao: { color: '#FFFFFF', textAlign: 'center', fontWeight: '600' },
});
```

Note que a malha de espaçamento (múltiplos de 8, Aula 6) e os tokens de cor continuam se aplicando — apenas expressos em `StyleSheet` do React Native em vez de widgets do Flutter.

## 5. Layout por Flexbox

Diferente do Flutter, que usa seu próprio sistema de composição (`Row`, `Column`, `Expanded`), o React Native adota diretamente o modelo **Flexbox** da web (com algumas diferenças de valores padrão — por exemplo, `flexDirection` padrão é `column`, não `row` como na web).

> **Definição — Flexbox**: modelo de layout unidimensional em que um contêiner distribui espaço entre seus filhos ao longo de um eixo principal (`flexDirection`), com propriedades como `flex` (proporção de espaço a ocupar), `justifyContent` (alinhamento ao longo do eixo principal) e `alignItems` (alinhamento no eixo cruzado).

```tsx
<View style={{ flexDirection: 'row', justifyContent: 'space-between', padding: 16 }}>
  <Text>Produto</Text>
  <Text>R$ 1.500,00</Text>
</View>
```

Para quem já programa para a web, o Flexbox do React Native é uma vantagem de reuso de conhecimento direto — uma das razões práticas de sua adoção por equipes com background majoritariamente web.

## 6. Responsividade com `useWindowDimensions`

> **Definição — `useWindowDimensions`**: hook do React Native que retorna a largura e a altura atuais da janela disponível, atualizando automaticamente o componente que o utiliza quando a tela gira ou (em telas grandes/dobráveis) quando o tamanho de janela muda.

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

A comparação direta com o `LayoutBuilder` do Flutter (Aula 9) é intencional: os mesmos pontos de quebra de 600dp e 840dp (Aula 7) se aplicam, apenas expressos por um hook em vez de um widget — reforçando que a **teoria de responsividade é da plataforma Android, não do framework**.

## 7. Exemplo real: por que equipes com background web escolhem React Native

Uma razão de mercado frequentemente citada para a adoção do React Native é a reutilização de conhecimento de equipes já proficientes em JavaScript/TypeScript e React para web: conceitos como componentes, hooks, Flexbox e gerenciamento de estado (Context, Redux — Aula 14) transferem quase diretamente. Isso reduz o tempo de ramp-up de uma equipe web para produção mobile, um fator relevante na análise comparativa de custo de implementação que será feita na Aula 20 — mas não elimina a necessidade de compreender os condicionantes de plataforma Android estudados na Unidade I, que continuam se aplicando integralmente.

## Síntese da aula

| Conceito | Papel |
|---|---|
| Ponte / JSI | Comunicação entre JavaScript e componentes nativos |
| Componente funcional + hooks | Unidade de construção de interface e estado |
| Flexbox | Modelo de layout, reaproveitado da web |
| `useWindowDimensions` | Responsividade equivalente ao `LayoutBuilder` do Flutter |

## Leitura recomendada

- EISENMAN, Bonnie. *Learning React Native*. 2. ed. Sebastopol: O'Reilly Media, 2017 — capítulos introdutórios sobre componentes e estilo.
- Documentação oficial: [React Native architecture overview](https://reactnative.dev/architecture/overview).

## Atividade da aula

**Configuração do ambiente React Native e implementação responsiva da mesma tela da semana 9**: instalar Node.js e o ambiente React Native/Expo, e implementar a mesma tela de detalhe de produto responsiva construída em Flutter na Aula 9, usando `useWindowDimensions` para alternar entre as três classes de tamanho de janela nos mesmos pontos de quebra.
