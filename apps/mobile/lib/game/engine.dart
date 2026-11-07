import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../data/content.dart';

/// Ekranlar (şartnamedeki S01–S13).
enum Scr { splash, menu, room, pick, lobby, prefs, prefsWait, intro, round, result, finale, settings }

enum RoundType { knowing, fact, shamata }

enum NetState { online, maintenance, offline }

enum Mood { idle, happy, think, surprised, sad, victory }

/// Görsel efekt istekleri; Flame katmanı dinler.
enum FxKind { stars, confetti, balloons, banana, shake }

class FxEvent {
  final FxKind kind;
  final String? playerId;
  const FxEvent(this.kind, {this.playerId});
}

class Player {
  final String id;
  String nick, mascot;
  final bool isMe, isBot;
  bool host, ready = false, prefDone = false;
  Map<String, int> prefs = {};
  List<String> questionIds = prefQuestions.map((q) => q.id).toList();
  int score = 0, knowPts = 0, factPts = 0, shamataPts = 0;
  Player({required this.id, required this.nick, required this.mascot, this.isMe = false, this.isBot = false, this.host = false});
  String get label => isMe ? 'Sen' : nick;
}

class Answer {
  final int index;
  final double remaining;
  const Answer(this.index, this.remaining);
}

class Round {
  final RoundType type;
  final String prompt;
  final List<String> options;
  final int correct;
  final String? targetId, explanation;
  final bool? factTrue;
  final List<Sym>? shown, optionSymbols;
  final Map<String, Answer> answers = {};
  Map<String, int> gain = {};
  int duration = 20, right = 0;
  bool memorizing = false, done = false, revealed = false;
  DateTime? endsAt;
  FxKind? cosmetic;
  String? slipId;
  Round({required this.type, required this.prompt, required this.options, required this.correct,
      this.targetId, this.explanation, this.factTrue, this.shown, this.optionSymbols});
}

class Settings {
  bool sound = true, music = true, haptics = true, reduceMotion = false, effects = true, largeText = false, longTime = false;
}

/// Yerel simülasyon. Gerçek sürümde aynı arayüzü Colyseus istemcisi uygular;
/// sunucu otoritesi (süre, doğru cevap, puan) burada tek yerde toplanır.
class GameEngine extends ChangeNotifier {
  final _rng = Random();
  final settings = Settings();
  final _fx = StreamController<FxEvent>.broadcast();
  final _toast = StreamController<String>.broadcast();
  Stream<FxEvent> get fx => _fx.stream;
  Stream<String> get toasts => _toast.stream;

  Scr screen = Scr.splash;
  Scr settingsReturn = Scr.menu;
  NetState net = NetState.online;
  bool creating = true;
  String nick = '', mascot = 'pof', code = '';
  final players = <Player>[];
  // tercih akışı
  List<PrefQuestion> myQuestions = List.of(prefQuestions);
  final myPrefs = <String, int>{};
  int prefIndex = 0, swapsLeft = 3;
  // maç
  final rounds = <Round>[];
  int roundIndex = 0, resultCountdown = 5;
  double splashProgress = 0;
  bool reconnecting = false;

  final _timers = <Timer>[];
  static const plan = [RoundType.fact, RoundType.knowing, RoundType.shamata, RoundType.knowing, RoundType.fact,
    RoundType.knowing, RoundType.shamata, RoundType.fact, RoundType.knowing, RoundType.shamata, RoundType.fact, RoundType.knowing];

  Player? get me => players.where((p) => p.isMe).firstOrNull;
  Round? get round => roundIndex < rounds.length ? rounds[roundIndex] : null;

  T pick<T>(List<T> l) => l[_rng.nextInt(l.length)];
  double rnd(double a, double b) => a + _rng.nextDouble() * (b - a);

