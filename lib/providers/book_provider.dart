// ignore_for_file: non_constant_identifier_names

import 'dart:convert';
import 'dart:io' show File;

import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:vocsy_epub_viewer/epub_viewer.dart';

// import 'package:vocsy_epub_viewer/model/enum/epub_scroll_direction.dart';
// import 'package:vocsy_epub_viewer/model/epub_locator.dart';
// import 'package:vocsy_epub_viewer/utils/util.dart';

class BookProvider {
  int id;
  String title;
  String author;
  String cover_url;
  String download_url;

  BookProvider({
    required this.id,
    required this.title,
    required this.author,
    required this.cover_url,
    required this.download_url,
  });

  factory BookProvider.fromJson(Map<String, dynamic> json) {
    return BookProvider(
      id: json['id'],
      title: json['title'],
      author: json['author'],
      cover_url: json['cover_url'],
      download_url: json['download_url'],
    );
  }

  static Future<List<BookProvider>> getBooks() async {
    final response =
        await http.get(Uri.parse('https://escribo.com/books.json'));

    if (response.statusCode == 200) {
      List jsonResponse = json.decode(response.body);
      return jsonResponse.map((item) => BookProvider.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load books');
    }
  }

  Future<String> downloadBook(String url, String filename) async {
    Dio dio = Dio();
    try {
      // Obtém o diretório de documentos do aplicativo
      var dir = await getApplicationDocumentsDirectory();

      // Caminho completo para o arquivo a ser baixado
      String filePath = "${dir.path}/$filename";

      // Verifica se o arquivo já existe para evitar baixar novamente
      if (!File(filePath).existsSync()) {
        // Baixa o livro usando a URL fornecida
        await dio.download(url, filePath);
      }

      // Retorna o caminho completo do arquivo baixado
      return filePath;
    } catch (e) {
      // Lida com erros durante o download
      print('Error downloading book: $e');
      throw e;
    }
  }

  // Função para abrir o livro usando a biblioteca vocsy_epub_viewer
  Future<void> openBook(String filePath) async {
    VocsyEpub.setConfig(
      identifier: "iosBook",
      scrollDirection: EpubScrollDirection.ALLDIRECTIONS,
      allowSharing: true,
      enableTts: true,
      nightMode: true,
    );

    // get current locator
    VocsyEpub.locatorStream.listen((locator) {
      print('LOCATOR: $locator');
    });

    VocsyEpub.open(
      filePath,
      // Você pode adicionar a última localização do livro aqui se desejar
    );
  }

  Future<bool> isDownloaded() async {
    try {
      // Obtém o diretório de documentos do aplicativo
      var dir = await getApplicationDocumentsDirectory();

      // Caminho completo para o arquivo do livro
      String filePath = "${dir.path}/${id}_$title.epub";

      // Verifica se o arquivo já existe
      return File(filePath).existsSync();
    } catch (e) {
      // Lida com erros durante a verificação
      print('Error checking if book is downloaded: $e');
      return false;
    }
  }

  Future<String> getBookFilePath() async {
    try {
      // Obtém o diretório de documentos do aplicativo
      var dir = await getApplicationDocumentsDirectory();

      // Caminho completo para o arquivo do livro
      String filePath = "${dir.path}/${id}_$title.epub";

      // Verifica se o arquivo já existe
      if (File(filePath).existsSync()) {
        return filePath;
      } else {
        throw Exception("Book file not found");
      }
    } catch (e) {
      // Lida com erros ao obter o caminho do arquivo
      print('Error getting book file path: $e');
      throw e;
    }
  }
}
