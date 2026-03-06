import 'package:equatable/equatable.dart';

class AuthUser extends Equatable {
  const AuthUser({
    required this.id,
    required this.email,
    this.fullName,
    this.avatarUrl,
    this.provider,
  });

  final String id;
  final String email;
  final String? fullName;
  final String? avatarUrl;
  final String? provider; // e.g., "google", "facebook", "email"

  bool get hasAvatar => avatarUrl != null && avatarUrl!.isNotEmpty;
  String get displayName => fullName ?? email.split('@').first;

  @override
  List<Object?> get props => [id, email, provider];
}
