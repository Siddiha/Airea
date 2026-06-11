/// Model class representing a single allergy or medical condition entry.
/// Stores all data the user enters and supports immutable updates via [copyWith].
class AllergyEntry {
  /// Unique identifier (UUID-style) generated at creation time.
  final String id;

  /// Short name / label of the allergy or condition, e.g. "Pollen", "Asthma".
  final String name;

  /// Free-form description / notes the user may add (editable in EditAllergySheet).
  final String description;

  /// Timestamp when this entry was first created.
  final DateTime createdAt;

  const AllergyEntry({
    required this.id,
    required this.name,
    required this.description,
    required this.createdAt,
  });

  /// Factory that auto-generates an [id] and [createdAt].
  factory AllergyEntry.create({
    required String name,
    String description = '',
  }) {
    return AllergyEntry(
      id: '${DateTime.now().millisecondsSinceEpoch}_${name.hashCode.abs()}',
      name: name,
      description: description,
      createdAt: DateTime.now(),
    );
  }

  /// Returns a new [AllergyEntry] with the given fields replaced.
  /// Unchanged fields keep their original values.
  AllergyEntry copyWith({
    String? name,
    String? description,
  }) {
    return AllergyEntry(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt,
    );
  }

  @override
  String toString() =>
      'AllergyEntry(id: $id, name: $name, description: $description)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AllergyEntry &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
    };
  }
}
