import 'package:flutter/painting.dart';

/// Maskot kimlikleri. Dosya/kod adları ASCII, ekranda Türkçe.
class MascotDef {
  final String id, name, desc;
  final Color base, light, dark, line;
  const MascotDef(this.id, this.name, this.desc, this.base, this.light, this.dark, this.line);
}

const mascots = <String, MascotDef>{
  'pof': MascotDef('pof', 'Pof', 'İyi niyetli, heyecanlı, biraz sakar. Doğru cevapta yıldız saçar.',
      Color(0xFF42BCEC), Color(0xFFB2E9FC), Color(0xFF2167B9), Color(0xFF173E7A)),
  'cakir': MascotDef('cakir', 'Çakır', 'Aceleci ve sportif. Hızlı turların yıldızı.',
      Color(0xFFFF8A2C), Color(0xFFFFCB2B), Color(0xFFC4521A), Color(0xFF5B2463)),
  'minti': MascotDef('minti', 'Minti', 'Meraklı bir mucit. Şaşırtıcı bilgileri büyüteçle bulur.',
      Color(0xFF62D65B), Color(0xFFC2F5AE), Color(0xFF278A57), Color(0xFF174D35)),
  'bidik': MascotDef('bidik', 'Bıdık', 'Her şeye heyecanlanan jöle. Sevinince yay gibi uzar.',
      Color(0xFFFFD94A), Color(0xFFFFF4B8), Color(0xFFF1A72C), Color(0xFF8E4F12)),
  'pika': MascotDef('pika', 'Pika', 'Sosyal bukalemun. Arkadaşlarını en iyi o tanır.',
      Color(0xFFF777BA), Color(0xFFFFC7E3), Color(0xFFC9488C), Color(0xFF6E1A4D)),
  'zipzip': MascotDef('zipzip', 'Zıpzıp', 'Afacan uzaylı. Antenleriyle soru işaretleri yakar.',
      Color(0xFF9250DA), Color(0xFFC9A6FF), Color(0xFF5E2CA5), Color(0xFF2C1455)),
};
const mascotOrder = ['pof', 'cakir', 'minti', 'bidik', 'pika', 'zipzip'];

class PrefQuestion {
  final String id, question;
  final List<String> options;
  final String Function(String nick) gameQuestion;
  const PrefQuestion(this.id, this.question, this.options, this.gameQuestion);
}

final prefQuestions = <PrefQuestion>[
  PrefQuestion('PREF_SUPERPOWER', 'Bir süper gücün olsa hangisini seçerdin?',
      ['Uçmak', 'Işınlanmak', 'Görünmez olmak', 'Hayvanlarla konuşmak'], (n) => '$n bir süper güç seçse hangisini seçerdi?'),
  PrefQuestion('PREF_PET', 'Hayali takım arkadaşın hangi hayvan olsun?', ['Panda', 'Ejderha', 'Penguen', 'Tilki'],
      (n) => '$n hayali takım arkadaşı olarak hangi hayvanı seçti?'),
  PrefQuestion('PREF_TRAVEL', 'Bir günlük maceraya nereye giderdin?',
      ['Uzay', 'Dinozor çağı', 'Deniz altı', 'Şeker gezegeni'], (n) => '$n bir günlük maceraya nereye giderdi?'),
  PrefQuestion('PREF_SKILL', 'Hangi oyun türünde kendine güveniyorsun?', ['Bulmaca', 'Hız', 'Hafıza', 'Tahmin'],
      (n) => '$n hangi oyun türünde kendine güveniyor?'),
  PrefQuestion('PREF_ROBOT', 'Bir robot arkadaşın olsa ne yapsın?',
      ['Oyun oynasın', 'Yemek yapsın', 'Uçursun', 'Şaka yapsın'], (n) => 'Bir robot arkadaşı olsa $n ondan ne isterdi?'),
  PrefQuestion('PREF_BASE', 'Hayali gizli üssün nerede olsun?',
      ['Ağaç ev', 'Uzay istasyonu', 'Denizaltı', 'Bulut şatosu'], (n) => '$n gizli üssünü nereye kurdu?'),
];

