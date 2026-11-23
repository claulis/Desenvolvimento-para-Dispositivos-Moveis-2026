# Aula 25 — Android com Capacitor: aplicações web em contêiner nativo

**Unidade:** V — Estilos arquiteturais, renderização e análise comparativa
**Referência principal:** documentação oficial do Capacitor para Android — https://capacitorjs.com/docs/android

## Objetivos da aula

- Definir o Capacitor e situá-lo em relação às abordagens já estudadas (Flutter e React Native).
- Descrever a arquitetura de uma aplicação Capacitor no Android: WebView, ponte nativa e plugins.
- Apresentar os requisitos, a instalação e a configuração de um projeto Capacitor para Android.
- Construir, passo a passo, uma aplicação *Hello World* executada em emulador ou aparelho Android.

---

## 1. O que é o Capacitor

O **Capacitor** é um *runtime* nativo multiplataforma, mantido pela Ionic, que permite empacotar uma aplicação web (HTML, CSS e JavaScript/TypeScript) como aplicação nativa para Android, iOS e web, com acesso às APIs do dispositivo por meio de uma ponte entre o código JavaScript e o código nativo.

> **Definição — Aplicação híbrida (hybrid app)**: aplicação cuja interface é implementada com tecnologias web e executada dentro de um componente de navegador embutido (WebView) em um projeto nativo, que a distribui pelas lojas e lhe concede acesso a recursos do sistema operacional.

O Capacitor é independente de *framework* de interface: a camada web pode ser escrita em JavaScript puro, Angular, React, Vue, Svelte ou qualquer outra ferramenta que produza um diretório de arquivos estáticos. É sucessor conceitual do Apache Cordova, com o qual mantém compatibilidade parcial de plugins, mas difere dele em um ponto central: o projeto nativo (a pasta `android/`) é tratado como **código-fonte versionado** do aplicativo, e não como artefato gerado e descartável.

### 1.1 Comparação com as abordagens estudadas

| Aspecto | Flutter | React Native | Capacitor |
|---|---|---|---|
| Linguagem da interface | Dart | JavaScript/TypeScript (JSX) | HTML, CSS, JavaScript/TypeScript |
| Renderização | Motor próprio desenha cada pixel | Componentes nativos reais (Fabric) | Motor do navegador (WebView do sistema) |
| Acesso a APIs nativas | Canais de plataforma | TurboModules / Expo Modules | Plugins Capacitor (ponte JS ↔ nativo) |
| Reaproveitamento de código web | Nenhum | Lógica e parte do ecossistema | Integral (a mesma base roda no navegador) |
| Projeto Android | Gerado e mantido pelo *framework* | Gerado e mantido pelo *framework* | Projeto Android Studio comum, versionado e editável |

A consequência arquitetural é direta: no Capacitor, a qualidade da interface (fluidez, aderência ao Material Design, acessibilidade) depende da qualidade da aplicação web e do desempenho do WebView do aparelho, e não de um conjunto de componentes nativos.

---

## 2. O que o Capacitor faz

Em termos funcionais, o Capacitor fornece:

1. **Empacotamento**: copia os arquivos estáticos da aplicação web para dentro do projeto Android, que é compilado em APK ou AAB pelo Gradle.
2. **Contêiner de execução**: uma `Activity` nativa que hospeda um WebView configurado para carregar esses arquivos a partir de um servidor local interno (por padrão, `https://localhost`), e não do sistema de arquivos com o esquema `file://`.
3. **Ponte nativa (bridge)**: canal de mensagens que permite ao JavaScript invocar métodos implementados em Java/Kotlin e receber respostas assíncronas (Promises) e eventos.
4. **Plugins oficiais**: APIs prontas para câmera, sistema de arquivos, geolocalização, notificações, preferências, rede, informações do dispositivo, entre outras, distribuídas como pacotes npm (`@capacitor/camera`, `@capacitor/device`, etc.).
5. **Ferramenta de linha de comando (CLI)**: comandos `npx cap ...` que criam, sincronizam, abrem e executam o projeto nativo.

---

## 3. Arquitetura

### 3.1 Visão em camadas

```
┌──────────────────────────────────────────────────────────┐
│  Aplicação web (HTML/CSS/JS) — diretório webDir          │
│  index.html, código do framework, chamadas a plugins     │
├──────────────────────────────────────────────────────────┤
│  @capacitor/core (JavaScript)                            │
│  objeto global Capacitor, registerPlugin, Promises       │
├────────────────────── PONTE (bridge) ────────────────────┤
│  Capacitor Android (Java)                                │
│  BridgeActivity → Bridge → WebView                       │
│  roteamento de chamadas para classes @CapacitorPlugin    │
├──────────────────────────────────────────────────────────┤
│  Plugins nativos (Java/Kotlin)                           │
│  Camera, Filesystem, Geolocation, plugins próprios       │
├──────────────────────────────────────────────────────────┤
│  Android SDK / sistema operacional                       │
└──────────────────────────────────────────────────────────┘
```

