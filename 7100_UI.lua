--!nocheck
--[[
	6L4M HUB  -  UI Library  v1.2.0
	Full guide: 6L4M_HUB_DOCS.md

	Put it in a LocalScript (StarterPlayerScripts). RightShift toggles the menu.

	LAYOUT
	  Header   wordmark or logo, search, settings, minimize, close (drag to move)
	  Sidebar  uppercase tabs with a sliding highlight ("Bar" or "Outline" style), footer
	  Content  two scrolling columns, letter-spaced section titles (click to fold), cards

	API
	  Library:SetAccent(Color3)                  -- optional, before CreateWindow
	  Library:KeySystem({ Title, Note, Link, Validate, Remember })
	  local Window = Library:CreateWindow({ Title, Logo, TabStyle, Footer, Intro })
	  local Tab    = Window:AddTab("Shooting")
	  local Sec    = Tab:AddSection("Auto Time", "Left", { Subtitle = "..." })
	  Window:AddSettingsTab()                    -- ready-made Configuration + Interface tab

	  Sec:AddToggle      { Name, Default, Callback, Flag, Tooltip, Locked, LockReason }
	      :AddKeybind    { Default = Enum.KeyCode.E, Mode = "Toggle" | "Hold" | "Always", Flag }
	      :AddColorPicker{ Default = Color3, Callback, Flag }
	  Sec:AddSlider      { Name, Min, Max, Default, Increment, Suffix, Callback, Flag, Dim }
	  Sec:AddDropdown    { Name, Options, Default, Multi, Callback, Flag, Dim }
	  Sec:AddButton      { Name, Callback, Tooltip }
	  Sec:AddButtons     { { Name, Callback }, { Name, Callback } }     -- side by side
	  Sec:AddTextbox     { Name, Default, Placeholder, Callback, Flag }
	  Sec:AddKeybind     { Name, Default, Callback, Changed, Flag, Dim }
	  Sec:AddColorPicker { Name, Default, Callback, Flag }
	  Sec:AddLabel       ("text")  or  { Text, Small, Centered }
	  Sec:AddHeader      ("Pass Type")             -- small spaced title inside a card
	  Sec:AddOptions     ("Options")  -> group with the same Add* methods
	  Sec:AddConfigManager()                       -- save / load / delete / auto-load block
	  Sec:SetCollapsed(true)                       -- fold a section from code

	  Every element: :Set(v) :Get() :SetVisible(bool) :SetLocked(bool, reason)
	  Library:Notify({ Title, Content, Duration, Type = "Success" | "Error" })
	  Library:SaveConfig(name) / LoadConfig / DeleteConfig / ListConfigs / SetAutoload
	  Library.Flags[flag] holds every flagged value.
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local GuiService = game:GetService("GuiService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

--------------------------------------------------------------------------------
-- Library
--------------------------------------------------------------------------------

local Library = {
	Name = "6L4M HUB",
	Version = "1.2.0",
	Flags = {},
	Options = {},
	ToggleKey = Enum.KeyCode.RightShift,
	Visible = true,
	Unloaded = false,
	ConfigFolder = "6L4M_HUB",
	CustomCursor = UserInputService.MouseEnabled,
	BackgroundBlur = true,
	ShowTooltips = true,
	_connections = {},
	_elements = {},
	_popup = nil,
	_binding = false,
}

-- re-executing replaces the old copy; window position / size / tab are kept for the session
local Env = (typeof(getgenv) == "function" and getgenv()) or _G
if Env.__6L4M_HUB and Env.__6L4M_HUB.Unload then
	pcall(function()
		Env.__6L4M_HUB:Unload()
	end)
end
Env.__6L4M_HUB = Library
Env.__6L4M_STATE = Env.__6L4M_STATE or {}
Env.__6L4M_CONFIGS = Env.__6L4M_CONFIGS or {}
local State = Env.__6L4M_STATE

--------------------------------------------------------------------------------
-- Device detection
--------------------------------------------------------------------------------

--[[
	Library:GetDevice() -> "Mobile" | "Tablet" | "Console" | "PC"
	  Console : Roblox's TV / console interface
	  Mobile  : touch screen, no keyboard or mouse, short side of the screen under 600px
	  Tablet  : touch screen, no keyboard or mouse, bigger screen
	  PC      : anything with a keyboard or mouse (touch-screen laptops included)
	Library.Device and Library.IsMobile (true for Mobile and Tablet) are set on load.
	If a PC player later taps the screen, mobile support switches on then.
]]
function Library:GetDevice()
	local ok, tenFoot = pcall(function()
		return GuiService:IsTenFootInterface()
	end)
	if ok and tenFoot then
		return "Console"
	end
	if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled and not UserInputService.MouseEnabled then
		local camera = workspace.CurrentCamera
		local viewport = camera and camera.ViewportSize or Vector2.new(0, 0)
		if math.min(viewport.X, viewport.Y) >= 600 then
			return "Tablet"
		end
		return "Mobile"
	end
	return "PC"
end

Library.Device = Library:GetDevice()
Library.IsMobile = Library.Device == "Mobile" or Library.Device == "Tablet"

-- touch screens don't hover, so no custom cursor or hover tooltips there
if Library.IsMobile then
	Library.CustomCursor = false
	Library.ShowTooltips = false
end

--------------------------------------------------------------------------------
-- Style
--------------------------------------------------------------------------------

local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end

local C = {
	Accent = rgb(255, 255, 255), -- change with Library:SetAccent() before CreateWindow

	Header = rgb(13, 13, 13),
	Content = rgb(9, 9, 9),
	ContentT = 0.26, -- the blurred game shows through, like OT
	WindowStroke = rgb(40, 40, 40),

	Card = rgb(21, 21, 21),
	CardT = 0.12,
	Element = rgb(29, 29, 29),
	ElementHover = rgb(37, 37, 37),
	Popup = rgb(17, 17, 17),
	Stroke = rgb(54, 54, 54),
	StrokeHover = rgb(88, 88, 88),

	Text = rgb(236, 236, 236),
	Sub = rgb(176, 176, 176),
	Dim = rgb(110, 110, 110),

	SwitchOff = rgb(44, 44, 44),
	SwitchOffHover = rgb(54, 54, 54),
	KnobOff = rgb(82, 82, 82),
	KnobOffHover = rgb(112, 112, 112),
	SwitchOn = rgb(246, 246, 246),
	KnobOn = rgb(14, 14, 14),

	Track = rgb(62, 62, 62),
	TrackHover = rgb(84, 84, 84),
	Fill = rgb(242, 242, 242),
	TabSelected = rgb(26, 26, 26),
	Scroll = rgb(60, 60, 60),
	White = rgb(255, 255, 255),
	Black = rgb(0, 0, 0),
	Success = rgb(74, 222, 128),
	Error = rgb(248, 113, 113),
}
Library.Colors = C

--[[
	Rebrand: Library:SetAccent(Color3.fromRGB(120, 160, 255))
	Call it before CreateWindow. Tints switches, slider fills, the active tab bar,
	open dropdown outlines, check marks, keybind highlights and the timer lines.
]]
function Library:SetAccent(color)
	C.Accent = color
	C.SwitchOn = color
	C.Fill = color
	local _, _, v = color:ToHSV()
	C.KnobOn = v > 0.6 and rgb(14, 14, 14) or rgb(255, 255, 255)
end

--[[
	Full colour themes. Library:SetTheme("Purple") or Library:SetTheme({ Accent = ..., Card = ... })
	Call before CreateWindow.
]]
Library.Themes = {
	Purple = {
		Accent = rgb(132, 10, 255),
		SwitchOn = rgb(132, 10, 255),
		Fill = rgb(132, 10, 255),
		KnobOn = rgb(255, 255, 255),
		Header = rgb(7, 6, 10),
		Content = rgb(5, 4, 8),
		WindowStroke = rgb(38, 30, 54),
		Card = rgb(17, 14, 24),
		Element = rgb(25, 21, 35),
		ElementHover = rgb(34, 28, 48),
		Popup = rgb(13, 11, 19),
		Stroke = rgb(48, 40, 66),
		StrokeHover = rgb(100, 70, 150),
		Sub = rgb(178, 170, 194),
		Dim = rgb(110, 100, 130),
		SwitchOff = rgb(36, 31, 48),
		SwitchOffHover = rgb(46, 40, 62),
		KnobOff = rgb(80, 70, 100),
		KnobOffHover = rgb(110, 96, 140),
		Track = rgb(50, 42, 68),
		TrackHover = rgb(72, 60, 100),
		TabSelected = rgb(30, 19, 50),
		Scroll = rgb(80, 60, 120),
	},
}

function Library:SetTheme(theme)
	local t = type(theme) == "string" and self.Themes[theme] or theme
	for k, v in pairs(t or {}) do
		C[k] = v
	end
end

local GOTHAM = "rbxasset://fonts/families/GothamSSm.json"
local F = {
	Regular = Font.new(GOTHAM, Enum.FontWeight.Regular),
	Medium = Font.new(GOTHAM, Enum.FontWeight.Medium),
	Bold = Font.new(GOTHAM, Enum.FontWeight.Bold),
	Heavy = Font.new(GOTHAM, Enum.FontWeight.Heavy),
	Mono = Font.new("rbxasset://fonts/families/RobotoMono.json", Enum.FontWeight.Regular),
}

local HEADER_H = 56
local SIDEBAR_W = 160
local QUINT = Enum.EasingStyle.Quint

--------------------------------------------------------------------------------
-- Helpers
--------------------------------------------------------------------------------

local function on(signal, fn)
	-- Touch screens fire MouseEnter on tap but often never fire MouseLeave, which leaves
	-- hover highlights stuck on. On phones / tablets hover effects are simply skipped.
	if Library.IsMobile and tostring(signal) == "Signal MouseEnter" then
		return { Disconnect = function() end }
	end
	local c = signal:Connect(fn)
	table.insert(Library._connections, c)
	return c
end

local function fire(cb, ...)
	if typeof(cb) == "function" then
		task.spawn(cb, ...)
	end
end

local function tween(obj, props, t, style, direction)
	local tw = TweenService:Create(
		obj,
		TweenInfo.new(t or 0.2, style or Enum.EasingStyle.Quad, direction or Enum.EasingDirection.Out),
		props
	)
	tw:Play()
	return tw
end

local function new(class, props, children)
	local inst = Instance.new(class)
	local parent
	for k, v in pairs(props or {}) do
		if k == "Parent" then
			parent = v
		else
			inst[k] = v
		end
	end
	for _, child in ipairs(children or {}) do
		child.Parent = inst
	end
	if parent then
		inst.Parent = parent
	end
	return inst
end

local function corner(r)
	return new("UICorner", { CornerRadius = r == "full" and UDim.new(1, 0) or UDim.new(0, r or 6) })
end

local function stroke(color, thickness, transparency)
	return new("UIStroke", {
		Color = color or C.Stroke,
		Thickness = thickness or 1,
		Transparency = transparency or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})
end

local function pad(t, b, l, r)
	return new("UIPadding", {
		PaddingTop = UDim.new(0, t or 0),
		PaddingBottom = UDim.new(0, b or 0),
		PaddingLeft = UDim.new(0, l or 0),
		PaddingRight = UDim.new(0, r or 0),
	})
end

local function list(spacing, horizontal, hAlign)
	local l = new("UIListLayout", {
		Padding = UDim.new(0, spacing or 0),
		SortOrder = Enum.SortOrder.LayoutOrder,
		FillDirection = horizontal and Enum.FillDirection.Horizontal or Enum.FillDirection.Vertical,
	})
	if horizontal then
		l.VerticalAlignment = Enum.VerticalAlignment.Center
	end
	if hAlign then
		l.HorizontalAlignment = hAlign
	end
	return l
end

local function label(props)
	props.BackgroundTransparency = 1
	props.BorderSizePixel = 0
	props.FontFace = props.FontFace or F.Medium
	props.TextColor3 = props.TextColor3 or C.Text
	props.TextSize = props.TextSize or 13
	props.TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Left
	return new("TextLabel", props)
end

-- "STATUS" -> "S T A T U S"
local function spaced(s)
	return (tostring(s):upper():gsub(".", "%0 "):gsub("%s+$", ""))
end

local function isPress(i)
	return i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch
end

local function isMove(i)
	return i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch
end

local function chevron(parent, color)
	local holder = new("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.fromOffset(12, 12),
		BackgroundTransparency = 1,
		Parent = parent,
	})
	for _, d in ipairs({ { -2.4, 45 }, { 2.4, -45 } }) do
		new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, d[1], 0.5, 0),
			Size = UDim2.fromOffset(8, 2),
			Rotation = d[2],
			BackgroundColor3 = color or C.Text,
			BorderSizePixel = 0,
			Parent = holder,
		}, { corner("full") })
	end
	return holder
end

-- small solid "v" built from stacked bars (clipping breaks on rotated frames, bars don't)
local function triangle(parent)
	local holder = new("Frame", {
		Size = UDim2.fromOffset(8, 5),
		BackgroundTransparency = 1,
		Parent = parent,
	})
	for i = 0, 4 do
		new("Frame", {
			Name = "Bar",
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.fromOffset(4, i),
			Size = UDim2.fromOffset(8 - i * 1.6, 1.15),
			BackgroundColor3 = C.Text,
			BorderSizePixel = 0,
			Parent = holder,
		})
	end
	return holder
end

local function fadeTriangle(tri, transparency, t)
	for _, bar in ipairs(tri:GetChildren()) do
		tween(bar, { BackgroundTransparency = transparency }, t or 0.2)
	end
end

-- two-bar check mark, returns the bars so they can be faded
local function checkmark(parent, color)
	local holder = new("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -9, 0.5, 0),
		Size = UDim2.fromOffset(10, 10),
		BackgroundTransparency = 1,
		ZIndex = 3,
		Parent = parent,
	})
	local function bar(x, y, w, r)
		return new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromOffset(x, y),
			Size = UDim2.fromOffset(w, 2),
			Rotation = r,
			BackgroundColor3 = color or C.Accent,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ZIndex = 3,
			Parent = holder,
		}, { corner("full") })
	end
	return { bar(2.6, 6, 5, 45), bar(6.4, 4.6, 9, -50) }
end

local KEY_NAMES = {
	LeftShift = "LSHIFT", RightShift = "RIGHTSHIFT", LeftControl = "LCTRL", RightControl = "RCTRL",
	LeftAlt = "LALT", RightAlt = "RALT", Return = "ENTER", MouseButton2 = "MB2", MouseButton3 = "MB3",
	One = "1", Two = "2", Three = "3", Four = "4", Five = "5", Six = "6", Seven = "7", Eight = "8", Nine = "9", Zero = "0",
	Backquote = "`", Minus = "-", Equals = "=", LeftBracket = "[", RightBracket = "]", Semicolon = ";",
	Quote = "'", Comma = ",", Period = ".", Slash = "/", BackSlash = "\\", CapsLock = "CAPS",
}

local function keyName(k)
	if not k then
		return "NONE"
	end
	return KEY_NAMES[k.Name] or k.Name:upper()
end

