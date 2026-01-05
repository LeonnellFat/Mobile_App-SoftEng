class User {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String address;
  final int orders;
  final int favorites;
  final bool isAdmin;
  final bool isDriver;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    this.orders = 0,
    this.favorites = 0,
    this.isAdmin = false,
    this.isDriver = false,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String? ?? '',
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      address: json['address'] as String,
      orders: json['orders'] as int? ?? 0,
      favorites: json['favorites'] as int? ?? 0,
      isAdmin: json['isAdmin'] as bool? ?? false,
      isDriver: json['isDriver'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'orders': orders,
      'favorites': favorites,
      'isAdmin': isAdmin,
      'isDriver': isDriver,
    };
  }

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? address,
    int? orders,
    int? favorites,
    bool? isAdmin,
    bool? isDriver,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      orders: orders ?? this.orders,
      favorites: favorites ?? this.favorites,
      isAdmin: isAdmin ?? this.isAdmin,
      isDriver: isDriver ?? this.isDriver,
    );
  }
}
