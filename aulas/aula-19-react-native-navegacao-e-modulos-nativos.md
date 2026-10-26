# Aula 19 — React Native: navegação e módulos nativos

**Carga horária:** 4h
**Unidade:** IV — Arquitetura de software em React Native

## Objetivos da aula

- Implementar navegação, rotas e ligações profundas com React Navigation.
- Relacionar a navegação React Native à pilha de retorno do Android.
- Explicar o papel dos módulos nativos na integração entre JavaScript e código específico do Android.

## Organização da aula

A aula espelha a Aula 14, aplicada ao React Native. Trata primeiro de como o usuário se desloca entre telas (§1 a §4) e, em seguida, de como o código JavaScript se comunica com o sistema Android quando a funcionalidade necessária não está disponível em uma biblioteca (§5). A comparação com o Flutter é feita em cada tópico, pois o objetivo é identificar o requisito de projeto comum às duas plataformas e as diferenças de API que o resolvem. Cada tópico segue a sequência: problema, mecanismo e aplicação.

## 1. React Navigation

### Problema

Um aplicativo é composto por várias telas, e o usuário precisa se deslocar entre elas de forma previsível. É necessário um mecanismo que mantenha o registro das telas visitadas, permita avançar e retornar, e suporte padrões de navegação diferentes (pilha, abas, menu lateral).

### Mecanismo

> **Definição — React Navigation**: biblioteca de referência para navegação em aplicativos React Native, que organiza rotas em navegadores (*stack*, *tab*, *drawer*) componíveis, cada um responsável por um padrão de navegação específico, sendo o `Stack Navigator` o análogo direto ao empilhamento estudado na Aula 2.

O `Stack Navigator` mantém uma pilha de telas: navegar para uma tela a **empilha**; retornar a **desempilha**, revelando a anterior. Cada tela é registrada com um nome único (`name`) e um componente (`component`). O `NavigationContainer` na raiz mantém o estado de navegação de todo o aplicativo. Os navegadores são **componíveis**: um navegador de abas pode conter, em cada aba, uma pilha própria.

### Aplicação

```tsx
import { NavigationContainer } from '@react-navigation/native';
import { createNativeStackNavigator } from '@react-navigation/native-stack';

const Stack = createNativeStackNavigator();

function App() {
  return (
    <NavigationContainer>
      <Stack.Navigator>
        <Stack.Screen name="Catalogo" component={TelaCatalogo} />
        <Stack.Screen name="DetalhePedido" component={TelaDetalhePedido} />
      </Stack.Navigator>
    </NavigationContainer>
  );
}
```

A primeira tela declarada (`Catalogo`) é a inicial. O uso de `createNativeStackNavigator` implica que as transições e a barra superior são implementadas com componentes nativos do sistema, em coerência com a abordagem do React Native (Aula 16).

```tsx
// Navegar para o detalhe, empilhando a nova tela
navigation.navigate('DetalhePedido', { id: pedido.id });

// Substituir a tela atual (sem deixá-la na pilha) — equivalente a
// pushReplacement no Flutter (Aula 14), usado após confirmação de formulário
navigation.replace('PedidoConfirmado');
```

O segundo argumento de `navigate` carrega os **parâmetros** da rota (`{ id: pedido.id }`), que a tela de destino lê pelas propriedades da rota. O método `replace` é indicado quando a tela anterior não deve ser alcançável por "voltar", como ocorre após o envio de um formulário já confirmado.

## 2. Relação com a pilha de retorno do Android

### Problema

Retomando a Aula 2, o Android mantém uma pilha de retorno, e o usuário espera que o gesto ou botão "voltar" desfaça a última navegação. Como na Aula 14, há situações em que o retorno imediato é indesejável, por exemplo quando acarretaria perda de dados de um formulário não salvo.

### Mecanismo

O `Stack Navigator` do React Navigation é construído para espelhar o comportamento de pilha de retorno nativo do Android: cada `navigate` empilha uma tela, e o gesto ou botão voltar do sistema desempilha automaticamente a tela do topo, sem código adicional para essa integração básica.

