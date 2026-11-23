# Aula 26 — Capacitor: tutorial de um mini aplicativo de delivery com SQLite

**Unidade:** V — Estilos arquiteturais, renderização e análise comparativa
**Pré-requisito:** [Aula 25 — Android com Capacitor](./aula-25-android-capacitor.md)

## Objetivos da aula

- Construir, com tecnologias web, um aplicativo Android de três páginas inspirado em plataformas de entrega de comida.
- Integrar a aplicação web a um banco de dados SQLite local por meio de um plugin Capacitor.
- Organizar o código em uma camada de acesso a dados separada da camada de apresentação.

---

## 1. Visão geral

O aplicativo **Mini Delivery** possui três páginas e não exige autenticação:

| Página | Rota | Conteúdo |
|---|---|---|
| Restaurantes | `#/` | Lista de restaurantes com categoria e tempo de entrega |
| Cardápio | `#/restaurante/:id` | Pratos de um restaurante, com botão para adicionar ao carrinho |
| Carrinho | `#/carrinho` | Itens, total, finalização do pedido e histórico dos últimos pedidos |

Todos os dados (restaurantes, pratos, carrinho e pedidos) residem em um banco SQLite no armazenamento interno do aplicativo. O carrinho, portanto, persiste mesmo quando o aplicativo é fechado.

### 1.1 Tecnologias

| Item | Função |
|---|---|
| **Vite** | Servidor de desenvolvimento e empacotador; gera o diretório `dist/` consumido pelo Capacitor |
| **JavaScript puro** | Interface e roteamento, sem *framework* de componentes |
| **Capacitor 8** | Contêiner nativo Android (Aula 25) |
| **`@capacitor-community/sqlite`** | Plugin que expõe o SQLite nativo do Android ao JavaScript |

O empacotador torna-se necessário porque o plugin é distribuído como módulo npm e precisa ser resolvido pela instrução `import`, o que um navegador não faz sozinho.

### 1.2 Arquitetura

```
┌──────────────────────── WebView ────────────────────────┐
│  main.js — apresentação                                 │
│  roteador por hash, três páginas, tratamento de cliques │
│                         │ chama funções                 │
│  db.js — acesso a dados                                 │
│  esquema, dados iniciais, consultas SQL parametrizadas  │
│                         │ @capacitor-community/sqlite   │
└─────────────────────────┼───────────────────────────────┘
                 ponte Capacitor (JSON assíncrono)
┌─────────────────────────┼───────────────────────────────┐
│  Plugin nativo (Java) → SQLite → arquivo delivery.db    │
└─────────────────────────────────────────────────────────┘
```

A camada de apresentação não contém SQL; ela apenas invoca funções como `listarRestaurantes()` ou `adicionarAoCarrinho(id)`. Essa separação corresponde ao padrão repositório estudado nas Aulas 13 e 18, aqui em sua forma mais simples.

### 1.3 Modelo de dados

```
restaurante (id, nome, categoria, tempo_entrega)
     1
     │
     N
prato (id, restaurante_id, nome, descricao, preco_centavos)
     1
     │
     0..1
carrinho (prato_id, quantidade)

pedido (id, criado_em, total_centavos)
```

Os valores monetários são armazenados como inteiros em centavos, o que evita os erros de arredondamento próprios da aritmética de ponto flutuante.

---

## 2. Passo a passo

Os comandos são apresentados para PowerShell e são idênticos em Linux e macOS. O ambiente (Node.js 22+, Android Studio, JDK 21 e emulador) é o mesmo da Aula 25.

### Passo 1 — Criar o projeto

```powershell
mkdir C:\dev\mini-delivery
cd C:\dev\mini-delivery
npm init -y
mkdir src
```

### Passo 2 — Instalar as dependências

```powershell
npm install @capacitor/core @capacitor/android @capacitor-community/sqlite
npm install -D vite @capacitor/cli
```

### Passo 3 — Configurar o `package.json`

Define-se o projeto como módulo ES e acrescentam-se os scripts do Vite:

```powershell
npm pkg set type=module
npm pkg set scripts.dev=vite
npm pkg set "scripts.build=vite build"
```

### Passo 4 — Página base: `index.html`

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

### Passo 5 — Camada de dados: `src/db.js`

O módulo concentra todo o acesso ao SQLite. Os pontos centrais são:

- `SQLiteConnection` é o objeto de gerenciamento de conexões fornecido pelo plugin;
- `abrirBanco()` cria (ou reaproveita) a conexão com o banco `delivery`, cria as tabelas com `CREATE TABLE IF NOT EXISTS` e insere os dados iniciais somente se a tabela `restaurante` estiver vazia;
- `query()` executa consultas `SELECT` e devolve as linhas em `values`; `run()` executa uma instrução de modificação; `execute()` executa um bloco de várias instruções em uma transação;
- os valores variáveis são passados como parâmetros (`?`), nunca concatenados ao texto SQL, o que previne injeção de SQL.

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

