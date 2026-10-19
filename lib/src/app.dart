import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/theme/app_theme.dart';
import 'data/client_repository.dart';
import 'data/session_store.dart';
import 'features/auth/login_page.dart';
import 'features/auth/registration_page.dart';
import 'features/auth/welcome_page.dart';
import 'features/shell/client_shell.dart';
import 'state/client_controller.dart';
import 'state/theme_controller.dart';

class App247Client extends StatefulWidget {
  const App247Client({
    required this.repository,
    super.key,
    this.sessionStore,
    this.themeController,
    this.clock,
  });
  final ClientRepository repository;
  final SessionStore? sessionStore;
  final ThemeController? themeController;
  final DateTime Function()? clock;

  @override
  State<App247Client> createState() => _App247ClientState();
}

class _App247ClientState extends State<App247Client> {
  static const _welcomeKey = 'app247.welcome_seen';

  final _navigatorKey = GlobalKey<NavigatorState>();
  late final ClientController controller = ClientController(
    widget.repository,
    sessionStore: widget.sessionStore,
    clock: widget.clock,
  );
  late final ThemeController themeController =
      widget.themeController ?? ThemeController();
  bool? _welcomeSeen;

  @override
  void initState() {
    super.initState();
    if (widget.sessionStore == null) {
      controller.initialized = true;
      themeController.initialized = true;
      _welcomeSeen = true;
    } else {
      controller.initialize();
      themeController.initialize();
      _loadWelcome();
    }
  }

  Future<void> _loadWelcome() async {
    var seen = true;
    try {
      seen = await SharedPreferencesAsync().getBool(_welcomeKey) ?? false;
    } catch (_) {
      // Sem storage, a apresentação não bloqueia o acesso.
    }
    if (mounted) setState(() => _welcomeSeen = seen);
  }

  Future<void> _finishWelcome({bool openRegistration = false}) async {
    setState(() => _welcomeSeen = true);
    try {
      await SharedPreferencesAsync().setBool(_welcomeKey, true);
    } catch (_) {
      // Mantém em memória quando o storage não está disponível.
    }
    if (!openRegistration) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navigatorKey.currentState?.push(
        MaterialPageRoute<void>(
          builder: (_) => RegistrationPage(repository: widget.repository),
        ),
      );
    });
  }

  @override
  void dispose() {
    controller.dispose();
    if (widget.themeController == null) themeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([controller, themeController]),
      builder: (context, _) {
        final restoring =
            !controller.initialized ||
            !themeController.initialized ||
            _welcomeSeen == null;
        return MaterialApp(
          navigatorKey: _navigatorKey,
          title: 'App 24/7',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: themeController.mode,
          locale: const Locale('pt', 'BR'),
          supportedLocales: const [Locale('pt', 'BR')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: AnimatedSwitcher(
            duration: AppAnimations.medium,
            switchInCurve: AppAnimations.standard,
            switchOutCurve: AppAnimations.exit,
            child: restoring
                ? const SplashPage(key: ValueKey('splash'))
                : controller.session != null
                ? ClientShell(
                    key: const ValueKey('shell'),
                    controller: controller,
                    themeController: themeController,
                  )
                : _welcomeSeen == false
                ? WelcomePage(
                    key: const ValueKey('welcome'),
                    onStart: () => _finishWelcome(openRegistration: true),
                    onLogin: _finishWelcome,
                  )
                : LoginPage(
                    key: const ValueKey('login'),
                    controller: controller,
                  ),
          ),
        );
      },
    );
  }
}

/// Abertura: navy com a marca enquanto a sessão é restaurada.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  bool _slow = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _slow = true);
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.navy,
    body: SafeArea(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _SplashMark(),
            const SizedBox(height: AppSpacing.s10),
            Semantics(
              label: 'Carregando App 24/7',
              liveRegion: true,
              child: SizedBox.square(
                dimension: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: context.semantic.gold,
                  backgroundColor: Colors.white.withValues(alpha: .15),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.s4),
            AnimatedSwitcher(
              duration: AppAnimations.medium,
              child: Text(
                _slow
                    ? 'A conexão está lenta. Ainda verificando sua sessão…'
                    : 'Verificando sua sessão…',
                key: ValueKey(_slow),
                textAlign: TextAlign.center,
                style: context.text.bodySmall?.copyWith(
                  color: AppColors.onNavyMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _SplashMark extends StatelessWidget {
  const _SplashMark();

  @override
  Widget build(BuildContext context) => Container(
    height: 56,
    padding: const EdgeInsets.symmetric(horizontal: 14),
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: AppColors.qrPaper,
      borderRadius: BorderRadius.circular(AppRadii.md),
    ),
    child: Text(
      '24/7',
      semanticsLabel: 'App 24/7',
      style: context.text.headlineSmall?.copyWith(color: AppColors.navy),
    ),
  );
}
