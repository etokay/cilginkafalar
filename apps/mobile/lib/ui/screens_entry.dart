import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../art/mascot_painter.dart';
import '../art/shapes.dart';
import '../data/content.dart';
import '../game/engine.dart';
import '../theme.dart';
import 'sheets.dart';
import 'widgets.dart';

// ---------------- S01 Açılış ----------------
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final g = GameScope.of(context);
    final p = g.splashProgress;
    final status = p < .4 ? 'Maskotlar uyanıyor' : p < .8 ? 'Bağlantı kontrol ediliyor' : 'Hazır';
    return Column(children: [
      const Spacer(),
      const Logo(size: 62),
      const SizedBox(height: 18),
      SizedBox(
        width: 300,
        height: 250,
        child: Stack(children: [
          Positioned.fill(top: 60, child: CustomPaint(painter: IslandPainter())),
          const Positioned(left: 60, bottom: 66, child: Mascot('pof', mood: Mood.happy, size: 180)),
        ]),
      ),
      const Spacer(),
      if (g.net == NetState.offline) ...[
        const Banner2('İnternet bağlantısı yok. Wi-Fi ya da mobil verini açıp tekrar dene.'),
        const SizedBox(height: 14),
        GameButton(label: 'TEKRAR DENE', onTap: g.startSplash),
      ] else ...[
        _ProgressBar(p),
        const SizedBox(height: 10),
        Semantics(liveRegion: true, child: Text(status, style: T.body(15, color: K.lilac, w: 800))),
        const SizedBox(height: 4),
        Text('Sürüm 0.1 prototip', style: T.body(12, color: K.lilac.withValues(alpha: .7))),
      ],
      const SizedBox(height: 8),
    ]);
  }
}

class _ProgressBar extends StatelessWidget {
  final double v;
  const _ProgressBar(this.v);
  @override
  Widget build(BuildContext context) => Semantics(
        value: '${(v * 100).round()}%',
        label: 'Yükleniyor',
        child: Container(
          width: 230,
          height: 18,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(color: const Color(0x66080420), borderRadius: BorderRadius.circular(9)),
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: v.clamp(.04, 1),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  gradient: const LinearGradient(colors: [K.orange, K.sun]),
                ),
              ),
            ),
          ),
        ),
      );
}

// ---------------- S02 Ana menü ----------------
class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final g = GameScope.of(context);
    final down = g.net != NetState.online;
    return Column(children: [
      TopBar(
        left: const Pill('3–6 oyuncu', leading: GameIcon(GI.people, size: 16)),
        right: Row(mainAxisSize: MainAxisSize.min, children: [
          IconTap(g.settings.sound ? GI.sound : GI.mute, label: g.settings.sound ? 'Sesi kapat' : 'Sesi aç', onTap: () {
            g.settings.sound = !g.settings.sound;
            g.go(Scr.menu);
          }),
        ]),
      ),
      SizedBox(
        height: 250,
        child: Stack(alignment: Alignment.center, children: [
          Positioned(bottom: 0, width: 300, height: 200, child: CustomPaint(painter: IslandPainter())),
          const Positioned(bottom: 70, child: Mascot('pof', mood: Mood.happy, size: 180)),
          const Positioned(left: 0, bottom: 110, child: Mascot('bidik', size: 84)),
          const Positioned(right: 0, bottom: 124, child: Mascot('zipzip', size: 80)),
        ]),
      ),
      const Logo(size: 44),
      const SizedBox(height: 14),
      Text('Aileni tanı, arkadaşlarını şaşırt!', style: T.body(17, color: K.lilac, w: 800)),
      const Spacer(),
      if (g.net == NetState.maintenance) const Banner2('Oyun kısa bir bakımda. Birkaç dakika sonra tekrar dene.', info: true),
      if (g.net == NetState.offline) const Banner2('İnternet bağlantısı yok. Oda kurmak ve katılmak için bağlantı gerekli.'),
      if (down) const SizedBox(height: 12),
      GameButton(label: 'ODA KUR', onTap: down ? null : () => g.openRoom(true)),
      const SizedBox(height: 12),
      GameButton.secondary(label: 'ODAYA KATIL', onTap: down ? null : () => g.openRoom(false)),
      const SizedBox(height: 8),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        LinkText('Nasıl oynanır?', onTap: () => showHowTo(context)),
        LinkText('Ayarlar', onTap: g.openSettings),
        LinkText('Gizlilik', onTap: () => showPrivacy(context)),
      ]),
    ]);
  }
}

