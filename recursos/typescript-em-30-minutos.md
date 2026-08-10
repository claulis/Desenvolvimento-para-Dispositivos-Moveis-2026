# TypeScript em 30 minutos — só o que este componente usa

Este não é um curso de TypeScript. Cobre exclusivamente a sintaxe usada nos exemplos das Aulas 13–19, para quem chega ao componente com JavaScript/ES6 mas sem experiência prévia em TypeScript. Se sua equipe já tem essa base, pule este anexo.

## Tipagem básica

```ts
let nome: string = 'Ana';
let idade: number = 30;
let ativo: boolean = true;
let itens: string[] = ['a', 'b'];       // array de strings
let par: [string, number] = ['a', 1];   // tupla: tipos fixos por posição
```

## `interface`

Descreve o formato esperado de um objeto — usada para modelar dados de domínio e contratos de repositório (Aulas 13–17):

```ts
interface Pedido {
  id: string;
  total: number;
  itens: Item[];
}

interface PedidoRepository {
  obterPedidos(): Promise<Pedido[]>;
  salvarPedido(pedido: Pedido): Promise<void>;
}
```

## Genéricos (`<T>`)

Permitem escrever uma função/tipo que funciona para qualquer tipo `T`, mantendo a checagem de tipo — é o que torna `useState<Pedido[]>([])` diferente de um `useState([])` sem tipo:

```ts
function primeiro<T>(lista: T[]): T | undefined {
  return lista[0];
}

const p = primeiro<Pedido>(pedidos); // p é inferido como Pedido | undefined
```

```tsx
const [pedidos, setPedidos] = useState<Pedido[]>([]); // sem o genérico, TS infere never[]
```

## `as` (asserção de tipo)

Diz ao compilador "eu sei o tipo real disto, mesmo que você não consiga inferir" — usado ao desserializar JSON (Aula 15), onde o compilador não tem como saber a forma dos dados vindos da rede:

```ts
const total = (json.total as number);
const id = (json.id as string);
```

**Cuidado**: `as` não converte o valor — apenas instrui o compilador a tratá-lo como aquele tipo. Se o dado real não corresponder, o erro só aparece em tempo de execução, não de compilação.

## Tipos opcionais e `null`/`undefined`

```ts
interface Usuario {
  nome: string;
  apelido?: string; // opcional: pode não existir no objeto
}

function saudacao(usuario: Usuario) {
  return usuario.apelido ?? usuario.nome; // ?? usa o da direita se o da esquerda for null/undefined
}
```

## Async/await e `Promise<T>`

Sintaxe idêntica ao Dart em espírito (Aula 11), com `Promise<T>` no lugar de `Future<T>`:

```ts
async function obterPedidos(): Promise<Pedido[]> {
  const resposta = await fetch('https://api.exemplo.com/pedidos');
  const dados = await resposta.json();
  return dados as Pedido[];
}
```

## Onde continuar

Documentação oficial: [typescriptlang.org/docs/handbook](https://www.typescriptlang.org/docs/handbook/intro.html) — cobre em profundidade tudo o que este resumo simplificou.
