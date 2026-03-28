/// Сохранённая сессия чата в сейфе.
class VaultSession {
  const VaultSession({
    required this.id,
    required this.title,
    required this.savedAt,
    this.encryptedData,
  });

  final String id;
  /// Первые слова / превью (хранится в индексе).
  final String title;
  final DateTime savedAt;
  /// Base64-пакет из secure storage (IV + ciphertext+tag), если загружен.
  final String? encryptedData;

  Map<String, dynamic> toIndexJson() => {
        'id': id,
        'title': title,
        'savedAt': savedAt.toIso8601String(),
      };

  factory VaultSession.fromIndexJson(Map<String, dynamic> json) {
    return VaultSession(
      id: json['id'] as String,
      title: json['title'] as String,
      savedAt: DateTime.parse(json['savedAt'] as String),
    );
  }

  VaultSession copyWith({String? encryptedData}) {
    return VaultSession(
      id: id,
      title: title,
      savedAt: savedAt,
      encryptedData: encryptedData ?? this.encryptedData,
    );
  }
}
