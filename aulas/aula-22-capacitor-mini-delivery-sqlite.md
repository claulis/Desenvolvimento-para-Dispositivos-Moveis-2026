# Aula 22 — Capacitor: tutorial progressivo de um mini aplicativo de delivery, da memória ao SQLite

**Carga horária:** 4h
**Unidade:** V — Aplicações híbridas com Capacitor
**Pré-requisito:** [Aula 21 — Android com Capacitor](./aula-21-android-capacitor.md)

## Objetivos da aula

- Construir, com tecnologias web e Capacitor, um aplicativo Android de três páginas inspirado em plataformas de entrega de comida.
- Desenvolver o aplicativo em duas etapas: primeiro com dados em memória, depois com persistência em SQLite.
- Demonstrar que a separação entre camada de apresentação e camada de dados permite trocar o armazenamento com apenas duas alterações pontuais na camada de apresentação.

---

## 1. Visão geral

O aplicativo **Mini Delivery** possui três páginas e não exige autenticação:

| Página | Rota | Conteúdo |
|---|---|---|
| Restaurantes | `#/` | Lista de restaurantes com categoria e tempo de entrega |
| Cardápio | `#/restaurante/:id` | Pratos de um restaurante, com botão para adicionar ao carrinho |
| Carrinho | `#/carrinho` | Itens, total, finalização do pedido e histórico dos últimos pedidos |

O desenvolvimento é dividido em duas partes:

| Parte | Armazenamento | Executa no navegador | Executa no Android | Dados sobrevivem ao fechamento do app |
|---|---|---|---|---|
| **A** | Vetores e `Map` em memória (`src/dados.js`) | Sim | Sim | Não |
| **B** | Banco SQLite nativo (`src/db.js`) | Não | Sim | Sim |

### 1.1 Arquitetura

```
┌──────────────────────── WebView ─────────────────────────┐
│  main.js — apresentação                                  │
│  roteador por hash, três páginas, tratamento de cliques  │
│                    │ chama as mesmas funções             │
│        ┌───────────┴────────────┐                        │
│   Parte A: dados.js        Parte B: db.js                │
│   (memória)                (SQL parametrizado)           │
└────────────────────────────────┼─────────────────────────┘
                     ponte Capacitor (JSON assíncrono)
┌────────────────────────────────┼─────────────────────────┐
│  Plugin nativo (Java) → SQLite → arquivo do banco        │
└──────────────────────────────────────────────────────────┘
```

Os módulos `dados.js` e `db.js` exportam **as mesmas funções, com os mesmos nomes e o mesmo formato de retorno**. Por esse motivo, todas as funções da Parte A são declaradas como `async`, embora operem sobre a memória: a interface da camada de dados já nasce compatível com o acesso assíncrono ao banco da Parte B. Trata-se do padrão repositório das Aulas 13 e 18 em sua forma mais simples.

### 1.2 Tecnologias

| Item | Função |
|---|---|
| **Vite** | Servidor de desenvolvimento e empacotador; gera o diretório `dist/` consumido pelo Capacitor |
| **JavaScript puro** | Interface e roteamento, sem *framework* de componentes |
| **Capacitor 8** | Contêiner nativo Android (Aula 21) |
| **`@capacitor-community/sqlite`** | Plugin que expõe o SQLite nativo do Android ao JavaScript (Parte B) |

O empacotador é necessário porque os pacotes npm são importados com `import` por nome (por exemplo, `'@capacitor-community/sqlite'`), resolução que o navegador não realiza sozinho.

---

## 2. Preparação do ambiente

O tutorial pressupõe **Android Studio**, **VS Code** e **Node.js** instalados no Windows. Os comandos são executados no terminal integrado do VS Code (**Terminal → New Terminal**), que utiliza o PowerShell.

### Passo 0.1 — Conferir o Node.js

```powershell
node --version
npm --version
```

O Capacitor 8 exige Node.js **22 ou superior**. Caso a versão seja inferior, instala-se a versão LTS atual a partir de https://nodejs.org.

### Passo 0.2 — Conferir o Android Studio, o SDK e o emulador

1. Abrir o Android Studio e concluir o assistente inicial (**Standard**), que instala o Android SDK.
2. Em **More Actions → SDK Manager**, anotar o campo **Android SDK Location** (normalmente `C:\Users\<usuário>\AppData\Local\Android\Sdk`).
3. Em **More Actions → Virtual Device Manager**, criar um dispositivo (**Medium Phone** ou Pixel, imagem de sistema mais recente) e iniciá-lo com ▶ para conferir que o Android é carregado.

