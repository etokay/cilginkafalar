import 'dart:math';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../art/mascot.dart';
import '../art/shapes.dart';
import '../data/content.dart';
import '../fx/flame_layers.dart';
import '../game/engine.dart';
import '../theme.dart';
import 'screens_entry.dart';
import 'sheets.dart';
import 'widgets.dart';

String catName(RoundType t) => t.title;

Color catColor(RoundType t) => switch (t.category) {
      Category.knowing => K.pink,
      Category.info => K.sky,
      Category.shamata => K.orange,
    };

SymShape answerShapesFor(int i) => const [SymShape.circle, SymShape.triangle, SymShape.square, SymShape.star][i % 4];

String fmtNum(double v) {
  final n = v.round();
  final s = '${n.abs()}';
  final b = StringBuffer(n < 0 ? '-' : '');
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write('.');
    b.write(s[i]);
  }
  return b.toString();
}

Widget _roundPills(GameEngine g, {Widget? right}) => SizedBox(
      height: 60,
      child: Row(children: [
        Pill('Tur ${g.roundIndex + 1}/12'),
        const SizedBox(width: 8),
        Flexible(child: Pill(catName(g.round!.type), color: catColor(g.round!.type).withValues(alpha: .28))),
        const Spacer(),
        ?right,
      ]),
    );

// ---------------- S07 Tur tanıtımı ----------------
class IntroScreen extends StatelessWidget {
  const IntroScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final g = GameScope.of(context);
    final r = g.round!;
    final tgt = r.targetId == null ? null : g.playerById(r.targetId!);
    final line = switch (r.type) {
      RoundType.knowing => tgt!.isMe ? 'Bu tur arkadaşların seni tahmin edecek.' : '${tgt.nick} ne cevap verdi, tahmin et.',
      RoundType.majority => 'Odadakilerin çoğu ne seçti? Kalabalığı tahmin et.',
      RoundType.fact => 'Bu bilgi gerçek mi, uydurma mı?',
      RoundType.estimate => 'Sayıyı tahmin et. En yakın tahmin en çok puanı alır.',
      RoundType.order => 'Dört şeyi doğru sıraya diz.',
      RoundType.memo => 'Ekrana iyi bak, sonra soruyu cevapla.',
      RoundType.starRain => 'Düşen yıldızlara dokun! Altın yıldız 3 sayar.',
    };
    final col = catColor(r.type);
    return Column(children: [
      SizedBox(height: 60, child: Row(children: [Pill('Tur ${g.roundIndex + 1}/12'), const Spacer(), Pill('${g.me?.score ?? 0} puan')])),
      Expanded(
        child: Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: Duration(milliseconds: g.settings.reduceMotion ? 1 : 600),
            curve: Curves.elasticOut,
            builder: (_, v, c) => Transform.scale(scale: .5 + .5 * v, child: Transform.rotate(angle: (1 - v) * -.2, child: c)),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color.lerp(col, Colors.white, .2)!, K.edge(col)]),
                boxShadow: [BoxShadow(color: K.edge(K.edge(col)), offset: const Offset(0, 8))],
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Mascot(r.type.mascot, mood: Mood.happy, size: 190),
                Semantics(
                  header: true,
                  liveRegion: true,
                  child: Text(catName(r.type), textAlign: TextAlign.center, style: T.display(34, height: 1).copyWith(shadows: const [Shadow(color: Color(0x5920173D), offset: Offset(0, 3))])),
                ),
                const SizedBox(height: 10),
                Text(line, textAlign: TextAlign.center, style: T.body(17, color: K.ink, w: 800)),
              ]),
            ),
          ),
        ),
      ),
    ]);
  }
}

