class Rider {
  final int id;
  final String name;
  final String email;
  final String? phone;

  Rider({required this.id, required this.name, required this.email, this.phone});

  factory Rider.fromJson(Map<String, dynamic> json) {
    return Rider(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
    );
  }
}
