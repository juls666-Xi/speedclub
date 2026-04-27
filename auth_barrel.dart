// lib/core/supabase/supabase_client.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final supabaseClientProvider = Provider<SupabaseClient>(
  (_) => Supabase.instance.client,
);

// ─────────────────────────────────────────────────────────────
// lib/features/auth/providers/auth_provider.dart
// ─────────────────────────────────────────────────────────────
// NOTE: DuelGap uses custom username/password auth via a
// Supabase Edge Function that issues a signed JWT.
// The JWT 'sub' claim = users.id (UUID).
// ─────────────────────────────────────────────────────────────

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../../../core/supabase/supabase_client.dart';
import '../data/auth_repository.dart';
import '../domain/user_session.dart';

part 'auth_provider.g.dart';

// Current session (null = logged out)
@riverpod
Stream<UserSession?> authState(AuthStateRef ref) {
  return ref.watch(authRepositoryProvider).sessionStream;
}

@riverpod
AuthRepository authRepository(AuthRepositoryRef ref) {
  return AuthRepository(ref.watch(supabaseClientProvider));
}

// ─────────────────────────────────────────────────────────────
// lib/features/auth/data/auth_repository.dart
// ─────────────────────────────────────────────────────────────

import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:crypto/crypto.dart';
import '../domain/user_session.dart';

class AuthRepository {
  final SupabaseClient _client;
  final _sessionCtrl = StreamController<UserSession?>.broadcast();

  AuthRepository(this._client) {
    _loadCachedSession();
  }

  Stream<UserSession?> get sessionStream => _sessionCtrl.stream;
  UserSession? _current;
  UserSession? get current => _current;

  String _hashPw(String pw) =>
      sha256.convert(utf8.encode(pw + 'duelgap_salt_v1')).toString();

  Future<UserSession> register({
    required String username,
    required String password,
  }) async {
    final hash = _hashPw(password);
    // Insert user – DB trigger creates profile + rankings
    final res = await _client
        .from('users')
        .insert({'username': username, 'password_hash': hash})
        .select('id, username')
        .single();

    final session = UserSession(id: res['id'], username: res['username']);
    await _persistSession(session);
    _sessionCtrl.add(session);
    _current = session;
    return session;
  }

  Future<UserSession> login({
    required String username,
    required String password,
  }) async {
    final hash = _hashPw(password);
    final res = await _client
        .from('users')
        .select('id, username, is_banned, ban_reason')
        .eq('username', username)
        .eq('password_hash', hash)
        .maybeSingle();

    if (res == null) throw Exception('Invalid username or password');
    if (res['is_banned'] == true) {
      throw Exception('Account banned: ${res['ban_reason'] ?? 'violation'}');
    }

    // Update last_seen
    await _client
        .from('users')
        .update({'last_seen': DateTime.now().toIso8601String()})
        .eq('id', res['id']);

    final session = UserSession(id: res['id'], username: res['username']);
    await _persistSession(session);
    _sessionCtrl.add(session);
    _current = session;
    return session;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('duelgap_session');
    _current = null;
    _sessionCtrl.add(null);
  }

  Future<void> _persistSession(UserSession s) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('duelgap_session', jsonEncode(s.toJson()));
  }

  Future<void> _loadCachedSession() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('duelgap_session');
    if (raw != null) {
      try {
        final s = UserSession.fromJson(jsonDecode(raw));
        _current = s;
        _sessionCtrl.add(s);
      } catch (_) {}
    } else {
      _sessionCtrl.add(null);
    }
  }
}

// ─────────────────────────────────────────────────────────────
// lib/features/auth/domain/user_session.dart
// ─────────────────────────────────────────────────────────────

import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_session.freezed.dart';
part 'user_session.g.dart';

@freezed
class UserSession with _$UserSession {
  const factory UserSession({
    required String id,
    required String username,
  }) = _UserSession;

  factory UserSession.fromJson(Map<String, dynamic> json) =>
      _$UserSessionFromJson(json);
}