# PyInstaller-Bauanleitung für Windows und Linux.
#   pyinstaller --noconfirm packaging/hauslog.spec
# Ergebnis: dist/hauslog/ (eigenständig, ohne installiertes Python lauffähig)
import re
import sys
from pathlib import Path

WURZEL = Path(SPECPATH).parent
VERSION = re.search(
    r'__version__ = "(.+)"', (WURZEL / "src/hauslog/__init__.py").read_text()
).group(1)


def windows_versionsinfo():
    """Angaben unter Eigenschaften → Details der hauslog.exe."""
    from PyInstaller.utils.win32.versioninfo import (
        FixedFileInfo, StringFileInfo, StringStruct, StringTable,
        VarFileInfo, VarStruct, VSVersionInfo,
    )

    nummern = (*map(int, VERSION.split(".")), 0)
    return VSVersionInfo(
        ffi=FixedFileInfo(filevers=nummern, prodvers=nummern),
        kids=[
            StringFileInfo([StringTable("040704B0", [
                StringStruct("FileDescription", "Hauslog"),
                StringStruct("FileVersion", VERSION),
                StringStruct("ProductName", "Hauslog"),
                StringStruct("ProductVersion", VERSION),
                StringStruct("OriginalFilename", "hauslog.exe"),
            ])]),
            VarFileInfo([VarStruct("Translation", [1031, 1200])]),
        ],
    )


# Ungenutzte Qt-Module weglassen, damit das Paket klein bleibt.
UNGENUTZT = [
    "PySide6.QtNetwork", "PySide6.QtQml", "PySide6.QtQuick", "PySide6.QtSql",
    "PySide6.QtTest", "PySide6.QtXml", "PySide6.QtOpenGL",
    "PySide6.QtOpenGLWidgets", "PySide6.QtConcurrent", "PySide6.QtPrintSupport",
    "PySide6.QtSvg", "PySide6.QtSvgWidgets", "tkinter", "unittest", "pydoc",
]

a = Analysis(
    [str(WURZEL / "packaging/start.py")],
    pathex=[str(WURZEL / "src")],
    datas=[(str(WURZEL / "src/hauslog/hauslog.png"), "hauslog")],
    excludes=UNGENUTZT,
    noarchive=False,
)
pyz = PYZ(a.pure)
exe = EXE(
    pyz,
    a.scripts,
    [],
    exclude_binaries=True,
    name="hauslog",
    console=False,
    icon=str(WURZEL / "packaging/windows/hauslog.ico") if sys.platform == "win32" else None,
    version=windows_versionsinfo() if sys.platform == "win32" else None,
)
coll = COLLECT(exe, a.binaries, a.datas, name="hauslog")
