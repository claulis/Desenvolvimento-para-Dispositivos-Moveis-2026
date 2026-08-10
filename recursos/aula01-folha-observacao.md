# Folha de observação — Aula 1

Preencher para cada perfil de emulador testado (mínimo dois: RAM baixa e RAM alta).

| Item | Perfil 1 (RAM baixa, ex.: Pixel 3a, 2GB) | Perfil 2 (RAM alta, ex.: topo de linha atual) |
|---|---|---|
| Modelo/perfil do emulador | | |
| Versão do Android | | |
| Tempo de inicialização a frio (*cold start*, em segundos) | | |
| Uso de memória logo após abrir (MB, via Android Studio Profiler) | | |
| Uso de memória após 2 minutos de uso | | |
| Estado da tela preservado ao pressionar Home e voltar? (S/N) | | |
| Processo permaneceu ativo em segundo plano? (S/N) | | |
| Observações adicionais | | |

## Como medir

1. **Tempo de inicialização**: cronometrar do toque no ícone até a primeira tela totalmente carregada e interativa.
2. **Uso de memória**: Android Studio > aba **Profiler** > selecionar o processo do app > memória (MB).
3. **Preservação de estado**: preencher um campo de texto ou navegar para uma tela secundária, pressionar Home, aguardar 30 segundos, voltar ao app pelo launcher, e observar se o estado foi mantido.
