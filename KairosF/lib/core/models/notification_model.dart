class KairosNotification {
  const KairosNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.createdLabel,
    required this.deepLink,
    required this.read,
  });

  final String id;
  final String title;
  final String body;
  final String type;
  final String createdLabel;
  final String deepLink;
  final bool read;

  KairosNotification copyWith({bool? read}) {
    return KairosNotification(
      id: id,
      title: title,
      body: body,
      type: type,
      createdLabel: createdLabel,
      deepLink: deepLink,
      read: read ?? this.read,
    );
  }
}