### Passo 0.3 — Variáveis de ambiente

A CLI do Capacitor compila o projeto com o Gradle fora do Android Studio e, para isso, precisa localizar o Java e o SDK. O Android Studio já inclui um JDK (pasta `jbr`), que pode ser reaproveitado. No PowerShell:

```powershell
[Environment]::SetEnvironmentVariable("JAVA_HOME", "C:\Program Files\Android\Android Studio\jbr", "User")
[Environment]::SetEnvironmentVariable("ANDROID_HOME", "$env:LOCALAPPDATA\Android\Sdk", "User")
```

Os caminhos devem ser ajustados caso o Android Studio ou o SDK estejam em outro local. Em seguida, **fecha-se e reabre-se o VS Code** para que as variáveis sejam carregadas, e confere-se:

```powershell
& "$env:JAVA_HOME\bin\java" -version
Test-Path "$env:ANDROID_HOME\platform-tools\adb.exe"
```

O segundo comando deve retornar `True`.

---

## 3. Parte A — Aplicativo com dados em memória

### Passo A1 — Criar o projeto

```powershell
mkdir C:\dev\mini-delivery
cd C:\dev\mini-delivery
npm init -y
mkdir src
code .
```

O caminho não deve conter espaços nem acentos e não deve estar dentro do OneDrive. O comando `code .` abre a pasta no VS Code, onde os arquivos dos passos seguintes são criados.

### Passo A2 — Instalar as dependências

```powershell
npm install @capacitor/core @capacitor/android
npm install -D vite @capacitor/cli
```

### Passo A3 — Configurar o `package.json`

Define-se o projeto como módulo ES e acrescentam-se os scripts do Vite:

```powershell
npm pkg set type=module
npm pkg set scripts.dev=vite
npm pkg set "scripts.build=vite build"
```

### Passo A4 — Página base: `index.html`

Criado na raiz do projeto, contém apenas o cabeçalho fixo e o elemento `<main>`, no qual as três páginas são desenhadas.

```html
<!DOCTYPE html>
<html lang="pt-BR">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
  <title>Mini Delivery</title>
</head>
<body>
  <header>
    <a href="#/">🍽️ Mini Delivery</a>
    <a href="#/carrinho" id="link-carrinho">Carrinho (0)</a>
  </header>
  <main id="app">Carregando…</main>
  <script type="module" src="/src/main.js"></script>
</body>
</html>
```

### Passo A5 — Camada de dados em memória: `src/dados.js`

Os restaurantes e os pratos são vetores constantes; o carrinho é um `Map` que associa o identificador do prato à quantidade; os pedidos são acumulados em um vetor. Os nomes das propriedades (`tempo_entrega`, `preco_centavos`, `restaurante_id`) já seguem os nomes das colunas que serão usadas no banco na Parte B. Os valores monetários são inteiros em centavos, o que evita erros de arredondamento de ponto flutuante.

