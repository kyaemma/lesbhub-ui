"""Execute the production fullscreen transaction with deterministic UI doubles."""
from pathlib import Path
import subprocess,tempfile
root=Path(__file__).resolve().parents[1]
source=(root/"src/components/window/Init.lua").read_text(encoding="utf-8")
a=source.index("\t-- lesbhub:fullscreen-start");b=source.index("\t-- lesbhub:fullscreen-end",a)
fixture=(root/"tests/fullscreen-fixture.luau").read_text(encoding="utf-8")
with tempfile.TemporaryDirectory() as d:
 path=Path(d)/"fullscreen.luau";path.write_text(fixture.replace("-- PRODUCTION",source[a:b]),encoding="utf-8")
 subprocess.run(["luau",str(path)],check=True)
