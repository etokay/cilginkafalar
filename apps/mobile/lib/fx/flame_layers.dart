import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
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

/// Arka plan: üretilmiş gökyüzü görseli (bg_sky.webp) + üstünde hafifçe parlayan yıldızlar.
class SkyGame extends FlameGame {
  bool reduceMotion = false;
  Sprite? bg;
  @override
  Color backgroundColor() => K.navy;

  @override
  Future<void> onLoad() async {
    bg = await Sprite.load('bg_sky.webp');
    add(_Backdrop());
    add(_StarField());
  }
}

class _Backdrop extends Component with HasGameReference<SkyGame> {
  @override
  void render(Canvas c) {
    final sp = game.bg;
    if (sp == null) return;
    // "cover" yerleşim: ekranı tamamen kaplar, oranı korur.
    final src = sp.srcSize, dst = game.size;
    final scale = max(dst.x / src.x, dst.y / src.y);
    final w = src.x * scale, h = src.y * scale;
    sp.render(c, position: Vector2((dst.x - w) / 2, (dst.y - h) / 2), size: Vector2(w, h));
    c.drawRect(Offset.zero & Size(dst.x, dst.y), Paint()..color = const Color(0x4D160F3B));
  }
}

class _StarField extends Component with HasGameReference<SkyGame> {
  final _stars = List.generate(26, (_) => (_r(0, 1), _r(0, .6), _r(.6, 1.6), _r(0, pi * 2)));
  double t = 0;
  @override
  void update(double dt) {
    if (!game.reduceMotion) t += dt;
  }

  @override
  void render(Canvas c) {
    final p = Paint();
    for (final s in _stars) {
      final a = .2 + .5 * (0.5 + 0.5 * sin(t * 1.6 + s.$4));
      p.color = Color.fromRGBO(255, 255, 255, a);
      c.drawCircle(Offset(s.$1 * game.size.x, s.$2 * game.size.y), s.$3, p);
    }
  }
}

/// Şamata mini oyunu: düşen yıldızlara dokun. Sarı yıldız 1, altın yıldız 3 puan.
class StarRainGame extends FlameGame {
  final void Function(int points) onCatch;
  bool running = false, reduceMotion = false;
  late Sprite _starSprite, _goldSprite;
  double _spawn = 0;
  StarRainGame({required this.onCatch});

  @override
  Color backgroundColor() => const Color(0x00000000);

  @override
  Future<void> onLoad() async {
    _starSprite = await Sprite.load('star.webp');
    _goldSprite = await Sprite.load('star_gold.webp');
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!running || size.x == 0) return;
    _spawn -= dt;
    if (_spawn <= 0) {
      _spawn = _r(.32, .55);
      final gold = _rng.nextDouble() < .15;
      final s = gold ? 74.0 : 60.0;
      add(_FallingStar(
        sprite: gold ? _goldSprite : _starSprite,
        points: gold ? 3 : 1,
        position: Vector2(_r(s / 2 + 6, size.x - s / 2 - 6), -s),
        size: Vector2.all(s),
        speed: (gold ? _r(230, 300) : _r(130, 220)) * (reduceMotion ? .65 : 1),
      ));
    }
  }

  void stop() {
    running = false;
    children.whereType<_FallingStar>().toList().forEach((c) => c.removeFromParent());
  }

  void burst(Vector2 at, bool gold) {
    add(ParticleSystemComponent(
      position: at,
      particle: Particle.generate(
        count: gold ? 18 : 10,
        lifespan: .5,
        generator: (i) {
          final a = i / (gold ? 18 : 10) * pi * 2;
          return AcceleratedParticle(
            speed: Vector2(cos(a), sin(a)) * _r(120, 220),
            child: ComputedParticle(renderer: (c, p) {
              c.drawPath(_star(6 * (1 - p.progress) + 2), Paint()..color = (gold ? K.orange : K.sun).withValues(alpha: 1 - p.progress));
            }),
          );
        },
      ),
    ));
  }
}

class _FallingStar extends SpriteComponent with TapCallbacks, HasGameReference<StarRainGame> {
  final int points;
  final double speed;
  final double _spin = _r(-1.5, 1.5);
  _FallingStar({required Sprite sprite, required this.points, required Vector2 position, required Vector2 size, required this.speed})
      : super(sprite: sprite, position: position, size: size, anchor: Anchor.center);

  @override
  void update(double dt) {
    y += speed * dt;
    angle += _spin * dt;
    if (y > game.size.y + size.y) removeFromParent();
  }

  @override
  bool containsLocalPoint(Vector2 point) {
    // Parmak için geniş dokunma alanı (görselden %25 büyük).
    final c = size / 2;
    return point.distanceTo(c) <= size.x * .62;
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (!game.running) return;
    game.onCatch(points);
    game.burst(position.clone(), points > 1);
    removeFromParent();
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
