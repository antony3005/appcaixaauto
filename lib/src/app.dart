import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'data/client_repository.dart';
import 'data/session_store.dart';
import 'features/auth/login_page.dart';
import 'features/shell/client_shell.dart';
import 'state/client_controller.dart';
import 'state/theme_controller.dart';

class App247Client extends StatefulWidget {
  const App247Client({
    required this.repository,
    super.key,
    this.sessionStore,
    this.themeController,
  });
  final ClientRepository repository;
  final SessionStore? sessionStore;
  final ThemeController? themeController;

  @override
  State<App247Client> createState() => _App247ClientState();
}

class _App247ClientState extends State<App247Client> {
  late final ClientController controller = ClientController(
    widget.repository,
    sessionStore: widget.sessionStore,
  );
  late final ThemeController themeController =
      widget.themeController ?? ThemeController();

  @override
  void initState() {
    super.initState();
    if (widget.sessionStore == null) {
      controller.initialized = true;
      themeController.initialized = true;
    } else {
      controller.initialize();
      themeController.initialize();
    }
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
      builder: (context, _) => MaterialApp(
        title: 'App 24/7',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: themeController.mode,
        home: !controller.initialized || !themeController.initialized
            ? const _AppLaunchPage()
            : controller.session == null
            ? LoginPage(controller: controller)
            : ClientShell(
                controller: controller,
                themeController: themeController,
              ),
      ),
    );
  }
}

class _AppLaunchPage extends StatelessWidget {
  const _AppLaunchPage();

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: Semantics(
          label: 'Carregando App 24/7',
          child: SizedBox.square(
            dimension: 44,
            child: CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ),
    ),
  );
}
