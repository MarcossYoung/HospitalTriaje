class HospitalModel {
  const HospitalModel({
    required this.id,
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
    this.phone,
    this.waitTimeMin,
    this.availableBeds,
    this.distanceKm,
    this.score,
    this.specialties = const [],
  });

  final int id;
  final String name;
  final String address;
  final double lat;
  final double lng;
  final String? phone;
  final int? waitTimeMin;
  final int? availableBeds;
  final double? distanceKm;
  final double? score;
  final List<SpecialtyModel> specialties;

  factory HospitalModel.fromJson(Map<String, dynamic> json) {
    final status = json['status'] as Map<String, dynamic>?;
    final specs = (json['specialties'] as List<dynamic>? ?? [])
        .map((e) => SpecialtyModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return HospitalModel(
      id: json['id'] as int,
      name: json['name'] as String,
      address: json['address'] as String,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      phone: json['phone'] as String?,
      waitTimeMin: status?['wait_time_min'] as int?,
      availableBeds: status?['available_beds'] as int?,
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
      score: (json['score'] as num?)?.toDouble(),
      specialties: specs,
    );
  }

  HospitalModel copyWith({int? waitTimeMin, int? availableBeds}) => HospitalModel(
        id: id,
        name: name,
        address: address,
        lat: lat,
        lng: lng,
        phone: phone,
        waitTimeMin: waitTimeMin ?? this.waitTimeMin,
        availableBeds: availableBeds ?? this.availableBeds,
        distanceKm: distanceKm,
        score: score,
        specialties: specialties,
      );
}

class SpecialtyModel {
  const SpecialtyModel({
    required this.id,
    required this.nameEs,
    required this.slug,
    required this.isAvailable,
  });

  final int id;
  final String nameEs;
  final String slug;
  final bool isAvailable;

  factory SpecialtyModel.fromJson(Map<String, dynamic> json) => SpecialtyModel(
        id: json['id'] as int,
        nameEs: json['name_es'] as String,
        slug: json['slug'] as String,
        isAvailable: json['is_available'] as bool,
      );
}