```js
// Dados em memória: existem apenas enquanto o aplicativo está aberto.
// As funções são assíncronas para terem a mesma interface da versão com SQLite (Parte B).

const restaurantes = [
  { id: 1, nome: 'Pizzaria Napoli', categoria: 'Pizza', tempo_entrega: 40 },
  { id: 2, nome: 'Sushi Kento', categoria: 'Japonesa', tempo_entrega: 50 },
  { id: 3, nome: 'Burger da Praça', categoria: 'Lanches', tempo_entrega: 30 },
];

const pratos = [
  { id: 1, restaurante_id: 1, nome: 'Pizza Margherita', descricao: 'Molho de tomate, muçarela e manjericão', preco_centavos: 4990 },
  { id: 2, restaurante_id: 1, nome: 'Pizza Calabresa', descricao: 'Calabresa fatiada e cebola', preco_centavos: 4590 },
  { id: 3, restaurante_id: 2, nome: 'Combinado 20 peças', descricao: 'Sashimi, niguiri e uramaki', preco_centavos: 6990 },
  { id: 4, restaurante_id: 2, nome: 'Temaki de salmão', descricao: 'Salmão, arroz e cebolinha', preco_centavos: 2890 },
  { id: 5, restaurante_id: 3, nome: 'X-Burger', descricao: 'Pão, hambúrguer 150 g e queijo', preco_centavos: 2490 },
  { id: 6, restaurante_id: 3, nome: 'Batata frita', descricao: 'Porção de 300 g', preco_centavos: 1590 },
];

const carrinho = new Map(); // prato_id → quantidade
const pedidos = [];

export async function listarRestaurantes() {
  return [...restaurantes].sort((a, b) => a.nome.localeCompare(b.nome));
}

export async function buscarRestaurante(id) {
  return restaurantes.find((r) => r.id === id);
}

export async function listarPratos(restauranteId) {
  return pratos
    .filter((p) => p.restaurante_id === restauranteId)
    .sort((a, b) => a.nome.localeCompare(b.nome));
}

export async function adicionarAoCarrinho(pratoId) {
  carrinho.set(pratoId, (carrinho.get(pratoId) ?? 0) + 1);
}

export async function removerDoCarrinho(pratoId) {
  const quantidade = (carrinho.get(pratoId) ?? 0) - 1;
  if (quantidade > 0) carrinho.set(pratoId, quantidade);
  else carrinho.delete(pratoId);
}

export async function listarCarrinho() {
  return [...carrinho].map(([pratoId, quantidade]) => {
    const p = pratos.find((x) => x.id === pratoId);
    return { id: p.id, nome: p.nome, preco_centavos: p.preco_centavos, quantidade,
             subtotal_centavos: p.preco_centavos * quantidade };
  }).sort((a, b) => a.nome.localeCompare(b.nome));
}

export async function contarItensCarrinho() {
  return [...carrinho.values()].reduce((soma, q) => soma + q, 0);
}

export async function finalizarPedido() {
  const itens = await listarCarrinho();
  const total = itens.reduce((soma, i) => soma + i.subtotal_centavos, 0);
  pedidos.push({ id: pedidos.length + 1, criado_em: new Date().toLocaleString('pt-BR'), total_centavos: total });
  carrinho.clear();
}

export async function listarPedidos() {
  return [...pedidos].reverse().slice(0, 5);
}
```

### Passo A6 — Camada de apresentação: `src/main.js`

O módulo implementa:

- **três funções de página**, assíncronas, que devolvem o HTML de cada página a partir dos dados obtidos da camada de dados;
- **um roteador por hash**: `renderizar()` interpreta `location.hash` e é reexecutada a cada evento `hashchange`. O uso de *hash* dispensa configuração de servidor, pois a navegação nunca solicita outro arquivo;
- **delegação de eventos**: um único ouvinte de cliques no `<main>` identifica o botão pelo atributo `data-acao`, executa a operação e redesenha a página;
- **escape de texto** (`esc`) antes da inserção em `innerHTML`, o que impede que dados sejam interpretados como marcação.

A camada de dados é importada com o apelido `banco`, nome que permanecerá inalterado na Parte B.

```js
import './style.css';
import * as banco from './dados.js';

const app = document.getElementById('app');
const reais = new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' });
const preco = (centavos) => reais.format(centavos / 100);
const esc = (texto) => String(texto).replace(/[&<>"']/g, (c) => `&#${c.charCodeAt(0)};`);

// Página 1: lista de restaurantes
async function paginaRestaurantes() {
  const restaurantes = await banco.listarRestaurantes();
  return `
    <h1>Restaurantes</h1>
    <ul class="lista">
      ${restaurantes.map((r) => `
        <li>
          <a class="cartao" href="#/restaurante/${r.id}">
            <strong>${esc(r.nome)}</strong>
            <span>${esc(r.categoria)} · ${r.tempo_entrega} min</span>
          </a>
        </li>`).join('')}
    </ul>`;
}

// Página 2: cardápio de um restaurante
async function paginaCardapio(id) {
  const restaurante = await banco.buscarRestaurante(id);
  if (!restaurante) return '<p>Restaurante não encontrado.</p>';
  const pratos = await banco.listarPratos(id);
  return `
    <a href="#/">← Voltar</a>
    <h1>${esc(restaurante.nome)}</h1>
    <ul class="lista">
      ${pratos.map((p) => `
        <li class="cartao">
          <strong>${esc(p.nome)}</strong>
          <span>${esc(p.descricao)}</span>
          <div class="linha">
            <span>${preco(p.preco_centavos)}</span>
            <button data-acao="adicionar" data-id="${p.id}">Adicionar</button>
          </div>
        </li>`).join('')}
    </ul>`;
}

