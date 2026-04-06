class ObraSocialModel {
  const ObraSocialModel({
    required this.id,
    required this.name,
    required this.code,
  });

  final int id;
  final String name;
  final String code;

  factory ObraSocialModel.fromJson(Map<String, dynamic> json) => ObraSocialModel(
        id: json['id'] as int,
        name: json['name'] as String,
        code: json['code'] as String,
      );
}
