"""Execute the fork's portable WindUI behaviors outside Roblox."""
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "src"


def extract(path, start, end):
    text = path.read_text(encoding="utf-8")
    begin = text.index(start) + len(start)
    finish = text.index(end, begin)
    return text[begin:finish]


def run_luau(source):
    runtime = shutil.which("luau")
    if not runtime:
        raise SystemExit("Official luau runtime is not on PATH")
    with tempfile.TemporaryDirectory() as directory:
        path = Path(directory) / "case.luau"
        path.write_text(source, encoding="utf-8")
        subprocess.run([runtime, str(path)], check=True)


def main():
    focus = extract(
        SRC / "components/window/Tab.lua",
        "-- lesbhub:focus-start\n",
        "\n\t-- lesbhub:focus-end",
    )
    compact = extract(
        SRC / "modules/Creator.lua",
        "-- lesbhub:compact-start\n",
        "\n-- lesbhub:compact-end",
    )
    fixture = (ROOT / "tests/focus-fixture.luau").read_text(encoding="utf-8")
    run_luau(fixture.replace("-- PRODUCTION", focus))
    run_luau((ROOT / "tests/signal-fixture.luau").read_text(encoding="utf-8").replace("-- PRODUCTION", compact))

    owned = [
        SRC / "Init.lua",
        SRC / "modules/Creator.lua",
        SRC / "elements/Init.lua",
        SRC / "elements/Paragraph.lua",
        SRC / "elements/Keybind.lua",
        SRC / "components/Notification.lua",
        SRC / "components/ui/Dropdown.lua",
        SRC / "components/window/Init.lua",
        SRC / "components/window/Tab.lua",
        SRC / "components/window/Section.lua",
    ]
    tree = "\n".join(path.read_text(encoding="utf-8") for path in owned)
    for forbidden in ("Lifecycle", "LesbianHub", "lesbianhub", "GhostVector", "FireServer", "webhook"):
        if forbidden in tree:
            raise SystemExit(f"Private marker leaked into a migrated module: {forbidden}")

    required = {
        "options.GuiParent": SRC / "Init.lua",
        "CloseBehavior": SRC / "components/window/Init.lua",
        "HideMinimizeButton": SRC / "components/window/Init.lua",
        "ButtonsLayout": SRC / "elements/Paragraph.lua",
        "AddGlobalInputBegan": SRC / "modules/Creator.lua",
        "DestroyAll": SRC / "components/Notification.lua",
        "table.find(list, content)": SRC / "elements/Init.lua",
        "MouseButton3": SRC / "elements/Keybind.lua",
        "lesbhub:sweep-start": SRC / "modules/Creator.lua",
    }
    for needle, path in required.items():
        if needle not in path.read_text(encoding="utf-8"):
            raise SystemExit(f"Missing {needle} in {path}")

    package = (ROOT / "package.json").read_text(encoding="utf-8")
    if '"license": "MIT"' not in package or "Footagesus" not in package:
        raise SystemExit("MIT license or upstream credit is missing from package.json")
    icons = ROOT / "src/Icons/lucide/dist/Icons.lua"
    if not icons.is_file():
        raise SystemExit("Icons submodule is not checked out")
    print("Parity: focus, signal compaction, scope boundary and submodule presence passed")


if __name__ == "__main__":
    sys.exit(main())
