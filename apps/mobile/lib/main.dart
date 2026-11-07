import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'fx/flame_layers.dart';
import 'game/engine.dart';
import 'theme.dart';
import 'ui/screens_entry.dart';
import 'ui/screens_match.dart';
import 'ui/sheets.dart';
import 'ui/widgets.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
  runApp(const CilginKafalarApp());
}

class CilginKafalarApp extends StatefulWidget {
  const CilginKafalarApp({super.key});
  @override
  State<CilginKafalarApp> createState() => _CilginKafalarAppState();
}

class _CilginKafalarAppState extends State<CilginKafalarApp> {
  final engine = GameEngine();
  @override
  void initState() {
    super.initState();
    // Web'de ?ekran=S08 gibi bağlantılarla doğrudan bir ekrana açılır (test/inceleme için).
    final q = Uri.base.queryParameters['ekran']?.toUpperCase();
    final jumps = <String, void Function()>{
      'S02': () => engine.jump(Scr.menu),
      'S03': () => engine.jump(Scr.pick),
      'S04': () => engine.openRoom(true),
      'S05': () => engine.jump(Scr.lobby),
      'S06': () => engine.jump(Scr.prefs),
      'S07': () => engine.jump(Scr.intro),
      'S08': () => engine.jump(Scr.round, type: RoundType.knowing),
      'S09': () => engine.jump(Scr.round, type: RoundType.fact),
      'S10': () => engine.jump(Scr.round, type: RoundType.shamata),
      'S11': () => engine.jump(Scr.result),
      'S12': () => engine.jump(Scr.finale),
      'S13': () => engine.jump(Scr.settings),
    };
    (jumps[q] ?? engine.startSplash)();
  }

