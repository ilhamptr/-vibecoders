class ProjectLocation {
  const ProjectLocation({
    required this.province,
    required this.city,
    this.district,
    this.village,
    this.latitude,
    this.longitude,
  });

  final String province;
  final String city;
  final String? district;
  final String? village;
  final double? latitude;
  final double? longitude;

  String get displayName {
    final parts = <String>[
      if (village != null && village!.isNotEmpty) village!,
      if (district != null && district!.isNotEmpty) district!,
      if (city.isNotEmpty) city,
      if (province.isNotEmpty) province,
    ];

    return parts.join(', ');
  }
}
