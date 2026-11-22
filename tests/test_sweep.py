"""Run the production theme/font/localization registry sweep."""
from pathlib import Path
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
source = (root / "src/modules/Creator.lua").read_text(encoding="utf-8")
start = source.index("-- lesbhub:sweep-start")
end = source.index("-- lesbhub:sweep-end", start)
fixture = (root / "tests/sweep-fixture.luau").read_text(encoding="utf-8")
with tempfile.TemporaryDirectory() as d:
    path = Path(d) / "sweep.luau"
    path.write_text(fixture.replace("-- PRODUCTION", source[start:end]), encoding="utf-8")
    subprocess.run(["luau", str(path)], check=True)