local function parseKey(v)
	if typeof(v) == "EnumItem" then
		return v
	end
	if type(v) ~= "string" then
		return nil
	end
	local ok, k = pcall(function()
		return Enum.KeyCode[v]
	end)
	if ok and k then
		return k
	end
	ok, k = pcall(function()
		return Enum.UserInputType[v]
	end)
	return ok and k or nil
end

local function keyMatches(input, key)
	if not key then
		return false
	end
	if key.EnumType == Enum.KeyCode then
		return input.KeyCode == key
	end
	return input.UserInputType == key
end

--------------------------------------------------------------------------------
-- ScreenGui + layers
--------------------------------------------------------------------------------

local function guiParent()
	local ok, hui = pcall(function()
		return gethui and gethui()
	end)
	if ok and hui then
		return hui
	end
	if pcall(function()
		local f = Instance.new("Folder")
		f.Parent = CoreGui
		f:Destroy()
	end) then
		return CoreGui
	end
	return LocalPlayer:WaitForChild("PlayerGui")
end

local GuiParent = guiParent()
do
	local old = GuiParent:FindFirstChild("6L4M_HUB")
	if old then
		old:Destroy()
	end
end

local ScreenGui = new("ScreenGui", {
	Name = "6L4M_HUB",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	DisplayOrder = 999,
	Parent = GuiParent,
})

-- Root sits at the true top-left; AbsolutePosition - Root.AbsolutePosition = offsets for this gui
local Root = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = ScreenGui })
local function toGui(v)
	return v - Root.AbsolutePosition
end

local function layer(name, z)
	return new("Frame", { Name = name, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = z, Parent = ScreenGui })
end

local WindowLayer = layer("Windows", 1)
local HudLayer = layer("Hud", 5)
local Overlay = layer("Overlay", 50)
local NotifyLayer = layer("Notifications", 60)
local TipLayer = layer("Tooltip", 80)
local IntroLayer = layer("Intro", 200)
Overlay.Visible = false

local Blocker = new("TextButton", {
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	Text = "",
	AutoButtonColor = false,
	Parent = Overlay,
})

--------------------------------------------------------------------------------
-- Popups (dropdowns, colour pickers, menus)
--------------------------------------------------------------------------------

function Library:_OpenPopup(p)
	if self._popup and self._popup ~= p then
		local old = self._popup
		self._popup = nil
		old:Close()
	end
	self._popup = p
	Overlay.Visible = true
end

function Library:_PopupClosed(p)
	if self._popup == p then
		self._popup = nil
		Overlay.Visible = false
	end
end

function Library:ClosePopups()
	local p = self._popup
	self._popup = nil
	if p then
		p:Close()
	end
	Overlay.Visible = false
end

on(Blocker.MouseButton1Click, function()
	Library:ClosePopups()
end)
on(Blocker.MouseButton2Click, function()
	Library:ClosePopups()
end)

-- keeps a popup attached to its anchor while columns scroll or the window moves
local function follower(anchor, popup, height, alignRight, onLost)
	local scroller = anchor:FindFirstAncestorWhichIsA("ScrollingFrame")
	return function()
		if not anchor:IsDescendantOf(ScreenGui) or anchor.AbsoluteSize.X <= 0 or not Library.Visible then
			onLost()
			return
		end
		local ap, as = anchor.AbsolutePosition, anchor.AbsoluteSize
		if scroller then
			local top = scroller.AbsolutePosition.Y
			if ap.Y + as.Y < top or ap.Y > top + scroller.AbsoluteSize.Y then
				onLost()
				return
			end
		end
		local g = toGui(ap)
		local w = popup.AbsoluteSize.X
		local x = alignRight and (g.X + as.X - w) or g.X
		x = math.clamp(x, 6, math.max(6, Root.AbsoluteSize.X - w - 6))
		local y = g.Y + as.Y + 6
		if y + height > Root.AbsoluteSize.Y - 6 then
			y = g.Y - height - 6
		end
		popup.Position = UDim2.fromOffset(x, y)
	end
end

-- unfold / fold animations shared by every popup
local function popIn(frame, w, h)
	frame.Size = UDim2.fromOffset(w, 0)
	frame.BackgroundTransparency = 0.4
	tween(frame, { Size = UDim2.fromOffset(w, h), BackgroundTransparency = 0 }, 0.26, QUINT)
end

local function popOut(frame)
	for _, d in ipairs(frame:GetDescendants()) do
		if d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox") then
			tween(d, { TextTransparency = 1 }, 0.1)
		elseif d:IsA("UIStroke") then
			tween(d, { Transparency = 1 }, 0.16)
		end
	end
	tween(frame, { Size = UDim2.fromOffset(frame.AbsoluteSize.X, 0), BackgroundTransparency = 1 }, 0.18, QUINT)
	task.delay(0.2, function()
		frame:Destroy()
	end)
end

-- small option menu (used for keybind modes)
local function openMenu(anchor, items, current, onPick)
	local menu = { closed = false }
	local itemH = 26
	local h = #items * itemH + 8
	local frame = new("Frame", {
		Size = UDim2.fromOffset(110, h),
		BackgroundColor3 = C.Popup,
		ClipsDescendants = true,
		Active = true,
		ZIndex = 2,
		Parent = Overlay,
	}, { corner(6), stroke(C.Stroke), pad(4, 4, 4, 4), list(0) })

	local conn
	function menu:Close()
		if self.closed then
			return
		end
		self.closed = true
		if conn then
			conn:Disconnect()
		end
		popOut(frame)
		Library:_PopupClosed(menu)
	end

	for i, item in ipairs(items) do
		local b = new("TextButton", {
			Size = UDim2.new(1, 0, 0, itemH),
			BackgroundColor3 = C.ElementHover,
			BackgroundTransparency = 1,
			Text = "",
			AutoButtonColor = false,
			LayoutOrder = i,
			ZIndex = 3,
			Parent = frame,
		}, { corner(4) })
		label({
			Position = UDim2.fromOffset(8, 0),
			Size = UDim2.new(1, -16, 1, 0),
			Text = item,
			TextSize = 12,
			TextColor3 = item == current and C.White or C.Sub,
			ZIndex = 3,
			Parent = b,
		})
		b.MouseEnter:Connect(function()
			tween(b, { BackgroundTransparency = 0 }, 0.12)
		end)
		b.MouseLeave:Connect(function()
			tween(b, { BackgroundTransparency = 1 }, 0.15)
		end)
		b.MouseButton1Click:Connect(function()
			Library:ClosePopups()
			fire(onPick, item)
		end)
	end

	Library:_OpenPopup(menu)
	local follow = follower(anchor, frame, h, true, function()
		Library:ClosePopups()
	end)
	follow()
	if not menu.closed then
		conn = RunService.RenderStepped:Connect(follow)
		popIn(frame, 110, h)
	end
end

--------------------------------------------------------------------------------
-- Tooltip (fades in after a short hover, follows the cursor)
--------------------------------------------------------------------------------

local Tip = new("Frame", {
	Size = UDim2.fromOffset(0, 24),
	AutomaticSize = Enum.AutomaticSize.X,
	BackgroundColor3 = C.Popup,
	BackgroundTransparency = 1,
	Visible = false,
	Parent = TipLayer,
}, { corner(5), pad(0, 0, 9, 9) })
local TipStroke = stroke(C.Stroke, 1, 1)
TipStroke.Parent = Tip
local TipLabel = label({
	Size = UDim2.fromOffset(0, 24),
	AutomaticSize = Enum.AutomaticSize.X,
	TextSize = 11,
	TextColor3 = C.Sub,
	TextTransparency = 1,
	Parent = Tip,
})

local tipOwner, tipToken = nil, nil

local function hideTip()
	tipOwner, tipToken = nil, nil
	tween(Tip, { BackgroundTransparency = 1 }, 0.12)
	tween(TipStroke, { Transparency = 1 }, 0.12)
	tween(TipLabel, { TextTransparency = 1 }, 0.12).Completed:Connect(function()
		if not tipOwner then
			Tip.Visible = false
		end
	end)
end

local function setTooltip(gui, text)
	if not text or text == "" then
		return
	end
	on(gui.MouseEnter, function()
		local token = {}
		tipOwner, tipToken = gui, token
		task.delay(0.35, function()
			if tipToken ~= token or not Library.ShowTooltips or not Library.Visible then
				return
			end
			TipLabel.Text = text
			Tip.Visible = true
			tween(Tip, { BackgroundTransparency = 0 }, 0.18)
			tween(TipStroke, { Transparency = 0 }, 0.18)
			tween(TipLabel, { TextTransparency = 0 }, 0.18)
		end)
	end)
	on(gui.MouseLeave, function()
		if tipOwner == gui then
			hideTip()
		end
	end)
end

on(RunService.RenderStepped, function()
	if Tip.Visible then
		if tipOwner and not tipOwner:IsDescendantOf(ScreenGui) then
			hideTip()
			return
		end
		local m = UserInputService:GetMouseLocation()
		local x = math.min(m.X + 16, Root.AbsoluteSize.X - Tip.AbsoluteSize.X - 6)
		Tip.Position = UDim2.fromOffset(x, m.Y + 18)
	end
end)

--------------------------------------------------------------------------------
-- Shared builders: keybind tag + colour swatch
--------------------------------------------------------------------------------

--[[
	Keybind tag (the little mono "MB2" / "RIGHTSHIFT" box).
	hooks = { Modes = { ... } or nil, OnPress(), OnState(bool) }
]]
local function keybindTag(parent, opts, hooks)
	local key = parseKey(opts.Default)
	local mode = opts.Mode or (hooks.Modes and hooks.Modes[1]) or "Press"
	local listening = false
	local state = mode == "Always"

	local s = stroke(C.Stroke)
	local tag = new("TextButton", {
		Name = "Keybind",
		Size = UDim2.fromOffset(0, 20),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = rgb(24, 24, 24),
		Text = "",
		FontFace = F.Mono,
		TextSize = 10,
		TextColor3 = C.Sub,
		AutoButtonColor = false,
		Visible = not Library.IsMobile, -- no keyboard on phones, so keybind tags are hidden
		Parent = parent,
	}, { corner(4), s, pad(0, 0, 7, 7) })

	local api = { Type = "Keybind", Tag = tag }

	local function render()
		tag.Text = listening and "..." or keyName(key)
		tween(s, { Color = listening and C.Accent or C.Stroke }, 0.15)
		tween(tag, { TextColor3 = listening and C.White or C.Sub }, 0.15)
	end

	function api:SetKey(k, silent)
		key = parseKey(k)
		if opts.Flag then
			Library.Flags[opts.Flag] = key
		end
		render()
		if not silent then
			fire(opts.Changed, key)
		end
	end
	api.Set = api.SetKey

	function api:Get()
		return key
	end
	api.GetKey = api.Get

	function api:SetMode(m)
		mode = m
		if m == "Always" then
			state = true
			fire(hooks.OnState, true)
		elseif m == "Hold" and state then
			state = false
			fire(hooks.OnState, false)
		end
	end

	function api:GetMode()
		return mode
	end

	function api:Serialize()
		return { Key = key and key.Name or nil, Mode = mode }
	end

	function api:Deserialize(v)
		if type(v) == "table" then
			api:SetKey(v.Key, true)
			if v.Mode then
				api:SetMode(v.Mode)
			end
		else
			api:SetKey(v, true)
		end
	end

	on(tag.MouseEnter, function()
		tween(tag, { BackgroundColor3 = C.ElementHover }, 0.15)
	end)
	on(tag.MouseLeave, function()
		tween(tag, { BackgroundColor3 = rgb(24, 24, 24) }, 0.2)
	end)
	on(tag.MouseButton1Click, function()
		listening = true
		Library._binding = true
		render()
	end)
	if hooks.Modes then
		on(tag.MouseButton2Click, function()
			openMenu(tag, hooks.Modes, mode, function(m)
				api:SetMode(m)
			end)
		end)
		setTooltip(tag, "Click to bind, right-click for mode")
	end

	on(UserInputService.InputBegan, function(input, gp)
		if listening then
			local t = input.UserInputType
			if t == Enum.UserInputType.MouseButton1 then
				listening = false
				task.defer(function()
					Library._binding = false
				end)
				render()
				return
			end
			local k
			if t == Enum.UserInputType.Keyboard then
				k = input.KeyCode
			elseif t == Enum.UserInputType.MouseButton2 or t == Enum.UserInputType.MouseButton3 then
				k = t
			else
				return
			end
			listening = false
			task.defer(function()
				Library._binding = false
			end)
			if k == Enum.KeyCode.Escape or k == Enum.KeyCode.Backspace then
				k = nil
			end
			api:SetKey(k)
			return
		end
		if not key or gp or Library._binding or Library.Unloaded then
			return
		end
		if keyMatches(input, key) then
			if mode == "Press" then
				fire(hooks.OnPress)
			elseif mode == "Toggle" then
				state = not state
				fire(hooks.OnState, state)
			elseif mode == "Hold" then
				state = true
				fire(hooks.OnState, true)
			end
		end
	end)
	on(UserInputService.InputEnded, function(input)
		if mode == "Hold" and state and keyMatches(input, key) then
			state = false
			fire(hooks.OnState, false)
		end
	end)

	if opts.Flag then
		Library.Flags[opts.Flag] = key
		Library.Options[opts.Flag] = api
	end
	render()
	return api
end

local HUE = (function()
	local keys = {}
	for i = 0, 6 do
		table.insert(keys, ColorSequenceKeypoint.new(i / 6, Color3.fromHSV((i / 6) % 1, 1, 1)))
	end
	return ColorSequence.new(keys)
end)()

