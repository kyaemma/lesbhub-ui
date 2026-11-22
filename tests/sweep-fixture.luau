-- Runs the production registry sweep with plain-table instances.
local Creator = { Objects = {}, FontObjects = {}, LocalizationObjects = {} }
-- PRODUCTION
local function obj(parent) return { Parent = parent } end
local root = obj("Gui")
local live, building, destroyed, font, lang = obj(root), obj(nil), obj(nil), obj(nil), obj(root)
Creator.Objects[live] = { Properties = {} }
Creator.Objects[building] = { Properties = {} }
Creator.Objects[destroyed] = { Properties = {} }
Creator.FontObjects[font] = true
Creator.LocalizationObjects[lang] = "Key"

Creator.Sweep(100)
assert(Creator.Objects[destroyed] and Creator.Objects[building], "first sight only marks parentless entries")
building.Parent = root
Creator.Sweep(105)
assert(Creator.Objects[destroyed], "sweeps are rate limited")
Creator.Sweep(110)
assert(Creator.Objects[live] and Creator.Objects[building], "live and freshly parented entries stay")
assert(Creator.Objects[destroyed] == nil and Creator.FontObjects[font] == nil, "entries parentless twice are dropped")
assert(Creator.LocalizationObjects[lang] == "Key", "parented localization entries stay")
local late = obj(nil)
Creator.Objects[late] = { Properties = {} }
Creator.Sweep(120)
assert(Creator.Objects[late], "a new parentless entry gets a full interval of grace")
-- Live entries survive any number of sweeps.
for t = 130, 400, 10 do Creator.Sweep(t) end
assert(Creator.Objects[live] and Creator.Objects[building] and Creator.LocalizationObjects[lang], "live entries survive")
print("Sweep: rate limit, grace interval, live entries kept, destroyed entries dropped in all registries passed")
