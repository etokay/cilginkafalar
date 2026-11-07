import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../art/mascot_painter.dart';
import '../art/shapes.dart';
import '../data/content.dart';
import '../game/engine.dart';
import '../theme.dart';

class GameScope extends InheritedNotifier<GameEngine> {
  const GameScope({super.key, required GameEngine engine, required super.child}) : super(notifier: engine);
  static GameEngine of(BuildContext c) => c.dependOnInheritedWidgetOfExactType<GameScope>()!.notifier!;
  static GameEngine read(BuildContext c) => (c.getElementForInheritedWidgetOfExactType<GameScope>()!.widget as GameScope).notifier!;
}

void tapFeedback(BuildContext context) {
  if (GameScope.read(context).settings.haptics) HapticFeedback.selectionClick();
}

/// Kalın, alt kenarı "3D" basılan oyun butonu. Her şey CustomPainter ile çizilir.
class GameButton extends StatefulWidget {
  final String? label;
  final Widget? child;
  final VoidCallback? onTap;
  final Color color;
  final Color? textColor;
  final double height, radius, depth;
  final bool selected, dimmed, expand;
  final String? semanticLabel;
  final bool radio;
  final double hPad;
  const GameButton({super.key, this.label, this.child, required this.onTap, this.color = K.sun, this.textColor, this.height = 60,
      this.radius = 24, this.depth = 6, this.selected = false, this.dimmed = false, this.expand = true, this.semanticLabel, this.radio = false, this.hPad = 14});

  const GameButton.secondary({super.key, this.label, this.child, required this.onTap, this.height = 56, this.radius = 24, this.expand = true, this.semanticLabel})
      : color = K.btnViolet,
        textColor = K.paper,
        depth = 6,
        selected = false,
        dimmed = false,
        radio = false,
        hPad = 14;

  const GameButton.ghost({super.key, this.label, this.child, required this.onTap, this.height = 52, this.radius = 22, this.expand = true, this.semanticLabel})
      : color = const Color(0xFF3A2D86),
        textColor = K.paper,
        depth = 5,
        selected = false,
        dimmed = false,
        radio = false,
        hPad = 14;

  @override
  State<GameButton> createState() => _GameButtonState();
}

class _GameButtonState extends State<GameButton> with SingleTickerProviderStateMixin {
  late final AnimationController _p = AnimationController(vsync: this, duration: const Duration(milliseconds: 110));
  bool _focus = false;

  @override
  void dispose() {
    _p.dispose();
    super.dispose();
  }

  void _fire() {
    if (widget.onTap == null) return;
    tapFeedback(context);
    widget.onTap!();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    final face = enabled ? widget.color : const Color(0xFF4A3E8A);
    final fg = enabled ? (widget.textColor ?? K.ink) : K.paper.withValues(alpha: .55);
    final content = widget.child ??
        Text(widget.label ?? '', textAlign: TextAlign.center, style: T.display(20, color: fg).copyWith(letterSpacing: .6));
    return Semantics(
      button: !widget.radio,
      inMutuallyExclusiveGroup: widget.radio,
      checked: widget.radio ? widget.selected : null,
      enabled: enabled,
      label: widget.semanticLabel ?? widget.label,
      excludeSemantics: widget.semanticLabel != null || widget.label != null,
      child: FocusableActionDetector(
        enabled: enabled,
        mouseCursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        onShowFocusHighlight: (v) => setState(() => _focus = v),
        actions: {ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) => _fire())},
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: enabled ? (_) => _p.forward() : null,
          onTapUp: enabled
              ? (_) {
                  _p.reverse();
                  _fire();
                }
              : null,
          onTapCancel: () => _p.reverse(),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: widget.dimmed ? .45 : 1,
            child: AnimatedBuilder(
              animation: _p,
              builder: (_, child) {
                final d = widget.depth * (1 - _p.value);
                return SizedBox(
                  width: widget.expand ? double.infinity : null,
                  height: widget.height + widget.depth,
                  child: CustomPaint(
                    painter: _BtnPainter(face, widget.radius, d, widget.depth, widget.selected, _focus),
                    child: Padding(
                      padding: EdgeInsets.only(top: widget.depth - d, bottom: d, left: widget.hPad, right: widget.hPad),
                      child: Center(widthFactor: widget.expand ? null : 1, child: child),
                    ),
                  ),
                );
              },
              child: DefaultTextStyle(style: T.body(18, color: fg, w: 900), child: content),
            ),
          ),
        ),
      ),
    );
  }
}