-- colour swatch + picker popup (SV square, hue bar, hex input)
local function colorSwatch(parent, opts)
	local color = opts.Default or C.White
	local h, s, v = color:ToHSV()

	local swStroke = stroke(C.Stroke)
	-- small soft swatch: dark frame with the colour inset inside it
	local swatch = new("TextButton", {
		Name = "Swatch",
		Size = UDim2.fromOffset(16, 16),
		BackgroundColor3 = rgb(24, 24, 24),
		Text = "",
		AutoButtonColor = false,
		Parent = parent,
	}, { corner(5), swStroke })
	local swatchFill = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(1, -6, 1, -6),
		BackgroundColor3 = color,
		BorderSizePixel = 0,
		Parent = swatch,
	}, { corner(3) })

	local picker = { Type = "ColorPicker", Swatch = swatch, closed = true }
	local frame, conn, els
	local dragSV, dragHue = false, false

	local function apply(fireCb)
		color = Color3.fromHSV(h, s, v)
		swatchFill.BackgroundColor3 = color
		if els then
			els.sv.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
			els.svCursor.Position = UDim2.fromScale(s, 1 - v)
			els.hueCursor.Position = UDim2.fromScale(h, 0.5)
			els.preview.BackgroundColor3 = color
			if not els.hex:IsFocused() then
				els.hex.Text = "#" .. color:ToHex():upper()
			end
		end
		if opts.Flag then
			Library.Flags[opts.Flag] = color
		end
		if fireCb then
			fire(opts.Callback, color)
		end
	end

	function picker:Close()
		if self.closed then
			return
		end
		self.closed = true
		if conn then
			conn:Disconnect()
			conn = nil
		end
		dragSV, dragHue = false, false
		if frame then
			popOut(frame)
		end
		frame, els = nil, nil
		tween(swStroke, { Color = C.Stroke, Thickness = 1 }, 0.18)
		Library:_PopupClosed(picker)
	end

	function picker:Open()
		if not self.closed then
			return
		end
		self.closed = false
		Library:_OpenPopup(picker)
		tween(swStroke, { Color = C.Accent, Thickness = 1.5 }, 0.18)

		local W, H = 206, 180
		frame = new("Frame", {
			Size = UDim2.fromOffset(W, H),
			BackgroundColor3 = C.Popup,
			ClipsDescendants = true,
			Active = true,
			ZIndex = 2,
			Parent = Overlay,
		}, { corner(8), stroke(C.Stroke) })
		els = {}

		els.sv = new("TextButton", {
			Position = UDim2.fromOffset(10, 10),
			Size = UDim2.fromOffset(186, 112),
			BackgroundColor3 = Color3.fromHSV(h, 1, 1),
			Text = "",
			AutoButtonColor = false,
			ZIndex = 3,
			Parent = frame,
		}, { corner(5) })
		new("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = C.White,
			BorderSizePixel = 0,
			ZIndex = 3,
			Parent = els.sv,
		}, { corner(5), new("UIGradient", { Transparency = NumberSequence.new(0, 1) }) })
		new("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = C.Black,
			BorderSizePixel = 0,
			ZIndex = 3,
			Parent = els.sv,
		}, { corner(5), new("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(1, 0) }) })
		els.svCursor = new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.fromOffset(11, 11),
			BackgroundTransparency = 1,
			ZIndex = 4,
			Parent = els.sv,
		}, { corner("full"), stroke(C.White, 2) })

		els.hue = new("TextButton", {
			Position = UDim2.fromOffset(10, 132),
			Size = UDim2.fromOffset(186, 8),
			BackgroundColor3 = C.White,
			Text = "",
			AutoButtonColor = false,
			ZIndex = 3,
			Parent = frame,
		}, { corner("full"), new("UIGradient", { Color = HUE }) })
		els.hueCursor = new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.fromOffset(12, 12),
			BackgroundColor3 = C.White,
			ZIndex = 4,
			Parent = els.hue,
		}, { corner("full"), stroke(rgb(20, 20, 20), 1) })

		els.preview = new("Frame", {
			Position = UDim2.fromOffset(10, 150),
			Size = UDim2.fromOffset(22, 22),
			BackgroundColor3 = color,
			ZIndex = 3,
			Parent = frame,
		}, { corner(5), stroke(C.Stroke) })
		local hexStroke = stroke(C.Stroke)
		local hexFrame = new("Frame", {
			Position = UDim2.fromOffset(40, 150),
			Size = UDim2.fromOffset(156, 22),
			BackgroundColor3 = C.Element,
			ZIndex = 3,
			Parent = frame,
		}, { corner(5), hexStroke })
		els.hex = new("TextBox", {
			Position = UDim2.fromOffset(8, 0),
			Size = UDim2.new(1, -16, 1, 0),
			BackgroundTransparency = 1,
			Text = "",
			FontFace = F.Mono,
			TextSize = 11,
			TextColor3 = C.Text,
			TextXAlignment = Enum.TextXAlignment.Left,
			ClearTextOnFocus = false,
			ZIndex = 3,
			Parent = hexFrame,
		})
		els.hex.Focused:Connect(function()
			tween(hexStroke, { Color = C.StrokeHover }, 0.15)
		end)
		els.hex.FocusLost:Connect(function()
			tween(hexStroke, { Color = C.Stroke }, 0.15)
			local ok, c = pcall(Color3.fromHex, (els.hex.Text:gsub("[#%s]", "")))
			if ok and c then
				h, s, v = c:ToHSV()
			end
			apply(true)
		end)

		els.sv.InputBegan:Connect(function(input)
			if isPress(input) then
				dragSV = true
				local p = input.Position
				s = math.clamp((p.X - els.sv.AbsolutePosition.X) / els.sv.AbsoluteSize.X, 0, 1)
				v = 1 - math.clamp((p.Y - els.sv.AbsolutePosition.Y) / els.sv.AbsoluteSize.Y, 0, 1)
				apply(true)
			end
		end)
		els.hue.InputBegan:Connect(function(input)
			if isPress(input) then
				dragHue = true
				h = math.clamp((input.Position.X - els.hue.AbsolutePosition.X) / els.hue.AbsoluteSize.X, 0, 0.999)
				apply(true)
			end
		end)

		local follow = follower(swatch, frame, H, true, function()
			Library:ClosePopups()
		end)
		follow()
		if self.closed then
			return
		end
		conn = RunService.RenderStepped:Connect(follow)
		apply(false)
		popIn(frame, W, H)
	end

	function picker:Set(c, silent)
		if type(c) == "string" then
			local ok, parsed = pcall(Color3.fromHex, (c:gsub("#", "")))
			c = ok and parsed or nil
		end
		if typeof(c) ~= "Color3" then
			return
		end
		h, s, v = c:ToHSV()
		apply(not silent)
	end

	function picker:Get()
		return color
	end

	function picker:Serialize()
		return color:ToHex()
	end

	function picker:Deserialize(v_)
		picker:Set(v_)
	end

	on(UserInputService.InputChanged, function(input)
		if not els or not isMove(input) then
			return
		end
		if dragSV then
			local p = input.Position
			s = math.clamp((p.X - els.sv.AbsolutePosition.X) / els.sv.AbsoluteSize.X, 0, 1)
			v = 1 - math.clamp((p.Y - els.sv.AbsolutePosition.Y) / els.sv.AbsoluteSize.Y, 0, 1)
			apply(true)
		elseif dragHue then
			h = math.clamp((input.Position.X - els.hue.AbsolutePosition.X) / els.hue.AbsoluteSize.X, 0, 0.999)
			apply(true)
		end
	end)
	on(UserInputService.InputEnded, function(input)
		if isPress(input) then
			dragSV, dragHue = false, false
		end
	end)
	on(swatch.MouseEnter, function()
		if picker.closed then
			tween(swStroke, { Color = C.StrokeHover }, 0.15)
		end
	end)
	on(swatch.MouseLeave, function()
		if picker.closed then
			tween(swStroke, { Color = C.Stroke }, 0.2)
		end
	end)
	on(swatch.MouseButton1Click, function()
		if picker.closed then
			picker:Open()
		else
			Library:ClosePopups()
		end
	end)

	if opts.Flag then
		Library.Flags[opts.Flag] = color
		Library.Options[opts.Flag] = picker
	end
	return picker
end

--------------------------------------------------------------------------------
-- Sections + elements
--------------------------------------------------------------------------------

local Section = {}
Section.__index = Section

function Section:_row(h)
	self._order += 1
	return new("Frame", {
		Name = "Row",
		Size = UDim2.new(1, 0, 0, h),
		BackgroundTransparency = 1,
		LayoutOrder = self._order,
		Parent = self.Container,
	})
end

local function setLocked(row, locked, reason)
	local overlay = row:FindFirstChild("__Lock")
	if locked then
		if not overlay then
			overlay = new("TextButton", {
				Name = "__Lock",
				Position = UDim2.fromOffset(-4, -2),
				Size = UDim2.new(1, 8, 1, 4),
				BackgroundColor3 = C.Card,
				BackgroundTransparency = 0.3,
				Text = "",
				AutoButtonColor = false,
				ZIndex = 20,
				Parent = row,
			}, { corner(6) })
			label({
				Name = "Reason",
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -6, 0.5, 0),
				Size = UDim2.new(0.6, 0, 1, 0),
				FontFace = F.Mono,
				TextSize = 10,
				TextColor3 = C.Sub,
				TextXAlignment = Enum.TextXAlignment.Right,
				ZIndex = 21,
				Parent = overlay,
			})
		end
		overlay.Reason.Text = (reason or "LOCKED"):upper()
	elseif overlay then
		overlay:Destroy()
	end
end

function Section:_register(opts, row, api)
	api.Frame = row
	function api:SetVisible(v)
		row.Visible = v and true or false
	end
	function api:SetLocked(locked, reason)
		setLocked(row, locked, reason)
	end
	if opts.Flag then
		Library.Options[opts.Flag] = api
	end
	if opts.Name and not opts.NoSearch then
		table.insert(Library._elements, { Name = opts.Name, Row = row, Tab = self.Tab, Section = self.Root })
	end
	setTooltip(row, opts.Tooltip)
	if opts.Locked then
		setLocked(row, true, opts.LockReason)
	end
	return api
end

----------------------------------------------------------------- Toggle

function Section:AddToggle(opts)
	opts = opts or {}
	local value = opts.Default == true
	local row = self:_row(26)

	local hit = new("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", Parent = row })
	local switch = new("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 1, 0.5, 0),
		Size = UDim2.fromOffset(28, 16),
		BackgroundColor3 = C.SwitchOff,
		Parent = row,
	}, { corner("full") })
	local knob = new("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 2, 0.5, 0),
		Size = UDim2.fromOffset(12, 12),
		BackgroundColor3 = C.KnobOff,
		Parent = switch,
	}, { corner("full") })
	local nameLabel = label({
		Position = UDim2.fromOffset(36, 0),
		Size = UDim2.new(1, -36, 1, 0),
		Text = opts.Name or "Toggle",
		TextColor3 = C.Sub,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = row,
	})

	-- keybind tags / colour swatches sit on the right of the row
	local addons = new("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.fromOffset(0, 20),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		ZIndex = 2,
		Parent = row,
	}, { list(6, true, Enum.HorizontalAlignment.Right) })
	on(addons:GetPropertyChangedSignal("AbsoluteSize"), function()
		local w = addons.AbsoluteSize.X
		nameLabel.Size = UDim2.new(1, -36 - (w > 0 and w + 8 or 0), 1, 0)
	end)

	local toggle = { Type = "Toggle" }
	local hovering = false

	local function render(instant)
		local t = instant and 0 or 0.3
		tween(switch, { BackgroundColor3 = value and C.SwitchOn or (hovering and C.SwitchOffHover or C.SwitchOff) }, t, QUINT)
		tween(knob, {
			Size = UDim2.fromOffset(12, 12),
			Position = UDim2.new(0, value and 14 or 2, 0.5, 0),
			BackgroundColor3 = value and C.KnobOn or (hovering and C.KnobOffHover or C.KnobOff),
		}, t, QUINT)
		tween(nameLabel, { TextColor3 = (value or hovering) and C.Text or C.Sub }, instant and 0 or 0.2)
	end

	function toggle:Set(v, silent)
		value = v and true or false
		if opts.Flag then
			Library.Flags[opts.Flag] = value
		end
		render()
		if not silent then
			fire(opts.Callback, value)
		end
	end

	function toggle:Get()
		return value
	end

	-- Toggle mode flips the toggle; Hold / Always drive it directly
	function toggle:AddKeybind(kopts)
		kopts = kopts or {}
		local kb
		kb = keybindTag(addons, kopts, {
			Modes = { "Toggle", "Hold", "Always" },
			OnState = function(state)
				if kb and kb:GetMode() == "Toggle" then
					toggle:Set(not value)
				else
					toggle:Set(state)
				end
			end,
		})
		kb.Tag.LayoutOrder = 2
		toggle.Keybind = kb
		return kb
	end

	function toggle:AddColorPicker(copts)
		local cp = colorSwatch(addons, copts or {})
		cp.Swatch.LayoutOrder = 1
		toggle.ColorPicker = cp
		return cp
	end

	on(hit.MouseButton1Down, function()
		tween(knob, {
			Size = UDim2.fromOffset(15, 12),
			Position = UDim2.new(0, value and 11 or 2, 0.5, 0),
		}, 0.15, QUINT)
	end)
	on(hit.MouseButton1Click, function()
		toggle:Set(not value)
	end)
	on(hit.MouseEnter, function()
		hovering = true
		render()
	end)
	on(hit.MouseLeave, function()
		hovering = false
		render()
	end)

	if opts.Flag then
		Library.Flags[opts.Flag] = value
	end
	render(true)
	return self:_register(opts, row, toggle)
end

----------------------------------------------------------------- Slider

function Section:AddSlider(opts)
	opts = opts or {}
	local min, max = opts.Min or 0, opts.Max or 100
	local inc = opts.Increment or 1
	local decimals = (tostring(inc):match("%.(%d+)") or ""):len()
	local value = math.clamp(opts.Default or min, min, max)
	local default = value
	local row = self:_row(46)

	label({
		Position = UDim2.fromOffset(8, 2),
		Size = UDim2.new(1, -80, 0, 18),
		Text = opts.Name or "Slider",
		TextColor3 = opts.Dim and C.Sub or C.Text,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = row,
	})
	local valueLabel = label({
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -8, 0, 2),
		Size = UDim2.fromOffset(70, 18),
		FontFace = F.Mono,
		TextSize = 11,
		TextColor3 = C.Sub,
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = row,
	})
	local track = new("Frame", {
		Position = UDim2.new(0, 8, 0, 29),
		Size = UDim2.new(1, -16, 0, 2),
		BackgroundColor3 = C.Track,
		BorderSizePixel = 0,
		Parent = row,
	}, { corner("full") })
	local fill = new("Frame", {
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = C.Fill,
		BorderSizePixel = 0,
		Parent = track,
	}, { corner("full") })
	local halo = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(13, 13),
		BackgroundColor3 = C.Accent,
		BackgroundTransparency = 1,
		ZIndex = 1,
		Parent = track,
	}, { corner("full") })
	local knob = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(13, 13),
		BackgroundColor3 = C.White,
		ZIndex = 2,
		Parent = track,
	}, { corner("full"), stroke(rgb(20, 20, 20), 1) })
	local knobScale = new("UIScale", { Parent = knob })
	local shown = new("NumberValue", { Value = value })
	local hit = new("TextButton", {
		Position = UDim2.fromOffset(0, 20),
		Size = UDim2.new(1, 0, 0, 22),
		BackgroundTransparency = 1,
		Text = "",
		ZIndex = 3,
		Parent = row,
	})

	local slider = { Type = "Slider" }
	local function fmt(v)
		return string.format("%." .. decimals .. "f", v) .. (opts.Suffix or "")
	end
	on(shown.Changed, function(v)
		valueLabel.Text = fmt(v)
	end)

	local function render(instant)
		local p = (max > min) and (value - min) / (max - min) or 0
		if instant then
			fill.Size = UDim2.fromScale(p, 1)
			knob.Position = UDim2.fromScale(p, 0.5)
			halo.Position = knob.Position
			shown.Value = value
			valueLabel.Text = fmt(value)
			return
		end
		tween(fill, { Size = UDim2.fromScale(p, 1) }, 0.22, QUINT)
		tween(knob, { Position = UDim2.fromScale(p, 0.5) }, 0.22, QUINT)
		tween(halo, { Position = UDim2.fromScale(p, 0.5) }, 0.22, QUINT)
		tween(shown, { Value = value }, 0.25, QUINT)
	end

	function slider:Set(v, silent)
		v = tonumber(v)
		if not v then
			return
		end
		v = min + math.floor((v - min) / inc + 0.5) * inc
		local m = 10 ^ decimals
		v = math.clamp(math.floor(v * m + 0.5) / m, min, max)
		local changed = v ~= value
		value = v
		if opts.Flag then
			Library.Flags[opts.Flag] = value
		end
		render()
		if changed and not silent then
			fire(opts.Callback, value)
		end
	end

	function slider:Get()
		return value
	end

	local dragging, hovering = false, false
	local function state()
		local active = hovering or dragging
		tween(halo, {
			Size = UDim2.fromOffset(active and 26 or 13, active and 26 or 13),
			BackgroundTransparency = active and 0.9 or 1,
		}, 0.25, QUINT)
		tween(knobScale, { Scale = dragging and 1.18 or (hovering and 1.08 or 1) }, 0.25, QUINT)
		tween(track, { BackgroundColor3 = active and C.TrackHover or C.Track }, 0.2)
		tween(valueLabel, { TextColor3 = dragging and C.White or C.Sub }, 0.2)
	end
	local function fromX(x)
		local p = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
		slider:Set(min + (max - min) * p)
	end

	on(hit.MouseEnter, function()
		hovering = true
		state()
	end)
	on(hit.MouseLeave, function()
		hovering = false
		state()
	end)
	on(hit.InputBegan, function(input)
		if isPress(input) then
			dragging = true
			state()
			fromX(input.Position.X)
		end
	end)
	on(UserInputService.InputChanged, function(input)
		if dragging and isMove(input) then
			fromX(input.Position.X)
		end
	end)
	on(UserInputService.InputEnded, function(input)
		if dragging and isPress(input) then
			dragging = false
			state()
		end
	end)
	on(hit.MouseButton2Click, function()
		slider:Set(default)
	end)

	if opts.Flag then
		Library.Flags[opts.Flag] = value
	end
	render(true)
	opts.Tooltip = opts.Tooltip or "Right-click to reset"
	return self:_register(opts, row, slider)
