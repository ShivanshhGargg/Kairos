enum MemoryType {
  bill,
  exam,
  assignment,
  meeting,
  subscription,
  travel,
  goal,
  note,
}

extension MemoryTypeLabel on MemoryType {
  String get label {
    return switch (this) {
      MemoryType.bill => 'Bill',
      MemoryType.exam => 'Exam',
      MemoryType.assignment => 'Assignment',
      MemoryType.meeting => 'Meeting',
      MemoryType.subscription => 'Subscription',
      MemoryType.travel => 'Travel',
      MemoryType.goal => 'Goal',
      MemoryType.note => 'Note',
    };
  }
}

enum ConfidenceLevel { high, medium, low }

extension ConfidenceLabel on ConfidenceLevel {
  String get label {
    return switch (this) {
      ConfidenceLevel.high => 'High',
      ConfidenceLevel.medium => 'Medium',
      ConfidenceLevel.low => 'Low',
    };
  }
}

enum WorkflowState { detected, approaching, critical, overdue, resolved }

extension WorkflowStateLabel on WorkflowState {
  String get label {
    return switch (this) {
      WorkflowState.detected => 'Detected',
      WorkflowState.approaching => 'Approaching',
      WorkflowState.critical => 'Critical',
      WorkflowState.overdue => 'Overdue',
      WorkflowState.resolved => 'Resolved',
    };
  }
}