  void _later(Duration d, void Function() f) => _timers.add(Timer(d, f));
  void _every(Duration d, void Function(Timer) f) => _timers.add(Timer.periodic(d, f));
  void _clear() {
    for (final t in _timers) {
      t.cancel();
    }
    _timers.clear();
  }

  void go(Scr s) {
    screen = s;
    notifyListeners();
  }

  void toast(String m) => _toast.add(m);
  void emit(FxKind k, {String? playerId}) => _fx.add(FxEvent(k, playerId: playerId));

  // ---------- S01 / S02 ----------
  void startSplash() {
    _clear();
    splashProgress = 0;
    go(Scr.splash);
    if (net == NetState.offline) return;
    _every(const Duration(milliseconds: 50), (t) {
      splashProgress = min(1, splashProgress + 0.035);
      notifyListeners();
      if (splashProgress >= 1) {
        _clear();
        _later(const Duration(milliseconds: 300), () => go(Scr.menu));
      }
    });
  }

  void setNet(NetState n) {
    net = n;
    notifyListeners();
  }

  void openSettings() {
    settingsReturn = screen == Scr.settings ? Scr.menu : screen;
    go(Scr.settings);
  }

  void closeSettings() => go(settingsReturn);

  // ---------- S04 ----------
  void openRoom(bool create) {
    _clear();
    creating = create;
    go(Scr.room);
  }

  String randomNick() => '${pick(nicknameAdjectives)} ${pick(nicknameNouns)}';

  String? nickError(String n) {
    n = n.trim();
    if (n.length < 2) return 'Takma ad en az 2 karakter olmalı.';
    if (n.length > 16) return 'Takma ad en fazla 16 karakter olabilir.';
    final low = '${n.toLowerCase()} ';
    if (blockedWords.any(low.contains)) return 'Bu takma ad kullanılamıyor. Başka bir ad dene ya da zar at.';
    return null;
  }

  String? codeError(String c) {
    if (c.length != 6) return 'Oda kodu 6 karakter olmalı.';
    if (c == 'DOLU66') return 'Bu oda dolu (6/6). Oda sahibinden yeni oda kurmasını iste.';
    if (c == 'BASLAD') return 'Bu odada maç başladı. Bir sonraki maçta katılabilirsin.';
    if (c == 'ESKI99') return 'Bu kodun süresi doldu. Oda sahibinden yeni kod iste.';
    return null;
  }

  String generateCode() {
    const a = '23456789ABCDEFGHJKMNPQRSTUVWXYZ';
    return List.generate(6, (_) => a[_rng.nextInt(a.length)]).join();
  }

  void confirmRoom(String nickname, String joinCode) {
    nick = nickname.trim();
    code = creating ? generateCode() : joinCode;
    go(Scr.pick);
  }

  // ---------- S03 ----------
  void chooseMascot(String id) {
    mascot = id;
    notifyListeners();
  }

  // ---------- S05 ----------
  Player _bot(int i, {bool host = false}) =>
      Player(id: 'b$i', nick: botProfiles[i].$1, mascot: botProfiles[i].$2, isBot: true, host: host);

  void enterLobby({bool fresh = true}) {
    _clear();
    if (fresh) {
      players.clear();
      if (creating) {
        players.add(Player(id: 'me', nick: nick.isEmpty ? 'Sen' : nick, mascot: mascot, isMe: true, host: true));
      } else {
        players.addAll([_bot(0, host: true)..ready = true, _bot(1),
          Player(id: 'me', nick: nick.isEmpty ? 'Sen' : nick, mascot: mascot, isMe: true)]);
      }
    } else {
      for (final p in players) {
        p.ready = p.isBot && p.host;
        p.score = p.knowPts = p.factPts = p.shamataPts = 0;
      }
    }
    go(Scr.lobby);
    for (final ms in [900, 2300, 3800]) {
      _later(Duration(milliseconds: ms), () {
        if (screen == Scr.lobby && players.length < 4) addBot(quiet: true);
      });
    }
    _every(const Duration(milliseconds: 1100), (_) {
      if (screen != Scr.lobby) return;
      final waiting = players.where((p) => p.isBot && !p.ready).toList();
      if (waiting.isNotEmpty && _rng.nextBool()) {
        waiting.first.ready = true;
        notifyListeners();
        _checkAutoStart();
      }
    });
  }

