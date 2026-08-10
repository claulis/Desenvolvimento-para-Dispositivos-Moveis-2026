# 09 — Widgets responsivos (Flutter)

Ponto de partida para a atividade da Aula 9: implementar em Dart a tela de detalhe de produto prototipada na Aula 7, com três variações por classe de tamanho de janela.

## Como rodar

```bash
flutter create . --project-name tela_produto   # se ainda não inicializado
flutter run
```

## O que alterar

- `inicio/lib/main.dart`: contém a tela âncora `TelaProduto` da Aula 9 §3, sem responsividade. Adicionar `LayoutBuilder` (ou `MediaQuery.sizeOf`, ver nota da Aula 9) para alternar entre `_LayoutCompacto`, `_LayoutMedio` e `_LayoutExpandido` nos pontos de quebra de 600dp e 840dp.
- `solucao/lib/main.dart`: referência com a responsividade já implementada — consulte depois de tentar.

Esta é a "tela âncora" reconstruída em React Native na Aula 13 e comparada na Aula 20 — mantenha a estrutura de dados (`Produto`) simples e estável para facilitar a comparação futura.
