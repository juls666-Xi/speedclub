// ════════════════════════════════════════════════════════════════
// lib/features/challenge/presentation/pages/create_challenge_page.dart
// ════════════════════════════════════════════════════════════════
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/router/app_router.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../data/challenge_repository.dart';
import 'meet_place_picker_page.dart';

const _gapOptions = [100, 300, 500, 1000];

class CreateChallengePage extends ConsumerStatefulWidget {
  const CreateChallengePage({super.key, this.prefilledOpponentId});
  final String? prefilledOpponentId;

  @override
  ConsumerState<CreateChallengePage> createState() => _CreateChallengePageState();
}

class _CreateChallengePageState extends ConsumerState<CreateChallengePage> {
  final _formKey = GlobalKey<FormState>();
  final _opponentCtrl = TextEditingController();
  final _msgCtrl = TextEditingController();
  final _customGapCtrl = TextEditingController();

  String _category = 'running';
  int? _selectedGap;
  bool _customGap = false;
  DateTime? _scheduledDate;
  TimeOfDay? _scheduledTime;
  LatLng? _meetPlace;
  String? _meetPlaceName;
  bool _loading = false;
  String? _opponentId;
  String? _opponentUsername;

  @override
  void initState() {
    super.initState();
    if (widget.prefilledOpponentId != null) {
      _opponentId = widget.prefilledOpponentId;
      _resolveOpponentUsername();
    }
  }

  Future<void> _resolveOpponentUsername() async {
    try {
      final sb = ref.read(supabaseClientProvider);
      final res = await sb
          .from('users')
          .select('username')
          .eq('id', _opponentId!)
          .single();
      setState(() {
        _opponentUsername = res['username'];
        _opponentCtrl.text = res['username'];
      });
    } catch (_) {}
  }

