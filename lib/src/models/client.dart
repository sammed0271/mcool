class Client {
  final int? id;
  final String name;
  final String? phone;
  final String? address;

  const Client({
    this.id,
    required this.name,
    this.phone,
    this.address,
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'phone': phone,
        'address': address,
      };

  factory Client.fromMap(Map<String, dynamic> map) => Client(
        id: (map['id'] as num?)?.toInt(),
        name: map['name'] as String,
        phone: map['phone'] as String?,
        address: map['address'] as String?,
      );

  @override
  String toString() => 'Client(id: $id, name: $name, phone: $phone)';
}
