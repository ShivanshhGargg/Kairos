class UserProfile {
  const UserProfile({
    required this.fullName,
    required this.email,
    required this.occupation,
    required this.kairosInboxAddress,
    required this.dailyBriefingTime,
    required this.timezone,
    required this.currency,
    required this.notificationIntensity,
    required this.pushEnabled,
    required this.emailEnabled,
  });

  final String fullName;
  final String email;
  final String occupation;
  final String kairosInboxAddress;
  final String dailyBriefingTime;
  final String timezone;
  final String currency;
  final double notificationIntensity;
  final bool pushEnabled;
  final bool emailEnabled;

  UserProfile copyWith({
    String? dailyBriefingTime,
    String? timezone,
    String? currency,
    double? notificationIntensity,
    bool? pushEnabled,
    bool? emailEnabled,
  }) {
    return UserProfile(
      fullName: fullName,
      email: email,
      occupation: occupation,
      kairosInboxAddress: kairosInboxAddress,
      dailyBriefingTime: dailyBriefingTime ?? this.dailyBriefingTime,
      timezone: timezone ?? this.timezone,
      currency: currency ?? this.currency,
      notificationIntensity:
          notificationIntensity ?? this.notificationIntensity,
      pushEnabled: pushEnabled ?? this.pushEnabled,
      emailEnabled: emailEnabled ?? this.emailEnabled,
    );
  }
}