class LinkText extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  const LinkText(this.text, {super.key, required this.onTap});
  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        child: InkResponse(
          onTap: () {
            tapFeedback(context);
            onTap();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
            child: Text(text, style: T.body(15, color: K.lilac, w: 800)),
          ),
        ),
      );
}

// ---------------- S04 Oda kur / katıl ----------------
const _trKeys = 'ABCÇDEFGĞHIİJKLMNOÖPRSŞTUÜVYZ';
const _codeKeys = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';

String trTitle(String s) => s
    .split(' ')
    .map((w) => w.isEmpty ? w : w[0] + w.substring(1).replaceAll('I', 'ı').replaceAll('İ', 'i').toLowerCase())
    .join(' ');

class RoomScreen extends StatefulWidget {
  const RoomScreen({super.key});
  @override
  State<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends State<RoomScreen> {
  String code = '', nickRaw = '';
  int step = 0; // katıl: 0 kod, 1 takma ad
  String? err;
  int shakeKey = 0;

  @override
  void initState() {
    super.initState();
    final g = GameScope.read(context);
    nickRaw = g.nick.toUpperCase();
  }

  String get nick => trTitle(nickRaw.trim());

  void _fail(String m) => setState(() {
        err = m;
        shakeKey++;
      });

  void _submit(GameEngine g) {
    if (!g.creating && step == 0) {
      final e = g.codeError(code);
      if (e != null) return _fail(e);
      setState(() {
        step = 1;
        err = null;
      });
      return;
    }
    final e = g.nickError(nick);
    if (e != null) return _fail(e);
    g.confirmRoom(nick, code);
  }

  @override
  Widget build(BuildContext context) {
    final g = GameScope.of(context);
    final codeStep = !g.creating && step == 0;
    return Column(children: [
      TopBar(
        left: IconTap(GI.back, label: 'Geri', onTap: () {
          if (!g.creating && step == 1) {
            setState(() => step = 0);
          } else {
            g.go(Scr.menu);
          }
        }),
        title: g.creating ? 'Oda kur' : 'Odaya katıl',
      ),
      _Tabs(creating: g.creating, onChange: (c) {
        setState(() {
          step = 0;
          err = null;
        });
        g.openRoom(c);
      }),
      const SizedBox(height: 16),
      if (g.creating)
        GPanel(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            const Mascot('pika', size: 64),
            const SizedBox(width: 10),
            Expanded(child: Text('Odayı sen kurarsın, sen de oynarsın. Kodu arkadaşlarınla paylaşman yeter.', style: T.body(14, color: K.lilac))),
          ]),
        ),
      if (g.creating) const SizedBox(height: 14),
      Align(
        alignment: Alignment.centerLeft,
        child: Text(codeStep ? 'Oda kodu' : 'Takma adın', style: T.display(18)),
      ),
      const SizedBox(height: 8),
      Shake(
        key: ValueKey(shakeKey),
        active: shakeKey > 0,
        child: codeStep
            ? LetterSlots(code, error: err != null)
            : Row(children: [
                Expanded(child: _NamePlate(nickRaw.isEmpty ? '' : nick, error: err != null)),
                const SizedBox(width: 10),
                IconTap(GI.dice, label: 'Rastgele takma ad öner', size: 62, color: K.violet5, onTap: () {
                  setState(() {
                    nickRaw = g.randomNick().toUpperCase();
                    err = null;
                  });
                }),
              ]),
      ),
      const SizedBox(height: 8),
      SizedBox(
        height: 40,
        child: err != null
            ? Row(children: [
                const GameIcon(GI.warn, size: 18),
                const SizedBox(width: 6),
                Expanded(child: Semantics(liveRegion: true, child: Text(err!, style: T.body(13, color: const Color(0xFFFFB3C1), w: 800)))),
              ])
            : Text(codeStep ? 'Kodu oda sahibinden al. 6 harf ve rakamdan oluşur.' : '2–16 karakter. Gerçek adını yazmana gerek yok.',
                style: T.body(13, color: K.lilac)),
      ),
      const Spacer(),
      GameKeyboard(
        keys: codeStep ? _codeKeys : _trKeys,
        onKey: (k) => setState(() {
          err = null;
          if (codeStep) {
            if (code.length < 6) code += k;
          } else if (nickRaw.length < 16) {
            nickRaw += k;
          }
        }),
        onSpace: codeStep
            ? null
            : () => setState(() {
                  if (nickRaw.isNotEmpty && !nickRaw.endsWith(' ') && nickRaw.length < 16) nickRaw += ' ';
                }),
        onBack: () => setState(() {
          err = null;
          if (codeStep) {
            if (code.isNotEmpty) code = code.substring(0, code.length - 1);
          } else if (nickRaw.isNotEmpty) {
            nickRaw = nickRaw.substring(0, nickRaw.length - 1);
          }
        }),
      ),
      const SizedBox(height: 14),
      GameButton(label: g.creating ? 'ODA KUR' : codeStep ? 'DEVAM' : 'KATIL', onTap: () => _submit(g)),
    ]);
  }
}

