class ProStatus {
  final bool isPro;

  const ProStatus({required this.isPro});

  factory ProStatus.fromJson(Map<String, dynamic> json) =>
      ProStatus(isPro: json['is_pro'] as bool? ?? false);
}
