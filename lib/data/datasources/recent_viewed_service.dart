import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../models/recent_viewed_product_model.dart';
import '../models/product_model.dart';

class RecentViewedService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;

  /// 최근 본 상품 저장
  Future<void> saveRecentViewedProduct(ProductModel product) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      final userId = currentUser.uid;
      final docId = '${userId}_${product.id}';

      final recentViewed = RecentViewedProductModel(
        id: docId,
        userId: userId,
        productId: product.id,
        productTitle: product.title,
        productPrice: product.price,
        productImageUrl:
            product.imageUrls.isNotEmpty ? product.imageUrls.first : '',
        productLocation: product.location,
        productStatus: _getStatusString(product.status),
        viewedAt: DateTime.now(),
      );

      await _firestore
          .collection('recent_viewed')
          .doc(docId)
          .set(recentViewed.toFirestore());

      // 사용자당 최대 50개만 유지
      await _limitRecentViewedProducts(userId);
    } catch (e) {
      // 에러가 발생해도 앱 동작에 영향을 주지 않도록 조용히 처리
      print('최근 본 상품 저장 실패: $e');
    }
  }

  /// 사용자당 최대 50개만 유지 (오래된 것부터 삭제)
  Future<void> _limitRecentViewedProducts(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('recent_viewed')
          .where('userId', isEqualTo: userId)
          .orderBy('viewedAt', descending: true)
          .get();

      if (snapshot.docs.length > 50) {
        // 50개를 초과하는 문서들을 삭제
        final docsToDelete = snapshot.docs.skip(50).toList();
        final batch = _firestore.batch();

        for (final doc in docsToDelete) {
          batch.delete(doc.reference);
        }

        await batch.commit();
      }
    } catch (e) {
      print('최근 본 상품 제한 실패: $e');
    }
  }

  /// 최근 본 상품 목록 가져오기 (Stream)
  Stream<List<RecentViewedProductModel>> getRecentViewedProducts() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('recent_viewed')
        .where('userId', isEqualTo: currentUser.uid)
        .orderBy('viewedAt', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => RecentViewedProductModel.fromFirestore(doc))
              .toList(),
        );
  }

  /// 최근 본 상품 전체 삭제
  Future<void> clearRecentViewedProducts() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      final snapshot = await _firestore
          .collection('recent_viewed')
          .where('userId', isEqualTo: currentUser.uid)
          .get();

      final batch = _firestore.batch();

      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      print('최근 본 상품 삭제 실패: $e');
    }
  }

  /// 특정 최근 본 상품 삭제
  Future<void> deleteRecentViewedProduct(String productId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      final docId = '${currentUser.uid}_$productId';
      await _firestore.collection('recent_viewed').doc(docId).delete();
    } catch (e) {
      print('최근 본 상품 개별 삭제 실패: $e');
    }
  }

  /// ProductStatus를 String으로 변환
  String _getStatusString(dynamic status) {
    return status.toString().split('.').last;
  }
}