class _Tabs extends StatelessWidget {
  final bool creating;
  final ValueChanged<bool> onChange;
  const _Tabs({required this.creating, required this.onChange});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(color: const Color(0x59080420), borderRadius: BorderRadius.circular(22)),
        child: Row(children: [
          for (final c in [true, false])
            Expanded(
              child: GameButton(
                label: c ? 'Oda kur' : 'Odaya katıl',
                onTap: () => onChange(c),
                color: creating == c ? K.sun : const Color(0xFF2C2177),
                textColor: creating == c ? K.ink : K.lilac,
                height: 44,
                depth: creating == c ? 4 : 0,
                radius: 17,
                radio: true,
                selected: false,
              ),
            ),
        ]),
      );
}

class _NamePlate extends StatefulWidget {
  final String text;
  final bool error;
  const _NamePlate(this.text, {this.error = false});
  @override
  State<_NamePlate> createState() => _NamePlateState();
}

class _NamePlateState extends State<_NamePlate> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
        label: widget.text.isEmpty ? 'Takma ad boş' : 'Takma ad ${widget.text}',
        child: Container(
          height: 62,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: K.paper,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: widget.error ? K.error : K.violet5, width: 3),
            boxShadow: const [BoxShadow(color: Color(0xFF3B2794), offset: Offset(0, 4))],
          ),
          alignment: Alignment.centerLeft,
          child: Row(children: [
            Flexible(
              child: Text(widget.text.isEmpty ? 'ör. Uçan Panda' : widget.text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: T.display(24, color: widget.text.isEmpty ? K.ink.withValues(alpha: .35) : K.ink)),
            ),
            FadeTransition(opacity: _c, child: Container(width: 3, height: 28, margin: const EdgeInsets.only(left: 2), color: K.violet5)),
          ]),
        ),
      );
}

