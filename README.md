# ÇILGIN KAFALAR!

Aile ve arkadaşların kendi telefonlarından oynadığı, 3–6 kişilik mobil parti oyunu. Ürün şartnamesi: [`docs/product.md`](docs/product.md).

**Durum:** Oynanabilir arayüz prototipi (sürüm 0.1). Diğer oyuncular cihazda simüle edilir; gerçek zamanlı sunucu henüz bağlı değil.

## Neler var

| Alan | İçerik |
|---|---|
| `apps/mobile` | Flutter + Flame istemcisi (Android, iOS, web) |
| Görseller | Maskotlar (6 maskot × 6 ruh hali), logo, gökyüzü, uçan ada ve yıldızlar GPT Image 2.6 ile üretildi (Magnific), WebP olarak `assets/` altında |
| Arayüz | Sistem form bileşeni yok: butonlar, kartlar, sayaç, Türkçe Q klavye, kaydırıcı ve geçişler `CustomPainter`/Flutter ile çizilir |
| Flame | Gökyüzü katmanı, efektler (yıldız patlaması, konfeti, balon, muz kabuğu) ve "Yıldız yağmuru" mini oyunu |
| Akış | S01–S13 ekranları, 12 turluk maç, şartnamedeki 5 + 4 + 3 kategori dağılımı |
| Erişilebilirlik | Ekran okuyucu etiketleri, renk + şekil işaretli cevaplar, hareketi azalt, büyük metin, uzun süre seçeneği |

### Oyun türleri

Kategori sırası sabit, her yuvadaki oyun maçtan maça rastgele değişir.

| Kategori (tur) | Oyunlar |
|---|---|
| Tanıma (5) | **Beni ne kadar tanıyorsun?** bir oyuncunun cevabını tahmin et · **Çoğunluk ne dedi?** odanın çoğunun seçtiğini bul |
| Bilgi (4) | **Gerçek mi uydurma mı?** (ilk tur hep bu) · **Yakın tahmin** sayıyı kaydırıcıyla tahmin et · **Sırala!** dört maddeyi doğru sıraya diz |
| Şamata (3) | **Hafıza** 3 sn ezberle, soruyu cevapla · **Yıldız yağmuru** düşen yıldızlara dokun (Flame) |

İçerik havuzu: 18 tercih sorusu (her maçta 6'sı rastgele), 24 bilgi kartı, 12 tahmin sorusu, 8 sıralama bulmacası, 3 hafıza türü. Bilgi içeriği editör kontrolü bekleyen taslaktır.

Henüz yok: Colyseus oyun sunucusu, gerçek çok oyunculu bağlantı, ses dosyaları, Rive animasyonları, mağaza derlemeleri.

## Kod yapısı

```text
apps/mobile/lib/
├── main.dart              # uygulama kabuğu, ekran geçişleri, Flame katmanları, geniş ekranda test paneli
├── theme.dart             # renk tokenları, Baloo 2 + Nunito tipografi
├── data/content.dart      # maskotlar, tercih soruları, bilgi kartları, şamata sembolleri
├── game/engine.dart       # maç motoru (sunucu otoritesinin yerel simülasyonu)
├── art/                   # maskot görselleri, şekil ve ikon çizimleri
├── fx/flame_layers.dart   # SkyGame, FxGame, StarRainGame
└── ui/                    # oyun bileşenleri ve ekranlar
```

`GameEngine` sunucunun yapacağı işi (süre, doğru cevap, puan, bot oyuncular) tek yerde toplar. Gerçek sunucu geldiğinde aynı arayüzü Colyseus istemcisi uygulayacak; ekranlar değişmeyecek.

## Testler

```bash
cd apps/mobile && flutter test   # tur planı, puan formülleri, içerik havuzu
```

## Çalıştırma

```bash
cd apps/mobile
flutter pub get
flutter run                 # bağlı telefon ya da emülatör
flutter run -d chrome       # tarayıcı
```

Web'de `?ekran=S08` gibi bir parametreyle doğrudan bir ekrana açılır (S02–S13; yeni oyunlar için `COGUNLUK`, `TAHMIN`, `SIRALA`, `YILDIZ`). Telefonda **Ayarlar → Test paneli** aynı işi yapar.

Katılım ekranında `DOLU66`, `BASLAD`, `ESKI99` kodları hata durumlarını gösterir.

## Web yayını (cilginkafalar.io)

```bash
cd apps/mobile
flutter build web --release --no-web-resources-cdn --pwa-strategy=none
```

`build/web` klasörü Hostinger'daki `cilginkafalar.io` sitesinin `public_html` dizinine yüklenir. `web/.htaccess` önbellek ve wasm türü ayarlarını içerir.

## Fontlar

Baloo 2 ve Nunito, SIL Open Font License 1.1 ile [google/fonts](https://github.com/google/fonts) deposundan alınmıştır.
