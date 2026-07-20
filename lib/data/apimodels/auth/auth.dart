import 'package:gymboss/domain/models/auth/user.dart';

class TokenResponseModel {
  final String accessToken;
  final String refreshToken;

  const TokenResponseModel({required this.accessToken, required this.refreshToken});

  factory TokenResponseModel.fromJson(Map<String, dynamic> json) {
    return TokenResponseModel(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
    );
  }

  AuthTokens toDomain() => AuthTokens(
    accessToken: accessToken,
    refreshToken: refreshToken,
  );
}