  @override
  void dispose() {
    engine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GameScope(
        engine: engine,
        child: MaterialApp(
          title: 'ÇILGIN KAFALAR!',
          debugShowCheckedModeBanner: false,
          theme: buildTheme(),
          home: const Stage(),
        ),
      );
}

/// Geniş ekranda (web/tablet) telefon çerçevesi + test paneli; telefonda tam ekran.
class Stage extends StatelessWidget {
  const Stage({super.key});
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final wide = size.width >= 900 && size.height >= 600;
    if (!wide) return const Scaffold(body: GameShell());
    final scale = ((size.height - 48) / 844).clamp(.6, 1.0);
    return Scaffold(
      backgroundColor: K.deep,
      body: Center(
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          SizedBox(
            width: 300,
            child: SingleChildScrollView(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('ÇILGIN KAFALAR!', style: T.display(30, color: K.sun)),
                const SizedBox(height: 8),
                Text('Flutter + Flame prototipi, sürüm 0.1. Diğer oyuncular bu cihazda simüle edilir; gerçek sunucu bağlı değil. Bilgi soruları editör onayı bekleyen örnek içeriktir.',
                    style: T.body(14, color: K.lilac, height: 1.5)),
                const SizedBox(height: 18),
                const TestPanel(),
              ]),
            ),
          ),
          const SizedBox(width: 56),
          SizedBox(
            width: 414 * scale,
            height: 868 * scale,
            child: FittedBox(
              child: Container(
                width: 414,
                height: 868,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0E0A2A),
                  borderRadius: BorderRadius.circular(58),
                  boxShadow: const [BoxShadow(color: Color(0xFF2D2470), spreadRadius: 2), BoxShadow(color: Color(0x99050214), blurRadius: 80, offset: Offset(0, 40))],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(46),
                  child: MediaQuery(
                    data: MediaQuery.of(context).copyWith(size: const Size(390, 844), padding: const EdgeInsets.only(top: 44, bottom: 30), viewPadding: const EdgeInsets.only(top: 44, bottom: 30)),
                    child: const GameShell(),
                  ),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class GameShell extends StatefulWidget {
  const GameShell({super.key});
  @override
  State<GameShell> createState() => _GameShellState();
}

class _GameShellState extends State<GameShell> {
  final sky = SkyGame();
  final fx = FxGame();
  StreamSubscription<FxEvent>? _fxSub;
  StreamSubscription<String>? _toastSub;
  String? _toast;
  Timer? _toastTimer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_fxSub != null) return;
    final g = GameScope.read(context);
    _fxSub = g.fx.listen((e) {
      switch (e.kind) {
        case FxKind.stars:
          fx.stars();
        case FxKind.confetti:
          fx.confetti();
        case FxKind.balloons:
          fx.balloons();
        case FxKind.banana:
          fx.banana();
        case FxKind.shake:
          if (g.settings.haptics) HapticFeedback.mediumImpact();
      }
    });
    _toastSub = g.toasts.listen((m) {
      _toastTimer?.cancel();
      setState(() => _toast = m);
      _toastTimer = Timer(const Duration(milliseconds: 2600), () => mounted ? setState(() => _toast = null) : null);
    });
  }

  @override
  void dispose() {
    _fxSub?.cancel();
    _toastSub?.cancel();
    _toastTimer?.cancel();
    super.dispose();
  }

  Widget _screen(GameEngine g) => switch (g.screen) {
        Scr.splash => const SplashScreen(),
        Scr.menu => const MenuScreen(),
        Scr.room => const RoomScreen(),
        Scr.pick => const PickScreen(),
        Scr.lobby => const LobbyScreen(),
        Scr.prefs => const PrefsScreen(),
        Scr.prefsWait => const PrefsWaitScreen(),
        Scr.intro => const IntroScreen(),
        Scr.round => const RoundScreen(),
        Scr.result => const ResultScreen(),
        Scr.finale => const FinaleScreen(),
        Scr.settings => const SettingsScreen(),
      };

  @override
  Widget build(BuildContext context) {
    final g = GameScope.of(context);
    final reduce = g.settings.reduceMotion || (MediaQuery.maybeDisableAnimationsOf(context) ?? false);
    sky.reduceMotion = reduce;
    fx.reduceMotion = reduce || !g.settings.effects && g.screen == Scr.round;
    final key = ValueKey('${g.screen.name}-${g.roundIndex}-${g.round?.memorizing}');
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: reduce),
      child: Stack(children: [
        Positioned.fill(child: GameWidget(game: sky)),
        Positioned.fill(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: AnimatedSwitcher(
                duration: Duration(milliseconds: reduce ? 1 : 320),
                switchInCurve: Curves.easeOutBack,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (c, a) => FadeTransition(
                  opacity: a,
                  child: ScaleTransition(scale: Tween(begin: .94, end: 1.0).animate(a), child: c),
                ),
                child: KeyedSubtree(key: key, child: _screen(g)),
              ),
            ),
          ),
        ),
        Positioned.fill(child: IgnorePointer(child: GameWidget(game: fx))),
        if (_toast != null)
          Positioned(
            left: 20,
            right: 20,
            bottom: MediaQuery.paddingOf(context).bottom + 20,
            child: Semantics(
              liveRegion: true,
              child: Enter(
                key: ValueKey(_toast),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: K.paper,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: const [BoxShadow(color: Color(0xFF3B2794), offset: Offset(0, 5)), BoxShadow(color: Color(0x80050214), blurRadius: 24)],
                  ),
                  child: Text(_toast!, style: T.body(15, color: K.ink, w: 800)),
                ),
              ),
            ),
          ),
        if (g.reconnecting)
          Positioned.fill(
            child: Container(
              color: const Color(0xE6140D3C),
              alignment: Alignment.center,
              padding: const EdgeInsets.all(30),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const SizedBox(width: 56, height: 56, child: CircularProgressIndicator(strokeWidth: 6, color: K.sun)),
                const SizedBox(height: 18),
                Text('Bağlantı koptu', style: T.display(24)),
                const SizedBox(height: 6),
                Text('Yeniden bağlanıyor. Oyun seni bekliyor.', textAlign: TextAlign.center, style: T.body(15, color: K.lilac)),
              ]),
            ),
          ),
      ]),
    );
  }
}
