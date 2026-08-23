import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../letters/presentation/letter_page.dart';
import '../../letters/repository/letter_repository.dart';
import '../../letters/provider/read_letter_provider.dart';
import '../../letters/provider/shizuku_provider.dart';

class BookshelfPage extends StatelessWidget {
  const BookshelfPage({super.key, this.letterRepository});

  static const Color _pageBackgroundColor = Color(0xFFE5DDD0);
  static const Color _paperColor = Color(0xFFFFFAEC);
  static const Color _inkColor = Color(0xFF3F382F);
  static const Color _secondaryInkColor = Color(0xFF71685D);
  static const Color _ruleColor = Color(0x268A8175);

  final LetterRepository? letterRepository;

  @override
  Widget build(BuildContext context) {
    final readLetterProvider = context.watch<ReadLetterProvider>();
    final readLetterIds = readLetterProvider.readLetterIds;
    final fullBottleCount = context.watch<ShizukuProvider>().fullBottleCount;
    final repository = letterRepository ?? LetterRepository();

    return Scaffold(
      backgroundColor: _pageBackgroundColor,
      appBar: AppBar(
        title: const Text('本棚'),
        backgroundColor: _pageBackgroundColor,
        foregroundColor: _inkColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Container(
                key: const ValueKey('bookshelfPaper'),
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(18, 24, 18, 20),
                decoration: BoxDecoration(
                  color: _paperColor,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x263D342B),
                      blurRadius: 24,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '届いた手紙',
                      key: ValueKey('bookshelfPaperTitle'),
                      style: TextStyle(
                        color: _inkColor,
                        fontSize: 23,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '満ちた瓶 $fullBottleCount本',
                      key: const ValueKey('bookshelfBottleRecord'),
                      style: const TextStyle(
                        color: _secondaryInkColor,
                        fontSize: 14,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Divider(height: 1, thickness: 0.8, color: _ruleColor),
                    Expanded(
                      child: FutureBuilder(
                        future: repository.getAll(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          if (snapshot.hasError) {
                            return Center(
                              child: Text(
                                '手紙の読み込みに失敗しました\n${snapshot.error}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: _inkColor),
                              ),
                            );
                          }

                          final allLetters = snapshot.data ?? [];
                          final readLetters = allLetters
                              .where(
                                (letter) => readLetterIds.contains(letter.id),
                              )
                              .toList();

                          if (readLetters.isEmpty) {
                            return const Center(
                              child: Text(
                                'まだ読んだ手紙はありません',
                                style: TextStyle(color: _secondaryInkColor),
                              ),
                            );
                          }

                          return ListView.separated(
                            key: const ValueKey('bookshelfLetterList'),
                            padding: EdgeInsets.zero,
                            itemCount: readLetters.length,
                            separatorBuilder: (context, index) => const Divider(
                              height: 1,
                              thickness: 0.8,
                              color: _ruleColor,
                            ),
                            itemBuilder: (context, index) {
                              final letter = readLetters[index];

                              return _BookshelfLetterRow(
                                letterId: letter.id,
                                title: letter.title,
                                receivedDate: _formatReceivedDate(
                                  readLetterProvider.receivedDateFor(letter.id),
                                ),
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (context) =>
                                          LetterPage(letter: letter),
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
              ),
            ),
          ),
        ),
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

class _BookshelfLetterRow extends StatelessWidget {
  const _BookshelfLetterRow({
    required this.letterId,
    required this.title,
    required this.receivedDate,
    required this.onTap,
  });

  final String letterId;
  final String title;
  final String receivedDate;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: ValueKey('bookshelfLetterRow-$letterId'),
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 72),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                receivedDate,
                style: const TextStyle(
                  color: BookshelfPage._secondaryInkColor,
                  fontSize: 12.5,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: BookshelfPage._inkColor,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