end

----------------------------------------------------------------- Buttons

local function makeButton(parent, opts, size, position)
	local s = stroke(C.Stroke)
	local b = new("TextButton", {
		Position = position or UDim2.new(),
		Size = size or UDim2.fromScale(1, 1),
		BackgroundColor3 = C.Element,
		Text = opts.Name or "Button",
		FontFace = F.Bold,
		TextSize = 13,
		TextColor3 = C.Text,
		AutoButtonColor = false,
		Parent = parent,
	}, { corner(6), s })
	local press = new("UIScale", { Parent = b })
	on(b.MouseEnter, function()
		tween(b, { BackgroundColor3 = C.ElementHover }, 0.2)
		tween(s, { Color = C.StrokeHover }, 0.2)
	end)
	on(b.MouseLeave, function()
		tween(b, { BackgroundColor3 = C.Element }, 0.25)
		tween(s, { Color = C.Stroke }, 0.25)
		tween(press, { Scale = 1 }, 0.25, QUINT)
	end)
	on(b.MouseButton1Down, function()
		tween(press, { Scale = 0.975 }, 0.12, QUINT)
		tween(b, { TextColor3 = C.Sub }, 0.12)
	end)
	on(b.MouseButton1Up, function()
		tween(press, { Scale = 1 }, 0.4, Enum.EasingStyle.Back)
		tween(b, { TextColor3 = C.Text }, 0.2)
	end)
	on(b.MouseButton1Click, function()
		fire(opts.Callback)
	end)
	setTooltip(b, opts.Tooltip)
	return b
end

function Section:AddButton(opts)
	opts = opts or {}
	local row = self:_row(30)
	local b = makeButton(row, opts)
	local api = { Type = "Button", Button = b }
	function api:SetText(t)
		b.Text = t
	end
	return self:_register({ Name = opts.Name, Locked = opts.Locked, LockReason = opts.LockReason }, row, api)
end

-- two (or more) buttons side by side
function Section:AddButtons(buttons)
	local row = self:_row(30)
	local n = #buttons
	local gap = 8
	for i, opts in ipairs(buttons) do
		makeButton(
			row,
			opts,
			UDim2.new(1 / n, -gap * (n - 1) / n, 1, 0),
			UDim2.new((i - 1) / n, (i - 1) * gap / n, 0, 0)
		)
	end
	return self:_register({ Name = buttons[1] and buttons[1].Name }, row, {})
end

----------------------------------------------------------------- Dropdown

function Section:AddDropdown(opts)
	opts = opts or {}
	local options = opts.Options or {}
	local multi = opts.Multi == true
	local value
	if multi then
		value = {}
		for _, v in ipairs(opts.Default or {}) do
			value[v] = true
		end
	else
		value = opts.Default or options[1]
	end

	local row = self:_row(28)
	label({
		Size = UDim2.new(1, -140, 1, 0),
		Text = opts.Name or "Dropdown",
		TextColor3 = opts.Dim and C.Sub or C.Text,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = row,
	})
	local boxStroke = stroke(C.Stroke)
	local box = new("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.fromOffset(opts.Width or 128, 26),
		BackgroundColor3 = C.Element,
		Text = "",
		AutoButtonColor = false,
		Parent = row,
	}, { corner(6), boxStroke })
	local display = label({
		Position = UDim2.fromOffset(9, 0),
		Size = UDim2.new(1, -32, 1, 0),
		TextSize = 12,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = box,
	})
	local chev = chevron(box, C.Text)

	local dropdown = { Type = "Dropdown", closed = true }
	local popup, conn

	local function selected(o)
		return (multi and value[o]) or (not multi and value == o)
	end

	local function get()
		if multi then
			local out = {}
			for _, o in ipairs(options) do
				if value[o] then
					table.insert(out, o)
				end
			end
			return out
		end
		return value
	end

	local function updateDisplay()
		if multi then
			local sel = get()
			if #sel == 0 then
				display.Text = "None"
			elseif #sel >= 3 then
				display.Text = #sel .. " selected"
			else
				display.Text = table.concat(sel, ", ")
			end
		else
			display.Text = value ~= nil and tostring(value) or "None"
		end
		if opts.Flag then
			Library.Flags[opts.Flag] = get()
		end
	end

	function dropdown:Close()
		if self.closed then
			return
		end
		self.closed = true
		if conn then
			conn:Disconnect()
			conn = nil
		end
		if popup then
			popOut(popup)
			popup = nil
		end
		tween(boxStroke, { Color = C.Stroke, Thickness = 1 }, 0.18)
		tween(chev, { Rotation = 0 }, 0.25, QUINT)
		Library:_PopupClosed(dropdown)
	end

	function dropdown:Open()
		if not self.closed then
			return
		end
		self.closed = false
		Library:_OpenPopup(dropdown)
		tween(boxStroke, { Color = C.Accent, Thickness = 1.5 }, 0.18)
		tween(chev, { Rotation = 180 }, 0.25, QUINT)

		local itemH = 28
		local hasSearch = #options > 8
		local h = math.max(1, math.min(#options, 6)) * itemH + 8 + (hasSearch and 32 or 0)
		local w = box.AbsoluteSize.X
		popup = new("ScrollingFrame", {
			Size = UDim2.fromOffset(w, h),
			BackgroundColor3 = C.Popup,
			BorderSizePixel = 0,
			ScrollBarThickness = 2,
			ScrollBarImageColor3 = C.Scroll,
			CanvasSize = UDim2.new(),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			Active = true,
			ZIndex = 2,
			Parent = Overlay,
		}, { corner(6), stroke(C.Stroke), pad(4, 4, 4, 4), list(0) })

		local views = {}

		-- long lists get a search box on top
		if hasSearch then
			local searchHolder = new("Frame", {
				Size = UDim2.new(1, 0, 0, 32),
				BackgroundTransparency = 1,
				LayoutOrder = 0,
				ZIndex = 3,
				Parent = popup,
			})
			local sStroke = stroke(C.Stroke)
			local sFrame = new("Frame", {
				Size = UDim2.new(1, 0, 0, 26),
				BackgroundColor3 = C.Element,
				ZIndex = 3,
				Parent = searchHolder,
			}, { corner(5), sStroke })
			local sBox = new("TextBox", {
				Position = UDim2.fromOffset(8, 0),
				Size = UDim2.new(1, -16, 1, 0),
				BackgroundTransparency = 1,
				Text = "",
				PlaceholderText = "Search",
				PlaceholderColor3 = C.Dim,
				TextColor3 = C.Text,
				FontFace = F.Medium,
				TextSize = 12,
				TextXAlignment = Enum.TextXAlignment.Left,
				ClearTextOnFocus = false,
				ZIndex = 3,
				Parent = sFrame,
			})
			sBox.Focused:Connect(function()
				tween(sStroke, { Color = C.StrokeHover }, 0.15)
			end)
			sBox.FocusLost:Connect(function()
				tween(sStroke, { Color = C.Stroke }, 0.15)
			end)
			sBox:GetPropertyChangedSignal("Text"):Connect(function()
				local q = sBox.Text:lower()
				for o, view in pairs(views) do
					view.Item.Visible = q == "" or tostring(o):lower():find(q, 1, true) ~= nil
				end
			end)
		end
		local function paint(instant)
			for o, view in pairs(views) do
				local on_ = selected(o)
				local t = instant and 0 or 0.15
				tween(view.Text, {
					TextColor3 = on_ and C.White or C.Sub,
					Position = UDim2.fromOffset(on_ and 10 or 8, 0),
				}, t, QUINT)
				for _, bar in ipairs(view.Check) do
					tween(bar, { BackgroundTransparency = on_ and 0 or 1 }, t)
				end
			end
		end

		for i, o in ipairs(options) do
			local item = new("TextButton", {
				Size = UDim2.new(1, 0, 0, itemH),
				BackgroundColor3 = C.ElementHover,
				BackgroundTransparency = 1,
				Text = "",
				AutoButtonColor = false,
				LayoutOrder = i,
				ZIndex = 3,
				Parent = popup,
			}, { corner(4) })
			local txt = label({
				Position = UDim2.fromOffset(8, 0),
				Size = UDim2.new(1, -34, 1, 0),
				Text = tostring(o),
				TextSize = 12,
				TextColor3 = C.Sub,
				TextTransparency = 1,
				TextTruncate = Enum.TextTruncate.AtEnd,
				ZIndex = 3,
				Parent = item,
			})
			views[o] = { Text = txt, Check = checkmark(item), Item = item }
			task.delay(0.015 * i, function()
				if txt.Parent then
					tween(txt, { TextTransparency = 0 }, 0.2)
				end
			end)
			item.MouseEnter:Connect(function()
				tween(item, { BackgroundTransparency = 0 }, 0.12)
				if not selected(o) then
					tween(txt, { TextColor3 = C.Text }, 0.12)
				end
			end)
			item.MouseLeave:Connect(function()
				tween(item, { BackgroundTransparency = 1 }, 0.15)
				if not selected(o) then
					tween(txt, { TextColor3 = C.Sub }, 0.15)
				end
			end)
			item.MouseButton1Click:Connect(function()
				if multi then
					value[o] = (not value[o]) or nil
				else
					value = o
				end
				updateDisplay()
				paint()
				fire(opts.Callback, get())
				if not multi then
					Library:ClosePopups()
				end
			end)
		end
		if #options == 0 then
			label({
				Size = UDim2.new(1, 0, 0, itemH),
				Text = "No options",
				TextSize = 12,
				TextColor3 = C.Dim,
				TextXAlignment = Enum.TextXAlignment.Center,
				ZIndex = 3,
				Parent = popup,
			})
		end
		paint(true)

		local follow = follower(box, popup, h, false, function()
			Library:ClosePopups()
		end)
		follow()
		if self.closed then
			return
		end
		conn = RunService.RenderStepped:Connect(follow)
		popIn(popup, w, h)
	end

	function dropdown:Set(v, silent)
		if multi then
			value = {}
			for _, o in ipairs(type(v) == "table" and v or { v }) do
				value[o] = true
			end
		else
			value = v
		end
		updateDisplay()
		if not silent then
			fire(opts.Callback, get())
		end
	end

	function dropdown:Get()
		return get()
	end

	function dropdown:SetOptions(newOptions, keep)
		options = newOptions or {}
		if not multi and not keep and not table.find(options, value) then
			value = options[1]
		end
		updateDisplay()
	end

	on(box.MouseEnter, function()
		tween(box, { BackgroundColor3 = C.ElementHover }, 0.15)
		if dropdown.closed then
			tween(boxStroke, { Color = C.StrokeHover }, 0.15)
		end
	end)
	on(box.MouseLeave, function()
		tween(box, { BackgroundColor3 = C.Element }, 0.2)
		if dropdown.closed then
			tween(boxStroke, { Color = C.Stroke }, 0.2)
		end
	end)
	on(box.MouseButton1Click, function()
		if dropdown.closed then
			dropdown:Open()
		else
			Library:ClosePopups()
		end
	end)

	updateDisplay()
	return self:_register(opts, row, dropdown)
end

----------------------------------------------------------------- Textbox

function Section:AddTextbox(opts)
	opts = opts or {}
	local row = self:_row(30)
	local s = stroke(C.Stroke)
	local frame = new("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = C.Element,
		Parent = row,
	}, { corner(6), s })
	-- soft glow while typing
	local glow = stroke(C.White, 3, 1)
	glow.Parent = new("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Parent = frame,
	}, { corner(6) })
	local box = new("TextBox", {
		Position = UDim2.fromOffset(9, 0),
		Size = UDim2.new(1, -18, 1, 0),
		BackgroundTransparency = 1,
		Text = opts.Default or "",
		PlaceholderText = opts.Placeholder or "",
		PlaceholderColor3 = C.Dim,
		TextColor3 = C.Text,
		FontFace = F.Medium,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		ClearTextOnFocus = false,
		ClipsDescendants = true,
		Parent = frame,
	})

	local textbox = { Type = "Textbox" }
	function textbox:Set(v)
		box.Text = tostring(v or "")
		if opts.Flag then
			Library.Flags[opts.Flag] = box.Text
		end
	end
	function textbox:Get()
		return box.Text
	end

	on(frame.MouseEnter, function()
		if not box:IsFocused() then
			tween(frame, { BackgroundColor3 = C.ElementHover }, 0.15)
		end
	end)
	on(frame.MouseLeave, function()
		tween(frame, { BackgroundColor3 = C.Element }, 0.2)
	end)
	on(box.Focused, function()
		tween(s, { Color = C.StrokeHover }, 0.2)
		tween(glow, { Transparency = 0.93 }, 0.25)
	end)
	on(box.FocusLost, function(enter)
		tween(s, { Color = C.Stroke }, 0.2)
		tween(glow, { Transparency = 1 }, 0.25)
		if opts.Flag then
			Library.Flags[opts.Flag] = box.Text
		end
		fire(opts.Callback, box.Text, enter)
	end)

	if opts.Flag then
		Library.Flags[opts.Flag] = box.Text
	end
	return self:_register(opts, row, textbox)
