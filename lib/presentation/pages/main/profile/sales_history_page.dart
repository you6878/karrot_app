import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:karrot_clone/data/models/product_model.dart';
import 'package:karrot_clone/domain/entities/product.dart';

class SalesHistoryPage extends StatefulWidget {
  const SalesHistoryPage({super.key});

  @override
  State<SalesHistoryPage> createState() => _SalesHistoryPageState();
}

class _SalesHistoryPageState extends State<SalesHistoryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _getCurrentUserId();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _getCurrentUserId() {
    final user = firebase_auth.FirebaseAuth.instance.currentUser;
    if (mounted) {
      setState(() {
        _currentUserId = user?.uid;
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF333333)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '판매내역',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF333333),
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFFFF700F),
          unselectedLabelColor: const Color(0xFF808080),
          indicatorColor: const Color(0xFFFF700F),
          labelStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          tabs: const [
            Tab(text: '판매중'),
            Tab(text: '예약중'),
            Tab(text: '판매완료'),
          ],
        ),
      ),
      body: _currentUserId == null
          ? const Center(
              child: Text(
                '로그인이 필요합니다',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF808080),
                ),
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildProductList(ProductStatus.available),
                _buildProductList(ProductStatus.reserved),
                _buildProductList(ProductStatus.sold),
              ],
            ),
    );
  }

  Widget _buildProductList(ProductStatus status) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('products')
          .where('sellerId', isEqualTo: _currentUserId)
          .where('status', isEqualTo: _getStatusString(status))
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFFFF700F),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              '오류가 발생했습니다\n${snapshot.error}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF808080),
              ),
            ),
          );
        }

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
                Text(
                  _getEmptyMessage(status),
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF808080),
                  ),
                ),
              ],
            ),
          );
        }

        final products = snapshot.data!.docs
            .map((doc) => ProductModel.fromFirestore(doc))
            .toList();

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: products.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            return _buildProductCard(products[index]);
          },
        );
      },
    );
  }

  Widget _buildProductCard(ProductModel product) {
    return GestureDetector(
      onTap: () {
        // TODO: 상품 상세 페이지로 이동
        debugPrint('상품 클릭: ${product.title}');
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE6E6E6)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 상품 이미지
              _buildProductImage(product),
              const SizedBox(width: 16),
              // 상품 정보
              Expanded(
                child: _buildProductInfo(product),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductImage(ProductModel product) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 80,
        height: 80,
        color: const Color(0xFFF2F2F2),
        child: product.imageUrls.isNotEmpty
            ? Image.network(
                product.imageUrls.first,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Icon(
                      Icons.image_not_supported,
                      color: Color(0xFFB3B3B3),
                      size: 32,
                    ),
                  );
                },
              )
            : const Center(
                child: Icon(
                  Icons.image,
                  color: Color(0xFFB3B3B3),
                  size: 32,
                ),
              ),
      ),
    );
  }

  Widget _buildProductInfo(ProductModel product) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 상태 배지
        _buildStatusBadge(product.status),
        const SizedBox(height: 8),
        // 상품 제목
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
        // 상품 가격
        Text(
          _formatPrice(product.price),
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 4),
        // 위치 및 시간
        Row(
          children: [
            Text(
              product.location,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF808080),
              ),
            ),
            const Text(
              ' · ',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF808080),
              ),
            ),
            Text(
              _formatDateTime(product.createdAt),
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF808080),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        // 관심 수와 조회 수
        Row(
          children: [
            const Icon(
              Icons.favorite_border,
              size: 14,
              color: Color(0xFF808080),
            ),
            const SizedBox(width: 4),
            Text(
              '${product.likeCount}',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF808080),
              ),
            ),
            const SizedBox(width: 12),
            const Icon(
              Icons.visibility_outlined,
              size: 14,
              color: Color(0xFF808080),
            ),
            const SizedBox(width: 4),
            Text(
              '${product.viewCount}',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF808080),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusBadge(ProductStatus status) {
    Color bgColor;
    Color textColor;
    String text;

    switch (status) {
      case ProductStatus.available:
        bgColor = const Color(0xFFE8F5E9);
        textColor = const Color(0xFF2E7D32);
        text = '판매중';
        break;
      case ProductStatus.reserved:
        bgColor = const Color(0xFFFFF3E0);
        textColor = const Color(0xFFE65100);
        text = '예약중';
        break;
      case ProductStatus.sold:
        bgColor = const Color(0xFFEEEEEE);
        textColor = const Color(0xFF616161);
        text = '판매완료';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  String _formatPrice(int price) {
    return '${price.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match match) => '${match[1]},',
        )}원';
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return '방금 전';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}분 전';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}시간 전';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}일 전';
    } else {
      return '${dateTime.month}월 ${dateTime.day}일';
    }
  }

  String _getStatusString(ProductStatus status) {
    switch (status) {
      case ProductStatus.available:
        return 'available';
      case ProductStatus.reserved:
        return 'reserved';
      case ProductStatus.sold:
        return 'sold';
    }
  }

  String _getEmptyMessage(ProductStatus status) {
    switch (status) {
      case ProductStatus.available:
        return '판매중인 상품이 없습니다';
      case ProductStatus.reserved:
        return '예약중인 상품이 없습니다';
      case ProductStatus.sold:
        return '판매완료된 상품이 없습니다';
    }
  }
}
