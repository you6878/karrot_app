import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';
import 'package:karrot_clone/data/models/membership_model.dart';

class MembershipPlan {
  final String id;
  final String name;
  final String description;
  final int price;
  final MembershipPlanType type;
  final List<String> benefits;

  const MembershipPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.type,
    required this.benefits,
  });
}

class MembershipService {
  static final MembershipService _instance = MembershipService._internal();
  factory MembershipService() => _instance;
  MembershipService._internal();

  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: 'asia-northeast3',
  );
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 멤버십 플랜 목록
  static const List<MembershipPlan> plans = [
    MembershipPlan(
      id: 'monthly',
      name: '월간 멤버십',
      description: '매달 자동 갱신',
      price: 4900,
      type: MembershipPlanType.monthly,
      benefits: [
        '끌올 무제한',
        '프리미엄 배지 표시',
        '광고 없는 깔끔한 화면',
        '우선 노출 혜택',
      ],
    ),
    MembershipPlan(
      id: 'yearly',
      name: '연간 멤버십',
      description: '연간 결제 시 2개월 무료',
      price: 49000,
      type: MembershipPlanType.yearly,
      benefits: [
        '끌올 무제한',
        '프리미엄 배지 표시',
        '광고 없는 깔끔한 화면',
        '우선 노출 혜택',
        '연 2개월 무료 혜택',
      ],
    ),
  ];

  /// 토스페이먼츠 결제 승인
  Future<Map<String, dynamic>> confirmPayment({
    required String paymentKey,
    required String orderId,
    required int amount,
  }) async {
    try {
      final callable = _functions.httpsCallable('confirmPayment');
      final result = await callable.call({
        'paymentKey': paymentKey,
        'orderId': orderId,
        'amount': amount,
      });

      return Map<String, dynamic>.from(result.data);
    } on FirebaseFunctionsException catch (e) {
      debugPrint('결제 승인 실패: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  /// 멤버십 생성
  Future<Map<String, dynamic>> createMembership({
    required String paymentKey,
    required String orderId,
    required int amount,
    required MembershipPlanType planType,
  }) async {
    try {
      final callable = _functions.httpsCallable('createMembership');
      final result = await callable.call({
        'paymentKey': paymentKey,
        'orderId': orderId,
        'amount': amount,
        'planType': planType.name,
      });

      return Map<String, dynamic>.from(result.data);
    } on FirebaseFunctionsException catch (e) {
      debugPrint('멤버십 생성 실패: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  /// 멤버십 상태 확인
  Future<Map<String, dynamic>> checkMembershipStatus() async {
    try {
      final callable = _functions.httpsCallable('checkMembershipStatus');
      final result = await callable.call();

      return Map<String, dynamic>.from(result.data);
    } on FirebaseFunctionsException catch (e) {
      debugPrint('멤버십 상태 확인 실패: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  /// 현재 사용자의 활성 멤버십 조회
  Future<MembershipModel?> getCurrentMembership() async {
    try {
      final user = firebase_auth.FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      final snapshot = await _firestore
          .collection('memberships')
          .where('userId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'active')
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      final doc = snapshot.docs.first;
      return MembershipModel.fromJson({
        'id': doc.id,
        ...doc.data(),
      });
    } catch (e) {
      debugPrint('멤버십 조회 실패: $e');
      return null;
    }
  }

  /// 사용자가 멤버인지 확인
  Future<bool> isMember() async {
    try {
      final user = firebase_auth.FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      final doc = await _firestore.collection('users').doc(user.uid).get();

      if (!doc.exists) return false;

      final data = doc.data();
      final isMember = data?['isMember'] as bool? ?? false;
      final membershipEndDate = data?['membershipEndDate'] as Timestamp?;

      if (!isMember || membershipEndDate == null) return false;

      // 만료 여부 확인
      return membershipEndDate.toDate().isAfter(DateTime.now());
    } catch (e) {
      debugPrint('멤버십 확인 실패: $e');
      return false;
    }
  }

  /// 결제 취소
  Future<Map<String, dynamic>> cancelPayment({
    required String paymentKey,
    required String cancelReason,
  }) async {
    try {
      final callable = _functions.httpsCallable('cancelPayment');
      final result = await callable.call({
        'paymentKey': paymentKey,
        'cancelReason': cancelReason,
      });

      return Map<String, dynamic>.from(result.data);
    } on FirebaseFunctionsException catch (e) {
      debugPrint('결제 취소 실패: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  /// 주문 ID 생성
  String generateOrderId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final user = firebase_auth.FirebaseAuth.instance.currentUser;
    final userId = user?.uid.substring(0, 8) ?? 'guest';
    return 'KARROT_${userId}_$timestamp';
  }
}


