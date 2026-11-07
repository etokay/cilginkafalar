import 'dart:math';

import 'package:flutter/material.dart';

import '../data/content.dart';
import '../game/engine.dart';

/// Altı maskotun vektör çizimi (200×200 tasarım ızgarası).
/// Üretimde Rive/sprite varlıklarıyla değiştirilebilir; arayüz aynı kalır.
class MascotPainter extends CustomPainter {
  final String id;
  final Mood mood;
  final double blink; // 0 açık, 1 kapalı
  final double wave; // kalkık kolların salınım açısı (radyan)
  MascotPainter(this.id, this.mood, {this.blink = 0, this.wave = 0});

  late Canvas c;
  late MascotDef m;

  Paint _grad(Rect r) => Paint()
    ..shader = RadialGradient(center: const Alignment(-.28, -.44), radius: .78, colors: [m.light, m.base, m.dark], stops: const [0, .48, 1])
        .createShader(r.inflate(2));
  Paint _stroke([double w = 4, Color? col]) => Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = w
    ..color = col ?? m.line
    ..strokeJoin = StrokeJoin.round
    ..strokeCap = StrokeCap.round;
  Paint _fill(Color col) => Paint()..color = col;

  void _shape(Path p, {Paint? fill, double sw = 4}) {
    c.drawPath(p, fill ?? _grad(p.getBounds()));
    c.drawPath(p, _stroke(sw));
  }

  Path _oval(double cx, double cy, double rx, double ry, [double deg = 0]) {
    final p = Path()..addOval(Rect.fromCenter(center: Offset(cx, cy), width: rx * 2, height: ry * 2));
    if (deg == 0) return p;
    final a = deg * pi / 180;
    final mtx = Matrix4.identity()
      ..translateByDouble(cx, cy, 0, 1)
      ..rotateZ(a)
      ..translateByDouble(-cx, -cy, 0, 1);
    return p.transform(mtx.storage);
  }

  Path _fur(double cx, double cy, double r, int n, double amp) {
    final p = Path();
    for (var i = 0; i < n; i++) {
      final a0 = i / n * pi * 2 - pi / 2, a1 = (i + 1) / n * pi * 2 - pi / 2, am = (a0 + a1) / 2;
      if (i == 0) p.moveTo(cx + r * cos(a0), cy + r * sin(a0));
      p.quadraticBezierTo(cx + (r + amp * 2) * cos(am), cy + (r + amp * 2) * sin(am), cx + r * cos(a1), cy + r * sin(a1));
    }
    return p..close();
  }

  void _limb(Path p, double outer, double inner, Color col) {
    c.drawPath(p, _stroke(outer));
    c.drawPath(p, _stroke(inner, col));
  }

  void _eye(double x, double y, double r, {bool closed = false}) {
    final shut = closed || blink > .5;
    if (shut) {
      final p = Path()
        ..moveTo(x - r * .8, y + 2)
        ..quadraticBezierTo(x, y - (closed ? r * .95 : 0), x + r * .8, y + 2);
      c.drawPath(p, _stroke(r * .3));
      return;
    }
    var px = x + r * .12, py = y - r * .05, pr = r * .56;
    if (mood == Mood.think) {
      px = x - r * .28;
      py = y - r * .3;
    } else if (mood == Mood.sad) {
      px = x;
      py = y + r * .22;
    } else if (mood == Mood.surprised) {
      pr = r * .36;
    }
    c.drawCircle(Offset(x, y), r, _fill(Colors.white));
    c.drawCircle(Offset(x, y), r, _stroke(3));
    c.drawCircle(Offset(px, py), pr, _fill(const Color(0xFF20173D)));
    c.drawCircle(Offset(px + pr * .36, py - pr * .38), pr * .34, _fill(Colors.white));
  }

