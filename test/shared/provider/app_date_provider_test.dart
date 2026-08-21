import 'package:ame_tsuzuri/shared/model/season_type.dart';
import 'package:ame_tsuzuri/shared/provider/app_data_provider.dart';
import 'package:ame_tsuzuri/shared/repository/app_date_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('保存日付がなければ初回loadでプロトタイプ開始日を保存・反映する', () async {
    final provider = AppDateProvider(AppDateRepository());
    expect(provider.isLoaded, isFalse);

    await provider.load();

    expect(provider.isLoaded, isTrue);
    expect(provider.today, DateTime(2026, 8, 7));
    expect(provider.isDebugDateEnabled, isTrue);
    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getString('prototypeDate'),
      DateTime(2026, 8, 7).toIso8601String(),
    );
  });

  test('保存済みのプロトタイプ日付をロードする', () async {
    SharedPreferences.setMockInitialValues({
      'prototypeDate': '2026-08-09T00:00:00.000',
    });
    final provider = AppDateProvider(AppDateRepository());

    await provider.load();

    expect(provider.isLoaded, isTrue);
    expect(provider.today, DateTime(2026, 8, 9));
    expect(provider.isDebugDateEnabled, isTrue);
  });

  test('保存済み日付を優先し保存し直さない', () async {
    final repository = _TrackingAppDateRepository(
      loadedDate: DateTime(2026, 8, 10),
    );
    final provider = AppDateProvider(repository);

    await provider.load();

    expect(provider.today, DateTime(2026, 8, 10));
    expect(repository.savedDates, isEmpty);
  });

  test('初回8月7日から翌日へ進めて保存・復元できる', () async {
    final firstProvider = AppDateProvider(AppDateRepository());
    await firstProvider.load();

    await firstProvider.moveToNextDay();
    expect(firstProvider.today, DateTime(2026, 8, 8));

    final reloadedProvider = AppDateProvider(AppDateRepository());
    await reloadedProvider.load();
    expect(reloadedProvider.today, DateTime(2026, 8, 8));
  });

  test('保存済みの翌日を新しいProviderで復元できる', () async {
    final firstProvider = AppDateProvider(AppDateRepository());
    await firstProvider.load();
    await firstProvider.setDebugDate(DateTime(2026, 8, 7));
    await firstProvider.moveToNextDay();

    final reloadedProvider = AppDateProvider(AppDateRepository());
    await reloadedProvider.load();

    expect(reloadedProvider.today, DateTime(2026, 8, 8));
  });

  test('プロトタイプ開始日を保存して復元できる', () async {
    final provider = AppDateProvider(AppDateRepository());
    await provider.load();
    await provider.startPrototypePeriod();

    final reloadedProvider = AppDateProvider(AppDateRepository());
    await reloadedProvider.load();

    expect(reloadedProvider.today, DateTime(2026, 8, 7));
    expect(reloadedProvider.currentSeason, SeasonType.summer);
  });

  test('不正なprototypeDateはプロトタイプ開始日で修復する', () async {
    SharedPreferences.setMockInitialValues({'prototypeDate': 'invalid'});
    final provider = AppDateProvider(AppDateRepository());

    await provider.load();

    expect(provider.today, DateTime(2026, 8, 7));
    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getString('prototypeDate'),
      DateTime(2026, 8, 7).toIso8601String(),
    );
  });

  test('初回日付の保存失敗時はProvider状態を更新せず例外を伝播する', () async {
    final repository = _TrackingAppDateRepository(failSave: true);
    final provider = AppDateProvider(repository);
    var notificationCount = 0;
    provider.addListener(() => notificationCount++);

    await expectLater(provider.load(), throwsA(isA<StateError>()));

    expect(provider.isLoaded, isFalse);
    expect(provider.isDebugDateEnabled, isFalse);
    expect(repository.savedDates, [DateTime(2026, 8, 7)]);
    expect(notificationCount, 0);
  });

  test('デバッグ日付をクリアすると現在のProviderでは実日付へ戻る', () async {
    final provider = AppDateProvider(AppDateRepository());
    await provider.load();
    await provider.clearDebugDate();

    final now = DateTime.now();
    expect(
      provider.today.difference(now).abs(),
      lessThan(const Duration(seconds: 2)),
    );
    expect(provider.isDebugDateEnabled, isFalse);
  });

  test('clear後の新しいProviderはプロトタイプ開始日を再初期化する', () async {
    final provider = AppDateProvider(AppDateRepository());
    await provider.load();
    await provider.clearDebugDate();

    final reloadedProvider = AppDateProvider(AppDateRepository());
    await reloadedProvider.load();

    expect(reloadedProvider.today, DateTime(2026, 8, 7));
    expect(reloadedProvider.isDebugDateEnabled, isTrue);
  });
}

class _TrackingAppDateRepository extends AppDateRepository {
  _TrackingAppDateRepository({this.loadedDate, this.failSave = false});

  final DateTime? loadedDate;
  final bool failSave;
  final List<DateTime> savedDates = [];

  @override
  Future<DateTime?> load() async => loadedDate;

  @override
  Future<void> save(DateTime date) async {
    savedDates.add(date);
    if (failSave) {
      throw StateError('save failed');
    }
  }
}