// ---------------- S03 Maskot seçimi ----------------
class PickScreen extends StatelessWidget {
  const PickScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final g = GameScope.of(context);
    final m = mascots[g.mascot]!;
    void cycle(int d) => g.chooseMascot(mascotOrder[(mascotOrder.indexOf(g.mascot) + d + 6) % 6]);
    return Column(children: [
      TopBar(left: IconTap(GI.back, label: 'Geri', onTap: () => g.openRoom(g.creating)), title: 'Maskotunu seç'),
      SizedBox(
        height: 290,
        child: Stack(alignment: Alignment.center, children: [
          Container(
            width: 250,
            height: 250,
            decoration: const BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [Color(0x8C825AE6), Color(0x00825AE6)])),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 380),
            transitionBuilder: (c, a) => ScaleTransition(scale: CurvedAnimation(parent: a, curve: Curves.easeOutBack), child: FadeTransition(opacity: a, child: c)),
            child: Mascot(g.mascot, key: ValueKey(g.mascot), mood: Mood.happy, size: 236),
          ),
          Positioned(left: 0, child: IconTap(GI.back, label: 'Önceki maskot', onTap: () => cycle(-1))),
          Positioned(right: 0, child: IconTap(GI.fwd, label: 'Sonraki maskot', onTap: () => cycle(1))),
        ]),
      ),
      Text(m.name, style: T.display(32, color: K.sun)),
      SizedBox(height: 44, child: Text(m.desc, textAlign: TextAlign.center, style: T.body(15, color: K.lilac))),
      const SizedBox(height: 10),
      Row(children: [
        for (final id in mascotOrder)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: GameButton(
                onTap: () => g.chooseMascot(id),
                color: id == g.mascot ? const Color(0xFF5B45C0) : const Color(0xFF34287F),
                height: 54,
                depth: 4,
                radius: 16,
                hPad: 0,
                radio: true,
                selected: id == g.mascot,
                semanticLabel: mascots[id]!.name,
                child: Mascot(id, size: 48, animate: id == g.mascot),
              ),
            ),
          ),
      ]),
      const SizedBox(height: 12),
      Text('Aynı maskotu başka oyuncular da seçebilir. Hepsi eşit güçte.', textAlign: TextAlign.center, style: T.body(13, color: K.lilac)),
      const Spacer(),
      GameButton(label: 'SEÇ', onTap: () => g.enterLobby()),
    ]);
  }
}

// ---------------- S05 Lobi ----------------
class LobbyScreen extends StatelessWidget {
  const LobbyScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final g = GameScope.of(context);
    final me = g.me;
    final host = me?.host ?? false;
    final n = g.players.length, rd = g.players.where((p) => p.ready).length;
    final blocker = g.startBlocker;
    final hostName = g.players.where((p) => p.host).firstOrNull?.label ?? '';
    void copy(String text, String msg) {
      Clipboard.setData(ClipboardData(text: text));
      g.toast(msg);
    }

    return Column(children: [
      TopBar(left: IconTap(GI.back, label: 'Odadan çık', onTap: g.leaveRoom), title: 'Oyun lobisi'),
      Container(
        padding: const EdgeInsets.fromLTRB(18, 12, 12, 12),
        decoration: BoxDecoration(color: K.paper, borderRadius: BorderRadius.circular(22), boxShadow: const [BoxShadow(color: Color(0xFF3B2794), offset: Offset(0, 5))]),
        child: Row(children: [
          Expanded(
            child: Semantics(
              label: 'Oda kodu ${g.code.split('').join(' ')}',
              child: ExcludeSemantics(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Oda kodu', style: T.body(13, color: const Color(0xFF5B4C8F), w: 800)),
                  Text(g.code.length == 6 ? '${g.code.substring(0, 3)} ${g.code.substring(3)}' : g.code, style: T.display(34, color: K.ink, height: 1).copyWith(letterSpacing: 3)),
                ]),
              ),
            ),
          ),
          IconTap(GI.copy, label: 'Kodu kopyala', color: const Color(0xFFEDE4FF), iconColor: K.ink, onTap: () => copy(g.code, 'Oda kodu kopyalandı')),
          const SizedBox(width: 8),
          IconTap(GI.share, label: 'Daveti paylaş', color: const Color(0xFFEDE4FF), iconColor: K.ink,
              onTap: () => copy('ÇILGIN KAFALAR! odama gel. Oda kodu: ${g.code}', 'Davet mesajı kopyalandı. İstediğin uygulamaya yapıştır.')),
        ]),
      ),
      const SizedBox(height: 18),
      Row(children: [
        Text('Oyuncular $n/6', style: T.display(19)),
        const Spacer(),
        Text('$rd hazır', style: T.body(13, color: K.lilac)),
      ]),
      const SizedBox(height: 10),
      GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 2.1,
        children: [for (var i = 0; i < 6; i++) i < n ? _PlayerCard(g.players[i], canKick: host && !g.players[i].isMe) : const _EmptySlot()],
      ),
      const Spacer(),
      Semantics(
        liveRegion: true,
        child: Text(host ? (blocker ?? 'Herkes hazır. Maçı başlatabilirsin.') : (blocker ?? '$hostName maçı başlatmak üzere…'),
            textAlign: TextAlign.center, style: T.body(14, color: K.lilac)),
      ),
      const SizedBox(height: 10),
      if (me != null)
        me.ready ? GameButton.ghost(label: 'HAZIR DEĞİLİM', onTap: g.toggleReady) : GameButton.secondary(label: 'HAZIRIM', onTap: g.toggleReady),
      if (host) ...[
        const SizedBox(height: 12),
        GameButton(label: 'OYUNU BAŞLAT', onTap: blocker == null ? g.startPreferences : null),
      ],
    ]);
  }
}

