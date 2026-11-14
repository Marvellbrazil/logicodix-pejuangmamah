import 'package:flutter/material.dart';

import '../application/api_failure.dart';
import '../application/ask_assistant.dart';
import '../domain/profile.dart';
import '../infrastructure/google_token_provider.dart';
import 'app_state.dart';
import 'app_theme.dart';
import 'auth_screen.dart';
import 'home_shell.dart';
import 'landing_screen.dart';
import 'onboarding_screen.dart';

class KerjaqueueApp extends StatelessWidget {
  const KerjaqueueApp({
    super.key,
    required this.state,
    required this.askAssistant,
    required this.google,
  });

  final AppState state;
  final AskAssistant askAssistant;
  final GoogleTokenProvider google;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kerjaqueue',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      darkTheme: buildAppTheme(),
      themeMode: ThemeMode.dark,
      scrollBehavior: const _AppScrollBehavior(),
      home: _SplashGate(
        state: state,
        askAssistant: askAssistant,
        google: google,
      ),
    );
  }
}

class _AppScrollBehavior extends MaterialScrollBehavior {
  const _AppScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) => child;
}

class _SplashGate extends StatefulWidget {
  const _SplashGate({
    required this.state,
    required this.askAssistant,
    required this.google,
  });

  final AppState state;
  final AskAssistant askAssistant;
  final GoogleTokenProvider google;

  @override
  State<_SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<_SplashGate> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    setState(() => _ready = true);
    await widget.state.boot();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 320),
      switchInCurve: Curves.easeOut,
      child: !_ready
          ? const _BrandSplash(key: ValueKey('splash'))
          : _Root(
              key: const ValueKey('root'),
              state: widget.state,
              askAssistant: widget.askAssistant,
              google: widget.google,
            ),
    );
  }
}

class _BrandSplash extends StatelessWidget {
  const _BrandSplash({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Surfaces.base,
      body: Center(
        child: Semantics(
          label: 'Kerjaqueue sedang dibuka',
          liveRegion: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 82,
                height: 82,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Accent.teal, Accent.tealDeep],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(26),
                ),
                child: const Icon(
                  Icons.work_history_outlined,
                  size: 42,
                  color: Accent.tealInk,
                ),
              ),
              const SizedBox(height: Space.xl),
              Text(
                'Kerjaqueue',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: Space.xs + 2),
              Text(
                'Kerja dekat, peluang terbuka.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: Space.xxl),
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Root extends StatefulWidget {
  const _Root({
    super.key,
    required this.state,
    required this.askAssistant,
    required this.google,
  });

  final AppState state;
  final AskAssistant askAssistant;
  final GoogleTokenProvider google;

  @override
  State<_Root> createState() => _RootState();
}

class _RootState extends State<_Root> {
  bool _showAuth = false;
  bool _startRegistering = false;
  String? _landingError;

  Future<bool> _google(UserRole role) async {
    final idToken = await widget.google.requestIdToken();
    if (idToken == null) throw const ApiFailure('Google tidak mengirim token.');
    return widget.state.signInWithGoogle(idToken: idToken, role: role);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.state,
      builder: (context, _) {
        final state = widget.state;
        if (state.booting) return const _BrandSplash();
        if (!state.signedIn) {
          if (!_showAuth) {
            return LandingScreen(
              onLogin: () => setState(() {
                _startRegistering = false;
                _landingError = null;
                _showAuth = true;
              }),
              onRegister: () => setState(() {
                _startRegistering = true;
                _landingError = null;
                _showAuth = true;
              }),
              onGoogle: (role) async {
                try {
                  final ok = await _google(role);
                  if (!ok && mounted) {
                    setState(() {
                      _landingError = state.authError;
                      _startRegistering = false;
                      _showAuth = true;
                    });
                  }
                } on ApiFailure catch (error) {
                  if (mounted) {
                    setState(() {
                      _landingError = error.message;
                      _startRegistering = false;
                      _showAuth = true;
                    });
                  }
                }
              },
            );
          }
          return AuthScreen(
            key: const ValueKey('auth'),
            state: state,
            onGoogle: _google,
            onBack: () => setState(() => _showAuth = false),
            initialRegistering: _startRegistering,
            initialError: _landingError,
          );
        }
        if (state.needsOnboarding) {
          return OnboardingScreen(state: state);
        }
        return HomeShell(state: state, askAssistant: widget.askAssistant);
      },
    );
  }
}
