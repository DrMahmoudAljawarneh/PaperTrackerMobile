Map<String, dynamic> safeCastMap(dynamic value) {
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }
  return <String, dynamic>{};
}

List<String> safeCastStringList(dynamic value) {
  if (value is List) {
    return List<String>.from(value);
  }
  return [];
}
