#!/usr/bin/env bash
# Web derlemesi + önbellek kırma: main.dart.js her yayında içeriğe göre yeni ad alır,
# böylece tarayıcılar eski oyun dosyasını önbellekten kullanamaz.
set -euo pipefail
cd "$(dirname "$0")/.."
SURUM=$(git rev-parse --short HEAD 2>/dev/null || echo yerel)
flutter build web --release --no-web-resources-cdn --pwa-strategy=none --no-wasm-dry-run --dart-define=SURUM="$SURUM"
cd build/web
HASH=$(sha256sum main.dart.js | cut -c1-10)
NEW="main.dart.$HASH.js"
mv main.dart.js "$NEW"
[ -f main.dart.js.map ] && mv main.dart.js.map "$NEW.map"
sed -i "s/\"mainJsPath\":\"main.dart.js\"/\"mainJsPath\":\"$NEW\"/" flutter_bootstrap.js
grep -q "$NEW" flutter_bootstrap.js || { echo "flutter_bootstrap.js güncellenemedi" >&2; exit 1; }
# index.html ve bootstrap da sürüm etiketi alsın
sed -i "s/flutter_bootstrap.js\" async/flutter_bootstrap.js?v=$HASH\" async/" index.html
echo "Hazır: build/web ($NEW)"
