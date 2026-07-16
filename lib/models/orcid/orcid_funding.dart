class OrcidFunding {
  final String title;
  final String organizationName;
  final String type;
  final DateTime? startDate;
  final DateTime? endDate;
  final String amount;

  const OrcidFunding({
    this.title = '',
    this.organizationName = '',
    this.type = '',
    this.startDate,
    this.endDate,
    this.amount = '',
  });

  factory OrcidFunding.fromJson(Map<String, dynamic> json) {
    final titleMap = json['title'] as Map<String, dynamic>?;
    final titleVal = titleMap?['title']?['value']?.toString() ?? '';

    final org = json['organization'] as Map<String, dynamic>?;
    final orgName = org?['name']?.toString() ?? '';

    final amountMap = json['amount'] as Map<String, dynamic>?;
    String amountVal = '';
    if (amountMap != null) {
      final currency = amountMap['currency-code']?.toString() ?? '';
      final value = amountMap['value']?.toString() ?? '';
      amountVal = '$currency $value'.trim();
    }

    return OrcidFunding(
      title: titleVal,
      organizationName: orgName,
      type: json['type']?.toString() ?? '',
      startDate: _parseDate(json['start-date']),
      endDate: _parseDate(json['end-date']),
      amount: amountVal,
    );
  }

  static DateTime? _parseDate(dynamic dateObj) {
    if (dateObj == null || dateObj is! Map) return null;
    final year = int.tryParse(dateObj['year']?.toString() ?? '') ?? 0;
    final month = int.tryParse(dateObj['month']?.toString() ?? '') ?? 1;
    final day = int.tryParse(dateObj['day']?.toString() ?? '') ?? 1;
    if (year == 0) return null;
    return DateTime(year, month.clamp(1, 12), day.clamp(1, 31));
  }
}