  bool addBot({bool quiet = false}) {
    if (players.length >= 6) {
      toast('Oda dolu (6/6). 7. oyuncu katılamaz.');
      return false;
    }
    final used = players.map((p) => p.id).toSet();
    final i = List.generate(botProfiles.length, (i) => i).where((i) => !used.contains('b$i')).firstOrNull;
    if (i == null) return false;
    players.add(_bot(i));
    if (!quiet) toast('${botProfiles[i].$1} odaya katıldı');
    notifyListeners();
    return true;
  }

  void removePlayer(String id) {
    final p = players.where((x) => x.id == id).firstOrNull;
    if (p == null || p.isMe) return;
    players.remove(p);
    toast('${p.nick} odadan çıkarıldı');
    notifyListeners();
  }

  String? get startBlocker {
    final n = players.length, rd = players.where((p) => p.ready).length;
    if (n < 3) return 'Başlamak için en az 3 oyuncu gerekli. Şu an $n kişisiniz.';
    if (rd < n) return 'Herkes hazır olunca başlayabilirsiniz ($rd/$n hazır).';
    return null;
  }

  void toggleReady() {
    me!.ready = !me!.ready;
    notifyListeners();
    _checkAutoStart();
  }

  bool _autoStarting = false;
  void _checkAutoStart() {
    if (me?.host ?? true) return;
    if (startBlocker == null && !_autoStarting) {
      _autoStarting = true;
      _later(const Duration(milliseconds: 2200), () {
        _autoStarting = false;
        if (screen == Scr.lobby && startBlocker == null) startPreferences();
      });
    }
  }

  void leaveRoom() {
    _clear();
    players.clear();
    go(Scr.menu);
  }

  // ---------- S06 ----------
  void startPreferences() {
    _clear();
    myPrefs.clear();
    myQuestions = List.of(prefQuestions);
    swapsLeft = 3;
    prefIndex = 0;
    for (final p in players) {
      p.ready = false;
      p.prefDone = false;
      if (p.isBot) p.prefs = {for (final q in prefQuestions) q.id: _rng.nextInt(4)};
    }
    go(Scr.prefs);
  }

  void answerPref(int i) {
    myPrefs[myQuestions[prefIndex].id] = i;
    notifyListeners();
  }

  void prefNext() {
    if (myPrefs[myQuestions[prefIndex].id] == null) return;
    if (prefIndex < 5) {
      prefIndex++;
      notifyListeners();
    } else {
      _prefWait();
    }
  }

  void prefBack() {
    if (prefIndex > 0) {
      prefIndex--;
      notifyListeners();
    }
  }

  void swapQuestion() {
    if (swapsLeft == 0) return;
    final used = myQuestions.map((q) => q.id).toSet();
    final alt = reserveQuestions.where((q) => !used.contains(q.id)).firstOrNull;
    if (alt == null) return;
    myPrefs.remove(myQuestions[prefIndex].id);
    myQuestions[prefIndex] = alt;
    swapsLeft--;
    notifyListeners();
  }

  void _prefWait() {
    _clear();
    final m = me!;
    m.prefDone = true;
    m.prefs = Map.of(myPrefs);
    m.questionIds = myQuestions.map((q) => q.id).toList();
    go(Scr.prefsWait);
    var k = 0;
    for (final p in players.where((p) => p.isBot && !p.prefDone)) {
      _later(Duration(milliseconds: 700 + k++ * 900 + _rng.nextInt(500)), () {
        p.prefDone = true;
        notifyListeners();
        if (players.every((x) => x.prefDone)) _later(const Duration(milliseconds: 900), startMatch);
      });
    }
    if (players.every((x) => x.prefDone)) _later(const Duration(milliseconds: 900), startMatch);
  }

