import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:karrot_clone/data/models/product_model.dart';
import 'package:karrot_clone/presentation/pages/product/product_detail_page.dart';

class PurchaseHistoryPage extends StatefulWidget {
  const PurchaseHistoryPage({super.key});

  @override
  State<PurchaseHistoryPage> createState() => _PurchaseHistoryPageState();
}

class _PurchaseHistoryPageState extends State<PurchaseHistoryPage> {
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _getCurrentUserId();
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
          '구매내역',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF333333),
          ),
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
          : _buildPurchaseList(),
    );
  }

  Widget _buildPurchaseList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('products')
          .where('buyerId', isEqualTo: _currentUserId)
          .orderBy('updatedAt', descending: true)
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
                  '🛍️',
                  style: TextStyle(fontSize: 48),
                ),
                const SizedBox(height: 16),
                const Text(
                  '구매한 상품이 없습니다',
                  style: TextStyle(
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
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailPage(product: product),
          ),
        );
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
        // 상태 배지 (구매완료)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Text(
            '구매완료',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2E7D32),
            ),
          ),
        ),
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
        // 위치 및 구매 시간
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
              _formatDateTime(product.updatedAt),
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
}





