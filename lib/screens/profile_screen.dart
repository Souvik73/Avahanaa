import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';
import 'auth/login_screen.dart';
import '../utils/qr_payload_builder.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService();
  final _firestoreService = FirestoreService();
  final _currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: StreamBuilder<UserModel?>(
        stream: _firestoreService.streamUserData(_currentUser!.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final user = snapshot.data;
          if (user == null) {
            return const Center(child: Text('User data not found'));
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                // Profile Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF2563EB), Color(0xFF10B981)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    children: [
                      // Avatar
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            user.email[0].toUpperCase(),
                            style: const TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      Text(
                        user.email,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      if (user.phoneNumber.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          user.phoneNumber,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Car Details Section
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Card(
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.directions_car,
                              color: Color(0xFF2563EB)),
                          title: const Text(
                            'Car Details',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(user.carDescription),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _showEditCarDialog(user),
                        ),
                      ],
                    ),
                  ),
                ),

                // Account Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Card(
                    child: Column(
                      children: [
                        ListTile(
                          leading:
                              const Icon(Icons.phone, color: Color(0xFF2563EB)),
                          title: const Text('Phone Number'),
                          subtitle: Text(
                            user.phoneNumber.isEmpty
                                ? 'Not set'
                                : user.phoneNumber,
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _showEditPhoneDialog(user),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading:
                              const Icon(Icons.lock, color: Color(0xFF2563EB)),
                          title: const Text('Change Password'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: _showChangePasswordDialog,
                        ),
                      ],
                    ),
                  ),
                ),

                // QR Code Section
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Card(
                    child: Column(
                      children: [
                        SwitchListTile(
                          secondary: const Icon(Icons.qr_code,
                              color: Color(0xFF2563EB)),
                          title: const Text('QR Code Active'),
                          subtitle: const Text('Allow others to notify you'),
                          value: true, // TODO: Implement toggle
                          onChanged: (value) {
                            // TODO: Implement QR code toggle
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('QR code status updated'),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                // Statistics
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: FutureBuilder<Map<String, int>>(
                    future: _firestoreService
                        .getNotificationStats(_currentUser.uid),
                    builder: (context, snapshot) {
                      final stats = snapshot.data ?? {'today': 0, 'total': 0};

                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatItem(
                                'Today',
                                stats['today'].toString(),
                                Icons.today,
                              ),
                              Container(
                                width: 1,
                                height: 40,
                                color: Colors.grey[300],
                              ),
                              _buildStatItem(
                                'Total',
                                stats['total'].toString(),
                                Icons.notifications,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // Danger Zone
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Card(
                    color: Colors.red[50],
                    child: ListTile(
                      leading:
                          Icon(Icons.delete_forever, color: Colors.red[700]),
                      title: Text(
                        'Delete Account',
                        style: TextStyle(
                          color: Colors.red[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: const Text('Permanently delete your account'),
                      trailing:
                          const Icon(Icons.chevron_right, color: Colors.red),
                      onTap: _showDeleteAccountDialog,
                    ),
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF2563EB), size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2563EB),
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

  void _showEditCarDialog(UserModel user) {
    final colorController = TextEditingController(
      text: user.carDetails?['color'] ?? '',
    );
    final modelController = TextEditingController(
      text: user.carDetails?['carModel'] ?? '',
    );
    final plateController = TextEditingController(
      text: user.carDetails?['licensePlate'] ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Car Details'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: colorController,
                decoration: const InputDecoration(
                  labelText: 'Color',
                  hintText: 'e.g., Red, Blue',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: modelController,
                decoration: const InputDecoration(
                  labelText: 'Model',
                  hintText: 'e.g., Toyota Camry',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: plateController,
                decoration: const InputDecoration(
                  labelText: 'License Plate',
                  hintText: 'e.g., ABC-1234',
                ),
                textCapitalization: TextCapitalization.characters,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                final updatedCarDetails = {
                  'color': colorController.text.trim(),
                  'carModel': modelController.text.trim(),
                  'licensePlate': plateController.text.trim().toUpperCase(),
                };

                await _firestoreService.updateUserProfile(
                  userId: _currentUser!.uid,
                  carDetails: updatedCarDetails,
                );

                if (user.qrCodeId.isNotEmpty) {
                  final updatedUser =
                      user.copyWith(carDetails: updatedCarDetails);
                  await _firestoreService.syncQRCodeMetadata(
                    qrCodeId: user.qrCodeId,
                    metadata: QrPayloadBuilder.buildMetadata(updatedUser),
                    shareableLink:
                        QrPayloadBuilder.buildShareableLink(updatedUser),
                    payload: QrPayloadBuilder.buildPayload(updatedUser),
                  );
                }

                if (!mounted) return;
                Navigator.pop(context);
                Future.delayed(const Duration(seconds: 0), () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Car details updated')),
                  );
                });
              } catch (e) {
                if (!mounted) return;
                Future.delayed(const Duration(seconds: 0), () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                });
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showEditPhoneDialog(UserModel user) {
    final phoneController = TextEditingController(text: user.phoneNumber);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Phone Number'),
        content: TextField(
          controller: phoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Phone Number',
            hintText: '+1234567890',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await _firestoreService.updateUserProfile(
                  userId: _currentUser!.uid,
                  phoneNumber: phoneController.text.trim(),
                );

                if (!mounted) return;
                Navigator.pop(context);
                Future.delayed(const Duration(seconds: 0), () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Phone number updated')),
                  );
                });
              } catch (e) {
                if (!mounted) return;
                Future.delayed(const Duration(seconds: 0), () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                });
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Current Password',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'New Password',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm Password',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (newPasswordController.text !=
                  confirmPasswordController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Passwords do not match')),
                );
                return;
              }

              try {
                // Re-authenticate first
                final credential = EmailAuthProvider.credential(
                  email: _currentUser!.email!,
                  password: currentPasswordController.text,
                );
                await _currentUser.reauthenticateWithCredential(credential);

                // Update password
                await _authService.updatePassword(
                  newPassword: newPasswordController.text,
                );

                if (!mounted) return;
                Navigator.pop(context);
                Future.delayed(const Duration(seconds: 0), () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Password updated successfully')),
                  );
                });
              } catch (e) {
                if (!mounted) return;
                Future.delayed(const Duration(seconds: 0), () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                });
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone. All your data including QR code and notifications will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              try {
                await _authService.deleteAccount();

                if (!mounted) return;
                Future.delayed(const Duration(seconds: 0), () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                });
              } catch (e) {
                if (!mounted) return;
                Future.delayed(const Duration(seconds: 0), () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                });
              }
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _authService.signOut();

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }
}
