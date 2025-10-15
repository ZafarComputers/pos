import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:provider/provider.dart';
import 'calculator_dialog.dart';
import 'todays_summary_dialog.dart';
import '../providers/providers.dart';
import '../services/services.dart';
import '../pages/profile/user_profile_page.dart';

class PosNavbar extends StatefulWidget {
  const PosNavbar({super.key});

  @override
  State<PosNavbar> createState() => _PosNavbarState();
}

class _PosNavbarState extends State<PosNavbar> {
  late Timer _timer;
  String _currentTime = '';
  Future<Uint8List?>? _imageFuture;
  String? _lastImageUrl;

  Future<Uint8List?> _loadImageBytes(String path) async {
    try {
      return await File('${Directory.current.path}/$path').readAsBytes();
    } catch (e) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        _updateTime();
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _updateTime() {
    final now = DateFormat('HH:mm:ss').format(DateTime.now());
    if (mounted && now != _currentTime) {
      setState(() {
        _currentTime = now;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      color: const Color(0xFF0D1845),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // Logo
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.business, size: 24, color: Colors.white),
          ),

          const SizedBox(width: 30),

          // Time Display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.teal,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                const Icon(Icons.access_time, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Text(
                  _currentTime,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          // Action Buttons
          _buildActionButton(
            icon: Icons.calculate,
            tooltip: 'Calculator',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const CalculatorDialog(),
              );
            },
          ),

          _buildActionButton(
            icon: Icons.fullscreen,
            tooltip: 'Maximize',
            onPressed: () {
              // TODO: Toggle fullscreen
            },
          ),

          _buildActionButton(
            icon: Icons.account_balance_wallet,
            tooltip: 'Cash Register',
            onPressed: () {
              // TODO: Open cash register modal
            },
          ),

          _buildActionButton(
            icon: Icons.bar_chart,
            tooltip: 'Today\'s Sale',
            onPressed: () {
              // TODO: Open today's sale modal
            },
          ),

          _buildActionButton(
            icon: Icons.summarize,
            tooltip: 'Today\'s Summary',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const TodaysSummaryDialog(),
              );
            },
          ),

          // Slim purple dashboard button
          Container(
            margin: const EdgeInsets.only(left: 8),
            child: Tooltip(
              message: 'Back to Dashboard',
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/dashboard',
                    (route) => false, // Remove all routes from stack
                  );
                },
                icon: const Icon(Icons.dashboard, size: 16),
                label: const Text(
                  'Dashboard',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 2,
                  shadowColor: Colors.purple.withOpacity(0.3),
                ),
              ),
            ),
          ),

          const SizedBox(width: 16),

          // User Profile
          PopupMenuButton<String>(
            onSelected: (value) async {
              switch (value) {
                case 'profile':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const UserProfilePage(),
                    ),
                  );
                  break;
                case 'logout':
                  // Call logout API and then logout locally
                  try {
                    await ApiService.logoutUser();
                    // Also clear provider state
                    final authProvider = Provider.of<AuthProvider>(
                      context,
                      listen: false,
                    );
                    await authProvider.logout();
                    if (mounted) {
                      Navigator.pushReplacementNamed(context, '/login');
                    }
                  } catch (e) {
                    // Even if API fails, show error and redirect
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Logout completed with warning: $e'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                      // Still clear provider state and redirect
                      final authProvider = Provider.of<AuthProvider>(
                        context,
                        listen: false,
                      );
                      await authProvider.logout();
                      Navigator.pushReplacementNamed(context, '/login');
                    }
                  }
                  break;
              }
            },
            offset: const Offset(20, 50),
            constraints: const BoxConstraints(minWidth: 200, maxWidth: 200),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Container(
                margin: const EdgeInsets.only(right: 16),
                child: Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    String? imageUrl;
                    String initial = 'A'; // Default

                    if (authProvider.user != null) {
                      if (authProvider.user!.firstName.isNotEmpty) {
                        initial = authProvider.user!.firstName[0].toUpperCase();
                      }
                      // Check for profile picture in userProfile first, then user imgPath
                      imageUrl =
                          authProvider.userProfile?.profilePicture ??
                          authProvider.user!.imgPath;
                    }

                    // Only create a new future if the image URL has changed
                    if (_lastImageUrl != imageUrl) {
                      _lastImageUrl = imageUrl;
                      _imageFuture =
                          imageUrl != null && !imageUrl.startsWith('http')
                          ? _loadImageBytes(imageUrl)
                          : Future.value(null);
                    }

                    return FutureBuilder<Uint8List?>(
                      future: _imageFuture,
                      builder: (context, snapshot) {
                        Uint8List? bytes = snapshot.data;
                        return CircleAvatar(
                          key: ValueKey(
                            '${imageUrl ?? 'default'}_${authProvider.imageVersion}',
                          ),
                          backgroundColor: const Color(0xFF0D1845),
                          backgroundImage: bytes != null
                              ? MemoryImage(bytes)
                              : null,
                          child: (imageUrl == null || imageUrl.isEmpty)
                              ? Text(
                                  initial,
                                  style: const TextStyle(color: Colors.white),
                                )
                              : null,
                        );
                      },
                    );
                  },
                ),
              ),
            ),
            itemBuilder: (BuildContext context) => [
              PopupMenuItem<String>(
                value: 'profile',
                height: 48,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D1845).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.person,
                          color: Color(0xFF0D1845),
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'User Profile',
                        style: TextStyle(
                          color: Color(0xFF343A40),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const PopupMenuDivider(height: 1),
              PopupMenuItem<String>(
                value: 'logout',
                height: 48,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.logout,
                          color: Colors.red,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Logout',
                        style: TextStyle(
                          color: Color(0xFF343A40),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      child: Tooltip(
        message: tooltip,
        child: IconButton(
          onPressed: onPressed,
          icon: Icon(icon, color: Colors.white, size: 20),
          style: IconButton.styleFrom(
            backgroundColor: Colors.white.withOpacity(0.1),
            padding: const EdgeInsets.all(8),
          ),
        ),
      ),
    );
  }
}
