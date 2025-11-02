import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../features/auth/screens/splash_screen.dart';
import '../features/auth/screens/phone_login_screen.dart';
import '../features/auth/screens/otp_verification_screen.dart';
import '../features/auth/screens/user_details_screen.dart';
import '../features/home/screens/home_screen.dart';
import '../features/home/screens/search_screen.dart';
import '../features/catalog/screens/product_list_screen.dart';
import '../features/catalog/screens/product_detail_screen.dart';
import '../features/cart/screens/cart_screen.dart';
import '../features/checkout/screens/checkout_screen.dart';
import '../features/orders/screens/orders_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../features/profile/screens/edit_profile_screen.dart';
import '../features/profile/screens/address_list_screen.dart';
import '../features/profile/screens/add_edit_address_screen.dart';
import '../models/user.dart';
import '../models/address.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) async {
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'access_token');
      final isAuthRoute = state.uri.path.startsWith('/auth');
      final isSplashRoute = state.uri.path == '/splash';
      
      print('Router redirect - Path: ${state.uri.path}, Token: ${token != null ? "exists" : "null"}, isAuthRoute: $isAuthRoute');
      
      // If no token and not on auth/splash routes, redirect to login
      if (token == null && !isAuthRoute && !isSplashRoute) {
        print('Redirecting to phone login - no token');
        return '/auth/phone-login';
      }
      
      // If token exists and on auth routes, redirect to home
      if (token != null && isAuthRoute) {
        print('Redirecting to home - token exists and on auth route');
        return '/home';
      }
      
      print('No redirect needed');
      return null;
    },
    routes: [
      // Auth routes (no bottom navigation)
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/auth/phone-login',
        builder: (context, state) => const PhoneLoginScreen(),
      ),
      GoRoute(
        path: '/auth/otp-verification',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return OTPVerificationScreen(
            phone: extra['phone'] as String,
          );
        },
      ),
      GoRoute(
        path: '/auth/user-details',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return UserDetailsScreen(
            tempToken: extra['tempToken'] as String,
          );
        },
      ),
      // Checkout route (no bottom navigation)
      GoRoute(
        path: '/checkout',
        builder: (context, state) => const CheckoutScreen(),
      ),
      // Main app routes (with bottom navigation)
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/search',
            builder: (context, state) => const SearchScreen(),
          ),
          GoRoute(
            path: '/products/:categoryId',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              return ProductListScreen(
                categoryId: state.pathParameters['categoryId']!,
                categoryName: extra != null ? extra['categoryName'] as String? : null,
              );
            },
          ),
          GoRoute(
            path: '/product/:productId',
            builder: (context, state) => ProductDetailScreen(
              productId: state.pathParameters['productId']!,
            ),
          ),
          GoRoute(
            path: '/cart',
            builder: (context, state) => const CartScreen(),
          ),
          GoRoute(
            path: '/orders',
            builder: (context, state) => const OrdersScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/profile/edit',
            builder: (context, state) => EditProfileScreen(
              user: state.extra as User,
            ),
          ),
          GoRoute(
            path: '/profile/addresses',
            builder: (context, state) => const AddressListScreen(),
          ),
          GoRoute(
            path: '/profile/addresses/add',
            builder: (context, state) => const AddEditAddressScreen(),
          ),
          GoRoute(
            path: '/profile/addresses/edit',
            builder: (context, state) => AddEditAddressScreen(
              address: state.extra as Address,
            ),
          ),
        ],
      ),
    ],
  );
});

class MainShell extends StatefulWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateSelectedIndex();
  }

  void _updateSelectedIndex() {
    final location = GoRouterState.of(context).uri.path;
    setState(() {
      if (location.startsWith('/home')) {
        _selectedIndex = 0;
      } else if (location.startsWith('/cart')) {
        _selectedIndex = 1;
      } else if (location.startsWith('/orders')) {
        _selectedIndex = 2;
      } else if (location.startsWith('/profile')) {
        _selectedIndex = 3;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) => _onTap(context, index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Cart',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  void _onTap(BuildContext context, int index) {
    setState(() {
      _selectedIndex = index;
    });
    
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/cart');
        break;
      case 2:
        context.go('/orders');
        break;
      case 3:
        context.go('/profile');
        break;
    }
  }
}