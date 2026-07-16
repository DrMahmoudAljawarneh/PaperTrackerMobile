class OrcidName {
  final String givenNames;
  final String familyName;
  final String creditName;
  final String displayName;

  const OrcidName({
    this.givenNames = '',
    this.familyName = '',
    this.creditName = '',
    this.displayName = '',
  });

  factory OrcidName.fromJson(Map<String, dynamic> json) {
    final name = json['name'] as Map<String, dynamic>?;
    return OrcidName(
      givenNames: _readVal(name, 'given-names', 'value'),
      familyName: _readVal(name, 'family-name', 'value'),
      creditName: _readVal(name, 'credit-name', 'value'),
      displayName: _readVal(name, 'display-name'),
    );
  }

  static String _readVal(Map<String, dynamic>? map, String outer, [String inner = '']) {
    if (map == null) return '';
    final outerVal = map[outer];
    if (outerVal == null) return '';
    if (inner.isNotEmpty && outerVal is Map) return outerVal[inner]?.toString() ?? '';
    return outerVal.toString();
  }
}
