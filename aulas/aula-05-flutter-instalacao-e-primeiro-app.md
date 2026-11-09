# Aula 5 — Criar e rodar um app Flutter no Windows (VS Code + emulador Android)

Roteiro passo a passo para criar o app de exemplo do Flutter (o "contador": um botão **+** que soma 1 a cada toque) e executá-lo em um emulador Android.

> **Tempo estimado:** 1h30 a 2h na primeira vez, porque os downloads são grandes (somando tudo, cerca de 10 GB).
> **Requisitos da máquina:** Windows 10/11 64 bits, 8 GB de RAM (16 GB recomendado), 20 GB livres em disco e virtualização habilitada na BIOS (ver a seção [Problemas comuns](#problemas-comuns)).

---

## 1. O que instalar

| # | Programa | Para que serve |
|---|----------|----------------|
| 1 | **Git** | Usado pelo Flutter para se atualizar |
| 2 | **VS Code** | Editor de código |
| 3 | **Flutter SDK** | Framework e ferramentas de linha de comando (`flutter`) |
| 4 | **Android Studio** | Fornece o Android SDK e o emulador (não é utilizado para programar) |
| 5 | **JDK 21** | Java usado para compilar a parte Android do app |

O modo mais rápido é utilizar o **winget** (já incluído no Windows 11). Abre-se o **PowerShell** e executam-se os comandos:

```powershell
winget install --id Git.Git -e
winget install --id Microsoft.VisualStudioCode -e
winget install --id Google.AndroidStudio -e
winget install --id Microsoft.OpenJDK.21 -e
```

Após a instalação, é necessário **fechar e abrir o PowerShell de novo** para que os novos programas sejam reconhecidos.

### 1.1 Flutter SDK

1. Baixar o ZIP do Flutter (canal *stable*) para Windows em: https://docs.flutter.dev/install/archive
2. Criar a pasta `C:\dev` e extrair o ZIP dentro dela. O resultado deve ser `C:\dev\flutter\bin\flutter.bat`.

> ⚠️ **Não** se deve colocar o Flutter (nem os projetos) em `C:\Program Files`, em pastas com espaço ou acento no nome, ou dentro do **OneDrive** (a Área de Trabalho e os Documentos costumam ficar no OneDrive). A sincronização e os caminhos com espaço causam erros de build.

### 1.2 Colocar o Flutter no PATH

1. Menu Iniciar → digitar **"variáveis de ambiente"** → abrir **"Editar as variáveis de ambiente para sua conta"**.
2. Em **Variáveis de usuário**, selecionar **Path** → **Editar** → **Novo** e adicionar:
   ```
   C:\dev\flutter\bin
   ```
3. Clicar em **OK** em todas as janelas, **fechar e abrir o PowerShell** e testar:
   ```powershell
   flutter --version
   ```

---

## 2. Configurar o Android Studio (SDK e emulador)

### 2.1 Primeira execução

1. Abrir o **Android Studio** e seguir o assistente (**Standard**), que baixa o Android SDK, as Platform-Tools e o emulador.
2. Na tela inicial, abrir **More Actions → SDK Manager → aba SDK Tools**, marcar **Android SDK Command-line Tools (latest)** e clicar em **Apply**.

### 2.2 Criar o emulador

1. Na tela inicial: **More Actions → Virtual Device Manager**.
2. Clicar em **+ (Create Virtual Device)**, escolher **Medium Phone** (ou Pixel) → **Next**.
3. Escolher a imagem do sistema mais recente (baixando-a, se necessário) → **Next** → **Finish**.
4. Clicar em ▶ para ligar o emulador e conferir se o Android inicia.

---

## 3. Configurar o Flutter

No PowerShell:

```powershell
# Usar o JDK 21 para compilar (evita erro com o Java do Android Studio)
flutter config --jdk-dir="C:\Program Files\Microsoft\jdk-21.0.12.101-hotspot"

# Aceitar as licenças do Android (responda "y" para todas)
flutter doctor --android-licenses

# Verificar se está tudo certo
flutter doctor
```

> O nome exato da pasta do JDK pode mudar conforme a versão. Convém conferir o conteúdo de `C:\Program Files\Microsoft\` e utilizar a pasta que começa com `jdk-21`.

O resultado esperado do `flutter doctor` é ✓ (verde) em **Flutter**, **Android toolchain** e **VS Code**. Os itens **Visual Studio** (para apps Windows desktop) e **Chrome** podem ficar com aviso, porque não são necessários para Android.

---

## 4. Configurar o VS Code

1. Abrir o VS Code → **Extensões** (`Ctrl+Shift+X`).
2. Instalar a extensão **Flutter** (da Dart Code), que instala junto a extensão **Dart**.
3. Reiniciar o VS Code.

---

## 5. Criar o projeto

### Opção A: pelo VS Code

1. Pressionar `Ctrl+Shift+P` → digitar **Flutter: New Project** → **Application**.
2. Escolher a pasta (ex.: `C:\dev\projetos`).
3. Digitar o nome do projeto, por exemplo `meu_app`, usando só **letras minúsculas, números e `_`**.

### Opção B: pelo terminal

```powershell
mkdir C:\dev\projetos
cd C:\dev\projetos
flutter create meu_app
cd meu_app
code .
```

O código principal fica em **`lib/main.dart`**.

---

## 6. Rodar o app no emulador

### 6.1 Ligar o emulador

Pelo **Device Manager** do Android Studio (▶) ou pelo terminal:

```powershell
flutter emulators                         # lista os emuladores criados
flutter emulators --launch Medium_Phone   # liga o emulador (use o Id da lista)
flutter devices                           # confere se o emulador aparece
```

Aguardar o Android terminar de iniciar (tela inicial do celular aparecendo).

### 6.2 Rodar

**No VS Code (recomendado):**
1. Na barra inferior (canto direito), clicar no nome do dispositivo e escolher o emulador.
2. Abrir `lib/main.dart` e pressionar **F5** (ou **Run → Start Debugging**).

**No terminal:**
```powershell
flutter run
```

> A **primeira** execução demora de 3 a 10 minutos, porque o Gradle baixa dependências. As próximas levam segundos.

---

## 7. Hot reload: mudar o app sem reiniciar

**Hot reload** aplica as mudanças do código no app que já está rodando, em cerca de 1 segundo, **sem perder o estado** (o número do contador continua o mesmo).

**Exemplo:**
1. Com o app rodando, tocar no botão **+** algumas vezes (ex.: até chegar em 5).
2. Em `lib/main.dart`, trocar a cor do tema:
   ```dart
   colorScheme: .fromSeed(seedColor: Colors.deepPurple),
   ```
   por:
   ```dart
   colorScheme: .fromSeed(seedColor: Colors.green),
   ```
3. Salvar (`Ctrl+S`). A cor muda e o contador **continua em 5**.
4. Em seguida, fazer um **hot restart** (`Ctrl+Shift+F5` no VS Code ou `R` no terminal). O contador volta a 0.

| Ação | VS Code | Terminal | Mantém o estado? |
|------|---------|----------|------------------|
| Hot reload | Salvar (`Ctrl+S`) | `r` | ✅ Sim |
| Hot restart | `Ctrl+Shift+F5` | `R` | ❌ Não |
| Parar o app | `Shift+F5` | `q` | — |

O **hot restart** é indicado quando houver mudança em `main()`, `initState()` ou variáveis globais. Quando se adicionam pacotes no `pubspec.yaml`, é necessário parar o app e executá-lo de novo.

---

## 8. Comandos úteis (resumo)

```powershell
flutter --version                 # versão instalada
flutter doctor                    # diagnóstico do ambiente
flutter doctor -v                 # diagnóstico detalhado (mostra versão do Java etc.)
flutter create nome_do_app        # cria um projeto
flutter emulators                 # lista emuladores
flutter emulators --launch <id>   # liga um emulador
flutter devices                   # lista dispositivos conectados
flutter run                       # compila e roda o app
flutter run -d emulator-5554      # roda em um dispositivo específico
flutter pub get                   # baixa os pacotes do pubspec.yaml
flutter clean                     # apaga arquivos de build (use quando algo "travar")
```

---

## Problemas comuns

### Emulador aparece como `offline` (`Device emulator-5554 is offline`)
1. Reiniciar o ADB:
   ```powershell
   & "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" kill-server
   & "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" start-server
   ```
2. Se não resolver, fazer um **Cold Boot**: fechar o emulador → Device Manager → **⋮ → Cold Boot Now**.

### Build falha com `What went wrong: 25.0.3` (ou outro número de versão do Java)
O Flutter está usando um Java novo demais para o Gradle do projeto (o Java que vem com o Android Studio). O passo da seção 3 resolve o problema:
```powershell
flutter config --jdk-dir="C:\Program Files\Microsoft\jdk-21.0.12.101-hotspot"
```
Em seguida, executa-se `flutter run` de novo. No VS Code, o editor deve ser reiniciado.

### `flutter` não é reconhecido como comando
O PATH não foi configurado, ou o terminal estava aberto antes da configuração. Revisar a seção 1.2 e **abrir um novo terminal** (no VS Code, fechar e reabrir o VS Code).

### `Android license status unknown` no `flutter doctor`
Executar `flutter doctor --android-licenses` e aceitar tudo com `y`. Se ocorrer erro, instalar as **Android SDK Command-line Tools** (seção 2.1).

### Emulador não abre ou fica muito lento
- Confirmar que a **virtualização** está ativada: Gerenciador de Tarefas → aba **Desempenho → CPU** → "Virtualização: **Habilitado**". Se estiver desabilitada, ativá-la na BIOS (Intel VT-x / AMD SVM).
- Ativar o **Windows Hypervisor Platform**: Menu Iniciar → "Ativar ou desativar recursos do Windows" → marcar **Plataforma do Hipervisor do Windows** → reiniciar o PC.
- Fechar outros programas pesados. O emulador usa de 2 a 4 GB de RAM.

### Erro de build estranho depois de mover ou renomear o projeto
```powershell
flutter clean
flutter pub get
flutter run
```
