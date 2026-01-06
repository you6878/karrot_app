import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tosspayments_widget_sdk_flutter/model/payment_info.dart';
import 'package:tosspayments_widget_sdk_flutter/model/payment_widget_options.dart';
import 'package:tosspayments_widget_sdk_flutter/payment_widget.dart';
import 'package:tosspayments_widget_sdk_flutter/widgets/agreement.dart';
import 'package:tosspayments_widget_sdk_flutter/widgets/payment_method.dart';
import 'package:karrot_clone/data/models/membership_model.dart';
import 'package:karrot_clone/services/payment/membership_service.dart';

class MembershipPage extends StatefulWidget {
  const MembershipPage({super.key});

  @override
  State<MembershipPage> createState() => _MembershipPageState();
}

class _MembershipPageState extends State<MembershipPage> {
  final MembershipService _membershipService = MembershipService();
  MembershipModel? _currentMembership;
  bool _isLoading = true;
  int _selectedPlanIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadMembershipStatus();
  }

  Future<void> _loadMembershipStatus() async {
    try {
      final membership = await _membershipService.getCurrentMembership();
      if (mounted) {
        setState(() {
          _currentMembership = membership;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('멤버십 상태 로드 실패: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF333333)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '당근 멤버십',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF333333),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFFF700F),
              ),
            )
          : _currentMembership != null && _currentMembership!.isActive
              ? _buildActiveMembershipView()
              : _buildMembershipPlansView(),
    );
  }

  /// 활성 멤버십이 있을 때 보여주는 뷰
  Widget _buildActiveMembershipView() {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 20),
          // 멤버십 상태 카드
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFF700F), Color(0xFFFF9F5A)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF700F).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: const Center(
                        child: Text(
                          '🥕',
                          style: TextStyle(fontSize: 24),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '당근 프리미엄',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '멤버십 이용 중',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _currentMembership!.planTypeDisplayName,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFFF700F),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '다음 결제일',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                      Text(
                        _formatDate(_currentMembership!.endDate),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '남은 기간',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                      Text(
                        '${_currentMembership!.remainingDays}일',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          // 멤버십 혜택
          _buildBenefitsSection(),
        ],
      ),
    );
  }

  /// 멤버십 플랜 선택 뷰
  Widget _buildMembershipPlansView() {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 20),
          // 헤더
          _buildHeader(),
          const SizedBox(height: 32),
          // 플랜 선택
          _buildPlanSelector(),
          const SizedBox(height: 32),
          // 혜택 섹션
          _buildBenefitsSection(),
          const SizedBox(height: 32),
          // 결제 버튼
          _buildPaymentButton(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFF700F), Color(0xFFFF9F5A)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Text(
            '🥕',
            style: TextStyle(fontSize: 48),
          ),
          const SizedBox(height: 16),
          const Text(
            '당근 프리미엄',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '더 편리한 거래를 위한\n프리미엄 혜택을 만나보세요',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '멤버십 플랜 선택',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 16),
          ...MembershipService.plans.asMap().entries.map((entry) {
            final index = entry.key;
            final plan = entry.value;
            final isSelected = _selectedPlanIndex == index;
            final isYearly = plan.type == MembershipPlanType.yearly;

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedPlanIndex = index;
                });
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFFFF700F)
                        : const Color(0xFFE6E6E6),
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFFFF700F).withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFFFF700F)
                              : const Color(0xFFCCCCCC),
                          width: 2,
                        ),
                        color: isSelected
                            ? const Color(0xFFFF700F)
                            : Colors.transparent,
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check,
                              size: 16,
                              color: Colors.white,
                            )
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                plan.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF333333),
                                ),
                              ),
                              if (isYearly) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFF700F),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Text(
                                    '추천',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            plan.description,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF808080),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${_formatPrice(plan.price)}원',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFFF700F),
                          ),
                        ),
                        if (isYearly)
                          const Text(
                            '월 4,083원',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF808080),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildBenefitsSection() {
    final benefits = [
      {'icon': '🔄', 'title': '끌올 무제한', 'desc': '게시물을 상단으로 올려 더 많은 관심을 받으세요'},
      {'icon': '⭐', 'title': '프리미엄 배지', 'desc': '신뢰할 수 있는 판매자임을 보여주세요'},
      {'icon': '🚫', 'title': '광고 없는 화면', 'desc': '깔끔하게 당근을 이용하세요'},
      {'icon': '📈', 'title': '우선 노출', 'desc': '검색 결과에서 더 잘 보이세요'},
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '멤버십 혜택',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 20),
          ...benefits.map((benefit) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF4ED),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          benefit['icon']!,
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            benefit['title']!,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF333333),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            benefit['desc']!,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF808080),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildPaymentButton() {
    final selectedPlan = MembershipService.plans[_selectedPlanIndex];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '결제 금액',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF333333),
                  ),
                ),
                Text(
                  '${_formatPrice(selectedPlan.price)}원',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFFF700F),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () => _startPayment(selectedPlan),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF700F),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                '멤버십 가입하기',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '결제 시 이용약관 및 개인정보처리방침에 동의합니다',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  /// 토스페이먼츠 결제 시작
  Future<void> _startPayment(MembershipPlan plan) async {
    final user = firebase_auth.FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showErrorSnackBar('로그인이 필요합니다');
      return;
    }

    // 사용자 정보 가져오기
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    final userData = userDoc.data();
    final customerName = userData?['nickname'] ?? '사용자';
    final customerEmail = user.email ?? '';

    final orderId = _membershipService.generateOrderId();
    final orderName = '당근마켓 ${plan.name}';

    // 토스페이먼츠 결제 위젯 페이지로 이동
    if (!mounted) return;

    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => TossPaymentPage(
          // 토스페이먼츠 공식 테스트 클라이언트 키
          clientKey: 'test_gck_docs_Ovk5rk1EwkEbP0W43n07xlzm',
          orderId: orderId,
          orderName: orderName,
          amount: plan.price,
          customerName: customerName,
          customerEmail: customerEmail,
          planType: plan.type,
        ),
      ),
    );

    if (result != null && result['success'] == true) {
      // 결제 성공 처리
      await _handlePaymentSuccess(result, plan);
    }
  }

  /// 결제 성공 처리
  Future<void> _handlePaymentSuccess(
    Map<String, dynamic> paymentResult,
    MembershipPlan plan,
  ) async {
    // 로딩 표시
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFFF700F),
        ),
      ),
    );

    try {
      // 1. 서버에서 결제 승인
      await _membershipService.confirmPayment(
        paymentKey: paymentResult['paymentKey'],
        orderId: paymentResult['orderId'],
        amount: plan.price,
      );

      // 2. 멤버십 생성
      await _membershipService.createMembership(
        paymentKey: paymentResult['paymentKey'],
        orderId: paymentResult['orderId'],
        amount: plan.price,
        planType: plan.type,
      );

      // 로딩 닫기
      if (mounted) Navigator.pop(context);

      // 성공 메시지
      _showSuccessDialog();

      // 멤버십 상태 새로고침
      await _loadMembershipStatus();
    } catch (e) {
      // 로딩 닫기
      if (mounted) Navigator.pop(context);

      _showErrorSnackBar('결제 처리 중 오류가 발생했습니다: $e');
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: Color(0xFF4CAF50),
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              '멤버십 가입 완료!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '당근 프리미엄 혜택을\n지금 바로 이용해보세요',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF808080),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF700F),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                '확인',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }
}

