import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:karrot_clone/presentation/pages/product/product_upload_page.dart';
import 'package:karrot_clone/presentation/pages/product/product_detail_page.dart';
import 'package:karrot_clone/data/models/product_model.dart';
import 'package:karrot_clone/domain/entities/product.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 시간 차이 계산
  String _getTimeAgo(DateTime createdAt) {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inSeconds < 60) {
      return '방금 전';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}분 전';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}시간 전';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}일 전';
    } else {
      return '${difference.inDays ~/ 7}주 전';
    }
  }

  /// 가격 포맷팅
  String _formatPrice(int price) {
    return '${price.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        )}원';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Column(
          children: [
            // 상단 헤더
            _buildHeader(),

            // 상품 리스트 (Firestore StreamBuilder)
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('products')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  // 로딩 중
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFFF700F),
                      ),
                    );
                  }

                  // 에러 발생
                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            '⚠️',
                            style: TextStyle(fontSize: 48),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            '데이터를 불러오는데 실패했습니다',
                            style: TextStyle(
                              fontSize: 16,
                              color: Color(0xFF666666),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            snapshot.error.toString(),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF999999),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  // 데이터가 없음
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            '📦',
                            style: TextStyle(fontSize: 48),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            '등록된 상품이 없습니다',
                            style: TextStyle(
                              fontSize: 16,
                              color: Color(0xFF666666),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '첫 번째 상품을 등록해보세요!',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF999999),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // 데이터 표시
                  final docs = snapshot.data!.docs;
                  final products = docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return ProductModel.fromJson({
                      'id': doc.id,
                      ...data,
                    });
                  }).toList();

                  return RefreshIndicator(
                    color: const Color(0xFFFF700F),
                    onRefresh: () async {
                      setState(() {});
                      await Future.delayed(const Duration(milliseconds: 500));
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        return _buildProductCard(products[index]);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ProductUploadPage(),
            ),
          );

          // 상품 등록 후 자동으로 업데이트됨
          if (result != null && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('상품이 등록되었습니다'),
                backgroundColor: Color(0xFF4CAF50),
                duration: Duration(seconds: 2),
              ),
            );
          }
        },
        backgroundColor: const Color(0xFFFF700F),
        child: const Icon(
          Icons.add,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 100,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // 앱 로고
          const Text(
            '당근마켓',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFFFF700F),
            ),
          ),
          const Spacer(),

          // 검색바
          Container(
            width: 200,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(17),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: const Row(
              children: [
                Text(
                  '🔍',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(width: 8),
                Text(
                  '검색어를 입력하세요',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF999999),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // 알림 아이콘
          const Text(
            '🔔',
            style: TextStyle(fontSize: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE6E6E6),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailPage(product: product),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 상품 이미지
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: product.imageUrls.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: product.imageUrls.first,
                        width: 96,
                        height: 96,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          width: 96,
                          height: 96,
                          color: const Color(0xFFE6E6E6),
                          child: const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFFFF700F),
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          width: 96,
                          height: 96,
                          color: const Color(0xFFE6E6E6),
                          child: const Center(
                            child: Icon(
                              Icons.error_outline,
                              color: Color(0xFF999999),
                              size: 32,
                            ),
                          ),
                        ),
                      )
                    : Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE6E6E6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Text(
                            '📷',
                            style: TextStyle(fontSize: 32),
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 12),

              // 상품 정보
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 2),
                    // 상품명
                    Text(
                      product.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF333333),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // 위치 및 시간
                    Text(
                      '${product.location} · ${_getTimeAgo(product.createdAt)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF999999),
                      ),
                    ),
                    const SizedBox(height: 4),

                    // 가격
                    Text(
                      _formatPrice(product.price),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFFF700F),
                      ),
                    ),
                    const SizedBox(height: 4),

                    // 채팅 및 관심수
                    Row(
                      children: [
                        if (product.viewCount > 0) ...[
                          const Text(
                            '👁️',
                            style: TextStyle(fontSize: 12),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${product.viewCount}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF999999),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (product.likeCount > 0) ...[
                          const Text(
                            '❤️',
                            style: TextStyle(fontSize: 12),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${product.likeCount}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF999999),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