// ---------------- S08 / S09 / S10 Tur ----------------
class RoundScreen extends StatelessWidget {
  const RoundScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final g = GameScope.of(context);
    final r = g.round!;
    final timer = r.memorizing ? const SizedBox(width: 58) : TimerRing(remaining: g.remaining(r), total: r.duration.toDouble());
    final mine = r.answers['me'];
    final locked = mine != null;
    final el = g.eligible(r);
    final cnt = el.where((p) => r.answers.containsKey(p.id)).length;
    final strip = Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      for (final p in el)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: Avatar(p, done: r.answers.containsKey(p.id), slip: r.slipId == p.id),
        ),
    ]);
    final lockBar = Semantics(
      liveRegion: true,
      child: Container(
        height: 52,
        decoration: BoxDecoration(color: K.aqua.withValues(alpha: .15), borderRadius: BorderRadius.circular(18), border: Border.all(color: K.aqua.withValues(alpha: .5), width: 2)),
        alignment: Alignment.center,
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const GameIcon(GI.check, color: K.aqua, size: 18),
          const SizedBox(width: 8),
          Text('Cevabın kilitlendi. Diğerleri: $cnt/${el.length}', style: T.body(15, w: 900)),
        ]),
      ),
    );

    Widget grid(List<Widget> tiles) => Column(children: [
          Row(children: [Expanded(child: tiles[0]), const SizedBox(width: 12), Expanded(child: tiles[1])]),
          const SizedBox(height: 12),
          Row(children: [Expanded(child: tiles[2]), const SizedBox(width: 12), Expanded(child: tiles[3])]),
        ]);

    List<Widget> tiles({List<Widget>? markers}) => [
          for (var i = 0; i < r.options.length; i++)
            Enter(
              delayMs: 50 * i,
              child: AnswerTile(
                index: i,
                text: r.options[i],
                tall: true,
                selected: mine?.index == i,
                dimmed: locked && mine.index != i,
                marker: markers?[i],
                onTap: locked ? null : () => g.answer('me', i),
              ),
            ),
        ];

    Widget hostLine(String mascot, Mood mood, String text) => Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Mascot(mascot, mood: mood, size: 92),
          const SizedBox(width: 6),
          Expanded(child: Padding(padding: const EdgeInsets.only(bottom: 16), child: Text(text, style: T.body(15, color: K.lilac)))),
        ]);

    switch (r.type) {
      case RoundType.knowing:
        final t = g.playerById(r.targetId!);
        if (t.isMe) {
          return Column(children: [
            _roundPills(g, right: timer),
            const Spacer(),
            Mascot(g.mascot, mood: Mood.surprised, size: 170),
            Text('Arkadaşların seni tahmin ediyor', textAlign: TextAlign.center, style: T.display(26)),
            const SizedBox(height: 14),
            SizedBox(width: double.infinity, child: QuestionCard(r.prompt, size: 19)),
            const SizedBox(height: 14),
            GPanel(
              child: Row(children: [
                Container(width: 42, height: 42, decoration: const BoxDecoration(color: K.paper, shape: BoxShape.circle), alignment: Alignment.center, child: SymbolIcon(answerShapesFor(r.correct), size: 20)),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Senin cevabın', style: T.body(13, color: K.lilac)),
                  Text(r.options[r.correct], style: T.body(19, w: 900)),
                ]),
              ]),
            ),
            const SizedBox(height: 10),
            Text('Yarıdan fazlası bilirse sen de +30 puan alırsın.', style: T.body(14, color: K.lilac)),
            const Spacer(),
            strip,
          ]);
        }
        return Column(children: [
          _roundPills(g, right: timer),
          Container(
            padding: const EdgeInsets.fromLTRB(4, 4, 16, 4),
            decoration: BoxDecoration(color: K.pink.withValues(alpha: .2), borderRadius: BorderRadius.circular(999), border: Border.all(color: K.pink.withValues(alpha: .5), width: 2)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Mascot(t.mascot, mood: Mood.think, size: 44),
              const SizedBox(width: 8),
              Text('${t.nick} cevapladı, sen tahmin et', style: T.body(15, w: 900)),
            ]),
          ),
          const SizedBox(height: 14),
          SizedBox(width: double.infinity, child: QuestionCard(r.prompt)),
          const SizedBox(height: 18),
          grid(tiles()),
          const Spacer(),
          locked ? lockBar : Text('Bir cevap seç. İlk seçimin geçerli olur.', style: T.body(14, color: K.lilac)),
          const SizedBox(height: 14),
          strip,
        ]);
      case RoundType.majority:
        return Column(children: [
          _roundPills(g, right: timer),
          hostLine('bidik', locked ? Mood.happy : Mood.think, 'Herkes bu soruyu cevapladı. Sence çoğunluk hangisini seçti?'),
          SizedBox(width: double.infinity, child: QuestionCard(r.prompt, size: 21)),
          const SizedBox(height: 18),
          grid(tiles()),
          const Spacer(),
          if (locked) lockBar,
          const SizedBox(height: 14),
          strip,
        ]);
      case RoundType.fact:
        Widget tf(int i, String label, GI icon, int colorIdx) => Expanded(
              child: AnswerTile(
                index: colorIdx,
                text: label,
                tall: true,
                selected: mine?.index == i,
                dimmed: locked && mine.index != i,
                marker: GameIcon(icon, color: K.ink, size: 22),
                onTap: locked ? null : () => g.answer('me', i),
              ),
            );
        return Column(children: [
          _roundPills(g, right: timer),
          hostLine('minti', locked ? Mood.happy : Mood.think, 'Minti bir bilgi buldu. Sence doğru mu?'),
          SizedBox(width: double.infinity, child: QuestionCard(r.prompt, size: 26, padding: const EdgeInsets.fromLTRB(20, 32, 20, 34))),
          const SizedBox(height: 20),
          SizedBox(height: 128, child: Row(children: [tf(0, 'GERÇEK', GI.check, 1), const SizedBox(width: 12), tf(1, 'UYDURMA', GI.cross, 2)])),
          const Spacer(),
          if (locked) lockBar,
          const SizedBox(height: 14),
          strip,
        ]);
      case RoundType.estimate:
        return Column(children: [
          _roundPills(g, right: timer),
          hostLine('zipzip', locked ? Mood.happy : Mood.think, 'Tam sayıyı bilemesen de olur. En yakın tahmin kazanır.'),
          SizedBox(width: double.infinity, child: QuestionCard(r.prompt, size: 22)),
          const SizedBox(height: 16),
          Expanded(child: _EstimatePad(r: r, locked: locked, onSubmit: (v) => g.answer('me', 0, value: v))),
          if (locked) ...[lockBar, const SizedBox(height: 14)],
          strip,
        ]);
      case RoundType.order:
        return Column(children: [
          _roundPills(g, right: timer),
          hostLine('pof', locked ? Mood.happy : Mood.think, 'Sırayla dokun: önce ilk gelen. Yanlış dokunursan tekrar dokunup geri al.'),
          SizedBox(width: double.infinity, child: QuestionCard(r.prompt, size: 22)),
          const SizedBox(height: 14),
          Expanded(child: _OrderPicker(r: r, locked: locked, onSubmit: (o) => g.answer('me', 0, order: o))),
          if (locked) ...[lockBar, const SizedBox(height: 14)],
          strip,
        ]);
      case RoundType.memo:
        if (r.memorizing) {
          return Column(children: [
            _roundPills(g, right: timer),
            Text('Ekrana iyi bak!', style: T.display(28)),
            Text('3 saniye sonra kaybolacaklar.', style: T.body(15, color: K.lilac)),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: K.paper, borderRadius: BorderRadius.circular(24)),
              child: Wrap(spacing: 12, runSpacing: 12, alignment: WrapAlignment.center, children: [for (final s in r.shown!) SymTile(s, size: 94)]),
            ),
            const SizedBox(height: 18),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 1, end: 0),
              duration: const Duration(seconds: 3),
              builder: (_, v, _) => ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: LinearProgressIndicator(value: v, minHeight: 10, color: K.sun, backgroundColor: K.lilac.withValues(alpha: .2)),
              ),
            ),
            const Spacer(),
            strip,
          ]);
        }
        return Column(children: [
          _roundPills(g, right: timer),
          hostLine('cakir', locked ? Mood.happy : Mood.think, 'Hafızanı yokla! En hızlı doğru cevap en çok puanı alır.'),
          SizedBox(width: double.infinity, child: QuestionCard(r.prompt)),
          const SizedBox(height: 18),
          grid(tiles(markers: r.optionSymbols?.map((s) => SymbolIcon(s.shape, color: s.color, size: 24) as Widget).toList())),
          const Spacer(),
          if (locked) lockBar,
          const SizedBox(height: 14),
          strip,
        ]);
      case RoundType.starRain:
        return Column(children: [
          _roundPills(g, right: timer),
          Row(children: [
            Mascot('cakir', mood: r.memorizing ? Mood.surprised : Mood.happy, size: 64),
            const SizedBox(width: 8),
            Expanded(child: Text('Yıldızlara dokun! Altın yıldız 3 sayar.', style: T.body(15, color: K.lilac))),
            Semantics(
              liveRegion: true,
              label: '${r.liveStars} yıldız puanı',
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: K.sun, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: K.edge(K.sun), offset: const Offset(0, 4))]),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Image.asset('assets/images/star.webp', width: 26),
                  const SizedBox(width: 6),
                  Text('${r.liveStars}', style: T.display(24, color: K.ink)),
                ]),
              ),
            ),
          ]),
          const SizedBox(height: 10),
          Expanded(child: _StarRainView(r: r)),
          const SizedBox(height: 12),
          strip,
        ]);
    }
  }
}