### 3.2 Componentes

- **`BridgeActivity`**: `Activity` fornecida pela biblioteca `com.getcapacitor`. A `MainActivity` do projeto apenas a estende; é ela que cria o WebView, instancia a ponte e registra os plugins.
- **`Bridge`**: objeto Java que recebe as mensagens vindas do JavaScript, localiza o plugin e o método correspondentes, executa-os e devolve o resultado ao WebView.
- **WebView**: componente `android.webkit.WebView`, cuja implementação é o *Android System WebView* (baseado no Chromium) instalado no aparelho e atualizado pela Play Store, independentemente da versão do Android.
- **Plugins**: classes Java/Kotlin anotadas com `@CapacitorPlugin`, cujos métodos públicos anotados com `@PluginMethod` tornam-se acessíveis ao JavaScript. Do lado web, cada plugin é exposto por um *proxy* criado com `registerPlugin`.
- **`capacitor.config.json`**: cópia da configuração do projeto colocada nos *assets* do Android, lida pela ponte durante a inicialização.

### 3.3 Fluxo de uma chamada nativa

1. O código web chama, por exemplo, `Device.getInfo()`.
2. O *proxy* do plugin, em `@capacitor/core`, serializa a chamada (nome do plugin, método, argumentos e um identificador de *callback*) em JSON e a envia ao lado nativo por uma interface JavaScript injetada no WebView.
3. A `Bridge` localiza o plugin `Device` e executa o método `getInfo` em uma *thread* de segundo plano.
4. O plugin consulta as APIs do Android e resolve a chamada com `call.resolve(dados)` ou a rejeita com `call.reject(mensagem)`.
5. A `Bridge` devolve o resultado ao WebView, que resolve a Promise original no JavaScript.

Toda comunicação atravessa a ponte de forma **assíncrona** e com dados **serializáveis em JSON**. Esse custo de serialização é desprezível para chamadas eventuais (ler a localização, tirar uma foto), mas é relevante para tráfego de alta frequência, situação em que a lógica deve permanecer inteiramente de um dos lados.

---

## 4. Como funciona o ciclo de desenvolvimento

O fluxo de trabalho separa explicitamente a construção da aplicação web da construção do aplicativo nativo:

```
código web ──(build do framework web)──► webDir (ex.: dist/ ou www/)
                                            │
                                   npx cap sync android
                                            │
                                            ▼
            android/app/src/main/assets/public/   (cópia dos arquivos web)
            android/app/src/main/assets/capacitor.config.json
            dependências Gradle dos plugins instalados
                                            │
                     npx cap run android  ou  Android Studio (Run)
                                            │
                                            ▼
                                   APK instalado no dispositivo
```

| Comando | Função |
|---|---|
| `npx cap init` | Cria o arquivo `capacitor.config.ts` (ou `.json`) com nome, identificador e diretório web. |
| `npx cap add android` | Gera o projeto Android nativo na pasta `android/`. |
| `npx cap copy android` | Copia apenas os arquivos web e a configuração para o projeto Android. |
| `npx cap sync android` | Executa `copy` e, adicionalmente, atualiza as dependências nativas dos plugins. |
| `npx cap open android` | Abre a pasta `android/` no Android Studio. |
| `npx cap run android` | Sincroniza, compila e instala o aplicativo em um emulador ou aparelho escolhido. |
| `npx cap doctor` | Diagnostica versões e configuração do ambiente. |

Toda alteração no código web exige novo *build* web seguido de `npx cap copy` (ou `sync`); toda instalação ou remoção de plugin exige `npx cap sync`.

---

## 5. Instalação

### 5.1 Requisitos (Capacitor 8)

| Item | Versão / observação |
|---|---|
| Node.js | 22 ou superior (exigido pelo `@capacitor/cli`) |
| Android Studio | Versão estável recente, com Android SDK e emulador configurados (ver Aula 5) |
| JDK | 21, o mesmo utilizado na Aula 5 (o Android Gradle Plugin 8.13 exige no mínimo JDK 17) |
| Android SDK | `compileSdkVersion` e `targetSdkVersion` 36 |
| Versão mínima do Android | `minSdkVersion` 24 (Android 7.0) |
| Android System WebView | Versão atualizada no aparelho ou emulador |

A configuração do Android Studio, do SDK, do emulador e do JDK segue integralmente o roteiro da [Aula 5](./aula-05-flutter-instalacao-e-primeiro-app.md), seções 1 e 2. O Node.js pode ser instalado no Windows com:

```powershell
winget install --id OpenJS.NodeJS.LTS -e
node --version
```

