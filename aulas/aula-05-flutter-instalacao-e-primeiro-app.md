# Aula 5 — Criar e rodar um app Flutter no Windows (VS Code + emulador Android)

Roteiro passo a passo para criar o app de exemplo do Flutter (o "contador": um botão **+** que soma 1 a cada toque) e rodá-lo em um emulador Android.

> **Tempo estimado:** 1h30 a 2h na primeira vez, porque os downloads são grandes (somando tudo, cerca de 10 GB).
> **Requisitos da máquina:** Windows 10/11 64 bits, 8 GB de RAM (16 GB recomendado), 20 GB livres em disco e virtualização habilitada na BIOS (veja a seção [Problemas comuns](#problemas-comuns)).

---

## 1. O que instalar

| # | Programa | Para que serve |
|---|----------|----------------|
| 1 | **Git** | Usado pelo Flutter para se atualizar |
| 2 | **VS Code** | Editor de código |
| 3 | **Flutter SDK** | Framework e ferramentas de linha de comando (`flutter`) |
| 4 | **Android Studio** | Fornece o Android SDK e o emulador (não vamos programar nele) |
| 5 | **JDK 21** | Java usado para compilar a parte Android do app |

O jeito mais rápido é usar o **winget** (já vem no Windows 11). Abra o **PowerShell** e rode:

```powershell
winget install --id Git.Git -e
winget install --id Microsoft.VisualStudioCode -e
winget install --id Google.AndroidStudio -e
winget install --id Microsoft.OpenJDK.21 -e
```

Depois de instalar, **feche e abra o PowerShell de novo** para ele reconhecer os novos programas.

### 1.1 Flutter SDK

1. Baixe o ZIP do Flutter (canal *stable*) para Windows em: https://docs.flutter.dev/install/archive
2. Crie a pasta `C:\dev` e extraia o ZIP dentro dela. O resultado deve ser `C:\dev\flutter\bin\flutter.bat`.

> ⚠️ **Não** coloque o Flutter (nem os projetos) em `C:\Program Files`, em pastas com espaço ou acento no nome, ou dentro do **OneDrive** (a Área de Trabalho e os Documentos costumam ficar no OneDrive). A sincronização e os caminhos com espaço causam erros de build.

### 1.2 Colocar o Flutter no PATH

1. Menu Iniciar → digite **"variáveis de ambiente"** → abra **"Editar as variáveis de ambiente para sua conta"**.
2. Em **Variáveis de usuário**, selecione **Path** → **Editar** → **Novo** e adicione:
   ```
   C:\dev\flutter\bin
   ```
3. Clique em **OK** em todas as janelas, **feche e abra o PowerShell** e teste:
   ```powershell
   flutter --version
   ```

---

## 2. Configurar o Android Studio (SDK e emulador)

### 2.1 Primeira execução

1. Abra o **Android Studio** e siga o assistente (**Standard**). Ele baixa o Android SDK, as Platform-Tools e o emulador.
2. Na tela inicial, abra **More Actions → SDK Manager → aba SDK Tools**, marque **Android SDK Command-line Tools (latest)** e clique em **Apply**.

### 2.2 Criar o emulador

1. Na tela inicial: **More Actions → Virtual Device Manager**.
2. Clique em **+ (Create Virtual Device)**, escolha **Medium Phone** (ou Pixel) → **Next**.
3. Escolha a imagem do sistema mais recente (baixe se necessário) → **Next** → **Finish**.
4. Clique em ▶ para ligar o emulador e confira se o Android inicia.

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

> O nome exato da pasta do JDK pode mudar conforme a versão. Confira em `C:\Program Files\Microsoft\` e use a pasta que começa com `jdk-21`.

O resultado esperado do `flutter doctor` é ✓ (verde) em **Flutter**, **Android toolchain** e **VS Code**. Os itens **Visual Studio** (para apps Windows desktop) e **Chrome** podem ficar com aviso, porque não são necessários para Android.

---

## 4. Configurar o VS Code

1. Abra o VS Code → **Extensões** (`Ctrl+Shift+X`).
2. Instale a extensão **Flutter** (da Dart Code). Ela instala junto a extensão **Dart**.
3. Reinicie o VS Code.

---

## 5. Criar o projeto

### Opção A: pelo VS Code

1. `Ctrl+Shift+P` → digite **Flutter: New Project** → **Application**.
2. Escolha a pasta (ex.: `C:\dev\projetos`).
3. Digite o nome do projeto, por exemplo `meu_app`. Use só **letras minúsculas, números e `_`**.

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

Espere o Android terminar de iniciar (tela inicial do celular aparecendo).

### 6.2 Rodar

**No VS Code (recomendado):**
1. Na barra inferior (canto direito), clique no nome do dispositivo e escolha o emulador.
2. Abra `lib/main.dart` e aperte **F5** (ou **Run → Start Debugging**).

**No terminal:**
```powershell
flutter run
```

> A **primeira** execução demora de 3 a 10 minutos, porque o Gradle baixa dependências. As próximas levam segundos.

---

## 7. Hot reload: mudar o app sem reiniciar

**Hot reload** aplica as mudanças do código no app que já está rodando, em cerca de 1 segundo, **sem perder o estado** (o número do contador continua o mesmo).

**Exercício em sala:**
1. Com o app rodando, toque no botão **+** algumas vezes (ex.: até chegar em 5).
2. Em `lib/main.dart`, troque a cor do tema:
   ```dart
   colorScheme: .fromSeed(seedColor: Colors.deepPurple),
   ```
   por:
   ```dart
   colorScheme: .fromSeed(seedColor: Colors.green),
   ```
3. Salve (`Ctrl+S`). A cor muda e o contador **continua em 5**.
4. Agora faça um **hot restart** (`Ctrl+Shift+F5` no VS Code ou `R` no terminal). O contador volta a 0.

| Ação | VS Code | Terminal | Mantém o estado? |
|------|---------|----------|------------------|
| Hot reload | Salvar (`Ctrl+S`) | `r` | ✅ Sim |
| Hot restart | `Ctrl+Shift+F5` | `R` | ❌ Não |
| Parar o app | `Shift+F5` | `q` | — |

Use **hot restart** quando mudar `main()`, `initState()` ou variáveis globais. Quando adicionar pacotes no `pubspec.yaml`, pare o app e rode de novo.

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
1. Reinicie o ADB:
   ```powershell
   & "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" kill-server
   & "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" start-server
   ```
2. Se não resolver, faça um **Cold Boot**: feche o emulador → Device Manager → **⋮ → Cold Boot Now**.

### Build falha com `What went wrong: 25.0.3` (ou outro número de versão do Java)
O Flutter está usando um Java novo demais para o Gradle do projeto (o Java que vem com o Android Studio). Siga o passo da seção 3:
```powershell
flutter config --jdk-dir="C:\Program Files\Microsoft\jdk-21.0.12.101-hotspot"
```
Depois rode `flutter run` de novo. No VS Code, reinicie o editor.

### `flutter` não é reconhecido como comando
O PATH não foi configurado, ou o terminal estava aberto antes da configuração. Revise a seção 1.2 e **abra um novo terminal** (no VS Code, feche e reabra o VS Code).

### `Android license status unknown` no `flutter doctor`
Rode `flutter doctor --android-licenses` e aceite tudo com `y`. Se der erro, instale as **Android SDK Command-line Tools** (seção 2.1).

### Emulador não abre ou fica muito lento
- Confirme que a **virtualização** está ativada: Gerenciador de Tarefas → aba **Desempenho → CPU** → "Virtualização: **Habilitado**". Se estiver desabilitada, ative na BIOS (Intel VT-x / AMD SVM).
- Ative o **Windows Hypervisor Platform**: Menu Iniciar → "Ativar ou desativar recursos do Windows" → marque **Plataforma do Hipervisor do Windows** → reinicie o PC.
- Feche outros programas pesados. O emulador usa de 2 a 4 GB de RAM.

### Erro de build estranho depois de mover ou renomear o projeto
```powershell
flutter clean
flutter pub get
flutter run
```
