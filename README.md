# ÇILGIN KAFALAR!

Aile ve arkadaşların kendi telefonlarından oynadığı, 3–6 kişilik mobil parti oyunu. Ürün şartnamesi: [`docs/product.md`](docs/product.md).

**Durum:** Oynanabilir arayüz prototipi (sürüm 0.1). Diğer oyuncular cihazda simüle edilir; gerçek zamanlı sunucu henüz bağlı değil.

## Neler var

| Alan | İçerik |
|---|---|
| `apps/mobile` | Flutter + Flame istemcisi (Android, iOS, web) |
| Arayüz | Sistem form bileşeni yok: butonlar, kartlar, sayaç, klavye ve geçişler `CustomPainter` ile çizilir |
| Maskotlar | Pof, Çakır, Minti, Bıdık, Pika, Zıpzıp; vektör çizim, 6 ruh hali, nefes/göz kırpma/zıplama/el sallama animasyonu |
| Flame | Arka plan gökyüzü (parlayan yıldızlar, süzülen adacıklar) ve efekt katmanı (yıldız patlaması, konfeti, balon, muz kabuğu) |
| Akış | S01–S13 ekranlarının tamamı, 12 turluk maç (5 tanıma + 4 gerçek/uydurma + 3 şamata), şartnamedeki puan formülleri |
| Erişilebilirlik | Ekran okuyucu etiketleri, renk + şekil işaretli cevaplar, hareketi azalt, büyük metin, uzun süre seçeneği |

Henüz yok: Colyseus oyun sunucusu, gerçek çok oyunculu bağlantı, ses dosyaları, Rive animasyonları, mağaza derlemeleri.

## Kod yapısı

```text
apps/mobile/lib/
├── main.dart              # uygulama kabuğu, ekran geçişleri, Flame katmanları, geniş ekranda test paneli
├── theme.dart             # renk tokenları, Baloo 2 + Nunito tipografi
├── data/content.dart      # maskotlar, tercih soruları, bilgi kartları, şamata sembolleri
├── game/engine.dart       # maç motoru (sunucu otoritesinin yerel simülasyonu)
├── art/                   # maskot, şekil, ikon ve ada çizimleri
├── fx/flame_layers.dart   # SkyGame + FxGame
└── ui/                    # oyun bileşenleri ve ekranlar
```

`GameEngine` sunucunun yapacağı işi (süre, doğru cevap, puan, bot oyuncular) tek yerde toplar. Gerçek sunucu geldiğinde aynı arayüzü Colyseus istemcisi uygulayacak; ekranlar değişmeyecek.

## Çalıştırma

```bash
cd apps/mobile
flutter pub get
flutter run                 # bağlı telefon ya da emülatör
flutter run -d chrome       # tarayıcı
```

Web'de `?ekran=S08` gibi bir parametreyle doğrudan bir ekrana açılır (S02–S13). Telefonda **Ayarlar → Test paneli** aynı işi yapar.

Katılım ekranında `DOLU66`, `BASLAD`, `ESKI99` kodları hata durumlarını gösterir.

## Web yayını (cilginkafalar.io)

```bash
cd apps/mobile
flutter build web --release --no-web-resources-cdn --pwa-strategy=none
```

`build/web` klasörü Hostinger'daki `cilginkafalar.io` sitesinin `public_html` dizinine yüklenir. `web/.htaccess` önbellek ve wasm türü ayarlarını içerir.

## Fontlar

Baloo 2 ve Nunito, SIL Open Font License 1.1 ile [google/fonts](https://github.com/google/fonts) deposundan alınmıştır.
