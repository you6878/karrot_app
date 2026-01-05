import 'package:karrot_clone/domain/entities/product.dart';

abstract class ProductRepository {
  /// 상품을 생성합니다
  Future<String> createProduct(Product product);

  /// 상품을 수정합니다
  Future<void> updateProduct(Product product);

  /// 상품을 삭제합니다
  Future<void> deleteProduct(String productId);

  /// 상품 ID로 상품을 조회합니다
  Future<Product?> getProductById(String productId);

  /// 모든 상품 목록을 조회합니다
  Future<List<Product>> getAllProducts();

  /// 판매자 ID로 상품 목록을 조회합니다
  Future<List<Product>> getProductsBySeller(String sellerId);

  /// 카테고리별 상품 목록을 조회합니다
  Future<List<Product>> getProductsByCategory(String category);

  /// 위치 기반 상품 목록을 조회합니다
  Future<List<Product>> getProductsByLocation(
    double latitude,
    double longitude,
    double radiusInKm,
  );

  /// 상품 조회수를 증가시킵니다
  Future<void> incrementViewCount(String productId);

  /// 상품 좋아요 수를 증가시킵니다
  Future<void> incrementLikeCount(String productId);

  /// 상품 좋아요 수를 감소시킵니다
  Future<void> decrementLikeCount(String productId);

  /// 상품을 구매합니다 (구매자 ID 저장 및 상태 변경)
  Future<void> purchaseProduct(String productId, String buyerId);

  /// 구매자 ID로 구매한 상품 목록을 조회합니다
  Future<List<Product>> getProductsByBuyer(String buyerId);
}
