import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:karrot_clone/data/models/product_model.dart';

abstract class ProductRemoteDataSource {
  Future<String> createProduct(ProductModel product);
  Future<void> updateProduct(ProductModel product);
  Future<void> deleteProduct(String productId);
  Future<ProductModel?> getProductById(String productId);
  Future<List<ProductModel>> getAllProducts();
  Stream<List<ProductModel>> getProductsStream();
  Future<List<ProductModel>> getProductsBySeller(String sellerId);
  Future<List<ProductModel>> getProductsByCategory(String category);
  Future<void> incrementViewCount(String productId);
  Future<void> incrementLikeCount(String productId);
  Future<void> decrementLikeCount(String productId);
}

class ProductRemoteDataSourceImpl implements ProductRemoteDataSource {
  final FirebaseFirestore firestore;
  static const String collectionName = 'products';

  ProductRemoteDataSourceImpl({required this.firestore});

  CollectionReference get _productsCollection =>
      firestore.collection(collectionName);

  @override
  Future<String> createProduct(ProductModel product) async {
    try {
      final docRef = await _productsCollection.add(product.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('상품 생성 실패: $e');
    }
  }

  @override
  Future<void> updateProduct(ProductModel product) async {
    try {
      await _productsCollection.doc(product.id).update(product.toFirestore());
    } catch (e) {
      throw Exception('상품 수정 실패: $e');
    }
  }

  @override
  Future<void> deleteProduct(String productId) async {
    try {
      await _productsCollection.doc(productId).delete();
    } catch (e) {
      throw Exception('상품 삭제 실패: $e');
    }
  }

  @override
  Future<ProductModel?> getProductById(String productId) async {
    try {
      final doc = await _productsCollection.doc(productId).get();
      if (!doc.exists) {
        return null;
      }
      return ProductModel.fromFirestore(doc);
    } catch (e) {
      throw Exception('상품 조회 실패: $e');
    }
  }

  @override
  Future<List<ProductModel>> getAllProducts() async {
    try {
      final querySnapshot = await _productsCollection
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => ProductModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('상품 목록 조회 실패: $e');
    }
  }

  @override
  Stream<List<ProductModel>> getProductsStream() {
    try {
      return _productsCollection.snapshots().map((querySnapshot) {
        print('🔥 Firestore에서 받은 문서 개수: ${querySnapshot.docs.length}');
        final products = querySnapshot.docs
            .map((doc) {
              print('📄 문서 ID: ${doc.id}');
              try {
                final product = ProductModel.fromFirestore(doc);
                print('   ✅ 파싱 성공: ${product.title}');
                return product;
              } catch (e) {
                print('   ❌ 파싱 실패: $e');
                return null;
              }
            })
            .whereType<ProductModel>()
            .toList();

        // createdAt 기준으로 정렬 (앱에서 처리)
        products.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        print('📦 최종 상품 개수: ${products.length}');
        return products;
      });
    } catch (e) {
      print('❌ 스트림 에러: $e');
      throw Exception('상품 스트림 조회 실패: $e');
    }
  }

  @override
  Future<List<ProductModel>> getProductsBySeller(String sellerId) async {
    try {
      final querySnapshot = await _productsCollection
          .where('sellerId', isEqualTo: sellerId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => ProductModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('판매자 상품 목록 조회 실패: $e');
    }
  }

  @override
  Future<List<ProductModel>> getProductsByCategory(String category) async {
    try {
      final querySnapshot = await _productsCollection
          .where('category', isEqualTo: category)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => ProductModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('카테고리별 상품 목록 조회 실패: $e');
    }
  }

  @override
  Future<void> incrementViewCount(String productId) async {
    try {
      await _productsCollection.doc(productId).update({
        'viewCount': FieldValue.increment(1),
      });
    } catch (e) {
      throw Exception('조회수 증가 실패: $e');
    }
  }

  @override
  Future<void> incrementLikeCount(String productId) async {
    try {
      await _productsCollection.doc(productId).update({
        'likeCount': FieldValue.increment(1),
      });
    } catch (e) {
      throw Exception('좋아요 증가 실패: $e');
    }
  }

  @override
  Future<void> decrementLikeCount(String productId) async {
    try {
      await _productsCollection.doc(productId).update({
        'likeCount': FieldValue.increment(-1),
      });
    } catch (e) {
      throw Exception('좋아요 감소 실패: $e');
    }
  }
}