  // ---------- maç ----------
  List<Round> _buildRounds() {
    final factOrder = List.generate(facts.length, (i) => i)..shuffle(_rng);
    final memo = ['missing', 'twice', 'count']..shuffle(_rng);
    var order = <String>[];
    while (order.length < 5) {
      final sh = players.map((p) => p.id).toList()..shuffle(_rng);
      if (order.isNotEmpty && sh.first == order.last) sh.add(sh.removeAt(0));
      order.addAll(sh);
    }
    order = order.sublist(0, 5);
    final usedQ = <String, List<String>>{};
    var fi = 0, ki = 0, si = 0;
    return plan.map((t) {
      switch (t) {
        case RoundType.knowing:
          final tid = order[ki++];
          final p = players.firstWhere((x) => x.id == tid);
          final avail = p.questionIds.where((id) => !(usedQ[tid] ?? []).contains(id)).toList();
          final qid = pick(avail);
          (usedQ[tid] ??= []).add(qid);
          final q = questionById[qid]!;
          return Round(type: t, prompt: q.gameQuestion(p.nick), options: q.options, correct: p.prefs[qid] ?? 0, targetId: tid);
        case RoundType.fact:
          final f = facts[factOrder[fi++]];
          return Round(type: t, prompt: f.text, options: const ['Gerçek', 'Uydurma'], correct: f.isTrue ? 0 : 1,
              explanation: f.explanation, factTrue: f.isTrue);
        case RoundType.shamata:
          return _memoRound(memo[si++ % 3]);
      }
    }).toList();
  }

  Round _memoRound(String kind) {
    final syms = List.of(symbols)..shuffle(_rng);
    if (kind == 'missing') {
      final shown = syms.sublist(0, 4), miss = syms[4];
      final opts = [...shown.sublist(0, 3), miss]..shuffle(_rng);
      return Round(type: RoundType.shamata, prompt: 'Hangisi ekranda yoktu?', options: opts.map((s) => s.name).toList(),
          optionSymbols: opts, correct: opts.indexOf(miss), shown: shown..shuffle(_rng), explanation: '${miss.name} hiç görünmedi.');
    }
    if (kind == 'twice') {
      final four = syms.sublist(0, 4), dup = four.first;
      final shown = [...four, dup, syms[4]]..shuffle(_rng);
      final opts = List.of(four)..shuffle(_rng);
      return Round(type: RoundType.shamata, prompt: 'Hangisi iki kez göründü?', options: opts.map((s) => s.name).toList(),
          optionSymbols: opts, correct: opts.indexOf(dup), shown: shown, explanation: '${dup.name} iki kez göründü.');
    }
    final star = symbols.first, k = 2 + _rng.nextInt(3);
    final others = syms.where((s) => s.shape != SymShape.star).toList();
    final shown = [...List.filled(k, star), ...others.sublist(0, 6 - k)]..shuffle(_rng);
    final nums = [k - 1, k, k + 1, k + 2]..shuffle(_rng);
    return Round(type: RoundType.shamata, prompt: 'Ekranda kaç tane sarı yıldız vardı?',
        options: nums.map((n) => '$n').toList(), correct: nums.indexOf(k), shown: shown, explanation: 'Ekranda $k sarı yıldız vardı.');
  }

  void startMatch() {
    _clear();
    for (final p in players) {
      p.score = p.knowPts = p.factPts = p.shamataPts = 0;
    }
    rounds
      ..clear()
      ..addAll(_buildRounds());
    roundIndex = 0;
    _intro();
  }

  Player playerById(String id) => players.firstWhere((p) => p.id == id);
  List<Player> eligible(Round r) => players.where((p) => !(r.type == RoundType.knowing && p.id == r.targetId)).toList();