/// Yakın tahmin: büyük sayı, sürüklenebilir çizgi ve +/- tuşları.
class _EstimatePad extends StatefulWidget {
  final Round r;
  final bool locked;
  final ValueChanged<double> onSubmit;
  const _EstimatePad({required this.r, required this.locked, required this.onSubmit});
  @override
  State<_EstimatePad> createState() => _EstimatePadState();
}

class _EstimatePadState extends State<_EstimatePad> {
  late double v;
  Estimate get e => widget.r.estimate!;

  @override
  void initState() {
    super.initState();
    v = ((e.min + e.max) / 2 / e.step).round() * e.step;
    final mine = widget.r.answers['me']?.value;
    if (mine != null) v = mine;
  }

  void _set(double x) => setState(() => v = ((x / e.step).round() * e.step).clamp(e.min, e.max));

  @override
  Widget build(BuildContext context) {
    final big = (e.max - e.min) / e.step > 60;
    final steps = big ? [-10 * e.step, -e.step, e.step, 10 * e.step] : [-5 * e.step, -e.step, e.step, 5 * e.step];
    return Column(children: [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(color: const Color(0x59080420), borderRadius: BorderRadius.circular(22)),
        child: Semantics(
          liveRegion: true,
          label: 'Tahminin ${fmtNum(v)} ${e.unit}',
          child: ExcludeSemantics(
            child: Column(children: [
              Text(fmtNum(v), style: T.display(52, color: K.sun, height: 1).copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
              Text(e.unit, style: T.body(15, color: K.lilac, w: 800)),
            ]),
          ),
        ),
      ),
      const SizedBox(height: 14),
      LayoutBuilder(builder: (_, c) {
        double toV(double x) => e.min + (x / c.maxWidth).clamp(0, 1) * (e.max - e.min);
        return Semantics(
          slider: true,
          value: fmtNum(v),
          increasedValue: fmtNum(min(e.max, v + e.step)),
          decreasedValue: fmtNum(max(e.min, v - e.step)),
          onIncrease: widget.locked ? null : () => _set(v + e.step),
          onDecrease: widget.locked ? null : () => _set(v - e.step),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragUpdate: widget.locked ? null : (d) => _set(toV(d.localPosition.dx)),
            onTapDown: widget.locked ? null : (d) => _set(toV(d.localPosition.dx)),
            child: SizedBox(height: 48, width: c.maxWidth, child: CustomPaint(painter: _SliderPainter((v - e.min) / (e.max - e.min)))),
          ),
        );
      }),
      const SizedBox(height: 12),
      Row(children: [
        for (final (i, s) in steps.indexed) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: GameButton(
              label: '${s > 0 ? '+' : '−'}${fmtNum(s.abs())}',
              height: 46,
              depth: 4,
              radius: 16,
              hPad: 0,
              color: const Color(0xFF3A2D86),
              textColor: K.paper,
              onTap: widget.locked ? null : () => _set(v + s),
            ),
          ),
        ],
      ]),
      const Spacer(),
      if (!widget.locked) GameButton(label: 'TAHMİNİ KİLİTLE', onTap: () => widget.onSubmit(v)),
    ]);
  }
}

