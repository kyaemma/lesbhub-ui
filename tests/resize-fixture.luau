local function signal()
    local s={listeners={}}
    function s:Connect(fn)
        local conn={Connected=true}
        function conn:Disconnect() self.Connected=false end
        table.insert(self.listeners,{conn,fn}); return conn
    end
    function s:Fire(...)
        for _,pair in ipairs(table.clone(self.listeners)) do if pair[1].Connected then pair[2](...) end end
    end
    function s:active() local n=0; for _,p in ipairs(self.listeners) do if p[1].Connected then n+=1 end end; return n end
    return s
end
local vecmt={__sub=function(a,b) return setmetatable({X=a.X-b.X,Y=a.Y-b.Y},vecmt) end}
local function v(x,y) return setmetatable({X=x,Y=y},vecmt) end
local UDim2={new=function(xs,x,ys,y) return {X={Scale=xs,Offset=x},Y={Scale=ys,Offset=y}} end}
local Enum={UserInputType={MouseButton1=1,MouseMovement=2,Touch=3},UserInputState={End=1,Cancel=2}}
local UserInputService={InputChanged=signal(),InputEnded=signal(),WindowFocusReleased=signal()}
local RunService={RenderStepped=signal()}
local writes=0
local mainSize=UDim2.new(0,860,0,560)
local main=setmetatable({Parent=true,Visible=true},{__index=function(_,k) if k=="Size" then return mainSize end end,
    __newindex=function(_,k,val) if k=="Size" then writes+=1;mainSize=val else rawset(_,k,val) end end})
local Window={Destroyed=false,Closed=false,Resizable=true,CanResize=true,IsFullscreen=false,
    UIElements={Main=main}, Size=mainSize, MinSize={X=720,Y=460},MaxSize={X=1120,Y=760}, Resizing=false}
local wind={GenerateGUID=function() return "resize" end, UIScaleObj={Scale=1}, ScreenGui={Enabled=true}}
local Config={WindUI=wind}
local ResizeHandle={InputBegan=signal(),ImageLabel={}}
local FullScreenIcon={Active=false}
local Creator={AddSignal=function(s,f) return s:Connect(f) end, SafeCallback=function(f) f() end}
local tweens=0
local function Tween() tweens+=1; return {Play=function() end} end
local finishResize=function() end
local fullscreenTween
-- PRODUCTION
local ended=0
Window.OnResizeFinished=function() ended+=1 end
local function input(t,x,y) return {UserInputType=t,Position=v(x,y),Changed=signal()} end
local function begin(t) local p=input(t or 1,0,0); ResizeHandle.InputBegan:Fire(p); assert(Window.Resizing and wind.CurrentInput=="resize"); return p end
local function move(x,y) UserInputService.InputChanged:Fire(input(2,x,y)) end
local function finish(p) p.UserInputState=Enum.UserInputState.End; p.Changed:Fire() end
local function reset() mainSize=UDim2.new(0,860,0,560); Window.Size=mainSize; wind.UIScaleObj.Scale=1; writes=0 end
local p=begin(); for i=1,100 do move(i,0) end
assert(writes==0); RunService.RenderStepped:Fire(); assert(writes==1 and main.Size.X.Offset==1060)
RunService.RenderStepped:Fire(); assert(writes==1)
move(1000,1000); RunService.RenderStepped:Fire(); assert(writes==2 and main.Size.X.Offset==1120 and main.Size.Y.Offset==760)
move(2000,2000); RunService.RenderStepped:Fire(); assert(writes==2)
finish(p); assert(not Window.Resizing and wind.CurrentInput==nil and RunService.RenderStepped:active()==0)
reset();p=begin();for i=1,50 do move(i,0) end;RunService.RenderStepped:Fire();for i=51,100 do move(i,0) end;RunService.RenderStepped:Fire();assert(writes==2 and main.Size.X.Offset==1060);finish(p)
reset();p=begin();move(30,10);finish(p);assert(writes==1 and main.Size.X.Offset==920)
reset();p=begin();move(20,0);local before=ended;UserInputService.WindowFocusReleased:Fire();wind.CurrentInput="other";finish(p);RunService.RenderStepped:Fire();assert(writes==0 and ended==before+1 and wind.CurrentInput=="other");wind.CurrentInput=nil
p=begin(); Window:CancelResize();Window:CancelResize(); assert(not Window.Resizing and RunService.RenderStepped:active()==0)
for _, field in ipairs({"CanResize","Resizable"}) do Window[field]=false;ResizeHandle.InputBegan:Fire(input(1,0,0));assert(not wind.CurrentInput and RunService.RenderStepped:active()==0);Window[field]=true end
Window.IsFullscreen=true;ResizeHandle.InputBegan:Fire(input(1,0,0));assert(not wind.CurrentInput);Window.IsFullscreen=false
p=begin();ResizeHandle.InputBegan:Fire(input(1,0,0));assert(RunService.RenderStepped:active()==1);finish(p)
reset();local touch=begin(3);local other=input(3,100,100);UserInputService.InputChanged:Fire(other);UserInputService.InputEnded:Fire(other);RunService.RenderStepped:Fire();assert(writes==0 and Window.Resizing);touch.Position=v(25,10);UserInputService.InputChanged:Fire(touch);RunService.RenderStepped:Fire();assert(writes==1 and main.Size.X.Offset==910);UserInputService.InputEnded:Fire(touch);assert(not Window.Resizing)
for _,scale in ipairs({1,0.75,0.5}) do reset();wind.UIScaleObj.Scale=scale;p=begin();move(20*scale,10*scale);RunService.RenderStepped:Fire();assert(main.Size.X.Offset==900 and main.Size.Y.Offset==580);finish(p) end
reset();p=begin();move(20,0);RunService.RenderStepped:Fire();wind.UIScaleObj.Scale=0.5;move(30,0);RunService.RenderStepped:Fire();assert(main.Size.X.Offset==900);move(40,0);RunService.RenderStepped:Fire();assert(main.Size.X.Offset==940);finish(p)
for i=1,200 do reset();p=begin();move(10,0);finish(p);assert(RunService.RenderStepped:active()==0 and UserInputService.InputEnded:active()==0 and UserInputService.WindowFocusReleased:active()==0 and p.Changed:active()==0) end
reset();p=begin();move(20,0);Window.Destroyed=true;RunService.RenderStepped:Fire();Window:CancelResize();assert(writes==0 and not Window.Resizing and not wind.CurrentInput);Window.Destroyed=false
print("Resize: frame coalescing, clamping, final flush, focus, input ownership, scale, 200 clean cycles and destroy passed")
