import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/particles.dart';

import '../theme.dart';

final _rng = Random();
double _r(double a, double b) => a + _rng.nextDouble() * (b - a);

Path _star(double r) {
  final p = Path();
  for (var i = 0; i < 10; i++) {
    final rr = i.isOdd ? r * .45 : r, a = -pi / 2 + i * pi / 5;
    i == 0 ? p.moveTo(rr * cos(a), rr * sin(a)) : p.lineTo(rr * cos(a), rr * sin(a));
  }
  return p..close();
}

/// Arka plan: gece moru gökyüzü, parlayan yıldızlar, yavaş süzülen adacıklar.
class SkyGame extends FlameGame {
  bool reduceMotion = false;
  @override
  Color backgroundColor() => K.navy;

  @override
  Future<void> onLoad() async {
    add(_Backdrop());
    add(_StarField());
    for (var i = 0; i < 4; i++) {
      add(_Drifter(i));
    }
  }
}

class _Backdrop extends Component with HasGameReference<SkyGame> {
  @override
  void render(Canvas c) {
    final r = Offset.zero & Size(game.size.x, game.size.y);
    c.drawRect(r, Paint()
      ..shader = Gradient.linear(r.topCenter, r.bottomCenter, const [Color(0xFF2D2378), K.navy, Color(0xFF1C1450)], const [0, .46, 1]));
    c.drawOval(Rect.fromCenter(center: Offset(game.size.x * .1, game.size.y * .95), width: 260, height: 80), Paint()..color = const Color(0x803B2C8F));
    c.drawOval(Rect.fromCenter(center: Offset(game.size.x * .9, game.size.y * 1.0), width: 300, height: 100), Paint()..color = const Color(0x733B2C8F));
  }
}

class _StarField extends Component with HasGameReference<SkyGame> {
  final _stars = List.generate(56, (_) => (_r(0, 1), _r(0, .72), _r(.6, 1.9), _r(0, pi * 2)));
  double t = 0;
  @override
  void update(double dt) {
    if (!game.reduceMotion) t += dt;
  }

  @override
  void render(Canvas c) {
    final p = Paint()..color = const Color(0xFFFFFFFF);
    for (final s in _stars) {
      final a = .35 + .45 * (0.5 + 0.5 * sin(t * 1.6 + s.$4));
      p.color = Color.fromRGBO(255, 255, 255, a);
      c.drawCircle(Offset(s.$1 * game.size.x, s.$2 * game.size.y), s.$3, p);
    }
  }
}

class _Drifter extends PositionComponent with HasGameReference<SkyGame> {
  final int i;
  late double speed;
  _Drifter(this.i);
  @override
  void onMount() {
    super.onMount();
    position = Vector2(_r(0, game.size.x), game.size.y * (.14 + i * .17));
    speed = _r(4, 10) * (i.isEven ? 1 : -1);
    size = Vector2(_r(36, 64), 0);
  }

  @override
  void update(double dt) {
    if (game.reduceMotion) return;
    x += speed * dt;
    if (x > game.size.x + 80) x = -80;
    if (x < -80) x = game.size.x + 80;
  }

  @override
  void render(Canvas c) {
    final w = size.x;
    final p = Path()
      ..moveTo(-w / 2, 0)
      ..quadraticBezierTo(0, -w * .32, w / 2, 0)
      ..quadraticBezierTo(w * .2, w * .5, 0, w * .55)
      ..quadraticBezierTo(-w * .2, w * .5, -w / 2, 0)
      ..close();
    c.drawPath(p, Paint()..color = const Color(0x664A3AA8));
    c.drawOval(Rect.fromCenter(center: Offset.zero, width: w, height: w * .22), Paint()..color = const Color(0x5535D9C9));
  }
}

/// Ön plan efektleri: yıldız patlaması, konfeti, balon yağmuru, muz kabuğu.
/// Dokunmaları engellememesi için IgnorePointer içinde gösterilir.
class FxGame extends FlameGame {
  bool reduceMotion = false;
  @override
  Color backgroundColor() => const Color(0x00000000);