class _SliderPainter extends CustomPainter {
  final double f;
  _SliderPainter(this.f);
  @override
  void paint(Canvas c, Size s) {
    final y = s.height / 2;
    final track = RRect.fromRectAndRadius(Rect.fromLTWH(0, y - 7, s.width, 14), const Radius.circular(7));
    c.drawRRect(track, Paint()..color = const Color(0x66080420));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, y - 7, s.width * f.clamp(0, 1), 14), const Radius.circular(7)),
        Paint()..shader = const LinearGradient(colors: [K.orange, K.sun]).createShader(track.outerRect));
    final x = (s.width * f).clamp(16.0, s.width - 16);
    c.drawCircle(Offset(x, y + 3), 17, Paint()..color = K.edge(K.sun));
    c.drawCircle(Offset(x, y), 17, Paint()..color = K.sun);
    c.drawCircle(Offset(x, y), 17, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = K.ink);
  }

  @override
  bool shouldRepaint(_SliderPainter o) => o.f != f;
}

/// Sırala: dört kartı sırayla seç; seçilen kartta sıra numarası görünür.
class _OrderPicker extends StatefulWidget {
  final Round r;
  final bool locked;
  final ValueChanged<List<int>> onSubmit;
  const _OrderPicker({required this.r, required this.locked, required this.onSubmit});
  @override
  State<_OrderPicker> createState() => _OrderPickerState();
}

class _OrderPickerState extends State<_OrderPicker> {
  late List<int> picked = List.of(widget.r.answers['me']?.order ?? const []);

  @override
  Widget build(BuildContext context) {
    final r = widget.r;
    return Column(children: [
      for (var i = 0; i < r.options.length; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: AnswerTile(
            index: i,
            text: r.options[i],
            selected: picked.contains(i),
            marker: picked.contains(i) ? Text('${picked.indexOf(i) + 1}', style: T.display(22, color: K.ink)) : null,
            onTap: widget.locked
                ? null
                : () => setState(() {
                      if (picked.contains(i)) {
                        picked.remove(i);
                      } else if (picked.length < 4) {
                        picked.add(i);
                      }
                    }),
          ),
        ),
      const Spacer(),
      if (!widget.locked)
        GameButton(label: picked.length < 4 ? 'SIRAYI SEÇ (${picked.length}/4)' : 'SIRAYI GÖNDER', onTap: picked.length == 4 ? () => widget.onSubmit(picked) : null),
    ]);
  }
}

/// Flame yıldız yağmuru alanı.
class _StarRainView extends StatefulWidget {
  final Round r;
  const _StarRainView({required this.r});
  @override
  State<_StarRainView> createState() => _StarRainViewState();
}

class _StarRainViewState extends State<_StarRainView> {
  late final StarRainGame game = StarRainGame(onCatch: (p) => GameScope.read(context).catchStar(p));

