import 'package:equatable/equatable.dart';

enum ProductStatus { available, reserved, sold }

class Product extends Equatable {
  final String id;
  final String title;
  final String description;
  final int price;
  final List<String> imageUrls;
  final String category;
  final String sellerId;
  final String location;
  final double? longitude;
  final double? latitude;
  final ProductStatus status;
  final int viewCount;
  final int likeCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isNegotiable;

  const Product({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.imageUrls,
    required this.category,
    required this.sellerId,
    required this.location,
    this.longitude,
    this.latitude,
    required this.status,
    required this.viewCount,
    required this.likeCount,
    required this.createdAt,
    required this.updatedAt,
    required this.isNegotiable,
  });

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        price,
        imageUrls,
        category,
        sellerId,
        location,
        longitude,
        latitude,
        status,
        viewCount,
        likeCount,
        createdAt,
        updatedAt,
        isNegotiable,
      ];
}
