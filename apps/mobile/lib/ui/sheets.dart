import 'package:flutter/material.dart';

import '../game/engine.dart';
import '../theme.dart';
import 'widgets.dart';

Future<void> _sheet(BuildContext context, String title, Widget body) => showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      barrierColor: const Color(0xA80E0928),
      builder: (c) => Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(c).height * .86, maxWidth: 520),
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 30),
        decoration: const BoxDecoration(
          color: Color(0xFF2C2177),
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          border: Border(top: BorderSide(color: K.violet5, width: 3)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Center(child: Container(width: 44, height: 5, decoration: BoxDecoration(color: K.lilac.withValues(alpha: .4), borderRadius: BorderRadius.circular(3)))),
              const SizedBox(height: 14),
              Semantics(header: true, child: Text(title, style: T.display(24))),
              const SizedBox(height: 12),
              body,
              const SizedBox(height: 18),
              GameButton.secondary(label: 'Kapat', onTap: () => Navigator.pop(c)),
            ]),
          ),
        ),
      ),
    );

Widget _item(String lead, String text) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 26, child: Text(lead, style: T.display(18, color: K.sun))),
        Expanded(child: Text(text, style: T.body(15, color: K.lilac))),
      ]),
    );

void showHowTo(BuildContext context) => _sheet(
    context,
    'Nasıl oynanır?',
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _item('1', 'Oda kur ya da arkadaşının verdiği kodla katıl. 3–6 kişi gerekir.'),
      _item('2', 'Kendin hakkında 6 eğlenceli soruyu cevapla. Cevaplarını kimse görmez.'),
      _item('3', '12 turda arkadaşlarının cevaplarını tahmin et, şaşırtıcı bilgileri çöz, şamata turlarında dikkatini topla.'),
      const SizedBox(height: 4),
      Text('Yanlış cevap puan düşürmez. Hızlı doğru cevaplar biraz daha fazla puan kazanır.', style: T.body(14, color: K.paper)),
    ]));

void showPrivacy(BuildContext context) => _sheet(
    context,
    'Gizlilik',
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _item('•', 'Odalar sadece kodla açılır. Herkese açık oda ya da yabancılarla eşleşme yok.'),
      _item('•', 'Sohbet, fotoğraf, ses ve video paylaşımı yok.'),
      _item('•', 'Gerçek ad, okul, adres, telefon ya da e-posta istemiyoruz.'),
      _item('•', 'Tercih cevapların sadece bu maç için tutulur ve maç bitince silinir.'),
      Text('Prototip metni. Yayından önce hukuki inceleme yapılacak.', style: T.body(12, color: K.lilac)),
    ]));

void showParentGate(BuildContext context, String what) {
  final a = 6 + DateTime.now().millisecond % 7, b = 5 + DateTime.now().second % 8;
  var v = '';
  final g = GameScope.read(context);
  _sheet(
    context,
    'Bir yetişkin devam etsin',
    StatefulBuilder(
      builder: (c, set) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('$what bölümü yetişkinler içindir. Devam etmek için soruyu yanıtla.', style: T.body(15, color: K.lilac)),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(color: K.paper, borderRadius: BorderRadius.circular(18)),
          child: Row(children: [
            Text('$a + $b = ?', style: T.display(26, color: K.ink)),
            const Spacer(),
            Text(v.isEmpty ? '…' : v, style: T.display(28, color: K.ink)),
          ]),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 2.2,
          children: [
            for (final k in ['1', '2', '3', '4', '5', '6', '7', '8', '9', 'Sil', '0', 'Tamam'])
              GameButton(
                label: k,
                height: 44,
                depth: 4,
                radius: 14,
                hPad: 0,
                color: k == 'Tamam' ? K.sun : const Color(0xFF3A2D86),
                textColor: k == 'Tamam' ? K.ink : K.paper,
                onTap: () {
                  if (k == 'Sil') {
                    set(() => v = v.isEmpty ? v : v.substring(0, v.length - 1));
                  } else if (k == 'Tamam') {
                    Navigator.pop(c);
                    g.toast(int.tryParse(v) == a + b ? '$what sayfası burada açılacak (prototip).' : 'Cevap yanlış. Bir yetişkinden yardım iste.');
                  } else if (v.length < 3) {
                    set(() => v += k);
                  }
                },
              ),
          ],
        ),
      ]),
    ),
  );
}