  @override
  Widget build(BuildContext context) {
    final g = GameScope.of(context);
    final r = widget.r;
    game.reduceMotion = g.settings.reduceMotion;
    final active = !r.memorizing && !r.revealed && g.remaining(r) > 0;
    if (active != game.running) {
      if (active) {
        game.running = true;
      } else {
        game.stop();
      }
    }
    final count = r.memorizing && r.memoStart != null ? (3 - DateTime.now().difference(r.memoStart!).inMilliseconds ~/ 1000).clamp(1, 3) : 0;
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: Stack(children: [
        Positioned.fill(child: Container(decoration: BoxDecoration(color: const Color(0x55080420), border: Border.all(color: K.lilac.withValues(alpha: .2), width: 2), borderRadius: BorderRadius.circular(26)))),
        Positioned.fill(
          child: Semantics(
            label: 'Yıldız yağmuru oyun alanı. Düşen yıldızlara dokun.',
            child: GameWidget(game: game),
          ),
        ),
        if (r.memorizing)
          Positioned.fill(
            child: Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text('Hazır ol!', style: T.display(30)),
                TweenAnimationBuilder<double>(
                  key: ValueKey(count),
                  tween: Tween(begin: 1.6, end: 1),
                  duration: const Duration(milliseconds: 400),
                  builder: (_, s, c) => Transform.scale(scale: s, child: c),
                  child: Text('$count', style: T.display(90, color: K.sun, height: 1)),
                ),
              ]),
            ),
          ),
      ]),
    );
  }
}

// ---------------- S11 Tur sonucu ----------------
class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final g = GameScope.of(context);
    final r = g.round!;
    final my = r.answers['me'];
    final myGain = r.gain['me'] ?? 0;
    final iAmTarget = r.type == RoundType.knowing && r.targetId == 'me';
    final ok = r.isRight(my);
    final el = g.eligible(r);

    String head;
    Mood mood;
    if (iAmTarget) {
      (head, mood) = myGain > 0 ? ('${r.right} kişi seni bildi, +30 puan!', Mood.happy) : ('${r.right}/${el.length} kişi seni bildi', Mood.surprised);
    } else if (my == null) {
      (head, mood) = ('Süre doldu. Bir sonraki turda yakala!', Mood.sad);
    } else if (r.type == RoundType.estimate) {
      final tier = r.estimateTier(my.value ?? -1e9);
      head = const ['Bu sefer uzak kaldın.', 'Fena değil!', 'Yakın!', 'Çok yakın!', 'Tam isabet!'][tier] + (myGain > 0 ? ' +$myGain puan' : '');
      mood = tier >= 3 ? Mood.victory : tier >= 1 ? Mood.happy : Mood.sad;
    } else if (r.type == RoundType.order) {
      final n = r.correctPositions(my.order);
      head = n == 4 ? 'Kusursuz sıra! +$myGain puan' : '$n/4 doğru yer${myGain > 0 ? ', +$myGain puan' : ''}';
      mood = n == 4 ? Mood.victory : n >= 2 ? Mood.happy : Mood.sad;
    } else if (r.type == RoundType.starRain) {
      head = '${my.value?.round() ?? 0} yıldız puanı! +$myGain';
      mood = myGain >= 100 ? Mood.victory : myGain > 0 ? Mood.happy : Mood.sad;
    } else if (ok) {
      (head, mood) = ('Doğru! +$myGain puan', Mood.happy);
    } else {
      (head, mood) = ('Bu sefer olmadı. Puan kaybetmedin.', Mood.sad);
    }

    final sorted = [...g.players]..sort((a, b) => b.score.compareTo(a.score));
    return Column(children: [
      SizedBox(height: 60, child: Row(children: [Pill('Tur ${g.roundIndex + 1}/12'), const SizedBox(width: 8), Flexible(child: Pill(catName(r.type), color: catColor(r.type).withValues(alpha: .28)))])),
      Row(children: [
        Mascot(g.mascot, mood: mood, size: 92),
        const SizedBox(width: 12),
        Expanded(child: Semantics(liveRegion: true, child: Text(head, style: T.display(24)))),
      ]),
      const SizedBox(height: 10),
      Shake(active: my != null && !ok && !iAmTarget && myGain == 0, child: _RevealCard(r: r, g: g)),
      const SizedBox(height: 16),
      Align(alignment: Alignment.centerLeft, child: Text('Puan durumu', style: T.display(16, color: K.lilac))),
      const SizedBox(height: 8),
      for (final (i, p) in sorted.indexed)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Enter(delayMs: 60 * i, child: _ScoreRow(p, rank: g.rankOf(p), gain: r.gain[p.id] ?? 0)),
        ),
      const Spacer(),
      Semantics(
        liveRegion: true,
        child: Text('${g.roundIndex == 11 ? 'Final' : 'Sonraki tur'} ${g.resultCountdown} sn içinde', style: T.body(15, color: K.lilac)),
      ),
    ]);
  }
}

class _RevealCard extends StatelessWidget {
  final Round r;
  final GameEngine g;
  const _RevealCard({required this.r, required this.g});