/// 토스페이먼츠 결제 페이지
class TossPaymentPage extends StatefulWidget {
  final String clientKey;
  final String orderId;
  final String orderName;
  final int amount;
  final String customerName;
  final String customerEmail;
  final MembershipPlanType planType;

  const TossPaymentPage({
    super.key,
    required this.clientKey,
    required this.orderId,
    required this.orderName,
    required this.amount,
    required this.customerName,
    required this.customerEmail,
    required this.planType,
  });

  @override
  State<TossPaymentPage> createState() => _TossPaymentPageState();
}

class _TossPaymentPageState extends State<TossPaymentPage> {
  late PaymentWidget _paymentWidget;
  PaymentMethodWidgetControl? _paymentMethodWidgetControl;
  AgreementWidgetControl? _agreementWidgetControl;
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    _initPaymentWidget();
  }

  void _initPaymentWidget() {
    _paymentWidget = PaymentWidget(
      clientKey: widget.clientKey,
      customerKey: firebase_auth.FirebaseAuth.instance.currentUser?.uid ??
          'guest_${DateTime.now().millisecondsSinceEpoch}',
    );

    // 결제 수단 위젯 렌더링
    _paymentWidget
        .renderPaymentMethods(
      selector: 'methods',
      amount: Amount(
        value: widget.amount,
        currency: Currency.KRW,
        country: 'KR',
      ),
    )
        .then((control) {
      _paymentMethodWidgetControl = control;
      _checkReady();
    });

    // 약관 동의 위젯 렌더링
    _paymentWidget.renderAgreement(selector: 'agreement').then((control) {
      _agreementWidgetControl = control;
      _checkReady();
    });
  }

  void _checkReady() {
    if (_paymentMethodWidgetControl != null &&
        _agreementWidgetControl != null &&
        mounted) {
      setState(() {
        _isReady = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Color(0xFF333333)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '결제하기',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF333333),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 결제 정보
            Container(
              padding: const EdgeInsets.all(20),
              color: const Color(0xFFF5F5F5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.orderName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF333333),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '주문번호: ${widget.orderId}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF808080),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${_formatPrice(widget.amount)}원',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFFF700F),
                    ),
                  ),
                ],
              ),
            ),
            // 결제 위젯들
            Expanded(
              child: ListView(
                children: [
                  // 결제 수단 선택 위젯
                  PaymentMethodWidget(
                    paymentWidget: _paymentWidget,
                    selector: 'methods',
                  ),
                  // 약관 동의 위젯
                  AgreementWidget(
                    paymentWidget: _paymentWidget,
                    selector: 'agreement',
                  ),
                ],
              ),
            ),
            // 결제 버튼
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isReady ? _requestPayment : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF700F),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFFCCCCCC),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      _isReady
                          ? '${_formatPrice(widget.amount)}원 결제하기'
                          : '로딩 중...',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _requestPayment() async {
    try {
      final paymentInfo = PaymentInfo(
        orderId: widget.orderId,
        orderName: widget.orderName,
      );

      final result = await _paymentWidget.requestPayment(
        paymentInfo: paymentInfo,
      );

      if (result.success != null && mounted) {
        // 결제 성공
        Navigator.pop(context, {
          'success': true,
          'paymentKey': result.success!.paymentKey,
          'orderId': result.success!.orderId,
          'amount': result.success!.amount,
        });
      } else if (result.fail != null && mounted) {
        // 결제 실패
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.fail!.errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('결제 중 오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }
}