  void _intro() {
    _clear();
    go(Scr.intro);
    _later(Duration(milliseconds: settings.reduceMotion ? 1200 : 2000), _openRound);
  }

  double remaining(Round r) {
    if (r.endsAt == null) return r.duration.toDouble();
    return max(0, r.endsAt!.difference(DateTime.now()).inMilliseconds / 1000);
  }

  void _openRound() {
    _clear();
    final r = round!;
    final base = {RoundType.knowing: 20, RoundType.fact: 16, RoundType.shamata: 15}[r.type]!;
    r.duration = (base * (settings.longTime ? 1.5 : 1)).round();
    go(Scr.round);
    if (r.type == RoundType.shamata) {
      r.memorizing = true;
      notifyListeners();
      if (settings.effects) {
        r.cosmetic = pick([FxKind.confetti, FxKind.balloons, FxKind.banana]);
        final bot = pick(players.where((p) => p.isBot).toList());
        if (r.cosmetic == FxKind.banana) r.slipId = bot.id;
        emit(r.cosmetic!, playerId: bot.id);
        toast({FxKind.confetti: 'Şamata! Konfeti yağıyor', FxKind.balloons: 'Şamata! Baloncuk yağmuru',
          FxKind.banana: 'Şamata! ${bot.nick} muz kabuğuna bastı'}[r.cosmetic]!);
      }
      _later(const Duration(seconds: 3), () {
        r.memorizing = false;
        _beginTimer(r);
      });
      return;
    }
    _beginTimer(r);
  }

  void _beginTimer(Round r) {
    r.endsAt = DateTime.now().add(Duration(seconds: r.duration));
    notifyListeners();
    final acc = {RoundType.knowing: .55, RoundType.fact: .68, RoundType.shamata: .6}[r.type]!;
    for (final p in eligible(r).where((p) => p.isBot)) {
      _later(Duration(milliseconds: (rnd(.12, .62) * r.duration * 1000).round()), () {
        var i = r.correct;
        if (_rng.nextDouble() > acc) {
          i = pick(List.generate(r.options.length, (j) => j).where((j) => j != r.correct).toList());
        }
        answer(p.id, i);
      });
    }
    _every(const Duration(milliseconds: 200), (_) {
      notifyListeners();
      if (remaining(r) <= 0 && !r.done) _reveal();
    });
  }

  void answer(String pid, int i) {
    final r = round;
    if (r == null || r.done || r.memorizing || r.answers.containsKey(pid)) return;
    if (r.type == RoundType.knowing && pid == r.targetId) return;
    r.answers[pid] = Answer(i, remaining(r));
    notifyListeners();
    if (eligible(r).every((p) => r.answers.containsKey(p.id))) {
      r.done = true;
      _later(const Duration(milliseconds: 700), _reveal);
    }
  }

  void _reveal() {
    final r = round!;
    if (r.revealed) return;
    r
      ..revealed = true
      ..done = true;
    _clear();
    final rule = {RoundType.knowing: (120, 30), RoundType.fact: (100, 40), RoundType.shamata: (100, 30)}[r.type]!;
    r.gain = {for (final p in players) p.id: 0};
    final el = eligible(r);
    for (final p in el) {
      final a = r.answers[p.id];
      if (a != null && a.index == r.correct) {
        r.right++;
        r.gain[p.id] = r.gain[p.id]! + rule.$1 + (rule.$2 * a.remaining / r.duration).floor();
      }
    }
    if (r.type == RoundType.knowing && r.right > el.length / 2) r.gain[r.targetId!] = r.gain[r.targetId!]! + 30;
    for (final p in players) {
      final g = r.gain[p.id]!;
      p.score += g;
      switch (r.type) {
        case RoundType.knowing:
          p.knowPts += g;
        case RoundType.fact:
          p.factPts += g;
        case RoundType.shamata:
          p.shamataPts += g;
      }
    }
    final mine = r.answers['me'];
    if (mine != null && mine.index == r.correct) {
      emit(FxKind.stars);
    } else if (mine != null) {
      emit(FxKind.shake);
    }
    resultCountdown = 5;
    go(Scr.result);
    _every(const Duration(seconds: 1), (_) {
      resultCountdown--;
      notifyListeners();
      if (resultCountdown <= 0) {
        _clear();
        roundIndex++;
        if (roundIndex < rounds.length) {
          _intro();
        } else {
          _finale();
        }
      }
    });
  }

