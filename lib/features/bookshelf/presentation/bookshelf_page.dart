import 'package:flutter/material.dart';

// import '../../letters/model/letter.dart';
import '../../letters/presentation/letter_page.dart';
import '../../letters/repository/letter_repository.dart';

class BookshelfPage extends StatelessWidget {
  BookshelfPage({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = LetterRepository();
    return Scaffold(
      appBar: AppBar(title: const Text('本棚')),
      body: FutureBuilder(
        future: repository.getAll(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final letters = snapshot.data!;
          return ListView.builder(
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
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}年${date.month}月${date.day}日';
  }
}
