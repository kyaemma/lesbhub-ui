"""Exercise production font and grouping logic with portable Luau doubles."""
from pathlib import Path
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
source = (root / "src/modules/Creator.lua").read_text(encoding="utf-8")
font = source[source.index("function Creator.AddFontObject"):source.index("function Creator.GetThemeProperty")]
shape = source[source.index("function Creator:GetElementPosition"):source.index("\nreturn Creator")]
fixture = r'''
local Creator = { FontObjects = {}, Font = "one" }
local applications = 0
local Font = { new = function(id, weight, style)
    applications += 1
    return { Id = id, Weight = weight, Style = style }
end }
-- FONT
local items = {}
for i = 1, 1000 do
    local item = { FontFace = { Weight = i, Style = "italic" } }
    items[i] = item
    Creator.AddFontObject(item)
end
assert(applications == 1000)
Creator.UpdateFont("two")
assert(applications == 2000)
for i, item in ipairs(items) do
    assert(item.FontFace.Id == "two" and item.FontFace.Weight == i and item.FontFace.Style == "italic")
end
-- SHAPE
local a, d = { __type = "Button" }, { __type = "Divider" }
local list = {a, a, a, d, a, d, d, a, a}
local expected = {"Squircle-TL-TR", "Square", "Squircle-BL-BR", false, "Squircle", false, false, "Squircle-TL-TR", "Squircle-BL-BR"}
for i, value in ipairs(expected) do
    local result = Creator:GetElementPosition(list, i, false)
    assert(result == (value or nil))
end
assert(Creator:GetElementPosition(list, 1, true) == "SquircleH-TL-TR")
assert(Creator:GetElementPosition(list, 3, true) == "SquircleH-BL-BR")
local _, errorCode = Creator:GetElementPosition(list, 1.5, false); assert(errorCode == 1)
_, errorCode = Creator:GetElementPosition({}, 1, false); assert(errorCode == 2)
_, errorCode = Creator:GetElementPosition(list, 4, false); assert(errorCode == 3)
print("Font registrations: 1000 local writes; explicit global change: 1000 writes. Grouping cases passed.")
'''
with tempfile.TemporaryDirectory() as d:
    script = Path(d) / "fixture.luau"
    script.write_text(fixture.replace("-- FONT", font).replace("-- SHAPE", shape), encoding="utf-8")
    subprocess.run(["luau", str(script)], check=True)

fixture = (root / "tests/dropdown-fixture.luau").read_text(encoding="utf-8")
dropdown = (root / "src/components/ui/Dropdown.lua").read_text(encoding="utf-8")
dropdown = dropdown[dropdown.index("local TabBackgroundTransparency"):dropdown.rindex("return DropdownMenu")]
dropdown = "local DropdownMenu = {}\n" + dropdown
with tempfile.TemporaryDirectory() as d:
    script = Path(d) / "dropdown.luau"
    script.write_text(fixture.replace("-- PRODUCTION", dropdown), encoding="utf-8")
    subprocess.run(["luau", str(script)], check=True)

init = (root / "src/elements/Init.lua").read_text(encoding="utf-8")
body = init[init.index("Load = function("):]
body = "local load = function(" + body[len("Load = function("):body.rindex("\n}")]
body = body.rstrip().removesuffix(",")
fixture = r'''
local queued = {}
local task = { defer = function(fn) table.insert(queued, fn) end }
local function flush() while #queued > 0 do table.remove(queued,1)() end end
-- PRODUCTION
local calls = 0
local module = { New = function(_, config)
    local frame = { UIElements = {Main = "instance"}, Destroy = function() end }
    frame.UpdateShape = function(parent) calls += 1; assert(frame.Index > 0 and parent.Elements[frame.Index]) end
    return "Button", { ButtonFrame = frame }
end }
local tbl = { Elements = {}, __type = "Tab" }
local window = { AllElements = {}, NewElements = true, Destroyed = false }
load(tbl, {}, {Button=module}, window, {}, nil, {}, 1, tbl)
local items = {}
for i=1,300 do items[i]=tbl:Button({}) end
assert(calls==0 and #queued==1)
flush(); assert(calls==300, "one shape pass for 300 synchronous insertions")
items[100]:Destroy(); items[100]:Destroy(); tbl:Button({})
assert(#queued==1); flush(); assert(calls==600 and #tbl.Elements==300)
tbl:Button({}); window.Destroyed=true; flush(); assert(calls==600)
print("Shape load: 300 synchronous elements: 1 pass / 300 determinations (formerly 300 passes / 45150); destruction and replacement passed")
'''
with tempfile.TemporaryDirectory() as d:
    script = Path(d) / "load.luau"
    script.write_text(fixture.replace("-- PRODUCTION", body), encoding="utf-8")
    subprocess.run(["luau", str(script)], check=True)

packs = ("lucide", "solar", "craft", "geist", "sfsymbols", "gravity")
icons = (root / "src/modules/LocalIcons.lua").read_text(encoding="utf-8")
prelude = '''
local Vector2 = { new = function(x,y) return {X=x,Y=y} end }
local UDim2 = {new = function(...) return {...} end}
local Color3 = {new = function(...) return {...} end}
local loaded = {}
'''
for name in packs:
    catalog = (root / f"src/Icons/{name}/dist/Icons.lua").read_text(encoding="utf-8")
    prelude += f"loaded.{name} = (function()\n{catalog}\nend)()\n"
    icons = icons.replace(f'require("../Icons/{name}/dist/Icons")', f"loaded.{name}")
