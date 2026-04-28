// lib/features/home/presentation/pages/home_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/router/app_router.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../challenge/presentation/pages/challenges_tab.dart';
import '../../../matchmaking/presentation/pages/matchmaking_tab.dart';
import '../../../rankings/presentation/pages/rankings_tab.dart';
import '../../../profile/presentation/pages/profile_tab.dart';
import 'find_opponent_tab.dart';

// Bottom nav index state
final _navIndexProvider = StateProvider<int>((_) => 0);

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final idx = ref.watch(_navIndexProvider);
    final session = ref.watch(authStateProvider).valueOrNull;

    final tabs = [
      const FindOpponentTab(),
      const MatchmakingTab(),
      const ChallengesTab(),
      const RankingsTab(),
      ProfileTab(userId: session?.id ?? ''),
    ];

    return Scaffold(
      backgroundColor: AppColors.bg0,
      body: IndexedStack(index: idx, children: tabs),
      bottomNavigationBar: _DuelNavBar(
        currentIndex: idx,
        onTap: (i) => ref.read(_navIndexProvider.notifier).state = i,
      ),
    );
  }
}

class _DuelNavBar extends StatelessWidget {
  const _DuelNavBar({required this.currentIndex, required this.onTap});
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    const items = [
      _NavItem(icon: Icons.search_rounded, label: 'Find'),
      _NavItem(icon: Icons.queue_rounded, label: 'Queue'),
      _NavItem(icon: Icons.sports_score_rounded, label: 'Duels'),
      _NavItem(icon: Icons.leaderboard_rounded, label: 'Ranks'),
      _NavItem(icon: Icons.person_rounded, label: 'Profile'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.bg1,
        border: const Border(top: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (i) {
              final selected = i == currentIndex;
              final item = items[i];
              return GestureDetector(
                onTap: () => onTap(i),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.neonCyan.withOpacity(0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        item.icon,
                        size: 22,
                        color: selected ? AppColors.neonCyan : AppColors.textHint,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.label,
                        style: AppTextStyles.label.copyWith(
                          color: selected ? AppColors.neonCyan : AppColors.textHint,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem({required this.icon, required this.label});
  final IconData icon;
  final String label;
}

// ════════════════════════════════════════════════════════════════
// lib/features/home/presentation/pages/find_opponent_tab.dart
// ════════════════════════════════════════════════════════════════

class FindOpponentTab extends ConsumerStatefulWidget {
  const FindOpponentTab({super.key});

  @override
  ConsumerState<FindOpponentTab> createState() => _FindOpponentTabState();
}

class _FindOpponentTabState extends ConsumerState<FindOpponentTab> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  List<Map<String, dynamic>> _results = [];
  bool _loading = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _search(String q) async {
    if (q.trim().length < 2) {
      setState(() => _results = []);
      return;
    }
    setState(() => _loading = true);
    try {
      final sb = ref.read(supabaseClientProvider);
      final session = ref.read(authStateProvider).valueOrNull;
      final res = await sb
          .from('users')
          .select('id, username, profiles(avatar_url, bio, favorite_category), rankings(category, tier, rank_points)')
          .ilike('username', '%${q.trim()}%')
          .neq('id', session?.id ?? '')
          .eq('is_banned', false)
          .limit(20);
      setState(() => _results = List<Map<String, dynamic>>.from(res));
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          backgroundColor: AppColors.bg0,
          title: Text('FIND OPPONENT', style: AppTextStyles.h2),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(64),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: TextField(
                controller: _searchCtrl,
                style: AppTextStyles.body,
                decoration: InputDecoration(
                  hintText: 'Search username…',
                  prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.textHint),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close, size: 18, color: AppColors.textHint),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() { _query = ''; _results = []; });
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.bg2,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (v) {
                  setState(() => _query = v);
                  _search(v);
                },
              ),
            ),
          ),
        ),

        if (_loading)
          const SliverFillRemaining(
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(AppColors.neonCyan),
              ),
            ),
          )
        else if (_results.isEmpty && _query.length >= 2)
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.person_search, size: 56, color: AppColors.textHint),
                  const SizedBox(height: 12),
                  Text('No racers found', style: AppTextStyles.h3.copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ),
          )
        else if (_results.isEmpty)
          SliverFillRemaining(
            child: _SearchHint(),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final user = _results[i];
                  final profile = (user['profiles'] as List?)?.firstOrNull ?? {};
                  final rankings = (user['rankings'] as List?) ?? [];
                  // Find best rank by points
                  final bestRank = rankings.isEmpty
                      ? null
                      : rankings.reduce((a, b) =>
                          (a['rank_points'] as int) >= (b['rank_points'] as int) ? a : b);

                  return _OpponentCard(
                    userId: user['id'],
                    username: user['username'],
                    avatarUrl: profile['avatar_url'],
                    bio: profile['bio'],
                    tier: bestRank?['tier'],
                    rankPoints: bestRank?['rank_points'],
                    rankings: rankings,
                  ).animate(delay: (i * 40).ms).fadeIn().slideX(begin: 0.1);
                },
                childCount: _results.length,
              ),
            ),
          ),
      ],
    );
  }
}

class _SearchHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.neonCyan.withOpacity(0.08),
              border: Border.all(color: AppColors.neonCyan.withOpacity(0.2)),
            ),
            child: const Icon(Icons.search_rounded, size: 36, color: AppColors.neonCyan),
          ),
          const SizedBox(height: 20),
          Text('Search for a racer', style: AppTextStyles.h2),
          const SizedBox(height: 8),
          Text(
            'Type a username to challenge\nthem to a GPS duel',
            style: AppTextStyles.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _OpponentCard extends StatelessWidget {
  const _OpponentCard({
    required this.userId,
    required this.username,
    this.avatarUrl,
    this.bio,
    this.tier,
    this.rankPoints,
    required this.rankings,
  });

  final String userId;
  final String username;
  final String? avatarUrl;
  final String? bio;
  final String? tier;
  final int? rankPoints;
  final List rankings;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      onTap: () => context.go('/profile/$userId'),
      child: Row(
        children: [
          UserAvatar(
            username: username,
            avatarUrl: avatarUrl,
            size: 52,
            glowColor: tier != null ? tierColor(tier!) : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(username, style: AppTextStyles.h3),
                if (bio != null && bio!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(bio!, style: AppTextStyles.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
                if (tier != null) ...[
                  const SizedBox(height: 6),
                  RankBadge(tier: tier!, points: rankPoints ?? 0, compact: true),
                ],
                if (rankings.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 4,
                    children: rankings.map((r) =>
                      CategoryChip(category: r['category'] as String, selected: false),
                    ).toList(),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          NeonButton(
            label: 'DUEL',
            small: true,
            onPressed: () => context.go(
              '${AppRoutes.challenge}?opponentId=$userId',
            ),
            icon: Icons.sports_score_rounded,
          ),
        ],
      ),
    );
  }
}