Para **interceptar** a tentativa de voltar, a navegação emite o evento `beforeRemove` antes de remover uma tela da pilha. Um ouvinte pode chamar `preventDefault()` para bloquear a remoção e, após consultar o usuário, reenviar a ação original com `navigation.dispatch`.

### Aplicação

```tsx
useFocusEffect(
  useCallback(() => {
    const cancelarAssinatura = navigation.addListener('beforeRemove', (evento) => {
      if (formularioEstaVazio) return;
      evento.preventDefault();
      exibirDialogoDescartar().then((confirmar) => {
        if (confirmar) navigation.dispatch(evento.data.action);
      });
    });
    return cancelarAssinatura;
  }, [navigation, formularioEstaVazio])
);
```

Sequência de eventos: (1) o usuário aciona "voltar"; (2) a navegação emite `beforeRemove`; (3) se o formulário está vazio, o ouvinte retorna e a remoção prossegue; (4) caso contrário, `preventDefault()` bloqueia a remoção e o diálogo é exibido; (5) se o usuário confirma, `navigation.dispatch(evento.data.action)` executa novamente a ação original, que agora prossegue. O valor devolvido pelo ouvinte (`cancelarAssinatura`) remove o ouvinte quando o efeito é desfeito, e a lista de dependências garante que o ouvinte sempre enxergue o valor atual de `formularioEstaVazio`.

Essa solução é paralela ao `PopScope` do Flutter, estudado na Aula 14: o mesmo requisito de projeto (não perder dados do usuário sem confirmação), resolvido com uma API distinta em cada framework. No Flutter, a decisão é declarada por uma propriedade (`canPop`); no React Navigation, é tomada por um ouvinte de evento que pode cancelar a operação.

> **Simplificação**: o evento `beforeRemove` já é escopado à tela ativa por natureza. Envolvê-lo em `useFocusEffect`, como acima, adiciona uma camada de indireção sem ganho real neste caso; um `useEffect` simples, com a mesma lista de dependências, é suficiente e mais direto.

## 3. Ligações profundas (deep links)

### Problema

Como na Aula 14, uma ligação profunda leva o usuário diretamente a uma tela específica, sem que as telas anteriores tenham sido percorridas. Se a pilha contiver apenas a tela de destino, o botão voltar fecha o aplicativo de forma inesperada, o que contraria a heurística "controle e liberdade do usuário" (Aula 8).

### Mecanismo

O React Navigation permite declarar a correspondência entre URLs e telas de forma **centralizada**, na propriedade `linking` do `NavigationContainer`. O campo `prefixes` lista os prefixos aceitos (esquema próprio e endereço web), e `config.screens` associa o nome de cada tela a um padrão de caminho. Os segmentos iniciados por dois-pontos (`:id`) são parâmetros extraídos da URL e entregues à tela, como em `navigate`.

### Aplicação

```tsx
const configuracaoLinking = {
  prefixes: ['meuapp://', 'https://meuapp.com.br'],
  config: {
    screens: {
      DetalhePedido: 'pedido/:id',
    },
  },
};

<NavigationContainer linking={configuracaoLinking}>
  {/* ... */}
</NavigationContainer>
```

Com essa configuração, as URLs `meuapp://pedido/42` e `https://meuapp.com.br/pedido/42` abrem a tela `DetalhePedido` com o parâmetro `id` igual a `42`.

Assim como o `go_router` do Flutter (Aula 14), o React Navigation permite declarar ligações profundas de forma centralizada. O mesmo requisito de reconstrução de pilha coerente ao abrir por notificação aplica-se aqui: o aplicativo deve inserir os ancestrais lógicos da tela de destino, para que o botão voltar leve a um estado esperado, e não a um vazio. No React Navigation, a pilha inicial é definida pela estrutura de navegadores aninhados e pela propriedade `initialRouteName`, que devem refletir a hierarquia desejada.

### Configuração de plataforma

