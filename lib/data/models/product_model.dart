import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:karrot_clone/domain/entities/product.dart';

class ProductModel extends Product {
  const ProductModel({
    required super.id,
    required super.title,
    required super.description,
    required super.price,
    required super.imageUrls,
    required super.category,
    required super.sellerId,
    super.buyerId,
    required super.location,
    super.longitude,
    super.latitude,
    super.geoHash,
    required super.status,
    required super.viewCount,
    required super.likeCount,
    required super.likeUids,
    required super.createdAt,
    required super.updatedAt,
    required super.isNegotiable,
  });

  /// Firestore 문서에서 ProductModel 생성
  factory ProductModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return ProductModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      price: data['price'] ?? 0,
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      category: data['category'] ?? '',
      sellerId: data['sellerId'] ?? '',
      buyerId: data['buyerId'],
      location: data['location'] ?? '',
      longitude: data['longitude']?.toDouble(),
      latitude: data['latitude']?.toDouble(),
      geoHash: data['geo_hash'],
      status: _statusFromString(data['status'] ?? 'available'),
      viewCount: data['viewCount'] ?? 0,
      likeCount: data['likeCount'] ?? 0,
      likeUids: List<String>.from(data['likeUids'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isNegotiable: data['isNegotiable'] ?? false,
    );
  }

  /// Map에서 ProductModel 생성
  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      price: json['price'] ?? 0,
      imageUrls: List<String>.from(json['imageUrls'] ?? []),
      category: json['category'] ?? '',
      sellerId: json['sellerId'] ?? '',
      buyerId: json['buyerId'],
      location: json['location'] ?? '',
      longitude: json['longitude']?.toDouble(),
      latitude: json['latitude']?.toDouble(),
      geoHash: json['geo_hash'],
      status: _statusFromString(json['status'] ?? 'available'),
      viewCount: json['viewCount'] ?? 0,
      likeCount: json['likeCount'] ?? 0,
      likeUids: List<String>.from(json['likeUids'] ?? []),
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.parse(
              json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: json['updatedAt'] is Timestamp
          ? (json['updatedAt'] as Timestamp).toDate()
          : DateTime.parse(
              json['updatedAt'] ?? DateTime.now().toIso8601String()),
      isNegotiable: json['isNegotiable'] ?? false,
    );
  }

  /// ProductModel을 Map으로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'price': price,
      'imageUrls': imageUrls,
      'category': category,
      'sellerId': sellerId,
      'buyerId': buyerId,
      'location': location,
      'longitude': longitude,
      'latitude': latitude,
      'geo_hash': geoHash,
      'status': _statusToString(status),
      'viewCount': viewCount,
      'likeCount': likeCount,
      'likeUids': likeUids,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isNegotiable': isNegotiable,
    };
  }

  /// Firestore에 저장할 Map으로 변환 (id 제외)
  Map<String, dynamic> toFirestore() {
    final json = toJson();
    json.remove('id'); // Firestore 문서 ID는 별도로 관리
    return json;
  }

  /// Entity를 Model로 변환
  factory ProductModel.fromEntity(Product product) {
    return ProductModel(
      id: product.id,
      title: product.title,
      description: product.description,
      price: product.price,
      imageUrls: product.imageUrls,
      category: product.category,
      sellerId: product.sellerId,
      buyerId: product.buyerId,
      location: product.location,
      longitude: product.longitude,
      latitude: product.latitude,
      geoHash: product.geoHash,
      status: product.status,
      viewCount: product.viewCount,
      likeCount: product.likeCount,
      likeUids: product.likeUids,
      createdAt: product.createdAt,
      updatedAt: product.updatedAt,
      isNegotiable: product.isNegotiable,
    );
  }

  /// copyWith 메서드
  ProductModel copyWith({
    String? id,
    String? title,
    String? description,
    int? price,
    List<String>? imageUrls,
    String? category,
    String? sellerId,
    String? buyerId,
    String? location,
    double? longitude,
    double? latitude,
    String? geoHash,
    ProductStatus? status,
    int? viewCount,
    int? likeCount,
    List<String>? likeUids,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isNegotiable,
  }) {
    return ProductModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      imageUrls: imageUrls ?? this.imageUrls,
      category: category ?? this.category,
      sellerId: sellerId ?? this.sellerId,
      buyerId: buyerId ?? this.buyerId,
      location: location ?? this.location,
      longitude: longitude ?? this.longitude,
      latitude: latitude ?? this.latitude,
      geoHash: geoHash ?? this.geoHash,
      status: status ?? this.status,
      viewCount: viewCount ?? this.viewCount,
      likeCount: likeCount ?? this.likeCount,
      likeUids: likeUids ?? this.likeUids,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isNegotiable: isNegotiable ?? this.isNegotiable,
    );
  }

  /// String을 ProductStatus로 변환
  static ProductStatus _statusFromString(String status) {
    switch (status) {
      case 'available':
        return ProductStatus.available;
      case 'reserved':
        return ProductStatus.reserved;
      case 'sold':
        return ProductStatus.sold;
      default:
        return ProductStatus.available;
    }
  }

  /// ProductStatus를 String으로 변환
  static String _statusToString(ProductStatus status) {
    switch (status) {
      case ProductStatus.available:
        return 'available';
      case ProductStatus.reserved:
        return 'reserved';
      case ProductStatus.sold:
        return 'sold';
    }
  }
}
