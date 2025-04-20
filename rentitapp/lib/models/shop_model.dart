class ShopModel {
  final int id;
  final String name;
  final String? description;
  final double? latitude;
  final double? longitude;
  final String? location;
  final String? imageUrl;
  final String? contactNumber;
  final String? email;

  ShopModel({
    required this.id,
    required this.name,
    this.description,
    this.latitude,
    this.longitude,
    this.location,
    this.imageUrl,
    this.contactNumber,
    this.email,
  });

  // Factory method to create a ShopModel from a map
  factory ShopModel.fromMap(Map<String, dynamic> map) {
    return ShopModel(
      id: map['shop_id'],
      name: map['name'],
      description: map['description'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      location: map['location'],
      imageUrl: map['image_url'],
      contactNumber: map['contact_number'],
      email: map['email'],
    );
  }
}