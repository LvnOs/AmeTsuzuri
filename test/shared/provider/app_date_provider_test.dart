import 'package:ame_tsuzuri/shared/provider/app_data_provider.dart';
import 'package:ame_tsuzuri/shared/repository/app_date_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('保存済みのプロトタイプ日付をロードする', () async {
    SharedPreferences.setMockInitialValues({
      'prototypeDate': '2026-08-09T00:00:00.000',
    });
    final provider = AppDateProvider(AppDateRepository());

    expect(provider.isLoaded, isFalse);
    await provider.load();

    expect(provider.isLoaded, isTrue);
    expect(provider.today, DateTime(2026, 8, 9));
    expect(provider.isDebugDateEnabled, isTrue);
  });

  test('翌日へ進めた日付を新しいProviderで復元できる', () async {
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
  });

  test('デバッグ日付をクリアすると次回ロードで実日付へ戻る', () async {
    final provider = AppDateProvider(AppDateRepository());
    await provider.load();
    await provider.setDebugDate(DateTime(2026, 8, 7));
    await provider.clearDebugDate();

    final reloadedProvider = AppDateProvider(AppDateRepository());
    await reloadedProvider.load();

    expect(reloadedProvider.isDebugDateEnabled, isFalse);
  });
}
