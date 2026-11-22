"""Run the production tab parking and SelectTab blocks with deterministic UI doubles."""
from pathlib import Path
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]


def block(path, name):
    source = (root / path).read_text(encoding="utf-8")
    start = source.index(f"-- lesbhub:{name}-start")
    end = source.index(f"-- lesbhub:{name}-end", start)
    return source[start:end]


fixture = (root / "tests/tab-parking-fixture.luau").read_text(encoding="utf-8")
fixture = fixture.replace("-- PRODUCTION_PARKING", block("src/components/window/Init.lua", "tab-parking"))
fixture = fixture.replace("-- PRODUCTION_SELECT", block("src/components/window/Tab.lua", "tab-select"))
with tempfile.TemporaryDirectory() as d:
    path = Path(d) / "tab-parking.luau"
    path.write_text(fixture, encoding="utf-8")
    subprocess.run(["luau", str(path)], check=True)