Assim como na Aula 14, a configuração em JavaScript não é suficiente. O Android só encaminha uma URL ao aplicativo se o esquema estiver registrado no sistema. Em um projeto Expo, o esquema declarado acima precisa constar em `app.json`, e a ferramenta de build gera a configuração nativa correspondente (o *intent filter* que, no Flutter, era escrito manualmente no `AndroidManifest.xml`):

```json
{
  "expo": {
    "scheme": "meuapp"
  }
}
```

O teste utiliza o mesmo comando `adb` da Aula 14:

```bash
adb shell am start -W -a android.intent.action.VIEW -d "meuapp://pedido/42"
```

## 4. Fluxo de sessão

### Problema

O aplicativo precisa apresentar telas diferentes conforme o usuário esteja ou não autenticado. Navegar manualmente para a tela de login a partir de cada ponto possível (expiração de sessão, abertura por deep link, retorno de segundo plano) espalha a verificação pelo código e deixa lacunas.

### Mecanismo e aplicação

A abordagem recomendada é **renderizar condicionalmente o conjunto de navegadores** com base no estado de autenticação. Quando o usuário não está autenticado, as telas protegidas simplesmente não existem na árvore de navegação; ao autenticar, o estado muda e a árvore passa a incluir as telas principais.

```tsx
function App() {
  const { autenticado } = useAuth();

  return (
    <NavigationContainer>
      {autenticado ? <StackPrincipal /> : <StackDeAutenticacao />}
    </NavigationContainer>
  );
}
```

Como as telas protegidas não estão registradas enquanto o usuário não autenticou, nem mesmo um deep link consegue alcançá-las. Além disso, após o login ou o logout, a pilha é substituída automaticamente, o que impede que "voltar" leve o usuário de volta à tela de login ou a conteúdo protegido.

Trocar toda a árvore de navegadores com base no estado de autenticação é o mesmo princípio de "navegação como função do estado" discutido na Aula 14 a respeito da navegação declarativa. A diferença de implementação é que o `go_router` utiliza um callback `redirect`, ao passo que o React Navigation utiliza a própria renderização condicional.

## 5. Módulos nativos (native modules)

> **Definição — Módulo nativo (native module)**: código escrito em Kotlin/Java (para Android) ou Swift/Objective-C (para iOS) exposto ao JavaScript como uma API chamável, usado quando uma funcionalidade não está disponível em uma biblioteca JavaScript existente ou exige acesso direto a uma API do sistema operacional — o análogo direto do canal de plataforma do Flutter, estudado na Aula 14.

### Problema

O código JavaScript executa em seu próprio ambiente e não acessa diretamente as APIs do Android. Quando a funcionalidade necessária (por exemplo, um SDK de pagamento disponível apenas em Kotlin, ou um recurso de hardware sem biblioteca madura) não está disponível em JavaScript, é preciso uma ponte formal entre os dois mundos.

### Mecanismo

O módulo nativo é essa ponte. O lado nativo implementa a funcionalidade e a **registra** com um nome; o lado JavaScript a obtém por esse nome e a chama como uma função assíncrona que devolve uma `Promise`. Como no Flutter, a correspondência exige coincidência exata dos nomes dos módulos e dos métodos nos dois lados.

Com a Nova Arquitetura do React Native (TurboModules, Aula 16), a comunicação entre JavaScript e módulos nativos passa a usar o JSI diretamente, o que permite chamadas síncronas e tipadas. A evolução é análoga em espírito à que o próprio canal de plataforma do Flutter representa em relação a uma ponte assíncrona genérica.

> **API legada, mostrada por simplicidade didática**: o exemplo abaixo (`ReactContextBaseJavaModule` + `NativeModules`) é a API do modelo **Bridge antigo**, ainda amplamente encontrada em bibliotecas existentes e mais simples de introduzir em uma primeira aula. **A Nova Arquitetura resolve o mesmo problema por Codegen**: define-se uma especificação TypeScript (`NativeBateria.ts`) com a assinatura do módulo, e uma ferramenta de geração de código produz a interface tipada e o código de ponte a partir dela, eliminando o `NativeModules` não tipado do exemplo. Se o projeto utiliza Expo (Aula 16), a **Expo Modules API** é o caminho ainda mais simples, bem mais direto que o TurboModules puro para a maioria dos casos de uso deste nível.

