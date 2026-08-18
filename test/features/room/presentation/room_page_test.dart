import 'dart:async';

import 'package:ame_tsuzuri/features/furniture/provider/catalog_provider.dart';
import 'package:ame_tsuzuri/features/furniture/provider/placed_furniture_provider.dart';
import 'package:ame_tsuzuri/features/furniture/repository/placed_furniture_repository.dart';
import 'package:ame_tsuzuri/features/furniture/repository/purchased_furniture_repository.dart';
import 'package:ame_tsuzuri/features/letters/model/letter.dart';
import 'package:ame_tsuzuri/features/letters/model/shizuku_state.dart';
import 'package:ame_tsuzuri/features/letters/presentation/letter_page.dart';
import 'package:ame_tsuzuri/features/letters/provider/read_letter_provider.dart';
import 'package:ame_tsuzuri/features/letters/provider/shizuku_provider.dart';
import 'package:ame_tsuzuri/features/letters/repository/letter_repository.dart';
import 'package:ame_tsuzuri/features/letters/repository/read_letter_repository.dart';
import 'package:ame_tsuzuri/features/letters/repository/shizuku_repository.dart';
import 'package:ame_tsuzuri/features/room/presentation/room_page.dart';
import 'package:ame_tsuzuri/shared/provider/app_data_provider.dart';
import 'package:ame_tsuzuri/shared/model/weather_type.dart';
import 'package:ame_tsuzuri/shared/repository/app_date_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('初回30滴、2通目10滴、再読0滴で手紙を開ける', (tester) async {
    final harness = await _pumpRoom(tester);

    await _openDesk(tester);
    expect(harness.shizukuProvider.currentShizuku, 30);
    expect(harness.shizukuProvider.rewardedLetterIds, {'letterA'});
    expect(harness.readLetterProvider.readLetterIds, {'letterA'});
    expect(find.byType(LetterPage), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await harness.dateProvider.setDebugDate(DateTime(2026, 8, 8));
    await _openDesk(tester);
    expect(harness.shizukuProvider.currentShizuku, 40);
    expect(harness.shizukuProvider.rewardedLetterIds, {'letterA', 'letterB'});
    expect(harness.readLetterProvider.readLetterIds, {'letterA', 'letterB'});

    await tester.pageBack();
    await tester.pumpAndSettle();
    await harness.dateProvider.setDebugDate(DateTime(2026, 8, 7));
    await _openDesk(tester);
    expect(harness.shizukuProvider.currentShizuku, 40);
    expect(harness.shizukuRepository.saveCallCount, 2);
  });

  testWidgets('報酬保存失敗時は既読保存と画面遷移を行わず再試行できる', (tester) async {
    final harness = await _pumpRoom(tester);
    harness.shizukuRepository.failNextSave = true;

    await _openDesk(tester);

    expect(find.text('雫の受け取りに失敗しました'), findsOneWidget);
    expect(find.byType(LetterPage), findsNothing);
    expect(harness.readLetterRepository.saveCallCount, 0);
    expect(harness.shizukuProvider.currentShizuku, 0);

    await _openDesk(tester);
    expect(find.byType(LetterPage), findsOneWidget);
    expect(harness.shizukuProvider.currentShizuku, 30);
    expect(harness.readLetterProvider.readLetterIds, {'letterA'});
  });

  testWidgets('既読保存失敗後は追加報酬なしで既読保存を再試行する', (tester) async {
    final harness = await _pumpRoom(tester);
    harness.readLetterRepository.failNextSave = true;

    await _openDesk(tester);

    expect(find.text('手紙の保存に失敗しました'), findsOneWidget);
    expect(find.byType(LetterPage), findsNothing);
    expect(harness.shizukuProvider.currentShizuku, 30);
    expect(harness.readLetterProvider.readLetterIds, isEmpty);

    await _openDesk(tester);
    expect(find.byType(LetterPage), findsOneWidget);
    expect(harness.shizukuProvider.currentShizuku, 30);
    expect(harness.shizukuRepository.saveCallCount, 1);
    expect(harness.readLetterProvider.readLetterIds, {'letterA'});
  });

  testWidgets('ロード完了前は報酬処理と既読保存を開始しない', (tester) async {
    final harness = await _pumpRoom(tester, loadProviders: false);

    await _openDesk(tester);

    expect(find.text('読み込み中です'), findsOneWidget);
    expect(harness.shizukuRepository.saveCallCount, 0);
    expect(harness.readLetterRepository.saveCallCount, 0);
    expect(find.byType(LetterPage), findsNothing);
  });

  testWidgets('手紙処理中の連打で報酬保存と画面遷移を多重実行しない', (tester) async {
    final harness = await _pumpRoom(tester, blockRewardSave: true);

    await tester.tap(find.byKey(const ValueKey('deskTapArea')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('deskTapArea')));
    await tester.pump();

    expect(harness.shizukuRepository.saveCallCount, 1);
    harness.shizukuRepository.completeSave();
    await tester.pumpAndSettle();

    expect(harness.shizukuProvider.currentShizuku, 30);
    expect(find.byType(LetterPage), findsOneWidget);
  });
}

