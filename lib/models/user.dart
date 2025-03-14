class User {
  final String userId;
  final String displayName;
  final String email;

  User({
    required this.userId,
    required this.displayName,
    required this.email,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['userId'],
      displayName: json['displayName'],
      email: json['email'],
    );
  }
}