  int rankOf(Player p) => 1 + players.where((q) => q.score > p.score).length;

  void _finale() {
    _clear();
    go(Scr.finale);
    emit(FxKind.confetti);
  }

  void rematch() {
    creating = me?.host ?? true;
    enterLobby(fresh: false);
  }

  // ---------- demo kontrolleri ----------
  void simulateDrop() {
    reconnecting = true;
    notifyListeners();
    Timer(const Duration(milliseconds: 2600), () {
      reconnecting = false;
      final inMatch = const [Scr.intro, Scr.round, Scr.result].contains(screen);
      toast(inMatch ? 'Tekrar bağlandın. Tur ${roundIndex + 1}/12 devam ediyor.' : 'Tekrar bağlandın.');
      notifyListeners();
    });
  }

  void _ensurePlayers([int n = 4]) {
    if (nick.isEmpty) nick = 'Deniz K';
    if (code.isEmpty) code = generateCode();
    if (me == null) {
      creating = true;
      players
        ..clear()
        ..add(Player(id: 'me', nick: nick, mascot: mascot, isMe: true, host: true));
    }
    while (players.length < n) {
      addBot(quiet: true);
    }
    for (final p in players) {
      p.ready = true;
      p.prefDone = true;
      if (p.prefs.isEmpty) p.prefs = {for (final q in prefQuestions) q.id: _rng.nextInt(4)};
    }
  }

  /// Panelden ekranlara doğrudan geçiş (prototip/test için).
  void jump(Scr s, {RoundType? type}) {
    _clear();
    switch (s) {
      case Scr.splash:
        return startSplash();
      case Scr.lobby:
        if (nick.isEmpty) nick = 'Deniz K';
        if (code.isEmpty) code = generateCode();
        return enterLobby(fresh: me == null);
      case Scr.prefs:
        _ensurePlayers();
        return startPreferences();
      case Scr.intro:
      case Scr.round:
        _ensurePlayers();
        rounds
          ..clear()
          ..addAll(_buildRounds());
        final want = type ?? RoundType.knowing;
        var idx = rounds.indexWhere((r) => r.type == want && r.targetId != 'me');
        if (idx < 0) idx = rounds.indexWhere((r) => r.type == want);
        roundIndex = idx;
        return s == Scr.intro ? _intro() : _openRound();
      case Scr.result:
        _ensurePlayers();
        rounds
          ..clear()
          ..addAll(_buildRounds());
        roundIndex = 0;
        final r = round!;
        r.duration = 16;
        for (final p in eligible(r)) {
          r.answers[p.id] = Answer(_rng.nextDouble() < .65 ? r.correct : 1 - r.correct, rnd(4, 12));
        }
        r.answers['me'] = Answer(r.correct, 11);
        return _reveal();
      case Scr.finale:
        _ensurePlayers(5);
        for (final p in players) {
          p.knowPts = (1 + _rng.nextInt(5)) * 130;
          p.factPts = (1 + _rng.nextInt(4)) * 115;
          p.shamataPts = _rng.nextInt(3) * 112;
          p.score = p.knowPts + p.factPts + p.shamataPts;
        }
        return _finale();
      case Scr.settings:
        return openSettings();
      case Scr.pick:
        if (nick.isEmpty) nick = 'Deniz K';
        return go(Scr.pick);
      default:
        return go(s);
    }
  }

  @override
  void dispose() {
    _clear();
    _fx.close();
    _toast.close();
    super.dispose();
  }
}
