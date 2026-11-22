-- /* src/components/Window/Init.lua */

local cloneref = (cloneref or clonereference or function(instance)
	return instance
end)

local UserInputService = cloneref(game:GetService("UserInputService"))
local RunService = cloneref(game:GetService("RunService"))
local Players = cloneref(game:GetService("Players"))

local CurrentCamera = workspace.CurrentCamera

local Acrylic = require("../../utils/Acrylic/Init")

local Creator = require("../../modules/Creator")
local New = Creator.New
local Tween = Creator.Tween

--local UIComponents = require("../Components/UI.lua")
local CreateLabel = require("../ui/Label").New
local CreateButton = require("../ui/Button").New
local CreateScrollSlider = require("../ui/ScrollSlider").New
local Tag = require("../ui/Tag")

local ConfigManager = require("../../config/Init")

local Notified = false

return function(Config)
	local finishResize = function() end
	local finishFullscreen = function() end
	local openTween
	local Window = {
		Title = Config.Title or "UI Library",
		Author = Config.Author,
		Icon = Config.Icon,
		IconSize = Config.IconSize or 22,
		IconThemed = Config.IconThemed,
		IconRadius = Config.IconRadius or 0,
		Folder = Config.Folder,
		Resizable = Config.Resizable ~= false,
		Background = Config.Background,
		BackgroundImageTransparency = Config.BackgroundImageTransparency or 0,
		ShadowTransparency = Config.ShadowTransparency or 0.6,
		User = Config.User or {},
		Footer = Config.Footer or {},
		Topbar = Config.Topbar or { Height = 52, ButtonsType = "Default" }, -- Default or Mac

		Size = Config.Size,

		MinSize = Config.MinSize or Vector2.new(560, 350),
		MaxSize = Config.MaxSize or Vector2.new(850, 560),

		TopBarButtonIconSize = Config.TopBarButtonIconSize,

		ToggleKey = Config.ToggleKey,
		ElementsRadius = Config.ElementsRadius,
		Radius = Config.Radius or 16,
		Transparent = Config.Transparent or false,
		HideSearchBar = Config.HideSearchBar ~= false,
		ScrollBarEnabled = Config.ScrollBarEnabled or false,
		SideBarWidth = Config.SideBarWidth or 200,
		Acrylic = Config.Acrylic or false,
		NewElements = Config.NewElements or false,
		IgnoreAlerts = Config.IgnoreAlerts or false,
		HidePanelBackground = Config.HidePanelBackground or false,
		AutoScale = Config.AutoScale ~= false,
		OpenButton = Config.OpenButton,
		-- Absent CloseBehavior keeps the upstream confirmation dialog.
		-- "Hide" and "Destroy" close immediately. The hub uses "Hide".
		CloseBehavior = Config.CloseBehavior,
		HideMinimizeButton = Config.HideMinimizeButton == true,
		DragFrameSize = 160,

		Position = UDim2.new(0.5, 0, 0.5, 0),
		UICorner = 16, -- Window.Radius (16)
		UIPadding = 14,
		UIElements = {},
		CanDropdown = true,
		Closed = false,
		VisibilityGeneration = 0,
		Parent = Config.Parent,
		Destroyed = false,
		IsFullscreen = false,
		CanResize = Config.Resizable ~= false,
		IsOpenButtonEnabled = true,

		CurrentConfig = nil,
		ConfigManager = nil,
		AcrylicPaint = nil,
		CurrentTab = nil,
		TabModule = nil,

		OnOpenCallback = nil,
		OnCloseCallback = nil,
		OnDestroyCallback = nil,

		IsPC = false,

		Gap = 5,

		TopBarButtons = {},
		AllElements = {},

		ElementConfig = {},

		PendingFlags = {},

		IsToggleDragging = false,
	}

	Window.UICorner = Window.Radius

	Window.TopBarButtonIconSize = Window.TopBarButtonIconSize or (Window.Topbar.ButtonsType == "Mac" and 11 or 16)

	Window.ElementConfig = {
		UIPadding = (Window.NewElements and 10 or 13),
		UICorner = Window.ElementsRadius or (Window.NewElements and 23 or 16),
	}

	local WindowSize = Window.Size or UDim2.new(0, 580, 0, 460)
	Window.Size = UDim2.new(
		WindowSize.X.Scale,
		math.clamp(WindowSize.X.Offset, Window.MinSize.X, Window.MaxSize.X),
		WindowSize.Y.Scale,
		math.clamp(WindowSize.Y.Offset, Window.MinSize.Y, Window.MaxSize.Y)
	)

	if Window.Topbar == {} then
		Window.Topbar = { Height = 52, ButtonsType = "Default" }
	end

	if not RunService:IsStudio() and Window.Folder and writefile then
		if not isfolder("WindUI/" .. Window.Folder) then
			makefolder("WindUI/" .. Window.Folder)
		end
		if not isfolder("WindUI/" .. Window.Folder .. "/assets") then
			makefolder("WindUI/" .. Window.Folder .. "/assets")
		end
		if not isfolder(Window.Folder) then
			makefolder(Window.Folder)
		end
		if not isfolder(Window.Folder .. "/assets") then
			makefolder(Window.Folder .. "/assets")
		end
	end

	local UICorner = New("UICorner", {
		CornerRadius = UDim.new(0, Window.UICorner),
	})

	if Window.Folder then
		Window.ConfigManager = ConfigManager:Init(Window)
	end

	if Window.Acrylic then
		local AcrylicPaint, BlurModule = Acrylic.AcrylicPaint({ UseAcrylic = Window.Acrylic })

		Window.AcrylicPaint = AcrylicPaint
	end

	local ResizeHandle = New("Frame", {
		Size = UDim2.new(0, 32, 0, 32),
		Position = UDim2.new(1, 0, 1, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		ZIndex = 99,
		Active = true,
	}, {
		New("ImageLabel", {
			Size = UDim2.new(0, 48 * 2, 0, 48 * 2),
			BackgroundTransparency = 1,
			Image = "rbxassetid://120997033468887",
			Position = UDim2.new(0.5, -16, 0.5, -16),
			AnchorPoint = Vector2.new(0.5, 0.5),
			ImageTransparency = 1, -- .8; .35
		}),
	})
	local FullScreenIconData = Creator.Icon("expand")
	local FullScreenIcon = Creator.NewRoundFrame(Window.UICorner, "Squircle", {
		Size = UDim2.new(1, 0, 1, 0),
		ImageTransparency = 1, -- .65
		ImageColor3 = Color3.new(0, 0, 0),
		ZIndex = 98,
		Active = false, -- true
	}, {
		New("ImageLabel", {
			Size = UDim2.new(0, 70, 0, 70),
			Image = FullScreenIconData and FullScreenIconData[1],
			ImageRectOffset = FullScreenIconData and FullScreenIconData[2] and FullScreenIconData[2].ImageRectPosition,
			ImageRectSize = FullScreenIconData and FullScreenIconData[2] and FullScreenIconData[2].ImageRectSize,
			BackgroundTransparency = 1,
			Position = UDim2.new(0.5, 0, 0.5, 0),
			AnchorPoint = Vector2.new(0.5, 0.5),
			ImageTransparency = 1,
		}),
	})

	local FullScreenBlur = Creator.NewRoundFrame(Window.UICorner, "Squircle", {
		Size = UDim2.new(1, 0, 1, 0),
		ImageTransparency = 1, -- .65
		ImageColor3 = Color3.new(0, 0, 0),
		ZIndex = 999,
		Active = false, -- true
	})

	-- local TabHighlight = Creator.NewRoundFrame(Window.UICorner-(Window.UIPadding/2), "Squircle", {
	--     Size = UDim2.new(1,0,0,0),
	--     ImageTransparency = .95,
	--     ThemeTag = {
	--         ImageColor3 = "Text",
	--     }
	-- })

	Window.UIElements.SideBar = New("ScrollingFrame", {
		Size = UDim2.new(
			1,
			Window.ScrollBarEnabled and -3 - (Window.UIPadding / 2) or 0,
			1,
			not Window.HideSearchBar and -39 - 6 or 0
		),
		Position = UDim2.new(0, 0, 1, 0),
		AnchorPoint = Vector2.new(0, 1),
		BackgroundTransparency = 1,
		ScrollBarThickness = 0,
		ElasticBehavior = "Never",
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = "Y",
		ScrollingDirection = "Y",
		ClipsDescendants = true,
		VerticalScrollBarPosition = "Left",
	}, {
		New("Frame", {
			BackgroundTransparency = 1,
			AutomaticSize = "Y",
			Size = UDim2.new(1, 0, 0, 0),
			Name = "Frame",
		}, {
			New("UIPadding", {
				--PaddingTop = UDim.new(0,Window.UIPadding/2),
				--PaddingLeft = UDim.new(0,4+(Window.UIPadding/2)),
				--PaddingRight = UDim.new(0,4+(Window.UIPadding/2)),
				PaddingBottom = UDim.new(0, Window.UIPadding / 2),
			}),
			New("UIListLayout", {
				SortOrder = "LayoutOrder",
				Padding = UDim.new(0, Window.Gap),
			}),
		}),
		New("UIPadding", {
			--PaddingTop = UDim.new(0,4),
			PaddingLeft = UDim.new(0, Window.UIPadding / 2),
			PaddingRight = UDim.new(0, Window.UIPadding / 2),
			PaddingBottom = UDim.new(0, Window.UIPadding / 2),
		}),
		--TabHighlight
	})

	Window.UIElements.SideBarContainer = New("Frame", {
		Size = UDim2.new(
			0,
			Window.SideBarWidth,
			1,
			Window.User.Enabled and -Window.Topbar.Height - 42 - (Window.UIPadding * 2) or -Window.Topbar.Height
		),
		Position = UDim2.new(0, 0, 0, Window.Topbar.Height),
		BackgroundTransparency = 1,
		Visible = true,
	}, {
		New("Frame", {
			Name = "Content",
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 1, not Window.HideSearchBar and -39 - 6 - Window.UIPadding or -Window.UIPadding / 2),
			Position = UDim2.new(0, 0, 1, -Window.UIPadding / 2),
			AnchorPoint = Vector2.new(0, 1),
		}),
		Window.UIElements.SideBar,
	})

	if Window.ScrollBarEnabled then
		CreateScrollSlider(
			Window.UIElements.SideBar,
			Window.UIElements.SideBarContainer.Content,
			Window,
			3,
			Config.WindUI
		)
	end

	Window.UIElements.MainBar = New("Frame", {
		Size = UDim2.new(1, -Window.UIElements.SideBarContainer.AbsoluteSize.X, 1, -Window.Topbar.Height),
		Position = UDim2.new(1, 0, 1, 0),
		AnchorPoint = Vector2.new(1, 1),
		BackgroundTransparency = 1,
	}, {
		Creator.NewRoundFrame(Window.UICorner - (Window.UIPadding / 2), "Squircle", {
			Size = UDim2.new(1, 0, 1, 0),
			ThemeTag = {
				ImageColor3 = "PanelBackground",
				ImageTransparency = "PanelBackgroundTransparency",
			},
			-- ImageColor3 = Color3.new(1,1,1),
			-- ImageTransparency = .95,
			ZIndex = 3,
			Name = "Background",
			Visible = not Window.HidePanelBackground,
		}),
		New("UIPadding", {
			--PaddingTop = UDim.new(0,Window.UIPadding/2),
			PaddingLeft = UDim.new(0, Window.UIPadding / 2),
			PaddingRight = UDim.new(0, Window.UIPadding / 2),
			PaddingBottom = UDim.new(0, Window.UIPadding / 2),
		}),
	})

	-- lesbhub:tab-parking-start
	-- Hidden tab pages wait in TabParking, outside Main. Roblox recomputes every descendant of a frame
	-- that moves, hidden ones included, so a drag or resize now only touches the page on screen.
	-- TabParking copies MainBar's padding and scale and follows its size once a resize or tween settles,
	-- so a page keeps its layout when it moves in or out.
	local ParkingScale = New("UIScale", { Scale = Config.WindUI.UIScaleObj.Scale })
	Window.UIElements.TabParking = New("Frame", {
		Name = "TabParking",
		BackgroundTransparency = 1,
		Visible = false,
		Size = UDim2.new(
			0,
			math.max(0, Window.Size.X.Offset - Window.SideBarWidth),
			0,
			math.max(0, Window.Size.Y.Offset - Window.Topbar.Height)
		),
		Parent = Config.Parent,
	}, {
		ParkingScale,
		New("UIPadding", {
			PaddingLeft = UDim.new(0, Window.UIPadding / 2),
			PaddingRight = UDim.new(0, Window.UIPadding / 2),
			PaddingBottom = UDim.new(0, Window.UIPadding / 2),
		}),
	})
	local parkingSettling = false
	local function syncParking()
		if parkingSettling or Window.Destroyed then
			return
		end
		parkingSettling = true
		task.spawn(function()
			local scale, size
			repeat
				scale, size = Config.WindUI.UIScaleObj.Scale, Window.UIElements.MainBar.AbsoluteSize
				task.wait(0.15)
			until Window.Destroyed
				or (scale == Config.WindUI.UIScaleObj.Scale and size == Window.UIElements.MainBar.AbsoluteSize)
			parkingSettling = false
			if Window.Destroyed or Window.Closed or scale <= 0 or size.X < 1 or size.Y < 1 then
				return
			end
			ParkingScale.Scale = scale
			Window.UIElements.TabParking.Size = UDim2.fromOffset(size.X / scale, size.Y / scale)
		end)
	end
	Creator.AddSignal(Window.UIElements.MainBar:GetPropertyChangedSignal("AbsoluteSize"), syncParking)
	Creator.AddSignal(Config.WindUI.UIScaleObj:GetPropertyChangedSignal("Scale"), syncParking)
	-- lesbhub:tab-parking-end

	local Blur = New("ImageLabel", { -- Shadow
		Image = "rbxassetid://8992230677",
		ThemeTag = {
			ImageColor3 = "WindowShadow",
			--ImageTransparency = "WindowShadowTransparency",
		},
		ImageTransparency = 1, -- .7
		Size = UDim2.new(1, 100, 1, 100),
		Position = UDim2.new(0, -100 / 2, 0, -100 / 2),
		ScaleType = "Slice",
		SliceCenter = Rect.new(99, 99, 99, 99),
		BackgroundTransparency = 1,
		ZIndex = -999999999999999,
		Name = "Blur",
	})

	if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
		Window.IsPC = false
	elseif UserInputService.KeyboardEnabled then
		Window.IsPC = true
	else
		Window.IsPC = nil
	end

	--Window.IsPC = true

	-- local OpenButtonContainer = nil
	-- local OpenButton = nil
	-- local OpenButtonIcon = nil

	local UserIcon
	if Window.User then
		local function GetUserThumb()
			local ImageId, _ = Players:GetUserThumbnailAsync(
				Window.User.Anonymous and 1 or Players.LocalPlayer.UserId,
				Enum.ThumbnailType.HeadShot,
				Enum.ThumbnailSize.Size420x420
			)
			return ImageId
		end

		UserIcon = New("TextButton", {
			Size = UDim2.new(
				0,
				Window.UIElements.SideBarContainer.AbsoluteSize.X - (Window.UIPadding / 2),
				0,
				42 + Window.UIPadding
			),
			Position = UDim2.new(0, Window.UIPadding / 2, 1, -(Window.UIPadding / 2)),
			AnchorPoint = Vector2.new(0, 1),
			BackgroundTransparency = 1,
			Visible = Window.User.Enabled or false,
		}, {
			Creator.NewRoundFrame(Window.UICorner - (Window.UIPadding / 2), "SquircleOutline", {
				Size = UDim2.new(1, 0, 1, 0),
				ThemeTag = {
					ImageColor3 = "Text",
				},
				ImageTransparency = 1, -- .85
				Name = "Outline",
			}, {
				New("UIGradient", {
					Rotation = 78,
					Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0.0, Color3.fromRGB(255, 255, 255)),
						ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
						ColorSequenceKeypoint.new(1.0, Color3.fromRGB(255, 255, 255)),
					}),
					Transparency = NumberSequence.new({
						NumberSequenceKeypoint.new(0.0, 0.1),
						NumberSequenceKeypoint.new(0.5, 1),
						NumberSequenceKeypoint.new(1.0, 0.1),
					}),
				}),
			}),
			Creator.NewRoundFrame(Window.UICorner - (Window.UIPadding / 2), "Squircle", {
				Size = UDim2.new(1, 0, 1, 0),
				ThemeTag = {
					ImageColor3 = "Text",
				},
				ImageTransparency = 1, -- .95
				Name = "UserIcon",
			}, {
				New("ImageLabel", {
					Image = GetUserThumb(),
					BackgroundTransparency = 1,
					Size = UDim2.new(0, 42, 0, 42),
					ThemeTag = {
						BackgroundColor3 = "Text",
					},
					BackgroundTransparency = 0.93,
				}, {
					New("UICorner", {
						CornerRadius = UDim.new(1, 0),
					}),
				}),
				New("Frame", {
					AutomaticSize = "XY",
					BackgroundTransparency = 1,
				}, {
					New("TextLabel", {
						Text = Window.User.Anonymous and "Anonymous" or Players.LocalPlayer.DisplayName,
						TextSize = 17,
						ThemeTag = {
							TextColor3 = "Text",
						},
						FontFace = Font.new(Creator.Font, Enum.FontWeight.SemiBold),
						AutomaticSize = "Y",
						BackgroundTransparency = 1,
						Size = UDim2.new(1, -(42 / 2) - 6, 0, 0),
						TextTruncate = "AtEnd",
						TextXAlignment = "Left",
						Name = "DisplayName",
					}),
					New("TextLabel", {
						Text = Window.User.Anonymous and "anonymous" or Players.LocalPlayer.Name,
						TextSize = 15,
						TextTransparency = 0.6,
						ThemeTag = {
							TextColor3 = "Text",
						},
						FontFace = Font.new(Creator.Font, Enum.FontWeight.Medium),
						AutomaticSize = "Y",
						BackgroundTransparency = 1,
						Size = UDim2.new(1, -(42 / 2) - 6, 0, 0),
						TextTruncate = "AtEnd",
						TextXAlignment = "Left",
						Name = "UserName",
					}),
					New("UIListLayout", {
						Padding = UDim.new(0, 4),
						HorizontalAlignment = "Left",
					}),
				}),
				New("UIListLayout", {
					Padding = UDim.new(0, Window.UIPadding),
					FillDirection = "Horizontal",
					VerticalAlignment = "Center",
				}),
				New("UIPadding", {
					PaddingLeft = UDim.new(0, Window.UIPadding / 2),
					PaddingRight = UDim.new(0, Window.UIPadding / 2),
				}),
			}),
		})

		function Window.User:Enable()
			Window.User.Enabled = true
			Tween(
				Window.UIElements.SideBarContainer,
				0.25,
				{ Size = UDim2.new(0, Window.SideBarWidth, 1, -Window.Topbar.Height - 42 - (Window.UIPadding * 2)) },
				Enum.EasingStyle.Quint,
				Enum.EasingDirection.Out
			):Play()
			UserIcon.Visible = true
		end
		function Window.User:Disable()
			Window.User.Enabled = false
			Tween(
				Window.UIElements.SideBarContainer,
				0.25,
				{ Size = UDim2.new(0, Window.SideBarWidth, 1, -Window.Topbar.Height) },
				Enum.EasingStyle.Quint,
				Enum.EasingDirection.Out
			):Play()
			UserIcon.Visible = false
		end
		function Window.User:SetAnonymous(v)
			if v ~= false then
				v = true
			end
			Window.User.Anonymous = v
			UserIcon.UserIcon.ImageLabel.Image = GetUserThumb()
			UserIcon.UserIcon.Frame.DisplayName.Text = v and "Anonymous" or Players.LocalPlayer.DisplayName
			UserIcon.UserIcon.Frame.UserName.Text = v and "anonymous" or Players.LocalPlayer.Name
		end

		if Window.User.Enabled then
			Window.User:Enable()
		else
			Window.User:Disable()
		end

		if Window.User.Callback then
			Creator.AddSignal(UserIcon.MouseButton1Click, function()
				Window.User.Callback()
			end)
			Creator.AddSignal(UserIcon.MouseEnter, function()
				Tween(UserIcon.UserIcon, 0.04, { ImageTransparency = 0.95 }):Play()
				Tween(UserIcon.Outline, 0.04, { ImageTransparency = 0.85 }):Play()
			end)
			Creator.AddSignal(UserIcon.InputEnded, function()
				Tween(UserIcon.UserIcon, 0.04, { ImageTransparency = 1 }):Play()
				Tween(UserIcon.Outline, 0.04, { ImageTransparency = 1 }):Play()
			end)
		end
	end

	local Outline1
	local Outline2

	local IsVideoBG = false
	local BGImage = nil

	local BGVideo = typeof(Window.Background) == "string" and string.match(Window.Background, "^video:(.+)") or nil

	local BGHttpImage = typeof(Window.Background) == "string"
			and not BGVideo
			and string.match(Window.Background, "^https?://.+")
		or nil

	local BGRobloxImage = typeof(Window.Background) == "string"
			and not BGVideo
			and string.match(Window.Background, "^rbxassetid://%d+")
		or nil

	local function GetImageExtension(url)
		if not url or typeof(url) ~= "string" then
			return ".png"
		end
		local cleanUrl = url:match("^([^?#]+)") or url
		local ext = cleanUrl:match("%.(%w+)$")
		if ext then
			ext = ext:lower()
			if ext == "jpg" or ext == "jpeg" or ext == "png" or ext == "webp" then
				return "." .. ext
			end
		end
		return ".png"
	end

	--print(GetImageExtension(BGImageUrl))

	if typeof(Window.Background) == "string" and BGVideo then
		IsVideoBG = true

		if string.find(BGVideo, "http") then
			local videoPath = (Window.Folder or "Temp") .. "/assets/." .. Creator.SanitizeFilename(BGVideo) .. ".webm"
			if not isfile(videoPath) then
				local success, result = pcall(function()
					-- local response = Creator.Request({
					-- 	Url = BGVideo,
					-- 	Method = "GET",
					-- 	Headers = { ["User-Agent"] = "Roblox/Exploit" },
					-- })
					local response = game.HttpGet and game:HttpGet(BGVideo)
						or Creator.Request({
							Url = BGVideo,
							Method = "GET",
							Headers = { ["User-Agent"] = "Roblox/Exploit" },
						}).Body
					--print(response)
					writefile(videoPath, response)
				end)
				if not success then
					warn("[ WindUI.Window.Background ] Failed to download video: " .. tostring(result))
				end
			end

			local success, customAsset = pcall(function()
				return getcustomasset(videoPath)
			end)
			if not success then
				warn("[ WindUI.Window.Background ] Failed to load custom asset: " .. tostring(customAsset))
			end
			warn("[ WindUI.Window.Background ] VideoFrame may not work with custom video")
			BGVideo = customAsset
		end

		BGImage = New("VideoFrame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 1, 0),
			Video = BGVideo,
			Looped = true,
			Volume = 0,
		}, {
			New("UICorner", {
				CornerRadius = UDim.new(0, Window.UICorner),
			}),
		})
		BGImage:Play()
	elseif BGHttpImage then
		local imagePath = (Window.Folder or "Temp")
			.. "/assets/."
			.. Creator.SanitizeFilename(BGHttpImage)
			.. GetImageExtension(BGHttpImage)

		if isfile and not isfile(imagePath) then
			local success, result = pcall(function()
				local response = game.HttpGet and game:HttpGet(BGHttpImage)
					or Creator.Request({
						Url = BGHttpImage,
						Method = "GET",
						Headers = { ["User-Agent"] = "Roblox/Exploit" },
					}).Body

				writefile(imagePath, response)
			end)

			if not success then
				warn("[ Window.Background ] Failed to download image: " .. tostring(result))
			end
		end

		local success, customAsset = pcall(function()
			return getcustomasset(imagePath)
		end)

		if not success then
			warn("[ Window.Background ] Failed to load custom asset: " .. tostring(customAsset))
		end

		BGImage = New("ImageLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 1, 0),
			Image = customAsset,
			ImageTransparency = 0,
			ScaleType = "Crop",
		}, {
			New("UICorner", {
				CornerRadius = UDim.new(0, Window.UICorner),
			}),
		})
	elseif BGRobloxImage then
		BGImage = New("ImageLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 1, 0),
			Image = BGRobloxImage,
			ImageTransparency = 0,
			ScaleType = "Crop",
		}, {
			New("UICorner", {
				CornerRadius = UDim.new(0, Window.UICorner),
			}),
		})
	elseif Window.Background then
		BGImage = New("ImageLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 1, 0),
			Image = typeof(Window.Background) == "string" and Window.Background or "",
			ImageTransparency = 1,
			ScaleType = "Crop",
		}, {
			New("UICorner", {
				CornerRadius = UDim.new(0, Window.UICorner),
			}),
		})
	end

	local BottomDragFrame = Creator.NewRoundFrame(99, "Squircle", {
		ImageTransparency = 0.8,
		ImageColor3 = Color3.new(1, 1, 1),
		Size = UDim2.new(0, 0, 0, 4), -- 200
		Position = UDim2.new(0.5, 0, 1, 4),
		AnchorPoint = Vector2.new(0.5, 0),
	}, {
		New("TextButton", {
			Size = UDim2.new(1, 12, 1, 12),
			BackgroundTransparency = 1,
			Position = UDim2.new(0.5, 0, 0.5, 0),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Active = true,
			ZIndex = 99,
			Name = "Frame",
		}),
	})

	function createAuthor(text)
		return New("TextLabel", {
			Text = text,
			FontFace = Font.new(Creator.Font, Enum.FontWeight.Medium),
			BackgroundTransparency = 1,
			TextTransparency = 0.35,
			AutomaticSize = "XY",
			Parent = Window.UIElements.Main and Window.UIElements.Main.Main.Topbar.Left.Title,
			TextXAlignment = "Left",
			TextSize = 13,
			LayoutOrder = 2,
			ThemeTag = {
				TextColor3 = "WindowTopbarAuthor",
			},
			Name = "Author",
		})
	end

	local WindowAuthor
	local WindowIcon

	if Window.Author then
		WindowAuthor = createAuthor(Window.Author)
	end

	local WindowTitle = New("TextLabel", {
		Text = Window.Title,
		FontFace = Font.new(Creator.Font, Enum.FontWeight.SemiBold),
		BackgroundTransparency = 1,
		AutomaticSize = "XY",
		Name = "Title",
		TextXAlignment = "Left",
		TextSize = 16,
		ThemeTag = {
			TextColor3 = "WindowTopbarTitle",
		},
	})

	Window.UIElements.Main = New("Frame", {
		Size = UDim2.new(Window.Size.X.Scale, Window.Size.X.Offset, 0, 0),
		Position = Window.Position,
		BackgroundTransparency = 1,
		Parent = Config.Parent,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Active = true,
		--GroupTransparency = 1,
	}, {
		Config.WindUI.UIScaleObj,
		Window.AcrylicPaint and Window.AcrylicPaint.Frame or nil,
		Blur,
		Creator.NewRoundFrame(Window.UICorner, "Squircle", {
			ImageTransparency = 1, --  Window.Transparent and Config.WindUI.TransparencyValue or 0,
			Size = UDim2.new(1, 0, 1, 0),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			Name = "Background",
			ThemeTag = {
				ImageColor3 = "WindowBackground",
			},
			--ZIndex = -9999,
		}, {
			BGImage,
			BottomDragFrame,
			ResizeHandle,
		}),
		--[[New("UIScale", {
			Scale = 0.89,
		}),]]
		--UIStroke,
		UICorner,
		FullScreenIcon,
		FullScreenBlur,
		New("Frame", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			Name = "Main",
			--GroupTransparency = 1,
			Visible = false,
			ZIndex = 97,
		}, {
			New("UICorner", {
				CornerRadius = UDim.new(0, Window.UICorner),
			}),
			Window.UIElements.SideBarContainer,
			Window.UIElements.MainBar,

			UserIcon,

			Outline2,
			New("Frame", { -- Topbar
				Size = UDim2.new(1, 0, 0, Window.Topbar.Height),
				BackgroundTransparency = 1,
				BackgroundColor3 = Color3.fromRGB(50, 50, 50),
				Name = "Topbar",
			}, {
				Outline1,
				--[[New("Frame", { -- Outline
                    Size = UDim2.new(1,Window.UIPadding*2, 0, 1),
                    Position = UDim2.new(0,-Window.UIPadding, 1,Window.UIPadding-2),
                    BackgroundTransparency = 0.9,
                    BackgroundColor3 = Color3.fromHex(Config.Theme.Outline),
                }),]]
				New("Frame", { -- Topbar Left Side
					AutomaticSize = "X",
					Size = UDim2.new(0, 0, 1, 0),
					BackgroundTransparency = 1,
					Name = "Left",
				}, {
					New("UIListLayout", {
						Padding = UDim.new(0, Window.UIPadding + 4),
						SortOrder = "LayoutOrder",
						FillDirection = "Horizontal",
						VerticalAlignment = "Center",
					}),
					New("Frame", {
						AutomaticSize = "XY",
						BackgroundTransparency = 1,
						Name = "Title",
						Size = UDim2.new(0, 0, 1, 0),
						LayoutOrder = 2,
					}, {
						New("UIListLayout", {
							Padding = UDim.new(0, 0),
							SortOrder = "LayoutOrder",
							FillDirection = "Vertical",
							VerticalAlignment = "Center",
						}),
						WindowTitle,
						WindowAuthor,
					}),
					New("UIPadding", {
						PaddingLeft = UDim.new(0, 4),
					}),
				}),
				New("CanvasGroup", {
					Size = UDim2.new(0, 0, 1, 0),
					BackgroundTransparency = 1,
					Name = "Center",
					AnchorPoint = Vector2.new(0, 0.5),
					Position = UDim2.new(0, 0, 0.5, 0),
					AutomaticSize = "Y",
					Visible = false,
				}, {
					--[[New("UICorner", {
						CornerRadius = UDim.new(1, 0),
					}),]]
					New("ScrollingFrame", { -- Topbar Center Size
						Name = "Holder",
						BackgroundTransparency = 1,
						AutomaticSize = "Y",
						ScrollBarThickness = 0,
						ScrollingDirection = "X",
						AutomaticCanvasSize = "X",
						CanvasSize = UDim2.new(0, 0, 0, 0),
						Size = UDim2.new(1, 0, 1, 0),
						--AnchorPoint = Vector2.new(0, 0.5),
						--Position = UDim2.new(0, 0, 0.5, 0),
					}, {

						New("UIListLayout", {
							FillDirection = "Horizontal",
							VerticalAlignment = "Center",
							HorizontalAlignment = "Left",
							Padding = UDim.new(0, Window.UIPadding / 2),
						}),
					}),
				}),
				New("Frame", { -- Topbar Right Side -- Window.UIElements.Main.Main.Topbar.Right
					AutomaticSize = "XY",
					BackgroundTransparency = 1,
					Position = UDim2.new(Window.Topbar.ButtonsType == "Default" and 1 or 0, 0, 0.5, 0),
					AnchorPoint = Vector2.new(Window.Topbar.ButtonsType == "Default" and 1 or 0, 0.5),
					Name = "Right",
				}, {
					New("UIListLayout", {
						Padding = UDim.new(0, Window.Topbar.ButtonsType == "Default" and 9 or 0),
						FillDirection = "Horizontal",
						SortOrder = "LayoutOrder",
					}),
				}),
				New("UIPadding", {
					PaddingTop = UDim.new(0, Window.UIPadding),
					PaddingLeft = UDim.new(
						0,
						Window.Topbar.ButtonsType == "Default" and Window.UIPadding or Window.UIPadding - 2
					),
					PaddingRight = UDim.new(0, 8),
					PaddingBottom = UDim.new(0, Window.UIPadding),
				}),
			}),
		}),
	})

	Creator.AddSignal(Window.UIElements.Main.Main.Topbar.Left:GetPropertyChangedSignal("AbsoluteSize"), function()
		local LeftWidth = 0
		local RightWidth = Window.UIElements.Main.Main.Topbar.Right.UIListLayout.AbsoluteContentSize.X
			/ Config.WindUI.UIScale

		LeftWidth = Window.UIElements.Main.Main.Topbar.Left.AbsoluteSize.X / Config.WindUI.UIScale
		if Window.Topbar.ButtonsType ~= "Default" then
			LeftWidth = LeftWidth + RightWidth + Window.UIPadding - 4
		end

		Window.UIElements.Main.Main.Topbar.Center.Position =
			UDim2.new(0, LeftWidth + (Window.UIPadding / Config.WindUI.UIScale), 0.5, 0)
		Window.UIElements.Main.Main.Topbar.Center.Size = UDim2.new(
			1,
			-LeftWidth
				- (Window.UIPadding / Config.WindUI.UIScale)
				- (Window.Topbar.ButtonsType == "Default" and RightWidth + Window.UIPadding or 0),
			1,
			0
		)
	end)

	if Window.Topbar.ButtonsType ~= "Default" then
		Creator.AddSignal(Window.UIElements.Main.Main.Topbar.Right:GetPropertyChangedSignal("AbsoluteSize"), function()
			Window.UIElements.Main.Main.Topbar.Left.Position = UDim2.new(
				0,
				(Window.UIElements.Main.Main.Topbar.Right.AbsoluteSize.X / Config.WindUI.UIScale) + Window.UIPadding - 4,
				0,
				0
			)
		end)
	end

	function Window:CreateTopbarButton(Name, Icon, Callback, LayoutOrder, IconThemed, Color, IconSize)
		local IconFrame = Creator.Image(
			Icon,
			Icon,
			0,
			Window.Folder,
			"WindowTopbarIcon",
			Window.Topbar.ButtonsType == "Default" and true or false,
			IconThemed,
			"WindowTopbarButtonIcon"
		)
		IconFrame.Size = Window.Topbar.ButtonsType == "Default"
				and UDim2.new(0, IconSize or Window.TopBarButtonIconSize, 0, IconSize or Window.TopBarButtonIconSize)
			or UDim2.new(0, 0, 0, 0)
		IconFrame.AnchorPoint = Vector2.new(0.5, 0.5)
		IconFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
		IconFrame.ImageLabel.ImageTransparency = Window.Topbar.ButtonsType == "Default" and 0 or 1

		if Window.Topbar.ButtonsType ~= "Default" then
			IconFrame.ImageLabel.ImageColor3 = Creator.GetTextColorForHSB(Color)
		end

		local Button = Creator.NewRoundFrame(
			Window.Topbar.ButtonsType == "Default" and Window.UICorner - (Window.UIPadding / 2) or 999,
			"Squircle",
			{
				Size = Window.Topbar.ButtonsType == "Default"
						and UDim2.new(0, Window.Topbar.Height - 16, 0, Window.Topbar.Height - 16)
					or UDim2.new(0, 14, 0, 14),
				LayoutOrder = LayoutOrder or 999,
				--Parent = Window.Topbar.ButtonsType == "Default" and Window.UIElements.Main.Main.Topbar.Right or nil,
				--Active = true,
				ZIndex = 9999,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.5, 0, 0.5, 0),
				ImageColor3 = Window.Topbar.ButtonsType ~= "Default" and (Color or Color3.fromHex("#ff3030")) or nil,
				ThemeTag = Window.Topbar.ButtonsType == "Default" and {
					ImageColor3 = "Text",
				} or nil,
				ImageTransparency = Window.Topbar.ButtonsType == "Default" and 1 or 0, -- .93
			},
			{
				--[[Creator.NewRoundFrame(
					Window.Topbar.ButtonsType == "Default" and Window.UICorner - (Window.UIPadding / 2) or 999,
					"Glass-1",
					{
						Size = UDim2.new(1, 0, 1, 0),
						ThemeTag = {
							ImageColor3 = "Outline",
						},
						ImageTransparency = Window.Topbar.ButtonsType == "Default" and 1 or 0.5, -- .75
						Name = "Outline",
					}
				),]]
				IconFrame,
				New("UIScale", {
					Scale = 1,
				}),
			},
			true
		)

		local ButtonContainer = New("Frame", {
			Size = Window.Topbar.ButtonsType ~= "Default" and UDim2.new(0, 24, 0, 24)
				or UDim2.new(0, Window.Topbar.Height - 16, 0, Window.Topbar.Height - 16),
			BackgroundTransparency = 1,
			Parent = Window.UIElements.Main.Main.Topbar.Right,
			LayoutOrder = LayoutOrder or 999,
		}, {
			Button,
		})

		-- shhh

		Window.TopBarButtons[100 - LayoutOrder] = {
			Name = Name,
			Object = ButtonContainer,
		}

		Creator.AddSignal(Button.MouseButton1Click, function()
			if Callback then
				Callback()
			end
		end)
		Creator.AddSignal(Button.MouseEnter, function()
			if Window.Topbar.ButtonsType == "Default" then
				Tween(Button, 0.15, { ImageTransparency = 0.93 }):Play()
				--Tween(Button.Outline, 0.15, { ImageTransparency = 0.75 }):Play()
				--Tween(IconFrame.ImageLabel, .15, {ImageTransparency = 0}):Play()
			else
				--Tween(Button, .1, {Size = UDim2.new(0,14+8,0,14+8)}, Enum.EasingStyle.Quint, Enum.EasingDirection.Out):Play()
				Tween(
					IconFrame.ImageLabel,
					0.1,
					{ ImageTransparency = 0 },
					Enum.EasingStyle.Quint,
					Enum.EasingDirection.Out
				):Play()
				Tween(IconFrame, 0.1, {
					Size = UDim2.new(
						0,
						IconSize or Window.TopBarButtonIconSize,
						0,
						IconSize or Window.TopBarButtonIconSize
					),
				}, Enum.EasingStyle.Quint, Enum.EasingDirection.Out):Play()
			end
		end)

		Creator.AddSignal(Button.MouseButton1Down, function()
			Tween(Button.UIScale, 0.2, { Scale = 0.9 }, Enum.EasingStyle.Quint, Enum.EasingDirection.Out):Play()
		end)

		Creator.AddSignal(Button.MouseLeave, function()
			if Window.Topbar.ButtonsType == "Default" then
				Tween(Button, 0.1, { ImageTransparency = 1 }):Play()
				--Tween(Button.Outline, 0.1, { ImageTransparency = 1 }):Play()
				--Tween(IconFrame.ImageLabel, .1, {ImageTransparency = .2}):Play()
			else
				--Tween(Button, .1, {Size = UDim2.new(0,14,0,14)}, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut):Play()
				Tween(
					IconFrame.ImageLabel,
					0.1,
					{ ImageTransparency = 1 },
					Enum.EasingStyle.Quint,
					Enum.EasingDirection.Out
				):Play()
				Tween(
					IconFrame,
					0.1,
					{ Size = UDim2.new(0, 0, 0, 0) },
					Enum.EasingStyle.Quint,
					Enum.EasingDirection.Out
				):Play()
			end
		end)

		Creator.AddSignal(Button.InputEnded, function()
			Tween(Button.UIScale, 0.2, { Scale = 1 }, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut):Play()
		end)

		return Button
	end

	function Window.Topbar:Button(ButtonConfig: {
		Name: string,
		Icon: string,
		Callback: any,
		LayoutOrder: number,
		IconThemed: boolean,
		Color: Color3,
		IconSize: number,
	})
		return Window:CreateTopbarButton(
			ButtonConfig.Name,
			ButtonConfig.Icon,
			ButtonConfig.Callback,
			ButtonConfig.LayoutOrder or 0,
			ButtonConfig.IconThemed,
			ButtonConfig.Color,
			ButtonConfig.IconSize
		)
	end

	-- local Dragged = false

	local WindowDragModule = Creator.Drag(
		Window.UIElements.Main,
		{ Window.UIElements.Main.Main.Topbar, BottomDragFrame.Frame },
		function(dragging, frame) -- On drag
			if not Window.Closed then
				if dragging and frame == BottomDragFrame.Frame then
					Tween(BottomDragFrame, 0.1, { ImageTransparency = 0.35 }):Play()
				else
					Tween(BottomDragFrame, 0.2, { ImageTransparency = 0.8 }):Play()
				end
				Window.Position = Window.UIElements.Main.Position
				Window.Dragging = dragging
			end
		end
	)

	if not IsVideoBG and Window.Background and typeof(Window.Background) == "table" then
		local BackgroundGradient = New("UIGradient")
		for key, value in next, Window.Background do
			BackgroundGradient[key] = value
		end

		Window.UIElements.BackgroundGradient = Creator.NewRoundFrame(Window.UICorner, "Squircle", {
			Size = UDim2.new(1, 0, 1, 0),
			Parent = Window.UIElements.Main.Background,
			ImageTransparency = Window.Transparent and Config.WindUI.TransparencyValue or 0,
		}, {
			BackgroundGradient,
		})
	end

	-- local blur = require("../Blur")

	-- blur.new(Window.UIElements.Main.Background, {
	--     Corner = Window.UICorner
	-- })

	--Creator.Blur(Window.UIElements.Main.Background)
	-- local OpenButtonDragModule

	-- if not Window.IsPC then
	--     OpenButtonDragModule = Creator.Drag(OpenButtonContainer)
	-- end

	Window.OpenButtonMain = require("./Openbutton").New(Window)

	task.spawn(function()
		if Window.Icon then
			local WindowIconContainer = New("Frame", {
				Size = UDim2.new(0, 22, 0, 22),
				BackgroundTransparency = 1,
				Parent = Window.UIElements.Main.Main.Topbar.Left,
			})

			WindowIcon = Creator.Image(
				Window.Icon,
				Window.Title,
				Window.IconRadius,
				Window.Folder,
				"Window",
				true,
				Window.IconThemed,
				"WindowTopbarIcon"
			)
			WindowIcon.Parent = WindowIconContainer
			WindowIcon.Size = UDim2.new(0, Window.IconSize, 0, Window.IconSize)
			WindowIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
			WindowIcon.AnchorPoint = Vector2.new(0.5, 0.5)

			Window.OpenButtonMain:SetIcon(Window.Icon)

			-- if Creator.Icon(tostring(Window.Icon)) and Creator.Icon(tostring(Window.Icon))[1] then
			--     -- ImageLabel.Image = Creator.Icon(Window.Icon)[1]
			--     -- ImageLabel.ImageRectOffset = Creator.Icon(Window.Icon)[2].ImageRectPosition
			--     -- ImageLabel.ImageRectSize = Creator.Icon(Window.Icon)[2].ImageRectSize
			--     -- OpenButtonIcon.Image = Creator.Icon(Window.Icon)[1]
			--     -- OpenButtonIcon.ImageRectOffset = Creator.Icon(Window.Icon)[2].ImageRectPosition
			--     -- OpenButtonIcon.ImageRectSize = Creator.Icon(Window.Icon)[2].ImageRectSize

			-- end
			-- end
		else
			Window.OpenButtonMain:SetIcon(Window.Icon)
			--OpenButtonIcon.Visible = false
		end
	end)

	function Window:SetToggleKey(keycode)
		Window.ToggleKey = keycode
	end

	function Window:SetTitle(text)
		Window.Title = text
		WindowTitle.Text = text
	end

	function Window:SetAuthor(text)
		Window.Author = text
		if not WindowAuthor then
			WindowAuthor = createAuthor(Window.Author)
		end

		WindowAuthor.Text = text
	end

	function Window:SetSize(size)
		finishResize(false)
		finishFullscreen()
		if typeof(size) == "UDim2" then
			Window.Size = size

			Tween(Window.UIElements.Main, 0.08, { Size = size }, Enum.EasingStyle.Quint, Enum.EasingDirection.Out):Play()
		end
	end

	function Window:SetBackgroundImage(id)
		Window.UIElements.Main.Background.ImageLabel.Image = id
	end
	function Window:SetBackgroundImageTransparency(v)
		if BGImage and BGImage:IsA("ImageLabel") then
			BGImage.ImageTransparency = math.floor(v * 10 + 0.5) / 10
		end
		Window.BackgroundImageTransparency = math.floor(v * 10 + 0.5) / 10
	end

	function Window:SetBackgroundTransparency(v)
		local rounded = math.floor(tonumber(v) * 10 + 0.5) / 10
		Config.WindUI.TransparencyValue = rounded
		Window:ToggleTransparency(rounded > 0)
	end

	local CurrentPos
	local CurrentSize
	local iconCopy = Creator.Icon("minimize")
	local iconSquare = Creator.Icon("maximize")

	local FullscreenButton = Window:CreateTopbarButton(
		"Fullscreen",
		Window.Topbar.ButtonsType == "Mac" and "rbxassetid://127426072704909" or "maximize",
		function()
			Window:ToggleFullscreen()
		end,
		(Window.Topbar.ButtonsType == "Default" and 998 or 999),
		true,
		Color3.fromHex("#60C762"),
		Window.Topbar.ButtonsType == "Mac" and 9 or nil
	)

	-- lesbhub:fullscreen-start
	local fullscreenGeneration = 0
	local fullscreenTween, fullscreenConnection, fullscreenShell
	local fullscreenStartedAt, fullscreenReadyAt
	local function traceFullscreen(event, ...)
		if Window.FullscreenDiagnostic then
			Creator.SafeCallback(Window.FullscreenDiagnostic, event, fullscreenGeneration, ...)
		end
	end
	local function targetFullscreenSize()
		local uiScale = tonumber(Config.WindUI.UIScale) or 1
		if uiScale <= 0 then uiScale = 1 end
		local viewport = Config.WindUI.ScreenGui.AbsoluteSize
		return UDim2.new(0, math.max(0, viewport.X - 20) / uiScale,
			0, math.max(0, viewport.Y - 20 - 52) / uiScale)
	end
	finishFullscreen = function(completed)
		if not Window.FullscreenTransitioning then return end
		if Window.FullscreenDiagnostic then
			local now = os.clock()
			local startedAt = fullscreenStartedAt or now
			traceFullscreen(completed and "end" or "cancel", now - startedAt, now - (fullscreenReadyAt or startedAt))
		end
		fullscreenGeneration += 1
		if fullscreenConnection then fullscreenConnection:Disconnect(); fullscreenConnection = nil end
		if fullscreenTween then fullscreenTween:Cancel(); fullscreenTween = nil end
		if fullscreenShell then fullscreenShell:Destroy(); fullscreenShell = nil end
		Window.FullscreenTransitioning = false
		if not Window.Destroyed and Window.OnFullscreenTransitionFinished then
			Creator.SafeCallback(Window.OnFullscreenTransitionFinished)
		end
	end
	local function SetSize(animate)
		finishFullscreen()
		if Window.Destroyed then return end
		local main = Window.UIElements.Main
		local size = Window.IsFullscreen and targetFullscreenSize() or CurrentSize
		local position = Window.IsFullscreen and UDim2.new(0.5, 0, 0.5, 52 / 2) or CurrentPos
		if not size or not position then return end
		if animate then
			Window.FullscreenTransitioning = true
			fullscreenGeneration += 1
			fullscreenStartedAt, fullscreenReadyAt = nil, nil
			if Window.FullscreenDiagnostic then fullscreenStartedAt = os.clock() end
			traceFullscreen("start", Window.IsFullscreen)
			if Window.OnFullscreenTransitionStarted then Creator.SafeCallback(Window.OnFullscreenTransitionStarted) end
		end
		-- Keep the content at its final logical dimensions throughout the effect.
		local changedSize, changedPosition = main.Size ~= size, main.Position ~= position
		if changedSize then main.Size = size end
		if changedPosition then main.Position = position end
		if not animate then return end
		if Window.FullscreenDiagnostic then fullscreenReadyAt = os.clock() end
		traceFullscreen("layout", changedSize and 1 or 0, changedPosition and 1 or 0,
			fullscreenReadyAt and fullscreenStartedAt and fullscreenReadyAt - fullscreenStartedAt or 0)
		local generation = fullscreenGeneration
		-- A translucent border fades over the real, already-laid-out window.
		-- It never hides or duplicates the interactive content.
		fullscreenShell = New("Frame", {
			Name = "FullscreenTransition", BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 1, 0), ZIndex = 1000, Parent = main,
		}, {
			New("UICorner", { CornerRadius = UDim.new(0, Window.UICorner) }),
			New("UIStroke", { Name = "Outline", Transparency = 0.7, Thickness = 1,
				ThemeTag = { Color = "Outline" } }),
		})
		fullscreenTween = Tween(fullscreenShell.Outline, 0.25, { Transparency = 1 },
			Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
		fullscreenConnection = fullscreenTween.Completed:Connect(function()
			if generation == fullscreenGeneration then finishFullscreen(true) end
		end)
		fullscreenTween:Play()
	end

	function Window:ToggleFullscreen()
		if Window.Destroyed or Window.Closed then return end
		finishResize(false)
		finishFullscreen()
		if openTween then openTween:Cancel(); openTween = nil end
		local isFullscreen = Window.IsFullscreen
		WindowDragModule:Set(isFullscreen)
		if not isFullscreen then
			CurrentPos = Window.UIElements.Main.Position
			CurrentSize = Window.UIElements.Main.Size
			Window.CanResize = false
		else
			Window.CanResize = Window.Resizable == true and not Window.SearchActive
		end
		Window.IsFullscreen = not isFullscreen
		SetSize(true)
	end
	-- lesbhub:fullscreen-end

	Creator.AddSignal(Config.WindUI.ScreenGui:GetPropertyChangedSignal("AbsoluteSize"), function()
		if Window.IsFullscreen then
			SetSize()
		end
	end)

	if not Window.HideMinimizeButton then
	Window:CreateTopbarButton("Minimize", "minus", function()
		if Window.Close then
			Window:Close()
		end
		-- task.spawn(function()
		--     task.wait(.3)
		--     if not Window.IsPC and Window.IsOpenButtonEnabled then
		--         -- OpenButtonContainer.Visible = true
		--         --Window.OpenButtonMain:Visible(true)
		--     end
		-- end)

		-- local NotifiedText = Window.IsPC and "Press " .. Window.ToggleKey.Name .. " to open the Window" or "Click the Button to open the Window"

		-- if not Window.IsOpenButtonEnabled then
		--     Notified = true
		-- end
		-- if not Notified then
		--     Notified = not Notified
		--     Config.WindUI:Notify({
		--         Title = "Minimize",
		--         Content = "You've closed the Window. " .. NotifiedText,
		--         Icon = "eye-off",
		--         Duration = 5,
		--     })
		-- end
	end, (Window.Topbar.ButtonsType == "Default" and 997 or 998), nil, Color3.fromHex("#F4C948"))
	end

	function Window:OnOpen(func)
		Window.OnOpenCallback = func
	end
	function Window:OnClose(func)
		Window.OnCloseCallback = func
	end
	function Window:OnDestroy(func)
		Window.OnDestroyCallback = func
	end

	if Config.WindUI.UseAcrylic then
		Window.AcrylicPaint.AddParent(Window.UIElements.Main)
	end

	function Window:SetIconSize(Size)
		local NewSize
		if typeof(Size) == "number" then
			NewSize = UDim2.new(0, Size, 0, Size)
			Window.IconSize = Size
		elseif typeof(Size) == "UDim2" then
			NewSize = Size
			Window.IconSize = Size.X.Offset
		end

		if WindowIcon then
			WindowIcon.Size = NewSize
		end
	end

	function Window:Open()
		if Window.Destroyed then
			return
		end
		Window.VisibilityGeneration += 1
		local generation = Window.VisibilityGeneration
		Window.Closed = false
		task.spawn(function()
			task.wait(0.06)
			if Window.Destroyed or Window.Closed or Window.VisibilityGeneration ~= generation then
				return
			end
			if Window.OnOpenCallback then
				task.spawn(function()
					Creator.SafeCallback(Window.OnOpenCallback)
				end)
			end

			if Window.IsFullscreen then
				SetSize(false)
			else
				Window.UIElements.Main.Size = UDim2.new(Window.Size.X.Scale, Window.Size.X.Offset, 0, 100)
				openTween = Tween(Window.UIElements.Main, 0.8, { Size = Window.Size },
					Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
				openTween:Play()
			end

			if Window.UIElements.BackgroundGradient then
				Tween(Window.UIElements.BackgroundGradient, 0.2, {
					ImageTransparency = 0,
				}, Enum.EasingStyle.Quint, Enum.EasingDirection.Out):Play()
			end

			Window.UIElements.Main.Background.ImageTransparency = 1
			Tween(Window.UIElements.Main.Background, 0.4, {
				--Size = UDim2.new(1, 0, 1, 0),
				ImageTransparency = Window.Transparent and Config.WindUI.TransparencyValue or 0,
			}, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out):Play()

			if BGImage then
				if BGImage:IsA("VideoFrame") then
					BGImage.Visible = true
				else
					Tween(BGImage, 0.2, {
						ImageTransparency = Window.BackgroundImageTransparency,
					}, Enum.EasingStyle.Quint, Enum.EasingDirection.Out):Play()
				end
			end

			if Window.OpenButtonMain and Window.IsOpenButtonEnabled then
				Window.OpenButtonMain:Visible(false)
			end

			--[[Config.WindUI.UIScaleObj.Scale -= 1 - 0.85
			Tween(
				Config.WindUI.UIScaleObj,
				0.33,
				{ Scale = Config.WindUI.UIScale },
				Enum.EasingStyle.Back,
				Enum.EasingDirection.Out
			):Play()]]
			Tween(
				Blur,
				0.25,
				{ ImageTransparency = Window.ShadowTransparency },
				Enum.EasingStyle.Quint,
				Enum.EasingDirection.Out
			):Play()
			--[[if UIStroke then
				Tween(UIStroke, 0.25, { Transparency = 0.8 }, Enum.EasingStyle.Quint, Enum.EasingDirection.Out):Play()
			end]]

			Tween(
				BottomDragFrame,
				0.45,
				{ Size = UDim2.new(0, Window.DragFrameSize, 0, 4), ImageTransparency = 0.8 },
				Enum.EasingStyle.Exponential,
				Enum.EasingDirection.Out
			):Play()
			WindowDragModule:Set(true)

			if Window.Resizable and not Window.IsFullscreen then
				Tween(
					ResizeHandle.ImageLabel,
					0.45,
					{ ImageTransparency = 0.8 },
					Enum.EasingStyle.Exponential,
					Enum.EasingDirection.Out
				):Play()
				Window.CanResize = true
			end

			Window.CanDropdown = true
			Window.UIElements.Main.Visible = true
			--task.spawn(function()
			--task.wait(0.05)

			Window.UIElements.Main:WaitForChild("Main").Visible = true

			Config.WindUI:ToggleAcrylic(true)
			--end)
		end)
	end
	function Window:Close()
		if Window.Destroyed then
			return
		end

		finishResize(false)
		finishFullscreen()
		if openTween then openTween:Cancel(); openTween = nil end
		local Close = {}

		if Window.OnCloseCallback then
			task.spawn(function()
				Creator.SafeCallback(Window.OnCloseCallback)
			end)
		end

		Config.WindUI:ToggleAcrylic(false)

		if Window.UIElements.Main and Window.UIElements.Main:WaitForChild("Main") then
			Window.UIElements.Main.Main.Visible = false
		end

		Window.CanDropdown = false
		Window.VisibilityGeneration += 1
		local closeGeneration = Window.VisibilityGeneration
		Window.Closed = true

		Tween(Window.UIElements.Main, 0.9, {
			--GroupTransparency = 1,
			Size = UDim2.new(Window.Size.X.Scale, Window.Size.X.Offset, 0, 0),
		}, Enum.EasingStyle.Quint, Enum.EasingDirection.Out):Play()
		if Window.UIElements.BackgroundGradient then
			Tween(Window.UIElements.BackgroundGradient, 0.2, {
				ImageTransparency = 1,
			}, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut):Play()
		end

		Tween(Window.UIElements.Main.Background, 0.3, {
			--Size = UDim2.new(1, 0, 1, -240),
			ImageTransparency = 1,
		}, Enum.EasingStyle.Exponential, Enum.EasingDirection.InOut):Play()

		--[[Tween(
			Config.WindUI.UIScaleObj,
			0.28,
			{ Scale = Config.WindUI.UIScale - (1 - 0.85) },
			Enum.EasingStyle.Quint,
			Enum.EasingDirection.Out
		):Play()]]
		if BGImage then
			if BGImage:IsA("VideoFrame") then
				BGImage.Visible = false
			else
				Tween(BGImage, 0.3, {
					ImageTransparency = 1,
				}, Enum.EasingStyle.Quint, Enum.EasingDirection.Out):Play()
			end
		end
		Tween(Blur, 0.25, { ImageTransparency = 1 }, Enum.EasingStyle.Quint, Enum.EasingDirection.Out):Play()
		--[[if UIStroke then
			Tween(UIStroke, 0.25, { Transparency = 1 }, Enum.EasingStyle.Quint, Enum.EasingDirection.Out):Play()
		end]]

		Tween(
			BottomDragFrame,
			0.3,
			{ Size = UDim2.new(0, 0, 0, 4), ImageTransparency = 1 },
			Enum.EasingStyle.Exponential,
			Enum.EasingDirection.InOut
		):Play()
		Tween(
			ResizeHandle.ImageLabel,
			0.3,
			{ ImageTransparency = 1 },
			Enum.EasingStyle.Exponential,
			Enum.EasingDirection.Out
		):Play()
		WindowDragModule:Set(false)
		Window.CanResize = false

		task.spawn(function()
			task.wait(0.4)

			if Window.Destroyed or not Window.Closed or Window.VisibilityGeneration ~= closeGeneration then
				return
			end

			Window.UIElements.Main.Visible = false

			if Window.OpenButtonMain and not Window.Destroyed and not Window.IsPC and Window.IsOpenButtonEnabled then
				Window.OpenButtonMain:Visible(true)
			end
		end)

		function Close:Destroy()
			if Window.Destroyed then
				return
			end
			Window.Destroyed = true
			if Window.TabModule then
				for _, tab in ipairs(Window.TabModule.Tabs) do
					if tab.CancelPendingFocus then
						tab.CancelPendingFocus()
					end
				end
			end
			for _, connection in ipairs(Config.WindUI._RootConnections or {}) do
				if connection.Connected then
					connection:Disconnect()
				end
			end
			table.clear(Config.WindUI._RootConnections or {})
			Creator.DisconnectAll()

			task.spawn(function()
				if Window.OnDestroyCallback then
					task.spawn(function()
						Creator.SafeCallback(Window.OnDestroyCallback)
					end)
				end

				if Window.AcrylicPaint and Window.AcrylicPaint.Model then
					Window.AcrylicPaint.Model:Destroy()
				end

				task.wait(0.4)

				Config.WindUI.ScreenGui:Destroy()
				Config.WindUI.NotificationGui:Destroy()
				Config.WindUI.DropdownGui:Destroy()
				Config.WindUI.TooltipGui:Destroy()

				Creator.DisconnectAll()

				return
			end)
		end

		return Close
	end
	function Window:Destroy()
		if Window.Destroyed then
			return
		end
		local closing = Window:Close()
		if closing then
			return closing:Destroy()
		end
	end
	function Window:Toggle()
		if Window.Closed then
			Window:Open()
		else
			Window:Close()
		end
	end

	function Window:ToggleTransparency(Value)
		-- Config.Transparent = Value
		Window.Transparent = Value
		Config.WindUI.Transparent = Value

		Window.UIElements.Main.Background.ImageTransparency = Value and Config.WindUI.TransparencyValue or 0
		-- Window.UIElements.Main.Background.ImageLabel.ImageTransparency = Value and Config.WindUI.TransparencyValue or 0
		--Window.UIElements.MainBar.Background.ImageTransparency = Value and 0.97 or 0.95
	end

	function Window:LockAll()
		for _, element in next, Window.AllElements do
			if element.Lock then
				element:Lock()
			end
		end
	end
	function Window:UnlockAll()
		for _, element in next, Window.AllElements do
			if element.Unlock then
				element:Unlock()
			end
		end
	end
	function Window:GetLocked()
		local LockedElements = {}

		for _, element in next, Window.AllElements do
			if element.Locked then
				table.insert(LockedElements, element)
			end
		end

		return LockedElements
	end
	function Window:GetUnlocked()
		local UnlockedElements = {}

		for _, element in next, Window.AllElements do
			if element.Locked == false then
				table.insert(UnlockedElements, element)
			end
		end

		return UnlockedElements
	end

	function Window:GetUIScale(v)
		return Config.WindUI.UIScale
	end

	function Window:SetUIScale(v)
		if type(v) ~= "number" or v <= 0 then return Window end
		Config.WindUI.UIScale = v
		if Window.IsFullscreen then SetSize(false) end
		Tween(Config.WindUI.UIScaleObj, 0.2, { Scale = v }, Enum.EasingStyle.Quint, Enum.EasingDirection.Out):Play()
		return Window
	end

	function Window:SetToTheCenter()
		Tween(
			Window.UIElements.Main,
			0.45,
			{ Position = UDim2.new(0.5, 0, 0.5, 0) },
			Enum.EasingStyle.Quint,
			Enum.EasingDirection.Out
		):Play()
		return Window
	end

	function Window:SetCurrentConfig(ConfigModule)
		Window.CurrentConfig = ConfigModule
	end

	do
		local Margin = 40
		local ViewportSize = CurrentCamera.ViewportSize
		local WindowSize = Vector2.new(Window.Size.X.Offset, Window.Size.Y.Offset)

		if not Window.IsFullscreen and Window.AutoScale then
			local AvailableWidth = ViewportSize.X - (Margin * 2)
			local AvailableHeight = ViewportSize.Y - (Margin * 2)

			local ScaleX = AvailableWidth / WindowSize.X
			local ScaleY = AvailableHeight / WindowSize.Y

			local RequiredScale = math.min(ScaleX, ScaleY)

			local MinScale = 0.3
			local MaxScale = 1.0

			local FinalScale = math.clamp(RequiredScale, MinScale, MaxScale)

			local CurrentScale = Window:GetUIScale() or 1
			local Tolerance = 0.05

			if math.abs(FinalScale - CurrentScale) > Tolerance then
				Window:SetUIScale(FinalScale)
			end
		end
	end

	if Window.OpenButtonMain and Window.OpenButtonMain.Button then
		Creator.AddSignal(Window.OpenButtonMain.Button.TextButton.MouseButton1Click, function()
			-- OpenButtonContainer.Visible = false
			--Window.OpenButtonMain:Visible(false)
			Window:Open()
		end)
	end

	Creator.AddGlobalInputBegan(function(input, isProcessed)
		if isProcessed then
			return
		end

		if Window.ToggleKey then
			if input.KeyCode == Window.ToggleKey then
				Window:Toggle()
			end
		end
	end)

	task.spawn(function()
		--task.wait(1.38583)
		Window:Open()
	end)

	function Window:EditOpenButton(OpenButtonConfig)
		return Window.OpenButtonMain:Edit(OpenButtonConfig)
	end

	if Window.OpenButton and typeof(Window.OpenButton) == "table" then
		Window:EditOpenButton(Window.OpenButton)
	end

	local TabModuleMain = require("./Tab")
	local SectionModule = require("./Section")
	local TabModule = TabModuleMain.Init(Window, Config.WindUI, Config.WindUI.TooltipGui)
	TabModule:OnChange(function(t)
		Window.CurrentTab = t
	end)

	Window.TabModule = TabModule

	function Window:Tab(TabConfig)
		TabConfig.Parent = Window.UIElements.SideBar.Frame
		return TabModule.New(TabConfig, Config.WindUI.UIScale)
	end

	function Window:SelectTab(Tab)
		TabModule:SelectTab(Tab)
	end

	function Window:Section(SectionConfig)
		return SectionModule.New(
			SectionConfig,
			Window.UIElements.SideBar.Frame,
			Window.Folder,
			Config.WindUI.UIScale,
			Window
		)
	end

	function Window:IsResizable(v)
		if not v then finishResize(false) end
		Window.Resizable = v
		Window.CanResize = v
	end

	function Window:SetPanelBackground(v)
		if typeof(v) == "boolean" then
			Window.HidePanelBackground = v

			Window.UIElements.MainBar.Background.Visible = v

			if TabModule then
				for _, Container in next, TabModule.Containers do
					Container.ScrollingFrame.UIPadding.PaddingTop = UDim.new(0, Window.HidePanelBackground and 20 or 10)
					Container.ScrollingFrame.UIPadding.PaddingLeft =
						UDim.new(0, Window.HidePanelBackground and 20 or 10)
					Container.ScrollingFrame.UIPadding.PaddingRight =
						UDim.new(0, Window.HidePanelBackground and 20 or 10)
					Container.ScrollingFrame.UIPadding.PaddingBottom =
						UDim.new(0, Window.HidePanelBackground and 20 or 10)
				end
			end
		end
	end

	function Window:Divider()
		local Divider = New("Frame", {
			Size = UDim2.new(1, 0, 0, 1),
			Position = UDim2.new(0.5, 0, 0, 0),
			AnchorPoint = Vector2.new(0.5, 0),
			BackgroundTransparency = 0.9,
			ThemeTag = {
				BackgroundColor3 = "Text",
			},
		})
		local MainDivider = New("Frame", {
			Parent = Window.UIElements.SideBar.Frame,
			--AutomaticSize = "Y",
			Size = UDim2.new(1, -7, 0, 5),
			BackgroundTransparency = 1,
		}, {
			Divider,
		})

		return MainDivider
	end

	local DialogModule = require("./Dialog")
	function Window:Dialog(DialogConfig)
		local DialogTable = {
			Title = DialogConfig.Title or "Dialog",
			Width = DialogConfig.Width or 320,
			Content = DialogConfig.Content,
			Buttons = DialogConfig.Buttons or {},

			TextPadding = 14,
		}
		local Dialog = DialogModule.Create(false, "Dialog", Window, Config.WindUI, Window.UIElements.Main.Main)

		Dialog.UIElements.Main.Size = UDim2.new(0, DialogTable.Width, 0, 0)

		local DialogTopColFrame = New("Frame", {
			Size = UDim2.new(1, 0, 1, 0),
			AutomaticSize = "Y",
			BackgroundTransparency = 1,
			Parent = Dialog.UIElements.Main,
		}, {
			New("UIListLayout", {
				FillDirection = "Vertical",
				--HorizontalAlignment = "Center",
				Padding = UDim.new(0, Dialog.UIPadding),
			}),
		})

		local DialogTopRowFrame = New("Frame", {
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = "Y",
			BackgroundTransparency = 1,
			Parent = DialogTopColFrame,
		}, {
			New("UIListLayout", {
				FillDirection = "Horizontal",
				Padding = UDim.new(0, Dialog.UIPadding),
				VerticalAlignment = "Center",
			}),
			New("UIPadding", {
				PaddingTop = UDim.new(0, DialogTable.TextPadding / 2),
				PaddingLeft = UDim.new(0, DialogTable.TextPadding / 2),
				PaddingRight = UDim.new(0, DialogTable.TextPadding / 2),
			}),
		})

		local Icon
		if DialogConfig.Icon then
			Icon = Creator.Image(
				DialogConfig.Icon,
				DialogTable.Title .. ":" .. DialogConfig.Icon,
				0,
				Window,
				"Dialog",
				true,
				DialogConfig.IconThemed
			)
			Icon.Size = UDim2.new(0, 22, 0, 22)
			Icon.Parent = DialogTopRowFrame
		end

		Dialog.UIElements.UIListLayout = New("UIListLayout", {
			Padding = UDim.new(0, 12),
			FillDirection = "Vertical",
			HorizontalAlignment = "Left",
			VerticalFlex = "SpaceBetween",
			Parent = Dialog.UIElements.Main,
		})

		New("UISizeConstraint", {
			MinSize = Vector2.new(180, 20),
			MaxSize = Vector2.new(400, math.huge),
			Parent = Dialog.UIElements.Main,
		})

		Dialog.UIElements.Title = New("TextLabel", {
			Text = DialogTable.Title,
			TextSize = 20,
			FontFace = Font.new(Creator.Font, Enum.FontWeight.SemiBold),
			TextXAlignment = "Left",
			TextWrapped = true,
			RichText = true,
			Size = UDim2.new(1, Icon and -26 - Dialog.UIPadding or 0, 0, 0),
			AutomaticSize = "Y",
			ThemeTag = {
				TextColor3 = "Text",
			},
			BackgroundTransparency = 1,
			Parent = DialogTopRowFrame,
		})
		if DialogTable.Content then
			local Content = New("TextLabel", {
				Text = DialogTable.Content,
				TextSize = 18,
				TextTransparency = 0.4,
				TextWrapped = true,
				RichText = true,
				FontFace = Font.new(Creator.Font, Enum.FontWeight.Medium),
				TextXAlignment = "Left",
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = "Y",
				LayoutOrder = 2,
				ThemeTag = {
					TextColor3 = "Text",
				},
				BackgroundTransparency = 1,
				Parent = DialogTopColFrame,
			}, {
				New("UIPadding", {
					PaddingLeft = UDim.new(0, DialogTable.TextPadding / 2),
					PaddingRight = UDim.new(0, DialogTable.TextPadding / 2),
					PaddingBottom = UDim.new(0, DialogTable.TextPadding / 2),
				}),
			})
		end

		local ButtonsLayout = New("UIListLayout", {
			Padding = UDim.new(0, 6),
			FillDirection = "Horizontal",
			HorizontalAlignment = "Center",
			HorizontalFlex = "Fill",
		})

		local ButtonsContent = New("Frame", {
			Size = UDim2.new(1, 0, 0, 36),
			AutomaticSize = "None",
			BackgroundTransparency = 1,
			Parent = Dialog.UIElements.Main,
			LayoutOrder = 4,
		}, {
			ButtonsLayout,
			-- New("UIPadding", {
			--     PaddingTop = UDim.new(0, DialogTable.TextPadding/2),
			--     PaddingLeft = UDim.new(0, DialogTable.TextPadding/2),
			--     PaddingRight = UDim.new(0, DialogTable.TextPadding/2),
			--     PaddingBottom = UDim.new(0, DialogTable.TextPadding/2),
			-- })
		})

		local Buttons = {}

		for _, Button in next, DialogTable.Buttons do
			local ButtonFrame =
				CreateButton(Button.Title, Button.Icon, Button.Callback, Button.Variant, ButtonsContent, Dialog, true)
			table.insert(Buttons, ButtonFrame)
			ButtonFrame.Size = UDim2.new(1, 0, 1, 0)
		end

		local function CheckButtonsOverflow()
			ButtonsLayout.FillDirection = Enum.FillDirection.Horizontal
			ButtonsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
			ButtonsLayout.VerticalAlignment = Enum.VerticalAlignment.Center
			ButtonsContent.AutomaticSize = Enum.AutomaticSize.None

			for _, button in ipairs(Buttons) do
				button.Size = UDim2.new(0, 0, 1, 0)
				button.AutomaticSize = Enum.AutomaticSize.X
			end

			wait()

			local totalWidth = ButtonsLayout.AbsoluteContentSize.X / Config.WindUI.UIScale
			local parentWidth = ButtonsContent.AbsoluteSize.X / Config.WindUI.UIScale

			if totalWidth > parentWidth then
				ButtonsLayout.FillDirection = Enum.FillDirection.Vertical
				ButtonsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
				ButtonsLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
				ButtonsContent.AutomaticSize = Enum.AutomaticSize.Y

				for _, button in ipairs(Buttons) do
					button.Size = UDim2.new(1, 0, 0, 36)
					button.AutomaticSize = Enum.AutomaticSize.None
				end
			else
				local availableSpace = parentWidth - totalWidth
				if availableSpace > 0 then
					local smallestButton = nil
					local smallestWidth = math.huge

					for _, button in ipairs(Buttons) do
						local buttonWidth = button.AbsoluteSize.X / Config.WindUI.UIScale
						if buttonWidth < smallestWidth then
							smallestWidth = buttonWidth
							smallestButton = button
						end
					end

					if smallestButton then
						smallestButton.Size = UDim2.new(0, smallestWidth + availableSpace, 1, 0)
						smallestButton.AutomaticSize = Enum.AutomaticSize.None
					end
				end
			end
		end

		-- Creator.AddSignal(Dialog.UIElements.Main:GetPropertyChangedSignal("AbsoluteSize"), CheckButtonsOverflow)
		-- CheckButtonsOverflow()

		-- wait()
		Dialog:Open()

		return Dialog
	end

	local ClickedClose = false

	Window:CreateTopbarButton("Close", "x", function()
		if Window.CloseBehavior == "Hide" then
			Window:Close()
			return
		elseif Window.CloseBehavior == "Destroy" then
			Window:Destroy()
			return
		end
		if not ClickedClose then
			if not Window.IgnoreAlerts then
				ClickedClose = true
				--Window:SetToTheCenter()
				Window:Dialog({
					--Icon = "trash-2",
					Title = "Close Window",
					Content = "Do you want to close this window? You will not be able to open it again.",
					Buttons = {
						{
							Title = "Cancel",
							--Icon = "chevron-left",
							Callback = function()
								ClickedClose = false
							end,
							Variant = "Secondary",
						},
						{
							Title = "Close Window",
							--Icon = "chevron-down",
							Callback = function()
								ClickedClose = false
								Window:Destroy()
							end,
							Variant = "Primary",
						},
					},
				})
			else
				Window:Destroy()
			end
		end
	end, (Window.Topbar.ButtonsType == "Default" and 999 or 997), nil, Color3.fromHex("#F4695F"))

	function Window:Tag(TagConfig)
		if Window.UIElements.Main.Main.Topbar.Center.Visible == false then
			Window.UIElements.Main.Main.Topbar.Center.Visible = true
		end
		TagConfig.Window = Window
		return Tag:New(TagConfig, Window.UIElements.Main.Main.Topbar.Center.Holder)
	end

	-- lesbhub:resize-start
	local CurResizeInput = Config.WindUI.GenerateGUID()
	local isResizing = false
	local generation = 0
	local owner, kind, startPosition, startSize, pending, startScale
	local renderConnection, endConnection, inputEndConnection, focusConnection

	local function scale()
		local value = Config.WindUI.UIScaleObj and Config.WindUI.UIScaleObj.Scale or Config.WindUI.UIScale
		return type(value) == "number" and value > 0 and value or 1
	end
	local function valid()
		return (not isResizing or Config.WindUI.CurrentInput == CurResizeInput)
			and not Window.Destroyed and not Window.Closed and Window.Resizable and Window.CanResize
			and not Window.IsFullscreen and Window.UIElements.Main and Window.UIElements.Main.Parent
			and Window.UIElements.Main.Visible and Config.WindUI.ScreenGui.Enabled
	end
	local function applyLatest()
		if not isResizing or not pending or not valid() then return end
		local currentScale = scale()
		if currentScale ~= startScale then
			-- Rebase at the current pointer when scaling changes, so a scale transition
			-- cannot reinterpret the accumulated screen-space delta as a jump.
			startSize, startPosition, startScale = Window.Size, pending, currentScale
			pending = nil
			return
		end
		local delta = pending - startPosition
		local x = math.clamp(startSize.X.Offset + delta.X * 2 / currentScale, Window.MinSize.X, Window.MaxSize.X)
		local y = math.clamp(startSize.Y.Offset + delta.Y * 2 / currentScale, Window.MinSize.Y, Window.MaxSize.Y)
		pending = nil
		local previous = Window.UIElements.Main.Size
		if previous.X.Scale == 0 and previous.Y.Scale == 0 and previous.X.Offset == x and previous.Y.Offset == y then return end
		local size = UDim2.new(0, x, 0, y)
		Window.UIElements.Main.Size = size
		Window.Size = size
	end
	finishResize = function(flush)
		if not isResizing then return end
		if flush then applyLatest() end
		isResizing, Window.Resizing = false, false
		generation += 1
		for _, connection in ipairs({renderConnection, endConnection, inputEndConnection, focusConnection}) do
			connection:Disconnect()
		end
		renderConnection, endConnection, inputEndConnection, focusConnection = nil, nil, nil, nil
		owner, kind, startPosition, startSize, pending = nil, nil, nil, nil, nil
		if Config.WindUI.CurrentInput == CurResizeInput then Config.WindUI.CurrentInput = nil end
		if not Window.Destroyed then
			FullScreenIcon.Active = false
			Tween(ResizeHandle.ImageLabel, 0.17, { ImageTransparency = 0.8 }):Play()
			if Window.OnResizeFinished then Creator.SafeCallback(Window.OnResizeFinished) end
		end
	end
	function Window:CancelResize() finishResize(false) end

	Creator.AddSignal(ResizeHandle.InputBegan, function(input)
		local inputType = input.UserInputType
		if (inputType ~= Enum.UserInputType.MouseButton1 and inputType ~= Enum.UserInputType.Touch)
			or isResizing or not valid() or Config.WindUI.CurrentInput then return end
		finishFullscreen()
		Config.WindUI.CurrentInput = CurResizeInput
		isResizing, Window.Resizing = true, true
		generation += 1
		local currentGeneration = generation
		owner, kind = input, inputType
		startPosition, startSize, startScale = input.Position, Window.UIElements.Main.Size, scale()
		pending = nil
		FullScreenIcon.Active = true
		Tween(ResizeHandle.ImageLabel, 0.1, { ImageTransparency = 0.35 }):Play()
		renderConnection = RunService.RenderStepped:Connect(function()
			if currentGeneration ~= generation then return end
			if not valid() then finishResize(false); return end
			applyLatest()
		end)
		endConnection = input.Changed:Connect(function()
			if currentGeneration ~= generation then return end
			if input.UserInputState == Enum.UserInputState.End then finishResize(true)
			elseif input.UserInputState == Enum.UserInputState.Cancel then finishResize(false) end
		end)
		inputEndConnection = UserInputService.InputEnded:Connect(function(ended)
			if currentGeneration ~= generation then return end
			if (kind == Enum.UserInputType.Touch and ended == owner)
				or (kind == Enum.UserInputType.MouseButton1 and ended.UserInputType == Enum.UserInputType.MouseButton1) then
				finishResize(true)
			end
		end)
		focusConnection = UserInputService.WindowFocusReleased:Connect(function()
			if currentGeneration == generation then finishResize(false) end
		end)
	end)
	Creator.AddSignal(UserInputService.InputChanged, function(input)
		if not isResizing then return end
		if not valid() then finishResize(false); return end
		if (kind == Enum.UserInputType.Touch and input == owner)
			or (kind == Enum.UserInputType.MouseButton1 and input.UserInputType == Enum.UserInputType.MouseMovement) then
			pending = input.Position
		end
	end)
	-- lesbhub:resize-end

	Creator.AddSignal(ResizeHandle.MouseEnter, function()
		if Config.WindUI.CurrentInput and Config.WindUI.CurrentInput ~= CurResizeInput then
			return
		end
		if not isResizing then
			Tween(ResizeHandle.ImageLabel, 0.1, { ImageTransparency = 0.35 }):Play()
		end
	end)
	Creator.AddSignal(ResizeHandle.MouseLeave, function()
		if Config.WindUI.CurrentInput and Config.WindUI.CurrentInput ~= CurResizeInput then
			return
		end
		if not isResizing then
			Tween(ResizeHandle.ImageLabel, 0.17, { ImageTransparency = 0.8 }):Play()
		end
	end)

	-- / Double click /

	local LastUpTime = 0
	local DoubleClickWindow = 0.4
	local InitialPosition = nil
	local ClickCount = 0

	function onDoubleClick()
		Window:SetToTheCenter()
	end

	Creator.AddSignal(BottomDragFrame.Frame.MouseButton1Up, function()
		local currentTime = tick()
		local currentPosition = Window.Position

		ClickCount = ClickCount + 1

		if ClickCount == 1 then
			LastUpTime = currentTime
			InitialPosition = currentPosition

			task.spawn(function()
				task.wait(DoubleClickWindow)
				if ClickCount == 1 then
					ClickCount = 0
					InitialPosition = nil
				end
			end)
		elseif ClickCount == 2 then
			if currentTime - LastUpTime <= DoubleClickWindow and currentPosition == InitialPosition then
				onDoubleClick()
			end

			ClickCount = 0
			InitialPosition = nil
			LastUpTime = 0
		else
			ClickCount = 1
			LastUpTime = currentTime
			InitialPosition = currentPosition
		end
	end)

	-- / Search Bar /

	if not Window.HideSearchBar then
		local SearchBar = require("../search/Init")
		local IsOpen = false
		local CurrentSearchBar

		-- local SearchButton
		-- SearchButton = Window:CreateTopbarButton("search", function()
		--     if IsOpen then return end

		--     SearchBar.new(Window.TabModule, Window.UIElements.Main, function()
		--         -- OnClose
		--         IsOpen = false
		--         Window.CanResize = true

		--         Tween(FullScreenBlur, 0.1, {ImageTransparency = 1}):Play()
		--         FullScreenBlur.Active = false
		--     end)
		--     Tween(FullScreenBlur, 0.1, {ImageTransparency = .65}):Play()
		--     FullScreenBlur.Active = true

		--     IsOpen = true
		--     Window.CanResize = false
		-- end, 996)

		local SearchLabel = CreateLabel("Search", "search", Window.UIElements.SideBarContainer, true)
		SearchLabel.Size = UDim2.new(1, -Window.UIPadding / 2, 0, 39)
		SearchLabel.Position = UDim2.new(0, Window.UIPadding / 2, 0,--[[Window.UIPadding/2]] 0)

		Creator.AddSignal(SearchLabel.MouseButton1Click, function()
			if IsOpen then
				return
			end

			SearchBar.new(Window.TabModule, Window.UIElements.Main, function()
				-- OnClose
				IsOpen = false
				Window.SearchActive = false
				if Window.Resizable and not Window.IsFullscreen and not Window.Closed then
					Window.CanResize = true
				end

				Tween(FullScreenBlur, 0.1, { ImageTransparency = 1 }):Play()
				FullScreenBlur.Active = false
			end)
			Tween(FullScreenBlur, 0.1, { ImageTransparency = 0.65 }):Play()
			FullScreenBlur.Active = true

			IsOpen = true
			Window.SearchActive = true
			finishResize(false)
			Window.CanResize = false
		end)
	end

	-- / TopBar Edit /

	function Window:DisableTopbarButtons(btns)
		for _, b in next, btns do
			for _, i in next, Window.TopBarButtons do
				if i.Name == b then
					i.Object.Visible = false
				end
			end
		end
	end

	-- local Bindings = {
	--     Title = function(v)
	--         Window:SetTitle(v)
	--     end,
	--     Author = function(v)
	--         Window:SetAuthor(v)
	--     end,
	--     Size = function(v)
	--         Window:SetSize(v)
	--     end,
	--     HidePanelBackground  = function(v)
	--         Window:SetPanelBackground(v)
	--     end
	-- }

	-- setmetatable(Window, {
	--     __newindex = function(t, key, value)
	--         rawset(t, key, value)

	--         local bind = bindings[key]
	--         if bind then
	--             bind(value)
	--         end
	--     end
	-- })

	return Window
end
