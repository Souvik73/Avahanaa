import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';
import 'qr_code_screen.dart';
import '../utils/qr_payload_builder.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _firestoreService = FirestoreService();
  final _currentUser = FirebaseAuth.instance.currentUser;
  int _selectedIndex = 0;
  String? _lastSyncedPayload;
  bool _isSyncingQrMetadata = false;

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      _buildHomeContent(),
      const NotificationsScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_outlined),
            activeIcon: Icon(Icons.notifications),
            label: 'Notifications',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildHomeContent() {
    return StreamBuilder<UserModel?>(
      stream: _firestoreService.streamUserData(_currentUser!.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        final user = snapshot.data;

        if (user == null) {
          return const Center(
            child: Text('User data not found'),
          );
        }

        // Check if QR code is generated
        if (user.qrCodeId.isEmpty) {
          return _buildWaitingForQRCode();
        }

        return _buildMainContent(user);
      },
    );
  }

  Widget _buildWaitingForQRCode() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            const Text(
              'Generating your QR code...',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This usually takes a few seconds',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent(UserModel user) {
    final qrPayload = QrPayloadBuilder.buildPayload(user);
    final metadata = QrPayloadBuilder.buildMetadata(user);

    if (user.qrCodeId.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _syncQrMetadata(user, qrPayload, metadata);
      });
    }

    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color.fromARGB(255, 10, 10, 10), Color(0xFF10B981)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Welcome back!',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // QR Code Card
            Padding(
              padding: const EdgeInsets.all(24),
              child: Card(
                elevation: 4,
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => QRCodeScreen(user: user),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const Text(
                          'Your Vehicle QR Code',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap to view full size',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // QR Code
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.grey[300]!,
                              width: 2,
                            ),
                          ),
                          child: QrImageView(
                            data: qrPayload,
                            version: QrVersions.auto,
                            size: 200,
                            backgroundColor: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),

                        const Icon(
                          Icons.touch_app,
                          color: Color(0xFF2563EB),
                          size: 24,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Quick Stats
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: StreamBuilder<int>(
                stream: _firestoreService
                    .streamUnreadNotificationCount(_currentUser!.uid),
                builder: (context, snapshot) {
                  final unreadCount = snapshot.data ?? 0;

                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem(
                            icon: Icons.notifications_active,
                            label: 'Unread',
                            value: unreadCount.toString(),
                            color: const Color(0xFF2563EB),
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: Colors.grey[300],
                          ),
                          _buildStatItem(
                            icon: Icons.qr_code,
                            label: 'QR Status',
                            value: 'Active',
                            color: const Color(0xFF10B981),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Instructions Card
            Padding(
              padding: const EdgeInsets.all(24),
              child: Card(
                color: const Color(0xFFF0F9FF),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Color(0xFF2563EB),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'How it works',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildInstructionStep('1', 'Print your QR code'),
                      _buildInstructionStep(
                          '2', 'Place it on your car windshield'),
                      _buildInstructionStep(
                          '3', 'Receive instant notifications'),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildInstructionStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              color: Color(0xFF2563EB),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF1F2937),
            ),
          ),
        ],
      ),
    );
  }

  void _syncQrMetadata(
    UserModel user,
    String payload,
    Map<String, dynamic> metadata,
  ) {
    if (user.qrCodeId.isEmpty ||
        _isSyncingQrMetadata ||
        _lastSyncedPayload == payload) {
      return;
    }

    _isSyncingQrMetadata = true;
    final shareableLink = QrPayloadBuilder.buildShareableLink(user);

    _firestoreService
        .syncQRCodeMetadata(
      qrCodeId: user.qrCodeId,
      metadata: metadata,
      shareableLink: shareableLink,
      payload: payload,
    )
        .then((_) {
      _lastSyncedPayload = payload;
    }).catchError((e) {
      debugPrint('Error syncing QR metadata: $e');
    }).whenComplete(() {
      _isSyncingQrMetadata = false;
    });
  }
}
