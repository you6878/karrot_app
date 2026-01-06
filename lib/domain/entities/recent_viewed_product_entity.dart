import 'package:equatable/equatable.dart';

class RecentViewedProductEntity extends Equatable {
  final String id;
  final String userId;
  final String productId;
  final String productTitle;
  final int productPrice;
  final String productImageUrl;
  final String productLocation;
  final String productStatus;
  final DateTime viewedAt;

  const RecentViewedProductEntity({
    required this.id,
    required this.userId,
    required this.productId,
    required this.productTitle,
    required this.productPrice,
    required this.productImageUrl,
    required this.productLocation,
    required this.productStatus,
    required this.viewedAt,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        productId,
        productTitle,
        productPrice,
        productImageUrl,
        productLocation,
        productStatus,
        viewedAt,
      ];
}













