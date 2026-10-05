import axios, { AxiosInstance } from 'axios';
import { MMKV } from 'react-native-mmkv';
import { baseUrlApiSimulada } from './config';
import { NetworkError } from './erros';
import { AlteracaoPendente, Pedido } from './pedido';

const armazenamento = new MMKV();

export interface PedidoRepository {
  obterPedidos(): Promise<Pedido[]>;
  enviarAlteracao(alteracao: AlteracaoPendente): Promise<void>;
}

function criarCliente(): AxiosInstance {
  const api = axios.create({ baseURL: baseUrlApiSimulada, timeout: 8000 });
  api.interceptors.response.use(
    (resposta) => resposta,
    (erro) => {
      if (!erro.response) throw new NetworkError('Sem conexão com o servidor');
      throw erro;
    }
  );
  return api;
}

export class PedidoRepositoryImpl implements PedidoRepository {
  private api = criarCliente();

  async obterPedidos(): Promise<Pedido[]> {
    try {
      const resposta = await this.api.get<Pedido[]>('/pedidos');
      armazenamento.set('pedidos_cache', JSON.stringify(resposta.data));
      return resposta.data;
    } catch (erro) {
      if (erro instanceof NetworkError) {
        const cache = armazenamento.getString('pedidos_cache');
        return cache ? JSON.parse(cache) : [];
      }
      throw erro;
    }
  }

  async enviarAlteracao(alteracao: AlteracaoPendente): Promise<void> {
    try {
      await this.api.patch(`/pedidos/${alteracao.pedidoId}`, { status: alteracao.novoStatus });
    } catch (erro) {
      if (erro instanceof NetworkError) {
        this.enfileirarPendente(alteracao);
        return;
      }
      throw erro;
    }
  }

  private enfileirarPendente(alteracao: AlteracaoPendente): void {
    const pendentesJson = armazenamento.getString('alteracoes_pendentes');
    const pendentes: AlteracaoPendente[] = pendentesJson ? JSON.parse(pendentesJson) : [];
    pendentes.push(alteracao);
    armazenamento.set('alteracoes_pendentes', JSON.stringify(pendentes));
  }

  async sincronizarPendentes(): Promise<void> {
    const pendentesJson = armazenamento.getString('alteracoes_pendentes');
    const pendentes: AlteracaoPendente[] = pendentesJson ? JSON.parse(pendentesJson) : [];
    const restantes: AlteracaoPendente[] = [];

    for (const alteracao of pendentes) {
      try {
        await this.api.patch(`/pedidos/${alteracao.pedidoId}`, { status: alteracao.novoStatus });
      } catch {
        restantes.push(alteracao); // mantém para tentar depois
      }
    }
    armazenamento.set('alteracoes_pendentes', JSON.stringify(restantes));
  }
}
