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

  factory BodyMeasurement.fromJson(Map<String, dynamic> json) =>
      BodyMeasurement(
        id: json['id'] as String? ?? '',
        measuredAt: json['measured_at'] as String? ?? '',
        weightKg: (json['weight_kg'] as num?)?.toDouble(),
        bodyFatPercent: (json['body_fat_percent'] as num?)?.toDouble(),
        chestCm: (json['chest_cm'] as num?)?.toDouble(),
        waistCm: (json['waist_cm'] as num?)?.toDouble(),
        hipsCm: (json['hips_cm'] as num?)?.toDouble(),
        leftArmCm: (json['left_arm_cm'] as num?)?.toDouble(),
        rightArmCm: (json['right_arm_cm'] as num?)?.toDouble(),
        leftThighCm: (json['left_thigh_cm'] as num?)?.toDouble(),
        rightThighCm: (json['right_thigh_cm'] as num?)?.toDouble(),
        note: json['note'] as String? ?? '',
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
