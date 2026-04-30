import 'dart:convert';

class EnrolledSound {
  const EnrolledSound({required this.name, required this.embedding});

  final String name;
  final List<double> embedding;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'name': name,
      'embedding': embedding,
    };
  }

  static EnrolledSound fromJson(Map<String, Object?> json) {
    final name = (json['name'] as String?)?.trim() ?? '';
    final embeddingRaw = json['embedding'];
    final embedding = <double>[];
    if (embeddingRaw is List) {
      for (final v in embeddingRaw) {
        if (v is num) {
          embedding.add(v.toDouble());
        }
      }
    }

    return EnrolledSound(name: name, embedding: embedding);
  }

  String toJsonString() => jsonEncode(toJson());

  static EnrolledSound fromJsonString(String jsonString) {
    final decoded = jsonDecode(jsonString);
    if (decoded is Map<String, Object?>) {
      return fromJson(decoded);
    }
    if (decoded is Map) {
      return fromJson(decoded.cast<String, Object?>());
    }
    throw FormatException('Invalid EnrolledSound JSON');
  }
}
