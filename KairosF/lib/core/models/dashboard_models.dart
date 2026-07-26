import 'enums.dart';

class PriorityItem {
  const PriorityItem({
    required this.id,
    required this.title,
    required this.type,
    required this.dueLabel,
    required this.estimatedMinutes,
    required this.reasons,
    required this.workflowId,
    this.isAiGenerated = true,
  });

  final String id;
  final String title;
  final MemoryType type;
  final String dueLabel;
  final int estimatedMinutes;
  final List<String> reasons;
  final String workflowId;
  final bool isAiGenerated;
}

class RiskItem {
  const RiskItem({
    required this.id,
    required this.title,
    required this.description,
    required this.severity,
    required this.dueLabel,
  });

  final String id;
  final String title;
  final String description;
  final ConfidenceLevel severity;
  final String dueLabel;
}

class DashboardData {
  const DashboardData({
    required this.nextMove,
    required this.everythingElse,
    required this.risks,
    required this.insights,
  });

  final PriorityItem? nextMove;
  final List<PriorityItem> everythingElse;
  final List<RiskItem> risks;
  final List<String> insights;

  bool get allClear =>
      nextMove == null && everythingElse.isEmpty && risks.isEmpty;

  DashboardData copyWith({
    PriorityItem? nextMove,
    List<PriorityItem>? everythingElse,
    List<RiskItem>? risks,
    List<String>? insights,
    bool clearNextMove = false,
  }) {
    return DashboardData(
      nextMove: clearNextMove ? null : nextMove ?? this.nextMove,
      everythingElse: everythingElse ?? this.everythingElse,
      risks: risks ?? this.risks,
      insights: insights ?? this.insights,
    );
  }
}
