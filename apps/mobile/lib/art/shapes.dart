import 'dart:math';

import 'package:flutter/material.dart';

import '../data/content.dart';
import '../theme.dart';

Path symPath(SymShape s, Rect r) {
  final w = r.width, h = r.height, x = r.left, y = r.top;
  Offset p(double a, double b) => Offset(x + a * w, y + b * h);
  switch (s) {
    case SymShape.circle:
      return Path()..addOval(r.deflate(w * .1));
    case SymShape.triangle:
      return Path()
        ..moveTo(p(.5, .12).dx, p(.5, .12).dy)
        ..lineTo(p(.92, .84).dx, p(.92, .84).dy)
        ..lineTo(p(.08, .84).dx, p(.08, .84).dy)
        ..close();
    case SymShape.square:
      return Path()..addRRect(RRect.fromRectAndRadius(r.deflate(w * .16), Radius.circular(w * .12)));
    case SymShape.star:
      final path = Path();
      for (var i = 0; i < 10; i++) {
        final rr = i.isOdd ? w * .18 : w * .42, a = -pi / 2 + i * pi / 5;
        final o = Offset(r.center.dx + rr * cos(a), r.center.dy + h * .03 + rr * sin(a));
        i == 0 ? path.moveTo(o.dx, o.dy) : path.lineTo(o.dx, o.dy);
      }
      return path..close();
    case SymShape.heart:
      return Path()
        ..moveTo(p(.5, .84).dx, p(.5, .84).dy)
        ..cubicTo(p(.16, .6).dx, p(.16, .6).dy, p(.1, .36).dx, p(.1, .36).dy, p(.25, .26).dx, p(.25, .26).dy)
        ..cubicTo(p(.36, .18).dx, p(.36, .18).dy, p(.46, .24).dx, p(.46, .24).dy, p(.5, .34).dx, p(.5, .34).dy)
        ..cubicTo(p(.54, .24).dx, p(.54, .24).dy, p(.64, .18).dx, p(.64, .18).dy, p(.75, .26).dx, p(.75, .26).dy)
        ..cubicTo(p(.9, .36).dx, p(.9, .36).dy, p(.84, .6).dx, p(.84, .6).dy, p(.5, .84).dx, p(.5, .84).dy)
        ..close();
    case SymShape.moon:
      final outer = Path()..addOval(Rect.fromCircle(center: p(.46, .52), radius: w * .38));
      final inner = Path()..addOval(Rect.fromCircle(center: p(.66, .4), radius: w * .3));
      return Path.combine(PathOperation.difference, outer, inner);
  }
}

class SymbolIcon extends StatelessWidget {
  final SymShape shape;
  final Color color;
  final double size;
  const SymbolIcon(this.shape, {super.key, this.color = K.ink, this.size = 22});
  @override
  Widget build(BuildContext context) => CustomPaint(size: Size.square(size), painter: _SymPainter(shape, color));
}

class _SymPainter extends CustomPainter {
  final SymShape s;
  final Color col;
  _SymPainter(this.s, this.col);
  @override
  void paint(Canvas c, Size z) {
    final p = symPath(s, Offset.zero & z);
    c.drawPath(p, Paint()..color = col);
    c.drawPath(p, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(1.5, z.width * .07)
      ..strokeJoin = StrokeJoin.round
      ..color = K.ink);
  }

  @override
  bool shouldRepaint(_SymPainter o) => o.s != s || o.col != col;
}

enum GI { gear, sound, mute, back, fwd, copy, share, check, cross, crown, home, dice, people, warn, info, backspace, clock }

class GameIcon extends StatelessWidget {
  final GI icon;
  final Color color;
  final double size;
  const GameIcon(this.icon, {super.key, this.color = K.paper, this.size = 24});
  @override
  Widget build(BuildContext context) => ExcludeSemantics(child: CustomPaint(size: Size.square(size), painter: _IconPainter(icon, color)));
}

