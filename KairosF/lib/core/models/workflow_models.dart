import 'enums.dart';

class WorkflowStep {
  const WorkflowStep({
    required this.label,
    required this.description,
    required this.complete,
  });

  final String label;
  final String description;
  final bool complete;
}

class Workflow {
  const Workflow({
    required this.id,
    required this.memoryId,
    required this.title,
    required this.typeLabel,
    required this.state,
    required this.snoozesUsed,
    required this.steps,
  });

  final String id;
  final String memoryId;
  final String title;
  final String typeLabel;
  final WorkflowState state;
  final int snoozesUsed;
  final List<WorkflowStep> steps;

  Workflow copyWith({
    WorkflowState? state,
    int? snoozesUsed,
    List<WorkflowStep>? steps,
  }) {
    return Workflow(
      id: id,
      memoryId: memoryId,
      title: title,
      typeLabel: typeLabel,
      state: state ?? this.state,
      snoozesUsed: snoozesUsed ?? this.snoozesUsed,
      steps: steps ?? this.steps,
    );
  }
}
