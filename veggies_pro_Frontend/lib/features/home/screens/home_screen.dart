import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/dio_client.dart';
import '../../../models/product.dart';
import '../../../models/cart.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  List<Category> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // Load categories
      final categoriesResponse = await DioClient().dio.get('/categories');
      if (categoriesResponse.statusCode == 200) {
        setState(() {
          _categories = (categoriesResponse.data['data'] as List)
              .map((json) => Category.fromJson(json))
              .toList();
        });
      }
    } catch (e) {
      final messenger = ScaffoldMessenger.maybeOf(context);
      if (mounted && messenger != null) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Failed to load data: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () {
              // TODO: Implement notifications
            },
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Top section with search bar and festive background
                    Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFF4A148C), // Dark purple
                            Color(0xFF7B1FA2), // Medium purple
                            Color(0xFFE91E63), // Pink-red
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      child: Stack(
                        children: [
                          // Festive background elements
                          _buildFestiveBackground(),
                          // Content
                          SafeArea(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(20, 15, 20, 20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Welcome text
                                  const Text(
                                    'Fresh Vegetables',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  const Text(
                                    'Free delivery on orders above ₹200',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white70,
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  
                                  // Elegant search bar
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(25),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          spreadRadius: 0,
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: TextField(
                                      onTap: () => context.push('/search'),
                                      readOnly: true,
                                      decoration: InputDecoration(
                                        hintText: 'Search for vegetables, fruits...',
                                        hintStyle: TextStyle(
                                          color: Colors.grey[400],
                                          fontSize: 16,
                                        ),
                                        prefixIcon: Icon(
                                          Icons.search,
                                          color: Colors.grey[600],
                                          size: 24,
                                        ),
                                        suffixIcon: Icon(
                                          Icons.mic,
                                          color: Colors.grey[600],
                                          size: 24,
                                        ),
                                        border: InputBorder.none,
                                        contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Slider section
                    Container(
                      height: 180,
                      margin: const EdgeInsets.only(left: 16, right: 20, top: 16, bottom: 8),
                      child: PageView.builder(
                        itemCount: 3,
                        controller: PageController(viewportFraction: 0.92),
                        itemBuilder: (context, index) {
                          return _buildSliderCard(index);
                        },
                      ),
                    ),
                    
                    // Content section
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Categories section
                          Text(
                            'Categories',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          GridView.builder(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              childAspectRatio: 0.85,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                            ),
                            itemCount: _categories.length,
                            itemBuilder: (context, index) {
                              final category = _categories[index];
                              return GestureDetector(
                                onTap: () => context.push('/products/${category.id}', extra: {
                                      'categoryName': category.name,
                                    }),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.1),
                                        spreadRadius: 1,
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        height: 60,
                                        width: 60,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[50],
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: category.iconUrl != null
                                            ? CachedNetworkImage(
                                                imageUrl: category.iconUrl!,
                                                fit: BoxFit.cover,
                                                placeholder: (context, url) => const Center(
                                                  child: SizedBox(
                                                    width: 20,
                                                    height: 20,
                                                    child: CircularProgressIndicator(strokeWidth: 2),
                                                  ),
                                                ),
                                                errorWidget: (context, url, error) => Icon(
                                                  Icons.category,
                                                  color: Colors.grey[400],
                                                  size: 24,
                                                ),
                                              )
                                            : Icon(
                                                Icons.category,
                                                color: Colors.grey[400],
                                                size: 24,
                                              ),
                                      ),
                                      const SizedBox(height: 8),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 8),
                                        child: Text(
                                          category.name,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black87,
                                          ),
                                          textAlign: TextAlign.center,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
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

  Widget _buildFestiveBackground() {
    return Positioned.fill(
      child: Stack(
        children: [
          // Bokeh effect - circular lights
          ...List.generate(15, (index) {
            return Positioned(
              left: (index * 50.0) % MediaQuery.of(context).size.width,
              top: (index * 30.0) % 200.0 + 100,
              child: Container(
                width: 20 + (index % 3) * 10,
                height: 20 + (index % 3) * 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red.withOpacity(0.3 + (index % 3) * 0.1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.5),
                      blurRadius: 15 + (index % 3) * 5,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            );
          }),
          
          // Lantern in upper left
          Positioned(
            left: 20,
            top: 40,
            child: _buildLantern(),
          ),
          
          // Diya in upper right
          Positioned(
            right: 30,
            top: 50,
            child: _buildDiya(),
          ),
        ],
      ),
    );
  }

  Widget _buildLantern() {
    return Container(
      width: 60,
      height: 80,
      child: Stack(
        children: [
          // Main lantern body
          Positioned(
            top: 0,
            left: 10,
            child: Container(
              width: 40,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFFFF8A65), // Orange
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Top band
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE65100), // Darker orange
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                    ),
                  ),
                  // Diamond pattern
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFB74D), // Light orange
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  // Bottom band
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE65100), // Darker orange
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(8),
                        bottomRight: Radius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Hanging string
          Positioned(
            top: 0,
            left: 30,
            child: Container(
              width: 2,
              height: 20,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          // Decorative fringe
          Positioned(
            bottom: 0,
            left: 15,
            child: Column(
              children: List.generate(5, (index) {
                return Container(
                  width: 30 - index * 2,
                  height: 8,
                  margin: const EdgeInsets.only(bottom: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF8A65),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiya() {
    return Container(
      width: 50,
      height: 60,
      child: Stack(
        children: [
          // Diya base
          Positioned(
            bottom: 0,
            left: 5,
            child: Container(
              width: 40,
              height: 25,
              decoration: BoxDecoration(
                color: const Color(0xFF8D6E63), // Terracotta
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.brown.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Container(
                margin: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: const Color(0xFFA1887F), // Lighter terracotta
                  borderRadius: BorderRadius.circular(17),
                ),
              ),
            ),
          ),
          // Flame
          Positioned(
            top: 15,
            left: 20,
            child: Container(
              width: 8,
              height: 20,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFFFEB3B), // Bright yellow center
                    const Color(0xFFFF9800), // Orange edges
                  ],
                  radius: 0.8,
                ),
                borderRadius: BorderRadius.circular(4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.6),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderCard(int index) {
    final List<Map<String, dynamic>> sliderData = [
      {
        'title': 'Fresh Organic Vegetables',
        'subtitle': 'Get 20% off on your first order',
        'color': const Color(0xFF4CAF50),
        'icon': Icons.eco,
      },
      {
        'title': 'Free Delivery',
        'subtitle': 'On orders above ₹200',
        'color': const Color(0xFF2196F3),
        'icon': Icons.local_shipping,
      },
      {
        'title': 'Premium Quality',
        'subtitle': 'Farm fresh vegetables daily',
        'color': const Color(0xFFFF9800),
        'icon': Icons.star,
      },
    ];

    final data = sliderData[index];
    
    return Container(
      margin: const EdgeInsets.only(left: 4, right: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            data['color'] as Color,
            (data['color'] as Color).withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (data['color'] as Color).withOpacity(0.3),
            spreadRadius: 0,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    data['icon'] as IconData,
                    color: Colors.white,
                    size: 32,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    data['title'] as String,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    data['subtitle'] as String,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(40),
              ),
              child: Icon(
                data['icon'] as IconData,
                color: Colors.white,
                size: 40,
              ),
            ),
          ],
        ),
      ),
    );
  }
}