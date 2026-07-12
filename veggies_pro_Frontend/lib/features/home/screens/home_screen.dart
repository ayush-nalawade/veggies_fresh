import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/dio_client.dart';
import '../../../models/product.dart';
import '../../../models/deal.dart';
import '../../../services/deals_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  List<Category> _categories = [];
  List<Deal> _deals = [];
  DateTime? _dealEndsAt;
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
      if (mounted) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(
            content: Text('Failed to load categories: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    // Load deals separately — failure here is non-fatal
    try {
      final dealsResult = await DealsService.fetchTodaysDeals();
      if (mounted) {
        setState(() {
          _deals = dealsResult.deals;
          _dealEndsAt = dealsResult.dealEndsAt;
        });
      }
    } catch (_) {
      // Silently ignore — no deals available
    }

    if (mounted) setState(() => _isLoading = false);
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
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Categories header row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Categories',
                                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF1A1A2E),
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'What are you looking for?',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[500],
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                              GestureDetector(
                                onTap: () {},
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF7B1FA2), Color(0xFFE91E63)],
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF7B1FA2).withOpacity(0.35),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: const Text(
                                    'See All',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),

                          // Horizontal scrolling circular category cards
                          SizedBox(
                            height: 130,
                            child: _categories.isEmpty
                                ? _buildCategoryShimmer()
                                : ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    physics: const BouncingScrollPhysics(),
                                    itemCount: _categories.length,
                                    separatorBuilder: (_, __) => const SizedBox(width: 16),
                                    itemBuilder: (context, index) {
                                      final category = _categories[index];
                                      return _buildCircularCategoryCard(category, index);
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),

                    // ── Today's Deals ──────────────────────────────────────
                    _buildTodaysDealsSection(),
                  ],
                ),
              ),
            ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // TODAY'S DEALS SECTION
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildTodaysDealsSection() {
    // Show shimmer while loading, hide section entirely if no deals after load
    final showShimmer = _isLoading;
    if (!showShimmer && _deals.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFFF8E1),
            const Color(0xFFFFF3E0).withValues(alpha: 0.4),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('🔥', style: TextStyle(fontSize: 20)),
                          const SizedBox(width: 6),
                          Text(
                            "Today's Deals",
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1A1A2E),
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Hurry up! Prices valid until midnight',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                // Countdown timer chip
                if (_dealEndsAt != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF6B6B).withValues(alpha: 0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.timer_outlined, color: Colors.white, size: 14),
                        const SizedBox(width: 4),
                        _CountdownTimer(endsAt: _dealEndsAt!),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Deal cards horizontal list
            SizedBox(
              height: 250,
              child: showShimmer
                  ? _buildDealsShimmer()
                  : ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: _deals.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 14),
                      itemBuilder: (context, index) => _buildDealCard(_deals[index]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDealCard(Deal deal) {
    return GestureDetector(
      onTap: () => context.push('/products/${deal.product.id}', extra: {
        'categoryName': '',
      }),
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              spreadRadius: 0,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image area with discount badge
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  child: deal.product.firstImage.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: deal.product.firstImage,
                          height: 130,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            height: 130,
                            color: Colors.grey[100],
                            child: const Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFFFF6B6B),
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            height: 130,
                            color: Colors.grey[100],
                            child: Icon(Icons.image_not_supported_outlined,
                                color: Colors.grey[400], size: 36),
                          ),
                        )
                      : Container(
                          height: 130,
                          color: Colors.grey[100],
                          child: Icon(Icons.eco, color: Colors.grey[400], size: 36),
                        ),
                ),
                // Discount badge
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF6B6B), Color(0xFFFF3D3D)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '-${deal.discountPercent}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Product info
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    deal.product.name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A2E),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  // Prices row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${deal.dealPrice.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '₹${deal.originalPrice.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500],
                          decoration: TextDecoration.lineThrough,
                          decorationColor: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Add button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => context.push('/products/${deal.product.id}', extra: {
                        'categoryName': '',
                      }),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'View Deal',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDealsShimmer() {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 4,
      separatorBuilder: (_, __) => const SizedBox(width: 14),
      itemBuilder: (context, index) => Container(
        width: 160,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  // Curated pastel gradient palette for category cards
  static const List<List<Color>> _categoryColors = [
    [Color(0xFFFF6B6B), Color(0xFFFF8E53)],   // Warm red-orange
    [Color(0xFF43C6AC), Color(0xFF191654)],   // Teal-navy
    [Color(0xFFA18CD1), Color(0xFFFBC2EB)],  // Lavender-pink
    [Color(0xFF56CCF2), Color(0xFF2F80ED)],  // Sky blue
    [Color(0xFFF7971E), Color(0xFFFFD200)],  // Amber-yellow
    [Color(0xFF6A11CB), Color(0xFF2575FC)],  // Purple-blue
    [Color(0xFF11998E), Color(0xFF38EF7D)],  // Green teal
    [Color(0xFFFC5C7D), Color(0xFF6A82FB)],  // Pink-purple
  ];

  Widget _buildCircularCategoryCard(Category category, int index) {
    final colors = _categoryColors[index % _categoryColors.length];
    return GestureDetector(
      onTap: () => context.push('/products/${category.id}', extra: {
        'categoryName': category.name,
      }),
      child: SizedBox(
        width: 84,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Outer glow ring
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: colors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: colors[0].withValues(alpha: 0.45),
                    blurRadius: 16,
                    spreadRadius: 2,
                    offset: const Offset(0, 6),
                  ),
                  BoxShadow(
                    color: colors[1].withValues(alpha: 0.2),
                    blurRadius: 8,
                    spreadRadius: 0,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                child: Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        colors[0].withValues(alpha: 0.15),
                        colors[1].withValues(alpha: 0.15),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: ClipOval(
                    child: category.iconUrl != null
                        ? CachedNetworkImage(
                            imageUrl: category.iconUrl!,
                            fit: BoxFit.cover,
                            width: 68,
                            height: 68,
                            placeholder: (context, url) => Center(
                              child: SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: colors[0],
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Icon(
                              Icons.category_rounded,
                              color: colors[0],
                              size: 28,
                            ),
                          )
                        : Icon(
                            Icons.category_rounded,
                            color: colors[0],
                            size: 28,
                          ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              category.name,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2D2D3A),
                letterSpacing: 0.1,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryShimmer() {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 5,
      separatorBuilder: (_, __) => const SizedBox(width: 16),
      itemBuilder: (context, index) {
        return SizedBox(
          width: 84,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey[200],
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: 60,
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ],
          ),
        );
      },
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

// ─────────────────────────────────────────────────────────────────────────────
// Countdown Timer Widget
// ─────────────────────────────────────────────────────────────────────────────
class _CountdownTimer extends StatefulWidget {
  final DateTime endsAt;
  const _CountdownTimer({required this.endsAt});

  @override
  State<_CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<_CountdownTimer> {
  late Duration _remaining;
  late final _ticker = Stream<int>.periodic(const Duration(seconds: 1), (i) => i);
  late final _subscription = _ticker.listen(_onTick);

  @override
  void initState() {
    super.initState();
    _remaining = _calcRemaining();
  }

  Duration _calcRemaining() {
    final diff = widget.endsAt.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  void _onTick(int _) {
    if (!mounted) return;
    setState(() => _remaining = _calcRemaining());
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  String _pad(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final h = _pad(_remaining.inHours);
    final m = _pad(_remaining.inMinutes.remainder(60));
    final s = _pad(_remaining.inSeconds.remainder(60));
    return Text(
      '$h:$m:$s',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 13,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.0,
        fontFeatures: [FontFeature.tabularFigures()],
      ),
    );
  }
}