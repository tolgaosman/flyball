import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flyball_core/flyball_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/app_config.dart';
import 'account_api.dart';

/// The signed-in account (or `null`), persisted across launches.
///
/// Accounts live on the Flyball backend, so they're only [isAvailable] in
/// [AiMode.backend]; in the other modes every screen simply has no account.
/// Listen to this notifier to react to sign-in / sign-out anywhere.
class SessionController extends ValueNotifier<AccountUser?> {
  SessionController({AccountApi? api})
      : _api = api, // ignore: prefer_initializing_formals
        super(null);

  /// Built from `--dart-define` config: backend mode gets a real API,
  /// anything else gets an unavailable controller.
  factory SessionController.fromConfig() => SessionController(
        api: AppConfig.aiMode == AiMode.backend
            ? AccountApi(baseUrl: AppConfig.apiBaseUrl)
            : null,
      );

  static const _tokenKey = 'flyball.session.token';
  static const _userKey = 'flyball.session.user';

  final AccountApi? _api;
  String? _token;

  bool get isAvailable => _api != null;

  bool get isSignedIn => value != null;

  /// The bearer token for authenticated backend calls
  /// (`Authorization: Bearer <token>`), or `null` when signed out.
  String? get token => _token;

  /// Restores the saved session instantly from local storage (so the app
  /// starts signed in even offline), then re-checks it with the backend in
  /// the background.
  Future<void> restore() async {
    if (!isAvailable) return;
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    final userJson = prefs.getString(_userKey);
    if (token == null || userJson == null) return;
    try {
      value = AccountUser.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
      _token = token;
    } on Object {
      await _clear();
      return;
    }
    unawaited(refresh());
  }

  /// Re-fetches the account from the backend. A session the server no
  /// longer knows signs the app out; an unreachable server keeps the cached
  /// account.
  Future<void> refresh() async {
    final token = _token;
    if (_api == null || token == null) return;
    try {
      final user = await _api.me(token);
      if (_token != token) return; // signed out/in again meanwhile.
      await _save(token, user);
    } on AccountException catch (e) {
      if (e.code == AccountErrors.unauthorized && _token == token) await _clear();
    }
  }

  /// Throws [AccountException] on failure.
  Future<void> login({required String username, required String password}) async {
    final result = await _requireApi().login(username: username, password: password);
    await _save(result.token, result.user);
  }

  /// Throws [AccountException] on failure.
  Future<void> register({
    required String username,
    required String password,
    String? displayName,
  }) async {
    final result = await _requireApi().register(
      username: username,
      password: password,
      displayName: displayName,
    );
    await _save(result.token, result.user);
  }

  /// Signs out locally right away; tells the backend in the background.
  Future<void> logout() async {
    final token = _token;
    await _clear();
    if (token != null) unawaited(_api?.logout(token));
  }

  AccountApi _requireApi() {
    final api = _api;
    if (api == null) throw const AccountException(AccountException.network);
    return api;
  }

  Future<void> _save(String token, AccountUser user) async {
    _token = token;
    value = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  Future<void> _clear() async {
    _token = null;
    value = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }
}
