import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../models/user.dart';
import '../../../services/profile_service.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  User? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final user = await ProfileService().getProfile();
      setState(() => _user = user);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    const storage = FlutterSecureStorage();
    await storage.deleteAll();
    if (mounted) {
      context.go('/auth/phone-login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        context.pop();
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Profile'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
          actions: [
            IconButton(
              onPressed: _loadProfile,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _user == null
              ? _buildErrorState()
              : RefreshIndicator(
                  onRefresh: _loadProfile,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildProfileHeader(),
                        const SizedBox(height: 32),
                        _buildMenuItems(),
                        const SizedBox(height: 32),
                        _buildLogoutButton(),
                      ],
                    ),
                  ),
                ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 100,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to load profile',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please try again',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadProfile,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          child: _user!.avatarUrl != null
              ? ClipOval(
                  child: Image.network(
                    _user!.avatarUrl!,
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.person,
                      size: 50,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                )
              : Icon(
                  Icons.person,
                  size: 50,
                  color: Theme.of(context).colorScheme.primary,
                ),
        ),
        const SizedBox(height: 16),
        Text(
          _user!.name,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          _user!.email,
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
        if (_user!.phone != null) ...[
          const SizedBox(height: 4),
          Text(
            _user!.phone!,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ],
    );
  }

  Widget _buildMenuItems() {
    return Column(
      children: [
        _buildMenuItem(
          icon: Icons.person,
          title: 'Edit Profile',
          subtitle: 'Update your personal information',
          onTap: () async {
            final result = await context.push<bool>('/profile/edit', extra: _user);
            if (result == true) {
              _loadProfile();
            }
          },
        ),
        _buildMenuItem(
          icon: Icons.location_on,
          title: 'My Addresses',
          subtitle: 'Manage your delivery addresses',
          onTap: () => context.push('/profile/addresses'),
        ),
        _buildMenuItem(
          icon: Icons.shopping_bag,
          title: 'My Orders',
          subtitle: 'View your order history',
          onTap: () => context.push('/orders'),
        ),
        _buildMenuItem(
          icon: Icons.notifications,
          title: 'Notifications',
          subtitle: 'Manage your notification preferences',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Notifications feature coming soon')),
            );
          },
        ),
        _buildMenuItem(
          icon: Icons.help,
          title: 'Help & Support',
          subtitle: 'Get help and contact support',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Help & Support feature coming soon')),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _logout,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
        ),
        child: const Text('Logout'),
      ),
    );
  }
}