end

----------------------------------------------------------------- Keybind row

function Section:AddKeybind(opts)
	opts = opts or {}
	local row = self:_row(26)
	label({
		Size = UDim2.new(1, -110, 1, 0),
		Text = opts.Name or "Keybind",
		TextColor3 = opts.Dim and C.Sub or C.Text,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = row,
	})
	local holder = new("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.fromOffset(0, 22),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		Parent = row,
	}, { list(0, true, Enum.HorizontalAlignment.Right) })
	local kb = keybindTag(holder, opts, {
		OnPress = function()
			fire(opts.Callback)
		end,
	})
	kb.Tag.Size = UDim2.fromOffset(0, 22)
	-- keybind rows can't be used without a keyboard
	if Library.IsMobile and not opts.ShowOnMobile then
		row.Visible = false
	end
	return self:_register(opts, row, kb)
end

----------------------------------------------------------------- Colour picker row

function Section:AddColorPicker(opts)
	opts = opts or {}
	local row = self:_row(26)
	label({
		Size = UDim2.new(1, -40, 1, 0),
		Text = opts.Name or "Colour",
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = row,
	})
	local holder = new("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.fromOffset(16, 16),
		BackgroundTransparency = 1,
		Parent = row,
	})
	local cp = colorSwatch(holder, opts)
	return self:_register(opts, row, cp)
end

----------------------------------------------------------------- Label

function Section:AddLabel(o)
	if type(o) ~= "table" then
		o = { Text = tostring(o) }
	end
	local indent = o.Indent or (o.Centered and 0 or 36)
	self._order += 1
	local row = new("Frame", {
		Name = "Row",
		Size = UDim2.new(1, 0, 0, o.Small and 0 or 26),
		AutomaticSize = o.Small and Enum.AutomaticSize.Y or Enum.AutomaticSize.None,
		BackgroundTransparency = 1,
		LayoutOrder = self._order,
		Parent = self.Container,
	}, { pad(0, 0, indent, o.Centered and 0 or 4) })
	local l = label({
		Size = o.Small and UDim2.new(1, 0, 0, 0) or UDim2.fromScale(1, 1),
		AutomaticSize = o.Small and Enum.AutomaticSize.Y or Enum.AutomaticSize.None,
		Text = o.Text or "",
		TextSize = o.Small and 11 or (o.Centered and 12 or 13),
		TextColor3 = (o.Small or o.Centered) and rgb(200, 200, 200) or C.Text,
		TextWrapped = o.Small == true,
		TextTruncate = (not o.Small) and Enum.TextTruncate.AtEnd or Enum.TextTruncate.None,
		TextXAlignment = o.Centered and Enum.TextXAlignment.Center or Enum.TextXAlignment.Left,
		Parent = row,
	})
	local api = { Type = "Label" }
	function api:Set(t)
		l.Text = tostring(t)
	end
	return self:_register({ Tooltip = o.Tooltip }, row, api)
end

----------------------------------------------------------------- Header (small spaced title inside a card)

function Section:AddHeader(text)
	local row = self:_row(16)
	label({
		Size = UDim2.fromScale(1, 1),
		Text = spaced(text),
		TextSize = 10,
		TextColor3 = C.Dim,
		Parent = row,
	})
	return row
end

----------------------------------------------------------------- Options group

function Section:AddOptions(name)
	self._order += 1
	local holder = new("Frame", {
		Name = "Options",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = self._order,
		Parent = self.Container,
	}, { list(9) })

	local s = stroke(C.Stroke)
	local bar = new("TextButton", {
		Size = UDim2.new(1, 0, 0, 30),
		BackgroundColor3 = C.Element,
		Text = "",
		AutoButtonColor = false,
		LayoutOrder = 1,
		Parent = holder,
	}, { corner(6), s })
	local content = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(0, 16),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		Parent = bar,
	}, { list(7, true) })
	local tri = triangle(content)
	tri.LayoutOrder = 1
	label({
		Size = UDim2.fromOffset(0, 16),
		AutomaticSize = Enum.AutomaticSize.X,
		Text = name or "Options",
		FontFace = F.Bold,
		TextSize = 13,
		LayoutOrder = 2,
		Parent = content,
	})

	local wrapper = new("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		Visible = false,
		LayoutOrder = 2,
		Parent = holder,
	})
	local body = new("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Parent = wrapper,
	}, { list(9), pad(0, 2, 0, 0) })

	local group = setmetatable({ Container = body, _order = 0, Tab = self.Tab, Root = self.Root }, Section)
	local open, animating = false, false

	local function bodyHeight()
		local scale = Library.Window and Library.Window._scale.Scale or 1
		return body.AbsoluteSize.Y / math.max(scale, 0.01)
	end
	on(body:GetPropertyChangedSignal("AbsoluteSize"), function()
		if open and not animating then
			wrapper.Size = UDim2.new(1, 0, 0, bodyHeight())
		end
	end)

	function group:SetOpen(v)
		open = v
		animating = true
		wrapper.Visible = true
		Library:ClosePopups()
		tween(tri, { Rotation = v and 180 or 0 }, 0.3, QUINT)
		tween(wrapper, { Size = UDim2.new(1, 0, 0, v and bodyHeight() or 0) }, 0.32, QUINT).Completed:Connect(function()
			animating = false
			if open then
				wrapper.Size = UDim2.new(1, 0, 0, bodyHeight())
			else
				wrapper.Visible = false
			end
		end)
	end

	on(bar.MouseButton1Click, function()
		group:SetOpen(not open)
	end)
	on(bar.MouseEnter, function()
		tween(bar, { BackgroundColor3 = C.ElementHover }, 0.2)
		tween(s, { Color = C.StrokeHover }, 0.2)
	end)
	on(bar.MouseLeave, function()
		tween(bar, { BackgroundColor3 = C.Element }, 0.25)
		tween(s, { Color = C.Stroke }, 0.25)
	end)
	return group
end

--------------------------------------------------------------------------------
-- Window
--------------------------------------------------------------------------------

local Window = {}
Window.__index = Window
local Tab = {}
Tab.__index = Tab

local blur
local function setBlur(on_)
	if not Library.BackgroundBlur then
		on_ = false
	end
	if on_ and not blur then
		blur = Instance.new("BlurEffect")
		blur.Name = "6L4M_Blur"
		blur.Size = 0
		pcall(function()
			blur.Parent = Lighting
		end)
	end
	if blur then
		tween(blur, { Size = on_ and 10 or 0 }, 0.35, QUINT)
	end
end

local function iconButton(parent, xOffset, draw, tip)
	local b = new("TextButton", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(1, xOffset, 0.5, 0),
		Size = UDim2.fromOffset(26, 26),
		BackgroundColor3 = C.ElementHover,
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		Parent = parent,
	}, { corner(6) })
	local parts = draw(b)
	b.MouseEnter:Connect(function()
		tween(b, { BackgroundTransparency = 0.4 }, 0.2)
		for _, p in ipairs(parts) do
			tween(p[1], { [p[2]] = C.White }, 0.15)
		end
	end)
	b.MouseLeave:Connect(function()
		tween(b, { BackgroundTransparency = 1 }, 0.25)
		for _, p in ipairs(parts) do
			tween(p[1], { [p[2]] = rgb(205, 205, 205) }, 0.2)
		end
	end)
	setTooltip(b, tip)
	return b
end

--[[ Library:CreateWindow { Title, Footer, Size, Intro } ]]
function Library:CreateWindow(o)
	o = o or {}
	if o.Intro then
		self:PlayIntro(o.Title, o.LogoBuilder)
	end

	local size = State.Size or o.Size or Vector2.new(825, 470)
	-- phones: size the window to the screen (below Roblox's top bar) so text stays readable
	if Library.IsMobile and not State.Size then
		local camera = workspace.CurrentCamera
		local viewport = camera and camera.ViewportSize or Vector2.new(844, 390)
		local inset = GuiService:GetGuiInset().Y
		local s = 0.9
		size = Vector2.new(
			math.floor(math.clamp((viewport.X - 24) / s, 560, 825)),
			math.floor(math.clamp((viewport.Y - inset - 16) / s, 300, 470))
		)
	end
	local W = setmetatable({ Tabs = {}, _size = size, _minimized = false, _baseScale = 1 }, Window)

	-- CanvasGroup lets the whole window fade as one piece
	local main = new("CanvasGroup", {
		Name = "Window",
		AnchorPoint = Vector2.new(0.5, 0.5),
		-- on phones, centre in the area below Roblox's top bar
		Position = State.Position
			or (Library.IsMobile and UDim2.new(0.5, 0, 0.5, GuiService:GetGuiInset().Y / 2) or UDim2.fromScale(0.5, 0.5)),
		Size = UDim2.fromOffset(size.X, size.Y),
		BackgroundColor3 = C.Content,
		BackgroundTransparency = C.ContentT,
		GroupTransparency = 1,
		Parent = WindowLayer,
	}, { corner(10) })
	local scale = new("UIScale", { Scale = 0.96, Parent = main })
	W.Main, W._scale = main, scale

	-- solid header + sidebar over the slightly see-through content
	new("Frame", {
		Size = UDim2.new(1, 0, 0, HEADER_H),
		BackgroundColor3 = C.Header,
		BorderSizePixel = 0,
		Parent = main,
	})
	new("Frame", {
		Position = UDim2.fromOffset(0, HEADER_H),
		Size = UDim2.new(0, SIDEBAR_W, 1, -HEADER_H),
		BackgroundColor3 = C.Header,
		BorderSizePixel = 0,
		Parent = main,
	})
	-- border drawn inside the canvas so it isn't clipped
	new("Frame", {
		Position = UDim2.fromOffset(1, 1),
		Size = UDim2.new(1, -2, 1, -2),
		BackgroundTransparency = 1,
		ZIndex = 20,
		Parent = main,
	}, { corner(9), stroke(C.WindowStroke) })

	------------------------------------------------------------- header
	local header = new("Frame", {
		Size = UDim2.new(1, 0, 0, HEADER_H),
		BackgroundTransparency = 1,
		Parent = main,
	})
	-- wordmark: a drawn logo (LogoBuilder), a logo image (Logo = "rbxassetid://..."), or bold text
	if o.LogoBuilder then
		local holder = new("Frame", {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 18, 0.5, 0),
			Size = UDim2.fromOffset(240, 30),
			BackgroundTransparency = 1,
			Parent = header,
		})
		o.LogoBuilder(holder)
	elseif o.Logo then
		new("ImageLabel", {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 18, 0.5, 0),
			Size = UDim2.fromOffset(o.LogoWidth or 140, o.LogoHeight or 26),
			BackgroundTransparency = 1,
			Image = o.Logo,
			ScaleType = Enum.ScaleType.Fit,
			Parent = header,
		})
	else
		label({
			Position = UDim2.fromOffset(18, 0),
			Size = UDim2.new(0, 300, 1, 0),
			Text = o.Title or Library.Name,
			FontFace = F.Heavy,
			TextSize = 24,
			TextColor3 = C.White,
			Parent = header,
		})
	end

	local searchStroke = stroke(C.Stroke)
	local searchFrame = new("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -110, 0.5, 0),
		Size = UDim2.fromOffset(162, 26),
		BackgroundColor3 = rgb(20, 20, 20),
		Parent = header,
	}, { corner("full"), searchStroke })
	local search = new("TextBox", {
		Position = UDim2.fromOffset(12, 0),
		Size = UDim2.new(1, -24, 1, 0),
		BackgroundTransparency = 1,
		Text = "",
		PlaceholderText = "Search",
		PlaceholderColor3 = C.Sub,
		TextColor3 = C.Text,
		FontFace = F.Medium,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		ClearTextOnFocus = false,
		ClipsDescendants = true,
		Parent = searchFrame,
	})
	W._search = search

	local settingsBtn = iconButton(header, -86, function(b)
		local s = stroke(rgb(205, 205, 205), 2)
		new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(11, 11),
			BackgroundTransparency = 1,
			Parent = b,
		}, { corner("full"), s })
		return { { s, "Color" } }
	end, "Settings")
	local minimizeBtn = iconButton(header, -57, function(b)
		local f = new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(13, 2),
			BackgroundColor3 = rgb(205, 205, 205),
			BorderSizePixel = 0,
			Parent = b,
		})
		return { { f, "BackgroundColor3" } }
	end, "Minimize")
	local closeBtn = iconButton(header, -27, function(b)
		local parts = {}
		for _, r in ipairs({ 45, -45 }) do
			local f = new("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromOffset(16, 2),
				Rotation = r,
				BackgroundColor3 = rgb(205, 205, 205),
				BorderSizePixel = 0,
				Parent = b,
			}, { corner("full") })
			table.insert(parts, { f, "BackgroundColor3" })
		end
		return parts
	end, "Hide (" .. keyName(Library.ToggleKey) .. ")")

	------------------------------------------------------------- drag (kept on screen)
	do
		local dragging, startMouse, startCenter
		on(header.InputBegan, function(input)
			if isPress(input) then
				dragging = true
				startMouse = input.Position
				startCenter = toGui(main.AbsolutePosition) + main.AbsoluteSize / 2
			end
		end)
		on(UserInputService.InputChanged, function(input)
			if not dragging or not isMove(input) then
				return
			end
			Library:ClosePopups()
			local d = input.Position - startMouse
			local half = main.AbsoluteSize / 2
			local screen = Root.AbsoluteSize
			local x = math.clamp(startCenter.X + d.X, half.X, math.max(half.X, screen.X - half.X))
			local y = math.clamp(startCenter.Y + d.Y, half.Y, math.max(half.Y, screen.Y - half.Y))
			main.Position = UDim2.fromOffset(math.floor(x + 0.5), math.floor(y + 0.5))
		end)
		on(UserInputService.InputEnded, function(input)
			if dragging and isPress(input) then
				dragging = false
				State.Position = main.Position
			end
		end)
	end

	------------------------------------------------------------- sidebar
	local sidebar = new("Frame", {
		Position = UDim2.fromOffset(0, HEADER_H),
		Size = UDim2.new(0, SIDEBAR_W, 1, -HEADER_H),
		BackgroundTransparency = 1,
		Parent = main,
	})
	local tabList = new("ScrollingFrame", {
		Position = UDim2.fromOffset(0, 14),
		Size = UDim2.new(1, 0, 1, -54),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 0,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Parent = sidebar,
	})
	local tabHolder = new("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		ZIndex = 2,
		Parent = tabList,
	}, { list(2), pad(3, 3, 6, 6) })
	-- one highlight that slides between tabs (the white bar sits at the sidebar's edge)
	local highlight = new("Frame", {
		Position = UDim2.fromOffset(6, 0),
		Size = UDim2.new(1, -12, 0, 34),
		BackgroundColor3 = C.TabSelected,
		Visible = false,
		ZIndex = 1,
		Parent = tabList,
	}, { corner(6) })
	local activeBar = new("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, -4, 0.5, 0),
		Size = UDim2.fromOffset(2, 22),
		BackgroundColor3 = C.Accent,
		BorderSizePixel = 0,
		Parent = highlight,
	}, { corner("full") })
	-- TabStyle = "Bar" (default: dark pill + accent bar) or "Outline" (OT's white rounded outline)
	if o.TabStyle == "Outline" then
		activeBar.Visible = false
		highlight.BackgroundColor3 = C.Header
		stroke(C.Accent, 2).Parent = highlight
	end
	W._tabHolder, W._highlight, W._activeBar = tabHolder, highlight, activeBar

	label({
		Position = UDim2.new(0, 20, 1, -30),
		Size = UDim2.new(1, -36, 0, 16),
		Text = o.Footer or ("v" .. Library.Version .. " · " .. LocalPlayer.Name),
		FontFace = F.Mono,
		TextSize = 10,
		TextColor3 = C.Sub,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = sidebar,
	})

	------------------------------------------------------------- content
	local content = new("Frame", {
		Position = UDim2.fromOffset(SIDEBAR_W, HEADER_H),
		Size = UDim2.new(1, -SIDEBAR_W, 1, -HEADER_H),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		Parent = main,
	})
	W._content = content
	W._noResults = label({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.45),
		Size = UDim2.new(1, -40, 0, 20),
		Text = "No results",
		TextSize = 13,
		TextColor3 = C.Dim,
		TextXAlignment = Enum.TextXAlignment.Center,
		Visible = false,
		ZIndex = 5,
		Parent = content,
	})

	------------------------------------------------------------- resize grip
	local grip = new("TextButton", {
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -4, 1, -4),
		Size = UDim2.fromOffset(14, 14),
		BackgroundTransparency = 1,
		Text = "",
		ZIndex = 21,
		Visible = not Library.IsMobile, -- the window is already sized to the screen on phones
		Parent = main,
	})
	local gripLine = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(13, 2),
		Rotation = -45,
		BackgroundColor3 = rgb(140, 140, 140),
		BorderSizePixel = 0,
		Parent = grip,
	}, { corner("full") })
	grip.MouseEnter:Connect(function()
		tween(gripLine, { BackgroundColor3 = C.White }, 0.15)
	end)
	grip.MouseLeave:Connect(function()
		tween(gripLine, { BackgroundColor3 = rgb(140, 140, 140) }, 0.2)
	end)
	do
		local resizing, start, startSize, startCenter
		on(grip.InputBegan, function(input)
			if isPress(input) and not W._minimized then
				resizing = true
				start = input.Position
				startSize = W._size
				startCenter = toGui(main.AbsolutePosition) + main.AbsoluteSize / 2
			end
		end)
		on(UserInputService.InputChanged, function(input)
			if not resizing or not isMove(input) then
				return
			end
			Library:ClosePopups()
			local sc = scale.Scale
			local d = (input.Position - start) / sc
			local w = math.max(640, startSize.X + d.X)
			local h = math.max(340, startSize.Y + d.Y)
			W._size = Vector2.new(math.floor(w), math.floor(h))
			main.Size = UDim2.fromOffset(W._size.X, W._size.Y)
			-- keep the top-left corner fixed
			main.Position = UDim2.fromOffset(
				startCenter.X + (W._size.X - startSize.X) * sc / 2,
				startCenter.Y + (W._size.Y - startSize.Y) * sc / 2
			)
		end)
		on(UserInputService.InputEnded, function(input)
			if resizing and isPress(input) then
				resizing = false
				State.Size = W._size
				State.Position = main.Position
				W:_Fit()
			end
		end)
	end

	------------------------------------------------------------- buttons
	on(settingsBtn.MouseButton1Click, function()
		for _, t in ipairs(W.Tabs) do
			if t.Name:lower() == "settings" then
				W:SelectTab(t)
			end
		end
	end)
	on(minimizeBtn.MouseButton1Click, function()
		W:SetMinimized(not W._minimized)
	end)
	on(closeBtn.MouseButton1Click, function()
		Library:Toggle(false)
		Library:Notify({ Title = Library.Name, Content = "Hidden. Press " .. keyName(Library.ToggleKey) .. " to open it again.", Duration = 3 })
	end)

	------------------------------------------------------------- search
	on(search:GetPropertyChangedSignal("Text"), function()
		W:_Filter(search.Text)
	end)
	on(search.Focused, function()
		tween(searchStroke, { Color = C.StrokeHover }, 0.2)
	end)
	on(search.FocusLost, function()
		tween(searchStroke, { Color = C.Stroke }, 0.2)
	end)

	------------------------------------------------------------- fit small screens
	on(Root:GetPropertyChangedSignal("AbsoluteSize"), function()
		W:_Fit()
	end)

	Library.Window = W
	W:_Fit()

	-- phones / tablets have no keybinds, so they get a floating open / close button
	if o.MobileButton == true or (o.MobileButton ~= false and Library.IsMobile) then
		Library:CreateMobileButton(o.MobileIcon)
	end
	-- a PC player who starts using touch (touch-screen laptop, emulator) gets it too
	if o.MobileButton ~= false then
		on(UserInputService.LastInputTypeChanged, function(inputType)
			if inputType == Enum.UserInputType.Touch and not Library._mobileButton then
				Library.IsMobile = true
				Library.CustomCursor = false
				Library:CreateMobileButton(o.MobileIcon)
			end
		end)
	end
	task.defer(function()
		W:_SetVisible(Library.Visible)
	end)
	return W
