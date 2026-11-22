-- Runs the production tab parking blocks with deterministic Instance, signal and scheduler doubles.
local V2 = {}
V2.__eq = function(a, b) return a.X == b.X and a.Y == b.Y end
local Vector2 = { new = function(x, y) return setmetatable({ X = x, Y = y }, V2) end }
local U2 = {}
U2.__eq = function(a, b)
	return a.X.Scale == b.X.Scale and a.X.Offset == b.X.Offset and a.Y.Scale == b.Y.Scale and a.Y.Offset == b.Y.Offset
end
local UDim2 = {
	new = function(a, b, c, d) return setmetatable({ X = { Scale = a, Offset = b }, Y = { Scale = c, Offset = d } }, U2) end,
}
UDim2.fromOffset = function(x, y) return UDim2.new(0, x, 0, y) end
local UDim = { new = function(s, o) return { Scale = s, Offset = o } end }

local function signal()
	local s = { listeners = {} }
	function s:Connect(fn)
		local c = { Connected = true }
		function c:Disconnect() self.Connected = false end
		table.insert(self.listeners, { c, fn })
		return c
	end
	function s:Fire()
		for _, p in ipairs(table.clone(self.listeners)) do
			if p[1].Connected then p[2]() end
		end
	end
	return s
end

-- Instance double: counts writes per property and hands out change signals.
local function object(class, props)
	local store, writes, signals = {}, {}, {}
	local o = setmetatable({}, {
		__index = function(_, k)
			if k == "ClassName" then return class end
			if k == "Writes" then return writes end
			if k == "GetPropertyChangedSignal" then
				return function(_, name)
					signals[name] = signals[name] or signal()
					return signals[name]
				end
			end
			if k == "Changed" then
				return function(_, name) if signals[name] then signals[name]:Fire() end end
			end
			return store[k]
		end,
		__newindex = function(_, k, v)
			writes[k] = (writes[k] or 0) + 1
			store[k] = v
		end,
	})
	for k, v in pairs(props or {}) do store[k] = v end
	return o
end

local created = {}
local function New(class, props, children)
	local o = object(class, props)
	for _, child in ipairs(children or {}) do child.Parent = o end
	table.insert(created, o)
	return o
end
local Creator = { AddSignal = function(sig, fn) return sig:Connect(fn) end }

-- Cooperative scheduler: task.wait yields until advance() passes its deadline.
local clock, sleepers = 0, {}
local function resume(co)
	local ok, delay = coroutine.resume(co)
	assert(ok, delay)
	if coroutine.status(co) ~= "dead" then table.insert(sleepers, { co = co, at = clock + delay }) end
end
local task = {
	spawn = function(fn) resume(coroutine.create(fn)) end,
	wait = function(t) return coroutine.yield(t or 0) end,
}
local function advance(dt)
	clock += dt
	local due = {}
	for i = #sleepers, 1, -1 do
		if sleepers[i].at <= clock + 1e-9 then table.insert(due, table.remove(sleepers, i)) end
	end
	for _, s in ipairs(due) do resume(s.co) end
end

local folder = object("Folder")
local mainBar = object("Frame", { AbsoluteSize = Vector2.new(0, 0) })
local uiScale = object("UIScale", { Scale = 1 })
local Config = { Parent = folder, WindUI = { UIScaleObj = uiScale } }
local Window = {
	UIElements = { MainBar = mainBar },
	Size = UDim2.new(0, 860, 0, 560),
	SideBarWidth = 172,
	Topbar = { Height = 52 },
	UIPadding = 14,
	Destroyed = false,
	Closed = false,
}
local function resizeBar(x, y)
	mainBar.AbsoluteSize = Vector2.new(x, y)
	mainBar:Changed("AbsoluteSize")
end

-- PRODUCTION_PARKING

local parking = Window.UIElements.TabParking
assert(parking and parking.Name == "TabParking", "parking frame exists")
assert(parking.Visible == false and parking.Parent == folder, "parking is hidden beside Main")
assert(parking.Size == UDim2.fromOffset(688, 508), "parking starts at the configured content size")
local parkingScale, parkingPadding
for _, o in ipairs(created) do
	if o.Parent == parking and o.ClassName == "UIScale" then parkingScale = o end
	if o.Parent == parking and o.ClassName == "UIPadding" then parkingPadding = o end
