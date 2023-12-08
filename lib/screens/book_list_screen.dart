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
          title: const Text('Open Book'),
          content: Text('Do you want to open ${book.title}?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);

                // Abre diretamente a página específica do plugin após o download
                await _openBook(context, book, filePath);

                setState(() {});
              },
              child: const Text('Open'),
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
          title: const Text('Download Book'),
          content: Text('Do you want to download ${book.title}?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);

                // Chama o método para fazer o download do livro
                String filePath = await book.downloadBook(
                    book.download_url, "${book.id}_${book.title}.epub");

                // Abre diretamente a página específica do plugin após o download
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
        title: const Text('Book Store'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.pushNamed(context, '/favorite-books');
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
              child: Text('No books available'),
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
                        Image.network(book.cover_url, height: 100.0),
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