  Widget _card(Widget child) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: K.paper, borderRadius: BorderRadius.circular(22), boxShadow: const [BoxShadow(color: Color(0xFF3B2794), offset: Offset(0, 5))]),
        child: child,
      );

  Widget _simple(Widget icon, Color iconBg, String label, String big, String ex) => _card(Row(children: [
        Container(width: 50, height: 50, decoration: BoxDecoration(shape: BoxShape.circle, color: iconBg), alignment: Alignment.center, child: icon),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: T.body(13, color: const Color(0xFF5B4C8F), w: 800)),
            Text(big, style: T.display(24, color: K.ink)),
            if (ex.isNotEmpty) Text(ex, style: T.body(14, color: const Color(0xFF4A3F78))),
          ]),
        ),
      ]));

  @override
  Widget build(BuildContext context) {
    final el = g.eligible(r);
    final my = r.answers['me'];
    switch (r.type) {
      case RoundType.fact:
        return _simple(GameIcon(r.factTrue! ? GI.check : GI.cross, color: K.ink, size: 22), r.factTrue! ? K.aqua : K.pink, 'Doğru cevap',
            r.factTrue! ? 'Gerçek' : 'Uydurma', r.explanation ?? '');
      case RoundType.knowing:
        return _simple(SymbolIcon(answerShapesFor(r.correct), size: 22), const Color(0xFFEFE6FF), 'Doğru cevap', r.options[r.correct],
            '${g.playerById(r.targetId!).nick} bunu seçmişti. ${r.right}/${el.length} kişi bildi.');
      case RoundType.memo:
        final s = r.optionSymbols?[r.correct];
        return _simple(s != null ? SymbolIcon(s.shape, color: s.color, size: 24) : SymbolIcon(answerShapesFor(r.correct), size: 22),
            const Color(0xFFEFE6FF), 'Doğru cevap', r.options[r.correct], r.explanation ?? '');
      case RoundType.estimate:
        final e = r.estimate!;
        return _simple(Text('≈', style: T.display(28, color: K.ink)), K.sun, 'Doğru cevap', '${fmtNum(e.answer)} ${e.unit}',
            '${my?.value != null ? 'Senin tahminin: ${fmtNum(my!.value!)}. ' : ''}${e.explanation}');
      case RoundType.majority:
        final votes = r.votes!;
        final total = votes.fold(0, (a, b) => a + b);
        return _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Oylar (${g.players.length} kişi)', style: T.body(13, color: const Color(0xFF5B4C8F), w: 800)),
          const SizedBox(height: 6),
          for (var i = 0; i < 4; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(children: [
                SymbolIcon(answerShapesFor(i), color: K.answer[i], size: 18),
                const SizedBox(width: 8),
                SizedBox(width: 110, child: Text(r.options[i], maxLines: 1, overflow: TextOverflow.ellipsis, style: T.body(14, color: K.ink, w: r.correctSet.contains(i) ? 900 : 700))),
                Expanded(
                  child: LayoutBuilder(
                    builder: (_, c) => Align(
                      alignment: Alignment.centerLeft,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: total == 0 ? 0 : votes[i] / total),
                        duration: const Duration(milliseconds: 700),
                        curve: Curves.easeOut,
                        builder: (_, f, _) => Container(
                          width: max(6, c.maxWidth * f),
                          height: 16,
                          decoration: BoxDecoration(color: r.correctSet.contains(i) ? K.answer[i] : K.answer[i].withValues(alpha: .35), borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text('${votes[i]}', style: T.display(18, color: K.ink)),
              ]),
            ),
          const SizedBox(height: 4),
          Text(r.correctSet.length > 1 ? 'Berabere çıkan seçenekler doğru sayıldı.' : '${r.right}/${el.length} kişi çoğunluğu bildi.', style: T.body(13, color: const Color(0xFF4A3F78))),
        ]));
      case RoundType.order:
        final correct = r.correctOrder!;
        return _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Doğru sıra', style: T.body(13, color: const Color(0xFF5B4C8F), w: 800)),
          const SizedBox(height: 4),
          for (var k = 0; k < 4; k++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(children: [
                Text('${k + 1}.', style: T.display(18, color: K.ink)),
                const SizedBox(width: 8),
                Expanded(child: Text(r.options[correct[k]], style: T.body(16, color: K.ink, w: 900))),
                if (my?.order != null)
                  GameIcon(my!.order![k] == correct[k] ? GI.check : GI.cross, color: my.order![k] == correct[k] ? const Color(0xFF1F9E92) : K.error, size: 18),
              ]),
            ),
          Text(r.explanation ?? '', style: T.body(13, color: const Color(0xFF4A3F78))),
        ]));
      case RoundType.starRain:
        final best = g.players.map((p) => (p, r.answers[p.id]?.value ?? 0)).reduce((a, b) => a.$2 >= b.$2 ? a : b);
        return _simple(Image.asset('assets/images/star_gold.webp', width: 34), K.sun, 'En çok yıldız toplayan', best.$1.label, '${best.$2.round()} yıldız puanı');
    }
  }
}

