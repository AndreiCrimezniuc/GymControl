import 'package:gymboss/domain/models/json_readers.dart';

class BodyMeasurement {
  final String id;
  final String measuredAt;
  final double? weightKg;
  final double? bodyFatPercent;
  final double? chestCm;
  final double? waistCm;
  final double? hipsCm;
  final double? leftArmCm;
  final double? rightArmCm;
  final double? leftThighCm;
  final double? rightThighCm;
  final String note;

  const BodyMeasurement({
    required this.id,
    required this.measuredAt,
    this.weightKg,
    this.bodyFatPercent,
    this.chestCm,
    this.waistCm,
    this.hipsCm,
    this.leftArmCm,
    this.rightArmCm,
    this.leftThighCm,
    this.rightThighCm,
    this.note = '',
  });

  factory BodyMeasurement.fromJson(
    Map<String, dynamic> json,
  ) => BodyMeasurement(
    id: jsonString(json['id']),
    measuredAt: jsonString(json['measured_at']),
    weightKg: jsonNullableDouble(json['weight_kg'], min: 0, max: 1000),
    bodyFatPercent: jsonNullableDouble(
      json['body_fat_percent'],
      min: 0,
      max: 100,
    ),
    chestCm: jsonNullableDouble(json['chest_cm'], min: 0, max: 1000),
    waistCm: jsonNullableDouble(json['waist_cm'], min: 0, max: 1000),
    hipsCm: jsonNullableDouble(json['hips_cm'], min: 0, max: 1000),
    leftArmCm: jsonNullableDouble(json['left_arm_cm'], min: 0, max: 1000),
    rightArmCm: jsonNullableDouble(json['right_arm_cm'], min: 0, max: 1000),
    leftThighCm: jsonNullableDouble(json['left_thigh_cm'], min: 0, max: 1000),
    rightThighCm: jsonNullableDouble(json['right_thigh_cm'], min: 0, max: 1000),
    note: jsonString(json['note']),
  );

  Map<String, dynamic> toJson() => {
    'measured_at': measuredAt,
    'weight_kg': weightKg,
    'body_fat_percent': bodyFatPercent,
    'chest_cm': chestCm,
    'waist_cm': waistCm,
    'hips_cm': hipsCm,
    'left_arm_cm': leftArmCm,
    'right_arm_cm': rightArmCm,
    'left_thigh_cm': leftThighCm,
    'right_thigh_cm': rightThighCm,
    'note': note,
  };
}
