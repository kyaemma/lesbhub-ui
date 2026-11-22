"""Run the production shape image override block."""
from pathlib import Path
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
source = (root / "src/modules/DynamicShape.lua").read_text(encoding="utf-8")
start = source.index("-- lesbhub:shape-override-start")
end = source.index("-- lesbhub:shape-override-end", start)
fixture = (root / "tests/shape-override-fixture.luau").read_text(encoding="utf-8")
with tempfile.TemporaryDirectory() as d:
    path = Path(d) / "shape-override.luau"
    path.write_text(fixture.replace("-- PRODUCTION", source[start:end]), encoding="utf-8")
    subprocess.run(["luau", str(path)], check=True)