end

-- scales the window down if the screen is too small for it
function Window:_Fit()
	local screen = Root.AbsoluteSize
	if screen.X <= 0 then
		return
	end
	-- phones: tighter margins and keep clear of Roblox's top bar
	local availX, availY = screen.X - 40, screen.Y - 40
	if Library.IsMobile then
		availX = screen.X - 24
		availY = screen.Y - GuiService:GetGuiInset().Y - 16
	end
	self._baseScale = math.clamp(math.min(availX / self._size.X, availY / self._size.Y), 0.5, 1)
	if Library.Visible then
		tween(self._scale, { Scale = self._baseScale }, 0.2, QUINT)
	end
end

function Window:_SetVisible(v)
	local main, sc = self.Main, self._scale
	if v then
		main.Visible = true
		tween(sc, { Scale = self._baseScale }, 0.35, QUINT)
		tween(main, { GroupTransparency = 0 }, 0.28)
	else
		tween(sc, { Scale = self._baseScale * 0.96 }, 0.22, QUINT)
		tween(main, { GroupTransparency = 1 }, 0.2).Completed:Connect(function()
			if not Library.Visible then
				main.Visible = false
			end
		end)
	end
	setBlur(v)
end

function Window:_Filter(query)
	local q = query:lower():gsub("^%s+", ""):gsub("%s+$", "")
	local matched = {}
	local firstTab
	for _, e in ipairs(Library._elements) do
		local match = q == "" or e.Name:lower():find(q, 1, true) ~= nil
		e.Row.Visible = match
		if match then
			matched[e.Section] = true
			if q ~= "" and not firstTab then
				firstTab = e.Tab
			end
		end
	end
	for _, t in ipairs(self.Tabs) do
		for _, s in ipairs(t._sections) do
			s.Visible = q == "" or matched[s] == true
		end
	end
	self._noResults.Visible = q ~= "" and firstTab == nil
	if firstTab then
		self:SelectTab(firstTab)
	elseif q ~= "" and self.Selected then
		self.Selected.Page.Visible = false
	elseif self.Selected then
		self.Selected.Page.Visible = true
	end
end

function Window:SetMinimized(v)
	self._minimized = v
	Library:ClosePopups()
	local sc = self._scale.Scale
	local center = toGui(self.Main.AbsolutePosition) + self.Main.AbsoluteSize / 2
	local h = v and HEADER_H or self._size.Y
	local dy = (h - self.Main.AbsoluteSize.Y / sc) * sc / 2
	tween(self.Main, {
		Size = UDim2.fromOffset(self._size.X, h),
		Position = UDim2.fromOffset(center.X, center.Y + dy),
	}, 0.32, QUINT)
end

function Window:AddTab(name)
	local W = self
	local button = new("TextButton", {
		Name = name,
		Size = UDim2.new(1, 0, 0, 34),
		BackgroundColor3 = C.TabSelected,
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		LayoutOrder = #self.Tabs + 1,
		ZIndex = 2,
		Parent = self._tabHolder,
	}, { corner(6) })
	local text = label({
		Position = UDim2.fromOffset(15, 0),
		Size = UDim2.new(1, -20, 1, 0),
		Text = name:upper(),
		FontFace = F.Bold,
		TextSize = 11,
		TextColor3 = rgb(205, 205, 205),
		ZIndex = 2,
		Parent = button,
	})

	local page = new("Frame", {
		Name = name,
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Visible = false,
		Parent = self._content,
	})
	local function column(right)
		local sf = new("ScrollingFrame", {
			Position = right and UDim2.new(0.5, 11, 0, 0) or UDim2.new(0, 13, 0, 0),
			Size = UDim2.new(0.5, -23, 1, 0),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 2,
			ScrollBarImageColor3 = C.Scroll,
			ScrollBarImageTransparency = 1,
			VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar,
			CanvasSize = UDim2.new(),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ScrollingDirection = Enum.ScrollingDirection.Y,
			Parent = page,
		}, { list(14), pad(16, 14, 0, 8) })
		-- scrollbar only shows while scrolling, then fades away
		local token
		on(sf:GetPropertyChangedSignal("CanvasPosition"), function()
			local t = {}
			token = t
			tween(sf, { ScrollBarImageTransparency = 0 }, 0.15)
			task.delay(0.9, function()
				if token == t then
					tween(sf, { ScrollBarImageTransparency = 1 }, 0.5)
				end
			end)
		end)
		return sf
	end

	local tab = setmetatable({
		Name = name,
		Window = W,
		Button = button,
		Label = text,
		Page = page,
		Left = column(false),
		Right = column(true),
		_sections = {},
	}, Tab)
	table.insert(self.Tabs, tab)

	on(button.MouseButton1Click, function()
		W:SelectTab(tab)
	end)
	on(button.MouseEnter, function()
		if W.Selected ~= tab then
			tween(button, { BackgroundTransparency = 0.6 }, 0.2)
			tween(text, { TextColor3 = C.White }, 0.2)
		end
	end)
	on(button.MouseLeave, function()
		if W.Selected ~= tab then
			tween(button, { BackgroundTransparency = 1 }, 0.25)
			tween(text, { TextColor3 = rgb(205, 205, 205) }, 0.25)
		end
	end)

	if #self.Tabs == 1 or State.Tab == name then
		task.defer(function()
			if not W.Selected or State.Tab == name then
				W:SelectTab(tab)
			end
		end)
	end
	return tab
end

function Window:SelectTab(tab)
	if self.Selected == tab and tab.Page.Visible then
		return
	end
	Library:ClosePopups()
	local first = self.Selected == nil
	self.Selected = tab
	State.Tab = tab.Name
	for _, t in ipairs(self.Tabs) do
		local on_ = t == tab
		t.Page.Visible = on_
		tween(t.Button, { BackgroundTransparency = 1 }, 0.2)
		tween(t.Label, {
			TextColor3 = on_ and C.White or rgb(205, 205, 205),
			Position = UDim2.fromOffset(on_ and 17 or 15, 0),
		}, 0.25, QUINT)
	end

	-- slide the highlight to the selected tab
	local W = self
	task.delay(first and 0.05 or 0, function()
		local y = tab.Button.AbsolutePosition.Y - W._tabHolder.AbsolutePosition.Y
		y = y / math.max(W._scale.Scale, 0.01)
		W._highlight.Visible = true
		if first then
			W._highlight.Position = UDim2.fromOffset(6, y)
		else
			tween(W._highlight, { Position = UDim2.fromOffset(6, y) }, 0.32, QUINT)
			W._activeBar.Size = UDim2.fromOffset(2, 10)
			tween(W._activeBar, { Size = UDim2.fromOffset(2, 22) }, 0.35, QUINT)
		end
	end)

	tab.Page.Position = UDim2.fromOffset(0, 10)
	tween(tab.Page, { Position = UDim2.fromOffset(0, 0) }, 0.35, QUINT)
end

-- Tab:AddSection(name, "Left" | "Right", { Subtitle = "..." })
function Tab:AddSection(name, side, opts)
	local column = side == "Right" and self.Right or self.Left
	local holder = new("Frame", {
		Name = name,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = #self._sections + 1,
		Parent = column,
	}, { list(8) })
	opts = opts or {}

	-- clickable title: folds the card away; a small arrow fades in on hover / when folded
	local titleRow = new("TextButton", {
		Size = UDim2.new(1, 0, 0, 14),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		LayoutOrder = 1,
		Parent = holder,
	}, { pad(0, 0, 4, 0), list(7, true) })
	local title = label({
		Size = UDim2.fromOffset(0, 14),
		AutomaticSize = Enum.AutomaticSize.X,
		Text = spaced(name),
		TextSize = 11,
		TextColor3 = rgb(190, 190, 190),
		LayoutOrder = 1,
		Parent = titleRow,
	})
	local arrow = triangle(titleRow)
	arrow.LayoutOrder = 2
	fadeTriangle(arrow, 1, 0)

	if opts.Subtitle then
		new("Frame", {
			Size = UDim2.new(1, 0, 0, 14),
			BackgroundTransparency = 1,
			LayoutOrder = 2,
			Parent = holder,
		}, {
			label({
				Position = UDim2.fromOffset(4, 0),
				Size = UDim2.new(1, -4, 1, 0),
				Text = spaced(opts.Subtitle),
				TextSize = 11,
				TextColor3 = rgb(190, 190, 190),
			}),
		})
	end

	local wrapper = new("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		LayoutOrder = 3,
		Parent = holder,
	})
	local card = new("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = C.Card,
		BackgroundTransparency = C.CardT,
		Parent = wrapper,
	}, { corner(8), pad(9, 9, 10, 10), list(9) })

	local section = setmetatable({ Container = card, _order = 0, Tab = self, Root = holder }, Section)
	local open, hovering = true, false

	local function paintArrow()
		fadeTriangle(arrow, (hovering or not open) and 0.2 or 1)
		tween(arrow, { Rotation = open and 0 or -90 }, 0.3, QUINT)
		tween(title, { TextColor3 = hovering and C.White or rgb(190, 190, 190) }, 0.2)
	end

	function section:SetCollapsed(collapsed)
		open = not collapsed
		Library:ClosePopups()
		local scale = self.Tab.Window._scale.Scale
		local h = card.AbsoluteSize.Y / math.max(scale, 0.01)
		wrapper.AutomaticSize = Enum.AutomaticSize.None
		if open then
			wrapper.Visible = true
			wrapper.Size = UDim2.new(1, 0, 0, 0)
			tween(wrapper, { Size = UDim2.new(1, 0, 0, h) }, 0.32, QUINT).Completed:Connect(function()
				if open then
					wrapper.AutomaticSize = Enum.AutomaticSize.Y
					wrapper.Size = UDim2.new(1, 0, 0, 0)
				end
			end)
		else
			wrapper.Size = UDim2.new(1, 0, 0, h)
			tween(wrapper, { Size = UDim2.new(1, 0, 0, 0) }, 0.28, QUINT).Completed:Connect(function()
				if not open then
					wrapper.Visible = false
				end
			end)
		end
		paintArrow()
	end

	on(titleRow.MouseButton1Click, function()
		section:SetCollapsed(open)
	end)
	on(titleRow.MouseEnter, function()
		hovering = true
		paintArrow()
	end)
	on(titleRow.MouseLeave, function()
		hovering = false
		paintArrow()
	end)

	table.insert(self._sections, holder)
	return section