class _PlayerCard extends StatelessWidget {
  final Player p;
  final bool canKick;
  const _PlayerCard(this.p, {required this.canKick});
  @override
  Widget build(BuildContext context) {
    final g = GameScope.read(context);
    return Enter(
      key: ValueKey(p.id),
      child: Stack(clipBehavior: Clip.none, children: [
        Container(
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
          decoration: BoxDecoration(
            color: K.violet7.withValues(alpha: .5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: p.ready ? K.aqua : K.lilac.withValues(alpha: .16), width: 2),
          ),
          child: Row(children: [
            Mascot(p.mascot, mood: p.ready ? Mood.happy : Mood.idle, size: 54),
            const SizedBox(width: 8),
            Expanded(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(p.isMe ? '${p.nick} (sen)' : p.nick, maxLines: 1, overflow: TextOverflow.ellipsis, style: T.body(15, w: 900, height: 1.1)),
                const SizedBox(height: 3),
                Row(children: [
                  if (p.ready) const GameIcon(GI.check, color: K.aqua, size: 13),
                  if (p.ready) const SizedBox(width: 3),
                  Text(p.ready ? 'Hazır' : 'Hazırlanıyor', style: T.body(12, color: p.ready ? K.aqua : K.lilac, w: 800)),
                ]),
              ]),
            ),
          ]),
        ),
        if (p.host) Positioned(left: 8, top: -10, child: Semantics(label: 'Oda sahibi', child: const GameIcon(GI.crown, size: 26))),
        if (canKick)
          Positioned(
            right: 2,
            top: 2,
            child: Semantics(
              button: true,
              label: '${p.nick} adlı oyuncuyu odadan çıkar',
              child: InkResponse(
                onTap: () => g.removePlayer(p.id),
                radius: 22,
                child: const Padding(padding: EdgeInsets.all(8), child: GameIcon(GI.cross, color: K.lilac, size: 14)),
              ),
            ),
          ),
      ]),
    );
  }
}

class _EmptySlot extends StatelessWidget {
  const _EmptySlot();
  @override
  Widget build(BuildContext context) => CustomPaint(
        painter: _DashPainter(),
        child: Center(child: Text('Oyuncu bekleniyor', style: T.body(13, color: K.lilac.withValues(alpha: .6), w: 800))),
      );
}