class _ScoreRow extends StatelessWidget {
  final Player p;
  final int rank, gain;
  const _ScoreRow(this.p, {required this.rank, required this.gain});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(10, 6, 14, 6),
        decoration: BoxDecoration(
          color: p.isMe ? K.sun.withValues(alpha: .16) : K.violet7.withValues(alpha: .45),
          borderRadius: BorderRadius.circular(18),
          border: p.isMe ? Border.all(color: K.sun.withValues(alpha: .55), width: 2) : null,
        ),
        child: Row(children: [
          SizedBox(width: 26, child: Text('$rank', textAlign: TextAlign.center, style: T.display(19))),
          Mascot(p.mascot, mood: gain > 0 ? Mood.happy : Mood.idle, size: 42, animate: gain > 0),
          const SizedBox(width: 8),
          Expanded(child: Text(p.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: T.body(16, w: 900))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
            decoration: BoxDecoration(color: gain > 0 ? K.aqua : K.lilac.withValues(alpha: .2), borderRadius: BorderRadius.circular(999)),
            child: Text('+$gain', style: T.body(14, color: gain > 0 ? K.ink : K.lilac, w: 900)),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 62,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: (p.score - gain).toDouble(), end: p.score.toDouble()),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOut,
              builder: (_, v, _) => Text(_fmt(v.round()), textAlign: TextAlign.right, style: T.display(19).copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
            ),
          ),
        ]),
      );
}

String _fmt(int n) {
  final s = '$n';
  if (s.length <= 3) return s;
  return '${s.substring(0, s.length - 3)}.${s.substring(s.length - 3)}';
}

// ---------------- S12 Final ----------------
class FinaleScreen extends StatelessWidget {
  const FinaleScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final g = GameScope.of(context);
    final ps = [...g.players]..sort((a, b) => b.score.compareTo(a.score));
    final tie = ps.length > 1 && ps[0].score == ps[1].score;
    String best(int Function(Player) f) {
      final mx = g.players.map(f).fold(0, max);
      if (mx <= 0) return '—';
      return g.players.where((p) => f(p) == mx).map((p) => p.label).join(', ');
    }

    Widget pod(Player? p, double h, Color col) {
      if (p == null) return const Expanded(child: SizedBox());
      final rank = g.rankOf(p);
      return Expanded(
        child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
          Mascot(p.mascot, mood: rank == 1 ? Mood.victory : Mood.happy, size: rank == 1 ? 120 : 94),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: h),
            duration: Duration(milliseconds: g.settings.reduceMotion ? 1 : 900),
            curve: Curves.easeOutBack,
            builder: (_, v, _) => Container(
              width: double.infinity,
              height: max(0, v),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                color: col,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18), bottom: Radius.circular(8)),
                boxShadow: [BoxShadow(color: K.edge(col), offset: const Offset(0, 6))],
              ),
              child: v < h * .7
                  ? null
                  : Column(children: [
                      Text('$rank', style: T.display(30, color: K.ink, height: 1)),
                      Text(p.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: T.body(14, color: K.ink, w: 900)),
                      Text(_fmt(p.score), style: T.body(13, color: K.ink, w: 800)),
                    ]),
            ),
          ),
        ]),
      );
    }

    return Column(children: [
      TopBar(title: tie ? 'Berabere!' : 'Maç sonucu', right: IconTap(GI.home, label: 'Ana menü', onTap: () => g.go(Scr.menu))),
      SizedBox(
        height: 290,
        child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          pod(ps.length > 1 ? ps[1] : null, 100, K.sky),
          pod(ps[0], 132, K.sun),
          pod(ps.length > 2 ? ps[2] : null, 82, K.pink),
        ]),
      ),
      const SizedBox(height: 14),
      for (final p in ps.skip(3))
        Padding(padding: const EdgeInsets.only(bottom: 8), child: _ScoreRow(p, rank: g.rankOf(p), gain: 0)),
      const SizedBox(height: 6),
      Row(children: [
        _Badge('En İyi Tahminci', best((p) => p.knowPts), K.pink),
        const SizedBox(width: 8),
        _Badge('Bilgi Kaşifi', best((p) => p.factPts), K.sky),
        const SizedBox(width: 8),
        _Badge('Şamata Ustası', best((p) => p.shamataPts), K.orange),
      ]),
      const Spacer(),
      GameButton(label: 'YENİ MAÇ', onTap: g.rematch),
      const SizedBox(height: 12),
      GameButton.ghost(label: 'ANA MENÜ', onTap: () => g.go(Scr.menu)),
    ]);
  }
}

class _Badge extends StatelessWidget {
  final String title, who;
  final Color col;
  const _Badge(this.title, this.who, this.col);
  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(color: K.violet7.withValues(alpha: .45), borderRadius: BorderRadius.circular(18)),
          child: Column(children: [
            CustomPaint(size: const Size(34, 34), painter: _MedalPainter(col)),
            const SizedBox(height: 4),
            Text(title, textAlign: TextAlign.center, style: T.body(12, color: K.lilac, w: 800)),
            Text(who, textAlign: TextAlign.center, maxLines: 2, style: T.body(13, w: 900, height: 1.15)),
          ]),
        ),
      );
}

