class RegionalCenter {
  final String id;
  final String name;
  final String address;
  final String url;
  final double lat;
  final double lng;
  final List<String> disciplines;
  final List<String> pathologies;

  RegionalCenter({
    required this.id,
    required this.name,
    required this.address,
    required this.url,
    required this.lat,
    required this.lng,
    required this.disciplines,
    required this.pathologies,
  });

  factory RegionalCenter.fromJson(Map<String, dynamic> json) {
    List<String> parseMultiline(dynamic value) {
      if (value == null) return [];
      return value
          .toString()
          .split(RegExp(r'\r\n|\n'))
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }

    return RegionalCenter(
      id: json['id']?.toString() ?? '',
      name: json['Name'] ?? '',
      address: json['address'] ?? '',
      url: json['url'] ?? '',
      lat: double.tryParse(json['lat']?.toString() ?? '0') ?? 0.0,
      lng: double.tryParse(json['lng']?.toString() ?? '0') ?? 0.0,
      disciplines: parseMultiline(json['Discipline']),
      pathologies: parseMultiline(json['Pathologies / Prévention']),
    );
  }
}