A função `adicionarAoCarrinho` emprega duas instruções: `INSERT OR IGNORE` garante a existência da linha do prato no carrinho, e o `UPDATE` subsequente incrementa a quantidade. A construção funciona em qualquer versão do SQLite, independentemente do suporte à cláusula `ON CONFLICT ... DO UPDATE`.

### Passo 6 — Camada de apresentação: `src/main.js`

O módulo implementa:

- **três funções de página**, cada uma assíncrona e responsável por devolver o HTML da página a partir dos dados lidos do banco;
- **um roteador por hash**: a função `renderizar()` interpreta `location.hash` e é reexecutada a cada evento `hashchange`. O uso de *hash* dispensa configuração de servidor, pois a navegação nunca solicita outro arquivo ao servidor local do Capacitor;
- **delegação de eventos**: um único ouvinte de cliques no `<main>` identifica o botão pelo atributo `data-acao`, executa a operação no banco e redesenha a página;
- **escape de texto** (`esc`) antes da inserção em `innerHTML`, prática que impede a interpretação de dados como marcação.

```js
import './style.css';
import * as banco from './db.js';

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
    await banco.abrirBanco();
    await renderizar();
  } catch (erro) {
    app.textContent = 'Erro ao abrir o banco de dados: ' + erro.message;
  }
}

iniciar();
```

### Passo 7 — Estilos: `src/style.css`

A folha de estilos aplica os princípios das Aulas 3, 4 e 7: unidades relativas, área segura (`env(safe-area-inset-*)`) e alvos de toque de no mínimo 48 × 48 px.

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

### Passo 8 — Gerar a versão web

```powershell
npm run build
```

O Vite produz o diretório `dist/`, que será copiado para o projeto Android.

> **Observação:** a execução com `npm run dev` no navegador do computador exibe a mensagem de erro de abertura do banco. No navegador, o plugin depende de um armazenamento alternativo (pacotes `jeep-sqlite` e `sql.js`), não configurado neste tutorial; o banco SQLite é utilizado apenas no Android.

### Passo 9 — Inicializar o Capacitor e adicionar o Android

```powershell
npx cap init "Mini Delivery" br.edu.exemplo.minidelivery --web-dir dist
npx cap add android
npx cap sync android
```

A saída de `npx cap sync` deve listar o plugin detectado:

```
[info] Found 1 Capacitor plugin for android:
       @capacitor-community/sqlite@8.1.1
```

O registro do plugin no projeto Android é automático; não há alteração a fazer em `MainActivity` nem no `AndroidManifest.xml`, pois o SQLite não exige permissões.

### Passo 10 — Executar no emulador

Com o emulador em execução:

```powershell
npx cap run android
```

ou, alternativamente, `npx cap open android` e **Run ▶** no Android Studio.

### Passo 11 — Verificar o funcionamento

1. A página inicial lista os três restaurantes.
2. Ao tocar em um restaurante, abre-se o cardápio; o botão **Adicionar** incrementa o contador do cabeçalho.
3. A página **Carrinho** apresenta itens, subtotais e total; o botão **−** reduz a quantidade e remove o item quando ela chega a zero.
4. **Finalizar pedido** registra o pedido na tabela `pedido`, esvazia o carrinho e o exibe em **Últimos pedidos**.
5. Ao fechar completamente o aplicativo e abri-lo de novo, o carrinho e os pedidos permanecem, o que confirma a persistência em SQLite.

### Passo 12 — Ciclo de alteração

Toda modificação em `index.html` ou em `src/` exige:

```powershell
npm run build
npx cap copy android
npx cap run android
```

A inspeção do WebView (console, rede e erros de JavaScript) é feita no Chrome do computador, em `chrome://inspect`, conforme a Aula 25.

---

## 3. Estrutura final do projeto

```
mini-delivery/
├── android/                 ← projeto nativo gerado pelo Capacitor
├── dist/                    ← saída do Vite (copiada para o Android)
├── src/
│   ├── db.js                ← camada de dados (SQLite)
│   ├── main.js              ← camada de apresentação e roteamento
│   └── style.css
├── capacitor.config.ts
├── index.html
└── package.json
```

## 4. Síntese

- Um aplicativo Capacitor com várias páginas pode ser construído como aplicação de página única com roteamento por *hash*, sem *framework*.
- O plugin `@capacitor-community/sqlite` dá ao JavaScript acesso a um banco SQLite nativo, persistente no armazenamento interno do aplicativo.
- A separação entre `db.js` (dados) e `main.js` (apresentação) mantém o SQL isolado em um único módulo, o que facilita a substituição do armazenamento e a manutenção.
- Consultas parametrizadas, valores monetários em centavos e escape de texto na interface são práticas que se aplicam independentemente da plataforma.

## Referências

- IONIC. *Capacitor Documentation — Android*. Disponível em: https://capacitorjs.com/docs/android.
- CAPACITOR COMMUNITY. *@capacitor-community/sqlite*. Disponível em: https://github.com/capacitor-community/sqlite.
- VITE. *Guia do Vite*. Disponível em: https://vite.dev/guide/.
- SQLITE. *SQL As Understood By SQLite*. Disponível em: https://www.sqlite.org/lang.html.