  Future<void> _searchOpponent(String username) async {
    if (username.trim().isEmpty) return;
    try {
      final sb = ref.read(supabaseClientProvider);
      final res = await sb
          .from('users')
          .select('id, username')
          .eq('username', username.trim())
          .single();
      setState(() {
        _opponentId = res['id'];
        _opponentUsername = res['username'];
      });
    } catch (_) {
      setState(() { _opponentId = null; _opponentUsername = null; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not found')),
        );
      }
    }
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(hours: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: AppColors.neonCyan),
        ),
        child: child!,
      ),
    );
    if (d != null) setState(() => _scheduledDate = d);
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: AppColors.neonCyan),
        ),
        child: child!,
      ),
    );
    if (t != null) setState(() => _scheduledTime = t);
  }

  Future<void> _pickMeetPlace() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => const MeetPlacePickerPage()),
    );
    if (result != null) {
      setState(() {
        _meetPlace = result['latlng'] as LatLng;
        _meetPlaceName = result['name'] as String?;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_opponentId == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Select a valid opponent')));
      return;
    }
    if (_meetPlace == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Pick a meet place on the map')));
      return;
    }
    final gap = _customGap
        ? int.tryParse(_customGapCtrl.text)
        : _selectedGap;
    if (gap == null || gap <= 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Select a valid gap distance')));
      return;
    }

    final scheduled = DateTime(
      _scheduledDate!.year, _scheduledDate!.month, _scheduledDate!.day,
      _scheduledTime!.hour, _scheduledTime!.minute,
    );

    setState(() => _loading = true);
    try {
      final repo = ref.read(challengeRepositoryProvider);
      final session = ref.read(authStateProvider).valueOrNull!;
      await repo.createChallenge(
        challengerId: session.id,
        opponentId: _opponentId!,
        category: _category,
        gapDistanceM: gap,
        scheduledAt: scheduled,
        meetLat: _meetPlace!.latitude,
        meetLng: _meetPlace!.longitude,
        meetPlaceName: _meetPlaceName,
        optionalMessage: _msgCtrl.text.trim().isEmpty ? null : _msgCtrl.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Challenge sent! ⚡'),
            backgroundColor: AppColors.neonGreen,
          ),
        );
        context.go(AppRoutes.home);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.neonRed),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg0,
      appBar: AppBar(
        title: const Text('CREATE DUEL'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.neonCyan),
          onPressed: () => context.pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // OPPONENT
            _SectionLabel(label: 'OPPONENT'),
            Row(
              children: [
                Expanded(
                  child: NeonTextField(
                    controller: _opponentCtrl,
                    label: 'USERNAME',
                    prefixIcon: Icons.person_outline,
                    enabled: widget.prefilledOpponentId == null,
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                ),
                if (widget.prefilledOpponentId == null) ...[
                  const SizedBox(width: 10),
                  IconButton(
                    icon: const Icon(Icons.search, color: AppColors.neonCyan),
                    onPressed: () => _searchOpponent(_opponentCtrl.text),
                  ),
                ],
              ],
            ),
            if (_opponentUsername != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.check_circle, size: 16, color: AppColors.neonGreen),
                  const SizedBox(width: 6),
                  Text('Opponent: $_opponentUsername', style: AppTextStyles.bodySmall.copyWith(color: AppColors.neonGreen)),
                ],
              ),
            ],

            const SizedBox(height: 24),
            _SectionLabel(label: 'CATEGORY'),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: ['car', 'bicycle', 'motorcycle', 'running']
                  .map((c) => CategoryChip(
                        category: c,
                        selected: _category == c,
                        onTap: () => setState(() => _category = c),
                      ))
                  .toList(),
            ),

            const SizedBox(height: 24),
            _SectionLabel(label: 'GAP DISTANCE TO WIN'),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                ..._gapOptions.map((g) => _GapChip(
                      meters: g,
                      selected: !_customGap && _selectedGap == g,
                      onTap: () => setState(() {
                        _selectedGap = g;
                        _customGap = false;
                      }),
                    )),
                _GapChip(
                  label: 'CUSTOM',
                  selected: _customGap,
                  onTap: () => setState(() {
                    _customGap = true;
                    _selectedGap = null;
                  }),
                ),
              ],
            ),
            if (_customGap) ...[
              const SizedBox(height: 12),
              NeonTextField(
                controller: _customGapCtrl,
                label: 'CUSTOM GAP (meters)',
                prefixIcon: Icons.straighten,
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (!_customGap) return null;
                  final n = int.tryParse(v ?? '');
                  if (n == null || n < 50) return 'Minimum 50 meters';
                  if (n > 10000) return 'Maximum 10,000 meters';
                  return null;
                },
              ),
            ],

            const SizedBox(height: 24),
            _SectionLabel(label: 'SCHEDULE'),
            Row(
              children: [
                Expanded(
                  child: _InfoTile(
                    icon: Icons.calendar_today,
                    label: 'DATE',
                    value: _scheduledDate != null
                        ? DateFormat('MMM dd, yyyy').format(_scheduledDate!)
                        : 'Tap to pick',
                    onTap: _pickDate,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _InfoTile(
                    icon: Icons.access_time,
                    label: 'TIME',
                    value: _scheduledTime != null
                        ? _scheduledTime!.format(context)
                        : 'Tap to pick',
                    onTap: _pickTime,
                  ),
                ),
              ],
            ),
            if (_scheduledDate == null || _scheduledTime == null) ...[
              const SizedBox(height: 6),
              Text('* Date and time required',
                  style: AppTextStyles.label.copyWith(color: AppColors.neonRed)),
            ],

            const SizedBox(height: 24),
            _SectionLabel(label: 'MEET PLACE'),
            _InfoTile(
              icon: Icons.location_on_outlined,
              label: 'LOCATION',
              value: _meetPlaceName ?? (_meetPlace != null
                  ? '${_meetPlace!.latitude.toStringAsFixed(5)}, ${_meetPlace!.longitude.toStringAsFixed(5)}'
                  : 'Tap to pick on map'),
              onTap: _pickMeetPlace,
              accentColor: _meetPlace != null ? AppColors.neonGreen : null,
            ),

            const SizedBox(height: 24),
            _SectionLabel(label: 'MESSAGE (OPTIONAL)'),
            NeonTextField(
              controller: _msgCtrl,
              label: 'Trash talk or instructions…',
              maxLines: 3,
            ),

            const SizedBox(height: 36),
            NeonButton(
              label: 'SEND CHALLENGE ⚡',
              loading: _loading,
              onPressed: () {
                if (_scheduledDate == null || _scheduledTime == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Pick a date and time')),
                  );
                  return;
                }
                _submit();
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(label, style: AppTextStyles.label.copyWith(letterSpacing: 2)),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
    this.accentColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? AppColors.neonCyan;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.bg2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTextStyles.label.copyWith(fontSize: 10)),
                  const SizedBox(height: 2),
                  Text(value,
                      style: AppTextStyles.body.copyWith(color: color),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 16, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}

class _GapChip extends StatelessWidget {
  const _GapChip({this.meters, this.label, required this.selected, required this.onTap});
  final int? meters;
  final String? label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = label ?? '${meters}m';
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.neonOrange.withOpacity(0.15) : AppColors.bg2,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppColors.neonOrange : AppColors.borderSubtle,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          text,
          style: AppTextStyles.body.copyWith(
            color: selected ? AppColors.neonOrange : AppColors.textSecondary,
            fontFamily: 'Orbitron',
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// lib/features/challenge/presentation/pages/challenges_tab.dart
// ════════════════════════════════════════════════════════════════

class ChallengesTab extends ConsumerStatefulWidget {
  const ChallengesTab({super.key});

  @override
  ConsumerState<ChallengesTab> createState() => _ChallengesTabState();
}

class _ChallengesTabState extends ConsumerState<ChallengesTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg0,
      appBar: AppBar(
        title: const Text('DUELS'),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: AppColors.neonCyan,
          labelColor: AppColors.neonCyan,
          unselectedLabelColor: AppColors.textHint,
          tabs: const [
            Tab(text: 'INCOMING'),
            Tab(text: 'OUTGOING'),
            Tab(text: 'SCHEDULED'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: const [
          _ChallengeList(type: 'incoming'),
          _ChallengeList(type: 'outgoing'),
          _ChallengeList(type: 'scheduled'),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go(AppRoutes.challenge),
        backgroundColor: AppColors.neonCyan,
        foregroundColor: AppColors.bg0,
        icon: const Icon(Icons.add),
        label: Text('NEW DUEL', style: AppTextStyles.label.copyWith(color: AppColors.bg0)),
      ),
    );
  }
}

class _ChallengeList extends ConsumerWidget {
  const _ChallengeList({required this.type});
  final String type;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authStateProvider).valueOrNull;
    if (session == null) return const SizedBox();

    return FutureBuilder(
      future: _fetchChallenges(ref, session.id),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(AppColors.neonCyan),
            ),
          );
        }
        final all = snap.data ?? [];
        final filtered = all.where((c) {
          if (type == 'incoming') {
            return c['opponent_id'] == session.id && c['status'] == 'pending';
          } else if (type == 'outgoing') {
            return c['challenger_id'] == session.id && c['status'] == 'pending';
          } else {
            return c['status'] == 'accepted';
          }
        }).toList();

        if (filtered.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  type == 'incoming'
                      ? Icons.inbox_rounded
                      : type == 'outgoing'
                          ? Icons.send_rounded
                          : Icons.event_rounded,
                  size: 52,
                  color: AppColors.textHint,
                ),
                const SizedBox(height: 12),
                Text('No ${type} challenges', style: AppTextStyles.bodySmall),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filtered.length,
          itemBuilder: (ctx, i) => _ChallengeCard(
            data: filtered[i],
            sessionId: session.id,
            type: type,
          ),
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _fetchChallenges(
      WidgetRef ref, String userId) async {
    final sb = ref.read(supabaseClientProvider);
    return List<Map<String, dynamic>>.from(
      await sb
          .from('challenges')
          .select('*, challenger:challenger_id(username), opponent:opponent_id(username)')
          .or('challenger_id.eq.$userId,opponent_id.eq.$userId')
          .order('created_at', ascending: false),
    );
  }
}

