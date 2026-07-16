class OrcidEmployment {
  final String departmentName;
  final String roleTitle;
  final String organizationName;
  final String city;
  final String region;
  final String country;
  final DateTime? startDate;
  final DateTime? endDate;

  const OrcidEmployment({
    this.departmentName = '',
    this.roleTitle = '',
    this.organizationName = '',
    this.city = '',
    this.region = '',
    this.country = '',
    this.startDate,
    this.endDate,
  });

  factory OrcidEmployment.fromJson(Map<String, dynamic> json) {
    final org = json['organization'] as Map<String, dynamic>? ?? {};
    final address = org['address'] as Map<String, dynamic>? ?? {};

    return OrcidEmployment(
      departmentName: json['department-name']?.toString() ?? '',
      roleTitle: json['role-title']?.toString() ?? '',
      organizationName: org['name']?.toString() ?? '',
      city: address['city']?.toString() ?? '',
      region: address['region']?.toString() ?? '',
      country: address['country']?.toString() ?? '',
      startDate: _parseDate(json['start-date']),
      endDate: _parseDate(json['end-date']),
    );
  }

  static DateTime? _parseDate(dynamic dateObj) {
    if (dateObj == null) return null;
    if (dateObj is! Map) return null;
    final year = int.tryParse(dateObj['year']?.toString() ?? '') ?? 0;
    final month = int.tryParse(dateObj['month']?.toString() ?? '') ?? 1;
    final day = int.tryParse(dateObj['day']?.toString() ?? '') ?? 1;
    if (year == 0) return null;
    return DateTime(year, month.clamp(1, 12), day.clamp(1, 31));
  }
}
