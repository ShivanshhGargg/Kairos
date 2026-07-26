import 'enums.dart';

class Memory {
  const Memory({
    required this.id,
    required this.title,
    required this.type,
    required this.source,
    required this.confidence,
    required this.status,
    required this.updatedLabel,
    required this.metadata,
    required this.workflowId,
    this.confirmed = false,
  });

  final String id;
  final String title;
  final MemoryType type;
  final String source;
  final double confidence;
  final String status;
  final String updatedLabel;
  final Map<String, String> metadata;
  final String workflowId;
  final bool confirmed;

  ConfidenceLevel get confidenceLevel {
    if (confidence >= 0.9) return ConfidenceLevel.high;
    if (confidence >= 0.7) return ConfidenceLevel.medium;
    return ConfidenceLevel.low;
  }

  Memory copyWith({
    String? status,
    bool? confirmed,
    double? confidence,
    Map<String, String>? metadata,
  }) {
    return Memory(
      id: id,
      title: title,
      type: type,
      source: source,
      confidence: confidence ?? this.confidence,
      status: status ?? this.status,
      updatedLabel: updatedLabel,
      metadata: metadata ?? this.metadata,
      workflowId: workflowId,
      confirmed: confirmed ?? this.confirmed,
    );
  }
}

class NeedsReviewItem {
  const NeedsReviewItem({
    required this.id,
    required this.title,
    required this.confidence,
    required this.extractedFields,
    required this.source,
  });

  final String id;
  final String title;
  final double confidence;
  final Map<String, String> extractedFields;
  final String source;

  ConfidenceLevel get confidenceLevel {
    if (confidence >= 0.9) return ConfidenceLevel.high;
    if (confidence >= 0.7) return ConfidenceLevel.medium;
    return ConfidenceLevel.low;
  }
}