  void _mouth(double x, double y, double w) {
    switch (mood) {
      case Mood.sad:
        c.drawPath(
            Path()
              ..moveTo(x - w * .28, y + w * .22)
              ..quadraticBezierTo(x, y - w * .06, x + w * .28, y + w * .22),
            _stroke(4));
        return;
      case Mood.think:
        final r = Rect.fromCenter(center: Offset(x + w * .18, y + w * .12), width: w * .24, height: w * .2);
        c.drawOval(r, _fill(const Color(0xFF4A1236)));
        c.drawOval(r, _stroke(2.5));
        return;
      case Mood.surprised:
        final r = Rect.fromCenter(center: Offset(x, y + w * .2), width: w * .34, height: w * .46);
        c.drawOval(r, _fill(const Color(0xFF4A1236)));
        c.drawOval(r, _stroke(3));
        return;
      default:
        final idle = mood == Mood.idle;
        final d = idle ? .6 : .85, ww = idle ? w * .8 : w;
        final p = Path()
          ..moveTo(x - ww / 2, y)
          ..quadraticBezierTo(x, y + ww * d * 1.15, x + ww / 2, y)
          ..close();
        c.save();
        c.drawPath(p, _fill(const Color(0xFF4A1236)));
        c.clipPath(p);
        c.drawRect(Rect.fromLTWH(x - ww * .32, y, ww * .64, ww * .12), _fill(const Color(0xFFFFF3D6)));
        c.drawOval(Rect.fromCenter(center: Offset(x, y + ww * d * .5), width: ww * .36, height: ww * .2), _fill(const Color(0xFFFF7FA0)));
        c.restore();
        c.drawPath(p, _stroke(3));
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    c = canvas;
    m = mascots[id] ?? mascots['pof']!;
    final up = mood == Mood.happy || mood == Mood.victory;
    final closed = mood == Mood.victory;
    c.save();
    c.scale(size.width / 200, size.height / 200);
    c.drawOval(Rect.fromCenter(center: const Offset(100, 194), width: 108, height: 12), _fill(const Color(0x59080420)));
    final wv = wave * 180 / pi;
    switch (id) {
      case 'pof':
        _shape(_oval(76, 182, 17, 10), fill: _fill(m.dark));
        _shape(_oval(124, 182, 17, 10), fill: _fill(m.dark));
        if (up) {
          _shape(_rot(_fur(34, 80, 22, 9, 3), 34, 110, -wv));
          _shape(_rot(_fur(166, 80, 22, 9, 3), 166, 110, wv));
        } else {
          _shape(_fur(38, 132, 20, 9, 3));
          _shape(_fur(162, 132, 20, 9, 3));
        }
        _shape(_fur(100, 118, 62, 22, 4.5));
        c.drawOval(Rect.fromCenter(center: const Offset(100, 150), width: 68, height: 44), _fill(m.light.withValues(alpha: .35)));
        _eye(80, 100, 15, closed: closed);
        _eye(120, 100, 15, closed: closed);
        _mouth(100, 130, 50);
        c.drawPath(
            Path()
              ..moveTo(46, 74)
              ..quadraticBezierTo(100, 46, 154, 74),
            _stroke(9, const Color(0xFF6B3E1F)));
        for (final x in [79.0, 121.0]) {
          c.drawCircle(Offset(x, 62), 16, _fill(const Color(0xFF8BE6FF)));
          c.drawCircle(Offset(x, 62), 16, _stroke(5, const Color(0xFF6B3E1F)));
          c.drawPath(
              Path()
                ..moveTo(x - 8, 58)
                ..quadraticBezierTo(x - 4, 52, x + 2, 52),
              _stroke(3, Colors.white));
        }
      case 'cakir':
        final flame = Path()
          ..moveTo(52, 112)
          ..cubicTo(44, 78, 56, 52, 62, 30)
          ..cubicTo(72, 50, 80, 58, 86, 62)
          ..cubicTo(86, 44, 92, 26, 100, 10)
          ..cubicTo(108, 26, 116, 44, 114, 62)
          ..cubicTo(122, 56, 130, 48, 140, 30)
          ..cubicTo(146, 52, 156, 78, 148, 112)
          ..close();
        _shape(flame,
            fill: Paint()
              ..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [Color(0xFFFFE45C), Color(0xFFFFB02B), Color(0xFFFF8A2C)], stops: [0, .6, 1]).createShader(flame.getBounds()));
        _shape(_oval(80, 180, 14, 9), fill: _fill(m.dark));
        _shape(_oval(120, 180, 14, 9), fill: _fill(m.dark));
        void arm(double x0, double x1, double y1, double mx, double my) {
          final p = Path()
            ..moveTo(x0, 126)
            ..quadraticBezierTo(mx, my, x1, y1);
          _limb(p, 12, 6, m.dark);
          final h = Path()..addOval(Rect.fromCircle(center: Offset(x1, y1), radius: 9));
          _shape(h, sw: 3);
        }
        if (up) {
          final dy = sin(wave) * 8;
          arm(48, 22, 92 + dy, 30, 118);
          arm(152, 178, 92 - dy, 170, 118);
        } else {
          arm(48, 30, 162, 34, 146);
          arm(152, 170, 162, 166, 146);
        }
        _shape(Path()..addOval(Rect.fromCircle(center: const Offset(100, 122), radius: 58)));
        final bolt = Path()
          ..moveTo(168, 52)
          ..relativeLineTo(-8, 14)
          ..relativeLineTo(8, 0)
          ..relativeLineTo(-5, 12)
          ..relativeLineTo(14, -18)
          ..relativeLineTo(-8, 0)
          ..relativeLineTo(5, -8)
          ..close();
        _shape(bolt, fill: _fill(const Color(0xFFFFCB2B)), sw: 2.5);
        c.drawLine(const Offset(24, 56), const Offset(34, 62), _stroke(4, const Color(0xFFFFCB2B)));
        c.drawLine(const Offset(20, 70), const Offset(32, 72), _stroke(4, const Color(0xFFFFCB2B)));
        c.drawLine(const Offset(66, 92), const Offset(92, 99), _stroke(5));
        c.drawLine(const Offset(134, 92), const Offset(108, 99), _stroke(5));
        _eye(80, 113, 13, closed: closed);
        _eye(120, 113, 13, closed: closed);
        _mouth(100, 140, 38);
      case 'minti':
        final leaf1 = Path()
          ..moveTo(98, 66)
          ..cubicTo(80, 56, 68, 38, 72, 18)
          ..cubicTo(92, 24, 104, 44, 98, 66)
          ..close();
        final leaf2 = Path()
          ..moveTo(104, 66)
          ..cubicTo(110, 44, 128, 30, 148, 32)
          ..cubicTo(144, 52, 126, 66, 104, 66)
          ..close();
        _shape(leaf1, fill: _fill(const Color(0xFF7BE36E)), sw: 3.5);
        _shape(leaf2, fill: _fill(const Color(0xFF4FBF55)), sw: 3.5);
        _shape(_oval(80, 182, 14, 9), fill: _fill(m.dark));
        _shape(_oval(120, 182, 14, 9), fill: _fill(m.dark));
        final armP = up
            ? (Path()
              ..moveTo(46, 124)
              ..quadraticBezierTo(28, 112, 26, 92 + sin(wave) * 6))
            : (Path()
              ..moveTo(46, 130)
              ..quadraticBezierTo(30, 142, 30, 160));
        _limb(armP, 14, 8, m.base);
        _shape(Path()..addOval(Rect.fromCircle(center: const Offset(100, 120), radius: 60)));
        final coat = Path()
          ..moveTo(70, 168)
          ..lineTo(100, 152)
          ..lineTo(130, 168)
          ..lineTo(132, 176)
          ..quadraticBezierTo(100, 186, 68, 176)
          ..close();
        _shape(coat, fill: _fill(const Color(0xFFF4F7FF)), sw: 3);
        c.drawLine(const Offset(150, 140), const Offset(160, 152), _stroke(10));
        final bag = Path()..addRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(146, 150, 38, 28), const Radius.circular(7)));
        _shape(bag, fill: _fill(const Color(0xFF9A633D)), sw: 3);
        c.drawPath(
            Path()
              ..moveTo(155, 150)
              ..quadraticBezierTo(165, 138, 175, 150),
            _stroke(3));
        c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(160, 160, 10, 6), const Radius.circular(2)), _fill(const Color(0xFF35D9C9)));
        _eye(80, 108, 13, closed: closed);
        _eye(120, 108, 13, closed: closed);
        for (final x in [80.0, 120.0]) {
          c.drawCircle(Offset(x, 108), 20, _fill(Colors.white.withValues(alpha: .14)));
          c.drawCircle(Offset(x, 108), 20, _stroke(5, const Color(0xFF183A2C)));
        }
        c.drawLine(const Offset(60, 104), const Offset(52, 100), _stroke(4, const Color(0xFF183A2C)));
        c.drawLine(const Offset(140, 104), const Offset(148, 100), _stroke(4, const Color(0xFF183A2C)));
        _mouth(100, 140, 34);
        if (up) {
          c.drawCircle(const Offset(150, 22), 12, _fill(const Color(0xFFFFE45C)));
          c.drawCircle(const Offset(150, 22), 12, _stroke(3));
          c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(145, 33, 10, 7), const Radius.circular(2)), _fill(const Color(0xFFB9A6F2)));
        }
      case 'bidik':
        if (up) {
          _shape(_oval(34, 96, 12, 22, -28 - wv));
          _shape(_oval(166, 96, 12, 22, 28 + wv));
        } else {
          _shape(_oval(36, 138, 12, 20, 20));
          _shape(_oval(164, 138, 12, 20, -20));
        }
        final body = Path()
          ..moveTo(100, 38)
          ..cubicTo(142, 38, 160, 80, 162, 120)
          ..cubicTo(165, 166, 140, 190, 100, 190)
          ..cubicTo(60, 190, 35, 166, 38, 120)
          ..cubicTo(40, 80, 58, 38, 100, 38)
          ..close();
        _shape(body);
        c.drawPath(_oval(78, 62, 16, 9, -25), _fill(Colors.white.withValues(alpha: .55)));
        c.drawOval(Rect.fromCenter(center: const Offset(64, 130), width: 24, height: 16), _fill(const Color(0xB3FF8FA6)));
        c.drawOval(Rect.fromCenter(center: const Offset(136, 130), width: 24, height: 16), _fill(const Color(0xB3FF8FA6)));
        _eye(80, 104, 16, closed: closed);
        _eye(120, 104, 16, closed: closed);
        _mouth(100, 136, 44);
      case 'pika':
        final tail = Path()
          ..moveTo(146, 152)
          ..cubicTo(190, 152, 196, 104, 168, 100)
          ..cubicTo(148, 98, 146, 128, 164, 128);
        _limb(tail, 22, 14, m.base);
        _shape(_oval(74, 182, 14, 9), fill: _fill(m.dark));
        _shape(_oval(116, 182, 14, 9), fill: _fill(m.dark));
        if (up) {
          final a = Path()
            ..moveTo(40, 128)
            ..quadraticBezierTo(24, 108, 30, 88 + sin(wave) * 6);
          _limb(a, 13, 7, m.base);
        }
        _shape(_oval(96, 122, 62, 60));
        c.drawOval(Rect.fromCenter(center: const Offset(96, 156), width: 64, height: 40), _fill(const Color(0xBFFF8C8A)));
        c.drawCircle(const Offset(130, 150), 5, _fill(const Color(0xFF35D9C9)));
        c.drawCircle(const Offset(62, 160), 4, _fill(const Color(0xFF35D9C9)));
        _eye(74, 110, 20, closed: closed);
        _eye(122, 108, 13, closed: closed || mood == Mood.happy);
        _mouth(98, 146, 36);
        c.drawPath(
            Path()
              ..moveTo(36, 112)
              ..quadraticBezierTo(36, 46, 96, 44)
              ..quadraticBezierTo(156, 46, 156, 112),
            _stroke(8, const Color(0xFF20173D)));
        final cap = Path()
          ..moveTo(54, 76)
          ..quadraticBezierTo(96, 28, 140, 76)
          ..close();
        _shape(cap, fill: _fill(const Color(0xFF35D9C9)));
        final brim = Path()
          ..moveTo(118, 72)
          ..quadraticBezierTo(152, 64, 172, 78)
          ..quadraticBezierTo(148, 86, 118, 80)
          ..close();
        _shape(brim, fill: _fill(const Color(0xFF1FA79A)), sw: 3);
        for (final x in [24.0, 146.0]) {
          final cup = Path()..addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x, 98, 22, 34), const Radius.circular(10)));
          _shape(cup, fill: _fill(const Color(0xFF35D9C9)), sw: 3);
        }
      case 'zipzip':
        final glow = 0.25 + 0.15 * sin(wave * 2).abs();
        for (final pr in [(84.0, 68.0), (116.0, 132.0)]) {
          c.drawLine(Offset(pr.$1, 52), Offset(pr.$2, 18), _stroke(4));
          c.drawCircle(Offset(pr.$2, 16), 15, _fill(const Color(0xFF35D9C9).withValues(alpha: glow)));
          c.drawCircle(Offset(pr.$2, 16), 9, _fill(const Color(0xFF35D9C9)));
          c.drawCircle(Offset(pr.$2, 16), 9, _stroke(3));
        }
        for (final pr in [(86.0, -1.0), (114.0, 1.0)]) {
          final x = pr.$1, s = pr.$2;
          final leg = Path()
            ..moveTo(x, 162)
            ..lineTo(x - 8 * s, 170)
            ..lineTo(x + 6 * s, 176)
            ..lineTo(x - 8 * s, 182)
            ..lineTo(x + 2 * s, 188);
          c.drawPath(leg, _stroke(5, m.dark));
          _shape(_oval(x + 4 * s, 191, 12, 6), fill: _fill(m.dark), sw: 3);
        }
        if (up) {
          final dy = sin(wave) * 6;
          c.drawLine(const Offset(54, 116), Offset(30, 90 + dy), _stroke(10));
          c.drawLine(const Offset(146, 116), Offset(170, 90 - dy), _stroke(10));
          for (final o in [Offset(29, 88 + dy), Offset(171, 88 - dy)]) {
            _shape(Path()..addOval(Rect.fromCircle(center: o, radius: 8)), fill: _fill(m.base), sw: 3);
          }
        } else {
          c.drawLine(const Offset(54, 120), const Offset(34, 146), _stroke(10));
          c.drawLine(const Offset(146, 120), const Offset(166, 146), _stroke(10));
        }
        _shape(Path()..addRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(52, 44, 96, 124), const Radius.circular(48))));
        for (final o in const [Offset(88, 62), Offset(100, 58), Offset(112, 62)]) {
          c.drawCircle(o, 3.5, _fill(const Color(0xFF35D9C9)));
        }
        c.drawCircle(const Offset(100, 152), 7, _fill(const Color(0xFF35D9C9)));
        c.drawCircle(const Offset(100, 152), 7, _stroke(2.5));
        c.drawPath(
            Path()
              ..moveTo(68, 80)
              ..quadraticBezierTo(80, 70, 92, 77)
              ..moveTo(108, 80)
              ..lineTo(132, 73),
            _stroke(4.5));
        _eye(82, 96, 14, closed: closed);
        _eye(118, 96, 14, closed: closed);
        _mouth(100, 122, 36);
    }
    if (mood == Mood.sad && id != 'cakir' && id != 'zipzip') {
      final y = id == 'pika' ? 84.0 : 78.0;
      c.drawLine(Offset(68, y), Offset(82, y - 5), _stroke(4));
      c.drawLine(Offset(132, y), Offset(118, y - 5), _stroke(4));
    }
    c.restore();
  }

  Path _rot(Path p, double cx, double cy, double deg) {
    if (deg == 0) return p;
    final mtx = Matrix4.identity()
      ..translateByDouble(cx, cy, 0, 1)
      ..rotateZ(deg * pi / 180)
      ..translateByDouble(-cx, -cy, 0, 1);
    return p.transform(mtx.storage);
  }

  @override
  bool shouldRepaint(MascotPainter o) => o.id != id || o.mood != mood || o.blink != blink || o.wave != wave;
}

