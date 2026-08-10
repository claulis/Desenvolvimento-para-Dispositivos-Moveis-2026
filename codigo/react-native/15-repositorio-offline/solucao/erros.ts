// Erro de domínio, lançado pelo interceptador de rede quando a falha é de
// conectividade — distinto de um erro HTTP (4xx/5xx), que deve se propagar
// normalmente (Aula 15 §1).
export class NetworkError extends Error {
  constructor(mensagem: string) {
    super(mensagem);
    this.name = 'NetworkError';
  }
}
