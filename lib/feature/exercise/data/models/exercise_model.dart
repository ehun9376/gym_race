/// 核心動作資料庫 Model，對應 Firestore `exercises` 集合。
///
/// 規範：屬性使用非 optional 型別提高安全性；fromJson 使用 optional
/// 轉換 + null coalescing，避免 runtime crash。
class ExerciseModel {
  final String id;
  final String name;
  final List<String> synonyms;
  final String category;
  final bool isBigThree;
  final double metValue;

  ExerciseModel({
    required this.id,
    required this.name,
    required this.synonyms,
    required this.category,
    required this.isBigThree,
    this.metValue = 6.0,
  });

  /// 寫入 Firestore 時使用的欄位格式（snake_case，與後端一致）。
  Map<String, dynamic> toFirestore() {
    return {
      "id": id,
      "name": name,
      "synonyms": synonyms,
      "category": category,
      "is_big_three": isBigThree,
      "met_value": metValue,
    };
  }

  factory ExerciseModel.fromJson(Map<String, dynamic> json) {
    return ExerciseModel(
      id: json["id"] as String? ?? "",
      name: json["name"] as String? ?? "",
      synonyms: (json["synonyms"] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      category: json["category"] as String? ?? "",
      isBigThree: json["is_big_three"] as bool? ?? false,
      metValue: (json["met_value"] as num?)?.toDouble() ?? 6.0,
    );
  }
}
