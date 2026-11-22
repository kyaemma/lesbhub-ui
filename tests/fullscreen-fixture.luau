local function signal()
 local s={listeners={}};function s:Connect(fn) local c={Connected=true};function c:Disconnect() self.Connected=false end;table.insert(self.listeners,{c,fn});return c end
 function s:Fire() for _,p in ipairs(table.clone(self.listeners)) do if p[1].Connected then p[2]() end end end
 function s:active() local n=0;for _,p in ipairs(self.listeners) do if p[1].Connected then n+=1 end end;return n end
 return s
end
local mt={__eq=function(a,b) return a.X.Scale==b.X.Scale and a.X.Offset==b.X.Offset and a.Y.Scale==b.Y.Scale and a.Y.Offset==b.Y.Offset end}
local UDim2={new=function(a,b,c,d) return setmetatable({X={Scale=a,Offset=b},Y={Scale=c,Offset=d}},mt) end}
local UDim={new=function(a,b) return {a,b} end}
local Enum={EasingStyle={Quint=1},EasingDirection={Out=1}}
local original=UDim2.new(0,860,0,560);local originalPos=UDim2.new(.4,12,.5,6)
local size,pos=original,originalPos
local sizeWrites,posWrites=0,0
local main=setmetatable({}, {__index=function(_,k) if k=="Size" then return size elseif k=="Position" then return pos end end,
 __newindex=function(_,k,v) if k=="Size" then size=v;sizeWrites+=1 elseif k=="Position" then pos=v;posWrites+=1 else rawset(_,k,v) end end})
local Window={UIElements={Main=main},UICorner=14,Resizable=true,CanResize=true,IsFullscreen=false,Destroyed=false,Closed=false}
local Config={WindUI={ScreenGui={AbsoluteSize={X=1000,Y=800}},UIScale=1}}
local WindowDragModule={Set=function() end}
local CurrentSize,CurrentPos
local finishes,started,ended=0,0,0
local function finishResize() finishes+=1 end
local finishFullscreen=function() end
local openTween
local Creator={SafeCallback=function(f,...) f(...) end}
local activeShells=0
local function New(class,props,children)
 if class=="Frame" then local shell={Outline=children[2],dead=false};activeShells+=1;function shell:Destroy() if not self.dead then self.dead=true;activeShells-=1 end end;return shell end
 return {Transparency=props.Transparency}
end
local lastTween,created,active= nil,0,0
local function Tween(target,_,props)
 assert(target~=main,"transition must not tween root size")
 created+=1; local tween={Completed=signal(),playing=false,target=target,props=props}
 function tween:Play() self.playing=true;active+=1;lastTween=self end
 function tween:Cancel() if self.playing then self.playing=false;active-=1 end end
 function tween:Complete() self:Cancel();self.Completed:Fire() end
 return tween
end
-- PRODUCTION
local trace = {}
Window.FullscreenDiagnostic = function(event, generation, ...) table.insert(trace,{event,generation,...}) end
Window.OnFullscreenTransitionStarted=function() started+=1;assert(Window.FullscreenTransitioning) end
Window.OnFullscreenTransitionFinished=function() ended+=1;assert(not Window.FullscreenTransitioning) end
Window:ToggleFullscreen();assert(Window.IsFullscreen and Window.FullscreenTransitioning and finishes==1)
assert(size.X.Offset==980 and size.Y.Offset==728 and sizeWrites==1 and posWrites==1 and activeShells==1)
local baseline=sizeWrites
for i=1,60 do assert(sizeWrites==baseline) end
lastTween:Complete();assert(not Window.FullscreenTransitioning and active==0 and activeShells==0 and ended==1)
assert(trace[1][1]=="start" and trace[2][1]=="layout" and trace[2][3]==1 and trace[3][1]=="end")
Window:ToggleFullscreen();assert(not Window.IsFullscreen and size==original and pos==originalPos);lastTween:Complete();assert(activeShells==0)
for i=1,20 do Window:ToggleFullscreen() end
assert(not Window.IsFullscreen and size==original and pos==originalPos and active==1 and activeShells==1)
lastTween:Complete();assert(active==0 and activeShells==0)
Window:ToggleFullscreen();local old=lastTween;Config.WindUI.ScreenGui.AbsoluteSize={X=1200,Y=900};SetSize(false);old.Completed:Fire()
assert(Window.IsFullscreen and not Window.FullscreenTransitioning and active==0 and activeShells==0 and size.X.Offset==1180)
Window:ToggleFullscreen();finishFullscreen();assert(not Window.FullscreenTransitioning and size==original and pos==originalPos and activeShells==0)
Window.Resizable=false;Window:ToggleFullscreen();lastTween:Complete();Window:ToggleFullscreen();lastTween:Complete();assert(Window.CanResize==false)
Window.Resizable=true;Window.SearchActive=true;Window:ToggleFullscreen();lastTween:Complete();Window:ToggleFullscreen();lastTween:Complete();assert(not Window.CanResize);Window.SearchActive=false
Config.WindUI.UIScale=.5;Window:ToggleFullscreen();assert(size.X.Offset==2360 and size.Y.Offset==1656);finishFullscreen()
Config.WindUI.UIScale=0;SetSize(false);assert(size.X.Offset==1180)
Window:ToggleFullscreen();finishFullscreen();Window.Closed=true;local before=sizeWrites;Window:ToggleFullscreen();assert(sizeWrites==before and not Window.FullscreenTransitioning)
assert(started==ended and active==0 and activeShells==0)
Window.Closed=false; Config.WindUI.UIScale=1
for i=1,100 do
 Window:ToggleFullscreen();lastTween:Complete()
 assert(not Window.FullscreenTransitioning and active==0 and activeShells==0 and lastTween.Completed:active()==0)
end
Window:ToggleFullscreen();local stale=lastTween;Window.Destroyed=true;finishFullscreen()
local beforeLate=sizeWrites;stale.Completed:Fire();assert(active==0 and activeShells==0 and sizeWrites==beforeLate)
print("Fullscreen: exact geometry, 60 frames without root writes, 20 rapid toggles, viewport, scale and 100 clean transitions passed")
