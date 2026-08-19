class ReadLetterState {
  ReadLetterState({required Map<String, DateTime?> receivedLetters})
    : receivedLetters = Map.unmodifiable(receivedLetters);

  final Map<String, DateTime?> receivedLetters;

  Set<String> get readLetterIds => Set.unmodifiable(receivedLetters.keys);
}
