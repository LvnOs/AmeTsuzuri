import 'package:flutter/material.dart';

import '../../letters/model/letter.dart';
import '../../letters/presentation/letter_page.dart';

class BookshelfPage extends StatelessWidget {
  BookshelfPage({super.key});

  final List<Letter> letters = [
    Letter(
      id: '2026-08-07',
      title: '朝顔',
      date: DateTime(2026, 8, 7),
      body: '朝顔の手紙本文です。',
    ),
    Letter(
      id: '2026-08-08',
      title: '風鈴',
      date: DateTime(2026, 8, 8),
      body: '風鈴の手紙本文です。',
    ),
    Letter(
      id: '2026-08-09',
      title: 'カエル',
      date: DateTime(2026, 8, 9),
      body: 'カエルの手紙本文です。',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('本棚')),
      body: ListView.builder(
        itemCount: letters.length,
        itemBuilder: (context, index) {
          final letter = letters[index];

          return ListTile(
            title: Text(letter.title),
            subtitle: Text(_formatDate(letter.date)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => LetterPage(letter: letter),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}年${date.month}月${date.day}日';
  }
}
