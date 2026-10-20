import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../letters/model/letter.dart';
import '../../letters/presentation/letter_page.dart';
import '../../letters/repository/letter_repository.dart';
import '../../letters/provider/read_letter_provider.dart';
import '../../letters/provider/shizuku_provider.dart';
import '../../../shared/model/season_type.dart';

class BookshelfPage extends StatefulWidget {
  const BookshelfPage({super.key, this.letterRepository});

  static const Color _pageBackgroundColor = Color(0xFFE5DDD0);
  static const Color _paperColor = Color(0xFFFFFAEC);
  static const Color _inkColor = Color(0xFF3F382F);
  static const Color _secondaryInkColor = Color(0xFF71685D);
  static const Color _ruleColor = Color(0x268A8175);

  final LetterRepository? letterRepository;

  @override
  State<BookshelfPage> createState() => _BookshelfPageState();
}

class _BookshelfPageState extends State<BookshelfPage> {
  late Future<List<Letter>> _lettersFuture;
  SeasonType? _selectedSeason;

  @override
  void initState() {
    super.initState();
    _lettersFuture = (widget.letterRepository ?? LetterRepository()).getAll();
  }

  @override
  void didUpdateWidget(covariant BookshelfPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.letterRepository != oldWidget.letterRepository) {
      _lettersFuture = (widget.letterRepository ?? LetterRepository()).getAll();
    }
  }

  @override
  Widget build(BuildContext context) {
    final readLetterProvider = context.watch<ReadLetterProvider>();
    final readLetterIds = readLetterProvider.readLetterIds;
    final fullBottleCount = context.watch<ShizukuProvider>().fullBottleCount;

    return Scaffold(
      backgroundColor: BookshelfPage._pageBackgroundColor,
      appBar: AppBar(
        title: const Text('本棚'),
        backgroundColor: BookshelfPage._pageBackgroundColor,
        foregroundColor: BookshelfPage._inkColor,
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
                  color: BookshelfPage._paperColor,
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
                        color: BookshelfPage._inkColor,
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
                        color: BookshelfPage._secondaryInkColor,
                        fontSize: 14,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Divider(
                      height: 1,
                      thickness: 0.8,
                      color: BookshelfPage._ruleColor,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 1),
                      child: _BookshelfSeasonFilter(
                        selectedSeason: _selectedSeason,
                        onChanged: (season) {
                          setState(() => _selectedSeason = season);
                        },
                      ),
                    ),
                    Expanded(
                      child: FutureBuilder(
                        future: _lettersFuture,
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
                                style: const TextStyle(
                                  color: BookshelfPage._inkColor,
                                ),
                              ),
                            );
                          }

                          final allLetters = snapshot.data ?? [];
                          final readLetters = allLetters
                              .where(
                                (letter) => readLetterIds.contains(letter.id),
                              )
                              .toList();

                          // Sort a display-only copy; delivery still uses YAML order.
                          // Explicit indexes keep equal/unknown dates deterministic.
                          final orderedLetters = readLetters.indexed.toList()
                            ..sort((a, b) {
                              final aDate = readLetterProvider.receivedDateFor(
                                a.$2.id,
                              );
                              final bDate = readLetterProvider.receivedDateFor(
                                b.$2.id,
                              );
                              if (aDate == null && bDate != null) return 1;
                              if (aDate != null && bDate == null) return -1;
                              final dateOrder = aDate == null || bDate == null
                                  ? 0
                                  : bDate.compareTo(aDate);
                              return dateOrder != 0
                                  ? dateOrder
                                  : a.$1.compareTo(b.$1);
                            });

                          final visibleLetters = _selectedSeason == null
                              ? orderedLetters
                              : orderedLetters
                                    .where(
                                      (entry) =>
                                          entry.$2.requiredSeason ==
                                          _selectedSeason,
                                    )
                                    .toList();

                          if (readLetters.isEmpty) {
                            return const Center(
                              child: Text(
                                'まだ読んだ手紙はありません',
                                style: TextStyle(
                                  color: BookshelfPage._secondaryInkColor,
                                ),
                              ),
                            );
                          }

                          if (visibleLetters.isEmpty) {
                            return const Center(
                              child: Text(
                                'この季節に届いた手紙はありません',
                                style: TextStyle(
                                  color: BookshelfPage._secondaryInkColor,
                                ),
                              ),
                            );
                          }

                          return ListView.separated(
                            key: const ValueKey('bookshelfLetterList'),
                            padding: EdgeInsets.zero,
                            itemCount: visibleLetters.length,
                            separatorBuilder: (context, index) => const Divider(
                              height: 1,
                              thickness: 0.8,
                              color: BookshelfPage._ruleColor,
                            ),
                            itemBuilder: (context, index) {
                              final letter = visibleLetters[index].$2;

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

class _BookshelfSeasonFilter extends StatelessWidget {
  const _BookshelfSeasonFilter({
    required this.selectedSeason,
    required this.onChanged,
  });

  final SeasonType? selectedSeason;
  final ValueChanged<SeasonType?> onChanged;

  static const _options = <(String, SeasonType?)>[
    ('すべて', null),
    ('春', SeasonType.spring),
    ('夏', SeasonType.summer),
    ('秋', SeasonType.autumn),
    ('冬', SeasonType.winter),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      key: const ValueKey('bookshelfSeasonFilters'),
      spacing: 4,
      runSpacing: 0,
      children: [
        for (final option in _options)
          _BookshelfSeasonFilterItem(
            key: ValueKey('bookshelfSeasonFilter-${option.$2?.name ?? 'all'}'),
            label: option.$1,
            isSelected: selectedSeason == option.$2,
            onTap: () => onChanged(option.$2),
          ),
      ],
    );
  }
}

class _BookshelfSeasonFilterItem extends StatelessWidget {
  const _BookshelfSeasonFilterItem({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(2),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: BookshelfPage._inkColor,
                    fontSize: 13.5,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 2),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  width: isSelected ? 18 : 0,
                  height: 1,
                  color: BookshelfPage._secondaryInkColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
