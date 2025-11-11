import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum LeaderboardType { monthly, allTime }

class LeaderboardState {
  const LeaderboardState({
    this.totalPoints = 0,
    this.monthlyPoints = 0,
    this.currentLeaderboardType = LeaderboardType.monthly,
    this.leaderboard = const [],
    this.currentUserRank = 0,
    this.fullName,
    this.avatarUrl,
    this.isLoading = true,
  });

  final int totalPoints;
  final int monthlyPoints;
  final LeaderboardType currentLeaderboardType;
  final List<LeaderboardEntry> leaderboard;
  final int currentUserRank;
  final String? fullName;
  final String? avatarUrl;
  final bool isLoading;

  LeaderboardState copyWith({
    int? totalPoints,
    int? monthlyPoints,
    LeaderboardType? currentLeaderboardType,
    List<LeaderboardEntry>? leaderboard,
    int? currentUserRank,
    String? fullName,
    String? avatarUrl,
    bool? isLoading,
  }) {
    return LeaderboardState(
      totalPoints: totalPoints ?? this.totalPoints,
      monthlyPoints: monthlyPoints ?? this.monthlyPoints,
      currentLeaderboardType: currentLeaderboardType ?? this.currentLeaderboardType,
      leaderboard: leaderboard ?? this.leaderboard,
      currentUserRank: currentUserRank ?? this.currentUserRank,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class LeaderboardEntry {
  const LeaderboardEntry({
    required this.userId,
    required this.fullName,
    required this.points,
    this.avatarUrl,
    this.rank = 0,
  });

  final String userId;
  final String fullName;
  final int points;
  final String? avatarUrl;
  final int rank;
}

class LeaderboardCubit extends StateNotifier<LeaderboardState> {
  LeaderboardCubit(this._firestore, this._auth) : super(const LeaderboardState()) {
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
      final points = (data['total_points'] as int?) ?? 0;
      final monthlyPoints = (data['monthly_points'] as int?) ?? 0;
      final fullName = data['full_name'] as String?;
      final avatarUrl = data['avatar_url'] as String?;

      state = state.copyWith(
        totalPoints: points,
        monthlyPoints: monthlyPoints,
        fullName: fullName,
        avatarUrl: avatarUrl,
        isLoading: false,
      );
    });

    _loadLeaderboard();
  }

  void switchLeaderboardType(LeaderboardType type) {
    state = state.copyWith(currentLeaderboardType: type);
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      Query<Map<String, dynamic>> query;
      if (state.currentLeaderboardType == LeaderboardType.monthly) {
        // Load monthly leaderboard
        query = _firestore
            .collection('users')
            .where('monthly_points', isGreaterThan: 0)
            .orderBy('monthly_points', descending: true)
            .limit(100);
      } else {
        // Load all-time leaderboard
        query = _firestore
            .collection('users')
            .where('total_points', isGreaterThan: 0)
            .orderBy('total_points', descending: true)
            .limit(100);
      }

      final snapshot = await query.get();
      final entries = <LeaderboardEntry>[];
      int rank = 1;
      int userRank = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final points = state.currentLeaderboardType == LeaderboardType.monthly
            ? (data['monthly_points'] as int?) ?? 0
            : (data['total_points'] as int?) ?? 0;

          if (points > 0) {
          entries.add(LeaderboardEntry(
            userId: doc.id,
            fullName: (data['full_name'] as String?) ?? 'משתמש/ת',
            points: points,
            avatarUrl: data['avatar_url'] as String?,
            rank: rank,
          ));

          if (doc.id == user.uid) {
            userRank = rank;
          }
          rank++;
        }
      }

      state = state.copyWith(
        leaderboard: entries,
        currentUserRank: userRank,
      );
    } catch (e) {
      debugPrint('Error loading leaderboard: $e');
    }
  }

  @override
  void dispose() {
    _userSub?.cancel();
    super.dispose();
  }
}

final leaderboardCubitProvider = StateNotifierProvider<LeaderboardCubit, LeaderboardState>((ref) {
  return LeaderboardCubit(
    FirebaseFirestore.instance,
    FirebaseAuth.instance,
  );
});