class _ChallengeCard extends ConsumerWidget {
  const _ChallengeCard({
    required this.data,
    required this.sessionId,
    required this.type,
  });

  final Map<String, dynamic> data;
  final String sessionId;
  final String type;

  bool get isIncoming => data['opponent_id'] == sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final other = isIncoming
        ? data['challenger']['username']
        : data['opponent']['username'];
    final status = data['status'] as String;
    final category = data['category'] as String;
    final gap = data['gap_distance_m'] as int;
    final scheduled = DateTime.parse(data['scheduled_at']).toLocal();

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      glowColor: categoryColor(category),
      onTap: () => context.go('/challenge/${data['id']}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CategoryChip(category: category),
              const Spacer(),
              _StatusBadge(status: status),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            isIncoming ? '⚡ ${other.toUpperCase()} challenges you' : '→ You challenged ${other.toUpperCase()}',
            style: AppTextStyles.h3,
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.straighten, size: 14, color: AppColors.neonOrange),
              const SizedBox(width: 4),
              Text('${gap}m gap to win', style: AppTextStyles.bodySmall),
              const SizedBox(width: 16),
              Icon(Icons.schedule, size: 14, color: AppColors.textHint),
              const SizedBox(width: 4),
              Text(DateFormat('MMM dd, HH:mm').format(scheduled),
                  style: AppTextStyles.bodySmall),
            ],
          ),
          if (type == 'incoming' && status == 'pending') ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: NeonButton(
                    label: 'ACCEPT',
                    small: true,
                    accentColor: AppColors.neonGreen,
                    onPressed: () => _respond(context, ref, 'accepted'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: NeonButton(
                    label: 'DECLINE',
                    small: true,
                    outlined: true,
                    accentColor: AppColors.neonRed,
                    onPressed: () => _respond(context, ref, 'declined'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _respond(BuildContext ctx, WidgetRef ref, String status) async {
    final sb = ref.read(supabaseClientProvider);
    await sb.from('challenges').update({
      'status': status,
      'responded_at': DateTime.now().toIso8601String(),
    }).eq('id', data['id']);

    // If accepted, create a match
    if (status == 'accepted') {
      await sb.from('matches').insert({
        'challenge_id': data['id'],
        'player_a_id': data['challenger_id'],
        'player_b_id': data['opponent_id'],
        'category': data['category'],
        'gap_distance_m': data['gap_distance_m'],
        'meet_lat': data['meet_lat'],
        'meet_lng': data['meet_lng'],
        'status': 'lobby',
      });
    }

    if (ctx.mounted) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: Text(status == 'accepted' ? 'Challenge accepted! 🔥' : 'Challenge declined'),
          backgroundColor: status == 'accepted' ? AppColors.neonGreen : AppColors.textSecondary,
        ),
      );
    }
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status) {
      'pending'   => (AppColors.neonOrange, 'PENDING'),
      'accepted'  => (AppColors.neonGreen, 'ACCEPTED'),
      'declined'  => (AppColors.neonRed, 'DECLINED'),
      'cancelled' => (AppColors.textHint, 'CANCELLED'),
      'completed' => (AppColors.neonCyan, 'DONE'),
      _           => (AppColors.textHint, status.toUpperCase()),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(label,
          style: AppTextStyles.label.copyWith(color: color, fontSize: 10)),
    );
  }
}