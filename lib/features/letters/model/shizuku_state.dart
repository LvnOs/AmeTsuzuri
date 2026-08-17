class ShizukuState {
  const ShizukuState({
    required this.currentShizuku,
    required this.rewardedLetterIds,
  });

  final int currentShizuku;
  final Set<String> rewardedLetterIds;
}