### 5.2 Pacotes

Em um projeto web existente (com `package.json`), instalam-se três pacotes:

```bash
npm install @capacitor/core
npm install -D @capacitor/cli
npm install @capacitor/android
```

- `@capacitor/core`: *runtime* JavaScript utilizado pela aplicação web.
- `@capacitor/cli`: ferramenta de linha de comando, necessária apenas em desenvolvimento.
- `@capacitor/android`: biblioteca nativa Android e modelo do projeto.

---

## 6. Configuração

### 6.1 Arquivo `capacitor.config.ts`

Criado por `npx cap init`, concentra a configuração comum a todas as plataformas:

```ts
import type { CapacitorConfig } from '@capacitor/cli';

const config: CapacitorConfig = {
  appId: 'br.edu.exemplo.olacapacitor',   // identificador único (applicationId no Android)
  appName: 'Olá Capacitor',               // nome exibido sob o ícone
  webDir: 'www',                          // diretório com os arquivos web prontos
  android: {
    // opções específicas do Android, por exemplo:
    // allowMixedContent: false,
    // webContentsDebuggingEnabled: true,
  },
};

export default config;
```

| Campo | Significado |
|---|---|
| `appId` | Identificador em notação de domínio invertido; torna-se o `applicationId` do Gradle e não deve ser alterado após a publicação. |
| `appName` | Nome do aplicativo exibido ao usuário. |
| `webDir` | Diretório de saída do *build* web (`dist`, `build`, `www`, conforme o *framework*). |
| `server.url` | Endereço de um servidor de desenvolvimento para recarga ao vivo; deve ser removido no *build* de produção. |
| `android.*` | Opções do WebView e da compilação específicas do Android. |

### 6.2 Estrutura do projeto Android gerado

```
android/
├── app/
│   ├── build.gradle
│   └── src/main/
│       ├── AndroidManifest.xml
│       ├── assets/
│       │   ├── capacitor.config.json      ← gerado por sync/copy
│       │   └── public/                    ← cópia do webDir
│       ├── java/br/edu/exemplo/olacapacitor/
│       │   └── MainActivity.java
│       └── res/                           ← ícones, strings, temas
├── build.gradle
├── variables.gradle                       ← versões de SDK e bibliotecas
└── settings.gradle
```

A `MainActivity` gerada é mínima, pois todo o comportamento reside em `BridgeActivity`:

```java
package br.edu.exemplo.olacapacitor;

import com.getcapacitor.BridgeActivity;

public class MainActivity extends BridgeActivity {}
```

O arquivo `variables.gradle` centraliza as versões do SDK utilizadas pelo projeto e pelos plugins:

```groovy
ext {
    minSdkVersion = 24
    compileSdkVersion = 36
    targetSdkVersion = 36
    // ... versões das bibliotecas AndroidX
}
```

### 6.3 Permissões

O modelo inclui apenas a permissão de Internet no `AndroidManifest.xml`. Plugins que dependem de recursos protegidos documentam as permissões que devem ser acrescentadas manualmente, por exemplo, para geolocalização:

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
```

A declaração no manifesto é condição necessária, mas não suficiente: permissões perigosas continuam sujeitas à solicitação em tempo de execução, que os plugins oficiais expõem por métodos como `checkPermissions()` e `requestPermissions()`.

### 6.4 Depuração do WebView

Com o aplicativo em execução em modo de depuração, o conteúdo do WebView pode ser inspecionado no Chrome do computador, em `chrome://inspect`, com acesso ao console, à árvore DOM, à rede e ao perfilador de desempenho. O código nativo, por sua vez, é depurado no Android Studio (Logcat e *breakpoints* em Java/Kotlin).

---

## 7. Tutorial: *Hello World* com Capacitor no Android

O tutorial utiliza JavaScript puro, sem *framework* nem empacotador, de modo que a única tecnologia nova seja o próprio Capacitor. Os comandos são apresentados para PowerShell, mas são idênticos em Linux e macOS.

### Passo 1 — Criar o projeto web

```powershell
mkdir C:\dev\ola-capacitor
cd C:\dev\ola-capacitor
npm init -y
mkdir www
```

O caminho segue a mesma recomendação da Aula 5: sem espaços, sem acentos e fora do OneDrive.

### Passo 2 — Criar a página inicial

Cria-se o arquivo `www/index.html`:

