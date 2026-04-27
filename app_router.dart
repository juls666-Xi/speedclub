// lib/core/router/app_router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/challenge/presentation/pages/create_challenge_page.dart';
import '../../features/challenge/presentation/pages/challenge_detail_page.dart';
import '../../features/race/presentation/pages/pre_race_lobby_page.dart';
import '../../features/race/presentation/pages/live_race_page.dart';
import '../../features/race/presentation/pages/post_race_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/profile/presentation/pages/edit_profile_page.dart';
import '../../features/matchmaking/presentation/pages/matchmaking_page.dart';
import '../../features/rankings/presentation/pages/rankings_page.dart';

part 'app_router.g.dart';

// Route names
class AppRoutes {
  static const login       = '/login';
  static const register    = '/register';
  static const home        = '/home';
  static const profile     = '/profile/:userId';
  static const editProfile = '/profile/edit';
  static const challenge   = '/challenge/new';
  static const challengeDetail = '/challenge/:challengeId';
  static const matchmaking = '/matchmaking';
  static const lobby       = '/race/lobby/:matchId';
  static const liveRace    = '/race/live/:matchId';
  static const postRace    = '/race/result/:matchId';
  static const rankings    = '/rankings';
}

@riverpod
GoRouter appRouter(AppRouterRef ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: AppRoutes.login,
    redirect: (context, state) {
      final loggedIn = authState.valueOrNull != null;
      final loggingIn = state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.register;

      if (!loggedIn && !loggingIn) return AppRoutes.login;
      if (loggedIn && loggingIn) return AppRoutes.home;
      return null;
    },
    routes: [
      GoRoute(path: AppRoutes.login,    builder: (_, __) => const LoginPage()),
      GoRoute(path: AppRoutes.register, builder: (_, __) => const RegisterPage()),
      GoRoute(path: AppRoutes.home,     builder: (_, __) => const HomePage()),
      GoRoute(
        path: AppRoutes.profile,
        builder: (_, state) => ProfilePage(userId: state.pathParameters['userId']!),
      ),
      GoRoute(path: AppRoutes.editProfile, builder: (_, __) => const EditProfilePage()),
      GoRoute(path: AppRoutes.challenge,   builder: (_, state) {
        final opponentId = state.uri.queryParameters['opponentId'];
        return CreateChallengePage(prefilledOpponentId: opponentId);
      }),
      GoRoute(
        path: AppRoutes.challengeDetail,
        builder: (_, state) => ChallengeDetailPage(
          challengeId: state.pathParameters['challengeId']!,
        ),
      ),
      GoRoute(path: AppRoutes.matchmaking, builder: (_, __) => const MatchmakingPage()),
      GoRoute(
        path: AppRoutes.lobby,
        builder: (_, state) => PreRaceLobbyPage(matchId: state.pathParameters['matchId']!),
      ),
      GoRoute(
        path: AppRoutes.liveRace,
        builder: (_, state) => LiveRacePage(matchId: state.pathParameters['matchId']!),
      ),
      GoRoute(
        path: AppRoutes.postRace,
        builder: (_, state) => PostRacePage(matchId: state.pathParameters['matchId']!),
      ),
      GoRoute(path: AppRoutes.rankings, builder: (_, __) => const RankingsPage()),
    ],
    errorBuilder: (_, state) => Scaffold(
      body: Center(child: Text('Route not found: ${state.uri}')),
    ),
  );
}