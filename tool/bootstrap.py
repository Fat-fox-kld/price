#!/usr/bin/env python3
"""Generate native scaffolding without overwriting application sources."""
from pathlib import Path
import shutil
import subprocess
import tempfile
root = Path(__file__).resolve().parents[1]
if shutil.which('flutter') is None:
    raise SystemExit('Установите Flutter и добавьте flutter в PATH.')
with tempfile.TemporaryDirectory() as tmp:
    generated = Path(tmp) / 'price_compare'
    subprocess.run(['flutter', 'create', '--no-pub', '--platforms=android', '--org=com.example', str(generated)], check=True)
    if (root / 'android').exists():
        raise SystemExit('android уже существует; ничего не перезаписано.')
    shutil.copytree(generated / 'android', root / 'android')
    gradle = root / 'android/app/build.gradle.kts'
    if not gradle.exists():
        raise SystemExit('Шаблон Flutter изменился: настройте minSdk не ниже 24 вручную.')
    gradle.write_text(gradle.read_text().replace('minSdk = flutter.minSdkVersion', 'minSdk = 24'))
subprocess.run(['flutter', 'pub', 'get'], cwd=root, check=True)
print('Далее: flutter analyze; flutter test; flutter run')
