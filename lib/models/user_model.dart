class User {
  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;

  User({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      displayName: json['name'],
      photoUrl: json['picture'],
    );
  }
}
