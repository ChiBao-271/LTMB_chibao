class AuthUser {
  final String uid;
  final String? email;
  final String? displayName;

  AuthUser({
    required this.uid,
    this.email,
    this.displayName,
  });

  factory AuthUser.fromFirebaseUser(dynamic user) {
    return AuthUser(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
    );
  }
}