class Rider {
  final int id;
  final String name;
  final String email;
  final String? phone;

  Rider({required this.id, required this.name, required this.email, this.phone});

  // factory Rider.fromJson(Map<String, dynamic> json) {
  //   return Rider(
  //     id: json['id'],
  //     name: json['name'],
  //     email: json['email'],
  //     phone: json['phone'],
  //   );
  // }

  factory Rider.fromJson(Map<String, dynamic> j) {
  return Rider(
    id: j['id'] as int,
    name: (j['name'] as String?) ?? '– no name –',
    email: (j['email'] as String?) ?? '',
    phone: j['phone'] as String?,  // stays nullable
  );
}

}