class _IconPainter extends CustomPainter {
  final GI i;
  final Color col;
  _IconPainter(this.i, this.col);
  @override
  void paint(Canvas c, Size z) {
    c.save();
    c.scale(z.width / 24);
    final st = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = col;
    final fl = Paint()..color = col;
    switch (i) {
      case GI.gear:
        c.drawCircle(const Offset(12, 12), 3.4, st);
        for (var k = 0; k < 8; k++) {
          final a = k * pi / 4;
          c.drawLine(Offset(12 + 6.4 * cos(a), 12 + 6.4 * sin(a)), Offset(12 + 9.4 * cos(a), 12 + 9.4 * sin(a)), st..strokeWidth = 3);
        }
        c.drawCircle(const Offset(12, 12), 6.6, st..strokeWidth = 2.6);
      case GI.sound:
      case GI.mute:
        c.drawPath(
            Path()
              ..moveTo(4, 9.5)
              ..lineTo(7.5, 9.5)
              ..lineTo(12, 5)
              ..lineTo(12, 19)
              ..lineTo(7.5, 14.5)
              ..lineTo(4, 14.5)
              ..close(),
            fl);
        if (i == GI.sound) {
          c.drawArc(const Rect.fromLTWH(11.5, 9, 6, 6), -pi / 2.4, pi / 1.2, false, st);
          c.drawArc(const Rect.fromLTWH(10, 5.5, 11, 13), -pi / 2.4, pi / 1.2, false, st);
        } else {
          c.drawLine(const Offset(15.5, 9.5), const Offset(20.5, 14.5), st);
          c.drawLine(const Offset(20.5, 9.5), const Offset(15.5, 14.5), st);
        }
      case GI.back:
        c.drawPath(Path()..moveTo(15, 5)..lineTo(8, 12)..lineTo(15, 19), st..strokeWidth = 3.2);
      case GI.fwd:
        c.drawPath(Path()..moveTo(9, 5)..lineTo(16, 12)..lineTo(9, 19), st..strokeWidth = 3.2);
      case GI.copy:
        c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(8, 8, 12, 12), const Radius.circular(3)), st);
        c.drawPath(Path()..moveTo(16, 6)..lineTo(16, 5)..quadraticBezierTo(16, 4, 14, 4)..lineTo(6, 4)..quadraticBezierTo(4, 4, 4, 6)..lineTo(4, 14)..quadraticBezierTo(4, 16, 6, 16), st);
      case GI.share:
        c.drawLine(const Offset(12, 15), const Offset(12, 3.5), st);
        c.drawPath(Path()..moveTo(7, 8)..lineTo(12, 3)..lineTo(17, 8), st);
        c.drawPath(Path()..moveTo(5, 13)..lineTo(5, 18)..quadraticBezierTo(5, 20, 7, 20)..lineTo(17, 20)..quadraticBezierTo(19, 20, 19, 18)..lineTo(19, 13), st);
      case GI.check:
        c.drawPath(Path()..moveTo(5, 12.5)..lineTo(9.5, 17)..lineTo(19, 7), st..strokeWidth = 3.6);
      case GI.cross:
        c.drawLine(const Offset(6, 6), const Offset(18, 18), st..strokeWidth = 3.6);
        c.drawLine(const Offset(18, 6), const Offset(6, 18), st);
      case GI.crown:
        final p = Path()..moveTo(2.5, 18)..lineTo(4, 6)..lineTo(9, 11)..lineTo(12, 3.5)..lineTo(15, 11)..lineTo(20, 6)..lineTo(21.5, 18)..close();
        c.drawPath(p, Paint()..color = K.sun);
        c.drawPath(p, Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8
          ..strokeJoin = StrokeJoin.round
          ..color = K.ink);
      case GI.home:
        c.drawPath(Path()..moveTo(4, 11)..lineTo(12, 4)..lineTo(20, 11)..lineTo(20, 20)..lineTo(15, 20)..lineTo(15, 14)..lineTo(9, 14)..lineTo(9, 20)..lineTo(4, 20)..close(), st);
      case GI.dice:
        c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(3, 3, 18, 18), const Radius.circular(5)), st);
        for (final o in const [Offset(8.5, 8.5), Offset(12, 12), Offset(15.5, 15.5)]) {
          c.drawCircle(o, 1.8, fl);
        }
      case GI.people:
        c.drawCircle(const Offset(8, 8), 3.5, fl);
        c.drawCircle(const Offset(16.5, 9), 3, fl);
        c.drawPath(Path()..moveTo(1.5, 20)..cubicTo(2, 16, 4.8, 14, 8, 14)..cubicTo(11.2, 14, 14, 16, 14.5, 20)..close(), fl);
        c.drawPath(Path()..moveTo(15, 20)..cubicTo(15, 17.5, 14.5, 16, 13.4, 14.8)..cubicTo(17, 13.6, 21, 15.5, 21.5, 20)..close(), fl);
      case GI.warn:
        final p = Path()..moveTo(12, 3)..lineTo(22, 20)..lineTo(2, 20)..close();
        c.drawPath(p, Paint()..color = const Color(0xFFFFB3C1));
        c.drawPath(p, Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..strokeJoin = StrokeJoin.round
          ..color = K.ink);
        c.drawLine(const Offset(12, 9), const Offset(12, 14), Paint()
          ..strokeWidth = 2.6
          ..strokeCap = StrokeCap.round
          ..color = K.ink);
        c.drawCircle(const Offset(12, 17), 1.4, Paint()..color = K.ink);
      case GI.info:
        c.drawCircle(const Offset(12, 12), 10, Paint()..color = K.sky);
        c.drawLine(const Offset(12, 11), const Offset(12, 17), Paint()
          ..strokeWidth = 2.6
          ..strokeCap = StrokeCap.round
          ..color = K.ink);
        c.drawCircle(const Offset(12, 7.5), 1.5, Paint()..color = K.ink);
      case GI.backspace:
        c.drawPath(Path()..moveTo(8, 5)..lineTo(20, 5)..lineTo(20, 19)..lineTo(8, 19)..lineTo(2.5, 12)..close(), st);
        c.drawLine(const Offset(11, 9), const Offset(17, 15), st);
        c.drawLine(const Offset(17, 9), const Offset(11, 15), st);
      case GI.clock:
        c.drawCircle(const Offset(12, 13), 8, st);
        c.drawPath(Path()..moveTo(12, 9)..lineTo(12, 13)..lineTo(15, 15), st);
    }
    c.restore();
  }

  @override
  bool shouldRepaint(_IconPainter o) => o.i != i || o.col != col;
}