icons = icons.replace("return IconModule", "return IconModule", 1)
fixture = prelude + "\nlocal icons = (function()\n" + icons + "\nend)()\n" + r'''
for _, name in ipairs({"lucide","solar","craft","geist","sfsymbols","gravity"}) do
    local pack = loaded[name]
    local source = pack.Icons or pack
    local key, metadata = next(source)
    assert(key and icons.Icon(name .. ":" .. key), name .. " catalog resolution")
    icons.AddIcons(name, { test_custom = 123456 })
    local custom = icons.Icon(name .. ":test_custom")
    assert(custom and custom[1] == "rbxassetid://123456")
    assert(icons.Icon(name .. ":missing-nonexistent-icon") == nil)
    assert(icons.Icon(name .. ":" .. key), "original icon preserved")
end
assert(icons.Icon("activity") and icons.Icon("search"))
print("Icons: six pinned local catalogs, missing identifiers and AddIcons overlays passed")
'''
with tempfile.TemporaryDirectory() as d:
    script = Path(d) / "icons.luau"
    script.write_text(fixture, encoding="utf-8")
    subprocess.run(["luau", str(script)], check=True)
assert "raw.githubusercontent.com/Footagesus/Icons" not in (root / "src/modules/LocalIcons.lua").read_text(encoding="utf-8")

search = (root / "src/components/search/Init.lua").read_text(encoding="utf-8")
search = search[search.index("local SearchBar = {"):search.rindex("return SearchBar")]
search = search.replace('local Creator = require("../../modules/Creator")', "")
search = search.replace('Icons = require("./Icons"),', "Icons = {},")
search = search.replace("local function Search(query)", "local function Search(query)\n        searchCalls += 1")
base = (root / "tests/dropdown-fixture.luau").read_text(encoding="utf-8").split("-- PRODUCTION")[0]
base = base.replace("local tasks = {}", "local tasks = {}\nlocal textboxes = {}")
base = base.replace("local function new(class, props, children)", "function methods:FindFirstChild(name) return self[name] end\nlocal function new(class, props, children)")
base = base.replace("for k,v in pairs(props or {}) do o[k] = v end", "for k,v in pairs(props or {}) do o[k] = v end\n    o.TextBounds = {X=50,Y=20}\n    if class == 'TextBox' then table.insert(textboxes,o) end")
base = base.replace('k == "InputEnded"', 'k == "InputEnded" or k == "Destroying"')
base = base.replace("self.dead = true; destroyed += 1", "if self.signals.Destroying then self.signals.Destroying:Fire() end\n    self.dead = true; destroyed += 1")
base = base.replace("local Creator = { Font", "task.delay = function(_,fn) table.insert(tasks,fn) end\nlocal Creator = { Font")
base = base.replace("Creator.SafeCallback =", "Creator.Icon = function() return nil end\nCreator.SafeCallback =")
base = base.replace("EasingStyle={Quart=1}", "EasingStyle={Quart=1,Quint=2}").replace("EasingDirection={Out=1}", "EasingDirection={Out=1,InOut=2}")
# The module supplies its own aliases.
base = base.replace("local New, Tween = Creator.New, Creator.Tween\n", "")
fixture = base + "\nlocal searchCalls = 0\n" + search + r'''
local closes, selects = 0, 0
local tab = { Title="Alpha", Icon="search", Elements = {{Title="Red apple",Desc="fruit",__type="Button"}} }
local tabs = { Tabs={tab}, SelectTab=function() selects+=1 end }
local parent = new("Parent",{})
for cycle=1,40 do
    local m=SearchBar.new(tabs,parent,function() closes+=1 end)
    local box=textboxes[#textboxes]
    box.Text="red"; box:GetPropertyChangedSignal("Text"):Fire()
    box.Text="apple"; box:GetPropertyChangedSignal("Text"):Fire()
    if cycle%2==0 then
        m:Close(); flush()
        assert(#parent.children==0, "closed search left an instance")
    else
        flush()
        assert(#parent.children==1)
        m:Close(); m:Close(); assert(#parent.children==0)
    end
end
assert(closes==40 and selects==0 and searchCalls==20, "only latest query of open searches executes")
print("Search: 40 cycles, rapid queries, close-before-debounce and idempotent cleanup passed")
'''
with tempfile.TemporaryDirectory() as d:
    script = Path(d) / "search.luau"
    script.write_text(fixture, encoding="utf-8")
    subprocess.run(["luau", str(script)], check=True)

source = (root / "src/components/window/Element.lua").read_text(encoding="utf-8")
hover = source[source.index("\tif Element.Hover then"):source.index("\n\tfunction Element:SetTitle")]
base = (root / "tests/dropdown-fixture.luau").read_text(encoding="utf-8").split("-- PRODUCTION")[0]
base = base.replace('k == "InputEnded"', 'k == "InputEnded" or k == "MouseMoved"')
fixture = base + r'''
local Element, CanHover = {Hover=true}, true
local Main = new("Frame",{})
local Hover, HoverOutline = {HoverGradient={}}, {HoverGradient={}}
-- PRODUCTION
for i=1,100 do Main.MouseEnter:Fire(); Main.InputEnded:Fire() end
assert(#Main.MouseMoved.listeners==1)
Main.MouseMoved:Fire(100, 0)
assert(Hover.HoverGradient.Offset.X == HoverOutline.HoverGradient.Offset.X)
Main:Destroy()
assert(not Main.MouseMoved.listeners[1][1].Connected)
print("Hover: 100 enter/exit cycles retained one movement listener, disconnected on destruction")
'''
with tempfile.TemporaryDirectory() as d:
    script = Path(d) / "hover.luau"
    script.write_text(fixture.replace("-- PRODUCTION", hover), encoding="utf-8")
    subprocess.run(["luau", str(script)], check=True)