// Página 3: carrinho e pedidos realizados
async function paginaCarrinho() {
  const itens = await banco.listarCarrinho();
  const pedidos = await banco.listarPedidos();
  const total = itens.reduce((soma, i) => soma + i.subtotal_centavos, 0);
  return `
    <h1>Carrinho</h1>
    ${itens.length === 0 ? '<p>O carrinho está vazio.</p>' : `
      <ul class="lista">
        ${itens.map((i) => `
          <li class="cartao linha">
            <span>${i.quantidade}× ${esc(i.nome)}</span>
            <span>${preco(i.subtotal_centavos)}</span>
            <button data-acao="remover" data-id="${i.id}" aria-label="Remover um ${esc(i.nome)}">−</button>
          </li>`).join('')}
      </ul>
      <p class="linha"><strong>Total</strong><strong>${preco(total)}</strong></p>
      <button data-acao="finalizar" class="principal">Finalizar pedido</button>`}
    <h2>Últimos pedidos</h2>
    ${pedidos.length === 0 ? '<p>Nenhum pedido realizado.</p>' : `
      <ul class="lista">
        ${pedidos.map((p) => `
          <li class="cartao linha">
            <span>#${p.id} · ${esc(p.criado_em)}</span>
            <span>${preco(p.total_centavos)}</span>
          </li>`).join('')}
      </ul>`}`;
}

// Roteador por hash: #/ , #/restaurante/2 , #/carrinho
async function renderizar() {
  const [, rota, id] = location.hash.split('/');
  if (rota === 'restaurante') app.innerHTML = await paginaCardapio(Number(id));
  else if (rota === 'carrinho') app.innerHTML = await paginaCarrinho();
  else app.innerHTML = await paginaRestaurantes();

  const n = await banco.contarItensCarrinho();
  document.getElementById('link-carrinho').textContent = `Carrinho (${n})`;
}

// Delegação de eventos: um único ouvinte trata todos os botões
app.addEventListener('click', async (evento) => {
  const botao = evento.target.closest('button[data-acao]');
  if (!botao) return;
  const id = Number(botao.dataset.id);
  if (botao.dataset.acao === 'adicionar') await banco.adicionarAoCarrinho(id);
  if (botao.dataset.acao === 'remover') await banco.removerDoCarrinho(id);
  if (botao.dataset.acao === 'finalizar') await banco.finalizarPedido();
  await renderizar();
});

window.addEventListener('hashchange', renderizar);

async function iniciar() {
  try {
    await renderizar();
  } catch (erro) {
    app.textContent = 'Erro: ' + erro.message;
  }
}