class _BtnPainter extends CustomPainter {
  final Color face;
  final double radius, d, depth;
  final bool selected, focus;
  _BtnPainter(this.face, this.radius, this.d, this.depth, this.selected, this.focus);
  @override
  void paint(Canvas c, Size s) {
    final h = s.height - depth;
    final edgeR = RRect.fromRectAndRadius(Rect.fromLTWH(0, depth, s.width, h), Radius.circular(radius));
    final faceR = RRect.fromRectAndRadius(Rect.fromLTWH(0, depth - d, s.width, h), Radius.circular(radius));
    if (selected) {
      c.drawRRect(faceR.inflate(8), Paint()..color = K.violet5);
      c.drawRRect(faceR.inflate(4), Paint()..color = K.paper);
    }
    c.drawRRect(edgeR.shift(const Offset(0, 4)), Paint()
      ..color = const Color(0x55080420)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
    c.drawRRect(edgeR, Paint()..color = K.edge(face));
    c.drawRRect(faceR, Paint()..color = face);
    // glossy highlight
    c.save();
    c.clipRRect(faceR);
    final gloss = Rect.fromLTWH(6, faceR.top + 3, s.width - 12, h * .42);
    c.drawRRect(RRect.fromRectAndRadius(gloss, Radius.circular(radius * .8)), Paint()
      ..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [Colors.white.withValues(alpha: .38), Colors.white.withValues(alpha: 0)]).createShader(gloss));
    c.restore();
    c.drawRRect(faceR.deflate(1.5), Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Colors.white.withValues(alpha: .22));
    if (focus) {
      c.drawRRect(faceR.inflate(5), Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = K.sun);
    }
  }

  @override
  bool shouldRepaint(_BtnPainter o) => o.face != face || o.d != d || o.selected != selected || o.focus != focus;
}

/// Kare/küçük ikon butonu.
class IconTap extends StatelessWidget {
  final GI icon;
  final VoidCallback? onTap;
  final String label;
  final Color color, iconColor;
  final double size;
  const IconTap(this.icon, {super.key, required this.onTap, required this.label, this.color = const Color(0xFF3A2D86), this.iconColor = K.paper, this.size = 48});
  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        child: GameButton(onTap: onTap, color: color, height: size - 4, depth: 4, radius: 16, hPad: 0, semanticLabel: label, child: GameIcon(icon, color: iconColor)),
      );
}

/// Cevap kartı: renk + sabit şekil işareti (renk körlüğü), seçim halkası.
class AnswerTile extends StatefulWidget {
  final int index;
  final String text;
  final VoidCallback? onTap;
  final bool selected, dimmed, tall;
  final Widget? marker;
  const AnswerTile({super.key, required this.index, required this.text, this.onTap, this.selected = false, this.dimmed = false, this.tall = false, this.marker});
  @override
  State<AnswerTile> createState() => _AnswerTileState();
}

class _AnswerTileState extends State<AnswerTile> with SingleTickerProviderStateMixin {
  late final AnimationController _pop = AnimationController(vsync: this, duration: const Duration(milliseconds: 380));
  @override
  void didUpdateWidget(AnswerTile old) {
    super.didUpdateWidget(old);
    if (widget.selected && !old.selected) _pop.forward(from: 0);
  }

