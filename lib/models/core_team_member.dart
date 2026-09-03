class CoreTeamMember {
  final String name;
  final String role;
  final String vertical;
  final String phone;
  final String email;
  final String imageUrl;

  CoreTeamMember({
    required this.name,
    required this.role,
    required this.vertical,
    required this.phone,
    required this.email,
    required this.imageUrl,
  });

  factory CoreTeamMember.fromJson(Map<String, dynamic> json) {
    return CoreTeamMember(
      name: json['name'] ?? '',
      role: json['role'] ?? '',
      vertical: json['vertical'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'role': role,
      'vertical': vertical,
      'phone': phone,
      'email': email,
      'imageUrl': imageUrl,
    };
  }
}
