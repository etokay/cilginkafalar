import 'dart:math';

import 'package:flutter/material.dart';

import '../data/content.dart';
import '../game/engine.dart';

/// Maskot görselleri (GPT Image ile üretildi): `assets/mascots/{id}_{ruh hali}.webp`.
String mascotAsset(String id, Mood mood) => 'assets/mascots/${mascots.containsKey(id) ? id : 'pof'}_${mood.name}.webp';

/// Tüm maskot pozlarını önceden belleğe alır; ekran geçişlerinde boş kare görünmez.
Future<void> precacheMascots(BuildContext context) async {
  for (final id in mascotOrder) {
    for (final m in Mood.values) {
      await precacheImage(AssetImage(mascotAsset(id, m)), context);
    }
  }
  for (final f in ['logo', 'island', 'star', 'star_gold', 'bg_sky']) {
    if (!context.mounted) return;
    await precacheImage(AssetImage('assets/images/$f.webp'), context);
  }
}

/// Canlı maskot: nefes alma, sevinçte zıplama, üzgünken çökme; ruh hali değişince poz "pop" ile değişir.
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
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600));
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
    final img = Image.asset(
      mascotAsset(widget.id, widget.mood),
      key: ValueKey('${widget.id}-${widget.mood}'),
      width: widget.size,
      height: widget.size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      gaplessPlayback: true,
    );
    return Semantics(
      label: mascots[widget.id]?.name,
      image: true,
      child: SizedBox.square(
        dimension: widget.size,
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, child) {
            final t = reduce ? 0.0 : (_c.value + _seed) % 1.0;
            final celebrate = widget.mood == Mood.happy || widget.mood == Mood.victory;
            final breathe = sin(t * pi * 2);
            final dy = celebrate ? -(sin(t * pi * 4).abs()) * widget.size * .05 : breathe * widget.size * .01;
            final sx = 1 + breathe * .015, sy = 1 - breathe * .02;
            return Transform.translate(
              offset: Offset(0, dy),
              child: Transform(alignment: Alignment.bottomCenter, transform: Matrix4.diagonal3Values(sx, sy, 1), child: child),
            );
          },
          child: AnimatedSwitcher(
            duration: Duration(milliseconds: reduce ? 1 : 260),
            transitionBuilder: (c, a) => ScaleTransition(scale: Tween(begin: .85, end: 1.0).animate(CurvedAnimation(parent: a, curve: Curves.easeOutBack)), child: FadeTransition(opacity: a, child: c)),
            child: img,
          ),
        ),
      ),
    );
  }
}
