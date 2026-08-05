import 'package:flutter/material.dart';

// import '../../letters/model/letter.dart';
import '../../letters/presentation/letter_page.dart';
import '../../letters/repository/letter_repository.dart';

class BookshelfPage extends StatelessWidget {
  BookshelfPage({super.key, required this.readLetterIds});

  final Set<String> readLetterIds;

  @override
  Widget build(BuildContext context) {
    final repository = LetterRepository();
    return Scaffold(
      appBar: AppBar(title: const Text('本棚')),
      body: FutureBuilder(
        future: repository.getAll(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('手紙の読み込みに失敗しました\n${snapshot.error}'));
          }

          final allLetters = snapshot.data ?? [];

          final readLetters = allLetters
              .where((letter) => readLetterIds.contains(letter.id))
              .toList();

          if (readLetters.isEmpty) {
            return const Center(child: Text('まだ読んだ手紙はありません'));
          }
          return ListView.builder(
            itemCount: readLetters.length,
            itemBuilder: (context, index) {
              final letter = readLetters[index];

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
