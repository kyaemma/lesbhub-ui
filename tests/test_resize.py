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

start=source.index("\tlocal fullscreenTween")
end=source.index('\n\tCreator.AddSignal(Config.WindUI.ScreenGui:GetPropertyChangedSignal("AbsoluteSize")',start)
fragment=source[start:end]
fixture=r'''
local UDim2={new=function(a,b,c,d) return {X={Scale=a,Offset=b},Y={Scale=c,Offset=d}} end}
local Enum={EasingStyle={Quint=1},EasingDirection={Out=1}}
local original=UDim2.new(0,860,0,560)
local Window={UIElements={Main={Size=original,Position=UDim2.new(.5,0,.5,0)}},Resizable=true,CanResize=true,IsFullscreen=false}
local Config={WindUI={ScreenGui={AbsoluteSize={X=1000,Y=800}},UIScale=1}}
local WindowDragModule={Set=function() end}
local CurrentSize,CurrentPos
local finishes,active,created=0,0,0
local function finishResize() finishes+=1 end
local function Tween(target,_,props)
 created+=1; local playing=false
 return {Play=function() playing=true;active+=1;for k,v in pairs(props) do target[k]=v end end,
  Cancel=function() if playing then active-=1;playing=false end end}
end
-- PRODUCTION
Window:ToggleFullscreen();assert(Window.IsFullscreen and CurrentSize==original and finishes==1 and active==1)
Config.WindUI.ScreenGui.AbsoluteSize={X=1200,Y=900};SetSize();assert(active==0 and Window.UIElements.Main.Size.X.Offset==1180)
Window:ToggleFullscreen();assert(not Window.IsFullscreen and Window.UIElements.Main.Size==original and active==1 and finishes==2)
SetSize();assert(active==0 and Window.UIElements.Main.Size==original)
print("Fullscreen: manual resize cancellation, viewport update and original-size restoration passed")
'''
with tempfile.TemporaryDirectory() as d:
 path=Path(d)/"fullscreen.luau";path.write_text(fixture.replace("-- PRODUCTION",fragment),encoding="utf-8")
 subprocess.run(["luau",str(path)],check=True)