end

--[[
	Ready-made pieces so every script doesn't rebuild the same settings.

	Section:AddConfigManager()  -> name box, Save, saved list, Load / Delete, auto-load toggle
	Window:AddSettingsTab()     -> "Settings" tab with Configuration + Interface sections
	                               (returns the tab so you can add your own sections too)
]]
function Section:AddConfigManager()
	local nameBox = self:AddTextbox({ Default = "default", Placeholder = "Config name", NoSearch = true })
	local saved
	local function refresh(select)
		saved:SetOptions(Library:ListConfigs(), true)
		if select then
			saved:Set(select, true)
		end
	end
	self:AddButton({
		Name = "Save current settings",
		Callback = function()
			local n = nameBox:Get()
			if Library:SaveConfig(n) then
				refresh(n)
				Library:Notify({ Title = "Configs", Content = 'Saved "' .. n .. '".', Type = "Success" })
			else
				Library:Notify({ Title = "Configs", Content = "Couldn't save, check the name.", Type = "Error" })
			end
		end,
	})
	local list_ = Library:ListConfigs()
	saved = self:AddDropdown({ Name = "Saved configs", Options = list_, Default = Library:GetAutoload() or list_[1], NoSearch = true })
	self:AddButtons({
		{
			Name = "Load",
			Callback = function()
				local n = saved:Get()
				if n and Library:LoadConfig(n) then
					Library:Notify({ Title = "Configs", Content = 'Loaded "' .. n .. '".', Type = "Success" })
				else
					Library:Notify({ Title = "Configs", Content = "Pick a saved config first.", Type = "Error" })
				end
			end,
		},
		{
			Name = "Delete",
			Callback = function()
				local n = saved:Get()
				if n then
					Library:DeleteConfig(n)
					if Library:GetAutoload() == n then
						Library:SetAutoload(nil)
					end
					refresh(Library:ListConfigs()[1])
					Library:Notify({ Title = "Configs", Content = 'Deleted "' .. n .. '".' })
				end
			end,
		},
	})
	self:AddToggle({
		Name = "Auto-load on launch",
		Default = Library:GetAutoload() ~= nil,
		Tooltip = "Loads the selected config when the script runs",
		NoSearch = true,
		Callback = function(v)
			local n = saved:Get()
			if v and n then
				Library:SetAutoload(n)
				Library:Notify({ Title = "Configs", Content = '"' .. n .. '" will load on launch.' })
			elseif v then
				Library:Notify({ Title = "Configs", Content = "Save a config first.", Type = "Error" })
			else
				Library:SetAutoload(nil)
			end
		end,
	})
	return { NameBox = nameBox, Saved = saved, Refresh = refresh }
end

function Window:AddSettingsTab(name)
	local tab = self:AddTab(name or "Settings")

	local configs = tab:AddSection("Configuration", "Left")
	configs:AddConfigManager()

	local interface = tab:AddSection("Interface", "Right")
	interface:AddKeybind({
		Name = "Open / Close Menu",
		Default = Library.ToggleKey,
		NoSearch = true,
		Changed = function(k)
			Library.ToggleKey = k
		end,
	})
	interface:AddToggle({
		Name = "Custom Cursor",
		Default = Library.CustomCursor,
		Callback = function(v)
			Library.CustomCursor = v
		end,
	})
	interface:AddToggle({
		Name = "Background Blur",
		Default = Library.BackgroundBlur,
		Callback = function(v)
			Library.BackgroundBlur = v
			setBlur(v and Library.Visible)
		end,
	})
	interface:AddToggle({
		Name = "Tooltips",
		Default = Library.ShowTooltips,
		Callback = function(v)
			Library.ShowTooltips = v
		end,
	})
	interface:AddButton({
		Name = "Unload",
		Callback = function()
			Library:Unload()
		end,
	})
	return tab
end

function Tab:Select()
	self.Window:SelectTab(self)
end

--------------------------------------------------------------------------------
-- Notifications
--------------------------------------------------------------------------------

local NotifyHolder = new("Frame", {
	AnchorPoint = Vector2.new(1, 1),
	Position = UDim2.new(1, -16, 1, -16),
	Size = UDim2.new(0, 280, 1, -32),
	BackgroundTransparency = 1,
	Parent = NotifyLayer,
}, {
	new("UIListLayout", {
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
	}),
})
local notifyCount = 0

-- Library:Notify({ Title, Content, Duration, Type }) or Library:Notify(title, content, duration)
function Library:Notify(o, content, duration)
	if type(o) ~= "table" then
		o = { Title = o, Content = content, Duration = duration }
	end
	local dur = o.Duration or 4
	notifyCount += 1

	local slot = new("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = notifyCount,
		Parent = NotifyHolder,
	})
	local card = new("CanvasGroup", {
		Position = UDim2.fromOffset(40, 0),
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = C.Header,
		GroupTransparency = 1,
		Parent = slot,
	}, { corner(8) })
	new("Frame", {
		Position = UDim2.fromOffset(1, 1),
		Size = UDim2.new(1, -2, 1, -2),
		BackgroundTransparency = 1,
		ZIndex = 5,
		Parent = card,
	}, { corner(7), stroke(C.WindowStroke) })
	local body = new("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Parent = card,
	}, { pad(11, 14, 14, 14), list(4) })

	local titleRow = new("Frame", {
		Size = UDim2.new(1, 0, 0, 16),
		BackgroundTransparency = 1,
		LayoutOrder = 1,
		Parent = body,
	}, { list(7, true) })
	if o.Type == "Success" or o.Type == "Error" then
		new("Frame", {
			Size = UDim2.fromOffset(6, 6),
			BackgroundColor3 = o.Type == "Success" and C.Success or C.Error,
			LayoutOrder = 1,
			Parent = titleRow,
		}, { corner("full") })
	end
	label({
		Size = UDim2.fromOffset(0, 16),
		AutomaticSize = Enum.AutomaticSize.X,
		Text = o.Title or Library.Name,
		FontFace = F.Bold,
		LayoutOrder = 2,
		Parent = titleRow,
	})
	if o.Content then
		label({
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			Text = o.Content,
			TextSize = 12,
			TextColor3 = C.Sub,
			TextWrapped = true,
			LayoutOrder = 2,
			Parent = body,
		})
	end
	-- thin timer line along the bottom
	local line = new("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 0, 1, 0),
		Size = UDim2.new(1, 0, 0, 2),
		BackgroundColor3 = C.Accent,
		BackgroundTransparency = 0.6,
		BorderSizePixel = 0,
		Parent = card,
	})
	local dismiss = new("TextButton", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = "",
		ZIndex = 6,
		Parent = card,
	})

	local closed = false
	local function close()
		if closed then
			return
		end
		closed = true
		tween(card, { GroupTransparency = 1, Position = UDim2.fromOffset(40, 0) }, 0.25, QUINT)
		task.delay(0.28, function()
			slot:Destroy()
		end)
	end
	dismiss.MouseButton1Click:Connect(close)

	tween(card, { GroupTransparency = 0, Position = UDim2.fromOffset(0, 0) }, 0.35, QUINT)
	tween(line, { Size = UDim2.new(0, 0, 0, 2) }, dur, Enum.EasingStyle.Linear)
	task.delay(dur, close)
end

--------------------------------------------------------------------------------
-- Intro (short, minimal)
--------------------------------------------------------------------------------

--[[
	PlayIntro(title, logoBuilder)
	Shows the drawn logo (logoBuilder(frame, height)) or the title text, with a thin
	loading line under it. Everything sits in one CanvasGroup so it fades as one piece.
]]
function Library:PlayIntro(title, logoBuilder)
	local LOGO_H = 44
	local backdrop = new("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = C.Black,
		BackgroundTransparency = 1,
		Active = true,
		Parent = IntroLayer,
	})
	local stage = new("CanvasGroup", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 14),
		Size = UDim2.fromOffset(280, 96),
		BackgroundTransparency = 1,
		GroupTransparency = 1,
		Parent = backdrop,
	})
	local stageScale = new("UIScale", { Scale = 0.92, Parent = stage })

	-- logo (or text), centred at the top of the stage
	local logoHolder = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0),
		Size = UDim2.fromOffset(280, LOGO_H),
		BackgroundTransparency = 1,
		Parent = stage,
	})
	if logoBuilder then
		local inner = new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.fromScale(0.5, 0),
			Size = UDim2.fromOffset(0, LOGO_H),
			BackgroundTransparency = 1,
			Parent = logoHolder,
		})
		local drawn = logoBuilder(inner, LOGO_H)
		-- centre whatever was drawn using its real width
		if typeof(drawn) == "Instance" and drawn:IsA("GuiObject") then
			inner.Size = UDim2.fromOffset(drawn.Size.X.Offset, LOGO_H)
		end
	else
		label({
			Size = UDim2.fromScale(1, 1),
			Text = title or self.Name,
			FontFace = F.Heavy,
			TextSize = 32,
			TextColor3 = C.White,
			TextXAlignment = Enum.TextXAlignment.Center,
			Parent = logoHolder,
		})
	end

	-- loading line + small spaced caption
	local track = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, LOGO_H + 22),
		Size = UDim2.fromOffset(150, 2),
		BackgroundColor3 = C.Track,
		BorderSizePixel = 0,
		Parent = stage,
	}, { corner("full") })
	local fill = new("Frame", {
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = C.Accent,
		BorderSizePixel = 0,
		Parent = track,
	}, { corner("full") })
	local caption = label({
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, LOGO_H + 32),
		Size = UDim2.fromOffset(200, 14),
		Text = spaced("Loading"),
		FontFace = F.Medium,
		TextSize = 10,
		TextColor3 = C.Dim,
		TextXAlignment = Enum.TextXAlignment.Center,
		Parent = stage,
	})

	-- in
	setBlur(true)
	tween(backdrop, { BackgroundTransparency = 0.35 }, 0.45)
	tween(stage, { GroupTransparency = 0, Position = UDim2.fromScale(0.5, 0.5) }, 0.6, QUINT)
	tween(stageScale, { Scale = 1 }, 0.7, QUINT)
	task.wait(0.35)
	tween(fill, { Size = UDim2.fromScale(1, 1) }, 1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
	task.wait(1.05)
	caption.Text = spaced("Ready")
	tween(caption, { TextColor3 = C.Sub }, 0.2)
	task.wait(0.3)

	-- out
	tween(stage, { GroupTransparency = 1 }, 0.35)
	tween(stageScale, { Scale = 1.04 }, 0.4, QUINT)
	tween(backdrop, { BackgroundTransparency = 1 }, 0.4)
	task.wait(0.4)
	backdrop:Destroy()
end

--------------------------------------------------------------------------------
-- Configs (files when available, otherwise kept for this session)
--------------------------------------------------------------------------------

local memory = Env.__6L4M_CONFIGS

local function hasFiles()
	return typeof(writefile) == "function" and typeof(readfile) == "function" and typeof(isfile) == "function"
end

local function ensureFolder()
	if typeof(isfolder) == "function" and typeof(makefolder) == "function" and not isfolder(Library.ConfigFolder) then
		makefolder(Library.ConfigFolder)
	end
end

local function cfgPath(name)
	return Library.ConfigFolder .. "/" .. name .. ".json"
end

local function cleanName(name)
	name = tostring(name or ""):gsub("[^%w%-_# ]", "")
	return name ~= "" and name or nil
end

function Library:SaveConfig(name)
	name = cleanName(name)
	if not name then
		return false
	end
	local data = {}
	for flag, opt in pairs(self.Options) do
		local ok, v = pcall(function()
			if opt.Serialize then
				return opt:Serialize()
			end
			local val = opt:Get()
			if typeof(val) == "EnumItem" then
				return val.Name
			end
			return val
		end)
		if ok then
			data[flag] = v
		end
	end
	local json = HttpService:JSONEncode(data)
	if hasFiles() then
		local ok = pcall(function()
			ensureFolder()
			writefile(cfgPath(name), json)
		end)
		return ok
	end
	memory[name] = json
	return true
end

function Library:LoadConfig(name)
	name = cleanName(name)
	if not name then
		return false
	end
	local json
	if hasFiles() then
		pcall(function()
			if isfile(cfgPath(name)) then
				json = readfile(cfgPath(name))
			end
		end)
	else
		json = memory[name]
	end
	if not json then
		return false
	end
	local ok, data = pcall(function()
		return HttpService:JSONDecode(json)
	end)
	if not ok or type(data) ~= "table" then
		return false
	end
	for flag, v in pairs(data) do
		local opt = self.Options[flag]
		if opt then
			pcall(function()
				if opt.Deserialize then
					opt:Deserialize(v)
				else
					opt:Set(v)
				end
			end)
		end
	end
	return true
end

function Library:DeleteConfig(name)
	name = cleanName(name)
	if not name then
		return false
	end
	if hasFiles() then
		return pcall(function()
			if typeof(delfile) == "function" and isfile(cfgPath(name)) then
				delfile(cfgPath(name))
			end
		end)
	end
	memory[name] = nil
	return true
end

function Library:ListConfigs()
	local out = {}
	if hasFiles() and typeof(listfiles) == "function" then
		pcall(function()
			ensureFolder()
			for _, p in ipairs(listfiles(self.ConfigFolder)) do
				local n = p:match("([^/\\]+)%.json$")
				if n then
					table.insert(out, n)
				end
			end
		end)
	else
		for n in pairs(memory) do
			table.insert(out, n)
		end
	end
	table.sort(out)
	return out
end

function Library:SetAutoload(name)
	if hasFiles() then
		pcall(function()
			ensureFolder()
			writefile(self.ConfigFolder .. "/autoload.txt", name or "")
		end)
	else
		memory.__autoload = name
	end
end

function Library:GetAutoload()
	if hasFiles() then
		local ok, n = pcall(function()
			local p = self.ConfigFolder .. "/autoload.txt"
			return isfile(p) and readfile(p) or nil
		end)
		return (ok and n ~= "" and n) or nil
	end
	return memory.__autoload
end

function Library:LoadAutoload()
	local n = self:GetAutoload()
	if n and self:LoadConfig(n) then
		self:Notify({ Title = "Configs", Content = 'Auto-loaded "' .. n .. '".', Type = "Success", Duration = 3 })
	end
end

--------------------------------------------------------------------------------
-- Key system (call before CreateWindow; yields until a valid key is entered)
--------------------------------------------------------------------------------

--[[
	Library:KeySystem({
		Title    = "6L4M HUB",
		Note     = "Get a key from our Discord.",
		Link     = "https://discord.gg/...",          -- copied by "Get Key"
		Validate = function(key) return key == "..." end, -- can yield (e.g. an HTTP check)
		Remember = true,                                -- skip the screen next time if still valid
	})
]]
function Library:KeySystem(o)
	o = o or {}
	local validate = o.Validate or function()
		return true
	end
	local keyFile = self.ConfigFolder .. "/key.txt"

	local function check(key)
		local ok, valid = pcall(validate, key)
		return ok and valid == true
	end

	-- remembered key
	if o.Remember ~= false then
		local saved
		if hasFiles() then
			pcall(function()
				if isfile(keyFile) then
					saved = readfile(keyFile)
				end
			end)
		else
			saved = memory.__key
		end
		if saved and saved ~= "" and check(saved) then
			return true
		end
	end

	local done = false
	setBlur(true)
	local holder = new("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = C.Black,
		BackgroundTransparency = 1,
		Active = true,
		Parent = IntroLayer,
	})
	local card = new("CanvasGroup", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 12),
		Size = UDim2.fromOffset(340, 200),
		BackgroundColor3 = C.Header,
		GroupTransparency = 1,
		Parent = holder,
	}, { corner(10) })
	new("Frame", {
		Position = UDim2.fromOffset(1, 1),
		Size = UDim2.new(1, -2, 1, -2),
		BackgroundTransparency = 1,
		ZIndex = 10,
		Parent = card,
	}, { corner(9), stroke(C.WindowStroke) })

	label({
		Position = UDim2.fromOffset(20, 16),
		Size = UDim2.new(1, -40, 0, 26),
		Text = o.Title or self.Name,
		FontFace = F.Heavy,
		TextSize = 20,
		TextColor3 = C.White,
		Parent = card,
	})
	local note = label({
		Position = UDim2.fromOffset(20, 44),
		Size = UDim2.new(1, -40, 0, 32),
		Text = o.Note or "Enter your key to continue.",
		TextSize = 12,
		TextColor3 = C.Sub,
		TextWrapped = true,
		TextYAlignment = Enum.TextYAlignment.Top,
		Parent = card,
	})

	local boxStroke = stroke(C.Stroke)
	local boxFrame = new("Frame", {
		Position = UDim2.fromOffset(20, 84),
		Size = UDim2.new(1, -40, 0, 32),
		BackgroundColor3 = C.Element,
		Parent = card,
	}, { corner(6), boxStroke })
	local box = new("TextBox", {
		Position = UDim2.fromOffset(10, 0),
		Size = UDim2.new(1, -20, 1, 0),
		BackgroundTransparency = 1,
		Text = "",
		PlaceholderText = "Key",
		PlaceholderColor3 = C.Dim,
		TextColor3 = C.Text,
		FontFace = F.Mono,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		ClearTextOnFocus = false,
		ClipsDescendants = true,
		Parent = boxFrame,
	})
	local status = label({
		Position = UDim2.fromOffset(21, 120),
		Size = UDim2.new(1, -40, 0, 14),
		Text = "",
		TextSize = 11,
		TextColor3 = C.Error,
		TextTransparency = 1,
		Parent = card,
	})
	box.Focused:Connect(function()
		tween(boxStroke, { Color = C.StrokeHover }, 0.15)
	end)
	box.FocusLost:Connect(function()
		tween(boxStroke, { Color = C.Stroke }, 0.15)
	end)

	local buttons = new("Frame", {
		Position = UDim2.fromOffset(20, 146),
		Size = UDim2.new(1, -40, 0, 32),
		BackgroundTransparency = 1,
		Parent = card,
	})
	local getKey = makeButton(buttons, { Name = "Get Key" }, UDim2.new(0.5, -4, 1, 0), UDim2.new())
	local continueBtn = makeButton(buttons, { Name = "Continue" }, UDim2.new(0.5, -4, 1, 0), UDim2.new(0.5, 4, 0, 0))
	continueBtn.BackgroundColor3 = C.Accent
	continueBtn.TextColor3 = C.KnobOn
	continueBtn.MouseEnter:Connect(function()
		tween(continueBtn, { BackgroundColor3 = C.Accent:Lerp(C.Black, 0.12) }, 0.2)
	end)
	continueBtn.MouseLeave:Connect(function()
		tween(continueBtn, { BackgroundColor3 = C.Accent }, 0.2)
	end)
	continueBtn.MouseButton1Up:Connect(function()
		tween(continueBtn, { TextColor3 = C.KnobOn }, 0.2)
	end)

	local function showStatus(text, color)
		status.Text = text
		status.TextColor3 = color or C.Error
		tween(status, { TextTransparency = 0 }, 0.2)
	end

	local function shake()
		local base = UDim2.new(0.5, 0, 0.5, 0)
		for _, x in ipairs({ -8, 7, -5, 3, 0 }) do
			tween(card, { Position = base + UDim2.fromOffset(x, 0) }, 0.05)
			task.wait(0.05)
		end
	end

	getKey.MouseButton1Click:Connect(function()
		if o.Link and typeof(setclipboard) == "function" then
			pcall(setclipboard, o.Link)
			showStatus("Link copied to clipboard.", C.Success)
		elseif o.Link then
			note.Text = o.Link
		end
	end)

	local checking = false
	local function submit()
		if checking then
			return
		end
		local key = box.Text:gsub("%s", "")
		if key == "" then
			showStatus("Enter a key first.")
			task.spawn(shake)
			return
		end
		checking = true
		continueBtn.Text = "Checking..."
		local valid = check(key)
		checking = false
		continueBtn.Text = "Continue"
		if valid then
			if o.Remember ~= false then
				if hasFiles() then
					pcall(function()
						ensureFolder()
						writefile(keyFile, key)
					end)
				else
					memory.__key = key
				end
			end
			showStatus("Key accepted.", C.Success)
			task.wait(0.35)
			done = true
		else
			showStatus("Invalid key.")
			task.spawn(shake)
		end
	end
	continueBtn.MouseButton1Click:Connect(submit)
	box.FocusLost:Connect(function(enter)
		if enter then
			submit()
		end
	end)

	tween(holder, { BackgroundTransparency = 0.5 }, 0.35)
	tween(card, { GroupTransparency = 0, Position = UDim2.fromScale(0.5, 0.5) }, 0.4, QUINT)

	repeat
		task.wait()
	until done or self.Unloaded

	tween(holder, { BackgroundTransparency = 1 }, 0.3)
	tween(card, { GroupTransparency = 1, Position = UDim2.new(0.5, 0, 0.5, -10) }, 0.3, QUINT)
	task.wait(0.3)
	holder:Destroy()
	setBlur(false)
	return done
