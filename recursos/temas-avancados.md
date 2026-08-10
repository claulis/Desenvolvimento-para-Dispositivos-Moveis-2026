# Temas avançados — não cobertos nas 80h do componente

Este componente não tem carga horária para cobrir tudo que um aplicativo de produção real eventualmente precisa. Os temas abaixo são citados ao longo das aulas como solução (notificações push, por exemplo) mas nunca implementados — este documento existe para que sua ausência seja uma decisão de escopo explícita, não uma lacuna silenciosa, e para orientar quem for aprofundar o tema em TCC ou projeto próprio.

## Notificações push (implementação)

Citadas como solução nas Aulas 1, 2, 12 e 16, nunca implementadas. Para aprofundar: Firebase Cloud Messaging (FCM) é o caminho mais comum em Android, com pacotes `firebase_messaging` (Flutter) e `@react-native-firebase/messaging` (React Native). O tópico central a estudar é o tratamento de mensagem com o app em primeiro plano, segundo plano e fechado — três caminhos de código distintos.

## Segurança

- **Armazenamento seguro**: `flutter_secure_storage` (Flutter) e `react-native-keychain`/`expo-secure-store` (React Native) para tokens de sessão e dados sensíveis — nunca em `shared_preferences`/`AsyncStorage` puro, que não são criptografados.
- **Certificate pinning**: evita ataques de interceptação mesmo com um certificado raiz malicioso instalado no aparelho.
- **Ofuscação de código**: `flutter build --obfuscate` e ProGuard/R8 (Android) dificultam engenharia reversa do binário.

## Build e publicação

- **Assinatura e keystore**: todo app Android publicado precisa de uma chave de assinatura própria, gerenciada com cuidado (perder a chave impede atualizar o app já publicado).
- **Flavors/variantes de build**: builds separadas para desenvolvimento, homologação e produção, cada uma com configuração própria (URL de API, ícone, nome).
- **Play Console**: processo de publicação, faixas de teste (interno, fechado, aberto, produção), políticas de revisão.
- **EAS Build** (Expo): equivalente ao processo de build/assinatura para projetos Expo, sem precisar configurar o ambiente nativo localmente.

## Observabilidade

Sem crash reporting, a pergunta da Aula 1 ("por que o app trava só em alguns aparelhos?") não tem resposta possível em produção. Ferramentas de referência: Firebase Crashlytics, Sentry — ambas com SDKs para Flutter e React Native, reportando stack traces de falhas reais de usuários, agrupadas por causa raiz e por perfil de aparelho.

## Internacionalização

Fora do escopo deste componente. Para aprofundar: `intl`/`flutter_localizations` (Flutter) e `i18next`/`react-i18next` ou `expo-localization` (React Native), cobrindo não apenas tradução de texto, mas formatação de data, número e moeda por localidade.
