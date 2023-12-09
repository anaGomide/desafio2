import 'package:desafio2/providers/book_provider.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vocsy_epub_viewer/epub_viewer.dart';

class BookListScreen extends StatefulWidget {
  static const routeName = '/book-list';

  const BookListScreen({Key? key}) : super(key: key);

  @override
  _BookListScreenState createState() => _BookListScreenState();
}

class _BookListScreenState extends State<BookListScreen> {
  late SharedPreferences _prefs;
  Set<int> _favoriteBooks = Set<int>();

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    _favoriteBooks = (_prefs.getStringList('favoriteBooks') ?? [])
        .map((id) => int.parse(id))
        .toSet();
  }

  Future<void> _savePreferences() async {
    await _prefs.setStringList(
        'favoriteBooks', _favoriteBooks.map((id) => id.toString()).toList());
  }

  void _openOrDownloadBook(BuildContext context, BookProvider book) async {
    try {
      if (await book.isDownloaded()) {
        await _openDownloadedBook(context, book);
      } else {
        await _downloadAndOpenBook(context, book);
      }
    } catch (e) {
      _handleError(e);
    }
  }

  Future<void> _openDownloadedBook(
      BuildContext context, BookProvider book) async {
    String filePath = await book.getBookFilePath();

    // ignore: use_build_context_synchronously
    showDialog(
      context: context,
      builder: (context) => _buildAlertDialog(
        title: 'Ler o Livro',
        content: 'Você quer ler ${book.title}?',
        onConfirm: () async {
          Navigator.pop(context);

          await _openBook(context, book, filePath);

          setState(() {});
        },
      ),
    );
  }

  Future<void> _downloadAndOpenBook(
      BuildContext context, BookProvider book) async {
    showDialog(
      context: context,
      builder: (context) => _buildAlertDialog(
        title: 'Download de Livro',
        content: 'Você quer fazer o download ${book.title}?',
        onConfirm: () async {
          Navigator.pop(context);

          String filePath = await book.downloadBook(
              book.download_url, "${book.id}_${book.title}.epub");

          await _openDownloadedBook(context, book);
        },
      ),
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

  void _handleError(dynamic error) {
    print('Error handling book: $error');
    showDialog(
      context: context,
      builder: (context) => _buildAlertDialog(
        title: 'Erro',
        content: 'Ocorreu um erro ao abrir o livro',
        onConfirm: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildAlertDialog({
    required String title,
    required String content,
    required VoidCallback onConfirm,
  }) {
    return AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: onConfirm,
          child: const Text('Confirmar'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Estante Virtual'),
        backgroundColor: Colors.deepOrange,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.pushNamed(context, '/favorite-books',
                  arguments: _favoriteBooks.toList());
            },
            icon: const Icon(Icons.favorite),
          ),
        ],
      ),
      body: FutureBuilder<List<BookProvider>>(
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
              child: Text('No available books'),
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
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              _buildFavoriteIcon(book),
                            ],
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
                                          alignment:
                                              AlignmentDirectional.center)
                                      : ColorFiltered(
                                          colorFilter: ColorFilter.mode(
                                              Colors.white,
                                              BlendMode.saturation),
                                          child: Image.network(book.cover_url,
                                              height: 100.0,
                                              alignment:
                                                  AlignmentDirectional.center),
                                        );
                                }
                              },
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            book.title,
                            textAlign: TextAlign.left,
                          ),
                          Text(book.author, textAlign: TextAlign.left),
                        ],
                      ),
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

  Widget _buildFavoriteIcon(BookProvider book) {
    final isFavorite = _favoriteBooks.contains(book.id);

    return IconButton(
      icon: Icon(
        isFavorite ? Icons.favorite : Icons.favorite_border,
        color: isFavorite ? Colors.red : null,
      ),
      onPressed: () {
        setState(() {
          if (isFavorite) {
            _favoriteBooks.remove(book.id);
          } else {
            _favoriteBooks.add(book.id);
          }
          _savePreferences();
        });
      },
    );
  }
}