  void stars([Vector2? at]) {
    if (reduceMotion || size.x == 0) return;
    final o = at ?? Vector2(size.x / 2, size.y * .42);
    add(ParticleSystemComponent(
      position: o,
      particle: Particle.generate(
        count: 22,
        lifespan: .9,
        generator: (i) {
          final a = i / 22 * pi * 2 + _r(-.1, .1), sp = _r(160, 300);
          return AcceleratedParticle(
            speed: Vector2(cos(a), sin(a)) * sp,
            acceleration: Vector2(0, 260),
            child: ComputedParticle(renderer: (c, p) {
              final s = 11 * (1 - p.progress) + 3;
              c.save();
              c.rotate(p.progress * pi);
              c.drawPath(_star(s), Paint()..color = K.sun.withValues(alpha: 1 - p.progress * .7));
              c.restore();
            }),
          );
        },
      ),
    ));
  }

  void confetti([int count = 90]) {
    if (reduceMotion || size.x == 0) return;
    const cols = [K.sun, K.pink, K.aqua, K.sky, K.orange, K.violet5];
    add(ParticleSystemComponent(
      particle: Particle.generate(
        count: count,
        lifespan: 2.6,
        generator: (i) {
          final col = cols[i % cols.length], spin = _r(-8, 8), w = _r(6, 11);
          return AcceleratedParticle(
            position: Vector2(_r(0, size.x), _r(-60, -10)),
            speed: Vector2(_r(-50, 50), _r(80, 240)),
            acceleration: Vector2(0, 140),
            child: ComputedParticle(renderer: (c, p) {
              c.save();
              c.rotate(spin * p.progress);
              c.scale(cos(p.progress * 18).abs() * .8 + .2, 1);
              c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: w, height: w * 1.5), const Radius.circular(2)),
                  Paint()..color = col);
              c.restore();
            }),
          );
        },
      ),
    ));
  }

  void balloons() {
    if (reduceMotion || size.x == 0) return;
    const cols = [K.pink, K.sun, K.sky, K.aqua];
    for (var i = 0; i < 10; i++) {
      final left = i.isOdd;
      add(_Balloon(
        Vector2(left ? _r(10, 50) : _r(size.x - 50, size.x - 10), size.y + 60 + i * 34),
        cols[i % 4],
      ));
    }
  }

  void banana() {
    if (reduceMotion || size.x == 0) return;
    add(_Peel(Vector2(-40, size.y - 120)));
  }
}

class _Balloon extends PositionComponent with HasGameReference<FxGame> {
  final Color color;
  double t = 0;
  final double phase = _r(0, pi * 2), baseX;
  _Balloon(Vector2 p, this.color)
      : baseX = p.x,
        super(position: p);
  @override
  void update(double dt) {
    t += dt;
    y -= 230 * dt;
    x = baseX + sin(t * 3 + phase) * 8;
    if (y < -80) removeFromParent();
  }

  @override
  void render(Canvas c) {
    c.drawPath(Path()..moveTo(0, 22)..quadraticBezierTo(5, 34, -2, 46), Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = const Color(0xCCFFF8FF));
    final r = Rect.fromCenter(center: Offset.zero, width: 34, height: 42);
    c.drawOval(r, Paint()..color = color);
    c.drawOval(r, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..color = K.ink);
    c.drawOval(Rect.fromCenter(center: const Offset(-7, -9), width: 8, height: 12), Paint()..color = const Color(0x99FFFFFF));
    c.drawPath(Path()..moveTo(-4, 21)..lineTo(4, 21)..lineTo(0, 26)..close(), Paint()..color = color);
  }
}

class _Peel extends PositionComponent with HasGameReference<FxGame> {
  double t = 0;
  _Peel(Vector2 p) : super(position: p);
  @override
  void update(double dt) {
    t += dt;
    x += 420 * dt;
    angle += 9 * dt;
    if (x > game.size.x + 60) removeFromParent();
  }

  @override
  void render(Canvas c) {
    final fill = Paint()..color = K.sun;
    final st = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeJoin = StrokeJoin.round
      ..color = K.ink;
    for (final a in [-1.1, 0.0, 1.1]) {
      c.save();
      c.rotate(a);
      final p = Path()..moveTo(0, 0)..quadraticBezierTo(10, -10, 4, -28)..quadraticBezierTo(-6, -12, 0, 0)..close();
      c.drawPath(p, fill);
      c.drawPath(p, st);
      c.restore();
    }
    c.drawCircle(Offset.zero, 6, Paint()..color = const Color(0xFFE0A81C));
    c.drawCircle(Offset.zero, 6, st);
  }
}
