import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/models/kairos_models.dart';
import 'kairos_data.dart';

export 'kairos_data.dart';

final kairosRepositoryProvider =
    StateNotifierProvider<KairosRepository, KairosData>((ref) {
  return KairosRepository(ref.watch(apiClientProvider));
});

class KairosRepository extends StateNotifier<KairosData> {
  KairosRepository(this._apiClient) : super(KairosData.empty()) {
    load();
  }

  final ApiClient _apiClient;

  Future<void> load() async {
    await _refreshFrom(
      () => _apiClient.get<Map<String, dynamic>>('/kairos/snapshot'),
    );
  }

  Future<void> submitText(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    await _mutateAndRefresh(
      () => _apiClient.post<Map<String, dynamic>>(
        '/inbox/text',
        data: {'text': trimmed},
      ),
    );
  }

  Future<String?> sendChatMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;
    return _chatMutation(
      () => _apiClient.post<Map<String, dynamic>>(
        '/chat/messages',
        data: {'text': trimmed},
      ),
    );
  }

  Future<String?> uploadChatAttachments(FormData data) {
    return _chatMutation(
      () => _apiClient.post<Map<String, dynamic>>(
        '/chat/attachments',
        data: data,
        options: Options(contentType: 'multipart/form-data'),
      ),
    );
  }

  Future<void> confirmReview(String id) async {
    await _mutateAndRefresh(
      () => _apiClient.post<Map<String, dynamic>>('/needs-review/$id/confirm'),
    );
  }

  Future<void> ignoreReview(String id) async {
    await _mutateAndRefresh(
      () => _apiClient.delete<Map<String, dynamic>>('/needs-review/$id'),
    );
  }

  Future<void> completeNextMove() async {
    await _mutateAndRefresh(
      () => _apiClient.post<Map<String, dynamic>>(
        '/dashboard/next-move/complete',
      ),
    );
  }

  Future<void> snoozeNextMove() async {
    await _mutateAndRefresh(
      () => _apiClient.post<Map<String, dynamic>>(
        '/dashboard/next-move/snooze',
      ),
    );
  }

  Future<void> markNotificationRead(String id) async {
    await _mutateAndRefresh(
      () => _apiClient.patch<Map<String, dynamic>>(
        '/notifications/$id',
        data: {'read': true},
      ),
    );
  }

  Future<void> markAllNotificationsRead() async {
    await _mutateAndRefresh(
      () => _apiClient.post<Map<String, dynamic>>(
        '/notifications/mark-all-read',
      ),
    );
  }

  Future<void> confirmMemory(String id) async {
    await _mutateAndRefresh(
      () => _apiClient.post<Map<String, dynamic>>('/memories/$id/confirm'),
    );
  }

  Future<void> snoozeWorkflow(String id) async {
    await _mutateAndRefresh(
      () => _apiClient.post<Map<String, dynamic>>('/workflows/$id/snooze'),
    );
  }

  Future<void> resolveWorkflow(String id) async {
    await _mutateAndRefresh(
      () => _apiClient.post<Map<String, dynamic>>('/workflows/$id/resolve'),
    );
  }

  Future<void> updateProfile({
    String? dailyBriefingTime,
    double? notificationIntensity,
    bool? pushEnabled,
    bool? emailEnabled,
  }) async {
    final nextProfile = state.profile.copyWith(
      dailyBriefingTime: dailyBriefingTime,
      notificationIntensity: notificationIntensity,
      pushEnabled: pushEnabled,
      emailEnabled: emailEnabled,
    );
    state = state.copyWith(profile: nextProfile);

    await _mutateAndRefresh(
      () => _apiClient.patch<Map<String, dynamic>>(
        '/profile',
        data: {
          if (dailyBriefingTime != null) 'dailyBriefingTime': dailyBriefingTime,
          if (notificationIntensity != null)
            'notificationIntensity': notificationIntensity,
          if (pushEnabled != null) 'pushEnabled': pushEnabled,
          if (emailEnabled != null) 'emailEnabled': emailEnabled,
        },
      ),
    );
  }

  Future<void> _mutateAndRefresh(
    Future<dynamic> Function() request,
  ) async {
    await _refreshFrom(request);
  }

  Future<String?> _chatMutation(Future<dynamic> Function() request) async {
    try {
      final response = await request();
      final data = _responseData(response);
      final parsed = _tryParseSnapshot(data);
      if (parsed != null) {
        state = parsed;
      } else {
        await _loadSnapshotOnly();
      }
      return _replyFromResponse(data);
    } catch (_) {
      return null;
    }
  }

  Future<void> _refreshFrom(Future<dynamic> Function() request) async {
    try {
      final response = await request();
      final parsed = _tryParseSnapshot(_responseData(response));
      if (parsed != null) {
        state = parsed;
        return;
      }
      await _loadSnapshotOnly();
    } catch (_) {
      // Keep the current state while backend endpoints are being created.
    }
  }

  Future<void> _loadSnapshotOnly() async {
    try {
      final response =
          await _apiClient.get<Map<String, dynamic>>('/kairos/snapshot');
      final parsed = _tryParseSnapshot(_responseData(response));
      if (parsed != null) state = parsed;
    } catch (_) {
      // Keep current state.
    }
  }

  Object? _responseData(Object? response) {
    try {
      return (response as dynamic).data;
    } catch (_) {
      return response;
    }
  }

  KairosData? _tryParseSnapshot(Object? source) {
    final root = _mapOrNull(source);
    if (root == null) return null;
    final payload = _mapOrNull(root['data']) ?? root;
    final snapshot = _mapOrNull(payload['snapshot']) ?? payload;
    if (!snapshot.containsKey('dashboard') &&
        !snapshot.containsKey('profile')) {
      return null;
    }

    return KairosData(
      dashboard: _dashboard(snapshot['dashboard']),
      memories: _list(snapshot['memories']).map(_memory).toList(),
      workflows: _list(snapshot['workflows']).map(_workflow).toList(),
      notifications:
          _list(snapshot['notifications']).map(_notification).toList(),
      needsReview: _list(snapshot['needsReview']).map(_reviewItem).toList(),
      profile: _profile(snapshot['profile']),
      rawNotes: _list(snapshot['rawNotes']).map(_string).toList(),
    );
  }

  String? _replyFromResponse(Object? source) {
    final root = _mapOrNull(source);
    if (root == null) return null;
    final payload = _mapOrNull(root['data']) ?? root;
    final reply = _string(
      payload['reply'] ?? payload['message'] ?? payload['assistantMessage'],
    );
    return reply.isEmpty ? null : reply;
  }

  DashboardData _dashboard(Object? source) {
    final map = _mapOrEmpty(source);
    return DashboardData(
      nextMove: map['nextMove'] == null ? null : _priorityItem(map['nextMove']),
      everythingElse: _list(map['everythingElse']).map(_priorityItem).toList(),
      risks: _list(map['risks']).map(_riskItem).toList(),
      insights: _list(map['insights']).map(_string).toList(),
    );
  }

  PriorityItem _priorityItem(Object? source) {
    final map = _mapOrEmpty(source);
    return PriorityItem(
      id: _string(map['id']),
      title: _string(map['title'], fallback: 'Untitled'),
      type: _memoryType(map['type']),
      dueLabel: _string(map['dueLabel']),
      estimatedMinutes: _int(map['estimatedMinutes']),
      reasons: _list(map['reasons']).map(_string).toList(),
      workflowId: _string(map['workflowId']),
      isAiGenerated: _bool(map['isAiGenerated'], fallback: true),
    );
  }

  RiskItem _riskItem(Object? source) {
    final map = _mapOrEmpty(source);
    return RiskItem(
      id: _string(map['id']),
      title: _string(map['title'], fallback: 'Risk'),
      description: _string(map['description']),
      severity: _confidenceLevel(map['severity']),
      dueLabel: _string(map['dueLabel']),
    );
  }

  Memory _memory(Object? source) {
    final map = _mapOrEmpty(source);
    return Memory(
      id: _string(map['id']),
      title: _string(map['title'], fallback: 'Memory'),
      type: _memoryType(map['type']),
      source: _string(map['source']),
      confidence: _double(map['confidence']),
      status: _string(map['status']),
      updatedLabel: _string(map['updatedLabel']),
      metadata: _stringMap(map['metadata']),
      workflowId: _string(map['workflowId']),
      confirmed: _bool(map['confirmed']),
    );
  }

  NeedsReviewItem _reviewItem(Object? source) {
    final map = _mapOrEmpty(source);
    return NeedsReviewItem(
      id: _string(map['id']),
      title: _string(map['title'], fallback: 'Needs Review'),
      confidence: _double(map['confidence']),
      extractedFields: _stringMap(map['extractedFields']),
      source: _string(map['source']),
    );
  }

  Workflow _workflow(Object? source) {
    final map = _mapOrEmpty(source);
    return Workflow(
      id: _string(map['id']),
      memoryId: _string(map['memoryId']),
      title: _string(map['title'], fallback: 'Workflow'),
      typeLabel: _string(map['typeLabel']),
      state: _workflowState(map['state']),
      snoozesUsed: _int(map['snoozesUsed']),
      steps: _list(map['steps']).map(_workflowStep).toList(),
    );
  }

  WorkflowStep _workflowStep(Object? source) {
    final map = _mapOrEmpty(source);
    return WorkflowStep(
      label: _string(map['label']),
      description: _string(map['description']),
      complete: _bool(map['complete']),
    );
  }

  KairosNotification _notification(Object? source) {
    final map = _mapOrEmpty(source);
    return KairosNotification(
      id: _string(map['id']),
      title: _string(map['title'], fallback: 'Notification'),
      body: _string(map['body']),
      type: _string(map['type']),
      createdLabel: _string(map['createdLabel']),
      deepLink: _string(map['deepLink'], fallback: '/today'),
      read: _bool(map['read']),
    );
  }

  UserProfile _profile(Object? source) {
    final map = _mapOrEmpty(source);
    final fallback = KairosData.empty().profile;
    return UserProfile(
      fullName: _string(map['fullName'], fallback: fallback.fullName),
      email: _string(map['email'], fallback: fallback.email),
      occupation: _string(map['occupation'], fallback: fallback.occupation),
      kairosInboxAddress: _string(
        map['kairosInboxAddress'],
        fallback: fallback.kairosInboxAddress,
      ),
      dailyBriefingTime: _string(
        map['dailyBriefingTime'],
        fallback: fallback.dailyBriefingTime,
      ),
      timezone: _string(map['timezone'], fallback: fallback.timezone),
      currency: _string(map['currency'], fallback: fallback.currency),
      notificationIntensity: _double(
        map['notificationIntensity'],
        fallback: fallback.notificationIntensity,
      ),
      pushEnabled: _bool(map['pushEnabled'], fallback: fallback.pushEnabled),
      emailEnabled: _bool(map['emailEnabled'], fallback: fallback.emailEnabled),
    );
  }

  Map<String, String> _stringMap(Object? source) {
    final map = _mapOrNull(source);
    if (map == null) return {};
    return {
      for (final entry in map.entries)
        entry.key.toString(): _string(entry.value),
    };
  }

  List<Object?> _list(Object? source) {
    if (source is List) return source.cast<Object?>();
    return const [];
  }

  Map<String, dynamic>? _mapOrNull(Object? source) {
    if (source is Map<String, dynamic>) return source;
    if (source is Map) {
      return source.map((key, value) => MapEntry(key.toString(), value));
    }
    return null;
  }

  Map<String, dynamic> _mapOrEmpty(Object? source) {
    return _mapOrNull(source) ?? const {};
  }

  String _string(Object? source, {String fallback = ''}) {
    if (source == null) return fallback;
    final value = source.toString();
    return value.isEmpty ? fallback : value;
  }

  int _int(Object? source, {int fallback = 0}) {
    if (source is int) return source;
    if (source is num) return source.round();
    return int.tryParse(source?.toString() ?? '') ?? fallback;
  }

  double _double(Object? source, {double fallback = 0}) {
    if (source is double) return source;
    if (source is num) return source.toDouble();
    return double.tryParse(source?.toString() ?? '') ?? fallback;
  }

  bool _bool(Object? source, {bool fallback = false}) {
    if (source is bool) return source;
    if (source is num) return source != 0;
    final normalized = source?.toString().toLowerCase();
    if (normalized == 'true') return true;
    if (normalized == 'false') return false;
    return fallback;
  }

  MemoryType _memoryType(Object? source) {
    final normalized = _enumName(source);
    return MemoryType.values.firstWhere(
      (value) => value.name == normalized,
      orElse: () => MemoryType.note,
    );
  }

  ConfidenceLevel _confidenceLevel(Object? source) {
    final normalized = _enumName(source);
    return ConfidenceLevel.values.firstWhere(
      (value) => value.name == normalized,
      orElse: () => ConfidenceLevel.medium,
    );
  }

  WorkflowState _workflowState(Object? source) {
    final normalized = _enumName(source);
    return WorkflowState.values.firstWhere(
      (value) => value.name == normalized,
      orElse: () => WorkflowState.detected,
    );
  }

  String _enumName(Object? source) {
    return _string(source).trim().toLowerCase().replaceAll('-', '_');
  }
}
