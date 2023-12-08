import 'package:desafio2/screens/book_list_screen.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Book Store',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const BookListScreen(),
      routes: {
        BookListScreen.routeName: (context) => const BookListScreen(),
      },
    );
  }
}
