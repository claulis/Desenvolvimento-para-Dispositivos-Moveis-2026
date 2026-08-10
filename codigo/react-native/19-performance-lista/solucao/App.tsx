import React, { useCallback, useState } from 'react';
import { FlatList, ListRenderItemInfo, Pressable, StyleSheet, Text, View } from 'react-native';
import produtosJson from './produtos.json';
import { Produto } from './produto';

const produtos = produtosJson as Produto[];

// React.memo evita re-renderizar um card cujas props não mudaram — mas só
// funciona porque, abaixo, `renderItem` e `alternarFavorito` são estáveis
// entre renders do pai (via useCallback), não recriados a cada render.
const CardProduto = React.memo(function CardProduto({
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
});

export default function App() {
  const [favoritos, setFavoritos] = useState<Set<string>>(new Set());

  const alternarFavorito = useCallback((id: string) => {
    setFavoritos((atual) => {
      const novo = new Set(atual);
      novo.has(id) ? novo.delete(id) : novo.add(id);
      return novo;
    });
  }, []);

  // renderItem estável — não inline — para que React.memo em CardProduto
  // funcione de fato (Aula 19 §4).
  const renderItem = useCallback(
    ({ item }: ListRenderItemInfo<Produto>) => (
      <CardProduto produto={item} favoritado={favoritos.has(item.id)} onFavoritar={alternarFavorito} />
    ),
    [favoritos, alternarFavorito]
  );

  return (
    <View style={estilos.container}>
      <FlatList
        data={produtos}
        keyExtractor={(item) => item.id} // FlatList usa keyExtractor, não a prop `key`
        renderItem={renderItem}
        initialNumToRender={20}
        windowSize={5}
        removeClippedSubviews
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