final reserveQuestions = <PrefQuestion>[
  PrefQuestion('PREF_SNACK', 'Film gecesinde hangi atıştırmalığı seçerdin?',
      ['Patlamış mısır', 'Meyve tabağı', 'Kurabiye', 'Simit'], (n) => '$n film gecesinde hangi atıştırmalığı seçerdi?'),
  PrefQuestion('PREF_SEASON', 'Hangi mevsimde maceraya çıkardın?', ['İlkbahar', 'Yaz', 'Sonbahar', 'Kış'],
      (n) => '$n hangi mevsimde maceraya çıkardı?'),
  PrefQuestion('PREF_BAND', 'Bir müzik grubu kursan hangi çalgıyı çalardın?', ['Davul', 'Gitar', 'Piyano', 'Ukulele'],
      (n) => 'Bir müzik grubunda $n hangi çalgıyı çalardı?'),
];

final questionById = {for (final q in [...prefQuestions, ...reserveQuestions]) q.id: q};

class Fact {
  final String text, explanation;
  final bool isTrue;
  const Fact(this.text, this.isTrue, this.explanation);
}

/// Başlangıç editör taslağı. Kaynak ve yaş uygunluğu incelemesi bekliyor.
const facts = <Fact>[
  Fact('Ahtapotların üç kalbi vardır.', true, 'Biri vücuda, ikisi solungaçlara kan pompalar.'),
  Fact('Dünya’nın iki doğal Ay’ı vardır.', false, 'Dünya’nın tek kalıcı doğal uydusu Ay’dır.'),
  Fact('Penguenler kuştur.', true, 'Uçamazlar ama tüyleri ve gagaları olan bir kuş grubudur.'),
  Fact('Güneş bir gezegendir.', false, 'Güneş bir yıldızdır. Dünya onun çevresinde döner.'),
  Fact('Balinalar memelidir.', true, 'Akciğerleriyle nefes alır, yavrularını sütle beslerler.'),
  Fact('İnsan vücudundaki en büyük organ kalptir.', false, 'En büyük organ deridir.'),
  Fact('Bal arıları dans ederek çiçeklerin yerini tarif eder.', true,
      'Sallanma dansıyla yönü ve uzaklığı diğer arılara anlatırlar.'),
  Fact('Bukalemunlar renklerini sadece saklanmak için değiştirir.', false,
      'Renk değişimi daha çok ısı ve diğer bukalemunlarla iletişim içindir.'),
];

enum SymShape { star, triangle, square, circle, heart, moon }

class Sym {
  final SymShape shape;
  final String name;
  final Color color;
  const Sym(this.shape, this.name, this.color);
}

const symbols = <Sym>[
  Sym(SymShape.star, 'Sarı yıldız', Color(0xFFFFD343)),
  Sym(SymShape.triangle, 'Pembe üçgen', Color(0xFFF57FCE)),
  Sym(SymShape.square, 'Mavi kare', Color(0xFF44C9F8)),
  Sym(SymShape.circle, 'Turkuaz daire', Color(0xFF35D9C9)),
  Sym(SymShape.heart, 'Turuncu kalp', Color(0xFFFF9330)),
  Sym(SymShape.moon, 'Mor hilal', Color(0xFF825AE6)),
];

/// Cevap kartlarında renk körlüğü için sabit şekil işaretleri.
const answerShapes = [SymShape.circle, SymShape.triangle, SymShape.square, SymShape.star];

const botProfiles = [
  ('Maya', 'pika'),
  ('Deniz', 'minti'),
  ('Kerem', 'cakir'),
  ('Ela', 'bidik'),
  ('Arda', 'zipzip'),
];

const nicknameAdjectives = ['Uçan', 'Neşeli', 'Minik', 'Hızlı', 'Gizli', 'Şeker', 'Zıp', 'Bulut'];
const nicknameNouns = ['Panda', 'Roket', 'Ejder', 'Tilki', 'Kaşif', 'Penguen', 'Mucit', 'Pilot'];
const blockedWords = ['salak', 'aptal', 'gerizekal', 'ahmak', 'mal ', 'kötü'];
