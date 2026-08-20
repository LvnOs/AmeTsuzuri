import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../letters/presentation/letter_page.dart';
import '../../letters/repository/letter_repository.dart';
import '../../letters/provider/read_letter_provider.dart';
import '../../letters/provider/shizuku_provider.dart';

class BookshelfPage extends StatelessWidget {
  const BookshelfPage({super.key, this.letterRepository});

  final LetterRepository? letterRepository;

  @override
  Widget build(BuildContext context) {
    final readLetterProvider = context.watch<ReadLetterProvider>();
    final readLetterIds = readLetterProvider.readLetterIds;
    final fullBottleCount = context.watch<ShizukuProvider>().fullBottleCount;
    final repository = letterRepository ?? LetterRepository();

    return Scaffold(
      appBar: AppBar(title: const Text('本棚')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            child: Row(
              children: [
                const Icon(Icons.local_drink_outlined, size: 18),
                const SizedBox(width: 6),
                Text('満ちた瓶 $fullBottleCount本'),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder(
              future: repository.getAll(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('手紙の読み込みに失敗しました\n${snapshot.error}'),
                  );
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
                      subtitle: Text(
                        _formatReceivedDate(
                          readLetterProvider.receivedDateFor(letter.id),
                        ),
                      ),
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
          ),
        ],
      ),
    );
  }

  String _formatReceivedDate(DateTime? date) {
    if (date == null) {
      return '受取日不明';
    }
    return '${date.year}年${date.month}月${date.day}日';
  }
}
