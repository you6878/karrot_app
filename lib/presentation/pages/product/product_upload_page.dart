import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:karrot_clone/utils/helpers/location_helper.dart';
import 'package:karrot_clone/data/models/product_model.dart';
import 'package:karrot_clone/domain/entities/product.dart';
import 'package:karrot_clone/data/datasources/remote/product_remote_datasource.dart';
import 'package:karrot_clone/data/repositories/product_repository_impl.dart';

class ProductUploadPage extends StatefulWidget {
  const ProductUploadPage({super.key});

  @override
  State<ProductUploadPage> createState() => _ProductUploadPageState();
}

class _ProductUploadPageState extends State<ProductUploadPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  String? _selectedCategory;
  final List<XFile> _selectedImages = []; // 선택된 이미지 파일
  final List<String> _imageUrls = []; // 업로드된 이미지 URL
  bool _isLoadingLocation = false;
  bool _isSubmitting = false;
  bool _isUploadingImages = false;
  Position? _currentPosition;

  final ImagePicker _imagePicker = ImagePicker();
  late final ProductRepositoryImpl _productRepository;

  @override
  void initState() {
    super.initState();
    // Repository 초기화
    final remoteDataSource = ProductRemoteDataSourceImpl(
      firestore: FirebaseFirestore.instance,
    );
    _productRepository = ProductRepositoryImpl(
      remoteDataSource: remoteDataSource,
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  /// 현재 위치를 가져오는 메서드
  Future<void> _fetchCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      // 위치 서비스 활성화 확인
      bool serviceEnabled = await LocationHelper.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          _showErrorDialog(
            '위치 서비스 비활성화',
            '위치 서비스가 비활성화되어 있습니다. 기기 설정에서 위치 서비스를 활성화해주세요.',
          );
        }
        return;
      }

      // 위치 권한 요청
      bool hasPermission = await LocationHelper.requestLocationPermission();
      if (!hasPermission) {
        if (mounted) {
          _showPermissionDialog();
        }
        return;
      }

      // 현재 위치 가져오기
      Position? position = await LocationHelper.getCurrentPosition();
      if (position == null) {
        throw Exception('위치를 가져올 수 없습니다');
      }

      // 주소로 변환
      String address = await LocationHelper.getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );

      setState(() {
        _currentPosition = position;
        _locationController.text = address;
        _isLoadingLocation = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('위치를 가져왔습니다: $address'),
            backgroundColor: const Color(0xFF4CAF50),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoadingLocation = false;
      });

      if (mounted) {
        _showErrorDialog(
          '위치 가져오기 실패',
          e.toString().replaceAll('Exception: ', ''),
        );
      }
    }
  }

  /// 권한 요청 다이얼로그
  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('위치 권한 필요'),
        content: const Text(
          '거래 위치를 설정하려면 위치 권한이 필요합니다.\n설정에서 위치 권한을 허용해주세요.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await LocationHelper.requestLocationPermission();
            },
            child: const Text(
              '설정 열기',
              style: TextStyle(color: Color(0xFFFF6626)),
            ),
          ),
        ],
      ),
    );
  }

  /// 에러 다이얼로그
  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              '확인',
              style: TextStyle(color: Color(0xFFFF6626)),
            ),
          ),
        ],
      ),
    );
  }

  /// 이미지 선택 메서드
  Future<void> _pickImages() async {
    try {
      // 최대 10개까지만 선택 가능
      final remainingSlots = 10 - _selectedImages.length;
      if (remainingSlots <= 0) {
        _showErrorDialog('이미지 선택 제한', '최대 10개의 이미지만 선택할 수 있습니다.');
        return;
      }

      // 갤러리에서 여러 이미지 선택
      final List<XFile> images = await _imagePicker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (images.isNotEmpty) {
        setState(() {
          // 남은 슬롯만큼만 추가
          final imagesToAdd = images.take(remainingSlots).toList();
          _selectedImages.addAll(imagesToAdd);
        });

        if (images.length > remainingSlots) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('최대 10개까지만 선택됩니다. ${remainingSlots}개의 이미지가 추가되었습니다.'),
              backgroundColor: const Color(0xFFFF9800),
            ),
          );
        }
      }
    } catch (e) {
      _showErrorDialog('이미지 선택 실패', '이미지를 선택하는 중 오류가 발생했습니다.');
    }
  }

  /// 이미지 삭제 메서드
  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
      // 이미 업로드된 URL이 있다면 함께 제거
      if (index < _imageUrls.length) {
        _imageUrls.removeAt(index);
      }
    });
  }

  /// Firebase Storage에 이미지 업로드
  Future<List<String>> _uploadImages() async {
    if (_selectedImages.isEmpty) {
      return [];
    }

    setState(() {
      _isUploadingImages = true;
    });

    final List<String> uploadedUrls = [];
    final currentUser = firebase_auth.FirebaseAuth.instance.currentUser;

    try {
      for (int i = 0; i < _selectedImages.length; i++) {
        final XFile image = _selectedImages[i];
        final String fileName =
            '${currentUser!.uid}_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
        final Reference storageRef =
            FirebaseStorage.instance.ref().child('products/$fileName');

        // 파일 업로드
        final File file = File(image.path);
        final UploadTask uploadTask = storageRef.putFile(file);

        // 업로드 완료 대기
        final TaskSnapshot snapshot = await uploadTask;

        // 다운로드 URL 가져오기
        final String downloadUrl = await snapshot.ref.getDownloadURL();
        uploadedUrls.add(downloadUrl);
      }

      setState(() {
        _isUploadingImages = false;
      });

      return uploadedUrls;
    } catch (e) {
      setState(() {
        _isUploadingImages = false;
      });
      throw Exception('이미지 업로드 중 오류가 발생했습니다: ${e.toString()}');
    }
  }

  bool get _isFormValid {
    return _titleController.text.isNotEmpty &&
        _priceController.text.isNotEmpty &&
        _descriptionController.text.isNotEmpty &&
        _selectedCategory != null;
  }

  Future<void> _handleSubmit() async {
    if (!_isFormValid) {
      _showErrorDialog('입력 오류', '모든 필수 항목을 입력해주세요.');
      return;
    }

    // 로그인 확인
    final currentUser = firebase_auth.FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      _showErrorDialog('로그인 필요', '상품을 등록하려면 로그인이 필요합니다.');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // 이미지 업로드
      List<String> uploadedImageUrls = [];
      if (_selectedImages.isNotEmpty) {
        uploadedImageUrls = await _uploadImages();
      }

      // Product 엔티티 생성
      final now = DateTime.now();
      final product = ProductModel(
        id: '', // Firestore가 자동 생성
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        price: int.parse(_priceController.text.replaceAll(',', '')),
        imageUrls: uploadedImageUrls,
        category: _selectedCategory!,
        sellerId: currentUser.uid,
        location: _locationController.text.trim().isEmpty
            ? '위치 미설정'
            : _locationController.text.trim(),
        longitude: _currentPosition?.longitude,
        latitude: _currentPosition?.latitude,
        status: ProductStatus.available,
        viewCount: 0,
        likeCount: 0,
        createdAt: now,
        updatedAt: now,
        isNegotiable: true,
      );

      // Firestore에 상품 등록
      final productId = await _productRepository.createProduct(product);

      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });

        // 성공 메시지 표시
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('상품이 성공적으로 등록되었습니다!'),
            backgroundColor: Color(0xFF4CAF50),
            duration: Duration(seconds: 2),
          ),
        );

        // 이전 화면으로 돌아가기
        Navigator.pop(context, productId);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });

        _showErrorDialog(
          '등록 실패',
          '상품 등록 중 오류가 발생했습니다.\n${e.toString().replaceAll('Exception: ', '')}',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back,
            color: Color(0xFF333333),
            size: 24,
          ),
        ),
        title: const Text(
          '상품 등록',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isFormValid && !_isSubmitting ? _handleSubmit : null,
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFFFF6626),
                      ),
                    ),
                  )
                : Text(
                    '완료',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: _isFormValid
                          ? const Color(0xFF333333)
                          : const Color(0xFF999999),
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 이미지 업로드 섹션
            _buildImageUploadSection(),

            const SizedBox(height: 8),

            // 상품 정보 입력
            _buildProductInfoSection(),

            const SizedBox(height: 80),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomButton(),
    );
  }

  Widget _buildImageUploadSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '사진 (${_selectedImages.length}/10)',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 120,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                // 사진 추가 버튼
                InkWell(
                  onTap: _isUploadingImages ? null : _pickImages,
                  child: Container(
                    width: 120,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F2F2),
                      border: Border.all(
                        color: const Color(0xFFD9D9D9),
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: _isUploadingImages
                        ? const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFFFF6626),
                              ),
                            ),
                          )
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '📷',
                                style: TextStyle(fontSize: 24),
                              ),
                              SizedBox(height: 8),
                              Text(
                                '사진 추가',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF808080),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(width: 8),
                // 선택된 이미지 표시
                ..._selectedImages.asMap().entries.map((entry) {
                  final index = entry.key;
                  final image = entry.value;
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: Stack(
                      children: [
                        // 이미지 미리보기
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(image.path),
                            width: 120,
                            height: 120,
                            fit: BoxFit.cover,
                          ),
                        ),
                        // 삭제 버튼
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => _removeImage(index),
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                        // 첫 번째 이미지 표시
                        if (index == 0)
                          Positioned(
                            bottom: 4,
                            left: 4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF6626),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                '대표',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductInfoSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 제목 입력 필드
          _buildTextField(
            controller: _titleController,
            hintText: '상품 제목을 입력해주세요',
          ),

          const SizedBox(height: 20),

          // 카테고리 선택 필드
          InkWell(
            onTap: () {
              _showCategoryBottomSheet();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFFAFAFA),
                border: Border.all(
                  color: const Color(0xFFE6E6E6),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _selectedCategory ?? '카테고리 선택',
                    style: TextStyle(
                      fontSize: 16,
                      color: _selectedCategory != null
                          ? const Color(0xFF333333)
                          : const Color(0xFF999999),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    color: Color(0xFF999999),
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // 가격 입력 필드
          _buildTextField(
            controller: _priceController,
            hintText: '가격 입력',
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            suffix: const Text(
              '원',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF4D4D4D),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // 설명 입력 필드
          _buildTextField(
            controller: _descriptionController,
            hintText: '상품 설명을 입력해주세요',
            maxLines: 5,
            minLines: 5,
          ),

          const SizedBox(height: 20),

          // 거래 위치 입력 필드
          InkWell(
            onTap: _isLoadingLocation ? null : _fetchCurrentLocation,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFFAFAFA),
                border: Border.all(
                  color: const Color(0xFFE6E6E6),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: _isLoadingLocation
                        ? const Row(
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(0xFFFF6626),
                                  ),
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                '위치를 가져오는 중...',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF999999),
                                ),
                              ),
                            ],
                          )
                        : Text(
                            _locationController.text.isEmpty
                                ? '거래 위치 입력(탭하여 현재위치 가져오기)'
                                : _locationController.text,
                            style: TextStyle(
                              fontSize: 16,
                              color: _locationController.text.isEmpty
                                  ? const Color(0xFF999999)
                                  : const Color(0xFF333333),
                            ),
                          ),
                  ),
                  const SizedBox(width: 8),
                  const Text('📍', style: TextStyle(fontSize: 16)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    Widget? suffix,
    int? maxLines,
    int? minLines,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        border: Border.all(
          color: const Color(0xFFE6E6E6),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              inputFormatters: inputFormatters,
              maxLines: maxLines ?? 1,
              minLines: minLines ?? 1,
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF999999),
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF333333),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          if (suffix != null) suffix,
        ],
      ),
    );
  }

  Widget _buildBottomButton() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _isFormValid && !_isSubmitting ? _handleSubmit : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6626),
              disabledBackgroundColor: const Color(0xFFE6E6E6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.white,
                      ),
                    ),
                  )
                : const Text(
                    '등록하기',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  void _showCategoryBottomSheet() {
    final categories = [
      '디지털기기',
      '생활가전',
      '가구/인테리어',
      '유아동',
      '유아도서',
      '생활/가공식품',
      '스포츠/레저',
      '여성잡화',
      '여성의류',
      '남성패션/잡화',
      '게임/취미',
      '뷰티/미용',
      '반려동물용품',
      '도서/티켓/음반',
      '식물',
      '기타 중고물품',
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE6E6E6),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 8),
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  '카테고리 선택',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    final isSelected = _selectedCategory == category;

                    return ListTile(
                      title: Text(
                        category,
                        style: TextStyle(
                          fontSize: 16,
                          color: isSelected
                              ? const Color(0xFFFF6626)
                              : const Color(0xFF333333),
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(
                              Icons.check,
                              color: Color(0xFFFF6626),
                            )
                          : null,
                      onTap: () {
                        setState(() {
                          _selectedCategory = category;
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
