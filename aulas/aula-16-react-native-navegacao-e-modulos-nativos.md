# Aula 16 — React Native: navegação e módulos nativos

**Carga horária:** 4h
**Unidade:** IV — Arquitetura de software em React Native

## Objetivos da aula

- Implementar navegação, rotas e ligações profundas com React Navigation.
- Relacionar a navegação React Native à pilha de retorno do Android.
- Explicar o papel dos módulos nativos na integração entre JavaScript e código específico do Android.

## 1. React Navigation

> **Definição — React Navigation**: biblioteca de referência para navegação em aplicativos React Native, que organiza rotas em navegadores (*stack*, *tab*, *drawer*) componíveis, cada um responsável por um padrão de navegação específico, sendo o `Stack Navigator` o análogo direto ao empilhamento estudado na Aula 2.

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

```tsx
// Navegar para o detalhe, empilhando a nova tela
navigation.navigate('DetalhePedido', { id: pedido.id });

// Substituir a tela atual (sem deixá-la na pilha) — equivalente a
// pushReplacement no Flutter (Aula 12), usado após confirmação de formulário
navigation.replace('PedidoConfirmado');
```

## 2. Relação com a pilha de retorno do Android

O `Stack Navigator` do React Navigation é construído justamente para espelhar o comportamento de pilha de retorno nativo do Android (Aula 2): cada `navigate` empilha uma tela, e o gesto/botão voltar do sistema desempilha automaticamente a tela do topo, sem necessidade de código adicional para essa integração básica. Para interceptar a tentativa de voltar (ex.: confirmar descarte de formulário), usa-se o hook `useFocusEffect` combinado ao evento `beforeRemove` da navegação:

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

Essa comparação é diretamente paralela ao `PopScope` do Flutter, estudado na Aula 12 — o mesmo requisito de projeto (não perder dados do usuário sem confirmação), resolvido com uma API distinta em cada framework.

> **Simplificação**: o evento `beforeRemove` já é escopado à tela ativa por natureza — envolvê-lo em `useFocusEffect`, como acima, adiciona uma camada de indireção sem ganho real neste caso; um `useEffect` simples, com a mesma lista de dependências, é suficiente e mais direto.

## 3. Ligações profundas (deep links)

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

Assim como o `go_router` do Flutter (Aula 12), o React Navigation permite declarar deep links de forma centralizada, mapeando uma URL (`meuapp://pedido/42` ou `https://meuapp.com.br/pedido/42`) diretamente a uma tela e seus parâmetros — o mesmo requisito de reconstrução de pilha coerente ao abrir por notificação se aplica aqui: o app deve inserir os ancestrais lógicos da tela de destino, para que o botão voltar leve a um estado esperado, e não a um vazio.

Assim como na Aula 12, a configuração em JavaScript não basta sozinha: em um projeto Expo, o esquema declarado acima precisa também estar registrado em `app.json`:

```json
{
  "expo": {
    "scheme": "meuapp"
  }
}
```

E testado com o mesmo comando `adb` da Aula 12:

```bash
adb shell am start -W -a android.intent.action.VIEW -d "meuapp://pedido/42"
```

## 4. Fluxo de sessão

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

Trocar toda a árvore de navegadores com base no estado de autenticação (em vez de navegar manualmente para a tela de login a partir de cada ponto possível) é a abordagem recomendada — o mesmo princípio de "navegação como função do estado" discutido na Aula 12 a respeito da navegação declarativa.

## 5. Módulos nativos (native modules)

> **Definição — Módulo nativo (native module)**: código escrito em Kotlin/Java (para Android) ou Swift/Objective-C (para iOS) exposto ao JavaScript como uma API chamável, usado quando uma funcionalidade não está disponível em uma biblioteca JavaScript existente ou exige acesso direto a uma API do sistema operacional — o análogo direto do canal de plataforma do Flutter, estudado na Aula 12.

Com a Nova Arquitetura do React Native (TurboModules, Aula 13), a comunicação entre JavaScript e módulos nativos passa a usar JSI diretamente, permitindo chamadas síncronas e tipadas, análogas em espírito à evolução que o próprio canal de plataforma do Flutter representa em relação a uma ponte assíncrona genérica.

> **API legada, mostrada por simplicidade didática**: o exemplo abaixo (`ReactContextBaseJavaModule` + `NativeModules`) é a API do modelo **Bridge antigo**, ainda amplamente encontrada em bibliotecas existentes e mais simples de introduzir em uma primeira aula. **A Nova Arquitetura resolve o mesmo problema por Codegen**: define-se uma especificação TypeScript (`NativeBateria.ts`) com a assinatura do módulo, e uma ferramenta de geração de código produz a interface tipada e o código de ponte a partir dela — eliminando o `NativeModules` não tipado do exemplo abaixo. Se o projeto usa Expo (Aula 13), a **Expo Modules API** é o caminho mais simples ainda: bem mais direta que TurboModules puro para a maioria dos casos de uso deste nível.

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

> **Observação de arquitetura**: assim como o canal de plataforma do Flutter, um módulo nativo é a fronteira formal entre o código de aplicação (JavaScript) e o sistema operacional — e deve ser tratado como uma dependência externa isolável, não espalhada livremente pelo código de domínio, retomando o princípio de isolamento de framework que será formalizado na Aula 17.

## 6. Exemplo real: por que apps de streaming usam deep links de push

Aplicativos de streaming de conteúdo, ao enviar uma notificação "Novo episódio disponível", usam a mesma técnica discutida na Aula 12 para Flutter: a notificação carrega um identificador de conteúdo, e o `linking` do React Navigation traduz isso em navegação direta à tela do episódio — sem esse mecanismo, o usuário tocaria na notificação e cairia na tela inicial, precisando buscar manualmente o conteúdo anunciado, uma fricção que reduz a taxa de conversão de notificações em produtos reais.

## Síntese da aula

| Conceito Flutter (Aula 12) | Equivalente React Native |
|---|---|
| `Navigator`/`go_router` | `Stack Navigator`/React Navigation |
| `PopScope` | `beforeRemove` listener |
| Deep link declarativo | `linking` config |
| Canal de plataforma | Módulo nativo (Native Module/Turbo Module) |

## Leitura recomendada

- Documentação oficial: [React Navigation](https://reactnavigation.org/) e [Native Modules](https://reactnative.dev/docs/native-modules-intro).

## Atividade da aula

**Entrega 2 — Módulo em React Native (peso 20%)**: cada equipe reimplementa, em React Native, o mesmo módulo entregue em Flutter na Avaliação 2 (Aula 12), com equivalência de arquitetura (camadas, repositório, gerenciamento de estado justificado) e de interface (mesma responsividade, mesma navegação com deep link, mesmo comportamento off-line). Use o [`recursos/checklist-paridade.md`](../recursos/checklist-paridade.md) para verificar a equivalência antes de entregar — mesmas rotas, mesmo comportamento offline, mesmos três estados de interface — de forma que a comparação da Aula 20 seja sobre arquitetura, não sobre "a equipe implementou coisas diferentes em cada plataforma". A comparação ponto a ponto entre as duas implementações do mesmo módulo é o que sustenta a análise da Unidade V.