Future<void> _openDesk(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('deskTapArea')));
  await tester.pumpAndSettle();
}

Future<_RoomHarness> _pumpRoom(
  WidgetTester tester, {
  bool loadProviders = true,
  bool blockRewardSave = false,
}) async {
  final shizukuRepository = _FakeShizukuRepository(blockSave: blockRewardSave);
  final readLetterRepository = _FakeReadLetterRepository();
  final shizukuProvider = ShizukuProvider(shizukuRepository);
  final readLetterProvider = ReadLetterProvider(readLetterRepository);
  final catalogProvider = CatalogProvider(_FakePurchasedFurnitureRepository());
  final placedProvider = PlacedFurnitureProvider(
    _FakePlacedFurnitureRepository(),
  );
  final dateProvider = AppDateProvider(
    _FakeAppDateRepository(DateTime(2026, 8, 7)),
  );

  if (loadProviders) {
    await Future.wait([
      shizukuProvider.load(),
      readLetterProvider.load(),
      catalogProvider.load(),
      placedProvider.load(),
      dateProvider.load(),
    ]);
  }

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: shizukuProvider),
        ChangeNotifierProvider.value(value: readLetterProvider),
        ChangeNotifierProvider.value(value: catalogProvider),
        ChangeNotifierProvider.value(value: placedProvider),
        ChangeNotifierProvider.value(value: dateProvider),
      ],
      child: MaterialApp(
        home: RoomPage(letterRepository: _FakeLetterRepository()),
      ),
    ),
  );
  await tester.pump();

  return _RoomHarness(
    shizukuRepository: shizukuRepository,
    readLetterRepository: readLetterRepository,
    shizukuProvider: shizukuProvider,
    readLetterProvider: readLetterProvider,
    dateProvider: dateProvider,
  );
}

class _RoomHarness {
  const _RoomHarness({
    required this.shizukuRepository,
    required this.readLetterRepository,
    required this.shizukuProvider,
    required this.readLetterProvider,
    required this.dateProvider,
  });

  final _FakeShizukuRepository shizukuRepository;
  final _FakeReadLetterRepository readLetterRepository;
  final ShizukuProvider shizukuProvider;
  final ReadLetterProvider readLetterProvider;
  final AppDateProvider dateProvider;
}

class _FakeLetterRepository extends LetterRepository {
  @override
  Future<Letter?> getByDate(DateTime date) async {
    return switch (date.day) {
      7 => Letter(
        id: 'letterA',
        title: '手紙A',
        date: DateTime(2026, 8, 7),
        requiredWeather: WeatherType.rain,
        body: '本文A',
      ),
      8 => Letter(
        id: 'letterB',
        title: '手紙B',
        date: DateTime(2026, 8, 8),
        requiredWeather: WeatherType.rain,
        body: '本文B',
      ),
      _ => null,
    };
  }
}

class _FakeShizukuRepository extends ShizukuRepository {
  _FakeShizukuRepository({required this.blockSave});

  final bool blockSave;
  final Completer<void> _saveCompleter = Completer<void>();
  ShizukuState state = const ShizukuState(
    currentShizuku: 0,
    rewardedLetterIds: {},
  );
  bool failNextSave = false;
  int saveCallCount = 0;

  @override
  Future<ShizukuState> loadState() async => state;

  @override
  Future<void> saveState(ShizukuState nextState) async {
    saveCallCount++;
    if (failNextSave) {
      failNextSave = false;
      throw StateError('save failed');
    }
    if (blockSave) {
      await _saveCompleter.future;
    }
    state = nextState;
  }

  void completeSave() {
    if (!_saveCompleter.isCompleted) {
      _saveCompleter.complete();
    }
  }
}

class _FakeReadLetterRepository extends ReadLetterRepository {
  Set<String> persistedIds = {};
  bool failNextSave = false;
  int saveCallCount = 0;

  @override
  Future<Set<String>> loadReadLetterIds() async => Set.of(persistedIds);

  @override
  Future<void> saveReadLetterIds(Set<String> ids) async {
    saveCallCount++;
    if (failNextSave) {
      failNextSave = false;
      throw StateError('save failed');
    }
    persistedIds = Set.of(ids);
  }
}

class _FakePurchasedFurnitureRepository extends PurchasedFurnitureRepository {
  @override
  Future<Set<String>> loadPurchasedFurnitureIds() async => {};
}

class _FakePlacedFurnitureRepository extends PlacedFurnitureRepository {
  @override
  Future<Map<String, String>> loadPlacedFurnitureIds() async => {};
}

class _FakeAppDateRepository extends AppDateRepository {
  _FakeAppDateRepository(this.savedDate);

  DateTime? savedDate;

  @override
  Future<DateTime?> load() async => savedDate;

  @override
  Future<void> save(DateTime date) async {
    savedDate = date;
  }

  @override
  Future<void> clear() async {
    savedDate = null;
  }
}