  @override
  void dispose() {
    _pop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final col = K.answer[widget.index % 4];
    final badge = Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: .62), shape: BoxShape.circle),
      alignment: Alignment.center,
      child: widget.marker ?? SymbolIcon(answerShapes[widget.index % 4], size: 20),
    );
    final text = Text(widget.text, textAlign: widget.tall ? TextAlign.center : TextAlign.left, style: T.body(18, color: K.ink, w: 900, height: 1.15));
    return AnimatedBuilder(
      animation: _pop,
      builder: (_, child) => Transform.scale(scale: 1 + sin(_pop.value * pi) * .06, child: child),
      child: GameButton(
        onTap: widget.onTap,
        color: col,
        radius: 20,
        height: widget.tall ? 104 : 64,
        selected: widget.selected,
        dimmed: widget.dimmed,
        radio: true,
        semanticLabel: widget.text,
        child: widget.tall
            ? Column(mainAxisSize: MainAxisSize.min, children: [badge, const SizedBox(height: 8), text])
            : Row(children: [badge, const SizedBox(width: 12), Expanded(child: text)]),
      ),
    );
  }
}

class QuestionCard extends StatelessWidget {
  final String text;
  final double size;
  final EdgeInsets padding;
  const QuestionCard(this.text, {super.key, this.size = 23, this.padding = const EdgeInsets.fromLTRB(20, 22, 20, 24)});
  @override
  Widget build(BuildContext context) => CustomPaint(
        painter: _CardPainter(),
        child: Padding(
          padding: padding,
          child: Center(
            child: Text(text, textAlign: TextAlign.center, style: T.display(size * (GameScope.of(context).settings.largeText ? 1.12 : 1), color: K.ink, w: 700, height: 1.18)),
          ),
        ),
      );
}

class _CardPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final r = RRect.fromRectAndRadius(Offset.zero & s, const Radius.circular(24));
    c.drawRRect(r.shift(const Offset(0, 10)), Paint()
      ..color = const Color(0x66080420)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12));
    c.drawRRect(r.inflate(3), Paint()..color = K.violet5.withValues(alpha: .6));
    c.drawRRect(r, Paint()..color = K.paper);
    final p = Paint()..color = K.sun;
    for (final o in [Offset(s.width - 18, 14), const Offset(16, 0)]) {
      c.save();
      c.translate(o.dx, o.dy + (o.dx < 20 ? s.height - 14 : 0));
      final path = Path();
      for (var i = 0; i < 8; i++) {
        final rr = i.isOdd ? 2.2 : 6.5, a = i * pi / 4;
        i == 0 ? path.moveTo(rr * cos(a), rr * sin(a)) : path.lineTo(rr * cos(a), rr * sin(a));
      }
      c.drawPath(path..close(), p);
      c.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}

class GPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final Color? tint;
  const GPanel({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.tint});
  @override
  Widget build(BuildContext context) => Container(
        padding: padding,
        decoration: BoxDecoration(
          color: (tint ?? K.violet7).withValues(alpha: .42),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: (tint ?? K.lilac).withValues(alpha: .22), width: 2),
        ),
        child: child,
      );
}

class Pill extends StatelessWidget {
  final String text;
  final Color? color;
  final Widget? leading;
  const Pill(this.text, {super.key, this.color, this.leading});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: color ?? Colors.white.withValues(alpha: .1), borderRadius: BorderRadius.circular(999)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (leading != null) ...[leading!, const SizedBox(width: 6)],
          Text(text, style: T.body(13, w: 900).copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
        ]),
      );
}