/// Uçan ada (ana menü ve açılış).
class IslandPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size z) {
    c.save();
    c.scale(z.width / 300, z.height / 200);
    final rock = Path()
      ..moveTo(30, 88)
      ..quadraticBezierTo(150, 114, 270, 88)
      ..quadraticBezierTo(252, 146, 190, 166)
      ..quadraticBezierTo(160, 196, 128, 170)
      ..quadraticBezierTo(62, 150, 30, 88)
      ..close();
    c.drawPath(rock, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [Color(0xFF6A4ACF), Color(0xFF241A5C)]).createShader(rock.getBounds()));
    c.drawPath(Path()..moveTo(120, 150)..lineTo(130, 180)..lineTo(138, 154)..moveTo(170, 150)..lineTo(176, 172)..lineTo(182, 152), Paint()..color = const Color(0xFF3B2794));
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(222, 94, 11, 80), const Radius.circular(5)),
        Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [K.sky, Color(0x0044C9F8)]).createShader(const Rect.fromLTWH(222, 94, 11, 80)));
    const grassR = Rect.fromLTWH(28, 66, 244, 44);
    c.drawOval(grassR, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF6FF0C9), Color(0xFF1FA79A)]).createShader(grassR));
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(66, 56, 6, 22), const Radius.circular(3)), Paint()..color = const Color(0xFF5B3A22));
    c.drawCircle(const Offset(69, 50), 16, Paint()..color = K.pink);
    c.drawCircle(const Offset(63, 45), 5, Paint()..color = const Color(0xFFFFC7E3));
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(236, 60, 5, 18), const Radius.circular(2.5)), Paint()..color = const Color(0xFF5B3A22));
    c.drawCircle(const Offset(238, 54), 13, Paint()..color = K.sun);
    c.drawCircle(const Offset(200, 80), 4, Paint()..color = K.sun);
    c.drawCircle(const Offset(104, 82), 3.5, Paint()..color = K.pink);
    c.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
