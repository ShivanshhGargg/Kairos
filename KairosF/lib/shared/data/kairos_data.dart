import '../../core/models/kairos_models.dart';

class KairosData {
  const KairosData({
    required this.dashboard,
    required this.memories,
    required this.workflows,
    required this.notifications,
    required this.needsReview,
    required this.profile,
    required this.rawNotes,
  });

  final DashboardData dashboard;
  final List<Memory> memories;
  final List<Workflow> workflows;
  final List<KairosNotification> notifications;
  final List<NeedsReviewItem> needsReview;
  final UserProfile profile;
  final List<String> rawNotes;

  factory KairosData.empty() {
    return const KairosData(
      dashboard: DashboardData(
        nextMove: null,
        everythingElse: [],
        risks: [],
        insights: [],
      ),
      memories: [],
      workflows: [],
      notifications: [],
      needsReview: [],
      profile: UserProfile(
        fullName: 'You',
        email: '',
        occupation: '',
        kairosInboxAddress: '',
        dailyBriefingTime: '08:00',
        timezone: 'Asia/Kolkata',
        currency: 'INR',
        notificationIntensity: 0.5,
        pushEnabled: true,
        emailEnabled: false,
      ),
      rawNotes: [],
    );
  }

  Memory? memoryById(String id) {
    for (final memory in memories) {
      if (memory.id == id) return memory;
    }
    return null;
  }

  Workflow? workflowById(String id) {
    for (final workflow in workflows) {
      if (workflow.id == id) return workflow;
    }
    return null;
  }

  KairosData copyWith({
    DashboardData? dashboard,
    List<Memory>? memories,
    List<Workflow>? workflows,
    List<KairosNotification>? notifications,
    List<NeedsReviewItem>? needsReview,
    UserProfile? profile,
    List<String>? rawNotes,
  }) {
    return KairosData(
      dashboard: dashboard ?? this.dashboard,
      memories: memories ?? this.memories,
      workflows: workflows ?? this.workflows,
      notifications: notifications ?? this.notifications,
      needsReview: needsReview ?? this.needsReview,
      profile: profile ?? this.profile,
      rawNotes: rawNotes ?? this.rawNotes,
    );
  }
}