const screenNames = {
  Scr.splash: 'S01 Açılış',
  Scr.menu: 'S02 Ana menü',
  Scr.pick: 'S03 Maskot seçimi',
  Scr.room: 'S04 Oda kur / katıl',
  Scr.lobby: 'S05 Lobi',
  Scr.prefs: 'S06 Seni tanıyalım',
  Scr.intro: 'S07 Tur tanıtımı',
  Scr.result: 'S11 Tur sonucu',
  Scr.finale: 'S12 Final',
  Scr.settings: 'S13 Ayarlar',
};

/// Prototip test paneli: ekranlara doğrudan geçiş ve hata durumları.
class TestPanel extends StatelessWidget {
  final VoidCallback? onDone;
  const TestPanel({super.key, this.onDone});
  @override
  Widget build(BuildContext context) {
    final g = GameScope.of(context);
    Widget chip(String t, VoidCallback f, {bool on = false}) => Padding(
          padding: const EdgeInsets.only(right: 6, bottom: 6),
          child: GameButton(
            semanticLabel: t,
            expand: false,
            height: 36,
            depth: 3,
            radius: 14,
            color: on ? K.sun : const Color(0xFF3A2D86),
            textColor: on ? K.ink : K.paper,
            onTap: () {
              f();
              onDone?.call();
            },
            child: Text(t, style: T.body(14, color: on ? K.ink : K.paper, w: 900)),
          ),
        );
    final jumps = <(String, VoidCallback)>[
      for (final e in screenNames.entries.where((e) => e.key.index <= Scr.intro.index)) (e.value, () => g.jump(e.key)),
      ('S08 Beni ne kadar tanıyorsun?', () => g.jump(Scr.round, type: RoundType.knowing)),
      ('S09 Gerçek mi uydurma mı?', () => g.jump(Scr.round, type: RoundType.fact)),
      ('S10 Şamata: hafıza', () => g.jump(Scr.round, type: RoundType.memo)),
      ('S10b Şamata: yıldız yağmuru', () => g.jump(Scr.round, type: RoundType.starRain)),
      ('S08b Çoğunluk ne dedi?', () => g.jump(Scr.round, type: RoundType.majority)),
      ('S09b Yakın tahmin', () => g.jump(Scr.round, type: RoundType.estimate)),
      ('S09c Sırala!', () => g.jump(Scr.round, type: RoundType.order)),
      (screenNames[Scr.result]!, () => g.jump(Scr.result)),
      (screenNames[Scr.finale]!, () => g.jump(Scr.finale)),
      (screenNames[Scr.settings]!, () => g.jump(Scr.settings)),
    ];
    jumps.sort((a, b) => a.$1.compareTo(b.$1));
    return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      Text('Ekranlar', style: T.display(17)),
      const SizedBox(height: 8),
      Wrap(children: [for (final j in jumps) chip(j.$1, j.$2)]),
      const SizedBox(height: 10),
      Text('Demo kontrolleri', style: T.display(17)),
      const SizedBox(height: 8),
      Wrap(children: [
        chip('Lobiye oyuncu ekle', () => g.screen == Scr.lobby ? g.addBot() : g.toast('Bu kontrol lobide çalışır.')),
        chip('Bağlantıyı kopar', g.simulateDrop),
        chip('Çevrimiçi', () => g.setNet(NetState.online), on: g.net == NetState.online),
        chip('Bakım', () => g.setNet(NetState.maintenance), on: g.net == NetState.maintenance),
        chip('Bağlantı yok', () => g.setNet(NetState.offline), on: g.net == NetState.offline),
      ]),
      const SizedBox(height: 6),
      Text('Katılım ekranında DOLU66, BASLAD veya ESKI99 kodları hata durumlarını gösterir.', style: T.body(13, color: K.lilac)),
    ]);
  }
}

void showTestPanel(BuildContext context) => _sheet(context, 'Test paneli', Builder(builder: (c) => TestPanel(onDone: () => Navigator.pop(c))));
