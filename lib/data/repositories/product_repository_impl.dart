import 'package:karrot_clone/data/datasources/remote/product_remote_datasource.dart';
import 'package:karrot_clone/data/models/product_model.dart';
import 'package:karrot_clone/domain/entities/product.dart';
import 'package:karrot_clone/domain/repositories/product_repository.dart';

class ProductRepositoryImpl implements ProductRepository {
  final ProductRemoteDataSource remoteDataSource;

  ProductRepositoryImpl({required this.remoteDataSource});

  @override
  Future<String> createProduct(Product product) async {
    try {
      final productModel = ProductModel.fromEntity(product);
      return await remoteDataSource.createProduct(productModel);
    } catch (e) {
      throw Exception('상품 등록 실패: $e');
    }
  }

  @override
  Future<void> updateProduct(Product product) async {
    try {
      final productModel = ProductModel.fromEntity(product);
      await remoteDataSource.updateProduct(productModel);
    } catch (e) {
      throw Exception('상품 수정 실패: $e');
    }
  }

  @override
  Future<void> deleteProduct(String productId) async {
    try {
      await remoteDataSource.deleteProduct(productId);
    } catch (e) {
      throw Exception('상품 삭제 실패: $e');
    }
  }

  @override
  Future<Product?> getProductById(String productId) async {
    try {
      return await remoteDataSource.getProductById(productId);
    } catch (e) {
      throw Exception('상품 조회 실패: $e');
    }
  }

  @override
  Future<List<Product>> getAllProducts() async {
    try {
      return await remoteDataSource.getAllProducts();
    } catch (e) {
      throw Exception('상품 목록 조회 실패: $e');
    }
  }

  @override
  Stream<List<Product>> getProductsStream() {
    try {
      return remoteDataSource.getProductsStream();
    } catch (e) {
      throw Exception('상품 스트림 조회 실패: $e');
    }
  }

  @override
  Future<List<Product>> getProductsBySeller(String sellerId) async {
    try {
      return await remoteDataSource.getProductsBySeller(sellerId);
    } catch (e) {
      throw Exception('판매자 상품 목록 조회 실패: $e');
    }
  }

  @override
  Future<List<Product>> getProductsByCategory(String category) async {
    try {
      return await remoteDataSource.getProductsByCategory(category);
    } catch (e) {
      throw Exception('카테고리별 상품 목록 조회 실패: $e');
    }
  }

  @override
  Future<List<Product>> getProductsByLocation(
    double latitude,
    double longitude,
    double radiusInKm,
  ) async {
    // TODO: 위치 기반 쿼리 구현 (Firestore GeoPoint 또는 GeoFlutterFire 사용)
    throw UnimplementedError('위치 기반 검색은 아직 구현되지 않았습니다');
  }

  @override
  Future<void> incrementViewCount(String productId) async {
    try {
      await remoteDataSource.incrementViewCount(productId);
    } catch (e) {
      throw Exception('조회수 증가 실패: $e');
    }
  }

  @override
  Future<void> incrementLikeCount(String productId) async {
    try {
      await remoteDataSource.incrementLikeCount(productId);
    } catch (e) {
      throw Exception('좋아요 증가 실패: $e');
    }
  }

  @override
  Future<void> decrementLikeCount(String productId) async {
    try {
      await remoteDataSource.decrementLikeCount(productId);
    } catch (e) {
      throw Exception('좋아요 감소 실패: $e');
    }
  }
}
