import 'package:ame_tsuzuri/features/letters/provider/read_letter_provider.dart';
import 'package:ame_tsuzuri/features/letters/repository/read_letter_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('未読手紙を保存して通知しtrueを返す', () async {
    final repository = _FakeReadLetterRepository();
    final provider = await _loadProvider(repository);
    var notificationCount = 0;
    provider.addListener(() => notificationCount++);

    final result = await provider.markAsRead('letterA');

    expect(result, isTrue);
    expect(provider.readLetterIds, {'letterA'});
    expect(repository.persistedIds, {'letterA'});
    expect(repository.saveCallCount, 1);
    expect(notificationCount, 1);
  });

  test('既読手紙は保存も通知もせずfalseを返す', () async {
    final repository = _FakeReadLetterRepository({'letterA'});
    final provider = await _loadProvider(repository);
    var notificationCount = 0;
    provider.addListener(() => notificationCount++);

    final result = await provider.markAsRead('letterA');

    expect(result, isFalse);
    expect(provider.readLetterIds, {'letterA'});
    expect(repository.saveCallCount, 0);
    expect(notificationCount, 0);
  });

  test('保存失敗時は追加IDを取り除き通知せず例外を伝える', () async {
    final repository = _FakeReadLetterRepository()..failSave = true;
    final provider = await _loadProvider(repository);
    var notificationCount = 0;
    provider.addListener(() => notificationCount++);

    await expectLater(
      provider.markAsRead('letterA'),
      throwsA(isA<StateError>()),
    );

    expect(provider.readLetterIds, isEmpty);
    expect(repository.persistedIds, isEmpty);
    expect(notificationCount, 0);
  });

  test('保存失敗時も既存の既読IDを維持する', () async {
    final repository = _FakeReadLetterRepository({'letterA'})..failSave = true;
    final provider = await _loadProvider(repository);

    await expectLater(
      provider.markAsRead('letterB'),
      throwsA(isA<StateError>()),
    );

    expect(provider.readLetterIds, {'letterA'});
    expect(repository.persistedIds, {'letterA'});
  });
}

Future<ReadLetterProvider> _loadProvider(
  ReadLetterRepository repository,
) async {
  final provider = ReadLetterProvider(repository);
  await provider.load();
  return provider;
}

class _FakeReadLetterRepository extends ReadLetterRepository {
  _FakeReadLetterRepository([Set<String>? initialIds])
    : persistedIds = Set.of(initialIds ?? {});

  Set<String> persistedIds;
  bool failSave = false;
  int saveCallCount = 0;

  @override
  Future<Set<String>> loadReadLetterIds() async => Set.of(persistedIds);

  @override
  Future<void> saveReadLetterIds(Set<String> ids) async {
    saveCallCount++;
    if (failSave) {
      throw StateError('save failed');
    }
    persistedIds = Set.of(ids);
  }
}