end

--------------------------------------------------------------------------------
-- Custom cursor (ring trails softly, dot is exact)
--------------------------------------------------------------------------------

local CursorRing = new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Size = UDim2.fromOffset(24, 24),
	BackgroundTransparency = 1,
	Visible = false,
	ZIndex = 1000,
	Parent = ScreenGui,
})
local ringScale = new("UIScale", { Parent = CursorRing })
new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.new(1, 2, 1, 2),
	BackgroundTransparency = 1,
	Parent = CursorRing,
}, { corner("full"), new("UIStroke", { Color = C.Black, Thickness = 1, Transparency = 0.55 }) })
local ringStroke = new("UIStroke", { Color = C.White, Thickness = 1.6 })
new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = CursorRing }, { corner("full"), ringStroke })

local CursorDot = new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Size = UDim2.fromOffset(5, 5),
	BackgroundColor3 = C.White,
	Visible = false,
	ZIndex = 1001,
	Parent = ScreenGui,
}, { corner("full"), new("UIStroke", { Color = C.Black, Thickness = 1, Transparency = 0.5 }) })

-- frees the mouse in shift-lock / first person while the menu is open
local ModalUnlock = new("TextButton", {
	Size = UDim2.fromOffset(0, 0),
	BackgroundTransparency = 1,
	Text = "",
	Modal = true,
	Parent = ScreenGui,
})

-- holder for a custom-drawn cursor (see Library:SetCursor)
local CustomCursorFrame = new("Frame", {
	Size = UDim2.fromOffset(0, 0),
	BackgroundTransparency = 1,
	Visible = false,
	ZIndex = 1002,
	Parent = ScreenGui,
})
local customScale = new("UIScale", { Parent = CustomCursorFrame })
local customCursor = nil

local ringPos, cursorShown = nil, nil

--[[
	Library:SetCursor({
		Size    = Vector2.new(28, 16),     -- size of the drawing
		Hotspot = Vector2.new(0, 0),       -- which point is the actual mouse position (0..1)
		Build   = function(frame) ... end, -- draw anything inside `frame`
	})
	Library:SetCursor(nil) goes back to the ring + dot.
]]
function Library:SetCursor(o)
	for _, child in ipairs(CustomCursorFrame:GetChildren()) do
		if child ~= customScale then
			child:Destroy()
		end
	end
	customCursor = o
	if o then
		CustomCursorFrame.Size = UDim2.fromOffset(o.Size.X, o.Size.Y)
		CustomCursorFrame.AnchorPoint = o.Hotspot or Vector2.new(0, 0)
		o.Build(CustomCursorFrame)
	end
	cursorShown = nil -- re-apply visibility next frame
end

on(RunService.RenderStepped, function(dt)
	local show = Library.Visible and Library.CustomCursor and not Library.Unloaded
	ModalUnlock.Visible = Library.Visible
	if show ~= cursorShown then
		cursorShown = show
		CursorRing.Visible = show and customCursor == nil
		CursorDot.Visible = show and customCursor == nil
		CustomCursorFrame.Visible = show and customCursor ~= nil
		UserInputService.MouseIconEnabled = not show
		ringPos = nil
	end
	if not show then
		return
	end
	local m = UserInputService:GetMouseLocation()
	if customCursor then
		CustomCursorFrame.Position = UDim2.fromOffset(m.X, m.Y)
		return
	end
	ringPos = ringPos and ringPos:Lerp(m, math.clamp(dt * 18, 0, 1)) or m
	CursorDot.Position = UDim2.fromOffset(m.X, m.Y)
	CursorRing.Position = UDim2.fromOffset(ringPos.X, ringPos.Y)
end)

on(UserInputService.InputBegan, function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		tween(ringScale, { Scale = 0.72 }, 0.12, QUINT)
		tween(ringStroke, { Thickness = 2.2 }, 0.12)
		tween(customScale, { Scale = 0.82 }, 0.12, QUINT)
	end
end)
on(UserInputService.InputEnded, function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		tween(ringScale, { Scale = 1 }, 0.35, Enum.EasingStyle.Back)
		tween(ringStroke, { Thickness = 1.6 }, 0.2)
		tween(customScale, { Scale = 1 }, 0.35, Enum.EasingStyle.Back)
	end
end)

--------------------------------------------------------------------------------
-- Mobile open button
--------------------------------------------------------------------------------

--[[
	Floating button for phones / tablets: tap to open or close the menu, drag to move it.
	iconBuilder(frame) draws the icon (the demo uses the "7" from the logo).
	Created automatically by CreateWindow on touch devices; MobileButton = true forces it on PC.
]]
function Library:CreateMobileButton(iconBuilder)
	if self._mobileButton then
		self._mobileButton:Destroy()
	end

	local SIZE = 52
	local b = new("TextButton", {
		Name = "MobileToggle",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = State.MobilePos or UDim2.new(0, 16 + SIZE / 2, 0.32, 0),
		Size = UDim2.fromOffset(SIZE, SIZE),
		BackgroundColor3 = C.Header,
		BackgroundTransparency = 0.05,
		Text = "",
		AutoButtonColor = false,
		Parent = HudLayer,
	}, { corner(14) })
	local border = stroke(C.WindowStroke, 1.5)
	border.Parent = b
	local press = new("UIScale", { Parent = b })
	self._mobileButton = b

	-- icon, centred
	local icon = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(28, 16),
		BackgroundTransparency = 1,
		Parent = b,
	})
	if iconBuilder then
		iconBuilder(icon)
	else
		label({
			Size = UDim2.fromScale(1, 1),
			Text = tostring(self.Name):sub(1, 1),
			FontFace = F.Heavy,
			TextSize = 20,
			TextColor3 = C.Accent,
			TextXAlignment = Enum.TextXAlignment.Center,
			Parent = icon,
		})
	end
	local iconScale = new("UIScale", { Parent = icon })

	-- the border lights up in the accent colour while the menu is open
	function self._mobileRefresh()
		tween(border, { Color = self.Visible and C.Accent or C.WindowStroke }, 0.25)
		tween(iconScale, { Scale = self.Visible and 1 or 0.9 }, 0.3, QUINT)
	end
	self._mobileRefresh()

	local dragging, moved, start, startPos = false, false, nil, nil
	on(b.InputBegan, function(input)
		if isPress(input) then
			dragging, moved, start = true, false, input.Position
			startPos = toGui(b.AbsolutePosition) + b.AbsoluteSize / 2
			tween(press, { Scale = 0.9 }, 0.12, QUINT)
		end
	end)
	on(UserInputService.InputChanged, function(input)
		if not dragging or not isMove(input) then
			return
		end
		local d = input.Position - start
		if math.abs(d.X) + math.abs(d.Y) > 8 then
			moved = true
		end
		if moved then
			local half = SIZE / 2
			local screen = Root.AbsoluteSize
			local x = math.clamp(startPos.X + d.X, half, screen.X - half)
			local y = math.clamp(startPos.Y + d.Y, half, screen.Y - half)
			b.Position = UDim2.fromOffset(x, y)
		end
	end)
	on(UserInputService.InputEnded, function(input)
		if dragging and isPress(input) then
			dragging = false
			tween(press, { Scale = 1 }, 0.4, Enum.EasingStyle.Back)
			if moved then
				State.MobilePos = b.Position
			else
				Library:Toggle()
			end
		end
	end)
	return b
end

--------------------------------------------------------------------------------
-- Toggle / unload / global keys
--------------------------------------------------------------------------------

function Library:Toggle(state)
	if state == nil then
		state = not self.Visible
	end
	self.Visible = state and true or false
	self:ClosePopups()
	hideTip()
	if self.Window then
		self.Window:_SetVisible(self.Visible)
	end
	if self._mobileRefresh then
		self._mobileRefresh()
	end
end

function Library:Unload()
	if self.Unloaded then
		return
	end
	self.Unloaded = true
	for _, c in ipairs(self._connections) do
		c:Disconnect()
	end
	UserInputService.MouseIconEnabled = true
	if blur then
		blur:Destroy()
	end
	ScreenGui:Destroy()
	if Env.__6L4M_HUB == self then
		Env.__6L4M_HUB = nil
	end
end

on(UserInputService.InputBegan, function(input, gp)
	if Library._binding or Library.Unloaded then
		return
	end
	if input.KeyCode == Enum.KeyCode.Escape and Library._popup then
		Library:ClosePopups()
		return
	end
	if not gp and Library.ToggleKey and input.KeyCode == Library.ToggleKey then
		Library:Toggle()
	end
end)

-- helpers exposed so menu scripts can draw custom logos / icons
Library.Create = new
Library.RGB = rgb

return Library
