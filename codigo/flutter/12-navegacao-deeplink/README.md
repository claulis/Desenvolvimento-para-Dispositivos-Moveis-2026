# 12 — Navegação declarativa e deep link (Flutter)

Ponto de partida para a Avaliação 2 (Aula 12): navegação com `go_router`, incluindo uma rota acessível por deep link.

## Como rodar

```bash
flutter pub get
flutter run
```

## Testar o deep link

Requer o `AndroidManifest.xml` configurado com o `intent-filter` mostrado na Aula 12 §3 (já incluído em `inicio/android/app/src/main/AndroidManifest.xml`):

```bash
adb shell am start -W -a android.intent.action.VIEW -d "meuapp://pedido/42"
```

## O que alterar

- `inicio/lib/router.dart`: contém as rotas de catálogo e detalhe de pedido, sem aninhamento — adicionar a rota de detalhe como filha da rota de catálogo (Aula 12 §3) para que o deep link reconstrua a pilha corretamente.
- `inicio/lib/tela_formulario.dart`: contém um `PopScope` incompleto — corrigir seguindo o exemplo da Aula 12 §2 (liberar `canPop` antes de chamar `pop()`).