iniciar();
```

### Passo A7 — Estilos: `src/style.css`

A folha de estilos aplica os princípios das Aulas 3, 4 e 7: área segura (`env(safe-area-inset-*)`), unidades relativas e alvos de toque de no mínimo 48 × 48 px.

```css
* { box-sizing: border-box; }
body {
  margin: 0;
  font-family: system-ui, sans-serif;
  background: #f5f5f5;
  color: #222;
}
header {
  position: sticky; top: 0;
  display: flex; justify-content: space-between; align-items: center;
  padding: calc(env(safe-area-inset-top) + 12px) 16px 12px;
  background: #ea1d2c;
}
header a { color: #fff; font-weight: 600; text-decoration: none; }
main { padding: 16px 16px calc(env(safe-area-inset-bottom) + 16px); }
.lista { list-style: none; margin: 0; padding: 0; display: grid; gap: 12px; }
.cartao {
  display: flex; flex-direction: column; gap: 4px;
  padding: 16px; background: #fff; border-radius: 12px;
  color: inherit; text-decoration: none;
}
.linha { display: flex; justify-content: space-between; align-items: center; gap: 8px; }
.cartao.linha { flex-direction: row; }
button {
  min-height: 48px; min-width: 48px; padding: 0 16px;
  border: 1px solid #ea1d2c; border-radius: 8px;
  background: #fff; color: #ea1d2c; font-size: 1rem;
}
button.principal { width: 100%; background: #ea1d2c; color: #fff; }
```

### Passo A8 — Testar no navegador

```powershell
npm run dev
```

O Vite informa o endereço local (normalmente `http://localhost:5173`). Ao abri-lo no navegador, é possível navegar pelas três páginas, adicionar pratos, remover itens e finalizar pedidos. Para emular a tela de um celular, utilizam-se as ferramentas de desenvolvedor do navegador (**F12 → Toggle device toolbar**). O servidor é encerrado com **Ctrl + C**.

Ao recarregar a página (**F5**), o carrinho e os pedidos desaparecem: os dados existem apenas na memória da página.

### Passo A9 — Gerar a versão web e adicionar o Android

```powershell
npm run build
npx cap init "Mini Delivery" br.edu.exemplo.minidelivery --web-dir dist
npx cap add android
npx cap sync android
```

- `npm run build` gera o diretório `dist/`;
- `npx cap init` cria `capacitor.config.ts`, apontando `webDir` para `dist`;
- `npx cap add android` cria o projeto nativo na pasta `android/`;
- `npx cap sync android` copia `dist/` para `android/app/src/main/assets/public/`.

### Passo A10 — Executar no emulador

Com o emulador do Passo 0.2 em execução:

```powershell
npx cap run android
```

A CLI lista os dispositivos disponíveis; seleciona-se o emulador com as setas e **Enter**. A primeira compilação é demorada, pois o Gradle baixa suas dependências.

Alternativamente, executa-se `npx cap open android` e, no Android Studio, após a sincronização do Gradle, aciona-se **Run ▶**.

### Passo A11 — Verificar e observar a limitação

1. A página inicial lista os três restaurantes.
2. O cardápio permite adicionar pratos, e o contador do cabeçalho é atualizado.
3. O carrinho apresenta subtotais e total; **Finalizar pedido** move o pedido para **Últimos pedidos**.
4. Adicionam-se itens ao carrinho e **encerra-se o aplicativo completamente** (botão de aplicativos recentes do Android → deslizar o app para fora). Ao abri-lo novamente, o carrinho e os pedidos estão vazios.

A Parte B elimina essa limitação.

---

## 4. Parte B — Persistência com SQLite

A Parte B consiste em quatro modificações: instalar o plugin, criar `src/db.js`, fazer duas alterações em `src/main.js` e sincronizar o projeto Android. Os arquivos `index.html` e `style.css` permanecem inalterados.

### Passo B1 — Instalar o plugin SQLite

```powershell
npm install @capacitor-community/sqlite
```

### Passo B2 — Criar a camada de dados com SQLite: `src/db.js`

O novo módulo exporta as mesmas funções de `dados.js`, agora implementadas com SQL, e acrescenta `abrirBanco()`. Os pontos centrais são:

- `SQLiteConnection` é o gerenciador de conexões fornecido pelo plugin;
- `abrirBanco()` cria (ou reaproveita, após recarga do WebView) a conexão com o banco `delivery`, cria as tabelas com `CREATE TABLE IF NOT EXISTS` e insere os dados iniciais apenas se a tabela `restaurante` estiver vazia;
- `query()` executa consultas `SELECT` e devolve as linhas em `values`; `run()` executa uma instrução de modificação; `execute()` executa um bloco de instruções dentro de uma transação;
- os valores variáveis são passados como parâmetros (`?`), nunca concatenados ao texto SQL, o que previne injeção de SQL.

O modelo de dados corresponde exatamente às estruturas da Parte A:

| Parte A (memória) | Parte B (tabela) |
|---|---|
| vetor `restaurantes` | `restaurante (id, nome, categoria, tempo_entrega)` |
| vetor `pratos` | `prato (id, restaurante_id, nome, descricao, preco_centavos)` |
| `Map` `carrinho` | `carrinho (prato_id, quantidade)` |
| vetor `pedidos` | `pedido (id, criado_em, total_centavos)` |

```js
import { CapacitorSQLite, SQLiteConnection } from '@capacitor-community/sqlite';

const sqlite = new SQLiteConnection(CapacitorSQLite);
const NOME_BANCO = 'delivery';
let db;

const ESQUEMA = `
CREATE TABLE IF NOT EXISTS restaurante (
  id INTEGER PRIMARY KEY,
  nome TEXT NOT NULL,
  categoria TEXT NOT NULL,
  tempo_entrega INTEGER NOT NULL
);
CREATE TABLE IF NOT EXISTS prato (
  id INTEGER PRIMARY KEY,
  restaurante_id INTEGER NOT NULL REFERENCES restaurante(id),
  nome TEXT NOT NULL,
  descricao TEXT NOT NULL,
  preco_centavos INTEGER NOT NULL
);
CREATE TABLE IF NOT EXISTS carrinho (
  prato_id INTEGER PRIMARY KEY REFERENCES prato(id),
  quantidade INTEGER NOT NULL
);
CREATE TABLE IF NOT EXISTS pedido (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  criado_em TEXT NOT NULL DEFAULT (datetime('now', 'localtime')),
  total_centavos INTEGER NOT NULL
);`;

const DADOS_INICIAIS = `
INSERT INTO restaurante VALUES
  (1, 'Pizzaria Napoli', 'Pizza', 40),
  (2, 'Sushi Kento', 'Japonesa', 50),
  (3, 'Burger da Praça', 'Lanches', 30);
INSERT INTO prato VALUES
  (1, 1, 'Pizza Margherita', 'Molho de tomate, muçarela e manjericão', 4990),
  (2, 1, 'Pizza Calabresa', 'Calabresa fatiada e cebola', 4590),
  (3, 2, 'Combinado 20 peças', 'Sashimi, niguiri e uramaki', 6990),
  (4, 2, 'Temaki de salmão', 'Salmão, arroz e cebolinha', 2890),
  (5, 3, 'X-Burger', 'Pão, hambúrguer 150 g e queijo', 2490),
  (6, 3, 'Batata frita', 'Porção de 300 g', 1590);`;

export async function abrirBanco() {
  // Reaproveita a conexão se ela já existir (por exemplo, após recarregar o WebView).
  const consistente = (await sqlite.checkConnectionsConsistency()).result;
  const existe = (await sqlite.isConnection(NOME_BANCO, false)).result;
  db = consistente && existe
    ? await sqlite.retrieveConnection(NOME_BANCO, false)
    : await sqlite.createConnection(NOME_BANCO, false, 'no-encryption', 1, false);
  await db.open();
  await db.execute(ESQUEMA);

  const { values } = await db.query('SELECT COUNT(*) AS n FROM restaurante');
  if (values[0].n === 0) await db.execute(DADOS_INICIAIS);
}

export async function listarRestaurantes() {
  return (await db.query('SELECT * FROM restaurante ORDER BY nome')).values;
}

export async function buscarRestaurante(id) {
  return (await db.query('SELECT * FROM restaurante WHERE id = ?', [id])).values[0];
}

export async function listarPratos(restauranteId) {
  return (await db.query(
    'SELECT * FROM prato WHERE restaurante_id = ? ORDER BY nome', [restauranteId]
  )).values;
}

export async function adicionarAoCarrinho(pratoId) {
  await db.run('INSERT OR IGNORE INTO carrinho (prato_id, quantidade) VALUES (?, 0)', [pratoId]);
  await db.run('UPDATE carrinho SET quantidade = quantidade + 1 WHERE prato_id = ?', [pratoId]);
}

export async function removerDoCarrinho(pratoId) {
  await db.run('UPDATE carrinho SET quantidade = quantidade - 1 WHERE prato_id = ?', [pratoId]);
  await db.run('DELETE FROM carrinho WHERE quantidade <= 0');
}

export async function listarCarrinho() {
  return (await db.query(`
    SELECT p.id, p.nome, p.preco_centavos, c.quantidade,
           p.preco_centavos * c.quantidade AS subtotal_centavos
    FROM carrinho c JOIN prato p ON p.id = c.prato_id
    ORDER BY p.nome`)).values;
}

export async function contarItensCarrinho() {
  const { values } = await db.query('SELECT COALESCE(SUM(quantidade), 0) AS n FROM carrinho');
  return values[0].n;
}

export async function finalizarPedido() {
  // Uma única chamada execute roda as instruções dentro de uma transação.
  await db.execute(`
    INSERT INTO pedido (total_centavos)
      SELECT SUM(p.preco_centavos * c.quantidade)
      FROM carrinho c JOIN prato p ON p.id = c.prato_id;
    DELETE FROM carrinho;`);
}

export async function listarPedidos() {
  return (await db.query('SELECT * FROM pedido ORDER BY id DESC LIMIT 5')).values;
}
```

A função `adicionarAoCarrinho` emprega duas instruções: `INSERT OR IGNORE` garante a existência da linha do prato no carrinho, e o `UPDATE` subsequente incrementa a quantidade, construção compatível com qualquer versão do SQLite. Em `finalizarPedido`, o cálculo do total, a gravação do pedido e o esvaziamento do carrinho ocorrem em uma única transação: ou as duas instruções são aplicadas, ou nenhuma é.

### Passo B3 — Alterar `src/main.js`

São necessárias apenas duas alterações. Nenhuma função de página, o roteador e o tratamento de cliques mudam.

**Alteração 1** — trocar a origem dos dados (linha 2):

```diff
 import './style.css';
-import * as banco from './dados.js';
+import * as banco from './db.js';
```

**Alteração 2** — abrir o banco antes da primeira renderização, na função `iniciar()` ao final do arquivo:

```diff
 async function iniciar() {
   try {
+    await banco.abrirBanco();
     await renderizar();
   } catch (erro) {
-    app.textContent = 'Erro: ' + erro.message;
+    app.textContent = 'Erro ao abrir o banco de dados: ' + erro.message;
   }
 }
```

O arquivo `src/dados.js` deixa de ser utilizado e pode ser removido ou mantido como referência.

### Passo B4 — Gerar e sincronizar

```powershell
npm run build
npx cap sync android
```

Nesta etapa é indispensável o `sync`, e não apenas o `copy`, porque um plugin nativo foi instalado. A saída deve listar o plugin:

```
[info] Found 1 Capacitor plugin for android:
       @capacitor-community/sqlite@8.1.1
```

O registro do plugin no projeto Android é automático. Não há alterações em `MainActivity` nem no `AndroidManifest.xml`, pois o SQLite não exige permissões.

### Passo B5 — Executar no emulador

```powershell
npx cap run android
```

### Passo B6 — Verificar a persistência

1. A navegação e o comportamento das três páginas são idênticos aos da Parte A.
2. Adicionam-se itens ao carrinho, finaliza-se um pedido e adicionam-se novos itens.
3. Encerra-se o aplicativo completamente e abre-se de novo: o carrinho e o histórico de pedidos permanecem, pois estão gravados no banco SQLite no armazenamento interno do aplicativo.
4. Os dados só são apagados ao desinstalar o aplicativo ou ao limpar seus dados em **Configurações → Apps → Mini Delivery → Armazenamento**.

> **Importante:** a partir da Parte B, o aplicativo é executado sempre no emulador ou no aparelho Android, com `npx cap run android`, pois é no Android que o SQLite nativo está disponível. O comando `npm run dev` passa a ser utilizado apenas na Parte A.

### Passo B7 — Ciclo de alteração

Toda modificação em `index.html` ou em `src/` exige:

```powershell
npm run build
npx cap copy android
npx cap run android
```

Erros de JavaScript no aplicativo em execução são inspecionados no Chrome do computador, em `chrome://inspect`, conforme a Aula 21.

---

## 5. Estrutura final do projeto

```
mini-delivery/
├── android/                 ← projeto nativo gerado pelo Capacitor
├── dist/                    ← saída do Vite (copiada para o Android)
├── src/
│   ├── dados.js             ← Parte A: dados em memória (não utilizado na Parte B)
│   ├── db.js                ← Parte B: dados em SQLite
│   ├── main.js              ← apresentação e roteamento
│   └── style.css
├── capacitor.config.ts
├── index.html
└── package.json
```

## 6. Síntese

- Um aplicativo Capacitor com várias páginas pode ser construído como aplicação de página única com roteamento por *hash*, sem *framework*.
- A Parte A, com dados em memória, executa no navegador e no Android, mas perde o estado ao fechar o aplicativo.
- A Parte B substitui a camada de dados por SQLite por meio do plugin `@capacitor-community/sqlite`; como as duas camadas expõem a mesma interface assíncrona, a apresentação recebe apenas duas alterações pontuais.
- A troca do armazenamento sem impacto na interface é a evidência prática do benefício da separação em camadas estudada nas Aulas 12, 17 e 23.
- Consultas parametrizadas, transações, valores monetários em centavos e escape de texto na interface são práticas independentes de plataforma.

## Referências

- IONIC. *Capacitor Documentation — Android*. Disponível em: https://capacitorjs.com/docs/android.
- CAPACITOR COMMUNITY. *@capacitor-community/sqlite*. Disponível em: https://github.com/capacitor-community/sqlite.
- VITE. *Guia do Vite*. Disponível em: https://vite.dev/guide/.
- SQLITE. *SQL As Understood By SQLite*. Disponível em: https://www.sqlite.org/lang.html.
