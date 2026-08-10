import axios from 'axios';
import { baseUrlApiSimulada } from './config';
import { Pedido } from './pedido';
// TODO (Aula 15 §1): defina NetworkError em erros.ts e importe aqui —
// este arquivo referencia o tipo sem declará-lo, o que não compila.
// import { NetworkError } from './erros';

// TODO (Aula 15 §1): esta interface não declara enviarAlteracao, mas a
// sincronização de pendências (que você vai implementar) precisa dela.
// Adicione o método à interface e à implementação abaixo.
export interface PedidoRepository {
  obterPedidos(): Promise<Pedido[]>;
}

export class PedidoRepositoryImpl implements PedidoRepository {
  private api = axios.create({ baseURL: baseUrlApiSimulada, timeout: 8000 });

  async obterPedidos(): Promise<Pedido[]> {
    const resposta = await this.api.get<Pedido[]>('/pedidos');
    return resposta.data;
    // TODO: capturar falha de conectividade (NetworkError, depois de
    // definida) e retornar dados de um cache local (MMKV), como na Aula 15 §1.
  }
}
