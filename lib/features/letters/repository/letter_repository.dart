import '../model/letter.dart';

class LetterRepository {
  List<Letter> getAll() {
    return [
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
  }
}