/// Canlı maskot: nefes alma (squash), göz kırpma, sevinçte zıplama ve kol sallama.
class Mascot extends StatefulWidget {
  final String id;
  final Mood mood;
  final double size;
  final bool animate;
  const Mascot(this.id, {super.key, this.mood = Mood.idle, this.size = 120, this.animate = true});
  @override
  State<Mascot> createState() => _MascotState();
}

class _MascotState extends State<Mascot> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2800));
  final _seed = Random().nextDouble();

  @override
  void initState() {
    super.initState();
    if (widget.animate) _c.repeat();
  }

  @override
  void didUpdateWidget(Mascot old) {
    super.didUpdateWidget(old);
    if (widget.animate && !_c.isAnimating) _c.repeat();
    if (!widget.animate && _c.isAnimating) _c.stop();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return Semantics(
      label: mascots[widget.id]?.name,
      image: true,
      child: SizedBox.square(
        dimension: widget.size,
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, _) {
            final t = reduce ? 0.0 : (_c.value + _seed) % 1.0;
            final celebrate = widget.mood == Mood.happy || widget.mood == Mood.victory;
            final breathe = sin(t * pi * 2);
            final jump = celebrate ? -(sin(t * pi * 4).abs()) * widget.size * .06 : breathe * widget.size * .012;
            final sx = 1 + breathe * .02, sy = 1 - breathe * .025;
            final sad = widget.mood == Mood.sad ? widget.size * .02 : 0.0;
            final blink = (t > .46 && t < .5) ? 1.0 : 0.0;
            return Transform.translate(
              offset: Offset(0, jump + sad),
              child: Transform(
                alignment: Alignment.bottomCenter,
                transform: Matrix4.diagonal3Values(sx, sy, 1),
                child: CustomPaint(
                  painter: MascotPainter(widget.id, widget.mood, blink: blink, wave: celebrate ? sin(t * pi * 4) * .35 : 0),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
