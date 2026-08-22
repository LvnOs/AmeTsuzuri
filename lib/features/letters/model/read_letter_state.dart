class ReadLetterState {
  ReadLetterState({
    required Map<String, DateTime?> receivedLetters,
    Map<String, String> deliveredLetters = const {},
  }) : receivedLetters = Map.unmodifiable(receivedLetters),
       deliveredLetters = Map.unmodifiable(deliveredLetters);

  final Map<String, DateTime?> receivedLetters;
  final Map<String, String> deliveredLetters;

  Set<String> get readLetterIds => Set.unmodifiable(receivedLetters.keys);
}