end
assert(parkingScale and parkingScale.Scale == 1, "parking copies the window scale")
assert(parkingPadding.PaddingLeft.Offset == 7 and parkingPadding.PaddingRight.Offset == 7
	and parkingPadding.PaddingBottom.Offset == 7 and parkingPadding.PaddingTop == nil, "parking copies MainBar padding")

-- A settled size is mirrored once.
local sizeWrites = parking.Writes.Size or 0
resizeBar(796, 596)
advance(0.15)
assert(parking.Size == UDim2.fromOffset(796, 596), "settled size is mirrored")
assert(parking.Writes.Size == sizeWrites + 1, "one write per settle")

-- An open tween or a live resize only reaches parked pages once it settles.
sizeWrites = parking.Writes.Size
for step = 1, 16 do
	resizeBar(796 + step * 10, 596 + step * 5)
	advance(0.05)
end
assert(parking.Writes.Size == sizeWrites, "no parking writes while the size keeps changing")
advance(0.15)
advance(0.15)
assert(parking.Size == UDim2.fromOffset(956, 676), "final size is mirrored after the tween")
assert(parking.Writes.Size == sizeWrites + 1, "the whole tween costs one parking write")

-- A scale change keeps the parked content box identical to MainBar's.
uiScale.Scale = 1.25
uiScale:Changed("Scale")
resizeBar(1000, 750)
advance(0.15)
advance(0.15)
assert(parkingScale.Scale == 1.25, "parking follows the window scale")
assert(parking.Size == UDim2.fromOffset(800, 600), "parking size is unscaled")

-- A closed window and a zero-sized bar never shrink parked pages.
sizeWrites = parking.Writes.Size
Window.Closed = true
resizeBar(1000, 0)
advance(0.15)
advance(0.15)
Window.Closed = false
resizeBar(1000, 0)
advance(0.15)
advance(0.15)
assert(parking.Writes.Size == sizeWrites, "closed or empty sizes are ignored")

-- Destroying the window ends a pending settle without writing.
resizeBar(900, 700)
Window.Destroyed = true
advance(0.15)
advance(0.15)
assert(parking.Writes.Size == sizeWrites and #sleepers == 0, "destroy ends the settle loop")
Window.Destroyed = false

-- SelectTab keeps only the shown page inside MainBar.
local TabModule = { Containers = {} }
for i = 1, 4 do
	TabModule.Containers[i] = object("Frame", { Visible = false, Parent = parking })
end
local function select(TabIndex)
	-- PRODUCTION_SELECT
end
local function parentWrites()
	local n = 0
	for _, c in ipairs(TabModule.Containers) do n += c.Writes.Parent or 0 end
	return n
end

select(1)
assert(TabModule.Containers[1].Parent == mainBar and TabModule.Containers[1].Visible, "selected page is shown in MainBar")
for i = 2, 4 do
	assert(TabModule.Containers[i].Parent == parking and not TabModule.Containers[i].Visible, "other pages stay parked")
end
assert(parentWrites() == 1, "only the selected page moves")

select(3)
assert(TabModule.Containers[3].Parent == mainBar and TabModule.Containers[3].Visible, "new page moves in")
assert(TabModule.Containers[1].Parent == parking and not TabModule.Containers[1].Visible, "old page is parked")
assert(parentWrites() == 3, "a switch moves exactly two pages")

select(3)
assert(parentWrites() == 3, "selecting the shown tab moves nothing")
assert(TabModule.Containers[3].Visible, "reselected page stays visible")

-- Without a parking frame the stock behavior is kept.
Window.UIElements.TabParking = nil
for _, c in ipairs(TabModule.Containers) do c.Parent = mainBar end
select(2)
for i, c in ipairs(TabModule.Containers) do
	assert(c.Parent == mainBar and c.Visible == (i == 2), "fallback keeps every page in MainBar")
end
print("tab parking fixture passed")
