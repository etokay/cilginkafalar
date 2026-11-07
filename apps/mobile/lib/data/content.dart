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
  PrefQuestion('PREF_DESSERT', 'Hangi tatlıyı seçerdin?', ['Dondurma', 'Pasta', 'Lokum', 'Sütlaç'], (n) => '$n hangi tatlıyı seçerdi?'),
  PrefQuestion('PREF_VEHICLE', 'Hayalindeki araç hangisi?', ['Roket', 'Denizaltı', 'Uçan halı', 'Dev robot'], (n) => '$n hayalindeki araç olarak hangisini seçti?'),
  PrefQuestion('PREF_WEATHER', 'En sevdiğin hava hangisi?', ['Güneşli', 'Karlı', 'Yağmurlu', 'Rüzgârlı'], (n) => '$n en çok hangi havayı seviyor?'),
  PrefQuestion('PREF_HOBBY', 'Boş bir günde ne yapmak isterdin?', ['Resim yapmak', 'Kitap okumak', 'Bisiklete binmek', 'Oyun oynamak'],
      (n) => 'Boş bir günde $n ne yapmak isterdi?'),
  PrefQuestion('PREF_MAGIC', 'Sihirli bir eşyan olsa hangisi olurdu?', ['Görünmezlik pelerini', 'Uçan süpürge', 'Konuşan ayna', 'Zaman saati'],
      (n) => '$n hangi sihirli eşyayı seçti?'),
  PrefQuestion('PREF_JOB', 'Bir günlüğüne ne olmak isterdin?', ['Astronot', 'Aşçı', 'Dedektif', 'Hayvan bakıcısı'], (n) => '$n bir günlüğüne ne olmak isterdi?'),
  PrefQuestion('PREF_SPORT', 'Hangi sporu denemek isterdin?', ['Yüzme', 'Basketbol', 'Paten', 'Okçuluk'], (n) => '$n hangi sporu denemek isterdi?'),
  PrefQuestion('PREF_PARTY', 'Doğum günü partin hangi temada olsun?', ['Korsan', 'Uzay', 'Dinozor', 'Sihirbaz'], (n) => '$n doğum günü partisi için hangi temayı seçti?'),
  PrefQuestion('PREF_ANIMAL', 'Bir günlüğüne hangi hayvan olmak isterdin?', ['Kartal', 'Yunus', 'Kedi', 'Çita'], (n) => '$n bir günlüğüne hangi hayvan olmak isterdi?'),
];

/// Tüm tercih soruları; her maçta 6'sı rastgele sorulur, kalanlar "soruyu değiştir" için yedektir.
final allPrefQuestions = [...prefQuestions, ...reserveQuestions];

final questionById = {for (final q in allPrefQuestions) q.id: q};

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
  Fact('Yarasalar kördür.', false, 'Yarasalar görebilir. Birçoğu karanlıkta sesin yankısıyla da yolunu bulur.'),
  Fact('Deniz yıldızlarının beyni yoktur.', true, 'Beyin yerine vücutlarına yayılmış bir sinir ağı vardır.'),
  Fact('Muz bitkisi aslında bir ağaç değildir.', true, 'Dev bir otsu bitkidir; gövdesi odun değil, iç içe geçmiş yapraklardır.'),
  Fact('Kutup ayılarının derisi siyahtır.', true, 'Tüyleri beyaz görünür ama altındaki deri siyahtır, güneşin ısısını tutar.'),
  Fact('Venüs, Güneş Sistemi’nin en sıcak gezegenidir.', true, 'Kalın atmosferi ısıyı hapseder; Merkür’den bile sıcaktır.'),
  Fact('İnsanlar beyinlerinin sadece yüzde 10’unu kullanır.', false, 'Bu bir efsane. Gün içinde beynin neredeyse tüm bölgeleri çalışır.'),
  Fact('Japon balıklarının hafızası sadece 3 saniyedir.', false, 'Japon balıkları bir şeyi aylarca hatırlayabilir.'),
  Fact('Domates bilimsel olarak bir meyvedir.', true, 'Çiçekten oluşup tohum taşıdığı için bitki biliminde meyve sayılır.'),
  Fact('Dünya’nın en yüksek dağı K2’dir.', false, 'En yüksek dağ Everest’tir. K2 ikinci sıradadır.'),
  Fact('Develer hörgüçlerinde su depolar.', false, 'Hörgüçlerde yağ depolanır; deve bu yağı enerji olarak kullanır.'),
  Fact('Ses, uzay boşluğunda yayılamaz.', true, 'Sesin yayılması için hava gibi bir ortam gerekir; uzay neredeyse boştur.'),
  Fact('Yıldırım aynı yere iki kez düşmez.', false, 'Düşebilir. Yüksek binalara her yıl defalarca yıldırım düşer.'),
  Fact('Sinek kuşları geriye doğru uçabilir.', true, 'Kanatlarını çok hızlı çırparak havada durabilir ve geri geri uçabilirler.'),
  Fact('Ay kendi ışığını üretir.', false, 'Ay, Güneş’ten gelen ışığı yansıtır.'),
  Fact('Karıncalar kendi ağırlıklarının birkaç katını taşıyabilir.', true, 'Birçok karınca türü kendi ağırlığının 10 katından fazlasını taşır.'),
  Fact('Zürafaların dili koyu mor-mavi renktedir.', true, 'Koyu renk, yaprak yerken dili güneş yanığından korur diye düşünülür.'),
];

