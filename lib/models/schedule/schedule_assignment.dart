class ScheduleAssignment {
  final int positionId;
  final List<int> personIds;
  final DateTime date;

  const ScheduleAssignment({
    required this.positionId,
    required this.personIds,
    required this.date,
  });

  ScheduleAssignment copyWith({
    int? positionId,
    List<int>? personIds,
    DateTime? date,
  }) {
    return ScheduleAssignment(
      positionId: positionId ?? this.positionId,
      personIds: personIds ?? this.personIds,
      date: date ?? this.date,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'positionId': positionId,
      'personIds': personIds,
      'date': date.toIso8601String(),
    };
  }

  factory ScheduleAssignment.fromJson(Map<String, dynamic> json) {
    return ScheduleAssignment(
      positionId: json['positionId'],
      personIds: List<int>.from(json['personIds']),
      date: DateTime.parse(json['date']),
    );
  }
}