class _DashPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final path = Path()..addRRect(RRect.fromRectAndRadius((Offset.zero & s).deflate(2), const Radius.circular(20)));
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = K.lilac.withValues(alpha: .3);
    for (final m in path.computeMetrics()) {
      for (double d = 0; d < m.length; d += 12) {
        c.drawPath(m.extractPath(d, d + 6), p);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}

// ---------------- S06 Seni tanıyalım ----------------
class PrefsScreen extends StatelessWidget {
  const PrefsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final g = GameScope.of(context);
    final q = g.myQuestions[g.prefIndex];
    final sel = g.myPrefs[q.id];
    return Column(children: [
      SizedBox(
        height: 60,
        child: Row(children: [
          SizedBox(width: 60, child: g.prefIndex > 0 ? IconTap(GI.back, label: 'Önceki soru', onTap: g.prefBack) : null),
          Expanded(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Semantics(header: true, child: Text('Seni tanıyalım!', style: T.display(24))),
              Text('${g.prefIndex + 1}/6', style: T.body(14, color: K.lilac)),
            ]),
          ),
          const SizedBox(width: 60),
        ]),
      ),
      const SizedBox(height: 6),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        for (var i = 0; i < 6; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == g.prefIndex ? 34 : 22,
            height: 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: i == g.prefIndex ? K.pink : g.myPrefs[g.myQuestions[i].id] != null ? K.sun : K.lilac.withValues(alpha: .25),
            ),
          ),
      ]),
      const SizedBox(height: 16),
      Enter(key: ValueKey(q.id), child: SizedBox(width: double.infinity, child: QuestionCard(q.question))),
      const SizedBox(height: 18),
      for (var i = 0; i < 4; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Enter(
            key: ValueKey('${q.id}$i'),
            delayMs: 60 * i,
            child: AnswerTile(index: i, text: q.options[i], selected: sel == i, onTap: () => g.answerPref(i)),
          ),
        ),
      LinkText(g.swapsLeft > 0 ? 'Bu soruyu değiştir (${g.swapsLeft} hak)' : 'Değiştirme hakkın bitti', onTap: g.swapQuestion),
      const Spacer(),
      Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Expanded(child: Text('Cevabını sadece sen görürsün. Oyunda arkadaşların tahmin edecek.', style: T.body(13, color: K.lilac))),
        const Mascot('pika', mood: Mood.think, size: 72),
      ]),
      const SizedBox(height: 6),
      GameButton(label: g.prefIndex == 5 ? 'BİTİR' : 'DEVAM', onTap: sel == null ? null : g.prefNext),
    ]);
  }
}

class PrefsWaitScreen extends StatelessWidget {
  const PrefsWaitScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final g = GameScope.of(context);
    final done = g.players.where((p) => p.prefDone).length;
    return Column(children: [
      const Spacer(),
      const Mascot('pika', mood: Mood.happy, size: 170),
      const SizedBox(height: 10),
      Text('Cevapların kaydedildi', style: T.display(27)),
      const SizedBox(height: 6),
      Text('Diğer oyuncular cevaplıyor. Kimse kimsenin cevabını görmüyor.', textAlign: TextAlign.center, style: T.body(15, color: K.lilac)),
      const SizedBox(height: 16),
      GPanel(
        child: Column(children: [
          for (final p in g.players)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(children: [
                Avatar(p, done: p.prefDone, showName: false, size: 42),
                const SizedBox(width: 12),
                Expanded(child: Text(p.label, style: T.body(16, w: 800))),
                Text(p.prefDone ? '6/6' : 'yanıtlıyor', style: T.body(14, color: p.prefDone ? K.aqua : K.lilac, w: 800)),
              ]),
            ),
        ]),
      ),
      const SizedBox(height: 12),
      Semantics(liveRegion: true, child: Text('$done/${g.players.length} oyuncu hazır', style: T.body(15, color: K.lilac))),
      const Spacer(),
    ]);
  }
}

/// Basit şekil satırı (sonuç/şamata için).
class SymTile extends StatelessWidget {
  final Sym s;
  final double size;
  const SymTile(this.s, {super.key, this.size = 70});
  @override
  Widget build(BuildContext context) => Semantics(
        label: s.name,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(color: const Color(0xFFEFE6FF), borderRadius: BorderRadius.circular(18)),
          alignment: Alignment.center,
          child: SymbolIcon(s.shape, color: s.color, size: size * .62),
        ),
      );
}
