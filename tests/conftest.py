import os

# Qt-Tests ohne sichtbares Fenster (auch in CI ohne Bildschirm)
os.environ.setdefault("QT_QPA_PLATFORM", "offscreen")
