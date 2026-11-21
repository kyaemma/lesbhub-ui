local cloneref = (cloneref or clonereference or function(instance)
	return instance
end)

local UserInputService = cloneref(game:GetService("UserInputService"))

local Creator = require("../modules/Creator")
local New = Creator.New
local Tween = Creator.Tween

local Element = {
	UICorner = 6,
	UIPadding = 8,
}

local CreateLabel = require("../components/ui/Label").New

function Element:New(Config)
	local function NormalizeKeyCode(value)
		if typeof(value) == "EnumItem" then
			return value.Name
		elseif type(value) == "string" then
			return value
		else
			return "F"
		end
	end

	local MouseAliases = {
		MouseLeft = "MouseButton1",
		MouseLeftButton = "MouseButton1",
		MouseButton1 = "MouseButton1",
		MouseRight = "MouseButton2",
		MouseRightButton = "MouseButton2",
		MouseButton2 = "MouseButton2",
		MouseMiddle = "MouseButton3",
		MouseButton3 = "MouseButton3",
	}

	local function CanonicalInput(value)
		local name = NormalizeKeyCode(value)
		return MouseAliases[name] or name
	end

	local function InputName(input)
		if input.UserInputType == Enum.UserInputType.Keyboard then
			return input.KeyCode.Name
		end
		return MouseAliases[input.UserInputType.Name]
	end

	local Keybind = {
		__type = "Keybind",
		Title = Config.Title or "Keybind",
		Desc = Config.Desc or nil,
		Locked = Config.Locked or false,
		LockedTitle = Config.LockedTitle,
		Value = CanonicalInput(Config.Value) or "F",
		Callback = Config.Callback or function() end,
		CanChange = Config.CanChange ~= false,
		Blacklist = Config.Blacklist or {},
		Picking = false,
		UIElements = {},
	}

	local FilteredBlacklist = {}

	for _, Item in next, Keybind.Blacklist do
		FilteredBlacklist[CanonicalInput(Item)] = true
	end
	FilteredBlacklist[CanonicalInput("Escape")] = true

	local CanCallback = true

	Keybind.KeybindFrame = require("../components/window/Element")({
		Title = Keybind.Title,
		Desc = Keybind.Desc,
		Parent = Config.Parent,
		TextOffset = 85,
		Hover = Keybind.CanChange,
		Tab = Config.Tab,
		Index = Config.Index,
		Window = Config.Window,
		ElementTable = Keybind,
		ParentConfig = Config,
		Tags = Config.Tags,
	})

	Keybind.UIElements.Keybind = CreateLabel(
		Keybind.Value,
		nil,
		Keybind.KeybindFrame.UIElements.Main,
		nil,
		Config.Window.NewElements and 12 or 10
	)

	Keybind.UIElements.Keybind.Size =
		UDim2.new(0, 12 + 12 + Keybind.UIElements.Keybind.Frame.Frame.TextLabel.TextBounds.X, 0, 42)
	Keybind.UIElements.Keybind.AnchorPoint = Vector2.new(1, 0.5)
	Keybind.UIElements.Keybind.Position = UDim2.new(1, 0, 0.5, 0)
	Keybind.UIElements.Keybind.Interactable = false

	New("UIScale", {
		Parent = Keybind.UIElements.Keybind,
		Scale = 0.85,
	})

	Creator.AddSignal(
		Keybind.UIElements.Keybind.Frame.Frame.TextLabel:GetPropertyChangedSignal("TextBounds"),
		function()
			Keybind.UIElements.Keybind.Size =
				UDim2.new(0, 12 + 12 + Keybind.UIElements.Keybind.Frame.Frame.TextLabel.TextBounds.X, 0, 42)
		end
	)

	function Keybind:Lock()
		Keybind.Locked = true
		CanCallback = false
		return Keybind.KeybindFrame:Lock(Keybind.LockedTitle)
	end
	function Keybind:Unlock()
		Keybind.Locked = false
		CanCallback = true
		return Keybind.KeybindFrame:Unlock()
	end

	function Keybind:Set(v)
		local normalizedValue = CanonicalInput(v)
		Keybind.Value = normalizedValue
		Keybind.UIElements.Keybind.Frame.Frame.TextLabel.Text = normalizedValue
	end

	if Keybind.Locked then
		Keybind:Lock()
	end

	local EndedEvent

	Creator.AddSignal(Keybind.KeybindFrame.UIElements.Main.MouseButton1Click, function()
		if CanCallback then
			if Keybind.CanChange then
				Keybind.Picking = true
				Keybind.UIElements.Keybind.Frame.Frame.TextLabel.Text = "..."

				--task.wait(0.2)

				local Event
				Event = Creator.AddSignal(UserInputService.InputBegan, function(Input)
					local Key = InputName(Input)
					if not Key or FilteredBlacklist[Key] then
						return
					end

					if EndedEvent then
						EndedEvent:Disconnect()
						EndedEvent = nil
						Creator.CompactSignals()
					end

					EndedEvent = Creator.AddSignal(UserInputService.InputEnded, function(Ended)
						if Key and InputName(Ended) == Key then
							Keybind.Picking = false

							Keybind.UIElements.Keybind.Frame.Frame.TextLabel.Text = Key
							Keybind.Value = Key

							Event:Disconnect()
							EndedEvent:Disconnect()
							Event = nil
							EndedEvent = nil
							Creator.CompactSignals()
						end
					end)
				end)
			end
		end
	end)

	Creator.AddGlobalInputBegan(function(input, gpe, focusedTextBox)
		if focusedTextBox then
			return
		end
		if not CanCallback then
			return
		end
		if Keybind.Picking then
			return
		end

		local name = InputName(input)
		if name and name == CanonicalInput(Keybind.Value) then
			Creator.SafeCallback(Keybind.Callback, name)
		end
	end)

	return Keybind.__type, Keybind
end

return Element