### Aplicação

```kotlin
// Módulo nativo Android (Kotlin) — API legada (NativeModules/Bridge)
class BateriaModule(reactContext: ReactApplicationContext) :
    ReactContextBaseJavaModule(reactContext) {

    override fun getName() = "BateriaModule"

    @ReactMethod
    fun obterNivelBateria(promise: Promise) {
        try {
            promise.resolve(obterNivelBateriaReal())
        } catch (e: Exception) {
            promise.reject("ERRO_BATERIA", e)
        }
    }
}
```

```tsx
// Lado JavaScript — API legada
import { NativeModules } from 'react-native';
const { BateriaModule } = NativeModules;

async function obterNivelBateria(): Promise<number> {
  return await BateriaModule.obterNivelBateria();
}
```

Leitura do fluxo: `getName()` define o nome pelo qual o módulo é encontrado no JavaScript (`BateriaModule`); a anotação `@ReactMethod` expõe o método; o parâmetro `Promise` é o canal de resposta, pelo qual o código nativo conclui a operação com sucesso (`resolve`) ou com falha (`reject`, que inclui um código de erro). No lado JavaScript, a `Promise` devolvida é aguardada com `await`, e a rejeição se manifesta como exceção capturável com `try/catch`. Esse mecanismo é equivalente ao par `invokeMethod`/`result.success` do `MethodChannel` do Flutter (Aula 14), mas o módulo nativo recebe um nome de módulo e métodos individuais, em vez de um canal com um único manipulador de mensagens.

> **Observação de arquitetura**: assim como o canal de plataforma do Flutter, um módulo nativo é a fronteira formal entre o código de aplicação (JavaScript) e o sistema operacional. Deve ser tratado como uma dependência externa isolável, e não espalhado livremente pelo código de domínio, o que retoma o princípio de isolamento de framework que será formalizado na Aula 20. Na prática, encapsula-se a chamada em uma função ou classe de dados (como `obterNivelBateria` acima), de modo que o restante do aplicativo dependa dessa função, e não do módulo nativo diretamente.

## 6. Exemplo real: por que apps de streaming usam deep links de push

Aplicativos de streaming de conteúdo, ao enviar a notificação "Novo episódio disponível", usam a mesma técnica discutida na Aula 14 para o Flutter. O fluxo reúne os conceitos da aula:

1. A notificação carrega um identificador de conteúdo.
2. O `linking` do React Navigation traduz o identificador em navegação direta à tela do episódio (§3).
3. A pilha é construída de forma que "voltar" leve a um estado coerente.
4. Se o usuário não estiver autenticado, a renderização condicional (§4) o conduz primeiro à autenticação.

Sem esse mecanismo, o usuário tocaria na notificação e cairia na tela inicial, precisando buscar manualmente o conteúdo anunciado, uma fricção que reduz a taxa de conversão de notificações em produtos reais.

## Síntese da aula

| Conceito Flutter (Aula 14) | Equivalente React Native | Problema que resolve |
|---|---|---|
| `Navigator`/`go_router` | `Stack Navigator`/React Navigation | Registro e deslocamento entre telas |
| `PopScope` | Ouvinte de `beforeRemove` | Perda de dados ao voltar; coerência com a pilha nativa |
| Deep link declarativo (`go_router` + manifesto) | `linking` + `scheme` no `app.json` | Abertura em tela de destino sem pilha de retorno |
| `redirect` por sessão | Renderização condicional de navegadores | Verificação de autenticação repetida em cada ponto |
| Canal de plataforma (`MethodChannel`) | Módulo nativo (Native Module/Turbo Module) | Código de aplicação sem acesso às APIs do Android |

## Leitura recomendada

- Documentação oficial: [React Navigation](https://reactnavigation.org/) e [Native Modules](https://reactnative.dev/docs/native-modules-intro).
