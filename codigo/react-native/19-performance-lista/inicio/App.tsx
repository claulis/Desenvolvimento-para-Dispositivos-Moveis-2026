import React, { useState } from 'react';
import { FlatList, Pressable, StyleSheet, Text, View } from 'react-native';
import produtosJson from './produtos.json';
import { Produto } from './produto';

const produtos = produtosJson as Produto[];

// TODO (Aula 19): este é o componente da versão INEFICIENTE proposital
// (mesmo padrão da Aula 19 §3). CardProduto não é memoizado, e o
// `renderItem` abaixo é uma função inline recriada a cada render do App —
// mesmo que você adicione React.memo aqui, ele não vai ajudar sem também
// estabilizar renderItem/alternarFavorito com useCallback.
function CardProduto({
  produto,
  favoritado,
  onFavoritar,
}: {
  produto: Produto;
  favoritado: boolean;
  onFavoritar: (id: string) => void;
}) {
  return (
    <Pressable style={estilos.linha} onPress={() => onFavoritar(produto.id)}>
      <Text style={estilos.nome}>{produto.nome}</Text>
      <Text>{favoritado ? '♥' : '♡'}</Text>
    </Pressable>
  );
}

export default function App() {
  const [favoritos, setFavoritos] = useState<Set<string>>(new Set());

  function alternarFavorito(id: string) {
    setFavoritos((atual) => {
      const novo = new Set(atual);
      novo.has(id) ? novo.delete(id) : novo.add(id);
      return novo;
    });
  }

  return (
    <View style={estilos.container}>
      <FlatList
        data={produtos}
        // TODO: adicionar keyExtractor — sem ele, o React usa o índice
        // internamente, o antipadrão discutido na Aula 19 §5.
        renderItem={({ item }) => (
          <CardProduto
            produto={item}
            favoritado={favoritos.has(item.id)}
            onFavoritar={alternarFavorito}
          />
        )}
      />
    </View>
  );
}

const estilos = StyleSheet.create({
  container: { flex: 1, paddingTop: 48 },
  linha: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    padding: 12,
    borderBottomWidth: 1,
    borderBottomColor: '#eee',
  },
  nome: { fontSize: 16 },
});
