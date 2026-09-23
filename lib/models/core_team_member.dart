class CoreTeamMember {
  final String name;
  final String role;
  final String vertical;
  final String phone;
  final String email;
  final String imageUrl;
  final String year;
  final String quote;
  final int order;

  CoreTeamMember({
    required this.name,
    required this.role,
    required this.vertical,
    this.phone = '',
    this.email = '',
    required this.imageUrl,
    this.year = '',
    this.quote = '',
    this.order = 99,
  });

  factory CoreTeamMember.fromJson(Map<String, dynamic> json) {
    return CoreTeamMember(
      name: json['name'] ?? '',
      role: json['role'] ?? '',
      vertical: json['vertical'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      year: json['year'] ?? '',
      quote: json['quote'] ?? '',
      order: json['order'] ?? 99,
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
      'year': year,
      'quote': quote,
      'order': order,
    };
  }
}