/// Yakın tahmin soruları: en yakın tahmin en çok puanı alır.
class Estimate {
  final String question, unit, explanation;
  final double answer, min, max, step;
  const Estimate(this.question, this.answer, this.min, this.max, this.step, this.unit, this.explanation);
}

const estimates = <Estimate>[
  Estimate('Bir örümceğin kaç bacağı vardır?', 8, 0, 20, 1, 'bacak', 'Örümceklerin 8 bacağı vardır; böceklerin ise 6.'),
  Estimate('Türkiye’de kaç il vardır?', 81, 0, 150, 1, 'il', 'Türkiye’de 81 il vardır.'),
  Estimate('Yetişkin bir insanın vücudunda kaç kemik vardır?', 206, 0, 400, 1, 'kemik', 'Bebekler daha fazla kemikle doğar, bazıları büyürken birleşir.'),
  Estimate('Bir futbol takımında sahada kaç oyuncu bulunur?', 11, 0, 20, 1, 'oyuncu', 'Kaleci dahil 11 oyuncu.'),
  Estimate('Bir yılda kaç hafta vardır?', 52, 0, 100, 1, 'hafta', '52 hafta ve 1 ya da 2 gün.'),
  Estimate('Maraton koşusu kaç kilometredir?', 42, 0, 100, 1, 'km', 'Tam olarak 42,195 kilometre.'),
  Estimate('Everest Dağı kaç metre yüksekliğindedir?', 8849, 0, 15000, 50, 'metre', 'Everest yaklaşık 8.849 metredir.'),
  Estimate('Bir satranç tahtasında kaç kare vardır?', 64, 0, 120, 1, 'kare', '8 sıra × 8 sütun = 64 kare.'),
  Estimate('Deniz seviyesinde su kaç derecede kaynar?', 100, 0, 200, 1, '°C', 'Deniz seviyesinde su 100 °C’de kaynar.'),
  Estimate('Bir arının kaç bacağı vardır?', 6, 0, 12, 1, 'bacak', 'Arılar böcektir; bütün böceklerin 6 bacağı vardır.'),
  Estimate('Güneş Sistemi’nde kaç gezegen vardır?', 8, 0, 15, 1, 'gezegen', 'Merkür’den Neptün’e 8 gezegen.'),
  Estimate('Bir yıl kaç gündür?', 365, 0, 500, 1, 'gün', 'Artık yıllarda 366 gündür.'),
];

/// Sırala: maddeleri doğru sıraya dizme.
class OrderPuzzle {
  final String question, explanation;
  final List<String> items; // doğru sırada
  const OrderPuzzle(this.question, this.items, this.explanation);
}

const orderPuzzles = <OrderPuzzle>[
  OrderPuzzle('Küçükten büyüğe sırala', ['Fare', 'Kedi', 'At', 'Fil'], 'Fare en küçük, fil en büyük.'),
  OrderPuzzle('Güneş’e en yakından en uzağa sırala', ['Merkür', 'Venüs', 'Dünya', 'Mars'], 'Merkür Güneş’e en yakın gezegendir.'),
  OrderPuzzle('Kısadan uzuna sırala', ['Saniye', 'Dakika', 'Saat', 'Gün'], '60 saniye bir dakika, 24 saat bir gün eder.'),
  OrderPuzzle('Yavaştan hızlıya sırala', ['Salyangoz', 'Kaplumbağa', 'İnsan', 'Çita'], 'Çita karadaki en hızlı hayvandır.'),
  OrderPuzzle('Az bacaklıdan çok bacaklıya sırala', ['Yılan', 'Tavuk', 'Köpek', 'Örümcek'], '0, 2, 4 ve 8 bacak.'),
  OrderPuzzle('Eskiden yeniye sırala', ['Dinozorlar', 'Piramitler', 'Matbaa', 'Akıllı telefon'], 'Dinozorlar milyonlarca yıl önce yaşadı.'),
  OrderPuzzle('Küçükten büyüğe sırala', ['Ay', 'Mars', 'Dünya', 'Jüpiter'], 'Jüpiter Güneş Sistemi’nin en büyük gezegenidir.'),
  OrderPuzzle('Hafiften ağıra sırala', ['Tüy', 'Elma', 'Karpuz', 'Bisiklet'], 'Tüy birkaç gram, bisiklet kilolarca gelir.'),
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
