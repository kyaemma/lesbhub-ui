local tasks = {}
local task = { spawn = function(fn) table.insert(tasks, fn) end, wait = function() end }
local function flush() while #tasks > 0 do table.remove(tasks, 1)() end end
local function signal()
    local s = { listeners = {} }
    function s:Connect(fn)
        local c = { Connected = true }
        function c:Disconnect() self.Connected = false end
        table.insert(self.listeners, { c, fn })
        return c
    end
    function s:Fire(...) for _, pair in ipairs(self.listeners) do if pair[1].Connected then pair[2](...) end end end
    return s
end
local created, destroyed = 0, 0
local methods = {}
function methods:GetChildren() return self.children end
function methods:IsA(name) return self.ClassName == name end
function methods:GetPropertyChangedSignal(name) self.signals[name] = self.signals[name] or signal(); return self.signals[name] end
function methods:Destroy()
    if self.dead then return end
    self.dead = true; destroyed += 1
    for _, child in ipairs(table.clone(self.children)) do child:Destroy() end
    for _, sig in pairs(self.signals) do for _, pair in ipairs(sig.listeners) do pair[1]:Disconnect() end end
    if self.Parent and self.Parent.children then local i = table.find(self.Parent.children, self); if i then table.remove(self.Parent.children, i) end end
end
local function new(class, props, children)
    created += 1
    local o = setmetatable({ClassName = class, Name = class, children = {}, signals = {}, AbsoluteContentSize = {X=100,Y=80}, AbsoluteSize = {X=200,Y=200}, AbsolutePosition={X=0,Y=0}}, {__index = function(t,k)
        if methods[k] then return methods[k] end
        if k == "MouseButton1Click" or k == "MouseEnter" or k == "InputEnded" then t.signals[k] = t.signals[k] or signal(); return t.signals[k] end
    end})
    for k,v in pairs(props or {}) do o[k] = v end
    if o.Parent and o.Parent.children then table.insert(o.Parent.children, o); o.Parent[o.Name] = o end
    for _,c in pairs(children or {}) do if c then c.Parent=o; table.insert(o.children,c); o[c.Name]=c end end
    return o
end
local UDim = { new = function(...) return {...} end }
local UDim2 = { new = function(a,b,c,d) return {X={Scale=a,Offset=b},Y={Scale=c,Offset=d}} end, fromOffset = function(x,y) return {X={Scale=0,Offset=x},Y={Scale=0,Offset=y}} end }
local Vector2 = {new = function(x,y) return {X=x,Y=y} end}
local Font = {new = function(...) return {...} end}
local Enum = {FontWeight={Medium=1,Regular=2}, EasingStyle={Quart=1}, EasingDirection={Out=1}, UserInputType={MouseButton1=1,Touch=2}}
local Creator = { Font = "test", New = new }
Creator.NewRoundFrame = function(_,_, props,children) return new("ImageButton",props,children) end
Creator.Tween = function() return { Play = function() end } end
Creator.SafeCallback = function(fn,...) fn(...) end
Creator.AddSignal = function(sig, fn) return sig:Connect(fn) end
local globalCount = 0
Creator.AddGlobalInputBegan = function() globalCount += 1; local active=true; return {Disconnect=function() if active then active=false; globalCount -= 1 end end} end
local New, Tween = Creator.New, Creator.Tween
local Mouse, Camera = {X=0,Y=0}, {ViewportSize={X=1000,Y=1000}}
local CreateInput = function() return new("Input",{}) end
-- PRODUCTION
local window = {Destroyed=false,CanDropdown=true}
local cfg = { Window=window, WindUI={DropdownGui=new("ScreenGui",{})}, UIScale=1 }
local element = {MenuPadding=5,MenuCorner=15,TabPadding=10,TabIcon=18,SearchBarHeight=39}
local function make(multi)
    local callbacks, last = 0, nil
    local d = {Values={"one","two"}, Value=multi and {"one"} or "one", Multi=multi, AllowNone=true,
        Callback=function(v) callbacks += 1; last=v end, SuppressInitialCallback=true,
        UIElements={Dropdown=new("Button",{}, {new("Frame",{}, {new("Frame",{}, {new("TextLabel",{})})})})}, Tabs={}, MenuWidth=180}
    local m = DropdownMenu.New(cfg,d,element,"Dropdown")
    return d,m,function() return callbacks,last end
end
local d,m,count = make(false)
flush(); assert(count()==0, "silent construction")
local rows = { d.Tabs[1].UIElements.TabItem, d.Tabs[2].UIElements.TabItem }
local beforeCreated,beforeDestroyed=created,destroyed
for i=1,100 do m:Select(i%2==0 and "one" or "two",true) end
flush(); assert(count()==0 and created==beforeCreated and destroyed==beforeDestroyed and d.Tabs[1].UIElements.TabItem==rows[1], "silent select reconstructs or calls back")
for i=1,100 do m:Refresh({"one","two"},true) end
flush(); assert(count()==0,"silent refresh callback")
m:Refresh({"new"},false); flush(); local n,v=count(); assert(n==1 and v=="one" and d.Values[1]=="new")
m:Select("new",false); m:Select("new",true); flush(); assert(count()==1,"stale callback must be invalidated")
local canvas=d.UIElements.MenuCanvas
local previous=canvas.Position
d.UIElements.Dropdown:GetPropertyChangedSignal("AbsolutePosition"):Fire()
assert(canvas.Position==previous, "closed dropdown should not reposition")
m:Open(); local opened=canvas.Position; assert(opened~=previous)
d.UIElements.Dropdown:GetPropertyChangedSignal("AbsolutePosition"):Fire()
assert(canvas.Position~=opened, "opening dropdown must track movement")
m:Close(); flush(); previous=canvas.Position
d.UIElements.Dropdown:GetPropertyChangedSignal("AbsolutePosition"):Fire()
assert(canvas.Position==previous, "closed dropdown should remain still")
m:Select("new",false); m:Destroy(); m:Destroy(); flush(); assert(count()==1 and globalCount==0,"destroy invalidates callback and disconnects")
local multi,mm,mc=make(true); mm:Select({"two"},true); flush(); assert(mc()==0 and multi.Tabs[2].Selected and not multi.Tabs[1].Selected); mm:Destroy()
print("Dropdown: silent construction, 100 selects and refreshes, stale callbacks, selection and idempotent cleanup passed")
