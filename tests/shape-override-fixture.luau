-- Runs the production shape override block with attribute-carrying instance doubles.
local DynamicShapeModule = {}
-- PRODUCTION
local function shape(original)
	local attrs = { WindUIShape = original }
	return { Image = original, GetAttribute = function(_, k) return attrs[k] end }
end
local plain = { Image = "rbxassetid://art", GetAttribute = function() return nil end }
local squircle, glass, circle = shape("rbxassetid://sq"), shape("rbxassetid://glass"), shape("rbxassetid://circle")
local root = { GetDescendants = function() return { squircle, glass, plain, circle } end }

assert(DynamicShapeModule.Resolve("rbxassetid://sq") == "rbxassetid://sq", "no override keeps the original")
DynamicShapeModule.SetOverrides({ ["rbxassetid://sq"] = "rbxasset://clean.png", ["rbxassetid://glass"] = "" }, { root })
assert(squircle.Image == "rbxasset://clean.png" and glass.Image == "", "existing shapes are swapped or hidden")
assert(circle.Image == "rbxassetid://circle" and plain.Image == "rbxassetid://art", "other shapes and plain images stay")
assert(DynamicShapeModule.Resolve("rbxassetid://glass") == "", "new shapes resolve through the same map")
DynamicShapeModule.SetOverrides(nil, { root })
assert(squircle.Image == "rbxassetid://sq" and glass.Image == "rbxassetid://glass", "an empty map restores originals")
assert(next(DynamicShapeModule.Overrides) == nil)
print("Shape overrides: swap, hide, untouched plain images, resolve for new shapes and exact restore passed")
