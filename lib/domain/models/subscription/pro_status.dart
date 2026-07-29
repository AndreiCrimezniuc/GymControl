class ProStatus {
  final bool isPro;
  final DateTime? expiresAt;

  const ProStatus({required this.isPro, this.expiresAt});

  factory ProStatus.fromJson(Map<String, dynamic> json) => ProStatus(
    isPro: json['is_pro'] as bool? ?? false,
    expiresAt: DateTime.tryParse(json['expires_at'] as String? ?? ''),
  );
}
