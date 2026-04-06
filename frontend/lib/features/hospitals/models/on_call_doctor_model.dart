class OnCallDoctorModel {
  const OnCallDoctorModel({
    required this.id,
    required this.hospitalId,
    required this.doctorName,
    this.specialtyId,
    this.specialtyName,
    required this.shiftStart,
    required this.shiftEnd,
    required this.createdAt,
  });

  final int id;
  final int hospitalId;
  final String doctorName;
  final int? specialtyId;
  final String? specialtyName;
  final DateTime shiftStart;
  final DateTime shiftEnd;
  final DateTime createdAt;

  factory OnCallDoctorModel.fromJson(Map<String, dynamic> json) => OnCallDoctorModel(
        id: json['id'] as int,
        hospitalId: json['hospital_id'] as int,
        doctorName: json['doctor_name'] as String,
        specialtyId: json['specialty_id'] as int?,
        specialtyName: json['specialty_name'] as String?,
        shiftStart: DateTime.parse(json['shift_start'] as String),
        shiftEnd: DateTime.parse(json['shift_end'] as String),
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
