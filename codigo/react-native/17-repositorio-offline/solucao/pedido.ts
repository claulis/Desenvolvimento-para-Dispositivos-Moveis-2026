export interface Pedido {
  id: string;
  status: string;
  total: number;
}

export interface AlteracaoPendente {
  pedidoId: string;
  novoStatus: string;
}
