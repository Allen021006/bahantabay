import 'dart:async';

import 'package:flutter/material.dart';

import '../../home/presentation/screens/home_screen.dart';
import '../data/auth_service.dart';
import 'screens/sign_in_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key, this.authService});

  final AuthService? authService;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  StreamSubscription<AuthSessionSnapshot>? _sessionSubscription;
  late bool _isSignedIn;
  bool _isGuest = false;
  String? _email;

  @override
  void initState() {
    super.initState();
    _isSignedIn = widget.authService?.hasActiveSession ?? false;
    _email = widget.authService?.currentUserEmail;
    _sessionSubscription = widget.authService?.sessionChanges.listen(
      _handleSessionChange,
    );
  }

  @override
  void dispose() {
    _sessionSubscription?.cancel();
    super.dispose();
  }

  void _handleSessionChange(AuthSessionSnapshot session) {
    if (!mounted) return;
    setState(() {
      _isSignedIn = session.isSignedIn;
      _email = session.email;
      if (_isSignedIn) _isGuest = false;
    });
  }

  Future<String?> _signIn(String email, String password) async {
    final service = _requireService();
    await service.signIn(email: email, password: password);
    if (mounted) {
      setState(() {
        _isSignedIn = true;
        _email = service.currentUserEmail;
      });
    }
    return null;
  }

  Future<String?> _signUp(String email, String password) async {
    final service = _requireService();
    final hasSession = await service.signUp(email: email, password: password);

    if (hasSession && mounted) {
      setState(() {
        _isSignedIn = true;
        _email = service.currentUserEmail;
      });
      return null;
    }

    return 'Check your email to confirm your account, then sign in.';
  }

  AuthService _requireService() {
    final service = widget.authService;
    if (service == null) {
      throw const AuthFailure(
        'Supabase configuration is missing. Guest mode is still available.',
      );
    }
    return service;
  }

  void _continueAsGuest() {
    setState(() {
      _isGuest = true;
      _isSignedIn = false;
      _email = null;
    });
  }

  Future<void> _leaveSession() async {
    if (_isGuest) {
      setState(() {
        _isGuest = false;
      });
      return;
    }

    final service = widget.authService;
    if (service == null) return;

    try {
      await service.signOut();
      if (!mounted) return;
      setState(() {
        _isSignedIn = false;
        _email = null;
      });
    } on AuthFailure catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isSignedIn || _isGuest) {
      return HomeScreen(
        isGuest: _isGuest,
        email: _email,
        onReturnToAuth: _leaveSession,
      );
    }

    return SignInScreen(
      onSignIn: _signIn,
      onSignUp: _signUp,
      onContinueAsGuest: _continueAsGuest,
    );
  }
}
