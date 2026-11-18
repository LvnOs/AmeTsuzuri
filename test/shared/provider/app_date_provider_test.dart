import 'package:ame_tsuzuri/shared/model/season_type.dart';
import 'package:ame_tsuzuri/shared/provider/app_data_provider.dart';
import 'package:ame_tsuzuri/shared/repository/app_date_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final localDate = DateTime(2026, 11, 17);
  const modeKey = 'prototypeDateModeEnabled';

  AppDateProvider createProvider() =>
      AppDateProvider(AppDateRepository(), now: () => localDate);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('新規ユーザーは端末の実日付を使い日付送りを無視する', () async {
    final provider = createProvider();
    await provider.load();
    await provider.moveToNextDay();

    expect(provider.isLoaded, isTrue);
    expect(provider.today, localDate);
    expect(provider.isDebugDateEnabled, isFalse);
    expect(provider.needsMigrationNotice, isFalse);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.containsKey('prototypeDate'), isFalse);
  });

  test('旧日付を保持して通常プレイで起動し、案内の確認を保存する', () async {
    const savedDate = '2026-08-09T00:00:00.000';
    SharedPreferences.setMockInitialValues({'prototypeDate': savedDate});
    final provider = createProvider();
    await provider.load();
    expect(provider.today, localDate);
    expect(provider.needsMigrationNotice, isTrue);

    await provider.setPrototypeMode(false);
    final reloadedProvider = createProvider();
    await reloadedProvider.load();
    expect(reloadedProvider.needsMigrationNotice, isFalse);
    expect(reloadedProvider.today, localDate);
    await reloadedProvider.setPrototypeMode(true);
    expect(reloadedProvider.today, DateTime(2026, 8, 9));

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('prototypeDate'), savedDate);
  });

  test('Prototypeの日付送りと再起動後のモード・日付を復元する', () async {
    final provider = createProvider();
    await provider.load();
    await provider.setPrototypeMode(true);
    expect(provider.today, DateTime(2026, 8, 7));
    expect(provider.currentSeason, SeasonType.summer);
    await provider.moveToNextDay();

    final reloadedProvider = createProvider();
    await reloadedProvider.load();
    expect(reloadedProvider.isDebugDateEnabled, isTrue);
    expect(reloadedProvider.today, DateTime(2026, 8, 8));
    await reloadedProvider.setPrototypeMode(false);

    final normalProvider = createProvider();
    await normalProvider.load();
    expect(normalProvider.today, localDate);
    await normalProvider.setPrototypeMode(true);
    expect(normalProvider.today, DateTime(2026, 8, 8));
  });

  test('現地日付の変更と同日でのモード切替を通知する', () async {
    var now = DateTime(2026, 11, 17, 23, 59);
    final provider = AppDateProvider(AppDateRepository(), now: () => now);
    final notifications = <DateTime>[];
    provider.addListener(() => notifications.add(provider.today));
    await provider.load();
    provider.refreshLocalDate();
    now = DateTime(2026, 11, 18);
    provider.refreshLocalDate();
    await provider.setDebugDate(now);
    now = DateTime(2026, 11, 19);
    provider.refreshLocalDate();
    await provider.setPrototypeMode(false);

    expect(notifications, [
      localDate,
      DateTime(2026, 11, 18),
      DateTime(2026, 11, 18),
      DateTime(2026, 11, 19),
    ]);
  });

  test('明示的なPrototype初期化で開始日は保存される', () async {
    final provider = createProvider();
    await provider.load();
    await provider.setDebugDate(DateTime(2026, 8, 20, 12));
    await provider.startPrototypePeriod();
    final prefs = await SharedPreferences.getInstance();

    expect(provider.today, DateTime(2026, 8, 7));
    expect(prefs.getBool(modeKey), isTrue);
    expect(prefs.getString('prototypeDate'), '2026-08-07T00:00:00.000');
  });

  test('不正な旧日付でも起動でき、Prototypeでは開始日に戻る', () async {
    SharedPreferences.setMockInitialValues({'prototypeDate': 'invalid'});
    final provider = createProvider();
    await provider.load();
    expect(provider.today, localDate);

    await provider.setPrototypeMode(true);
    expect(provider.today, DateTime(2026, 8, 7));
  });

  test('日付モードの保存が失敗したときは状態を更新しない', () async {
    final provider = AppDateProvider(
      _FailingModeRepository(),
      now: () => localDate,
    );
    await provider.load();
    var notificationCount = 0;
    provider.addListener(() => notificationCount++);

    await expectLater(provider.setPrototypeMode(true), throwsStateError);

    expect(provider.isDebugDateEnabled, isFalse);
    expect(provider.today, localDate);
    expect(notificationCount, 0);
  });
}

class _FailingModeRepository extends AppDateRepository {
  @override
  Future<void> savePrototypeMode(bool enabled) async {
    throw StateError('save failed');
  }
}
