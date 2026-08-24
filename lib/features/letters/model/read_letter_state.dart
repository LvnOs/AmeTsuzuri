class ReadLetterState {
  ReadLetterState({
    required Map<String, DateTime?> receivedLetters,
    Map<String, String> deliveredLetters = const {},
    this.hasOpenedTutorialBottle = false,
    this.tutorialCompleted = false,
  }) : receivedLetters = Map.unmodifiable(receivedLetters),
       deliveredLetters = Map.unmodifiable(deliveredLetters);

  final Map<String, DateTime?> receivedLetters;
  final Map<String, String> deliveredLetters;
  final bool hasOpenedTutorialBottle;
  final bool tutorialCompleted;

  Set<String> get readLetterIds => Set.unmodifiable(receivedLetters.keys);
}
