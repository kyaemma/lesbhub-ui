local jobs = {}
local task = {}
function task.delay(_, callback)
	jobs[callback] = true
	return callback
end
function task.cancel(callback)
	jobs[callback] = nil
end
local function flush()
	for callback in pairs(jobs) do
		jobs[callback] = nil
		callback()
	end
end
local Vector2 = {}
function Vector2.new(x, y)
	return { X = x, Y = y }
end
local WindUI = { UIScale = 0.5 }
local Window = { Destroyed = false }
local scroll = {
	Parent = true,
	CanvasPosition = { Y = 200 },
	AbsolutePosition = { Y = 100 },
	AbsoluteCanvasSize = { Y = 1000 },
	AbsoluteSize = { Y = 200 },
	UIPadding = { PaddingTop = { Offset = 10 } },
}
local Tab = {
	Selected = true,
	Elements = {},
	UIElements = { ContainerFrame = scroll },
}
function Tab:CancelPendingFocus()
	if Tab.FocusThread then
		task.cancel(Tab.FocusThread)
		Tab.FocusThread = nil
	end
end
local outer = {
	ParentTable = Tab,
	Open = function(self)
		self.Opened = true
	end,
}
local inner = {
	ParentTable = outer,
	Open = outer.Open,
}
local element = {
	ParentTable = inner,
	Highlight = function(self)
		self.Highlighted = true
	end,
	ElementFrame = {
		Parent = true,
		AbsolutePosition = { Y = 150 },
		IsDescendantOf = function()
			return true
		end,
	},
}
Tab.Elements[1] = element
-- PRODUCTION
assert(not Tab:ScrollToTheElement(50))
assert(not Tab:ScrollToTheElement({}))
assert(Tab:ScrollToTheElement(element))
assert(inner.Opened and outer.Opened)
flush()
assert(scroll.CanvasPosition.Y == 290 and element.Highlighted, "Scale and existing canvas offset")
element.Highlighted = nil
assert(Tab:ScrollToTheElement(1))
assert(Tab:ScrollToTheElement(element))
local count = 0
for _ in pairs(jobs) do
	count += 1
end
assert(count == 1, "Only one outstanding navigation per tab")
table.clear(Tab.Elements)
flush()
assert(not element.Highlighted, "Destroyed or replaced entries cannot be focused")
Tab.Elements[1] = element
assert(Tab:ScrollToTheElement(element))
Tab.Selected = false
flush()
assert(not element.Highlighted)
Tab.Selected = true
assert(Tab:ScrollToTheElement(element))
Window.Destroyed = true
Tab:CancelPendingFocus()
assert(next(jobs) == nil and not Tab:ScrollToTheElement(element))
print("Focus: nested sections, scaling, stale indices, tab switches and cancellation passed")
