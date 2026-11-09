# Aula 20 — React Native: tutorial integrador com SQLite, Expo Router e navegação por abas

## Tutorial: App de Tarefas com Expo, React Native, SQLite e navegação por abas

Este tutorial explica, passo a passo, o projeto **tarefas**: um app mobile com **três telas** (Tarefas, Categorias e Resumo), um **menu de navegação em abas** e um banco **SQLite** local com duas tabelas relacionadas.



---

## Sumário

1. [O que é o projeto](#1-o-que-é-o-projeto)
2. [A plataforma: React Native + Expo](#2-a-plataforma-react-native--expo)
3. [Arquitetura](#3-arquitetura)
4. [Bibliotecas usadas](#4-bibliotecas-usadas)
5. [Pré-requisitos e instalação](#5-pré-requisitos-e-instalação)
6. [Estrutura de arquivos](#6-estrutura-de-arquivos)
7. [O código completo, arquivo por arquivo](#7-o-código-completo-arquivo-por-arquivo)
8. [Conceitos principais](#8-conceitos-principais)
9. [Como rodar](#9-como-rodar)
10. [Fluxos, do toque ao banco](#10-fluxos-do-toque-ao-banco)
11. [Migrações: como o banco passou da v1 para a v2](#11-migrações-como-o-banco-passou-da-v1-para-a-v2)
12. [Problemas comuns](#12-problemas-comuns)
13. [Pontos de atenção neste código](#13-pontos-de-atenção-neste-código)
14. [Exercícios e próximos passos](#14-exercícios-e-próximos-passos)

---

## 1. O que é o projeto

Um app com **três telas**, acessadas por um menu de abas na parte de baixo:

| Aba | O que faz |
|---|---|
| 📝 **Tarefas** | Adiciona tarefas escolhendo uma categoria; tocar no texto marca/desmarca como feita; **Excluir** apaga. Cada tarefa mostra o nome da categoria. |
| 🏷️ **Categorias** | Cadastra categorias (nomes únicos, sem diferenciar maiúsculas) e as exclui com confirmação. Ao excluir, as tarefas da categoria **não** são apagadas: ficam "sem categoria". |
| 📊 **Resumo** | Mostra, por categoria, quantas tarefas estão feitas em relação ao total (ex.: `2/5 feitas`). |

As telas se conversam **pelo banco**: uma categoria criada na aba Categorias aparece como opção na aba Tarefas; marcar uma tarefa muda os números do Resumo.

Os dados ficam num banco **SQLite** dentro do aparelho. Fechar e reabrir o app não apaga nada, e não há servidor nem internet envolvidos.

---

## 2. A plataforma: React Native + Expo

### React Native
Framework em que a interface é escrita em **JavaScript/TypeScript com React** e transformada em componentes **nativos** de Android e iOS. `<View>` vira uma view nativa, `<Text>` vira um texto nativo. Não é uma página web dentro de um app.

### Expo
Conjunto de ferramentas e bibliotecas sobre o React Native que remove a parte difícil (Xcode, Android Studio, configuração nativa):

- **Expo CLI** (`npx expo start`): sobe o servidor de desenvolvimento (Metro bundler).
- **Expo Go**: app instalado no celular para abrir o projeto escaneando um QR Code, sem compilar nada.
- **Módulos Expo** (`expo-sqlite`, `expo-router`...): bibliotecas já prontas e compatíveis entre si.
- **EAS** (opcional): serviço na nuvem para gerar o APK/IPA final e publicá-lo nas lojas.
- **Continuous Native Generation (CNG)**: as pastas `android/` e `ios/` **não existem** no repositório. O Expo as gera quando necessário a partir do `app.json`. Nunca são editadas à mão.

### Expo Router
Biblioteca de navegação **baseada em arquivos**: cada arquivo dentro de `src/app/` é uma tela, e o nome do arquivo é a rota. O arquivo `_layout.tsx` define o "molde" que envolve as telas (aqui, o menu de abas). É a navegação recomendada pelo Expo e pelo `AGENTS.md` deste projeto.

### TypeScript
O código usa TypeScript em modo `strict`: os tipos `Tarefa`, `Categoria` e `Resumo` descrevem o formato das linhas do banco e o compilador avisa em caso de uso incorreto.

---

## 3. Arquitetura

O app tem **três camadas**: navegação/telas, estilos compartilhados e dados.

```
┌──────────────────────────────────────────────────────────────┐
│  package.json  "main": "expo-router/entry"   Ponto de entrada │
│  (o Expo Router cria o app a partir de src/app/)              │
└───────────────────────────┬──────────────────────────────────┘
                            │
┌───────────────────────────▼──────────────────────────────────┐
│  src/app/_layout.tsx        LAYOUT RAIZ                       │
│   <SQLiteProvider onInit={migrar}>   ← abre e migra o banco   │
│     <Tabs>                           ← menu de navegação      │
│        ├─ index.tsx       → aba "Tarefas"                     │
│        ├─ categorias.tsx  → aba "Categorias"                  │
│        └─ resumo.tsx      → aba "Resumo"                      │
└───────────────────────────┬──────────────────────────────────┘
                            │ cada tela: useSQLiteContext() → db
┌───────────────────────────▼──────────────────────────────────┐
│  src/db/db.ts              CAMADA DE DADOS                    │
│   migrar · listar · adicionar · alternar · remover            │
│   listarCategorias · adicionarCategoria · removerCategoria    │
│   resumo        (SQL puro, nenhum código de interface)        │
└───────────────────────────┬──────────────────────────────────┘
                            │
┌───────────────────────────▼──────────────────────────────────┐
│  expo-sqlite  →  arquivo tarefas.db (armazenamento privado)   │
│                  tabelas: tarefas ──N:1──► categorias         │
└──────────────────────────────────────────────────────────────┘
```

**Decisões de design:**

- **Separação UI × dados.** As telas nunca escrevem SQL; `db.ts` nunca importa React.
- **Um único provider no layout raiz.** Todas as abas compartilham o mesmo banco aberto, via contexto. O banco é aberto e migrado uma vez, **antes** de qualquer tela aparecer.
- **Funções recebem `db` como parâmetro** em vez de usar variável global.
- **Banco como fonte da verdade.** Os estados (`itens`, `categorias`) são só cópias para renderizar. Depois de cada alteração, a tela relê do banco em vez de remendar o array na mão.
- **Telas sem estado compartilhado.** Não há Redux nem Context próprio: cada tela lê o que precisa do banco quando ganha foco (ver [8.4](#84-navegação-com-expo-router-e-abas) e [8.5](#85-recarregar-ao-ganhar-foco-usefocuseffect)).
- **Código fora de `src/app/`.** Tudo dentro de `src/app/` vira rota. Por isso `db.ts` e `estilos.ts` ficam em `src/db/` e `src/`.

---

## 4. Bibliotecas usadas

Definidas em `package.json`:

| Pacote | Versão | Para que serve |
|---|---|---|
| `expo` | ^58.0.23 | SDK base: CLI, configuração |
| `react` | 19.3.0 | Componentes e hooks (`useState`, `useCallback`...) |
| `react-native` | 0.88.1 | Componentes nativos (`View`, `Text`, `FlatList`...) |
| `expo-router` | ~58.0.30 | Navegação por arquivos; fornece `Tabs` e `useFocusEffect` |
| `react-native-screens` | ~4.30.1 | Telas nativas (dependência do Expo Router) |
| `react-native-safe-area-context` | ~5.11.1 | Respeita entalhes e barras do sistema (dependência do Expo Router) |
| `expo-linking` | ~58.0.16 | Links profundos (dependência do Expo Router) |
| `expo-constants` | ~58.0.15 | Constantes do app (dependência do Expo Router) |
| `expo-sqlite` | ~58.0.15 | Banco SQLite local; fornece `SQLiteProvider` e `useSQLiteContext` |
| `expo-status-bar` | ~58.0.4 | Barra de status (hora, bateria) |
| `typescript` (dev) | ~6.0.3 | Verificação de tipos |
| `@types/react` (dev) | ~19.3.0 | Tipos do React |

> **Regra do Expo:** os pacotes devem ser instalados sempre com `npx expo install <pacote>`, e não com `npm install`. O comando escolhe a versão compatível com o SDK do projeto.

---

## 5. Pré-requisitos e instalação

### 5.1 Pré-requisitos

1. **Node.js** em versão LTS recente (<https://nodejs.org>). Conferir com `node -v` e `npm -v`.
2. **Git** (opcional).
3. **Um destes para ver o app:**
   - **Celular com Expo Go** instalado (Play Store / App Store). É o caminho mais fácil.
   - **Emulador Android** (Android Studio) ou **Simulador iOS** (só macOS).
4. Celular e computador na **mesma rede Wi-Fi** (se for usar Expo Go).

### 5.2 Instalar as dependências do projeto existente

```bash
cd C:\codigo\reactnative\tarefas
npm install
```

### 5.3 (Opcional) Criar do zero um projeto equivalente

```bash
# 1. Cria o projeto a partir do template TypeScript em branco
npx create-expo-app@latest tarefas --template blank-typescript
cd tarefas

# 2. Instala o SQLite e o Expo Router (com as dependências dele)
npx expo install expo-sqlite expo-router react-native-safe-area-context react-native-screens expo-linking expo-constants

# 3. Cria as pastas
mkdir src\app src\db            # Windows (no macOS/Linux: mkdir -p src/app src/db)

# 4. Remove os arquivos do template, que o Expo Router substitui
del App.tsx index.ts            # (rm App.tsx index.ts no macOS/Linux)
```

Em seguida, ajusta-se a configuração (próxima seção) e criam-se os arquivos da [seção 7](#7-o-código-completo-arquivo-por-arquivo).

### 5.4 Configuração

Três arquivos:

- **`package.json`**: `"main": "expo-router/entry"` entrega o app ao Expo Router.
- **`app.json`**: recebe `"scheme": "tarefas"` (necessário para links profundos) e o plugin `"expo-router"` na lista de `plugins`.
- **`tsconfig.json`**: herda a base do Expo e liga o modo `strict`.

Não há variáveis de ambiente, chaves de API nem arquivo `.env`.

---

## 6. Estrutura de arquivos

```
tarefas/
├── src/
│   ├── app/                 ← TUDO aqui dentro vira rota (tela)
│   │   ├── _layout.tsx      ← layout raiz: banco + menu de abas
│   │   ├── index.tsx        ← aba Tarefas        (rota "/")
│   │   ├── categorias.tsx   ← aba Categorias     (rota "/categorias")
│   │   └── resumo.tsx       ← aba Resumo         (rota "/resumo")
│   ├── db/
│   │   └── db.ts            ← camada de dados: esquema, migrações, SQL
│   └── estilos.ts           ← estilos compartilhados pelas telas
├── app.json                 ← configuração do Expo
├── package.json             ← dependências e scripts
├── tsconfig.json            ← configuração do TypeScript
├── assets/                  ← ícones e splash screen
├── AGENTS.md                ← instruções para assistentes de IA
├── .gitignore
└── LICENSE
```

Gerados automaticamente (não devem ser editados): `node_modules/`, `.expo/` e, em caso de build nativo, `android/` e `ios/`.

---

## 7. O código completo, arquivo por arquivo

### 7.1 `package.json`

```json
{
  "name": "tarefas",
  "version": "1.0.0",
  "main": "expo-router/entry",
  "dependencies": {
    "expo": "^58.0.23",
    "expo-constants": "~58.0.15",
    "expo-linking": "~58.0.16",
    "expo-router": "~58.0.30",
    "expo-sqlite": "~58.0.15",
    "expo-status-bar": "~58.0.4",
    "react": "19.3.0",
    "react-native": "0.88.1",
    "react-native-safe-area-context": "~5.11.1",
    "react-native-screens": "~4.30.1"
  },
  "devDependencies": {
    "@types/react": "~19.3.0",
    "typescript": "~6.0.3"
  },
  "scripts": {
    "start": "expo start",
    "android": "expo start --android",
    "ios": "expo start --ios",
    "web": "expo start --web"
  },
  "private": true
}
```

**Como funciona:**
- `"main": "expo-router/entry"` substitui o antigo `index.ts` + `registerRootComponent`. O Expo Router registra o componente raiz e monta as rotas a partir de `src/app/`.
- `scripts` são atalhos: `npm start` roda `expo start`.
- `dependencies` vão para o app final; `devDependencies` só existem no desenvolvimento.

### 7.2 `app.json`

```json
{
  "expo": {
    "name": "tarefas",
    "slug": "tarefas",
    "version": "1.0.0",
    "orientation": "portrait",
    "icon": "./assets/icon.png",
    "userInterfaceStyle": "light",
    "ios": {
      "supportsTablet": true
    },
    "android": {
      "adaptiveIcon": {
        "backgroundColor": "#E6F4FE",
        "foregroundImage": "./assets/android-icon-foreground.png",
        "backgroundImage": "./assets/android-icon-background.png",
        "monochromeImage": "./assets/android-icon-monochrome.png"
      },
      "predictiveBackGestureEnabled": false,
      "package": "com.claudio.tarefas"
    },
    "web": {
      "favicon": "./assets/favicon.png"
    },
    "scheme": "tarefas",
    "plugins": [
      "expo-sqlite",
      "expo-status-bar",
      "expo-router"
    ]
  }
}
```

**Como funciona:**
- `name` é o nome sob o ícone; `slug` é o identificador na URL/Expo.
- `orientation: "portrait"` trava o app em pé; `userInterfaceStyle: "light"` força tema claro.
- `android.package` é o identificador único na Play Store; não muda depois de publicado.
- `scheme` define o prefixo de links profundos (`tarefas://resumo` abriria a aba Resumo). O Expo Router exige.
- `plugins` registra módulos que precisam de configuração nativa, sem necessidade de alterar `android/` e `ios/`.

### 7.3 `tsconfig.json`

```json
{
  "extends": "expo/tsconfig.base",
  "compilerOptions": {
    "strict": true
  }
}
```

**Como funciona:** herda as regras do Expo (inclusive o `jsx` correto) e ativa `strict`. O comando `npx tsc --noEmit` checa os tipos sem gerar arquivos.

### 7.4 `src/db/db.ts` (camada de dados)

```ts
import type { SQLiteDatabase } from 'expo-sqlite';

export type Categoria = { id: number; nome: string };
export type Tarefa = {
  id: number;
  titulo: string;
  feita: number;
  categoria_id: number | null;
  categoria: string | null; // nome, vindo do JOIN
};
export type Resumo = { categoria: string; total: number; feitas: number };

// Roda toda vez que o banco abre. PRAGMA user_version guarda a versão do esquema.
export async function migrar(db: SQLiteDatabase) {
  // Vale por conexão e vem desligado no SQLite: sem isto o REFERENCES é ignorado.
  await db.execAsync('PRAGMA foreign_keys = ON');

  const r = await db.getFirstAsync<{ user_version: number }>('PRAGMA user_version');
  let atual = r?.user_version ?? 0;

  if (atual === 0) {
    await db.execAsync(`
      PRAGMA journal_mode = 'wal';
      CREATE TABLE tarefas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        titulo TEXT NOT NULL,
        feita INTEGER NOT NULL DEFAULT 0
      );
      PRAGMA user_version = 1;
    `);
    atual = 1;
  }
  if (atual === 1) {
    // Transação: ou tudo é aplicado (inclusive o user_version), ou nada.
    await db.withTransactionAsync(async () => {
      await db.execAsync(`
        CREATE TABLE categorias (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          nome TEXT NOT NULL UNIQUE COLLATE NOCASE
        );
        ALTER TABLE tarefas ADD COLUMN categoria_id INTEGER REFERENCES categorias(id) ON DELETE SET NULL;
        PRAGMA user_version = 2;
      `);
    });
    atual = 2;
  }
}

// ---- tarefas ----
export const listar = (db: SQLiteDatabase) =>
  db.getAllAsync<Tarefa>(`
    SELECT t.id, t.titulo, t.feita, t.categoria_id, c.nome AS categoria
    FROM tarefas t LEFT JOIN categorias c ON c.id = t.categoria_id
    ORDER BY t.id DESC`);

export const adicionar = (db: SQLiteDatabase, titulo: string, categoriaId: number | null) =>
  db.runAsync('INSERT INTO tarefas (titulo, categoria_id) VALUES (?, ?)', titulo, categoriaId);

export const alternar = (db: SQLiteDatabase, id: number) =>
  db.runAsync('UPDATE tarefas SET feita = 1 - feita WHERE id = ?', id);

export const remover = (db: SQLiteDatabase, id: number) =>
  db.runAsync('DELETE FROM tarefas WHERE id = ?', id);

// ---- categorias ----
export const listarCategorias = (db: SQLiteDatabase) =>
  db.getAllAsync<Categoria>('SELECT * FROM categorias ORDER BY nome');

// Lança erro se o nome já existir (UNIQUE).
export const adicionarCategoria = (db: SQLiteDatabase, nome: string) =>
  db.runAsync('INSERT INTO categorias (nome) VALUES (?)', nome);

// As tarefas da categoria ficam sem categoria (ON DELETE SET NULL).
export const removerCategoria = (db: SQLiteDatabase, id: number) =>
  db.runAsync('DELETE FROM categorias WHERE id = ?', id);

// ---- resumo ----
export const resumo = (db: SQLiteDatabase) =>
  db.getAllAsync<Resumo>(`
    SELECT COALESCE(c.nome, 'Sem categoria') AS categoria,
           COUNT(*) AS total,
           SUM(t.feita) AS feitas
    FROM tarefas t LEFT JOIN categorias c ON c.id = t.categoria_id
    GROUP BY t.categoria_id
    ORDER BY categoria`);
```

**Como funciona, por bloco:**

- **Tipos.** `feita` é `number` (0/1), pois o SQLite não tem booleano. `categoria_id` pode ser `null` (tarefa sem categoria). `Tarefa.categoria` não é uma coluna: é o **nome** trazido pelo `JOIN` de `listar`. `Resumo` é o formato do resultado do `GROUP BY`.
- **`PRAGMA foreign_keys = ON`.** O SQLite **ignora** chaves estrangeiras por padrão, e essa configuração vale só para a conexão atual. Como `migrar` roda toda vez que o banco abre, ela fica sempre ligada. Sem ela, `ON DELETE SET NULL` não funcionaria.
- **`migrar` em degraus.** `PRAGMA user_version` é um número guardado no arquivo do banco (novo = `0`). Cada `if` aplica um degrau e avança `atual`. Um banco novo executa os dois; um banco que já estava na v1 executa só o segundo. Detalhes na [seção 11](#11-migrações-como-o-banco-passou-da-v1-para-a-v2).
- **v1:** cria `tarefas` e liga o modo WAL (*Write-Ahead Logging*, mais rápido e seguro para leituras e escritas simultâneas).
- **v2 (dentro de uma transação):** cria `categorias` (`nome` é `UNIQUE` e `COLLATE NOCASE`, então "Casa" e "casa" são o mesmo nome) e **adiciona a coluna** `categoria_id` em `tarefas`, apontando para `categorias(id)`. `ON DELETE SET NULL` significa: se a categoria for apagada, a coluna das tarefas dela vira `NULL`, e as tarefas continuam existindo. Colocar o `user_version = 2` dentro da transação garante que, se algo falhar no meio, nada fica pela metade.
- **`listar`.** `LEFT JOIN` junta cada tarefa à sua categoria. É `LEFT` para que tarefas **sem** categoria também apareçam (com `categoria = NULL`). Um `INNER JOIN` as esconderia.
- **`adicionar`.** Dois parâmetros `?`. Passar `null` grava `NULL` (sem categoria). **Nunca** se deve montar SQL concatenando texto do usuário.
- **`alternar`.** `feita = 1 - feita` inverte 0↔1 em um único comando.
- **`adicionarCategoria`.** Se o nome já existir, o SQLite lança um erro (`UNIQUE constraint failed`); quem chama trata (ver `categorias.tsx`).
- **`resumo`.** `GROUP BY t.categoria_id` agrupa as tarefas por categoria; `COUNT(*)` conta e `SUM(t.feita)` soma os 1, ou seja, as feitas. `COALESCE(c.nome, 'Sem categoria')` troca o `NULL` por um texto legível.

### 7.5 `src/estilos.ts`

```ts
import { StyleSheet } from 'react-native';

// Estilos compartilhados pelas três telas.
export const s = StyleSheet.create({
  tela: { flex: 1, padding: 16, backgroundColor: '#fff' },
  linha: { flexDirection: 'row', gap: 8, marginBottom: 12 },
  input: { flex: 1, borderWidth: 1, borderColor: '#ccc', borderRadius: 8, paddingHorizontal: 12 },
  botao: { backgroundColor: '#2563eb', borderRadius: 8, paddingHorizontal: 14, justifyContent: 'center' },
  botaoTxt: { color: '#fff', fontWeight: '600' },
  chips: { flexGrow: 0, marginBottom: 12 },
  chip: { paddingHorizontal: 12, paddingVertical: 6, marginRight: 8, borderRadius: 16, borderWidth: 1, borderColor: '#2563eb' },
  chipOn: { backgroundColor: '#2563eb' },
  chipTxt: { color: '#2563eb' },
  chipTxtOn: { color: '#fff' },
  item: { flexDirection: 'row', alignItems: 'center', paddingVertical: 12, borderBottomWidth: 1, borderColor: '#eee' },
  itemTexto: { flex: 1 },
  texto: { fontSize: 16 },
  pequeno: { fontSize: 12, color: '#2563eb' },
  feita: { textDecorationLine: 'line-through', color: '#999' },
  apagar: { color: '#dc2626' },
  vazio: { color: '#888', textAlign: 'center', marginTop: 24 },
});
```

**Como funciona:** um único objeto de estilos importado pelas três telas, para não repetir o mesmo código. Fica **fora** de `src/app/` para não virar rota. Os "chips" (`chip`, `chipOn`...) são os botões arredondados de escolha de categoria.

### 7.6 `src/app/_layout.tsx` (banco + menu de navegação)

```tsx
import { Text } from 'react-native';
import { Tabs } from 'expo-router';
import { SQLiteProvider } from 'expo-sqlite';
import { migrar } from '../db/db';

// Emoji como ícone: sem biblioteca extra.
const icone = (e: string) => () => <Text style={{ fontSize: 20 }}>{e}</Text>;

export default function Layout() {
  return (
    <SQLiteProvider databaseName="tarefas.db" onInit={migrar}>
      <Tabs>
        <Tabs.Screen name="index" options={{ title: 'Tarefas', tabBarIcon: icone('📝') }} />
        <Tabs.Screen name="categorias" options={{ title: 'Categorias', tabBarIcon: icone('🏷️') }} />
        <Tabs.Screen name="resumo" options={{ title: 'Resumo', tabBarIcon: icone('📊') }} />
      </Tabs>
    </SQLiteProvider>
  );
}
```

**Como funciona:**
- É o arquivo mais importante da navegação. O Expo Router o usa como **moldura** de todas as telas da mesma pasta.
- `SQLiteProvider` fica **por fora** de `Tabs`: abre `tarefas.db`, executa `onInit={migrar}` e só então mostra as abas. Assim todas as telas já encontram as tabelas prontas.
- `Tabs` desenha a barra de abas e o cabeçalho de cada tela. Cada `Tabs.Screen` liga um arquivo de `src/app/` ao menu: `name="index"` é `index.tsx`, `name="categorias"` é `categorias.tsx` etc. `title` aparece no cabeçalho e sob o ícone; a **ordem** dos `Tabs.Screen` é a ordem das abas.
- `tabBarIcon` recebe uma função que devolve o ícone. Utiliza-se um emoji dentro de `<Text>` para não instalar biblioteca de ícones. `icone('📝')` devolve essa função.

### 7.7 `src/app/index.tsx` (aba Tarefas)

```tsx
import { useCallback, useState } from 'react';
import { FlatList, Pressable, ScrollView, Text, TextInput, View } from 'react-native';
import { useFocusEffect } from 'expo-router';
import { useSQLiteContext } from 'expo-sqlite';
import { adicionar, alternar, listar, listarCategorias, remover, type Categoria, type Tarefa } from '../db/db';
import { s } from '../estilos';

export default function Tarefas() {
  const db = useSQLiteContext();
  const [itens, setItens] = useState<Tarefa[]>([]);
  const [categorias, setCategorias] = useState<Categoria[]>([]);
  const [texto, setTexto] = useState('');
  const [categoriaId, setCategoriaId] = useState<number | null>(null);

  const carregar = useCallback(async () => {
    setItens(await listar(db));
    const cats = await listarCategorias(db);
    setCategorias(cats);
    // Se a categoria selecionada foi apagada, volta para "sem categoria".
    setCategoriaId((atual) => (cats.some((c) => c.id === atual) ? atual : null));
  }, [db]);

  // As abas ficam montadas; useFocusEffect recarrega toda vez que esta aba ganha foco
  // (assim uma categoria criada na outra aba aparece aqui).
  useFocusEffect(
    useCallback(() => {
      carregar();
    }, [carregar]),
  );

  async function salvar() {
    const titulo = texto.trim();
    if (!titulo) return;
    await adicionar(db, titulo, categoriaId);
    setTexto('');
    await carregar();
  }

  async function marcar(id: number) {
    await alternar(db, id);
    await carregar();
  }

  async function apagar(id: number) {
    await remover(db, id);
    await carregar();
  }

  const opcoes: { id: number | null; nome: string }[] = [{ id: null, nome: 'Sem categoria' }, ...categorias];

  return (
    <View style={s.tela}>
      <View style={s.linha}>
        <TextInput style={s.input} value={texto} onChangeText={setTexto} placeholder="Nova tarefa" onSubmitEditing={salvar} />
        <Pressable style={s.botao} onPress={salvar}>
          <Text style={s.botaoTxt}>Adicionar</Text>
        </Pressable>
      </View>

      <ScrollView horizontal showsHorizontalScrollIndicator={false} style={s.chips}>
        {opcoes.map((c) => {
          const ativo = c.id === categoriaId;
          return (
            <Pressable key={c.id ?? 'nenhuma'} onPress={() => setCategoriaId(c.id)} style={[s.chip, ativo && s.chipOn]}>
              <Text style={ativo ? s.chipTxtOn : s.chipTxt}>{c.nome}</Text>
            </Pressable>
          );
        })}
      </ScrollView>

      <FlatList
        data={itens}
        keyExtractor={(t) => String(t.id)}
        ListEmptyComponent={<Text style={s.vazio}>Nenhuma tarefa ainda.</Text>}
        renderItem={({ item }) => (
          <View style={s.item}>
            <Pressable style={s.itemTexto} onPress={() => marcar(item.id)}>
              <Text style={[s.texto, item.feita === 1 && s.feita]}>{item.titulo}</Text>
              {item.categoria && <Text style={s.pequeno}>{item.categoria}</Text>}
            </Pressable>
            <Pressable onPress={() => apagar(item.id)}>
              <Text style={s.apagar}>Excluir</Text>
            </Pressable>
          </View>
        )}
      />
    </View>
  );
}
```

**Como funciona:**
- **Estados:** `itens` (tarefas), `categorias` (opções dos chips), `texto` (campo digitado) e `categoriaId` (chip selecionado; `null` = sem categoria).
- **`carregar`** lê tarefas e categorias do banco. A última linha usa a forma funcional do setter, `setCategoriaId((atual) => ...)`: se a categoria selecionada foi apagada em outra aba, a seleção volta para `null`. Sem isso, o próximo `INSERT` apontaria para uma categoria inexistente e a chave estrangeira o rejeitaria com erro.
- **`useFocusEffect`** executa `carregar` toda vez que **esta aba ganha foco**, e não só na primeira vez. O motivo está na [seção 8.5](#85-recarregar-ao-ganhar-foco-usefocuseffect). O callback precisa estar em `useCallback`, senão o efeito reexecutaria a cada renderização.
- **Chips de categoria.** `opcoes` junta a opção fixa "Sem categoria" (`id: null`) às categorias do banco. O `ScrollView horizontal` permite rolar para o lado se houver muitas. O chip ativo troca de estilo (`ativo && s.chipOn`). `key={c.id ?? 'nenhuma'}` dá uma chave única mesmo para o `null`.
- **`salvar`** passa o `categoriaId` escolhido para `adicionar`.
- **Lista.** `item.categoria && <Text>...` só mostra o nome da categoria se existir (tarefa sem categoria não mostra nada).

### 7.8 `src/app/categorias.tsx` (aba Categorias)

```tsx
import { useCallback, useState } from 'react';
import { Alert, FlatList, Pressable, Text, TextInput, View } from 'react-native';
import { useFocusEffect } from 'expo-router';
import { useSQLiteContext } from 'expo-sqlite';
import { adicionarCategoria, listarCategorias, removerCategoria, type Categoria } from '../db/db';
import { s } from '../estilos';

export default function Categorias() {
  const db = useSQLiteContext();
  const [itens, setItens] = useState<Categoria[]>([]);
  const [nome, setNome] = useState('');

  const carregar = useCallback(async () => {
    setItens(await listarCategorias(db));
  }, [db]);

  useFocusEffect(
    useCallback(() => {
      carregar();
    }, [carregar]),
  );

  async function salvar() {
    const n = nome.trim();
    if (!n) return;
    try {
      await adicionarCategoria(db, n);
      setNome('');
      await carregar();
    } catch {
      // ponytail: qualquer erro vira "já existe"; o esperado é a violação do UNIQUE.
      Alert.alert('Categoria já existe', `"${n}" já está cadastrada.`);
    }
  }

  function apagar(c: Categoria) {
    Alert.alert('Excluir categoria', `Excluir "${c.nome}"? As tarefas ficam sem categoria.`, [
      { text: 'Cancelar', style: 'cancel' },
      {
        text: 'Excluir',
        style: 'destructive',
        onPress: async () => {
          await removerCategoria(db, c.id);
          await carregar();
        },
      },
    ]);
  }

  return (
    <View style={s.tela}>
      <View style={s.linha}>
        <TextInput style={s.input} value={nome} onChangeText={setNome} placeholder="Nova categoria" onSubmitEditing={salvar} />
        <Pressable style={s.botao} onPress={salvar}>
          <Text style={s.botaoTxt}>Adicionar</Text>
        </Pressable>
      </View>

      <FlatList
        data={itens}
        keyExtractor={(c) => String(c.id)}
        ListEmptyComponent={<Text style={s.vazio}>Nenhuma categoria ainda.</Text>}
        renderItem={({ item }) => (
          <View style={s.item}>
            <Text style={[s.texto, s.itemTexto]}>{item.nome}</Text>
            <Pressable onPress={() => apagar(item)}>
              <Text style={s.apagar}>Excluir</Text>
            </Pressable>
          </View>
        )}
      />
    </View>
  );
}
```

**Como funciona:**
- Mesmo desenho da aba Tarefas, mais simples: um campo, uma lista e dois eventos.
- **`salvar` com `try/catch`.** Se o nome já existir (inclusive "casa" quando "Casa" existe, por causa do `COLLATE NOCASE`), o banco lança um erro. O `catch` mostra um aviso nativo com `Alert.alert` em vez de deixar o app quebrar. O campo **não** é limpo nesse caso, para o usuário corrigir.
- **`apagar` com confirmação.** `Alert.alert(título, mensagem, botões)` abre uma caixa de diálogo. O botão `destructive` aparece em vermelho no iOS. O `onPress` do botão "Excluir" é `async`: só então chama `removerCategoria` e recarrega. Como o banco usa `ON DELETE SET NULL`, as tarefas da categoria **não são apagadas**.
- `Alert.alert` com botões é para Android/iOS; na web ele não funciona do mesmo jeito (o projeto é pensado para celular).

### 7.9 `src/app/resumo.tsx` (aba Resumo)

```tsx
import { useCallback, useState } from 'react';
import { FlatList, Text, View } from 'react-native';
import { useFocusEffect } from 'expo-router';
import { useSQLiteContext } from 'expo-sqlite';
import { resumo, type Resumo } from '../db/db';
import { s } from '../estilos';

export default function ResumoTela() {
  const db = useSQLiteContext();
  const [itens, setItens] = useState<Resumo[]>([]);

  useFocusEffect(
    useCallback(() => {
      resumo(db).then(setItens);
    }, [db]),
  );

  return (
    <View style={s.tela}>
      <FlatList
        data={itens}
        keyExtractor={(r) => r.categoria}
        ListEmptyComponent={<Text style={s.vazio}>Sem tarefas para resumir.</Text>}
        renderItem={({ item }) => (
          <View style={s.item}>
            <Text style={[s.texto, s.itemTexto]}>{item.categoria}</Text>
            <Text>
              {item.feitas}/{item.total} feitas
            </Text>
          </View>
        )}
      />
    </View>
  );
}
```

**Como funciona:**
- Tela **somente leitura**: não tem campo nem botões. Só consulta e exibe.
- `resumo(db).then(setItens)` busca o `GROUP BY` e guarda o resultado. Como esta aba não altera nada, ela só precisa recarregar ao ganhar foco.
- O componente se chama `ResumoTela` (e não `Resumo`) para não colidir com o **tipo** `Resumo` importado de `db.ts`.
- `keyExtractor` usa o nome da categoria como chave: serve porque o `GROUP BY` devolve uma linha por categoria e os nomes são únicos.

---

## 8. Conceitos principais

### 8.1 Componentes e JSX
A interface é composta por funções que retornam JSX. Cada arquivo de `src/app/` exporta (com `export default`) um componente, que é a tela. Um componente se redesenha quando seu estado muda.

### 8.2 Estado (`useState`)
`const [itens, setItens] = useState<Tarefa[]>([])` cria um valor que, ao ser trocado via `setItens`, faz o React redesenhar a tela. **Nunca** se deve modificar o array diretamente; o setter é chamado com um novo valor. O setter também aceita uma **função** `(atual) => novo`, usada em `setCategoriaId` para decidir com base no valor mais recente.

### 8.3 Context e Provider
`SQLiteProvider` coloca o banco num *contexto* React; `useSQLiteContext()` o lê em qualquer componente abaixo dele. Como o provider está no layout raiz, as três telas usam o **mesmo** banco sem passar `db` como prop.

### 8.4 Navegação com Expo Router e abas
- **Rotas = arquivos.** `src/app/index.tsx` é a rota `/`; `categorias.tsx` é `/categorias`; `resumo.tsx` é `/resumo`.
- **`_layout.tsx` = moldura.** Define como as telas irmãs se organizam. Aqui, `<Tabs>` cria o menu de abas.
- **Abas ficam montadas.** Ao trocar de aba, a anterior **não é destruída**: continua na memória com seu estado (o texto digitado, por exemplo, é mantido). Isso é bom para a experiência, mas traz o problema da próxima seção.
- Para navegar por código ou por link, o Expo Router oferece `Link` (`<Link href="/resumo">`) e `router.push('/resumo')`. Este projeto navega só pelo menu.
- Outros tipos de menu usam o mesmo princípio: troca-se `Tabs` por `Stack` (telas empilhadas) ou `Drawer` (menu lateral).

### 8.5 Recarregar ao ganhar foco (`useFocusEffect`)
Em um app de uma tela, `useEffect` que carrega a lista ao abrir bastava. Com abas, **não basta**: as telas ficam montadas, então um `useEffect` com `[]` roda uma vez só. Se uma categoria for criada na aba Categorias e o usuário voltar à aba Tarefas, a lista de chips estaria desatualizada.

`useFocusEffect` (de `expo-router`) executa o efeito **sempre que a tela ganha foco**. Regras:
- Passar uma função envolvida em `useCallback`.
- Para funções `async`, chamá-las dentro do callback (`carregar();`), pois o callback em si não pode ser `async`.

### 8.6 Assíncrono (`async`/`await`)
Operações de disco demoram. `await` pausa a função até terminar sem congelar a interface. Deve-se sempre usar `await` antes de `carregar()` para recarregar **depois** da gravação.

### 8.7 SQL e SQLite
- **SQLite**: banco relacional num único arquivo, sem servidor, embutido em Android e iOS.
- **Parâmetros `?`**: separam comando de dados (segurança contra *SQL injection*).
- **`execAsync`**: executa um ou vários comandos sem parâmetros (esquema).
- **`runAsync`**: executa `INSERT/UPDATE/DELETE` com parâmetros.
- **`getAllAsync` / `getFirstAsync`**: executam `SELECT` e devolvem as linhas / a primeira linha.
- **`withTransactionAsync`**: agrupa comandos; se um falhar, todos são desfeitos.

### 8.8 Relacionamento entre tabelas
Uma categoria tem **várias** tarefas, e cada tarefa tem **no máximo uma** categoria (relação 1:N). Isso se modela com uma **chave estrangeira**: a coluna `tarefas.categoria_id` guarda o `id` de uma linha de `categorias`.

| Conceito | No código | Efeito |
|---|---|---|
| Chave estrangeira | `REFERENCES categorias(id)` | O banco rejeita um `categoria_id` que não existe |
| Ação ao apagar | `ON DELETE SET NULL` | Apagar a categoria zera `categoria_id` das tarefas, sem apagá-las |
| `NULL` | `categoria_id` sem valor | Tarefa sem categoria |
| `UNIQUE COLLATE NOCASE` | em `categorias.nome` | Sem nomes repetidos, ignorando maiúsculas |
| `LEFT JOIN` | em `listar` e `resumo` | Une as tabelas **mantendo** as tarefas sem categoria |
| `GROUP BY` | em `resumo` | Uma linha por categoria, com `COUNT` e `SUM` |

> **Armadilha clássica:** o SQLite só respeita chaves estrangeiras com `PRAGMA foreign_keys = ON`, ligado a cada conexão. Esquecer isso faz o `ON DELETE SET NULL` simplesmente não acontecer, sem nenhum erro.

### 8.9 Migrações com `PRAGMA user_version`
O banco guarda sua própria versão de esquema. Ao abrir, o app compara com a versão do banco e aplica só os degraus que faltam. Isso permite atualizar o app sem perder os dados dos usuários (ver [seção 11](#11-migrações-como-o-banco-passou-da-v1-para-a-v2)).

### 8.10 Lista virtualizada (`FlatList`)
Para listas, é preferível usar `FlatList` em vez de `ScrollView` + `map`: ela cria só os itens visíveis. Os chips usam `ScrollView horizontal` porque são poucos.

### 8.11 Estilos e Flexbox
Sem CSS: estilos são objetos JS. O layout é sempre por Flexbox (`flexDirection: 'column'` é o padrão). `flex: 1` significa "ocupe o espaço que sobrar". Estilos compartilhados ficam em um módulo importado pelas telas.

---

## 9. Como rodar

### Passo a passo (celular com Expo Go)

1. **Instalar as dependências** (uma vez):
   ```bash
   cd C:\codigo\reactnative\tarefas
   npm install
   ```
2. **Iniciar o servidor de desenvolvimento:**
   ```bash
   npm start
   ```
   Aparecem um **QR Code** e um menu no terminal.
3. **Abrir no celular:**
   - **Android:** abrir o **Expo Go** e usar *Scan QR code*.
   - **iPhone:** abrir a **Câmera** e ler o QR Code.
4. **Testar o roteiro completo:**
   1. Aba **Categorias**: cadastrar "Casa" e "Trabalho". Tentar cadastrar "casa" de novo: deve aparecer o aviso de duplicada.
   2. Aba **Tarefas**: tocar no chip "Casa", digitar "Lavar louça" e adicionar. Verificar o nome da categoria sob a tarefa.
   3. Marcar a tarefa como feita (tocar no texto).
   4. Aba **Resumo**: deve mostrar `Casa  1/1 feitas`.
   5. Voltar à aba **Categorias**, excluir "Casa" e confirmar. Na aba **Tarefas**, a tarefa continua lá, agora sem categoria; no **Resumo**, aparece em "Sem categoria".
   6. Fechar e reabrir o app: tudo persiste.

### Outras formas de rodar

| Comando | Resultado |
|---|---|
| `npm run android` | Abre no emulador Android (ou aparelho via USB) |
| `npm run ios` | Abre no Simulador iOS (somente macOS) |
| `npm run web` | Tenta abrir no navegador. **Atenção:** `expo-sqlite` na web exige configuração extra; este projeto foi pensado para Android/iOS |

### Atalhos no terminal do `expo start`

- `a`: abre no Android · `i`: abre no iOS · `r`: recarrega · `m`: menu de desenvolvedor · `Ctrl+C`: encerra.

### Fast Refresh
Ao salvar um arquivo, o app atualiza sozinho em segundos. Editar um texto ou uma cor permite ver isso.

### Verificações de qualidade
```bash
npx tsc --noEmit     # checa tipos
npx expo-doctor      # diagnostica dependências e configuração
npx expo lint        # lint (na primeira execução o Expo oferece instalar o ESLint)
```

### Gerar um app instalável (opcional)
```bash
npx eas-cli@latest build --platform android --profile preview
```
Requer conta gratuita em <https://expo.dev> e `npx eas-cli@latest login`.

---

## 10. Fluxos, do toque ao banco

### 10.1 Abertura do app

```
expo-router/entry
  └─ src/app/_layout.tsx
       └─ <SQLiteProvider> abre tarefas.db
            └─ migrar(db): foreign_keys = ON; lê user_version; aplica degraus
                 └─ <Tabs> aparece, mostrando a primeira aba (index.tsx)
                      └─ useFocusEffect → carregar() → lista exibida
```

### 10.2 Adicionar uma tarefa com categoria

O usuário escolhe o chip "Casa", digita "Comprar pão" e toca em **Adicionar**.

```
1. Toca no chip "Casa"      → setCategoriaId(3)
2. Digita                   → onChangeText → setTexto("Comprar pão")
3. Toca em "Adicionar"      → salvar()
4. texto.trim() não vazio   → adicionar(db, "Comprar pão", 3)
5. SQL                      → INSERT INTO tarefas (titulo, categoria_id) VALUES ('Comprar pão', 3)
6. setTexto('')             → campo limpo (o chip continua selecionado)
7. carregar()               → listar(db): SELECT ... LEFT JOIN categorias ...
8. setItens(...)            → FlatList redesenhada, "Casa" aparece sob a tarefa
```

### 10.3 Mudar de aba (o que o `useFocusEffect` resolve)

```
Aba Categorias: cria "Estudos"            → INSERT INTO categorias
Toca na aba "Tarefas"                     → a tela ganha foco
useFocusEffect dispara carregar()         → listarCategorias(db)
setCategorias(...)                        → o chip "Estudos" aparece
```

### 10.4 Excluir uma categoria

```
1. Toca em "Excluir"       → Alert de confirmação
2. Confirma                → removerCategoria(db, id)
3. SQL                     → DELETE FROM categorias WHERE id = ?
4. SQLite (foreign_keys=ON)→ UPDATE tarefas SET categoria_id = NULL WHERE categoria_id = ?   (automático)
5. carregar()              → lista de categorias atualizada
6. Ao voltar em "Tarefas"  → carregar() relê tudo; se o chip selecionado era essa categoria, volta a "Sem categoria"
```

O padrão **gravar → recarregar → redesenhar** vale para todas as ações.

---

## 11. Migrações: como o banco passou da v1 para a v2

A primeira versão do app tinha só a tabela `tarefas` (**v1**). Ao incluir categorias, o banco ganhou a tabela `categorias` e a coluna `tarefas.categoria_id` (**v2**). Quem já usava o app **tem um banco v1 no celular com dados** que não podem ser perdidos. Por isso **nunca** se edita o `CREATE TABLE` antigo: acrescenta-se um degrau novo.

```
Banco novo (user_version = 0):   degrau v1 → degrau v2   → fica em 2
Banco da versão antiga (= 1):                degrau v2   → fica em 2
Banco atual (= 2):               nenhum degrau executa
```

Pontos de cuidado no código:

1. **Cada degrau é um `if (atual === N)`** e termina com `atual = N + 1`, para o seguinte poder rodar em sequência num banco novo.
2. **O `user_version` é gravado junto com o degrau**, não só no final. Assim, se o app fechar entre dois degraus, na próxima abertura ele continua de onde parou.
3. **O degrau v2 usa `withTransactionAsync`.** Se `ALTER TABLE` falhar depois do `CREATE TABLE categorias`, tudo é desfeito, inclusive o `user_version`. Sem transação, o banco ficaria com a tabela criada e a versão antiga, e a próxima abertura falharia com `table categorias already exists`. (O degrau v1 não usa transação porque contém `PRAGMA journal_mode`, que não pode rodar dentro de uma.)
4. **`ALTER TABLE ... ADD COLUMN` com `REFERENCES`** exige que a coluna nova aceite `NULL` (sem `NOT NULL` e sem valor padrão diferente de `NULL`). Por isso as tarefas antigas ficam "sem categoria".

### Como criar a v3 (exemplo: data de criação)

```ts
if (atual === 2) {
  await db.withTransactionAsync(async () => {
    await db.execAsync(`
      ALTER TABLE tarefas ADD COLUMN criada_em TEXT;
      PRAGMA user_version = 3;
    `);
  });
  atual = 3;
}
```

O campo deve ser acrescentado ao tipo `Tarefa` e ao `SELECT` de `listar`.

---

## 12. Problemas comuns

| Sintoma | Causa provável | Solução |
|---|---|---|
| QR Code lido, mas o app não carrega | Celular e PC em redes diferentes ou firewall | Mesma rede Wi-Fi; ou `npx expo start --tunnel` |
| `npm install` falha com erro de versão | Node muito antigo | Atualizar para o Node LTS atual |
| Aviso de versões incompatíveis de pacotes | Pacote instalado com `npm install` | `npx expo install --fix` |
| Erros estranhos após mudar dependências, `app.json` ou `main` | Cache do Metro | `npx expo start --clear` |
| Tela "Unmatched Route" ou o app abre vazio | Faltou `"main": "expo-router/entry"`, ou arquivos fora de `src/app/` | Conferir a seção 7.1 e a estrutura da seção 6 |
| Erro "No route named X exists" no `Tabs.Screen` | `name` não corresponde a um arquivo de `src/app/` | `name="categorias"` exige `categorias.tsx` |
| Categoria nova não aparece na aba Tarefas | Tela carregando com `useEffect` em vez de `useFocusEffect` | Usar `useFocusEffect` (seção 8.5) |
| Excluir categoria não zera a categoria das tarefas / erro de chave estrangeira não aparece | `PRAGMA foreign_keys = ON` ausente | Manter essa instrução no início de `migrar` |
| Erro "no such table: categorias" ou "no such column: categoria_id" | Banco criado durante testes com esquema incompleto | Desinstalar o app do aparelho (apaga o banco) ou limpar os dados do app |
| Zerar os dados para testar | , | Limpar o armazenamento do Expo Go ou desinstalar o app |
| Falha ao rodar na web | `expo-sqlite` na web é experimental e exige configuração adicional | Testar em Android/iOS |
| Pacote com código nativo novo não funciona no Expo Go | Expo Go só inclui módulos nativos próprios | Criar um *development build*: `npx expo run:android` |

---

## 13. Pontos de atenção neste código

Observações sobre o que pode ser melhorado (nada impede o app de funcionar):

1. **Erros do banco só são tratados em `salvar` de categoria**, e ali qualquer erro é mostrado como "já existe". As demais operações não têm `try/catch`: se falharem, a exceção não é capturada.
2. **Sem confirmação ao excluir tarefa.** Um toque em "Excluir" apaga na hora (a exclusão de categoria, por afetar outras tarefas, pede confirmação).
3. **`feita` é `number`**, não `boolean` (limitação do SQLite). Convém converter ao ler.
4. **Dois toques rápidos em "Adicionar"** podem inserir duas vezes, pois o campo só é limpo depois do `await`. Convém limpar o campo antes ou desabilitar o botão durante a gravação.
5. **O chip selecionado permanece após adicionar uma tarefa.** É intencional (útil para cadastrar várias na mesma categoria), mas pode surpreender.
6. **Cada tela recarrega do banco ao ganhar foco**, mesmo sem mudanças. É simples e correto para listas pequenas; com milhares de linhas, convém considerar paginação.
7. **Não é possível mover uma tarefa para outra categoria depois de criada** nem renomear categorias (ver exercícios).
8. **Ícones são emojis**, que variam de aparência entre Android e iOS. Para ícones uniformes, recomenda-se `@expo/vector-icons` (já incluso no Expo).
9. **Sem testes automatizados.** O SQL da `db.ts` é a parte mais valiosa para testar.

---

## 14. Exercícios e próximos passos

Da mais simples à mais difícil:

1. **Filtrar por categoria** na aba Tarefas: reaproveitar os chips como filtro e adicionar `WHERE t.categoria_id = ?` em `listar` (atenção ao caso `NULL`: usar `IS NULL`).
2. **Renomear categoria**: novo `UPDATE categorias SET nome = ? WHERE id = ?` em `db.ts`. Tratar o erro de nome duplicado como em `salvar`.
3. **Trocar a categoria de uma tarefa**: um `UPDATE tarefas SET categoria_id = ? WHERE id = ?` e um jeito de escolher (toque longo abrindo as opções).
4. **Contador de pendentes** no ícone da aba: `tabBarBadge` em `Tabs.Screen`, alimentado por um `SELECT COUNT(*)`.
5. **Migração v3** com data de criação (seção 11) e exibição ordenada por data.
6. **Cor por categoria**: nova coluna `cor TEXT` (migração v3), `<TextInput>` ou lista fixa de cores no cadastro, e uso da cor no chip e na tarefa.
7. **Tela de detalhe da tarefa** (3ª rota empilhada): criar `src/app/tarefa/[id].tsx`, navegar com `router.push('/tarefa/3')` e ler o `id` com `useLocalSearchParams`. Isso exige um `Stack` em volta das abas: consultar a documentação do Expo Router sobre *nesting navigators*.
8. **Trocar abas por menu lateral**: instalar as dependências do `Drawer` conforme a documentação e trocar `Tabs` por `Drawer`.
9. **Modo escuro**: remover `userInterfaceStyle: "light"` e usar `useColorScheme()` do `react-native` nos estilos.
10. **Testes** das funções de `db.ts` e **publicação** com EAS Build e EAS Submit.

Documentação oficial: <https://docs.expo.dev/router/introduction/>

---

*Documentação gerada a partir do código do projeto na versão 1.0.0 (Expo SDK 58, React Native 0.88.1, React 19.3.0, Expo Router 58).*
