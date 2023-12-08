// Criando a tela BookFavoriteScreen
import 'package:desafio2/providers/book_provider.dart';
import 'package:flutter/material.dart';
import 'package:vocsy_epub_viewer/epub_viewer.dart';

class BookFavoriteScreen extends StatefulWidget {
  static const routeName = '/favorite-books';
  final List<int> favoriteBooks;

  const BookFavoriteScreen({Key? key, required this.favoriteBooks})
      : super(key: key);

  @override
  _BookFavoriteScreenState createState() => _BookFavoriteScreenState();
}

class _BookFavoriteScreenState extends State<BookFavoriteScreen> {
  Future<List<BookProvider>> _loadFavoriteBooks() async {
    // Implemente a lógica para carregar apenas os livros favoritos
    List<BookProvider> favoriteBooks = [];
    final allBooks = await BookProvider.getBooks();

    for (var book in allBooks) {
      if (widget.favoriteBooks.contains(book.id)) {
        favoriteBooks.add(book);
      }
    }

    return favoriteBooks;
  }

  void _openOrDownloadBook(BuildContext context, BookProvider book) async {
    try {
      if (await book.isDownloaded()) {
        await _openDownloadedBook(context, book);
      } else {
        await _downloadAndOpenBook(context, book);
      }
    } catch (e) {
      print('Error handling book: $e');
      // Lida com o erro (exibição de mensagem, etc.)
    }
  }

  Future<void> _openDownloadedBook(
      BuildContext context, BookProvider book) async {
    String filePath = await book.getBookFilePath();

    // ignore: use_build_context_synchronously
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Ler Livro'),
          content: Text('Você que abrir ${book.title}?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _openBook(context, book, filePath);

                setState(() {});
              },
              child: const Text('Abrir'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _downloadAndOpenBook(
      BuildContext context, BookProvider book) async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Download do Livro'),
          content: Text('Você quer fazer o download de ${book.title}?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);

                String filePath = await book.downloadBook(
                    book.download_url, "${book.id}_${book.title}.epub");
                await _openDownloadedBook(context, book);
              },
              child: const Text('Download'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openBook(
      BuildContext context, BookProvider book, String filePath) async {
    VocsyEpub.setConfig(
      themeColor: Theme.of(context).primaryColor,
      identifier: "iosBook",
      scrollDirection: EpubScrollDirection.ALLDIRECTIONS,
      allowSharing: true,
      enableTts: true,
      nightMode: true,
    );

    VocsyEpub.locatorStream.listen((locator) {
      print('LOCATOR: $locator');
    });

    VocsyEpub.open(
      filePath,
      lastLocation: EpubLocator.fromJson({
        "bookId": book.id.toString(),
        "href": "/OEBPS/ch06.xhtml",
        "created": DateTime.now().millisecondsSinceEpoch,
        "locations": {
          "cfi": "epubcfi(/0!/4/4[simple_book]/2/2/6)",
        },
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Livros Favoritos'),
        backgroundColor: Colors.deepOrange,
      ),
      body: FutureBuilder<List<BookProvider>>(
        future: _loadFavoriteBooks(),
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
              child: Text('Não há livros favoritos'),
            );
          } else {
            return GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8.0,
                mainAxisSpacing: 8.0,
              ),
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                var book = snapshot.data![index];
                return GestureDetector(
                  onTap: () {
                    _openOrDownloadBook(context, book);
                  },
                  child: Card(
                    child: Column(
                      children: [
                        SizedBox(
                          height: 16,
                        ),
                        Flexible(
                          child: FutureBuilder<bool>(
                            future: book.isDownloaded(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return CircularProgressIndicator();
                              } else if (snapshot.hasError) {
                                return Text('Error: ${snapshot.error}');
                              } else {
                                bool isDownloaded = snapshot.data ?? false;
                                return isDownloaded
                                    ? Image.network(book.cover_url,
                                        height: 100.0,
                                        alignment: AlignmentDirectional.center)
                                    : ColorFiltered(
                                        colorFilter: ColorFilter.mode(
                                            Colors.white, BlendMode.saturation),
                                        child: Image.network(book.cover_url,
                                            height: 100.0,
                                            alignment:
                                                AlignmentDirectional.center),
                                      );
                              }
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                book.title,
                                textAlign: TextAlign.left,
                              ),
                              Text(book.author, textAlign: TextAlign.left),
                            ],
                          ),
                        ),
                      ],
                    ),
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
