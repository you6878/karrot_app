import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/recent_viewed_product_entity.dart';

class RecentViewedProductModel extends Equatable {
  final String id;
  final String userId;
  final String productId;
  final String productTitle;
  final int productPrice;
  final String productImageUrl;
  final String productLocation;
  final String productStatus;
  final DateTime viewedAt;

  const RecentViewedProductModel({
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

  // Entity로 변환
  RecentViewedProductEntity toEntity() {
    return RecentViewedProductEntity(
      id: id,
      userId: userId,
      productId: productId,
      productTitle: productTitle,
      productPrice: productPrice,
      productImageUrl: productImageUrl,
      productLocation: productLocation,
      productStatus: productStatus,
      viewedAt: viewedAt,
    );
  }

  // Entity에서 Model로 변환
  factory RecentViewedProductModel.fromEntity(
    RecentViewedProductEntity entity,
  ) {
    return RecentViewedProductModel(
      id: entity.id,
      userId: entity.userId,
      productId: entity.productId,
      productTitle: entity.productTitle,
      productPrice: entity.productPrice,
      productImageUrl: entity.productImageUrl,
      productLocation: entity.productLocation,
      productStatus: entity.productStatus,
      viewedAt: entity.viewedAt,
    );
  }

  // Firestore에서 가져온 데이터를 Model로 변환
  factory RecentViewedProductModel.fromJson(Map<String, dynamic> json) {
    return RecentViewedProductModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      productId: json['productId'] as String,
      productTitle: json['productTitle'] as String,
      productPrice: json['productPrice'] as int,
      productImageUrl: json['productImageUrl'] as String,
      productLocation: json['productLocation'] as String,
      productStatus: json['productStatus'] as String,
      viewedAt: (json['viewedAt'] as Timestamp).toDate(),
    );
  }

  // Firestore 문서에서 Model로 변환
  factory RecentViewedProductModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RecentViewedProductModel(
      id: doc.id,
      userId: data['userId'] as String,
      productId: data['productId'] as String,
      productTitle: data['productTitle'] as String,
      productPrice: data['productPrice'] as int,
      productImageUrl: data['productImageUrl'] as String? ?? '',
      productLocation: data['productLocation'] as String,
      productStatus: data['productStatus'] as String,
      viewedAt: (data['viewedAt'] as Timestamp).toDate(),
    );
  }

  // Firestore에 저장할 데이터로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'productId': productId,
      'productTitle': productTitle,
      'productPrice': productPrice,
      'productImageUrl': productImageUrl,
      'productLocation': productLocation,
      'productStatus': productStatus,
      'viewedAt': Timestamp.fromDate(viewedAt),
    };
  }

  // Firestore에 저장할 Map으로 변환 (id 제외)
  Map<String, dynamic> toFirestore() {
    final json = toJson();
    json.remove('id'); // Firestore 문서 ID는 별도로 관리
    return json;
  }

  // copyWith 메서드
  RecentViewedProductModel copyWith({
    String? id,
    String? userId,
    String? productId,
    String? productTitle,
    int? productPrice,
    String? productImageUrl,
    String? productLocation,
    String? productStatus,
    DateTime? viewedAt,
  }) {
    return RecentViewedProductModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      productId: productId ?? this.productId,
      productTitle: productTitle ?? this.productTitle,
      productPrice: productPrice ?? this.productPrice,
      productImageUrl: productImageUrl ?? this.productImageUrl,
      productLocation: productLocation ?? this.productLocation,
      productStatus: productStatus ?? this.productStatus,
      viewedAt: viewedAt ?? this.viewedAt,
    );
  }

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