class _MedalPainter extends CustomPainter {
  final Color col;
  _MedalPainter(this.col);
  @override
  void paint(Canvas c, Size s) {
    final st = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..color = K.ink;
    c.drawPath(Path()..moveTo(10, 0)..lineTo(17, 14)..lineTo(24, 0), Paint()..color = K.violet5);
    c.drawCircle(Offset(s.width / 2, 21), 12, Paint()..color = col);
    c.drawCircle(Offset(s.width / 2, 21), 12, st);
    final p = symPath(SymShape.star, Rect.fromCenter(center: Offset(s.width / 2, 21), width: 15, height: 15));
    c.drawPath(p, Paint()..color = K.paper);
  }

  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}

// ---------------- S13 Ayarlar ----------------
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final g = GameScope.of(context);
    final s = g.settings;
    Widget row(String label, bool v, void Function(bool) set, {String? sub}) => _ToggleRow(label: label, sub: sub, value: v, onChanged: (x) {
          set(x);
          g.go(Scr.settings);
        });
    Widget link(String label, VoidCallback onTap, {bool parent = false}) => Semantics(
          button: true,
          child: InkWell(
            onTap: onTap,
            child: Container(
              constraints: const BoxConstraints(minHeight: 58),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              color: K.violet7.withValues(alpha: .4),
              child: Row(children: [
                Expanded(child: Text(label, style: T.body(16, w: 800))),
                if (parent) Padding(padding: const EdgeInsets.only(right: 8), child: Pill('Ebeveyn', color: K.sun.withValues(alpha: .25))),
                const GameIcon(GI.fwd, size: 20, color: K.lilac),
              ]),
            ),
          ),
        );
    Widget group(List<Widget> children) => ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Column(children: [for (final (i, c) in children.indexed) ...[if (i > 0) const SizedBox(height: 2), c]]),
        );
    Widget h(String t) => Padding(padding: const EdgeInsets.fromLTRB(4, 14, 4, 8), child: Align(alignment: Alignment.centerLeft, child: Text(t, style: T.display(16, color: K.lilac))));
    return Column(children: [
      TopBar(left: IconTap(GI.back, label: 'Geri', onTap: g.closeSettings), title: 'Ayarlar'),
      Expanded(
        child: ListView(padding: const EdgeInsets.only(bottom: 20), children: [
          h('Ses ve hareket'),
          group([
            row('Ses efektleri', s.sound, (v) => s.sound = v),
            row('Müzik', s.music, (v) => s.music = v),
            row('Titreşim', s.haptics, (v) => s.haptics = v),
            row('Hareketi azalt', s.reduceMotion, (v) => s.reduceMotion = v, sub: 'Animasyonları kısaltır, parlamaları kapatır'),
            row('Şamata efektleri', s.effects, (v) => s.effects = v, sub: 'Kapalıyken sana gönderilen efektler görünmez'),
          ]),
          h('Okuma ve süre'),
          group([
            row('Büyük metin', s.largeText, (v) => s.largeText = v),
            row('Uzun cevap süresi', s.longTime, (v) => s.longTime = v, sub: 'Süreler 1,5 katına çıkar'),
          ]),
          h('Bilgi'),
          group([
            link('Nasıl oynanır?', () => showHowTo(context)),
            link('Gizlilik bildirimi', () => showPrivacy(context)),
            link('Çocuk verileri', () => showParentGate(context, 'Çocuk verileri'), parent: true),
            link('Destek', () => showParentGate(context, 'Destek'), parent: true),
          ]),
          h('Prototip'),
          group([link('Test paneli: ekranlara git', () => showTestPanel(context))]),
          const SizedBox(height: 10),
          Center(child: Text('Sürüm 0.1 prototip', style: T.body(12, color: K.lilac))),
        ]),
      ),
    ]);
  }
}

class _ToggleRow extends StatelessWidget {
  final String label;
  final String? sub;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ToggleRow({required this.label, this.sub, required this.value, required this.onChanged});
  @override
  Widget build(BuildContext context) => Semantics(
        toggled: value,
        label: label,
        child: InkWell(
          onTap: () {
            tapFeedback(context);
            onChanged(!value);
          },
          child: Container(
            constraints: const BoxConstraints(minHeight: 60),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: K.violet7.withValues(alpha: .4),
            child: Row(children: [
              Expanded(
                child: ExcludeSemantics(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                    Text(label, style: T.body(16, w: 800)),
                    if (sub != null) Text(sub!, style: T.body(12, color: K.lilac)),
                  ]),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 54,
                height: 32,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: value ? K.aqua : K.lilac.withValues(alpha: .25), borderRadius: BorderRadius.circular(16)),
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(width: 24, height: 24, decoration: const BoxDecoration(color: K.paper, shape: BoxShape.circle)),
              ),
            ]),
          ),
        ),
      );
}