class TimerRing extends StatelessWidget {
  final double remaining, total;
  const TimerRing({super.key, required this.remaining, required this.total});
  @override
  Widget build(BuildContext context) {
    final low = remaining <= 5;
    final sec = remaining.ceil();
    return Semantics(
      label: 'Kalan süre $sec saniye',
      child: SizedBox.square(
        dimension: 58,
        child: CustomPaint(
          painter: _RingPainter(remaining / total, low),
          child: Center(
            child: AnimatedScale(
              scale: low ? 1.15 : 1,
              duration: const Duration(milliseconds: 200),
              child: Text('$sec', style: T.display(22, color: low ? K.orange : K.paper).copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double f;
  final bool low;
  _RingPainter(this.f, this.low);
  @override
  void paint(Canvas c, Size s) {
    final r = (Offset.zero & s).deflate(5);
    c.drawCircle(r.center, r.width / 2 + 4, Paint()..color = const Color(0x55080420));
    c.drawArc(r, 0, pi * 2, false, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..color = Colors.white.withValues(alpha: .15));
    c.drawArc(r, -pi / 2, pi * 2 * f.clamp(0, 1), false, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..color = low ? K.orange : K.sun);
  }

  @override
  bool shouldRepaint(_RingPainter o) => o.f != f || o.low != low;
}

/// Harfleri tek tek dalgalanan, katmanlı (extrude) logo.
class Logo extends StatefulWidget {
  final double size;
  final bool animate;
  const Logo({super.key, this.size = 44, this.animate = true});
  @override
  State<Logo> createState() => _LogoState();
}

class _LogoState extends State<Logo> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))..repeat();
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Widget _word(String w, Color face, List<Color> extrude, int offset) {
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < w.length; i++)
          AnimatedBuilder(
            animation: _c,
            builder: (_, child) {
              final dy = (!widget.animate || reduce) ? 0.0 : sin(_c.value * pi * 2 + (i + offset) * .55) * widget.size * .06;
              return Transform.translate(offset: Offset(0, dy), child: child);
            },
            child: Stack(children: [
              for (var k = extrude.length; k >= 1; k--)
                Transform.translate(
                  offset: Offset(0, k * widget.size * .045),
                  child: Text(w[i], style: T.display(widget.size, color: extrude[k - 1], height: .95)),
                ),
              Text(w[i], style: T.display(widget.size, color: face, height: .95)),
            ]),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => Semantics(
        header: true,
        label: 'ÇILGIN KAFALAR!',
        child: ExcludeSemantics(
          child: Transform.rotate(
            angle: -4 * pi / 180,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              _word('ÇILGIN', K.sun, const [Color(0xFFF1A72C), Color(0xFFE0891F), K.violet7, K.violet7, Color(0xFF3B2794)], 0),
              _word('KAFALAR!', K.paper, const [Color(0xFFE6DAFF), Color(0xFFB9A6F2), K.violet7, K.violet7, Color(0xFF3B2794)], 6),
            ]),
          ),
        ),
      );
}

class Avatar extends StatelessWidget {
  final Player p;
  final bool done, showName;
  final Mood mood;
  final double size;
  final bool slip;
  const Avatar(this.p, {super.key, this.done = false, this.showName = true, this.mood = Mood.idle, this.size = 52, this.slip = false});
  @override
  Widget build(BuildContext context) {
    Widget m = Mascot(p.mascot, mood: mood, size: size - 4);
    if (slip) {
      m = TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 1100),
        builder: (_, v, child) {
          final a = v < .4 ? -v / .4 * 1.4 : v < .7 ? -1.4 : -1.4 * (1 - (v - .7) / .3);
          return Transform.rotate(angle: a, alignment: Alignment.bottomCenter, child: child);
        },
        child: m,
      );
    }
    return Semantics(
      label: '${p.label}${done ? ', cevapladı' : ''}',
      child: ExcludeSemantics(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Stack(clipBehavior: Clip.none, children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: .1),
                border: Border.all(color: done ? K.aqua : K.lilac.withValues(alpha: .25), width: done ? 3 : 2),
              ),
              alignment: Alignment.center,
              child: m,
            ),
            if (done)
              Positioned(
                right: -4,
                bottom: -4,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(color: K.aqua, shape: BoxShape.circle, border: Border.all(color: K.navy, width: 2)),
                  alignment: Alignment.center,
                  child: const GameIcon(GI.check, color: K.ink, size: 13),
                ),
              ),
          ]),
          if (showName)
            SizedBox(
              width: size + 6,
              child: Text(p.label, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: T.body(11, color: K.lilac, w: 800)),
            ),
        ]),
      ),
    );
  }
}