```html
<!DOCTYPE html>
<html lang="pt-BR">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
  <title>Olá Capacitor</title>
  <style>
    body {
      font-family: system-ui, sans-serif;
      display: flex; flex-direction: column;
      align-items: center; justify-content: center;
      min-height: 100vh; margin: 0;
      padding: env(safe-area-inset-top) 16px env(safe-area-inset-bottom);
      box-sizing: border-box;
    }
    button { font-size: 1.1rem; min-height: 48px; padding: 0 24px; }
  </style>
</head>
<body>
  <h1>Olá, Capacitor!</h1>
  <p id="plataforma">Plataforma: verificando…</p>
  <button id="botao" type="button">Toque aqui</button>
  <p id="contador" aria-live="polite">Toques: 0</p>

  <script>
    // O objeto global Capacitor é injetado pelo runtime nativo no WebView.
    // No navegador comum ele não existe, e a página informa "web".
    const plataforma = window.Capacitor ? window.Capacitor.getPlatform() : 'web';
    document.getElementById('plataforma').textContent = 'Plataforma: ' + plataforma;

    let toques = 0;
    document.getElementById('botao').addEventListener('click', () => {
      toques++;
      document.getElementById('contador').textContent = 'Toques: ' + toques;
    });
  </script>
</body>
</html>
```

A página pode ser aberta diretamente no navegador do computador; nesse caso exibirá `Plataforma: web`, o que evidencia que a mesma base de código executa fora do contêiner nativo.

### Passo 3 — Instalar o Capacitor

```powershell
npm install @capacitor/core
npm install -D @capacitor/cli
npm install @capacitor/android
```

### Passo 4 — Inicializar a configuração

```powershell
npx cap init "Olá Capacitor" br.edu.exemplo.olacapacitor --web-dir www
```

O comando cria `capacitor.config.ts` com os valores de `appName`, `appId` e `webDir` informados.

### Passo 5 — Adicionar a plataforma Android

```powershell
npx cap add android
```

É criada a pasta `android/`, contendo um projeto Android Studio completo, e os arquivos de `www/` são copiados para `android/app/src/main/assets/public/`.

### Passo 6 — Sincronizar

```powershell
npx cap sync android
```

Neste projeto não há plugins adicionais, mas a execução de `sync` após qualquer alteração em `www/` ou na configuração é o procedimento padrão.

### Passo 7 — Executar no emulador

Com o emulador criado na Aula 5 em execução (ou um aparelho conectado com a depuração USB ativada):

```powershell
npx cap run android
```

A CLI lista os dispositivos disponíveis, compila o projeto com o Gradle e instala o aplicativo. A primeira compilação é demorada, pois o Gradle baixa suas dependências.

Alternativamente, o projeto pode ser aberto e executado pelo Android Studio:

```powershell
npx cap open android
```

Após a indexação do projeto, seleciona-se o dispositivo na barra de ferramentas e aciona-se **Run ▶**.

### Passo 8 — Verificar o resultado

O aplicativo **Olá Capacitor** é instalado e aberto no dispositivo, exibindo:

- o título *Olá, Capacitor!*;
- a linha `Plataforma: android`, que confirma a execução dentro do contêiner nativo e a disponibilidade do objeto `Capacitor` injetado pela ponte;
- o botão que incrementa o contador de toques.

### Passo 9 — Ciclo de alteração

Para alterar o aplicativo, edita-se `www/index.html` e repete-se:

```powershell
npx cap copy android
npx cap run android
```

Alterações feitas apenas na pasta `android/` (manifesto, ícones, código Java) dispensam o `copy`, mas exigem nova compilação.

### Passo 10 — Gerar o APK de depuração

```powershell
cd android
.\gradlew.bat assembleDebug
```

O arquivo é gerado em `android/app/build/outputs/apk/debug/app-debug.apk`. A geração de AAB assinado para publicação é feita no Android Studio, em **Build → Generate Signed App Bundle / APK**.

---

## 8. Síntese

- O Capacitor empacota uma aplicação web em um projeto Android nativo, executando-a em um WebView hospedado por `BridgeActivity`.
- O acesso a recursos do dispositivo ocorre por plugins, através de uma ponte assíncrona baseada em mensagens JSON.
- O projeto `android/` é código-fonte do aplicativo: é versionado, editado no Android Studio e compilado pelo Gradle.
- O ciclo de desenvolvimento consiste em construir a aplicação web, sincronizá-la com `npx cap sync` e executar com `npx cap run android`.
- Em comparação com Flutter e React Native, o Capacitor maximiza o reaproveitamento de código web, ao custo de depender do motor do navegador para renderização e desempenho da interface.

## Referências

- IONIC. *Capacitor Documentation — Android*. Disponível em: https://capacitorjs.com/docs/android.
- IONIC. *Capacitor Documentation — Getting Started*. Disponível em: https://capacitorjs.com/docs/getting-started.
- IONIC. *Capacitor Documentation — Configuration*. Disponível em: https://capacitorjs.com/docs/config.
- ANDROID DEVELOPERS. *Build web apps in WebView*. Disponível em: https://developer.android.com/develop/ui/views/layout/webapps/webview.
