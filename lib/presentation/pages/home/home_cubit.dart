import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeState {
  const HomeState({
    this.fullName,
    this.avatarUrl,
    this.isManager = false,
    this.managedUsersCount = 0,
    this.activeRequestsCount = 0,
    this.scheduledCount = 0,
    this.completedTodayCount = 0,
    this.totalPoints = 0,
    this.nextGoalPoints = 100,
    this.isLoading = true,
  });

  final String? fullName;
  final String? avatarUrl;
  final bool isManager;
  final int managedUsersCount;
  final int activeRequestsCount;
  final int scheduledCount;
  final int completedTodayCount;
  final int totalPoints;
  final int nextGoalPoints;
  final bool isLoading;

  HomeState copyWith({
    String? fullName,
    String? avatarUrl,
    bool? isManager,
    int? managedUsersCount,
    int? activeRequestsCount,
    int? scheduledCount,
    int? completedTodayCount,
    int? totalPoints,
    int? nextGoalPoints,
    bool? isLoading,
  }) {
    return HomeState(
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isManager: isManager ?? this.isManager,
      managedUsersCount: managedUsersCount ?? this.managedUsersCount,
      activeRequestsCount: activeRequestsCount ?? this.activeRequestsCount,
      scheduledCount: scheduledCount ?? this.scheduledCount,
      completedTodayCount: completedTodayCount ?? this.completedTodayCount,
      totalPoints: totalPoints ?? this.totalPoints,
      nextGoalPoints: nextGoalPoints ?? this.nextGoalPoints,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class HomeCubit extends StateNotifier<HomeState> {
  HomeCubit(this._firestore, this._auth) : super(const HomeState()) {
    _init();
  }

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userSub;

  void _init() {
    final user = _auth.currentUser;
    if (user == null) {
      state = state.copyWith(isLoading: false);
      return;
    }

    _userSub = _firestore.collection('users').doc(user.uid).snapshots().listen((snap) {
      final data = snap.data() ?? {};
      final isManager = (data['is_angel_manager'] as bool?) ?? false;
      final managerStatus = data['manager_status'] as String?;
      final isApprovedManager = isManager && managerStatus == 'approved';

      state = state.copyWith(
        fullName: data['full_name'] as String?,
        avatarUrl: data['avatar_url'] as String?,
        isManager: isApprovedManager,
        isLoading: false,
      );

      if (isApprovedManager) {
        _loadManagerStats(user.uid);
      } else {
        _loadUserPoints(user.uid);
      }
    });
  }

  Future<void> _loadManagerStats(String userId) async {
    try {
      // Count managed users (users linked to this manager)
      int managedUsersCount = 0;
      try {
        final managedUsersQuery = await _firestore
            .collection('users')
            .where('manager_id', isEqualTo: userId)
            .count()
            .get();
        managedUsersCount = managedUsersQuery.count ?? 0;
      } catch (_) {
        // Fallback: get documents and count
        final managedUsersSnapshot = await _firestore
            .collection('users')
            .where('manager_id', isEqualTo: userId)
            .get();
        managedUsersCount = managedUsersSnapshot.docs.length;
      }

      // Count active requests
      int activeRequestsCount = 0;
      try {
        final activeRequestsQuery = await _firestore
            .collection('pings')
            .where('status', isEqualTo: 'open')
            .count()
            .get();
        activeRequestsCount = activeRequestsQuery.count ?? 0;
      } catch (_) {
        final activeRequestsSnapshot = await _firestore
            .collection('pings')
            .where('status', isEqualTo: 'open')
            .limit(100) // Limit to avoid too many reads
            .get();
        activeRequestsCount = activeRequestsSnapshot.docs.length;
      }

      // Count scheduled
      int scheduledCount = 0;
      try {
        final scheduledQuery = await _firestore
            .collection('pings')
            .where('status', isEqualTo: 'scheduled')
            .count()
            .get();
        scheduledCount = scheduledQuery.count ?? 0;
      } catch (_) {
        final scheduledSnapshot = await _firestore
            .collection('pings')
            .where('status', isEqualTo: 'scheduled')
            .limit(100)
            .get();
        scheduledCount = scheduledSnapshot.docs.length;
      }

      // Count completed today
      int completedTodayCount = 0;
      try {
        final now = DateTime.now();
        final todayStart = DateTime(now.year, now.month, now.day);
        final completedQuery = await _firestore
            .collection('pings')
            .where('status', isEqualTo: 'completed')
            .where('completedAt', isGreaterThan: Timestamp.fromDate(todayStart))
            .count()
            .get();
        completedTodayCount = completedQuery.count ?? 0;
      } catch (_) {
        final now = DateTime.now();
        final todayStart = DateTime(now.year, now.month, now.day);
        final completedSnapshot = await _firestore
            .collection('pings')
            .where('status', isEqualTo: 'completed')
            .where('completedAt', isGreaterThan: Timestamp.fromDate(todayStart))
            .limit(100)
            .get();
        completedTodayCount = completedSnapshot.docs.length;
      }

      state = state.copyWith(
        managedUsersCount: managedUsersCount,
        activeRequestsCount: activeRequestsCount,
        scheduledCount: scheduledCount,
        completedTodayCount: completedTodayCount,
      );
    } catch (e) {
      // Silently fail - stats are not critical
      debugPrint('Error loading manager stats: $e');
    }
  }

  Future<void> _loadUserPoints(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final data = userDoc.data() ?? {};
      final points = (data['total_points'] as int?) ?? 0;
      final nextGoal = (data['next_goal_points'] as int?) ?? 100;

      state = state.copyWith(
        totalPoints: points,
        nextGoalPoints: nextGoal,
      );
    } catch (e) {
      debugPrint('Error loading user points: $e');
    }
  }

  @override
  void dispose() {
    _userSub?.cancel();
    super.dispose();
  }
}

final homeCubitProvider = StateNotifierProvider<HomeCubit, HomeState>((ref) {
  return HomeCubit(
    FirebaseFirestore.instance,
    FirebaseAuth.instance,
  );
});