/// Oyun içi harf klavyesi (sistem klavyesi ve form alanları yerine).
class GameKeyboard extends StatelessWidget {
  final String keys;
  final void Function(String) onKey;
  final VoidCallback onBack;
  final VoidCallback? onSpace;
  const GameKeyboard({super.key, required this.keys, required this.onKey, required this.onBack, this.onSpace});
  @override
  Widget build(BuildContext context) {
    final items = <Widget>[
      for (final k in keys.split(''))
        GameButton(onTap: () => onKey(k), color: const Color(0xFFEDE4FF), height: 40, depth: 4, radius: 12, hPad: 0, semanticLabel: k,
            child: Text(k, style: T.display(19, color: K.ink))),
      if (onSpace != null)
        GameButton(onTap: onSpace, color: const Color(0xFFB9A6F2), height: 40, depth: 4, radius: 12, hPad: 0, semanticLabel: 'Boşluk',
            child: Container(width: 18, height: 4, decoration: BoxDecoration(color: K.ink, borderRadius: BorderRadius.circular(2)))),
      GameButton(onTap: onBack, color: K.pink, height: 40, depth: 4, radius: 12, hPad: 0, semanticLabel: 'Sil', child: const GameIcon(GI.backspace, color: K.ink, size: 20)),
    ];
    return LayoutBuilder(builder: (_, c) {
      const cols = 8, gap = 6.0;
      final w = (c.maxWidth - gap * (cols - 1)) / cols;
      return Wrap(spacing: gap, runSpacing: 6, children: [for (final i in items) SizedBox(width: w, child: i)]);
    });
  }
}

/// Harf kutucukları (oda kodu / takma ad önizlemesi).
class LetterSlots extends StatelessWidget {
  final String value;
  final int count;
  final bool error;
  const LetterSlots(this.value, {super.key, this.count = 6, this.error = false});
  @override
  Widget build(BuildContext context) => Semantics(
        label: value.isEmpty ? 'Oda kodu boş' : 'Oda kodu ${value.split('').join(' ')}',
        child: ExcludeSemantics(
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            for (var i = 0; i < count; i++) ...[
              if (i == 3) const SizedBox(width: 10),
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: 46,
                height: 58,
                decoration: BoxDecoration(
                  color: K.paper,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: error ? K.error : i == value.length ? K.violet5 : Colors.transparent, width: 3),
                  boxShadow: const [BoxShadow(color: Color(0xFF3B2794), offset: Offset(0, 4))],
                ),
                alignment: Alignment.center,
                child: Text(i < value.length ? value[i] : '', style: T.display(30, color: K.ink)),
              ),
            ],
          ]),
        ),
      );
}

class Banner2 extends StatelessWidget {
  final String text;
  final bool info;
  const Banner2(this.text, {super.key, this.info = false});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: (info ? K.sky : K.error).withValues(alpha: .16),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: (info ? K.sky : K.error).withValues(alpha: .6), width: 2),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          GameIcon(info ? GI.info : GI.warn, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: T.body(14, w: 800))),
        ]),
      );
}

/// Yanlış cevapta kısa sarsıntı.
class Shake extends StatelessWidget {
  final Widget child;
  final bool active;
  const Shake({super.key, required this.child, required this.active});
  @override
  Widget build(BuildContext context) {
    if (!active || (MediaQuery.maybeDisableAnimationsOf(context) ?? false)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 420),
      builder: (_, v, c) => Transform.translate(offset: Offset(sin(v * pi * 6) * 7 * (1 - v), 0), child: c),
      child: child,
    );
  }
}

/// Giriş animasyonu: hafif yukarı kayma + belirme.
class Enter extends StatelessWidget {
  final Widget child;
  final int delayMs;
  const Enter({super.key, required this.child, this.delayMs = 0});
  @override
  Widget build(BuildContext context) {
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 380 + delayMs),
      curve: Interval(delayMs / (380 + delayMs), 1, curve: Curves.easeOutBack),
      builder: (_, v, c) => Opacity(opacity: v.clamp(0, 1), child: Transform.translate(offset: Offset(0, (1 - v) * 18), child: c)),
      child: child,
    );
  }
}

class TopBar extends StatelessWidget {
  final Widget? left, right;
  final String? title;
  const TopBar({super.key, this.left, this.right, this.title});
  @override
  Widget build(BuildContext context) => SizedBox(
        height: 60,
        child: Row(children: [
          SizedBox(width: 60, child: Align(alignment: Alignment.centerLeft, child: left)),
          Expanded(
            child: title == null
                ? const SizedBox()
                : Semantics(header: true, child: Text(title!, textAlign: TextAlign.center, style: T.display(26))),
          ),
          SizedBox(width: 60, child: Align(alignment: Alignment.centerRight, child: right)),
        ]),
      );
}
