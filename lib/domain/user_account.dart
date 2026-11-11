class UserAccount {
  const UserAccount({
    required this.id,
    required this.email,
    required this.name,
    this.photoUrl,
  });

  final String id;
  final String email;
  final String name;
  final String? photoUrl;
}
