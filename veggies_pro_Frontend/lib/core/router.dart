import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../features/auth/screens/splash_screen.dart';
import '../features/auth/screens/phone_login_screen.dart';
import '../features/auth/screens/otp_verification_screen.dart';
import '../features/auth/screens/user_details_screen.dart';
import '../features/home/screens/home_screen.dart';
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
      
      print('Router redirect - Path: ${state.uri.path}, Token: ${token != null ? "exists" : "null"}, isAuthRoute: $isAuthRoute');
      
      if (token == null && !isAuthRoute && state.uri.path != '/splash') {
        print('Redirecting to phone login - no token');
        return '/auth/phone-login';
      }
      
      if (token != null && isAuthRoute) {
        print('Redirecting to home - token exists and on auth route');
        return '/home';
      }
      
      print('No redirect needed');
      return null;
    },
    routes: [
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
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
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
      GoRoute(
        path: '/checkout',
        builder: (context, state) => const CheckoutScreen(),
      ),
    ],
  );
});

class MainShell extends StatelessWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _getCurrentIndex(context),
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

  int _getCurrentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/cart')) return 1;
    if (location.startsWith('/orders')) return 2;
    if (location.startsWith('/profile')) return 3;
    return 0;
  }

  void _onTap(BuildContext context, int index) {
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