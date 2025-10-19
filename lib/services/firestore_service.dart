import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/notification_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get user data
  Future<UserModel?> getUserData(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      log('Error getting user data: $e');
      return null;
    }
  }

  // Stream user data
  Stream<UserModel?> streamUserData(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((doc) => doc.exists ? UserModel.fromFirestore(doc) : null);
  }

  // Update user profile
  Future<void> updateUserProfile({
    required String userId,
    String? phoneNumber,
    Map<String, dynamic>? carDetails,
  }) async {
    try {
      Map<String, dynamic> updates = {};

      if (phoneNumber != null) {
        updates['phoneNumber'] = phoneNumber;
      }

      if (carDetails != null) {
        updates['carDetails'] = carDetails;
      }

      await _firestore.collection('users').doc(userId).update(updates);
    } catch (e) {
      debugPrint('Error updating user profile: $e');
      throw 'Failed to update profile';
    }
  }

  // Get QR code data
  Future<Map<String, dynamic>?> getQRCodeData(String qrCodeId) async {
    try {
      final doc = await _firestore.collection('qrCodes').doc(qrCodeId).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      debugPrint('Error getting QR code data: $e');
      return null;
    }
  }

  // Sync QR code metadata with Firestore
  Future<void> syncQRCodeMetadata({
    required String qrCodeId,
    required Map<String, dynamic> metadata,
    String? shareableLink,
    String? payload,
  }) async {
    try {
      await _firestore.collection('qrCodes').doc(qrCodeId).set(
        {
          'metadata': metadata,
          if (shareableLink != null) 'shareableLink': shareableLink,
          if (payload != null) 'payload': payload,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('Error syncing QR code metadata: $e');
    }
  }

  // Toggle QR code active status
  Future<void> toggleQRCodeStatus({
    required String qrCodeId,
    required bool isActive,
  }) async {
    try {
      await _firestore.collection('qrCodes').doc(qrCodeId).update({
        'isActive': isActive,
      });
    } catch (e) {
      debugPrint('Error toggling QR code status: $e');
      throw 'Failed to update QR code status';
    }
  }

  // Get user notifications
  Stream<List<NotificationModel>> streamUserNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('sentAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationModel.fromFirestore(doc))
            .toList());
  }

  // Get notification by ID
  Future<NotificationModel?> getNotification(String notificationId) async {
    try {
      final doc = await _firestore
          .collection('notifications')
          .doc(notificationId)
          .get();

      if (doc.exists) {
        return NotificationModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting notification: $e');
      return null;
    }
  }

  // Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'read': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();
    } catch (e) {
      debugPrint('Error deleting notification: $e');
      throw 'Failed to delete notification';
    }
  }

  // Get notification count
  Future<int> getUnreadNotificationCount(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('read', isEqualTo: false)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      debugPrint('Error getting notification count: $e');
      return 0;
    }
  }

  // Stream unread notification count
  Stream<int> streamUnreadNotificationCount(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Get notification statistics
  Future<Map<String, int>> getNotificationStats(String userId) async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);

      // Get today's notifications
      final todaySnapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('sentAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .get();

      // Get total notifications
      final totalSnapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .get();

      return {
        'today': todaySnapshot.docs.length,
        'total': totalSnapshot.docs.length,
      };
    } catch (e) {
      debugPrint('Error getting notification stats: $e');
      return {'today': 0, 'total': 0};
    }
  }

  // Clear all notifications for user
  Future<void> clearAllNotifications(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .get();

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Error clearing notifications: $e');
      throw 'Failed to clear notifications';
    }
  }
}
