import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AwardsState {
  const AwardsState({
    this.totalPoints = 0,
    this.monthlyPoints = 0,
    this.nextGoalPoints = 100,
    this.earnedBadges = const [],
    this.fullName,
    this.avatarUrl,
    this.isLoading = true,
  });

  final int totalPoints;
  final int monthlyPoints;
  final int nextGoalPoints;
  final List<String> earnedBadges; // List of badge IDs
  final String? fullName;
  final String? avatarUrl;
  final bool isLoading;

  AwardsState copyWith({
    int? totalPoints,
    int? monthlyPoints,
    int? nextGoalPoints,
    List<String>? earnedBadges,
    String? fullName,
    String? avatarUrl,
    bool? isLoading,
  }) {
    return AwardsState(
      totalPoints: totalPoints ?? this.totalPoints,
      monthlyPoints: monthlyPoints ?? this.monthlyPoints,
      nextGoalPoints: nextGoalPoints ?? this.nextGoalPoints,
      earnedBadges: earnedBadges ?? this.earnedBadges,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class AwardsCubit extends StateNotifier<AwardsState> {
  AwardsCubit(this._firestore, this._auth) : super(const AwardsState()) {
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

    _userSub = _firestore.collection('users').doc(user.uid).snapshots().listen((
      snap,
    ) {
      final data = snap.data() ?? {};
      final points = (data['total_points'] as int?) ?? 0;
      final monthlyPoints = (data['monthly_points'] as int?) ?? 0;
      final nextGoal = (data['next_goal_points'] as int?) ?? 100;
      final badges =
          (data['earned_badges'] as List?)?.map((e) => e.toString()).toList() ??
          <String>[];
      final fullName = data['full_name'] as String?;
      final avatarUrl = data['avatar_url'] as String?;

      state = state.copyWith(
        totalPoints: points,
        monthlyPoints: monthlyPoints,
        nextGoalPoints: nextGoal,
        earnedBadges: badges,
        fullName: fullName,
        avatarUrl: avatarUrl,
        isLoading: false,
      );
    });
  }

  @override
  void dispose() {
    _userSub?.cancel();
    super.dispose();
  }
}

final awardsCubitProvider = StateNotifierProvider<AwardsCubit, AwardsState>((
  ref,
) {
  return AwardsCubit(FirebaseFirestore.instance, FirebaseAuth.instance);
});
