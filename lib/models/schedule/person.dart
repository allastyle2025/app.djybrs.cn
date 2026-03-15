class Person {
  final int id;
  final String name;
  final String? avatar;
  final String? department;
  final bool isAvailable;

  const Person({
    required this.id,
    required this.name,
    this.avatar,
    this.department,
    this.isAvailable = true,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Person && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  Person copyWith({
    int? id,
    String? name,
    String? avatar,
    String? department,
    bool? isAvailable,
  }) {
    return Person(
      id: id ?? this.id,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      department: department ?? this.department,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }
}