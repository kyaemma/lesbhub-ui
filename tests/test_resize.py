"""Run the production resize state machine with deterministic input signals."""
from pathlib import Path
import subprocess
import tempfile
root = Path(__file__).resolve().parents[1]
source = (root / "src/components/window/Init.lua").read_text(encoding="utf-8")
start = source.index("\t-- lesbhub:resize-start")
end = source.index("\t-- lesbhub:resize-end",start)
fixture = (root / "tests/resize-fixture.luau").read_text(encoding="utf-8")
with tempfile.TemporaryDirectory() as d:
    path = Path(d)/"resize.luau"
    path.write_text(fixture.replace("-- PRODUCTION",source[start:end]),encoding="utf-8")
    subprocess.run(["luau",str(path)],check=True)
