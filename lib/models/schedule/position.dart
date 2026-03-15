class Position {
  final int id;
  final String name;
  final String description;
  final int maxCapacity;
  final String color;
  final String icon;

  const Position({
    required this.id,
    required this.name,
    required this.description,
    required this.maxCapacity,
    required this.color,
    required this.icon,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Position && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  Position copyWith({
    int? id,
    String? name,
    String? description,
    int? maxCapacity,
    String? color,
    String? icon,
  }) {
    return Position(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      maxCapacity: maxCapacity ?? this.maxCapacity,
      color: color ?? this.color,
      icon: icon ?? this.icon,
    );
  }
}