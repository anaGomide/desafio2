import 'package:desafio2/providers/book_provider.dart';
import 'package:flutter/material.dart';

class FavoriteBooksScreen extends StatelessWidget {
  static const routeName = '/favorite-books';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorite Books'),
      ),
      body: FutureBuilder<List<BookProvider>>(
        // Aqui você pode obter a lista completa de livros e filtrar os favoritos
        future: BookProvider.getBooks(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('No favorite books available'),
            );
          } else {
            // Filtra apenas os livros favoritos
            final favoriteBooks = snapshot.data!
                .where((book) => _favoriteBooks.contains(book.id))
                .toList();

            if (favoriteBooks.isEmpty) {
              return const Center(
                child: Text('No favorite books available'),
              );
            }

            return ListView.builder(
              itemCount: favoriteBooks.length,
              itemBuilder: (context, index) {
                var book = favoriteBooks[index];
                return Card(
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.topRight,
                        children: [
                          Image.network(book.cover_url, height: 100.0),
                          IconButton(
                            icon: Icon(
                              _isBookFavorite(book.id)
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color:
                                  _isBookFavorite(book.id) ? Colors.red : null,
                            ),
                            onPressed: () {
                              // Não implemente nada aqui para a tela de favoritos
                            },
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(book.title),
                            Text(book.author),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
