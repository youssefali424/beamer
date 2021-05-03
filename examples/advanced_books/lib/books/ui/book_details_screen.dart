import 'package:flutter/material.dart';
import 'package:beamer/beamer.dart';

import '../data.dart';

class BookDetailsScreen extends StatelessWidget {
  BookDetailsScreen({
    this.bookId,
  }) : book = books.firstWhere((book) => book['id'] == bookId);

  final String bookId;
  final Map<String, String> book;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(book['title']),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              onPressed: () => context.currentBeamLocation.update(
                (state) => state.copyWith(
                  pathBlueprintSegments: ['books', ':bookId', 'genres'],
                  pathParameters: {'bookId': bookId},
                ),
              ),
              child: Text('See genres'),
            ),
            ElevatedButton(
              onPressed: () => context.currentBeamLocation.update(
                (state) => state.copyWith(
                  pathBlueprintSegments: ['books', ':bookId', 'buy'],
                  pathParameters: {'bookId': bookId},
                ),
              ),
              child: Text('Buy'),
            ),
          ],
        ),
      ),
    );
  }
}
