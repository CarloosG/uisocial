class Event {
  String id;
  String title;
  String type;
  DateTime date;
  String location;
  int participants;
  String creatorId;
  DateTime createdAt;

  Event({
    required this.id,
    required this.title,
    required this.type,
    required this.date,
    required this.location,
    required this.participants,
    required this.creatorId,
    required this.createdAt,
  });
}