class Letter {
  const Letter({
    required this.id,
    required this.title,
    required this.date,
    required this.body,
  });

  final String id;
  final DateTime date;
  final String title;
  final String body;
}
