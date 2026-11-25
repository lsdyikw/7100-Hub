local function _N() end
local ALLOWED_PLACES = {
	[80681221431821] = true,
	[115491614485922] = true,
	[115776365257536] = true,
	[137939444694121] = true,
	[119587547774646] = true,
	[133311125103681] = true,
	[137269396533485] = true,
	[138505112166361] = true,
	[78438427735992] = true,
	[104645279125178] = true,
	[79672855812610] = true,
	[106120159518740] = true,
	[113883239895081] = true,
	[85576197307056] = true,
}
if not ALLOWED_PLACES[game.PlaceId] then
	pcall(function()
		game:GetService("Players").LocalPlayer:Kick("7100: unsupported game.")
	end)
	return
end

local Library = (function()

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local GuiService = game:GetService("GuiService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

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

if Library.IsMobile then
	Library.CustomCursor = false
	Library.ShowTooltips = false
end

local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end

local C = {
	Accent = rgb(255, 255, 255),

	Header = rgb(13, 13, 13),
	Content = rgb(9, 9, 9),
	ContentT = 0.26,
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

function Library:SetAccent(color)
	C.Accent = color
	C.SwitchOn = color
	C.Fill = color
	local _, _, v = color:ToHSV()
	C.KnobOn = v > 0.6 and rgb(14, 14, 14) or rgb(255, 255, 255)
end

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

local function on(signal, fn)

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
		Visible = not Library.IsMobile,
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

local function colorSwatch(parent, opts)
	local color = opts.Default or C.White
	local h, s, v = color:ToHSV()

	local swStroke = stroke(C.Stroke)

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

function Section:AddTextbox(opts)
	opts = opts or {}
	local row = self:_row(30)
	local s = stroke(C.Stroke)
	local frame = new("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = C.Element,
		Parent = row,
	}, { corner(6), s })

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

	if Library.IsMobile and not opts.ShowOnMobile then
		row.Visible = false
		if opts.Callback then
			self:AddButton({ Name = opts.Name or "Run", Callback = opts.Callback })
		end
	end
	return self:_register(opts, row, kb)
end

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

function Library:CreateWindow(o)
	o = o or {}
	if o.Intro then
		self:PlayIntro(o.Title, o.LogoBuilder)
	end

	local size = State.Size or o.Size or Vector2.new(825, 470)

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

	local main = new("CanvasGroup", {
		Name = "Window",
		AnchorPoint = Vector2.new(0.5, 0.5),

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

	new("Frame", {
		Position = UDim2.fromOffset(1, 1),
		Size = UDim2.new(1, -2, 1, -2),
		BackgroundTransparency = 1,
		ZIndex = 20,
		Parent = main,
	}, { corner(9), stroke(C.WindowStroke) })

	local header = new("Frame", {
		Size = UDim2.new(1, 0, 0, HEADER_H),
		BackgroundTransparency = 1,
		Parent = main,
	})

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

	local grip = new("TextButton", {
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -4, 1, -4),
		Size = UDim2.fromOffset(14, 14),
		BackgroundTransparency = 1,
		Text = "",
		ZIndex = 21,
		Visible = not Library.IsMobile,
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

	on(search:GetPropertyChangedSignal("Text"), function()
		W:_Filter(search.Text)
	end)
	on(search.Focused, function()
		tween(searchStroke, { Color = C.StrokeHover }, 0.2)
	end)
	on(search.FocusLost, function()
		tween(searchStroke, { Color = C.Stroke }, 0.2)
	end)

	on(Root:GetPropertyChangedSignal("AbsoluteSize"), function()
		W:_Fit()
	end)

	Library.Window = W
	W:_Fit()

	if o.MobileButton == true or (o.MobileButton ~= false and Library.IsMobile) then
		Library:CreateMobileButton(o.MobileIcon)
	end

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

function Window:_Fit()
	local screen = Root.AbsoluteSize
	if screen.X <= 0 then
		return
	end

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

	tween(stage, { GroupTransparency = 1 }, 0.35)
	tween(stageScale, { Scale = 1.04 }, 0.4, QUINT)
	tween(backdrop, { BackgroundTransparency = 1 }, 0.4)
	task.wait(0.4)
	backdrop:Destroy()
end

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

local ModalUnlock = new("TextButton", {
	Size = UDim2.fromOffset(0, 0),
	BackgroundTransparency = 1,
	Text = "",
	Modal = true,
	Parent = ScreenGui,
})

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
	cursorShown = nil
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

Library.Create = new
Library.RGB = rgb

return Library

end)()

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local new = Library.Create
local rgb = Library.RGB

Library:SetTheme("Purple")
Library.Name = "7100"
Library.ConfigFolder = "7100"

local HttpService = game:GetService("HttpService")

local LOADER_URL = "https://raw.githubusercontent.com/lsdyikw/7100-Hub/main/7100.lua"
local SESSION_FILE = Library.ConfigFolder .. "/session.json"
local TRANSFER_CONFIG = "__transfer"

local function filesOk()
	return typeof(readfile) == "function" and typeof(writefile) == "function" and typeof(isfile) == "function"
end
pcall(function()
	if typeof(isfolder) == "function" and typeof(makefolder) == "function" and not isfolder(Library.ConfigFolder) then
		makefolder(Library.ConfigFolder)
	end
end)

local session = { Rerun = false, HideOnExecute = false, StreamerMode = false }
if filesOk() then
	pcall(function()
		if isfile(SESSION_FILE) then
			local data = HttpService:JSONDecode(readfile(SESSION_FILE))
			if type(data) == "table" then
				for k in pairs(session) do
					if type(data[k]) == "boolean" then
						session[k] = data[k]
					end
				end
			end
		end
	end)
end
local function saveSession()
	if filesOk() then
		pcall(writefile, SESSION_FILE, HttpService:JSONEncode(session))
	end
end
local STAMP_FILE = Library.ConfigFolder .. "/transfer.txt"
local arrivedByTeleport = false
if filesOk() then
	pcall(function()
		if isfile(STAMP_FILE) then
			local stamp = tonumber(readfile(STAMP_FILE))
			arrivedByTeleport = stamp ~= nil and math.abs(os.time() - stamp) < 180
			if typeof(delfile) == "function" then
				delfile(STAMP_FILE)
			end
		end
	end)
end

do
	local rawNotify = Library.Notify
	Library.Notify = function(self, ...)
		if session.StreamerMode then
			return
		end
		return rawNotify(self, ...)
	end
end

local LOGO_PURPLE = Color3.fromRGB(132, 10, 255)

local function Draw7100(holder, H, sevenOnly, color)
	H = H or 22
	local colour = color or LOGO_PURPLE
	local s = H / 253
	local function px(v)
		return v * s
	end
	local logo = new("Frame", {
		AnchorPoint = Vector2.new(0, sevenOnly and 0 or 0.5),
		Position = sevenOnly and UDim2.new() or UDim2.new(0, 0, 0.5, 0),
		Size = UDim2.fromOffset(px(sevenOnly and 435 or 1372), H),
		BackgroundTransparency = 1,
		Parent = holder,
	})
	local function rect(x, y, w, h, parent)
		return new("Frame", {
			Position = UDim2.fromOffset(px(x), px(y)),
			Size = UDim2.fromOffset(px(w), px(h)),
			BackgroundColor3 = colour,
			BorderSizePixel = 0,
			Parent = parent or logo,
		})
	end
	local function clip(x, y, w, h)
		return new("Frame", {
			Position = UDim2.fromOffset(px(x), px(y)),
			Size = UDim2.fromOffset(px(w), px(h)),
			BackgroundTransparency = 1,
			ClipsDescendants = true,
			Parent = logo,
		})
	end
	local function rotated(cx, cy, w, h, rot, parent)
		return new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromOffset(px(cx), px(cy)),
			Size = UDim2.fromOffset(px(w), px(h)),
			Rotation = rot,
			BackgroundColor3 = colour,
			BorderSizePixel = 0,
			Parent = parent,
		})
	end
	local function ring(x, w)
		local t = 64
		new("Frame", {
			Position = UDim2.fromOffset(px(x + t), px(t)),
			Size = UDim2.fromOffset(px(w - 2 * t), px(250 - 2 * t)),
			BackgroundTransparency = 1,
			Parent = logo,
		}, {
			new("UICorner", { CornerRadius = UDim.new(0, px(38)) }),
			new("UIStroke", { Color = colour, Thickness = px(t), ApplyStrokeMode = Enum.ApplyStrokeMode.Border }),
		})
	end

	rect(62, 0, 373, 58)
	rotated(100.5, -41.8, 200, 200, 44.06, clip(0, 0, 62, 60))
	rotated(189.5, 101.5, 440, 81.5, 141.87, clip(52, 53, 383, 200))
	if sevenOnly then
		return logo
	end

	rect(470, 0, 88, 253)

	ring(589, 369)
	ring(988, 384)
	return logo
end

local KEY_LINK = "https://discord.gg/your-invite"
local KEY_SALT = "141069f4fd27dbdd"
local KEY_HASHES = {
	["ec87ca7e7445df6cd30562357def9834de5f093a339aa5d15cfe0e4bbde6c87c"] = true, ["e6d1c8595313dee295d64dcc9ab37c0459aa297a80d71a203050fedca070400e"] = true,
	["8e836759aea03c2a2af3ee8cc590756a76c3b6c7ffb979852f11a6e43341eed6"] = true, ["b6b617ddae4ac7b18107c505758780a266dfdfac42dd98c663307c2b32c8d34b"] = true,
	["9a93ad45e84c8357c27c6c9600a3744fe332311a55eb50041448a754e1fb8074"] = true, ["c589c21cc84564f6489fcd4a4f6a513e7880ec560f46a38d47ddc2449ee178dc"] = true,
	["1c0983939b508dc589571cacffb90b8c913cd8cce55280247023f86a6a152087"] = true, ["18b04b4d3334e9ceca53a6042e3e8322335d6a24f89976951d21e1e6610b279b"] = true,
	["03169cbdeced0ad2bc7a74aef55b440fd8172c79e07aca5b091aac999523a461"] = true, ["3ec5bb76fbd81c7e194751924a03046a5a66c9362d515ba7003c556a42d9362b"] = true,
	["8d0cffc2ba4f9e7f7b3d8cfa241974bc25c69639f4c3d82558d5d4e5202523b2"] = true, ["77c839c56a2b70afd798121405b857d1c29c78e8b30173772ac626947956f11b"] = true,
	["a134a2b19febd68c3c8d2be9c96859d5bee09fbc3794a388fdd84563c1e242f6"] = true, ["337685bc6fbf9aaf8e18ebeb0eeeb3579e52e28718b73c66a7d9a3eca671e2ec"] = true,
	["c818817d83f969038f77f1ae2e97b764b10da0b74a4464dc985b2057d1bcaf42"] = true, ["8693518f6398058d6a762e2b4b8d84cc0b34807941efa9b2f083ab821870ddf0"] = true,
	["2330672b6fb754f1db7cc9c9a30b4d668d4a756813241c81cb39f05ced7bfb19"] = true, ["6136482c37b8e888e8eb8fc0b454489dddde5f6d07fb46c9afccda4b9576d1f9"] = true,
	["f9eaa6a087e17fad2e52e0f2c402e313648468dad7c4328e9e7534352bb1714b"] = true, ["8ec0abefaae4d11fc610d86056c7a234727b6ef8b9827841aec1471ab909d588"] = true,
	["6a9d9de36cd7b3810383698840c365d2c1d7cdb126824dcf3595d73973f6e5fc"] = true, ["3ed4ae8ea2c511c622dc2c8efdaa557da28b3927cba8d472e10bdb7049b0f5db"] = true,
	["8fe359b6cc769313892b3575c3e38b6bb8b04d04396fc14b80f38ebff6e17ca7"] = true, ["3fd168916c0656c275c441ea03757cb3a79c97220f871edb11224b0b9ebec44a"] = true,
	["21a91820b0692b7cbb26595a298c7428c8a7746ce73e5b84ddf94f3d3c7ca29a"] = true, ["0e88a13a3967e1940bfb6faf2e1a8bd451e16139250e7323f4a8c3998fb6dbba"] = true,
	["693eb454075f3862f44766ab73074f6c0e2fad175a0522119e5b7400873a9a16"] = true, ["f1e6425e66b8213c2019ed02f0c456d47a350d720ae296a54e6c4841b655e5e2"] = true,
	["90fa15e82425b2274c743fbac2d14c5620f613a63f1962fe1572ac45eb291511"] = true, ["3b7af22236c168ec07a43917772b64db8d1e65ef960b5f0f39d0656bffc81aed"] = true,
	["456e044198dd01e01e0f1b00f5702d89e7ec43ebbc1c85bd2ad59990def1ec48"] = true, ["fe7e192c7cd4f68ee01a85d8e85a424ec6d2af9aa8531a387e75cdd76e51e2cf"] = true,
	["167042d835040b0296a45970718b99a3fea3e9cf6c6db743a8e63571a907c656"] = true, ["eb19534c405a5459a6b012164dbe35f74d4dd1b66dd5fc9939f01be395d80009"] = true,
	["fb9412f4f8e9a3bd9944ced562f8cb05fb2a2a36996719b3565b424c8f964e31"] = true, ["153517c94afc66995c7da56010e73929e93c9d3fd07b64155b3be332e0fd7eff"] = true,
	["86f103d0a364d484c63729b260e7d36ba5a153184e4934ef9860b80806ecdc5a"] = true, ["cefef1b505748936a6ec93967f9384f01129b3f287897c125145615b7bdcaba4"] = true,
	["a42ea75320fb0261ef19d2da871c932d240b378cddabfdd9752e485422d96c9d"] = true, ["49139d646df71674a7e5c8c9a0d83dc5effb81ac68466e7e1226b20e1679aeb7"] = true,
	["95050330abb0012bedb1f0c47d858044ec5dd987358270f0c7afb6e67bf002a4"] = true, ["dda84881ce0c308bc3a264bfc337c6d773918253a9ef666f96329dde012b1617"] = true,
	["8ac26645baae4cebee8cbc9f1e7be2660f58864b951045b2312c7a411a6cf77e"] = true, ["258c78903f67e024b4ae6e8e71cf13e27a1d6ea6bd8aa1d6e075cd14b9fd2e12"] = true,
	["c95749c1911c6f52d55b473a42ae93419230ac56a5a3102d86af71d24b9ea911"] = true, ["acc8337e0ca2874dd43f2e56a904b6a50a0e3e06566c2636fab62461548defbc"] = true,
	["6cea5ccf740fe525e8315c402c660e38401a53775d2f7a1418d43bb2dc62452b"] = true, ["e324f904623ac59f94b4624f94633348766c9a704dba7def23e237d6f24ac5f0"] = true,
	["17c2fd6aef99e5952ec74a36b920a2f9dfa9a7d0bf306f53c191fd3540427ae0"] = true, ["b9e4cc69aee71832753e42f93e6e31e4af07dd47a26d9b1b0312c029a3a73b02"] = true,
	["43314e4744eebfdba8a4621abb9f6b6f40436a532dd47c2264a6102366f807ef"] = true, ["661aa04d9b3f4767fb29baf7a18d0016f146f4b434a4f3e3796ea5523b534359"] = true,
	["670716bf6d1027468b81ccc755662e17b606907e17ee02b644f4cbce593178ce"] = true, ["02a8af3515362f80ce04b8e1969eaa8edc15451a764cee9a2df6f2b41a4d57cd"] = true,
	["8093325f3b8b183559ab4760f48e0a4197b4cc931f8fc1b2bf5bb472d4d01635"] = true, ["f7f39f7a809e697790f1889754ee5d945a033b34c7307f7010d12531c82b4fac"] = true,
	["9e06e5e6f5d4aff1006d6e3a7f88f1244e49bde4f0e193ad5840cdde1bdc7547"] = true, ["d5e4e5a308239066cd6b69f0012c4eb3ef3b1d6704c754cf8dcb77cc27f051a0"] = true,
	["4174f1211c155a67486a46fc99f8889b2b63c2ca8e92a5c5cc35fbedadd0e795"] = true, ["a534b52ed59ec386b5d13328df9d964d44625c7dda0078c8c655325421ae24ec"] = true,
	["e4b018721e6a7c210e7a42c8730f9cb856a856a7b6f7a2d8c122a21f038c9ce3"] = true, ["86b96e7d404222f7b031d892849f92f4818800809957cf23ed9deac7a5f63049"] = true,
	["f5379be42904e28ab25a9ec259f098b6d42104d8c3b4ce616f95fbfbe4445a69"] = true, ["f4a3190a7ac844a1885e9a9f9dffa01fd8a9e14a36d38101cdb0e5960a6c9171"] = true,
	["07eee55cc6584b6bd733893c527fd76e980a56eed84d45a96bdb5c81df860454"] = true, ["237f2e0d61a7a9ca93a383b50e93ab1c660a086a7ceb1cb3bfd042a0ed525869"] = true,
	["41667e49fed4c934a27b85a60784d61fc30f350767028aaeb2a89581a1f4de8c"] = true, ["c07b62e6d20e2f5e87dcb58451d78ad807eb77df08d61324dff080275168d15e"] = true,
	["58c6dd833aad112b25c7a62255a009c0dcf72ca649ea034864974f4c7a3b0a6f"] = true, ["8c4a0065fe5eb4ffdf6065d9edb953793f11f4c89e81beea83f9c45836dcd883"] = true,
	["292d19a846b70d7c8d74da4bcedfbea1e1926dfae5f0f52ce145dc3781e51eef"] = true, ["de8e59f9ba3e7445e4f068b1cd3ddb05b3480b97a1124742776e4ba979fba432"] = true,
	["a4234c6cc243823a48a684ce81cc6acbd656ab993890a77a6bccb9fc8fbb9e26"] = true, ["0b99ebabbfae93120047e5b8c3f9ea3c4c01eea9e5ace65aab17b5cf762700e9"] = true,
	["137f59765f9bd1df5a9ceebe4376bf5c471464dabec62b80c64290ca87fb54a6"] = true, ["a0879e6e161c4f566952bcb78940e3e7af09f226a89d9a6e06b4490b9adf85e1"] = true,
	["caaacc314a40736bf571caf3558f8d70268a92ff0fe40dc8a52311ccfd6bccf0"] = true, ["2c43e32f3171752917cb4b467304d96ccbce4b6713db102033568cd7c7575ff3"] = true,
	["f1b749e7a280debe49aee0a5a80c7f6c3b96acc2b7ca3f85fd8da1ac247bf28a"] = true, ["11f21d940b05fb6249de2fb01672b6749cc5d870f30dc892e5a2712041a3cd74"] = true,
	["1ec15c096637327772dc830c02cb6c56219f56f291a1ff5a6925ce4c587b71e8"] = true, ["48df6897bcdf7f6c12354ac7dcbbd19da1860ea4d6f826e541138499ebc6e8f1"] = true,
	["6e92e72b4792f130d526147cc0156ce614e09acf3630ea50e722a63353d5569e"] = true, ["603ed6d68e33790dc563688690191c9275bd1b58e2b2658e5f1fbf62e9603dc9"] = true,
	["1e9ad65fc149ad7af906543511d64ecbd06755a93528ffc368409b62206e9f80"] = true, ["4767cf6252f23e78c81528ad9e3024f8a04fcebc4ba44c6e32f742aaddb0dcaa"] = true,
	["3c639f7c0577906224cf55f3c3aec113e1a8506b7d4ff8fa76e087cc950514d2"] = true, ["1dab1ba16a48e53348c10ab6bce4abb9ed2b24213b1e3f9e229d9c6dbbfe7505"] = true,
	["dccf7be43d39d97df4700d37b4a7000923ed4421f0f0eea7410ef86b7855206f"] = true, ["93693753f7da7c4ecf769a141154f02eecc038ce92d8c4970813a6a526b521b7"] = true,
	["458ca46aee6d2067d6ed4d10d399debc505126fd787e624f6efcfd268469dede"] = true, ["754d3b6a7713341e64eb3171e094c9857e47005ff2e0fe1c9d5d4688e11b8181"] = true,
	["736684929790cd71137899c6a88f185c8f65d8c6e0cf4a9205633405873b381b"] = true, ["d00425c50e11fa0e947084b9f5271ddc283cd6c18bd514552e8b3fe248a505af"] = true,
	["6bcb10eb73081c9b311a35a164c63bab7c209e33682b043824cac798b0d5e662"] = true, ["5a30925c7b4ca745b81a414389a1ecf5336b07460c8d6199cacca1d8c507d08d"] = true,
	["e59f091c7a4546e8b8817a2f4619509449a225b84eee90769e129afcd18bf334"] = true, ["e98a8e941a52f0857c75f4ae52d0a0a9d1ab256518eb0d0f63b29e55da6b9e75"] = true,
	["e7ef40ede20c936375fc961622cdcae89e70e900ee9e050abdcbb743efde016e"] = true, ["5367f6b8e4b5931bad8a97928ee8bed954bbc7bc53561994d78d86ff09c5b33e"] = true,
}
local SHA_K = {
	0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5,
	0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
	0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3,
	0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
	0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc,
	0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
	0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7,
	0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
	0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13,
	0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
	0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3,
	0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
	0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5,
	0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
	0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208,
	0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2,
}
local function sha256(msg)
	local band, bxor, bnot, rshift, rrotate = bit32.band, bit32.bxor, bit32.bnot, bit32.rshift, bit32.rrotate
	local len = #msg
	local bits = len * 8
	msg = msg .. "\128" .. string.rep("\0", (55 - len) % 64)
		.. string.char(0, 0, 0, 0, band(rshift(bits, 24), 255), band(rshift(bits, 16), 255), band(rshift(bits, 8), 255), band(bits, 255))
	local H = { 0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a, 0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19 }
	local w = {}
	for i = 1, #msg, 64 do
		for j = 0, 15 do
			local a, b, c, d = string.byte(msg, i + j * 4, i + j * 4 + 3)
			w[j] = a * 16777216 + b * 65536 + c * 256 + d
		end
		for j = 16, 63 do
			local s0 = bxor(rrotate(w[j - 15], 7), rrotate(w[j - 15], 18), rshift(w[j - 15], 3))
			local s1 = bxor(rrotate(w[j - 2], 17), rrotate(w[j - 2], 19), rshift(w[j - 2], 10))
			w[j] = (w[j - 16] + s0 + w[j - 7] + s1) % 4294967296
		end
		local a, b, c, d, e, f, g, h = H[1], H[2], H[3], H[4], H[5], H[6], H[7], H[8]
		for j = 0, 63 do
			local S1 = bxor(rrotate(e, 6), rrotate(e, 11), rrotate(e, 25))
			local ch = bxor(band(e, f), band(bnot(e), g))
			local t1 = (h + S1 + ch + SHA_K[j + 1] + w[j]) % 4294967296
			local S0 = bxor(rrotate(a, 2), rrotate(a, 13), rrotate(a, 22))
			local maj = bxor(band(a, b), band(a, c), band(b, c))
			local t2 = (S0 + maj) % 4294967296
			h, g, f, e, d, c, b, a = g, f, e, (d + t1) % 4294967296, c, b, a, (t1 + t2) % 4294967296
		end
		H[1], H[2], H[3], H[4] = (H[1] + a) % 4294967296, (H[2] + b) % 4294967296, (H[3] + c) % 4294967296, (H[4] + d) % 4294967296
		H[5], H[6], H[7], H[8] = (H[5] + e) % 4294967296, (H[6] + f) % 4294967296, (H[7] + g) % 4294967296, (H[8] + h) % 4294967296
	end
	return string.format("%08x%08x%08x%08x%08x%08x%08x%08x", H[1], H[2], H[3], H[4], H[5], H[6], H[7], H[8])
end
local shaWorks = false
pcall(function()
	shaWorks = sha256("abc") == "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"
end)
local function keyIsValid(key)
	if not shaWorks then
		return false
	end
	key = (tostring(key):upper():gsub("%s", ""))
	local ok, digest = pcall(sha256, KEY_SALT .. key)
	return ok and KEY_HASHES[digest] == true
end
local keyAccepted = Library:KeySystem({
	Title = "7100",
	Note = "Enter your license key to continue.",
	Link = KEY_LINK,
	Remember = true,
	Validate = keyIsValid,
})
if not keyAccepted then
	return
end

Library:SetCursor({
	Size = Vector2.new(28, 16),
	Hotspot = Vector2.new(0, 0),
	Build = function(frame)
		local shadow = Draw7100(frame, 16, true, Color3.new(0, 0, 0))
		shadow.Position = UDim2.fromOffset(1, 1.5)
		for _, part in ipairs(shadow:GetDescendants()) do
			if part:IsA("Frame") and part.BackgroundTransparency < 1 then
				part.BackgroundTransparency = 0.45
			end
		end
		Draw7100(frame, 16, true, LOGO_PURPLE:Lerp(Color3.new(1, 1, 1), 0.12))
	end,
})

local windowEnv = (typeof(getgenv) == "function" and getgenv()) or _G
local savedState = windowEnv.__6L4M_STATE
local camera = workspace.CurrentCamera
local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)
if type(savedState) == "table" then
	savedState.Position = nil
	local s = savedState.Size
	if typeof(s) == "Vector2" and (s.X > viewport.X - 24 or s.Y > viewport.Y - 24) then
		savedState.Size = nil
	end
end

local windowSize = Vector2.new(math.max(480, math.min(1000, viewport.X - 24)), math.max(300, math.min(640, viewport.Y - 40)))

local Window = Library:CreateWindow({
	Title = "7100",
	LogoBuilder = Draw7100,
	MobileIcon = function(frame)
		Draw7100(frame, 16, true)
	end,

	Footer = "v" .. Library.Version .. " · " .. Library.Device:upper(),
	Intro = not (session.HideOnExecute or arrivedByTeleport),
	Size = windowSize,
})

local Home = Window:AddTab("7100")

local Shooting = Window:AddTab("Shooting")

local AutoTime = Shooting:AddSection("Auto Time", "Left")
AutoTime:AddToggle({ Name = "Auto Time", Default = true, Flag = "AutoTime" }):AddKeybind({ Default = Enum.KeyCode.T, Flag = "AutoTimeKey" })
local atOptions = AutoTime:AddOptions("Options")
atOptions:AddSlider({ Name = "No-Meter Hold", Min = 0, Max = 800, Default = 430, Suffix = "ms", Flag = "GreenHold", Tooltip = "Auto method, meter OFF: release this long after you press shoot. 0 = off. 430 is an estimate, tune it with the on-screen Early/Late label." })
atOptions:AddSlider({ Name = "Release Lead", Min = -40, Max = 40, Default = 0, Suffix = "ms", Flag = "GreenLead", Tooltip = "Auto method, meter ON: positive = release earlier, negative = later." })
atOptions:AddToggle({ Name = "Hide Stale Meters", Default = true, Flag = "GreenFixStale", Tooltip = "Hides a leftover meter of another style (visual only)" })

local PlayerTab = Window:AddTab("Player")
local PlayerUtility = PlayerTab:AddSection("Utility", "Left")
PlayerUtility:AddToggle({ Name = "Infinite Dribble Stamina", Flag = "InfStamina", Tooltip = "Visual only: keeps your stamina ring full. The game tracks stamina on the server." })
local LegitSection = PlayerTab:AddSection("Legit Speed", "Left")
LegitSection:AddToggle({ Name = "Legit Speed", Flag = "LegitSpeed", Tooltip = "Raises the ratings the game's own movement code reads. Speed Rating is scaled from your own WalkSpeed (uncalibrated)." })
local SpeedSection = PlayerTab:AddSection("Speed", "Right")
SpeedSection:AddToggle({ Name = "Screening Speed", Flag = "ScreenSpeed", Tooltip = "Speed while you are screening. The game clamps walk speed at 17." })
SpeedSection:AddSlider({ Name = "Speed (studs/sec)", Min = 8, Max = 17, Default = 14, Increment = 0.1, Flag = "ScreenSpeedVal" })
SpeedSection:AddToggle({ Name = "With Ball Speed", Flag = "BallSpeed", Tooltip = "Speed while you hold the ball. The game clamps walk speed at 17." })
SpeedSection:AddSlider({ Name = "Speed (studs/sec)", Min = 8, Max = 17, Default = 14, Increment = 0.1, Flag = "BallSpeedVal" })
SpeedSection:AddToggle({ Name = "Guard/Boxout Speed", Flag = "GuardSpeed", Tooltip = "Needs getgc to detect Guard/Boxout. The game clamps walk speed at 14 while guarding." })
SpeedSection:AddSlider({ Name = "Speed (studs/sec)", Min = 8, Max = 14, Default = 14, Increment = 0.1, Flag = "GuardSpeedVal" })
SpeedSection:AddToggle({ Name = "Sprint Boost", Flag = "SprintBoost", Tooltip = "Adds a percentage of the 3.35 sprint bonus while sprinting, inside the game's clamp." })
SpeedSection:AddSlider({ Name = "Boost %", Min = 0, Max = 100, Default = 50, Flag = "SprintBoostPct" })
local lsOptions = LegitSection:AddOptions("Ratings")
lsOptions:AddButton({ Name = "Match My Build", Tooltip = "Sets the four sliders to the ratings your build really has", Callback = function()
	local f = Library.Features
	local m = f and f.Modules and f.Modules.LegitSpeed
	if m and m.MatchBuild then
		m.MatchBuild()
	end
end })
lsOptions:AddSlider({ Name = "Speed Rating", Min = 25, Max = 99, Default = 99, Flag = "LegitSpeedRating", Tooltip = "Scales your WalkSpeed from your real rating; held at the game's 17 cap" })
lsOptions:AddSlider({ Name = "With Ball Speed Rating", Min = 25, Max = 99, Default = 99, Flag = "LegitBallHandle", Tooltip = "Writes Ball Handle, which scales your speed while dribbling" })
lsOptions:AddSlider({ Name = "Acceleration Rating", Min = 25, Max = 99, Default = 99, Flag = "LegitAccel" })
lsOptions:AddSlider({ Name = "Lateral Speed Rating", Min = 25, Max = 99, Default = 99, Flag = "LegitLateral" })
local DesyncSection = PlayerTab:AddSection("Desync (Fake Lag / Invisible)", "Right")
DesyncSection:AddToggle({ Name = "Desync", Flag = "Desync", Tooltip = "Others see you in the sky or frozen; you stay put (see-through) on your screen with a solid copy at your start spot. Unverified for other players." }):AddKeybind({ Mode = "Toggle", Flag = "DesyncKey" })
DesyncSection:AddDropdown({ Name = "Mode", Options = { "Sky", "Freeze" }, Default = "Sky", Flag = "DesyncMode" })
DesyncSection:AddSlider({ Name = "Sky Height (studs)", Min = 20, Max = 3900, Default = 950, Flag = "DesyncSky", Tooltip = "The position packet only holds +-1000 studs (+-4000 in Plaza), so outside Plaza anything above about 990 is cut to the limit" })
DesyncSection:AddToggle({ Name = "Be Real (hold key)", Flag = "DesyncReal", Tooltip = "While held your real position is sent, so you can pick up a ball" }):AddKeybind({ Mode = "Hold", Flag = "DesyncRealKey" })
DesyncSection:AddSlider({ Name = "Near Ball Range (studs)", Min = 5, Max = 80, Default = 40, Flag = "DesyncNearBall" })
DesyncSection:AddSlider({ Name = "See-through (%)", Min = 0, Max = 100, Default = 60, Flag = "DesyncAlpha" })
local CloudSection = PlayerTab:AddSection("Cloud Ride", "Left")
CloudSection:AddToggle({ Name = "Cloud Ride", Flag = "CloudRide", Tooltip = "Lifts you onto a cloud. Other players may or may not see it. Unverified." }):AddKeybind({ Mode = "Toggle", Flag = "CloudRideKey" })
CloudSection:AddSlider({ Name = "Fly Speed (studs/s)", Min = 5, Max = 80, Default = 28, Increment = 1, Flag = "CloudSpeed" })
CloudSection:AddSlider({ Name = "Start Height (studs)", Min = 0, Max = 60, Default = 12, Increment = 1, Flag = "CloudHeight" })
CloudSection:AddSlider({ Name = "Max Height (studs)", Min = 10, Max = 200, Default = 80, Increment = 5, Flag = "CloudMaxHeight" })
CloudSection:AddToggle({ Name = "Rise (hold key)", Flag = "CloudUp", Tooltip = "Give this a Hold key" }):AddKeybind({ Mode = "Hold", Flag = "CloudUpKey" })
CloudSection:AddToggle({ Name = "Descend (hold key)", Flag = "CloudDown", Tooltip = "Give this a Hold key" }):AddKeybind({ Mode = "Hold", Flag = "CloudDownKey" })
local BallGhostSection = PlayerTab:AddSection("Ball Ghost", "Left")
BallGhostSection:AddToggle({ Name = "Ball Ghost (predict landing)", Flag = "BallGhost", Tooltip = "Draws a see-through ball where a ball in the air will first hit something. Your screen only." })
BallGhostSection:AddToggle({ Name = "Show Trajectory", Flag = "BallTrajectory" })
local CosmeticsTab = Window:AddTab("Cosmetics")
local CatalogSection = CosmeticsTab:AddSection("Catalog", "Left")
CatalogSection:AddToggle({ Name = "Cosmetics (keep items on)", Default = true, Flag = "CosmeticsOn", Tooltip = "Keeps the items you picked on your character, even after the game redraws it. Your screen only." })
CatalogSection:AddButton({ Name = "Open Catalog", Callback = function()
	local m = Library.Features and Library.Features.Modules.Cosmetics
	if m then
		m.Toggle()
	end
end })
CatalogSection:AddKeybind({ Name = "Catalog Key", Flag = "CatalogKey", Callback = function()
	local m = Library.Features and Library.Features.Modules.Cosmetics
	if m then
		m.Toggle()
	end
end })
CatalogSection:AddButton({ Name = "Take Everything Off", Callback = function()
	local m = Library.Features and Library.Features.Modules.Cosmetics
	if m then
		m.Reset()
	end
end })
local greenEffectNames = { "Default (yours)" }
do
	local cfgNode = game:GetService("ReplicatedStorage")
	for _, n in ipairs({ "Aero", "Shared", "Config", "GreenEffects" }) do
		cfgNode = cfgNode and cfgNode:FindFirstChild(n)
	end
	if cfgNode and cfgNode:IsA("ModuleScript") then
		local okCfg, cfg = pcall(require, cfgNode)
		if okCfg and type(cfg) == "table" and type(cfg.Effects) == "table" then
			local names = {}
			for name in pairs(cfg.Effects) do
				table.insert(names, tostring(name))
			end
			table.sort(names)
			for _, name in ipairs(names) do
				table.insert(greenEffectNames, name)
			end
		end
	end
end
local GreenSection = CosmeticsTab:AddSection("Green Effect", "Left")
GreenSection:AddToggle({ Name = "Use My Green Effect", Flag = "GreenEffectOn", Tooltip = "Your own green shots play the effect you pick below. Your screen only." })
GreenSection:AddDropdown({ Name = "Green Effect", Options = greenEffectNames, Default = "Default (yours)", Flag = "GreenEffectChoice" })
local LogoSection = CosmeticsTab:AddSection("Logo", "Right")
LogoSection:AddToggle({ Name = "Use My Head Logo", Flag = "HeadLogoOn", Tooltip = "Shows the logo you pick above your head, on your screen only." })
LogoSection:AddDropdown({ Name = "Head Logo", Options = { "Default (yours)", "None", "Owner", "Moderator", "Twitch", "Tiktok", "YouTube", "Music" }, Default = "Default (yours)", Flag = "HeadLogoChoice" })
local DribblingTab = Window:AddTab("Dribbling")
local DribbleSection = DribblingTab:AddSection("Dribble Glide & Boost", "Left")
DribbleSection:AddToggle({ Name = "Dribble Glide", Flag = "DribbleGlide", Tooltip = "Scales the server-driven velocity of your dribble moves. Uncalibrated." })
DribbleSection:AddSlider({ Name = "Glide Power (%)", Min = 0, Max = 100, Default = 25, Flag = "DribbleGlidePower" })
DribbleSection:AddToggle({ Name = "Dribble Boost", Flag = "DribbleBoost", Tooltip = "Adds speed (studs/sec) for a moment after each dribble action. The game zeroes anything over 27.5 so it is capped." })
DribbleSection:AddSlider({ Name = "Boost Power (studs/sec)", Min = 0, Max = 12, Default = 7, Increment = 0.5, Flag = "DribbleBoostPower" })
DribbleSection:AddToggle({ Name = "Post Glide", Flag = "PostGlide", Tooltip = "Same as Dribble Glide, while you are in the post. Uncalibrated." })
DribbleSection:AddSlider({ Name = "Post Glide Power (%)", Min = 0, Max = 100, Default = 25, Flag = "PostGlidePower" })

local MacroSection = DribblingTab:AddSection("Dribble Macros", "Left")
MacroSection:AddLabel({ Text = "One key per move. It does the right version for the hand the ball is in.", Small = true })
MacroSection:AddToggle({ Name = "Sprint Version (Escape / Explosive)", Flag = "MacroSprint", Tooltip = "Sends the move as if Shift were held. Hold a direction for the push / forward / backward / lateral versions." })
local MOVE_NAMES = { "Switch Hand", "Crossover", "Hesitation", "Double Crossover", "Tween", "Double Tween", "Behind The Back", "BTB Between Legs", "Double BTB", "Spin", "Half Spin", "Stepback", "Snatchback", "Shammgod", "Jab Right", "Jab Left", "Jab Turn Around" }
for _, moveName in ipairs(MOVE_NAMES) do
	MacroSection:AddKeybind({ Name = moveName, Flag = "Macro_" .. moveName:gsub(" ", ""), Callback = function()
		local m = Library.Features and Library.Features.Modules.DribbleTools
		if m then
			m.Move(moveName)
		end
	end })
end
local COMBO_OPTIONS = { "None", "Crossover", "Hesitation", "Double Crossover", "Tween", "Double Tween", "Behind The Back", "BTB Between Legs", "Double BTB", "Spin", "Half Spin", "Stepback", "Snatchback", "Shammgod", "Switch Hand" }
local ComboSettings = DribblingTab:AddSection("Combo Settings", "Right")
ComboSettings:AddSlider({ Name = "Gap After Each Move (s)", Min = 0.05, Max = 1, Default = 0.25, Increment = 0.05, Flag = "ComboGap", Tooltip = "The reference uses 0.05. If moves get dropped, raise it." })
for combo = 1, 4 do
	local sec = DribblingTab:AddSection("Combo " .. combo, "Right")
	sec:AddKeybind({ Name = "Combo " .. combo .. " Key", Flag = "Combo" .. combo .. "Key", Callback = function()
		local m = Library.Features and Library.Features.Modules.DribbleTools
		if m then
			m.Combo(combo)
		end
	end })
	for slot = 1, 6 do
		sec:AddDropdown({ Name = "Move " .. slot, Options = COMBO_OPTIONS, Default = "None", Flag = ("Combo%dMove%d"):format(combo, slot) })
	end
end
local DefenseTab = Window:AddTab("Defense")
local BadgesTab = Window:AddTab("Badges")
local LegitSection2 = Shooting:AddSection("Legit Check", "Left")
LegitSection2:AddToggle({ Name = "Legit Warnings (HUD)", Flag = "LegitWarnings", Tooltip = "Shows your perfect % this game and all-time, with a warning when it is high for a human." })
LegitSection2:AddSlider({ Name = "Warn Above Perfect %", Min = 10, Max = 90, Default = 40, Flag = "WarnAbove" })
LegitSection2:AddSlider({ Name = "Perfect At/Above (%)", Min = 50, Max = 100, Default = 80, Flag = "PerfectAt", Tooltip = "A shot counts as perfect when the game's printed percentage is at or above this. Tune it to your build." })
LegitSection2:AddButton({ Name = "Reset All-Time Stats", Callback = function()
	local f = Library.Features
	local m = f and f.Modules and f.Modules.LegitHud
	if m and m.Reset then
		m.Reset()
	end
end })
local AutoShootSection = Shooting:AddSection("Auto Shoot", "Left")
AutoShootSection:AddToggle({ Name = "Auto Shoot", Flag = "AutoShoot", Tooltip = "Starts a shot when it looks good. Turn Auto Time on too. Contest and make % are rough estimates." })
AutoShootSection:AddSlider({ Name = "Min Make %", Min = 0, Max = 100, Default = 60, Flag = "ShootMinMake" })
AutoShootSection:AddSlider({ Name = "Aggressiveness", Min = 0, Max = 100, Default = 50, Flag = "ShootAggro", Tooltip = "Raises Max Contest and lowers Min Make" })
AutoShootSection:AddSlider({ Name = "Max Contest", Min = 0, Max = 100, Default = 18, Flag = "ShootMaxContest" })
AutoShootSection:AddSlider({ Name = "Max Distance (studs)", Min = 5, Max = 80, Default = 45, Flag = "ShootMaxDist" })
AutoShootSection:AddToggle({ Name = "Range Visual", Flag = "ShootRangeVisual", Tooltip = "Draws a ring on the floor at Max Distance around the basket (your screen only)" })
AutoShootSection:AddDropdown({ Name = "Shoot When", Options = { "Contest", "Potential Contest" }, Default = "Contest", Flag = "ShootWhen" })
local FoulSection = Shooting:AddSection("Foul Bait", "Left")
FoulSection:AddToggle({ Name = "Foul Bait Helper", Flag = "FoulBait", Tooltip = "Runs you into a nearby player who jumps to shoot, hoping for a blocking foul. Sometimes works. Needs getgc." })
FoulSection:AddSlider({ Name = "Range (studs)", Min = 3, Max = 25, Default = 10, Increment = 1, Flag = "FoulRange" })
FoulSection:AddSlider({ Name = "Run Time (s)", Min = 0.2, Max = 1.5, Default = 0.5, Increment = 0.05, Flag = "FoulRunTime" })
FoulSection:AddSlider({ Name = "Cooldown (s)", Min = 0.5, Max = 6, Default = 2, Increment = 0.5, Flag = "FoulCooldown" })
FoulSection:AddToggle({ Name = "Opponents Only (Team)", Flag = "FoulTeamCheck" })
local BadShotSection = Shooting:AddSection("Bad Shot Fake", "Left")
BadShotSection:AddToggle({ Name = "Bad Shot Fake", Flag = "BadShotFake", Tooltip = "When you start a shot against a high contest, sends a pump fake (a tap of E) instead. Contest is an estimate." })
BadShotSection:AddSlider({ Name = "Fake Above Contest", Min = 0, Max = 100, Default = 27, Flag = "BadShotContest" })local ShotGlideSection = Shooting:AddSection("Shot Glide", "Right")
ShotGlideSection:AddToggle({ Name = "Shot Glide", Flag = "ShotGlide", Tooltip = "Keeps you gliding while you shoot. Uncalibrated." })
ShotGlideSection:AddSlider({ Name = "Glide Speed (studs/sec)", Min = 0, Max = 12, Default = 6, Increment = 0.5, Flag = "ShotGlideSpeed" })
ShotGlideSection:AddDropdown({ Name = "Glide For", Options = { "Shooting", "Gathering", "Hopstep", "Eurostep", "Spin", "Stepback" }, Multi = true, Default = { "Shooting", "Gathering", "Hopstep", "Eurostep", "Spin", "Stepback" }, Flag = "ShotGlideFor" })

local LobSection = Shooting:AddSection("Lobs & Passes", "Right")
LobSection:AddToggle({ Name = "Auto Lob", Flag = "AutoLob", Tooltip = "Sends a self lob when you run at your basket with the ball. Auto Catch is not built yet." })
LobSection:AddSlider({ Name = "Lob Min Distance (studs)", Min = 3, Max = 30, Default = 8, Increment = 1, Flag = "LobMin" })
LobSection:AddSlider({ Name = "Lob Max Distance (studs)", Min = 10, Max = 60, Default = 24, Increment = 1, Flag = "LobMax" })
LobSection:AddSlider({ Name = "Lob Cooldown (s)", Min = 1, Max = 10, Default = 4, Increment = 0.5, Flag = "LobCooldown" })
LobSection:AddKeybind({ Name = "Self Lob Key", Flag = "SelfLobKey", Callback = function()
	local m = Library.Features and Library.Features.Modules.LobTools
	if m then
		m.SelfLob()
	end
end })
LobSection:AddKeybind({ Name = "Alley-Oop Key (to teammate near basket)", Flag = "AlleyOopKey", Callback = function()
	local m = Library.Features and Library.Features.Modules.LobTools
	if m then
		m.AlleyOop()
	end
end })
LobSection:AddKeybind({ Name = "Pass To Open Man Key", Flag = "PassOpenKey", Callback = function()
	local m = Library.Features and Library.Features.Modules.LobTools
	if m then
		m.PassOpen()
	end
end })
LobSection:AddSlider({ Name = "Open Distance (studs)", Min = 3, Max = 25, Default = 8, Increment = 1, Flag = "OpenDistance", Tooltip = "How far the nearest opponent must be from a teammate for them to count as open" })
LobSection:AddSlider({ Name = "Pass Range (studs)", Min = 15, Max = 120, Default = 70, Increment = 5, Flag = "OpenPassRange" })
local JumpHeightSection = Shooting:AddSection("Jump Height", "Right")
JumpHeightSection:AddToggle({ Name = "Jumpshot Height", Flag = "JumpshotHeight", Tooltip = "Raises your jumpshot. Visual/position only if the server does not agree. Unverified." })
JumpHeightSection:AddSlider({ Name = "Jumpshot Extra (studs)", Min = 0, Max = 6, Default = 1, Increment = 0.1, Flag = "JumpshotExtra" })
JumpHeightSection:AddToggle({ Name = "Hopstep Height", Flag = "HopstepHeight", Tooltip = "Raises your hopstep. The Hopstep action name is not confirmed yet." })
JumpHeightSection:AddSlider({ Name = "Hopstep Extra (studs)", Min = 0, Max = 6, Default = 1, Increment = 0.1, Flag = "HopstepExtra" })
local DunkVertSection = Shooting:AddSection("Dunk Vert", "Right")
DunkVertSection:AddToggle({ Name = "Dunk Vert", Flag = "DunkVert", Tooltip = "Raises your dunks. Unverified." })
DunkVertSection:AddSlider({ Name = "Extra Height (studs)", Min = 0, Max = 6, Default = 2, Increment = 0.1, Flag = "DunkVertExtra" })
local StealSection = DefenseTab:AddSection("Auto Steal", "Left")
StealSection:AddToggle({ Name = "Auto Steal", Flag = "AutoSteal", Tooltip = "Sends a steal when an opponent with the ball is in range and in front of you. The server decides if it works." })
StealSection:AddSlider({ Name = "Range (studs)", Min = 2, Max = 14, Default = 8, Increment = 0.5, Flag = "StealRange" })
StealSection:AddSlider({ Name = "Cooldown (s)", Min = 0.3, Max = 3, Default = 1.2, Increment = 0.1, Flag = "StealCooldown" })
StealSection:AddToggle({ Name = "Only When Facing", Flag = "StealFacing" })
StealSection:AddToggle({ Name = "Ball Handler Only", Flag = "StealBallOnly", Tooltip = "Off = press steal whenever anyone is in range, like holding X. On = only when they hold the ball and match Steal On." })
StealSection:AddToggle({ Name = "Opponents Only (Team)", Flag = "StealTeamCheck", Tooltip = "Skip players on your own team" })
StealSection:AddDropdown({ Name = "Steal On", Options = { "Dribbling", "Gathering", "Triple Threat", "Idle" }, Multi = true, Default = { "Dribbling", "Gathering", "Triple Threat", "Idle" }, Flag = "StealOn" })
local BlockSection = DefenseTab:AddSection("Auto Block", "Right")
BlockSection:AddToggle({ Name = "Auto Block", Flag = "AutoBlock", Tooltip = "Presses jump (the block key) when a nearby player starts a shot. The server decides if it is a block." })
BlockSection:AddSlider({ Name = "Range (studs)", Min = 5, Max = 40, Default = 18, Increment = 1, Flag = "BlockRange" })
BlockSection:AddSlider({ Name = "Delay After Shot Starts (ms)", Min = 0, Max = 600, Default = 150, Increment = 10, Flag = "BlockDelay" })
BlockSection:AddSlider({ Name = "Hold (ms)", Min = 100, Max = 800, Default = 350, Increment = 10, Flag = "BlockHold" })
BlockSection:AddSlider({ Name = "Cooldown (s)", Min = 0.5, Max = 4, Default = 1.5, Increment = 0.1, Flag = "BlockCooldown" })
BlockSection:AddToggle({ Name = "Opponents Only (Team)", Flag = "BlockTeamCheck", Tooltip = "Skip shooters on your own team" })
local ReboundSection = DefenseTab:AddSection("Auto Rebound", "Left")
ReboundSection:AddToggle({ Name = "Auto Rebound", Flag = "AutoRebound", Tooltip = "Presses jump when a loose ball is coming down within reach. Move To The Ball is not built. Unverified." })
ReboundSection:AddSlider({ Name = "Range (studs)", Min = 3, Max = 30, Default = 12, Increment = 1, Flag = "ReboundRange" })
ReboundSection:AddSlider({ Name = "Max Ball Height (studs)", Min = 3, Max = 25, Default = 12, Increment = 1, Flag = "ReboundHeight" })
ReboundSection:AddSlider({ Name = "Hold (ms)", Min = 100, Max = 800, Default = 300, Increment = 10, Flag = "ReboundHold" })
ReboundSection:AddSlider({ Name = "Cooldown (s)", Min = 0.4, Max = 4, Default = 1.2, Increment = 0.1, Flag = "ReboundCooldown" })
local GuardSection = DefenseTab:AddSection("Auto Guard", "Left")
GuardSection:AddToggle({ Name = "Auto Guard", Flag = "AutoGuard", Tooltip = "Holds defense (G) and steers you to the guard spot between the ball handler and their basket. Needs getgc. Unverified." })
GuardSection:AddToggle({ Name = "Hold G Automatically", Default = true, Flag = "GuardHoldG" })
GuardSection:AddToggle({ Name = "Steer To Guard Spot", Default = true, Flag = "GuardSteer" })
GuardSection:AddToggle({ Name = "Override My Input", Flag = "GuardOverride", Tooltip = "Steer even while you are pressing a movement key" })
GuardSection:AddSlider({ Name = "Range (studs)", Min = 5, Max = 50, Default = 25, Increment = 1, Flag = "GuardRange" })
GuardSection:AddSlider({ Name = "Guard Distance (studs)", Min = 1, Max = 10, Default = 3.5, Increment = 0.25, Flag = "GuardDistance" })
GuardSection:AddToggle({ Name = "Opponents Only (Team)", Flag = "GuardTeamCheck" })
local BlockGlideSection = DefenseTab:AddSection("Block Glide", "Left")
BlockGlideSection:AddToggle({ Name = "Block Glide", Flag = "BlockGlide", Tooltip = "Keeps you gliding while you block. Uncalibrated." })
BlockGlideSection:AddSlider({ Name = "Glide Speed (studs/sec)", Min = 0, Max = 12, Default = 8, Increment = 0.5, Flag = "BlockGlideSpeed" })

local FpsBoost = (function()
	local Lighting = game:GetService("Lighting")
	local api = {}
	local OPTIONS = { "Shadows", "Materials", "Particles & Beams", "Post-Processing", "Atmosphere & Fog", "Terrain & Water", "Decals & Textures", "Far Players" }
	local DEFAULT = { "Shadows", "Materials", "Particles & Beams", "Post-Processing", "Atmosphere & Fog", "Terrain & Water" }
	api.Options, api.Default = OPTIONS, DEFAULT
	local original = setmetatable({}, { __mode = "k" })
	local hidden = setmetatable({}, { __mode = "k" })
	local active = {}
	local running, generation = false, 0
	local prevCap, prevQuality
	local conns = {}

	local function put(inst, prop, value)
		pcall(function()
			local saved = original[inst]
			if not saved then
				saved = {}
				original[inst] = saved
			end
			if saved[prop] == nil then
				saved[prop] = inst[prop]
			end
			inst[prop] = value
		end)
	end

	local function boost(inst)
		if inst:IsA("BasePart") then
			if active["Shadows"] then
				put(inst, "CastShadow", false)
			end
			if active["Materials"] and not inst:IsA("Terrain") then
				put(inst, "Material", Enum.Material.SmoothPlastic)
				put(inst, "Reflectance", 0)
			end
		elseif active["Particles & Beams"] and (inst:IsA("ParticleEmitter") or inst:IsA("Trail") or inst:IsA("Beam") or inst:IsA("Smoke") or inst:IsA("Fire") or inst:IsA("Sparkles")) then
			put(inst, "Enabled", false)
		elseif active["Post-Processing"] and inst:IsA("PostEffect") and inst.Name ~= "6L4M_Blur" then
			put(inst, "Enabled", false)
		elseif active["Atmosphere & Fog"] and inst:IsA("Atmosphere") then
			put(inst, "Density", 0)
			put(inst, "Haze", 0)
		elseif active["Decals & Textures"] and (inst:IsA("Decal") or inst:IsA("Texture")) then
			put(inst, "Transparency", 1)
		end
	end

	local function readOptions()
		local list = Library.Flags.FpsOptions
		if type(list) ~= "table" then
			list = DEFAULT
		end
		local on = {}
		for _, name in ipairs(list) do
			on[name] = true
		end
		return on
	end

	local function setHidden(model, state)
		if (hidden[model] or false) == state then
			return
		end
		hidden[model] = state or nil
		for _, d in ipairs(model:GetDescendants()) do
			if d:IsA("BasePart") then
				if state then
					put(d, "LocalTransparencyModifier", 1)
				else
					local saved = original[d]
					if saved and saved.LocalTransparencyModifier ~= nil then
						pcall(function()
							d.LocalTransparencyModifier = saved.LocalTransparencyModifier
						end)
						saved.LocalTransparencyModifier = nil
					end
				end
			end
		end
	end

	local function farPlayers()
		local folder = workspace:FindFirstChild("Characters")
		local mine = folder and folder:FindFirstChild(LocalPlayer.Name)
		local root = mine and mine:FindFirstChild("HumanoidRootPart")
		if not (folder and root) then
			return
		end
		local limit = Library.Flags.FpsDistance or 100
		for _, model in ipairs(folder:GetChildren()) do
			if model ~= mine and model:IsA("Model") then
				local other = model:FindFirstChild("HumanoidRootPart")
				if other then
					setHidden(model, active["Far Players"] == true and (other.Position - root.Position).Magnitude > limit)
				end
			end
		end
	end

	local function restoreAll()
		local n = 0
		for inst, props in pairs(original) do
			for prop, value in pairs(props) do
				pcall(function()
					inst[prop] = value
				end)
			end
			n += 1
			if n % 2000 == 0 then
				task.wait()
			end
		end
		original = setmetatable({}, { __mode = "k" })
		hidden = setmetatable({}, { __mode = "k" })
	end

	local function applyAll(myGen)
		active = readOptions()
		if active["Shadows"] then
			put(Lighting, "GlobalShadows", false)
		end
		if active["Terrain & Water"] then
			local terrain = workspace:FindFirstChildOfClass("Terrain")
			if terrain then
				put(terrain, "WaterWaveSize", 0)
				put(terrain, "WaterWaveSpeed", 0)
				put(terrain, "WaterReflectance", 0)
				put(terrain, "Decoration", false)
			end
		end
		local n = 0
		for _, root in ipairs({ workspace, Lighting }) do
			for _, d in ipairs(root:GetDescendants()) do
				if myGen ~= generation then
					return
				end
				boost(d)
				n += 1
				if n % 1500 == 0 then
					task.wait()
				end
			end
		end
	end

	local function applyEngine()
		if typeof(setfpscap) == "function" then
			if prevCap == nil then
				prevCap = (typeof(getfpscap) == "function" and getfpscap()) or 60
			end
			pcall(setfpscap, Library.Flags.FpsCap or 240)
		end
		pcall(function()
			local rendering = settings().Rendering
			if prevQuality == nil then
				prevQuality = rendering.QualityLevel
			end
			rendering.QualityLevel = math.clamp(math.floor(Library.Flags.FpsGraphics or 6), 1, 10)
		end)
	end

	function api.Stop()
		generation += 1
		running = false
		for _, c in ipairs(conns) do
			c:Disconnect()
		end
		table.clear(conns)
		task.spawn(restoreAll)
		if prevCap ~= nil and typeof(setfpscap) == "function" then
			pcall(setfpscap, prevCap)
		end
		prevCap = nil
		if prevQuality ~= nil then
			pcall(function()
				settings().Rendering.QualityLevel = prevQuality
			end)
			prevQuality = nil
		end
	end

	function api.Update()
		generation += 1
		local myGen = generation
		if Library.Flags.FpsBoost ~= true then
			if running then
				api.Stop()
			end
			return
		end
		task.spawn(function()
			task.wait(0.3)
			if myGen ~= generation then
				return
			end
			if running then
				restoreAll()
			end
			running = true
			applyEngine()
			applyAll(myGen)
			if #conns == 0 then
				table.insert(conns, workspace.DescendantAdded:Connect(function(d)
					if running then
						boost(d)
					end
				end))
				table.insert(conns, Lighting.DescendantAdded:Connect(function(d)
					if running then
						boost(d)
					end
				end))
				table.insert(conns, game:GetService("RunService").Heartbeat:Connect(function()

					api._acc = (api._acc or 0) + 1
					if api._acc >= 30 and running then
						api._acc = 0
						farPlayers()
					end
				end))
			end
		end)
	end
	return api
end)()
do
	local baseUnload = Library.Unload
	Library.Unload = function(self, ...)
		pcall(FpsBoost.Stop)
		return baseUnload(self, ...)
	end

	local baseList = Library.ListConfigs
	Library.ListConfigs = function(self, ...)
		local out = {}
		for _, name in ipairs(baseList(self, ...)) do
			if name:sub(1, 2) ~= "__" then
				table.insert(out, name)
			end
		end
		return out
	end
end

local StatusSection = Home:AddSection("Status", "Left")
StatusSection:AddLabel({ Text = "Practical Basketball - active", Small = true })
StatusSection:AddLabel({ Text = "Version " .. Library.Version .. " / " .. Library.Device, Small = true })

local ConfigSection = Home:AddSection("Configuration", "Left")
ConfigSection:AddConfigManager()
ConfigSection:AddKeybind({
	Name = "Open / Close Menu",
	Default = Library.ToggleKey,
	NoSearch = true,
	Changed = function(k)
		Library.ToggleKey = k
	end,
})

local SessionSection = Home:AddSection("Session", "Left")
SessionSection:AddToggle({
	Name = "Re-run after teleport",
	Default = session.Rerun,
	Tooltip = "Runs 7100 again after you teleport and carries your current settings over",
	Callback = function(v)
		session.Rerun = v
		saveSession()
	end,
})
SessionSection:AddToggle({
	Name = "Hide Menu On Execute",
	Default = session.HideOnExecute,
	Tooltip = "Starts with the menu closed and no intro. Open it with your menu key or the 7 button",
	Callback = function(v)
		session.HideOnExecute = v
		saveSession()
	end,
})
SessionSection:AddToggle({
	Name = "Streamer Mode",
	Default = session.StreamerMode,
	Tooltip = "Hides every pop-up",
	Callback = function(v)
		session.StreamerMode = v
		saveSession()
	end,
})

local FpsSection = Home:AddSection("FPS Booster", "Right")
FpsSection:AddToggle({ Name = "FPS Booster", Flag = "FpsBoost", Callback = FpsBoost.Update })
FpsSection:AddDropdown({
	Name = "Boost",
	Options = FpsBoost.Options,
	Default = FpsBoost.Default,
	Multi = true,
	Flag = "FpsOptions",
	Callback = FpsBoost.Update,
})
FpsSection:AddSlider({ Name = "FPS Cap", Min = 30, Max = 360, Default = 240, Increment = 10, Flag = "FpsCap", Callback = FpsBoost.Update })
FpsSection:AddSlider({ Name = "Graphics Level", Min = 1, Max = 10, Default = 6, Increment = 1, Flag = "FpsGraphics", Callback = FpsBoost.Update })
FpsSection:AddSlider({ Name = "Player Distance", Min = 30, Max = 400, Default = 100, Increment = 10, Flag = "FpsDistance", Tooltip = "Used by Far Players: other players beyond this distance are hidden", Callback = FpsBoost.Update })

local InterfaceSection = Home:AddSection("Interface", "Right")
InterfaceSection:AddToggle({
	Name = "Custom Cursor",
	Default = Library.CustomCursor,
	Callback = function(v)
		Library.CustomCursor = v
	end,
})
InterfaceSection:AddToggle({
	Name = "Background Blur",
	Default = Library.BackgroundBlur,
	Callback = function(v)
		Library.BackgroundBlur = v
		Library:Toggle(Library.Visible)
	end,
})
InterfaceSection:AddToggle({
	Name = "Tooltips",
	Default = Library.ShowTooltips,
	Callback = function(v)
		Library.ShowTooltips = v
	end,
})
InterfaceSection:AddButton({
	Name = "Unload",
	Callback = function()
		Library:Unload()
	end,
})

if typeof(queue_on_teleport) == "function" then
	local queued = false
	LocalPlayer.OnTeleport:Connect(function(state)
		if state == Enum.TeleportState.Failed then
			queued = false
			return
		end
		if not session.Rerun or queued then
			return
		end
		queued = true
		pcall(function()
			Library:SaveConfig(TRANSFER_CONFIG)
		end)
		if filesOk() then
			pcall(writefile, STAMP_FILE, tostring(os.time()))
		end
		pcall(queue_on_teleport, 'loadstring(game:HttpGet("' .. LOADER_URL .. '"))()')
	end)
end

local okF, errF = pcall(function()
	Library.Features = (function()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

return function(Library)
	local LocalPlayer = Players.LocalPlayer

	local Config = {

		AutoGreen = {
			Characters = function() return workspace:FindFirstChild("Characters") end,
			ShootRemote = function()
				local r = ReplicatedStorage
				for _, n in ipairs({ "Aero", "AeroRemoteServices", "InputService", "Shoot" }) do
					r = r and r:FindFirstChild(n)
				end
				return r
			end,
			MeterEvent = function()
				local r = ReplicatedStorage
				for _, n in ipairs({ "Aero", "AeroRemoteServices", "GameplayService", "Meter" }) do
					r = r and r:FindFirstChild(n)
				end
				return r
			end,
			ShootArgs = { { Shoot = false } },
			Meters = { Vertical = {} },
		},

		Stamina = nil,
		Rebound = nil,
		Steal   = nil,
		Block   = nil,
	}

	local Recipes = {
		AutoGuard = "Unknown how this game moves characters. Find the movement/input remote or BodyMover in Dex while guarding, and the attribute/value that marks the ball handler.",
		DribbleSpeed = "Find the dribble move remote/animation in Dex or SimpleSpy while dribbling, then the speed value it reads (attribute, NumberValue or module constant).",
		DribbleGlide = "Same as Dribble Speed: find what controls movement during a dribble move (velocity/BodyMover) and its duration.",
		Speed = "Check if Humanoid.WalkSpeed is used (watch it in Dex) or a custom mover under Characters.<you>. Set Config.Speed once known.",
		Stamina = "Dex: Characters.<you> and PlayerGui, find the stamina NumberValue/Attribute while dribbling (it should drop). Set Config.Stamina = { Get = ..., Max = ... }.",
		Rebound = "SimpleSpy: grab a rebound, note the remote + args. Dex: find the ball part. Set Config.Rebound.",
		Steal = "SimpleSpy: perform a steal, note the remote + args. Find how the ball handler is marked. Set Config.Steal.",
		Block = "SimpleSpy: perform a block, note the remote + args. Find how the shooter is marked. Set Config.Block.",
	}

	local function myRoot()
		local folder = Config.AutoGreen.Characters()
		local char = (folder and folder:FindFirstChild(LocalPlayer.Name)) or LocalPlayer.Character
		return char and char:FindFirstChild("HumanoidRootPart")
	end

	local function finite(n)
		return typeof(n) == "number" and n == n and n ~= math.huge and n ~= -math.huge
	end

	local function flag(name)
		return Library.Flags[name]
	end

	local function gated(name, cfg)

		if cfg then
			return true
		end
		Library:Notify({ Title = name, Content = "Not configured: " .. (Recipes[name] or "unmeasured values"), Type = "Error", Duration = 8 })
		return false
	end

	local Modules = {}

	do
		local conns, reported = {}, {}
		local alive = false
		local active, mtype, grad = false, nil, nil
		local armed, fired, startedAt, dbgAt = false, false, 0, 0

		local function dbg(...)
			if flag("GreenDebug") then
				_N("[AutoGreen]", ...)
			end
		end

		local function clear()
			for k, c in pairs(conns) do
				c:Disconnect()
				conns[k] = nil
			end
			active, mtype, grad = false, nil, nil
		end

		local function getPing()
			local ok, v = pcall(function()
				return game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()
			end)
			if ok and v then
				return math.floor(v)
			end
			return math.floor(LocalPlayer:GetNetworkPing() * 2000)
		end

		local function myChar()
			local folder = Config.AutoGreen.Characters()
			return folder and folder:FindFirstChild(LocalPlayer.Name)
		end

		local function findGradient(char, t)
			local name = tostring(t) .. "Meter"
			local gui
			for _, partName in ipairs({ "HumanoidRootPart", "Head" }) do
				local p = char:FindFirstChild(partName)
				gui = gui or (p and p:FindFirstChild(name))
			end
			return gui and gui:FindFirstChild("FillGradient", true)
		end

		local function onMeterEvent(on, c, t)
			if not alive or c ~= myChar() then
				return
			end
			dbg("Meter event", tostring(on), tostring(t))
			if on and t and t ~= "None" then
				active, mtype = true, t
				armed, fired, startedAt = false, false, os.clock()
				grad = findGradient(c, t)
				if not Config.AutoGreen.Meters[t] and t ~= "Vertical" and not reported[t] then
					reported[t] = true
				end
			else
				active = false
			end
		end

		local function step()
			if not active then
				return
			end
			local char = myChar()
			if not char then
				return
			end
			local mcfg = Config.AutoGreen.Meters[mtype] or {}
			local v = char:GetAttribute("meterOffset")
			local y = typeof(v) == "Vector2" and v.Y or v
			if not finite(y) then
				if not (grad and grad.Parent) then
					grad = findGradient(char, mtype)
				end
				y = grad and grad.Offset.Y
			end
			if not finite(y) then
				return
			end
			local perfect = mcfg.Perfect or flag("GreenPerfect") or -1.5
			local margin = mcfg.Margin or flag("GreenMargin") or 0.15
			local thr = perfect + margin
			if flag("GreenPing") ~= false then

				thr += 3.2 * (getPing() - (flag("GreenRefPing") or 75)) / 1000
			end
			if os.clock() - dbgAt > 0.25 then
				dbgAt = os.clock()
				dbg(("type=%s y=%.3f thr=%.3f armed=%s fired=%s attr=%s rot=%s"):format(tostring(mtype), y, thr, tostring(armed), tostring(fired), tostring(v), tostring(char:GetAttribute("meterRotation"))))
			end

			if y > thr + 0.25 then
				armed = true
			end
			if not fired and (armed or os.clock() - startedAt > 0.8) and y <= thr then
				fired = true
				local remote = Config.AutoGreen.ShootRemote()
				if remote then
					dbg("RELEASE at y=" .. y)
					remote:FireServer(unpack(Config.AutoGreen.ShootArgs))
				end
			end
		end

		local origConns = {}
		local function origHook()
			pcall(function()
				local char = myChar()
				local hrp = char and char:FindFirstChild("HumanoidRootPart")
				local meter = hrp and hrp:FindFirstChild("VerticalMeter")
				local fill = meter and meter:FindFirstChild("Meter_Fill")
				local g = fill and fill:FindFirstChild("FillGradient")
				if not g or origConns[g] then
					return
				end
				local oArmed, oReleased, enabledAt = false, false, meter.Enabled and os.clock() or 0
				origConns[meter] = meter:GetPropertyChangedSignal("Enabled"):Connect(function()
					oArmed, oReleased = false, false
					if meter.Enabled then
						enabledAt = os.clock()
					end
				end)
				origConns[g] = g:GetPropertyChangedSignal("Offset"):Connect(function()
					if not alive or not meter.Enabled or oReleased then
						return
					end
					local threshold = (flag("GreenPerfect") or -1.5) + (flag("GreenMargin") or 0.15)
					if flag("GreenPing") ~= false then
						threshold += 3.2 * (getPing() - (flag("GreenRefPing") or 75)) / 1000
					end
					local y = g.Offset.Y
					if y > threshold + 0.25 then
						oArmed = true
					end
					if (oArmed or os.clock() - enabledAt > 0.8) and y <= threshold then
						oReleased = true
						local remote = Config.AutoGreen.ShootRemote()
						if remote then
							remote:FireServer(unpack(Config.AutoGreen.ShootArgs))
						end
					end
				end)
			end)
		end

		Modules.AutoGreen = {
			Flag = "AutoTime",
			Start = function()
				if not Config.AutoGreen.ShootRemote() then
					Library:Notify({ Title = "Auto Time", Content = "Shoot remote not found (Aero/AeroRemoteServices/InputService/Shoot).", Type = "Error" })
					return false
				end
				if false then
					alive = true
					task.spawn(function()
						while alive do
							origHook()
							for k, c in pairs(origConns) do
								if not k:IsDescendantOf(game) then
									c:Disconnect()
									origConns[k] = nil
								end
							end
							task.wait(1)
						end
					end)
					return true
				end
				do return true end
				local ev = Config.AutoGreen.MeterEvent()
				if not ev then
					Library:Notify({ Title = "Auto Time", Content = "Meter event not found (GameplayService.Meter).", Type = "Error" })
					return false
				end
				alive = true
				conns.event = ev.OnClientEvent:Connect(onMeterEvent)
				conns.step = RunService.RenderStepped:Connect(step)
				dbg("started")
				return true
			end,
			Stop = function()
				alive = false
				clear()
				for k, c in pairs(origConns) do
					c:Disconnect()
					origConns[k] = nil
				end
			end,
		}
	end

	do
		local BIND = "7100_InfStamina"
		local lastFull

		local function myRing()
			local node = workspace
			for _, n in ipairs({ "Assets", "Functionals", "Stamina", "Meters" }) do
				node = node and node:FindFirstChild(n)
			end
			local root = myRoot()
			if not (node and root) then
				return nil
			end
			local best, bestD = nil, 2
			for _, m in ipairs(node:GetChildren()) do
				local gui = m:IsA("BasePart") and m.Name ~= "Directional" and m:FindFirstChild("SurfaceGui")
				if gui then
					local dx, dz = m.Position.X - root.Position.X, m.Position.Z - root.Position.Z
					local d = math.sqrt(dx * dx + dz * dz)
					if d < bestD then
						best, bestD = gui, d
					end
				end
			end
			return best
		end

		Modules.InfStamina = {
			Flag = "InfStamina",
			Start = function()
				lastFull = nil
				RunService:BindToRenderStep(BIND, Enum.RenderPriority.Last.Value + 1, function()
					local gui = myRing()
					local cur = gui and gui:FindFirstChild("UIGradient", true)
					if not cur then
						return
					end
					local folder = Config.AutoGreen.Characters()
					local char = folder and folder:FindFirstChild(LocalPlayer.Name)
					local stamina, maxStamina = char and char:GetAttribute("Stamina"), char and char:GetAttribute("MaxStamina")
					if finite(stamina) and finite(maxStamina) and stamina >= maxStamina - 0.5 then
						lastFull = cur.Rotation
						return
					end
					local full = lastFull
					if not full then
						local maxGrad = gui:FindFirstChild("MaxGradient", true)
						full = maxGrad and maxGrad.Rotation
					end
					if finite(full) then
						cur.Rotation = full
					end
				end)
				return true
			end,
			Stop = function()
				pcall(RunService.UnbindFromRenderStep, RunService, BIND)
			end,
		}
	end

	local WalkWriter = { base = nil, last = nil, wants = {}, conns = {} }

	local attrCtl
	local function walkChar()
		local folder = Config.AutoGreen.Characters()
		return folder and folder:FindFirstChild(LocalPlayer.Name)
	end
	local function gameAttrs()
		local char = walkChar()
		if not char then
			return nil
		end
		if not attrCtl then
			local r = LocalPlayer:FindFirstChild("PlayerScripts")
			for _, n in ipairs({ "Aero", "Controllers", "Attributes" }) do
				r = r and r:FindFirstChild(n)
			end
			if r and r:IsA("ModuleScript") then
				local ok, m = pcall(require, r)
				if ok and type(m) == "table" then
					attrCtl = m
				end
			end
		end
		if not attrCtl or type(attrCtl.Get) ~= "function" then
			return nil
		end
		local ok, t = pcall(attrCtl.Get, attrCtl, char)
		return ok and type(t) == "table" and t or nil
	end
	local function walkStep()
		local attrs = gameAttrs()
		local cur = attrs and attrs.WalkSpeed
		if not finite(cur) then
			return
		end
		if WalkWriter.last == nil or math.abs(cur - WalkWriter.last) > 1e-6 then
			WalkWriter.base = cur
		end
		local target
		for _, name in ipairs({ "Speed", "Legit" }) do
			local w = WalkWriter.wants[name]
			target = w and w(WalkWriter.base, attrs)
			if target then
				break
			end
		end
		if target then
			WalkWriter.last = target
			attrs.WalkSpeed = target
		elseif WalkWriter.last ~= nil then
			if cur == WalkWriter.last then
				attrs.WalkSpeed = WalkWriter.base
			end
			WalkWriter.last = nil
		end
	end
	local function setWant(name, fn)
		WalkWriter.wants[name] = fn
		if next(WalkWriter.wants) ~= nil then
			if #WalkWriter.conns == 0 then
				if not gameAttrs() then
					Library:Notify({ Title = "Speed", Content = "Controllers.Attributes not reachable: the game's WalkSpeed can't be written.", Type = "Error" })
				end

				table.insert(WalkWriter.conns, RunService.Heartbeat:Connect(walkStep))
				table.insert(WalkWriter.conns, RunService.RenderStepped:Connect(walkStep))
			end
		else
			for _, c in ipairs(WalkWriter.conns) do
				c:Disconnect()
			end
			WalkWriter.conns = {}
			local attrs = gameAttrs()
			if attrs and WalkWriter.last ~= nil and WalkWriter.base and attrs.WalkSpeed == WalkWriter.last then
				attrs.WalkSpeed = WalkWriter.base
			end
			WalkWriter.base, WalkWriter.last = nil, nil
		end
	end

	do
		local conn
		local originals = {}
		local WALK_CAP = 17

		local function controller()
			local r = LocalPlayer:FindFirstChild("PlayerScripts")
			for _, n in ipairs({ "Aero", "Controllers", "Player" }) do
				r = r and r:FindFirstChild(n)
			end
			if not (r and r:IsA("ModuleScript")) then
				return nil
			end
			local ok, mod = pcall(require, r)
			return ok and type(mod) == "table" and mod or nil
		end

		local function setRating(tbl, key, value)
			if type(tbl) ~= "table" or not finite(value) then
				return
			end
			originals[tbl] = originals[tbl] or {}
			if originals[tbl][key] == nil then
				originals[tbl][key] = tbl[key]
			end
			tbl[key] = math.clamp(value, 25, 99)
		end

		local function restore()
			for tbl, keys in pairs(originals) do
				for k, v in pairs(keys) do
					tbl[k] = v
				end
			end
			originals = {}
		end

		Modules.LegitSpeed = {

			MatchBuild = function()
				local ctl = controller()
				local slot = ctl and ctl.SlotData
				local attrs = type(slot) == "table" and slot.Attributes
				if type(attrs) ~= "table" then
					Library:Notify({ Title = "Legit Speed", Content = "Build ratings not loaded yet.", Type = "Error" })
					return
				end
				local function real(tbl, key)
					if type(tbl) ~= "table" then
						return nil
					end
					local o = originals[tbl]
					if o and o[key] ~= nil then
						return o[key]
					end
					return tbl[key]
				end
				local map = {
					{ "LegitSpeedRating", real(attrs.Physicals, "Speed"), "Speed" },
					{ "LegitBallHandle", real(attrs.Playmaking, "BallHandle"), "Ball Handle" },
					{ "LegitAccel", real(attrs.Physicals, "Acceleration"), "Acceleration" },
					{ "LegitLateral", real(attrs.Defense, "LateralSpeed"), "Lateral" },
				}
				local shown = {}
				for _, m in ipairs(map) do
					local opt = Library.Options[m[1]]
					if opt and finite(m[2]) then
						opt:Set(m[2])
						table.insert(shown, m[3] .. " " .. tostring(m[2]))
					end
				end
				Library:Notify({ Title = "Legit Speed", Content = "Matched your build: " .. table.concat(shown, ", "), Type = "Success" })
			end,
			Flag = "LegitSpeed",
			Start = function()
				if not controller() then
					Library:Notify({ Title = "Legit Speed", Content = "Controllers.Player module not reachable.", Type = "Error" })
					return false
				end
				conn = RunService.Heartbeat:Connect(function()
					local ctl = controller()
					local slot = ctl and ctl.SlotData
					local attrs = type(slot) == "table" and slot.Attributes
					if type(attrs) ~= "table" then
						return
					end
					setRating(attrs.Physicals, "Acceleration", flag("LegitAccel"))
					setRating(attrs.Defense, "LateralSpeed", flag("LegitLateral"))
					setRating(attrs.Playmaking, "BallHandle", flag("LegitBallHandle"))
				end)
				setWant("Legit", function(base)
					local ctl = controller()
					local slot = ctl and ctl.SlotData
					local attrs = type(slot) == "table" and slot.Attributes
					local sr = attrs and attrs.Physicals and attrs.Physicals.Speed
					if not (finite(sr) and sr > 0 and finite(base)) then
						return nil
					end
					local target = base * (math.clamp(flag("LegitSpeedRating") or sr, 25, 99) / sr)
					return math.min(target, math.max(base, WALK_CAP))
				end)
				return true
			end,
			Stop = function()
				if conn then
					conn:Disconnect()
					conn = nil
				end
				setWant("Legit", nil)
				restore()
			end,
		}
	end

	do
		local active = { screen = false, ball = false, guard = false, sprint = false }
		local movementObj, lastFind, warnedGetgc = nil, 0, false

		local function getMovement()
			if movementObj and movementObj.Root and movementObj.Root.Parent then
				return movementObj
			end
			movementObj = nil
			if typeof(getgc) ~= "function" then
				if not warnedGetgc then
					warnedGetgc = true
					Library:Notify({ Title = "Speed", Content = "No getgc: Guard/Boxout speed can't detect your movement state.", Type = "Error" })
				end
				return nil
			end
			if os.clock() - lastFind < 3 then
				return nil
			end
			lastFind = os.clock()
			for _, v in ipairs(getgc(true)) do
				if type(v) == "table" and rawget(v, "CurrentMovementType") ~= nil and rawget(v, "WalkSpring") ~= nil and rawget(v, "Root") ~= nil then
					movementObj = v
					return v
				end
			end
			return nil
		end

		local function guarding(mt)
			return mt == "Guard" or mt == "Boxout" or mt == "BoxoutPlayer"
		end

		local function speedWant(base, attrs)
			local mv = (active.guard and getMovement()) or movementObj
			local mt = mv and mv.CurrentMovementType
			local screening = attrs.Screening
			local ball = attrs.Basketball
			local target
			if active.screen and screening then
				target = flag("ScreenSpeedVal")
			elseif active.ball and ball and not screening then
				target = flag("BallSpeedVal")
			elseif active.guard and guarding(mt) then
				target = flag("GuardSpeedVal")
			end
			if active.sprint and attrs.Sprinting == true then
				target = (target or base) + 3.35 * (flag("SprintBoostPct") or 0) / 100
			end
			if not finite(target) then
				return nil
			end
			local cap = guarding(mt) and 14 or 17
			return math.clamp(target, 0, math.max(cap, base))
		end

		local function refresh()
			if active.screen or active.ball or active.guard or active.sprint then
				setWant("Speed", speedWant)
			else
				setWant("Speed", nil)
			end
		end

		local function speedModule(flagName, key)
			Modules["Speed_" .. key] = {
				Flag = flagName,
				Start = function()
					active[key] = true
					refresh()
					return true
				end,
				Stop = function()
					active[key] = false
					refresh()
				end,
			}
		end
		speedModule("ScreenSpeed", "screen")
		speedModule("BallSpeed", "ball")
		speedModule("GuardSpeed", "guard")
		speedModule("SprintBoost", "sprint")
	end

	do
		local active = { boost = false, glide = false, postGlide = false }
		local conns = {}
		local boostSaved, glideBase, glideLast
		local BOOST_TIME = 0.6

		local function restore(attrs)
			if attrs then
				if boostSaved then
					attrs.SpeedBoost, attrs.SpeedBoostTime = boostSaved.SpeedBoost, boostSaved.SpeedBoostTime
				end
				if glideLast and attrs.ServerVelocity == glideLast then
					attrs.ServerVelocity = glideBase
				end
			end
			boostSaved, glideBase, glideLast = nil, nil, nil
		end

		local function step()
			local attrs = gameAttrs()
			if not attrs then
				return
			end
			if active.boost then
				if not boostSaved then
					boostSaved = { SpeedBoost = attrs.SpeedBoost, SpeedBoostTime = attrs.SpeedBoostTime }
				end
				local walk = math.min(finite(attrs.WalkSpeed) and attrs.WalkSpeed or 14, 17)
				local room = math.max(0, 26 - (walk + 3.35))
				attrs.SpeedBoost = math.min(flag("DribbleBoostPower") or 0, room)
				attrs.SpeedBoostTime = math.max(BOOST_TIME, boostSaved.SpeedBoostTime or 0)
			end
			local sv = attrs.ServerVelocity
			if typeof(sv) == "Vector3" then
				if glideLast == nil or sv ~= glideLast then
					glideBase = sv
				end
				local factor
				if active.glide and attrs.Action == "Dribbling" then
					factor = 1 + (flag("DribbleGlidePower") or 0) / 100
				elseif active.postGlide and attrs.InPost then
					factor = 1 + (flag("PostGlidePower") or 0) / 100
				end
				if factor and factor > 1 then
					local v = glideBase * factor
					if v.Magnitude > 26 then
						v = v.Unit * 26
					end
					glideLast = v
					attrs.ServerVelocity = v
				elseif glideLast then
					if sv == glideLast then
						attrs.ServerVelocity = glideBase
					end
					glideLast = nil
				end
			elseif glideLast then
				glideLast = nil
			end
		end

		local function refresh()
			local any = active.boost or active.glide or active.postGlide
			if any and #conns == 0 then
				if not gameAttrs() then
					Library:Notify({ Title = "Dribble", Content = "Controllers.Attributes not reachable.", Type = "Error" })
				end
				table.insert(conns, RunService.Heartbeat:Connect(step))
				table.insert(conns, RunService.RenderStepped:Connect(step))
			elseif not any then
				for _, c in ipairs(conns) do
					c:Disconnect()
				end
				conns = {}
				restore(gameAttrs())
			end
		end

		local function dribbleModule(flagName, key)
			Modules["Dribble_" .. key] = {
				Flag = flagName,
				Start = function()
					active[key] = true
					refresh()
					return true
				end,
				Stop = function()
					active[key] = false
					if key == "boost" and boostSaved then
						local attrs = gameAttrs()
						if attrs then
							attrs.SpeedBoost, attrs.SpeedBoostTime = boostSaved.SpeedBoost, boostSaved.SpeedBoostTime
						end
						boostSaved = nil
					end
					refresh()
				end,
			}
		end
		dribbleModule("DribbleBoost", "boost")
		dribbleModule("DribbleGlide", "glide")
		dribbleModule("PostGlide", "postGlide")
	end

	do
		local active = { shot = false, block = false }
		local conns = {}
		local base, last, lastAction
		local movementObj, lastFind = nil, 0

		local function inputDir()
			if not (movementObj and movementObj.Root and movementObj.Root.Parent) then
				movementObj = nil
				if typeof(getgc) ~= "function" or os.clock() - lastFind < 3 then
					return nil
				end
				lastFind = os.clock()
				for _, v in ipairs(getgc(true)) do
					if type(v) == "table" and rawget(v, "CurrentMovementType") ~= nil and rawget(v, "WalkSpring") ~= nil and rawget(v, "Root") ~= nil then
						movementObj = v
						break
					end
				end
			end
			local d = movementObj and movementObj.MoveDirection
			if typeof(d) == "Vector3" and d.Magnitude > 0.1 then
				return Vector3.new(d.X, 0, d.Z).Unit
			end
			return nil
		end

		local function inList(list, value)
			if type(list) == "table" then
				for _, v in ipairs(list) do
					if v == value then
						return true
					end
				end
			end
			return false
		end

		local function step()
			local attrs = gameAttrs()
			if not attrs then
				return
			end
			local action = attrs.Action
			if flag("GlideDebug") and action ~= lastAction then
				lastAction = action
				_N("[Glide] Action =", tostring(action), "| ServerVelocity =", tostring(attrs.ServerVelocity))
			end
			local sv = attrs.ServerVelocity
			if typeof(sv) ~= "Vector3" then
				last = nil
				return
			end
			if last == nil or sv ~= last then
				base = sv
			end
			local speed
			if active.shot and inList(flag("ShotGlideFor"), action) then
				speed = flag("ShotGlideSpeed")
			elseif active.block and action == "Blocking" then
				speed = flag("BlockGlideSpeed")
			end
			local applied = false
			if finite(speed) and speed > 0 then
				local dir = (base.Magnitude > 0.5 and base.Unit) or inputDir()
				if dir then
					local v = dir * math.min(math.max(base.Magnitude, speed), 26)
					last = v
					attrs.ServerVelocity = v
					applied = true
				end
			end
			if not applied and last then
				if sv == last then
					attrs.ServerVelocity = base
				end
				last = nil
			end
		end

		local function refresh()
			local any = active.shot or active.block
			if any and #conns == 0 then
				if not gameAttrs() then
					Library:Notify({ Title = "Glide", Content = "Controllers.Attributes not reachable.", Type = "Error" })
				end
				table.insert(conns, RunService.Heartbeat:Connect(step))
				table.insert(conns, RunService.RenderStepped:Connect(step))
			elseif not any then
				for _, c in ipairs(conns) do
					c:Disconnect()
				end
				conns = {}
				local attrs = gameAttrs()
				if attrs and last and attrs.ServerVelocity == last then
					attrs.ServerVelocity = base
				end
				base, last = nil, nil
			end
		end

		local function glideModule(flagName, key)
			Modules["Glide_" .. key] = {
				Flag = flagName,
				Start = function()
					active[key] = true
					refresh()
					return true
				end,
				Stop = function()
					active[key] = false
					refresh()
				end,
			}
		end
		glideModule("ShotGlide", "shot")
		glideModule("BlockGlide", "block")
	end

	do
		local active = { dunk = false, jump = false, hop = false }
		local conn
		local stateObj, lastFind = nil, 0

		local function getCharacterState()
			if stateObj and stateObj.ProxyCharacter and stateObj.ProxyCharacter.Parent and stateObj.MovementPosition and stateObj.MovementPosition.Parent then
				return stateObj
			end
			stateObj = nil
			if typeof(getgc) ~= "function" or os.clock() - lastFind < 3 then
				return nil
			end
			lastFind = os.clock()
			for _, v in ipairs(getgc(true)) do
				if type(v) == "table" and rawget(v, "MovementPosition") ~= nil and rawget(v, "MainMovementPosition") ~= nil and rawget(v, "ProxyCharacter") ~= nil then
					stateObj = v
					break
				end
			end
			return stateObj
		end

		local shotHolding, shotUntil = false, 0

		local SHOT_WINDOW = 0.9
		Library.OnShoot = function(kind)
			if kind == "start" then
				shotHolding = true
			elseif kind == "release" then
				shotHolding = false
				shotUntil = os.clock() + SHOT_WINDOW
			end
		end
		local lastAction
		local lift, lastT, dbgAt = 0, os.clock(), 0

		local told = { lift = false, state = false }
		local function apply()
			local now = os.clock()
			local dt = math.min(now - lastT, 0.1)
			lastT = now
			local attrs = gameAttrs()
			if not attrs then
				return
			end
			local action = attrs.Action
			if flag("HeightDebug") and action ~= lastAction then
				lastAction = action
				_N("[Height] Action =", tostring(action))
			end
			local target = 0
			if active.dunk and action == "Dunking" then
				target = flag("DunkVertExtra") or 0
			elseif active.jump and (shotHolding or now < shotUntil or action == "Shooting") then
				target = flag("JumpshotExtra") or 0
			elseif active.hop and action == "Hopstep" then
				target = flag("HopstepExtra") or 0
			end
			target = math.clamp(finite(target) and target or 0, 0, 8)
			lift = lift + (target - lift) * math.min(1, dt * 10)
			if lift < 0.02 then
				if target == 0 then
					lift = 0
				end
				return
			end
			local st = getCharacterState()
			local main, proxy = st and st.MainMovementPosition, st and st.MovementPosition
			if not (main and proxy and main.Parent and proxy.Parent) then
				if not told.state then
					told.state = true
					Library:Notify({ Title = "Height", Content = "Character state not found (needs getgc).", Type = "Error" })
				end
				return
			end
			local mp = main.Position
			local inAir = main.MaxForce.Y ~= 0
			local baseY = inAir and mp.Y or st.lastValidHeight
			if not finite(baseY) then
				return
			end

			local mass = st.ProxyCharacter and st.ProxyCharacter.AssemblyMass or 0
			proxy.MaxForce = Vector3.new(main.MaxForce.X, math.max(mass * 2250, main.MaxForce.Y), main.MaxForce.Z)
			proxy.Position = Vector3.new(mp.X, baseY + lift, mp.Z)
			if not inAir then
				proxy.P, proxy.D = 15500, 400
			end
			if not told.lift then
				told.lift = true
			end
			if flag("HeightDebug") and now - dbgAt > 0.25 then
				dbgAt = now
				_N(("[Height] action=%s lift=%.2f inAir=%s baseY=%.2f proxy.Y=%.2f target.Y=%.2f"):format(
					tostring(action), lift, tostring(inAir), baseY, proxy.Position.Y, baseY + lift))
			end
		end

		local function refresh()
			if (active.dunk or active.jump or active.hop) and not conn then
				if typeof(getgc) ~= "function" then
					Library:Notify({ Title = "Jump Height", Content = "Needs getgc to find your character state.", Type = "Error" })
				end
				conn = RunService.Stepped:Connect(function()
					task.defer(apply)
				end)
			elseif not (active.dunk or active.jump or active.hop) and conn then
				conn:Disconnect()
				conn = nil
			end
		end

		local function heightModule(flagName, key)
			Modules["Height_" .. key] = {
				Flag = flagName,
				Start = function()
					active[key] = true
					refresh()
					return true
				end,
				Stop = function()
					active[key] = false
					refresh()
				end,
			}
		end
		heightModule("DunkVert", "dunk")
		heightModule("JumpshotHeight", "jump")
		heightModule("HopstepHeight", "hop")
	end

	do
		local hooked, remote, Buf = false, nil, nil
		local on = false
		local lastMode, reason = nil, ""
		local ballCache, ballAt = false, 0
		local frozenState
		local original, lookConn, dummy = {}, nil, nil

		local function myModel()
			local folder = Config.AutoGreen.Characters()
			return folder and folder:FindFirstChild(LocalPlayer.Name)
		end

		local function ballNear(x, y, z)
			local now = os.clock()
			if now - ballAt < 0.1 then
				return ballCache
			end
			ballAt, ballCache = now, false
			local balls = workspace:FindFirstChild("Basketballs")
			if balls then
				local me = Vector3.new(x, y, z)
				local range = flag("DesyncNearBall") or 40
				for _, b in ipairs(balls:GetChildren()) do
					local ok, cf = pcall(b.GetPivot, b)
					if ok and (cf.Position - me).Magnitude < range then
						ballCache = true
						break
					end
				end
			end
			return ballCache
		end

		local function needReal(x, y, z)
			if flag("DesyncReal") == true then
				reason = "Be Real key held"
				return true
			end
			local char = myModel()
			if char then
				if char:GetAttribute("Basketball") then
					reason = "you hold the ball"
					return true
				end
				local action = char:GetAttribute("Action")
				if action and action ~= "" and action ~= "Moving" then
					reason = "action " .. tostring(action)
					return true
				end
			end
			if ballNear(x, y, z) then
				reason = "a ball is near"
				return true
			end
			return false
		end

		local function process(buf)
			local R = workspace:GetAttribute("Gamemode") == "Plaza" and 4000 or 1000
			local r = Buf.reader(buf)
			local t = Buf.Float64.Read(r)
			local x = Buf.RangedFloat16.Read(r, -R, R)
			local y = Buf.RangedFloat16.Read(r, -R, R)
			local z = Buf.RangedFloat16.Read(r, -R, R)
			local vx = Buf.Int8.Read(r)
			local vz = Buf.Int8.Read(r)
			local yaw = Buf.UInt8.Read(r)

			local real = needReal(x, y, z)
			local mode = real and "REAL" or "HIDDEN"
			if mode ~= lastMode then
				lastMode = mode
				if flag("DesyncDebug") then
					task.defer(_N, "[Desync] now sending " .. mode .. (real and (" (" .. reason .. ")") or ""))
				end
			end
			if real then
				return nil
			end

			local freeze = flag("DesyncMode") == "Freeze"
			if freeze then
				frozenState = frozenState or { x = x, y = y, z = z, yaw = yaw }
				x, y, z, yaw, vx, vz = frozenState.x, frozenState.y, frozenState.z, frozenState.yaw, 0, 0
			else
				frozenState = nil
				y = math.clamp(y + (flag("DesyncSky") or 950), -R + 1, R - 1)
			end

			local w = Buf.writer()
			Buf.Float64.Write(w, t)
			Buf.RangedFloat16.Write(w, x, -R, R)
			Buf.RangedFloat16.Write(w, y, -R, R)
			Buf.RangedFloat16.Write(w, z, -R, R)
			Buf.Int8.Write(w, vx)
			Buf.Int8.Write(w, vz)
			Buf.UInt8.Write(w, yaw)
			return w:ToBuffer()
		end

		local function ensureHook()
			if hooked then
				return true
			end
			if typeof(hookmetamethod) ~= "function" or typeof(getnamecallmethod) ~= "function" then
				Library:Notify({ Title = "Desync", Content = "Needs hookmetamethod.", Type = "Error" })
				return false
			end
			remote = ReplicatedStorage:FindFirstChild("Replication")
			local m = ReplicatedStorage
			for _, n in ipairs({ "Aero", "Shared", "Replication", "Buffer" }) do
				m = m and m:FindFirstChild(n)
			end
			if m and m:IsA("ModuleScript") then
				local ok, mod = pcall(require, m)
				Buf = ok and type(mod) == "table" and mod or nil
			end
			if not (remote and Buf and Buf.reader and Buf.writer) then
				Library:Notify({ Title = "Desync", Content = "Replication remote or Buffer module not found.", Type = "Error" })
				return false
			end
			local old
			old = hookmetamethod(game, "__namecall", (newcclosure or function(f) return f end)(function(self, ...)
				if on and self == remote and getnamecallmethod() == "FireServer" then
					local arg = ...
					if typeof(arg) == "buffer" then
						local ok, res = pcall(process, arg)
						if ok and res ~= nil then
							return old(self, res)
						end
					end
				end
				return old(self, ...)
			end))
			hooked = true
			return true
		end

		local function applyLook()
			local model = myModel()
			if not model then
				return
			end
			local alpha = math.clamp((flag("DesyncAlpha") or 60) / 100, 0, 1)
			for _, d in ipairs(model:GetDescendants()) do
				if (d:IsA("BasePart") and d.Name ~= "HumanoidRootPart") or d:IsA("Decal") or d:IsA("Texture") then
					if original[d] == nil then
						original[d] = d.Transparency
					end
					if original[d] < 1 then
						d.Transparency = math.max(original[d], alpha)
					end
				end
			end
		end
		local function setLook(enabled)
			if enabled and not lookConn then
				local acc = 0
				lookConn = RunService.RenderStepped:Connect(function(dt)
					acc += dt
					if acc >= 0.25 then
						acc = 0
						applyLook()
					end
				end)
				applyLook()
			elseif not enabled then
				if lookConn then
					lookConn:Disconnect()
					lookConn = nil
				end
				for inst, value in pairs(original) do
					if inst.Parent then
						inst.Transparency = value
					end
				end
				original = {}
			end
		end

		local function destroyDummy()
			if dummy then
				dummy:Destroy()
				dummy = nil
			end
		end
		local function createDummy()
			destroyDummy()
			local model = myModel()
			if not model then
				return
			end
			local was = model.Archivable
			model.Archivable = true
			local ok, c = pcall(model.Clone, model)
			model.Archivable = was
			if not ok or not c then
				return
			end
			for _, d in ipairs(c:GetDescendants()) do
				if d:IsA("BaseScript") or d:IsA("BillboardGui") or d:IsA("SurfaceGui") or d:IsA("BodyMover") or d:IsA("Constraint")
					or d:IsA("AlignPosition") or d:IsA("AlignOrientation") or d:IsA("Sound") then
					d:Destroy()
				elseif d:IsA("BasePart") then
					d.Anchored, d.CanCollide, d.CanQuery, d.CanTouch = true, false, false, false
				elseif d:IsA("Humanoid") then
					d.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
					d.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
				end
			end
			c.Name = "7100_OriginalPosition"
			c.Parent = workspace.CurrentCamera
			c:PivotTo(model:GetPivot())
			dummy = c
		end

		Modules.Desync = {
			Flag = "Desync",
			Start = function()
				if not ensureHook() then
					return false
				end
				frozenState, lastMode = nil, nil
				on = true
				createDummy()
				setLook(true)
				return true
			end,
			Stop = function()
				on = false
				setLook(false)
				destroyDummy()
			end,
		}
	end

	do
		local conn
		local lastFire, acc, dbgAt = 0, 0, 0
		local told = false

		local function remote()
			local r = ReplicatedStorage
			for _, n in ipairs({ "Aero", "AeroRemoteServices", "InputService", "Steal" }) do
				r = r and r:FindFirstChild(n)
			end
			return r
		end

		local function inList(list, value)
			if type(list) == "table" then
				for _, v in ipairs(list) do
					if v == value then
						return true
					end
				end
			end
			return false
		end

		local function targetOk(c)
			local action = c:GetAttribute("Action")
			local list = flag("StealOn")
			if inList(list, "Dribbling") and action == "Dribbling" then
				return true
			end
			if inList(list, "Gathering") and action == "Gathering" then
				return true
			end
			if inList(list, "Triple Threat") and (c:GetAttribute("TripleThreat") or action == "TripleThreat") then
				return true
			end
			if inList(list, "Idle") and (action == nil or action == "" or action == "Moving") then
				return true
			end
			return false
		end

		local function step(dt)
			acc += dt
			if acc < 0.1 then
				return
			end
			acc = 0
			local now = os.clock()
			if now - lastFire < (flag("StealCooldown") or 1.2) then
				return
			end
			local folder = Config.AutoGreen.Characters()
			local me = folder and folder:FindFirstChild(LocalPlayer.Name)
			local myHrp = me and me:FindFirstChild("HumanoidRootPart")
			if not myHrp then
				return
			end
			local myAction = me:GetAttribute("Action")
			if not (myAction == nil or myAction == "" or myAction == "Moving") then
				return
			end
			local myTeam = me:GetAttribute("Team")
			if flag("StealDebug") and now - dbgAt > 1 then
				dbgAt = now
				_N(("[Steal] me: Action=%s Team=%s | range=%s facing=%s"):format(tostring(myAction), tostring(myTeam), tostring(flag("StealRange")), tostring(flag("StealFacing"))))
				for _, c in ipairs(folder:GetChildren()) do
					if c ~= me then
						local h = c:FindFirstChild("HumanoidRootPart")
						_N(("[Steal]   %s: Basketball=%s Team=%s Action=%s dist=%s"):format(
							c.Name, tostring(c:GetAttribute("Basketball")), tostring(c:GetAttribute("Team")), tostring(c:GetAttribute("Action")),
							h and ("%.1f"):format((h.Position - myHrp.Position).Magnitude) or "no HRP"))
					end
				end
			end
			local range = flag("StealRange") or 8
			local best, bestD
			for _, c in ipairs(folder:GetChildren()) do
				if c ~= me and (flag("StealBallOnly") ~= true or c:GetAttribute("Basketball")) then
					local team = c:GetAttribute("Team")
					if flag("StealTeamCheck") ~= true or myTeam == 0 or myTeam == nil or team ~= myTeam then
						local hrp = c:FindFirstChild("HumanoidRootPart")
						if hrp and (flag("StealBallOnly") ~= true or targetOk(c)) then
							local offset = hrp.Position - myHrp.Position
							local d = offset.Magnitude
							if d <= range and d > 0.01 then
								local facing = myHrp.CFrame.LookVector:Dot(Vector3.new(offset.X, 0, offset.Z).Unit)
								if (flag("StealFacing") ~= true or facing > 0.2) and (not bestD or d < bestD) then
									best, bestD = c, d
								end
							end
						end
					end
				end
			end
			if best then
				local r = remote()
				if r then
					lastFire = now
					r:FireServer()
					if not told then
						told = true
					end
				end
			end
		end

		Modules.AutoSteal = {
			Flag = "AutoSteal",
			Start = function()
				if not remote() then
					Library:Notify({ Title = "Auto Steal", Content = "InputService.Steal remote not found.", Type = "Error" })
					return false
				end
				told, lastFire, acc = false, 0, 0
				conn = RunService.Heartbeat:Connect(step)
				return true
			end,
			Stop = function()
				if conn then
					conn:Disconnect()
					conn = nil
				end
			end,
		}
	end

	do
		local conn
		local acc, lastBlock = 0, 0
		local seen = {}
		local told = false
		local dbgAt = 0

		local function attrsFor(model)
			gameAttrs()
			if attrCtl and type(attrCtl.Get) == "function" then
				local ok, tbl = pcall(attrCtl.Get, attrCtl, model)
				if ok and type(tbl) == "table" then
					return tbl
				end
			end
			return nil
		end

		local function remotes()
			local base = ReplicatedStorage
			for _, n in ipairs({ "Aero", "AeroRemoteServices", "InputService" }) do
				base = base and base:FindFirstChild(n)
			end
			return base and base:FindFirstChild("Shoot"), base and base:FindFirstChild("Jump")
		end

		local function doBlock()
			local shoot, jump = remotes()
			if not (shoot and jump) then
				return false
			end
			shoot:FireServer({ Shoot = true, Input = "E", UseSpace = true })
			jump:FireServer()
			task.delay((flag("BlockHold") or 350) / 1000, function()
				shoot:FireServer({ Shoot = false })
			end)
			return true
		end

		local function step(dt)
			acc += dt
			if acc < 0.05 then
				return
			end
			acc = 0
			local now = os.clock()
			local folder = Config.AutoGreen.Characters()
			local me = folder and folder:FindFirstChild(LocalPlayer.Name)
			local myHrp = me and me:FindFirstChild("HumanoidRootPart")
			if not myHrp then
				return
			end
			local mine = attrsFor(me)
			local busy = mine and (mine.Basketball or (mine.Action ~= nil and mine.Action ~= "" and mine.Action ~= "Moving" and mine.Action ~= "Blocking"))
			local range = flag("BlockRange") or 18
			local delay = (flag("BlockDelay") or 150) / 1000
			local myTeam = mine and mine.Team
			for _, c in ipairs(folder:GetChildren()) do
				if c ~= me then
					local a = attrsFor(c)
					local action = a and a.Action
					local hrp = c:FindFirstChild("HumanoidRootPart")
					local dist = hrp and (hrp.Position - myHrp.Position).Magnitude
					if flag("BlockDebug") and now - dbgAt > 1 and action == "Shooting" then
						dbgAt = now
						_N(("[Block] %s is Shooting, dist=%s (range %s), me busy=%s"):format(c.Name, dist and ("%.1f"):format(dist) or "?", tostring(range), tostring(busy)))
					end
					if action == "Shooting" and dist and dist <= range then
						local s = seen[c]
						if not s then
							s = { at = now, done = false }
							seen[c] = s
						end
						local teamOk = flag("BlockTeamCheck") ~= true or myTeam == 0 or myTeam == nil or (a and a.Team) ~= myTeam
						if not s.done and not busy and teamOk and now - s.at >= delay and now - lastBlock >= (flag("BlockCooldown") or 1.5) then
							s.done = true
							if doBlock() then
								lastBlock = now
								if not told then
									told = true
								end
							end
						end
					else
						seen[c] = nil
					end
				end
			end
		end

		Modules.AutoBlock = {
			Flag = "AutoBlock",
			Start = function()
				local shoot, jump = remotes()
				if not (shoot and jump) then
					Library:Notify({ Title = "Auto Block", Content = "InputService.Shoot / Jump remotes not found.", Type = "Error" })
					return false
				end
				if not gameAttrs() then
					Library:Notify({ Title = "Auto Block", Content = "Controllers.Attributes not reachable: can't read other players' Action.", Type = "Error" })
					return false
				end
				acc, lastBlock, told = 0, 0, false
				seen = {}
				conn = RunService.Heartbeat:Connect(step)
				return true
			end,
			Stop = function()
				if conn then
					conn:Disconnect()
					conn = nil
				end
				seen = {}
			end,
		}
	end

	do
		local conn
		local acc, lastFire, dbgAt = 0, 0, 0
		local told = false

		local function attrsFor(model)
			gameAttrs()
			if attrCtl and type(attrCtl.Get) == "function" then
				local ok, tbl = pcall(attrCtl.Get, attrCtl, model)
				if ok and type(tbl) == "table" then
					return tbl
				end
			end
			return nil
		end

		local function remotes()
			local base = ReplicatedStorage
			for _, n in ipairs({ "Aero", "AeroRemoteServices", "InputService" }) do
				base = base and base:FindFirstChild(n)
			end
			return base and base:FindFirstChild("Shoot"), base and base:FindFirstChild("Jump")
		end

		local function ballState(b)
			local part = b:IsA("BasePart") and b or (b:IsA("Model") and (b.PrimaryPart or b:FindFirstChildWhichIsA("BasePart", true)))
			if not part then
				return nil
			end
			return part.Position, part.AssemblyLinearVelocity
		end

		local function step(dt)
			acc += dt
			if acc < 0.05 then
				return
			end
			acc = 0
			local now = os.clock()
			if now - lastFire < (flag("ReboundCooldown") or 1.2) then
				return
			end
			local folder = Config.AutoGreen.Characters()
			local me = folder and folder:FindFirstChild(LocalPlayer.Name)
			local myHrp = me and me:FindFirstChild("HumanoidRootPart")
			local balls = workspace:FindFirstChild("Basketballs")
			if not (myHrp and balls) then
				return
			end
			local mine = attrsFor(me)
			if mine and (mine.Basketball or (mine.Action ~= nil and mine.Action ~= "" and mine.Action ~= "Moving")) then
				return
			end

			local holderExists = false
			for _, c in ipairs(folder:GetChildren()) do
				local a = attrsFor(c)
				if a and a.Basketball then
					holderExists = true
					break
				end
			end
			local range, maxH = flag("ReboundRange") or 12, flag("ReboundHeight") or 12
			for _, b in ipairs(balls:GetChildren()) do
				local pos, vel = ballState(b)
				if pos then
					local flat = Vector3.new(pos.X - myHrp.Position.X, 0, pos.Z - myHrp.Position.Z).Magnitude
					local up = pos.Y - myHrp.Position.Y
					if flag("ReboundDebug") and now - dbgAt > 1 then
						dbgAt = now
						_N(("[Rebound] ball %s: flat=%.1f up=%.1f vy=%.1f holderExists=%s"):format(b.Name, flat, up, vel.Y, tostring(holderExists)))
					end
					if not holderExists and flat <= range and up <= maxH and up >= -3 and vel.Y <= 2 then
						local shoot, jump = remotes()
						if shoot and jump then
							lastFire = now
							shoot:FireServer({ Shoot = true, Input = "E", UseSpace = true })
							jump:FireServer()
							task.delay((flag("ReboundHold") or 300) / 1000, function()
								shoot:FireServer({ Shoot = false })
							end)
							if not told then
								told = true
							end
						end
						return
					end
				end
			end
		end

		Modules.AutoRebound = {
			Flag = "AutoRebound",
			Start = function()
				local shoot, jump = remotes()
				if not (shoot and jump) then
					Library:Notify({ Title = "Auto Rebound", Content = "InputService.Shoot / Jump remotes not found.", Type = "Error" })
					return false
				end
				if not gameAttrs() then
					Library:Notify({ Title = "Auto Rebound", Content = "Controllers.Attributes not reachable.", Type = "Error" })
					return false
				end
				acc, lastFire, told = 0, 0, false
				conn = RunService.Heartbeat:Connect(step)
				return true
			end,
			Stop = function()
				if conn then
					conn:Disconnect()
					conn = nil
				end
			end,
		}
	end

	do
		local conn, movementObj, wrappedFn
		local lastFind, holding, told = 0, false, false
		local dbgAt = 0

		local function attrsFor(model)
			gameAttrs()
			if attrCtl and type(attrCtl.Get) == "function" then
				local ok, tbl = pcall(attrCtl.Get, attrCtl, model)
				if ok and type(tbl) == "table" then
					return tbl
				end
			end
			return nil
		end

		local function findMovement()
			if movementObj and movementObj.Root and movementObj.Root.Parent then
				return movementObj
			end
			movementObj = nil
			if typeof(getgc) ~= "function" or os.clock() - lastFind < 3 then
				return nil
			end
			lastFind = os.clock()
			for _, v in ipairs(getgc(true)) do
				if type(v) == "table" and rawget(v, "CurrentMovementType") ~= nil and rawget(v, "WalkSpring") ~= nil and rawget(v, "Root") ~= nil then
					movementObj = v
					break
				end
			end
			return movementObj
		end

		local function holdG(state)
			local r = ReplicatedStorage
			for _, n in ipairs({ "Aero", "AeroRemoteServices", "InputService", "HoldG" }) do
				r = r and r:FindFirstChild(n)
			end
			if r then
				r:FireServer({ HoldingG = state })
				holding = state
			end
		end

		local function handlerInfo()
			local folder = Config.AutoGreen.Characters()
			local me = folder and folder:FindFirstChild(LocalPlayer.Name)
			local myHrp = me and me:FindFirstChild("HumanoidRootPart")
			if not myHrp then
				return nil
			end
			local mine = attrsFor(me)
			if mine and mine.Basketball then
				return nil
			end
			local range = flag("GuardRange") or 25
			local best, bestD, bestA
			for _, c in ipairs(folder:GetChildren()) do
				if c ~= me then
					local a = attrsFor(c)
					local hrp = c:FindFirstChild("HumanoidRootPart")
					if a and a.Basketball and hrp then
						local teamOk = flag("GuardTeamCheck") ~= true or not mine or mine.Team == 0 or mine.Team == nil or a.Team ~= mine.Team
						local d = (hrp.Position - myHrp.Position).Magnitude
						if teamOk and d <= range and (not bestD or d < bestD) then
							best, bestD, bestA = hrp, d, a
						end
					end
				end
			end
			if not best then
				return nil
			end
			local spot = best.Position
			local goal = bestA.Goal
			local goalPos = typeof(goal) == "Instance" and goal:IsA("BasePart") and goal.Position or (typeof(goal) == "CFrame" and goal.Position) or nil
			if goalPos then
				local toGoal = Vector3.new(goalPos.X - best.Position.X, 0, goalPos.Z - best.Position.Z)
				if toGoal.Magnitude > 0.1 then
					spot = best.Position + toGoal.Unit * (flag("GuardDistance") or 3.5)
				end
			end
			return spot, myHrp, bestD
		end

		local function steer(self)
			if not flag("GuardSteer") then
				return
			end
			local spot, myHrp = handlerInfo()
			if not spot then
				return
			end
			if self.MoveDirection.Magnitude > 0.1 and flag("GuardOverride") ~= true then
				return
			end
			local off = Vector3.new(spot.X - myHrp.Position.X, 0, spot.Z - myHrp.Position.Z)
			local dir = off.Magnitude < 0.8 and Vector3.new(0, 0, 0) or off.Unit * math.min(1, off.Magnitude / 4)
			self.MoveDirection = dir
			self.forwardValue = self.Root.CFrame.LookVector:Dot(dir)
			self.rightValue = self.Root.CFrame.RightVector:Dot(dir)
		end

		local function wrap()
			local mv = findMovement()
			if mv and not wrappedFn then
				local orig = mv.UpdateMoveDirection
				if type(orig) == "function" then
					wrappedFn = orig
					mv.UpdateMoveDirection = function(self, dt)
						orig(self, dt)
						local ok = pcall(steer, self)
						if not ok then

						end
					end
				end
			end
		end

		local acc = 0
		local function step(dt)
			acc += dt
			if acc < 0.1 then
				return
			end
			acc = 0
			wrap()
			local spot, _, d = handlerInfo()
			if flag("GuardHoldG") ~= false then
				if spot and not holding then
					holdG(true)
					if not told then
						told = true
					end
				elseif not spot and holding then
					holdG(false)
				end
			end
			if flag("GuardDebug") and os.clock() - dbgAt > 1 then
				dbgAt = os.clock()
				_N(("[Guard] handler=%s dist=%s movement=%s steer=%s holdingG=%s"):format(
					tostring(spot ~= nil), d and ("%.1f"):format(d) or "-", tostring(movementObj ~= nil), tostring(flag("GuardSteer")), tostring(holding)))
			end
		end

		Modules.AutoGuard = {
			Flag = "AutoGuard",
			Start = function()
				if not gameAttrs() then
					Library:Notify({ Title = "Auto Guard", Content = "Controllers.Attributes not reachable.", Type = "Error" })
					return false
				end
				if typeof(getgc) ~= "function" then
					Library:Notify({ Title = "Auto Guard", Content = "No getgc: steering is off, only Hold G works.", Type = "Error" })
				end
				told, acc, holding = false, 0, false
				conn = RunService.Heartbeat:Connect(step)
				return true
			end,
			Stop = function()
				if conn then
					conn:Disconnect()
					conn = nil
				end
				if movementObj and wrappedFn then
					pcall(function()
						movementObj.UpdateMoveDirection = nil
					end)
				end
				wrappedFn = nil
				if holding then
					holdG(false)
				end
			end,
		}
	end

	do
		local conn, rideConn
		local stateObj, lastFind = nil, 0
		local lift, target, lastT = 0, 0, os.clock()
		local cloud, puffs = nil, {}
		local told = false

		local function getState()
			if stateObj and stateObj.ProxyCharacter and stateObj.ProxyCharacter.Parent and stateObj.MovementPosition and stateObj.MovementPosition.Parent then
				return stateObj
			end
			stateObj = nil
			if typeof(getgc) ~= "function" or os.clock() - lastFind < 3 then
				return nil
			end
			lastFind = os.clock()
			for _, v in ipairs(getgc(true)) do
				if type(v) == "table" and rawget(v, "MovementPosition") ~= nil and rawget(v, "MainMovementPosition") ~= nil and rawget(v, "ProxyCharacter") ~= nil then
					stateObj = v
					break
				end
			end
			return stateObj
		end

		local function buildCloud()
			if cloud then
				return
			end
			cloud = Instance.new("Folder")
			cloud.Name = "7100_Cloud"
			cloud.Parent = workspace.CurrentCamera
			puffs = {}

			local layout = {
				{ 0, -0.2, 0, 6.6, 3.3 },
				{ 3.0, 0.1, 0.6, 4.4, 2.7 },
				{ -3.0, 0.0, 0.8, 4.6, 2.7 },
				{ 1.1, -0.1, 3.0, 4.2, 2.5 },
				{ -1.5, 0.0, -2.9, 4.4, 2.6 },
				{ 2.7, 0.2, -2.3, 3.6, 2.3 },
				{ -2.6, 0.3, -2.5, 3.4, 2.2 },
				{ 0.2, 0.5, 0.2, 4.2, 2.4 },
			}
			for _, l in ipairs(layout) do
				local part = Instance.new("Part")
				part.Size = Vector3.new(l[4], l[5], l[4])
				part.Material = Enum.Material.SmoothPlastic
				part.Color = Color3.fromRGB(250, 250, 255)
				part.Anchored, part.CanCollide, part.CanQuery, part.CanTouch = true, false, false, false
				part.CastShadow = false
				local mesh = Instance.new("SpecialMesh")
				mesh.MeshType = Enum.MeshType.Sphere
				mesh.Parent = part
				part.Parent = cloud
				table.insert(puffs, { part = part, off = Vector3.new(l[1], l[2], l[3]) })
			end
		end

		local function destroyCloud()
			if cloud then
				cloud:Destroy()
				cloud, puffs = nil, {}
			end
		end

		local function apply()
			local now = os.clock()
			local dt = math.min(now - lastT, 0.1)
			lastT = now
			local speed = flag("CloudSpeed") or 28
			local maxH = flag("CloudMaxHeight") or 80
			if flag("CloudUp") == true then
				target = math.min(maxH, target + speed * dt)
			end
			if flag("CloudDown") == true then
				target = math.max(0, target - speed * dt)
			end

			local diff = target - lift
			lift = lift + math.clamp(diff, -speed * dt, speed * dt)

			local st = getState()
			local main, proxy = st and st.MainMovementPosition, st and st.MovementPosition
			if not (main and proxy and main.Parent and proxy.Parent) then
				return
			end
			local floorY = st.lastValidHeight
			if not finite(floorY) then
				return
			end
			local mp = main.Position
			local mass = st.ProxyCharacter and st.ProxyCharacter.AssemblyMass or 0
			proxy.MaxForce = Vector3.new(main.MaxForce.X, math.max(mass * 2250, main.MaxForce.Y), main.MaxForce.Z)
			proxy.Position = Vector3.new(mp.X, floorY + lift, mp.Z)
			proxy.P, proxy.D = 15500, 400
			if not told then
				told = true
				Library:Notify({ Title = "Cloud Ride", Content = "Hold your Rise / Descend keys to change height.", Duration = 4 })
			end
		end

		local function follow()
			local st = stateObj
			local proxy = st and st.ProxyCharacter
			if not (cloud and proxy and proxy.Parent) then
				return
			end
			local base = proxy.Position
			local bob = math.sin(os.clock() * 1.6) * 0.15
			local feetY = base.Y - 2.2 + bob
			for _, p in ipairs(puffs) do
				p.part.CFrame = CFrame.new(base.X + p.off.X, feetY + p.off.Y, base.Z + p.off.Z)
			end
		end

		Modules.CloudRide = {
			Flag = "CloudRide",
			Start = function()
				if typeof(getgc) ~= "function" then
					Library:Notify({ Title = "Cloud Ride", Content = "Needs getgc to find your character state.", Type = "Error" })
					return false
				end
				lift, target, lastT, told = 0, flag("CloudHeight") or 12, os.clock(), false
				buildCloud()
				conn = RunService.Stepped:Connect(function()
					task.defer(apply)
				end)
				rideConn = RunService.RenderStepped:Connect(follow)
				return true
			end,
			Stop = function()
				if conn then
					conn:Disconnect()
					conn = nil
				end
				if rideConn then
					rideConn:Disconnect()
					rideConn = nil
				end
				destroyCloud()
				lift, target = 0, 0
			end,
		}
	end

	do
		local HttpService = game:GetService("HttpService")
		local FILE = "7100_legit_stats.json"
		local session = { shots = 0, perfect = 0 }
		local alltime = { shots = 0, perfect = 0 }
		local gui, label, conn

		local function load()
			if typeof(isfile) == "function" and typeof(readfile) == "function" and isfile(FILE) then
				local ok, data = pcall(function()
					return HttpService:JSONDecode(readfile(FILE))
				end)
				if ok and type(data) == "table" and finite(data.shots) and finite(data.perfect) then
					alltime = { shots = data.shots, perfect = data.perfect }
				end
			end
		end
		local function save()
			if typeof(writefile) == "function" then
				pcall(writefile, FILE, HttpService:JSONEncode(alltime))
			end
		end

		local function pct(s)
			return s.shots > 0 and (s.perfect / s.shots * 100) or nil
		end

		local function render()
			if not label then
				return
			end
			local sp, ap = pct(session), pct(alltime)
			local warnAbove = flag("WarnAbove") or 40
			local lines = {
				("<b>THIS GAME</b>  Perfect %s  (%d shots)"):format(sp and ("%.0f%%"):format(sp) or "--", session.shots),
				("<b>ALL-TIME</b>  Perfect %s  (%d shots)"):format(ap and ("%.0f%%"):format(ap) or "--", alltime.shots),
			}
			local defense = (flag("AutoGuard") or flag("AutoBlock") or flag("AutoSteal") or flag("AutoRebound")) and "on" or "off"
			table.insert(lines, ("<b>AUTO DEFENSE</b>  %s"):format(defense))
			if ap and alltime.shots >= 20 then
				if ap > warnAbove + 10 then
					table.insert(lines, ('<font color="#ff6b6b">very high for a human (most sit under %d%%)</font>'):format(warnAbove))
				elseif ap > warnAbove then
					table.insert(lines, ('<font color="#f5c542">high for a human (most sit under %d%%)</font>'):format(warnAbove))
				end
			end
			label.Text = table.concat(lines, "\n")
		end

		local function build()
			if gui then
				return
			end
			local parent
			local ok, hui = pcall(function()
				return gethui and gethui()
			end)
			parent = (ok and hui) or game:GetService("CoreGui")
			gui = Instance.new("ScreenGui")
			gui.Name = "7100_LegitHud"
			gui.ResetOnSpawn = false
			gui.DisplayOrder = 50
			gui.Parent = parent
			local frame = Instance.new("Frame")
			frame.BackgroundColor3 = Color3.fromRGB(14, 12, 20)
			frame.BackgroundTransparency = 0.2
			frame.Position = UDim2.new(0, 14, 0.42, 0)
			frame.AutomaticSize = Enum.AutomaticSize.XY
			frame.Parent = gui
			Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)
			local pad = Instance.new("UIPadding", frame)
			pad.PaddingTop, pad.PaddingBottom, pad.PaddingLeft, pad.PaddingRight = UDim.new(0, 8), UDim.new(0, 8), UDim.new(0, 10), UDim.new(0, 10)
			label = Instance.new("TextLabel")
			label.BackgroundTransparency = 1
			label.AutomaticSize = Enum.AutomaticSize.XY
			label.RichText = true
			label.TextXAlignment = Enum.TextXAlignment.Left
			label.Font = Enum.Font.GothamMedium
			label.TextSize = 13
			label.TextColor3 = Color3.fromRGB(245, 205, 90)
			label.Text = ""
			label.Parent = frame
		end

		local function onLog(kind, text)
			if kind ~= "Log" or type(text) ~= "string" or not text:find("Shot Feedback", 1, true) then
				return
			end
			local percentage = tonumber(text:match("Percentage %- ([%d%.]+)"))
			if not percentage then
				return
			end
			local isPerfect = percentage >= (flag("PerfectAt") or 80)
			for _, s in ipairs({ session, alltime }) do
				s.shots += 1
				if isPerfect then
					s.perfect += 1
				end
			end
			save()
			render()
		end

		Modules.LegitHud = {
			Flag = "LegitWarnings",
			Reset = function()
				alltime = { shots = 0, perfect = 0 }
				save()
				render()
				Library:Notify({ Title = "Stats", Content = "All-time stats reset.", Type = "Success" })
			end,
			Start = function()
				local out = ReplicatedStorage
				for _, n in ipairs({ "Aero", "AeroRemoteServices", "InputService", "Output" }) do
					out = out and out:FindFirstChild(n)
				end
				if not out then
					Library:Notify({ Title = "Legit Warnings", Content = "InputService.Output event not found.", Type = "Error" })
					return false
				end
				load()
				build()
				conn = out.OnClientEvent:Connect(onLog)
				render()
				return true
			end,
			Stop = function()
				if conn then
					conn:Disconnect()
					conn = nil
				end
				if gui then
					gui:Destroy()
					gui, label = nil, nil
				end
			end,
		}
	end

	do
		local conn
		local folder
		local ghosts = {}
		local dots = {}
		local acc = 0
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude

		local function ensureFolder()
			if not folder then
				folder = Instance.new("Folder")
				folder.Name = "7100_BallGhost"
				folder.Parent = workspace.CurrentCamera
			end
		end

		local function partOf(b)
			return b:IsA("BasePart") and b or (b:IsA("Model") and (b.PrimaryPart or b:FindFirstChildWhichIsA("BasePart", true)))
		end

		local GHOST_ALPHA = 0.6
		local function ghostFor(ball, size)
			local g = ghosts[ball]
			if g and g.Parent then
				return g
			end
			local was = ball.Archivable
			ball.Archivable = true
			local ok, clone = pcall(ball.Clone, ball)
			ball.Archivable = was
			if ok and clone then
				for _, d in ipairs(clone:GetDescendants()) do
					if d:IsA("BaseScript") or d:IsA("BodyMover") or d:IsA("Constraint") or d:IsA("Sound") or d:IsA("BillboardGui") or d:IsA("SurfaceGui")
						or d:IsA("ParticleEmitter") or d:IsA("Trail") or d:IsA("Beam") then
						d:Destroy()
					end
				end
				local function soften(inst)
					if inst:IsA("BasePart") then
						inst.Anchored, inst.CanCollide, inst.CanQuery, inst.CanTouch = true, false, false, false
						inst.CastShadow = false
						inst.Transparency = math.max(inst.Transparency, GHOST_ALPHA)
					elseif inst:IsA("Decal") or inst:IsA("Texture") then
						inst.Transparency = math.max(inst.Transparency, GHOST_ALPHA)
					end
				end
				soften(clone)
				for _, d in ipairs(clone:GetDescendants()) do
					soften(d)
				end
				clone.Name = "7100_BallGhostCopy"
				clone.Parent = folder
				ghosts[ball] = clone
				return clone
			end

			g = Instance.new("Part")
			g.Shape = Enum.PartType.Ball
			g.Size = Vector3.new(size, size, size)
			g.Anchored, g.CanCollide, g.CanQuery, g.CanTouch = true, false, false, false
			g.Color = Color3.fromRGB(255, 150, 60)
			g.Transparency = GHOST_ALPHA
			g.CastShadow = false
			g.Parent = folder
			ghosts[ball] = g
			return g
		end

		local function placeGhost(g, position)
			if g:IsA("Model") then
				g:PivotTo(CFrame.new(position))
			else
				g.Position = position
			end
		end

		local function dotAt(i)
			local d = dots[i]
			if not d then
				d = Instance.new("Part")
				d.Shape = Enum.PartType.Ball
				d.Size = Vector3.new(0.45, 0.45, 0.45)
				d.Anchored, d.CanCollide, d.CanQuery, d.CanTouch = true, false, false, false
				d.Material = Enum.Material.Neon
				d.Color = Color3.fromRGB(255, 190, 90)
				d.CastShadow = false
				d.Parent = folder
				dots[i] = d
			end
			return d
		end

		local function predict(pos, vel, radius)
			local g = Vector3.new(0, -workspace.Gravity, 0)
			local dt = 0.05
			local points = {}
			local ignore = { workspace.CurrentCamera, workspace:FindFirstChild("Basketballs"), workspace:FindFirstChild("Characters"), workspace:FindFirstChild("ProxyCharacter") }
			params.FilterDescendantsInstances = ignore
			for _ = 1, 70 do
				local nextVel = vel + g * dt
				local nextPos = pos + vel * dt + g * (0.5 * dt * dt)
				local dir = nextPos - pos
				local hit = workspace:Raycast(pos, dir + dir.Unit * radius, params)
				local tries = 0
				while hit and hit.Instance.Transparency >= 0.99 and tries < 3 do
					table.insert(ignore, hit.Instance)
					params.FilterDescendantsInstances = ignore
					hit = workspace:Raycast(pos, dir + dir.Unit * radius, params)
					tries += 1
				end
				if hit then
					return hit.Position + hit.Normal * radius, points
				end
				pos, vel = nextPos, nextVel
				table.insert(points, pos)
			end
			return nil, points
		end

		local function update()
			local balls = workspace:FindFirstChild("Basketballs")
			if not balls then
				return
			end
			ensureFolder()
			local used, dotCount = {}, 0
			for _, b in ipairs(balls:GetChildren()) do
				local part = partOf(b)
				if part then
					local vel = part.AssemblyLinearVelocity
					if vel.Magnitude > 6 and part.Position.Y > 1 then
						local radius = part.Size.X / 2
						local landing, points = predict(part.Position, vel, radius)
						if landing then
							local gh = ghostFor(b, part.Size.X)
							placeGhost(gh, landing)
							used[b] = true
						end
						if flag("BallTrajectory") then
							for i = 1, #points, 2 do
								dotCount += 1
								dotAt(dotCount).Position = points[i]
							end
						end
					end
				end
			end
			for b, gh in pairs(ghosts) do
				if not used[b] then
					gh:Destroy()
					ghosts[b] = nil
				end
			end
			for i = dotCount + 1, #dots do
				if dots[i] then
					dots[i]:Destroy()
					dots[i] = nil
				end
			end
		end

		Modules.BallGhost = {
			Flag = "BallGhost",
			Start = function()
				acc = 0
				conn = RunService.RenderStepped:Connect(function(dt)
					acc += dt
					if acc >= 0.05 then
						acc = 0
						pcall(update)
					end
				end)
				return true
			end,
			Stop = function()
				if conn then
					conn:Disconnect()
					conn = nil
				end
				if folder then
					folder:Destroy()
					folder = nil
				end
				ghosts, dots = {}, {}
			end,
		}
	end

	do
		local conn, ring
		local acc, lastShot, dbgAt = 0, 0, 0
		local told, warned = false, false

		local function attrsFor(model)
			gameAttrs()
			if attrCtl and type(attrCtl.Get) == "function" then
				local ok, tbl = pcall(attrCtl.Get, attrCtl, model)
				if ok and type(tbl) == "table" then
					return tbl
				end
			end
			return nil
		end

		local function ratings()
			local r = LocalPlayer:FindFirstChild("PlayerScripts")
			for _, n in ipairs({ "Aero", "Controllers", "Player" }) do
				r = r and r:FindFirstChild(n)
			end
			if r and r:IsA("ModuleScript") then
				local ok, mod = pcall(require, r)
				local slot = ok and type(mod) == "table" and mod.SlotData
				return type(slot) == "table" and slot.Attributes or nil
			end
			return nil
		end

		local function goalPosition(a)
			local goal = a and a.Goal
			if typeof(goal) == "Instance" and goal:IsA("BasePart") then
				return goal.Position
			elseif typeof(goal) == "CFrame" then
				return goal.Position
			elseif typeof(goal) == "Vector3" then
				return goal
			end
			return nil
		end

		local function destroyRing()
			if ring then
				ring:Destroy()
				ring = nil
			end
		end

		local function updateRing(goalPos, radius)
			if not flag("ShootRangeVisual") or not goalPos then
				destroyRing()
				return
			end
			if not ring then
				ring = Instance.new("Part")
				ring.Name = "7100_ShootRange"
				ring.Shape = Enum.PartType.Cylinder
				ring.Anchored, ring.CanCollide, ring.CanQuery, ring.CanTouch = true, false, false, false
				ring.Material = Enum.Material.Neon
				ring.Color = Color3.fromRGB(132, 10, 255)
				ring.Transparency = 0.88
				ring.CastShadow = false
				ring.Parent = workspace.CurrentCamera
			end

			local hit = workspace:Raycast(goalPos, Vector3.new(0, -60, 0))
			local y = (hit and hit.Position.Y or goalPos.Y - 10) + 0.08
			ring.Size = Vector3.new(0.1, radius * 2, radius * 2)
			ring.CFrame = CFrame.new(goalPos.X, y, goalPos.Z) * CFrame.Angles(0, 0, math.rad(90))
		end

		local function step(dt)
			acc += dt
			if acc < 0.1 then
				return
			end
			acc = 0
			local now = os.clock()
			local folder = Config.AutoGreen.Characters()
			local me = folder and folder:FindFirstChild(LocalPlayer.Name)
			local myHrp = me and me:FindFirstChild("HumanoidRootPart")
			local mine = me and attrsFor(me)
			if not (myHrp and mine) then
				return
			end
			local goalPos = goalPosition(mine)
			local maxDist = flag("ShootMaxDist") or 45
			updateRing(goalPos, maxDist)
			if not (mine.Basketball and goalPos) then
				return
			end
			local action = mine.Action
			if not (action == nil or action == "" or action == "Moving") then
				return
			end
			if now - lastShot < 2 then
				return
			end
			local dist = Vector3.new(goalPos.X - myHrp.Position.X, 0, goalPos.Z - myHrp.Position.Z).Magnitude
			if dist > maxDist then
				return
			end

			local radius = flag("ShootWhen") == "Potential Contest" and 20 or 12
			local nearest
			for _, c in ipairs(folder:GetChildren()) do
				if c ~= me then
					local a = attrsFor(c)
					local hrp = c:FindFirstChild("HumanoidRootPart")
					if hrp and not (a and a.Team == mine.Team and mine.Team ~= 0) then
						local d = (hrp.Position - myHrp.Position).Magnitude
						if not nearest or d < nearest then
							nearest = d
						end
					end
				end
			end
			local contest = nearest and math.max(0, (1 - nearest / 12) * 100) or 0
			if nearest and nearest <= radius and flag("ShootWhen") == "Potential Contest" then
				contest = math.max(contest, 25)
			end

			local rt = ratings()
			local shooting = rt and rt.Shooting
			local finishing = rt and rt.Finishing
			local rating = 70
			if shooting and finishing then
				if dist >= 28 then
					rating = shooting.ThreePointShot or rating
				elseif dist >= 9 then
					rating = shooting.MidRangeShot or rating
				else
					rating = finishing.CloseShot or rating
				end
			end
			local make = math.clamp(rating * 0.9 - contest * 0.6 + 10, 0, 100)
			local aggro = (flag("ShootAggro") or 50) / 100
			local maxContest = (flag("ShootMaxContest") or 18) + aggro * 30
			local minMake = (flag("ShootMinMake") or 60) - aggro * 20

			if flag("ShootDebug") and now - dbgAt > 1 then
				dbgAt = now
				_N(("[AutoShoot] dist=%.1f/%s contest=%.0f (max %.0f) makeEst=%.0f (min %.0f) rating=%s nearestOpp=%s"):format(
					dist, tostring(maxDist), contest, maxContest, make, minMake, tostring(rating), nearest and ("%.1f"):format(nearest) or "-"))
			end

			if contest <= maxContest and make >= minMake then
				local r = ReplicatedStorage
				for _, n in ipairs({ "Aero", "AeroRemoteServices", "InputService", "Shoot" }) do
					r = r and r:FindFirstChild(n)
				end
				if r then
					lastShot = now
					r:FireServer({ Shoot = true, Input = "E" })
					if not told then
						told = true
					end
				end
			end
		end

		Modules.AutoShoot = {
			Flag = "AutoShoot",
			Start = function()
				if not gameAttrs() then
					Library:Notify({ Title = "Auto Shoot", Content = "Controllers.Attributes not reachable.", Type = "Error" })
					return false
				end
				if flag("AutoTime") ~= true and not warned then
					warned = true
					Library:Notify({ Title = "Auto Shoot", Content = "Turn Auto Time on too, or the started shots are never released.", Duration = 6 })
				end
				acc, lastShot, told = 0, 0, false
				conn = RunService.Heartbeat:Connect(step)
				return true
			end,
			Stop = function()
				if conn then
					conn:Disconnect()
					conn = nil
				end
				destroyRing()
			end,
		}
	end

	do
		local conn
		local acc, lastLob = 0, 0
		local told = false

		local function attrsFor(model)
			gameAttrs()
			if attrCtl and type(attrCtl.Get) == "function" then
				local ok, tbl = pcall(attrCtl.Get, attrCtl, model)
				if ok and type(tbl) == "table" then
					return tbl
				end
			end
			return nil
		end

		local function passRemote()
			local r = ReplicatedStorage
			for _, n in ipairs({ "Aero", "AeroRemoteServices", "InputService", "Pass" }) do
				r = r and r:FindFirstChild(n)
			end
			return r
		end

		local function goalPosition(a)
			local goal = a and a.Goal
			if typeof(goal) == "Instance" and goal:IsA("BasePart") then
				return goal.Position
			elseif typeof(goal) == "CFrame" then
				return goal.Position
			elseif typeof(goal) == "Vector3" then
				return goal
			end
			return nil
		end

		local function context()
			local folder = Config.AutoGreen.Characters()
			local me = folder and folder:FindFirstChild(LocalPlayer.Name)
			local myHrp = me and me:FindFirstChild("HumanoidRootPart")
			local mine = me and attrsFor(me)
			if not (myHrp and mine) then
				return nil
			end
			local mates, foes = {}, {}
			for _, c in ipairs(folder:GetChildren()) do
				if c ~= me then
					local a = attrsFor(c)
					local hrp = c:FindFirstChild("HumanoidRootPart")
					if a and hrp then
						if a.Team == mine.Team then
							table.insert(mates, { model = c, hrp = hrp })
						else
							table.insert(foes, hrp)
						end
					end
				end
			end
			return { me = me, mine = mine, hrp = myHrp, mates = mates, foes = foes }
		end

		local function canPass(ctx)
			local a = ctx.mine.Action
			return ctx.mine.Basketball ~= nil and ctx.mine.Basketball ~= false and a ~= "Passing"
		end

		local function sendPass(player, passType)
			local r = passRemote()
			if not r then
				return false
			end
			r:FireServer({ Player = player, PassType = passType })
			return true
		end

		local function selfLob()
			local ctx = context()
			if ctx and canPass(ctx) then
				return sendPass(LocalPlayer.Name, 4)
			end
			return false
		end

		local function alleyOop()
			local ctx = context()
			if not (ctx and canPass(ctx)) then
				return false
			end
			local goalPos = goalPosition(ctx.mine)
			if not goalPos then
				return false
			end
			local best, bestD
			for _, m in ipairs(ctx.mates) do
				local d = (Vector3.new(goalPos.X, 0, goalPos.Z) - Vector3.new(m.hrp.Position.X, 0, m.hrp.Position.Z)).Magnitude
				if not bestD or d < bestD then
					best, bestD = m, d
				end
			end
			return best ~= nil and sendPass(best.model.Name, 4)
		end

		local function passOpen()
			local ctx = context()
			if not (ctx and canPass(ctx)) then
				return false
			end
			local openMin, range = flag("OpenDistance") or 8, flag("OpenPassRange") or 70
			local best, bestSpace
			for _, m in ipairs(ctx.mates) do
				local toMe = (m.hrp.Position - ctx.hrp.Position).Magnitude
				if toMe <= range then
					local space = math.huge
					for _, f in ipairs(ctx.foes) do
						space = math.min(space, (f.Position - m.hrp.Position).Magnitude)
					end
					if space >= openMin and (not bestSpace or space > bestSpace) then
						best, bestSpace = m, space
					end
				end
			end
			return best ~= nil and sendPass(best.model.Name, 1)
		end

		local function step(dt)
			acc += dt
			if acc < 0.1 then
				return
			end
			acc = 0
			local now = os.clock()
			if now - lastLob < (flag("LobCooldown") or 4) then
				return
			end
			local ctx = context()
			if not (ctx and canPass(ctx)) then
				return
			end
			local a = ctx.mine.Action
			if not (a == nil or a == "" or a == "Moving") then
				return
			end
			local goalPos = goalPosition(ctx.mine)
			if not goalPos then
				return
			end
			local off = Vector3.new(goalPos.X - ctx.hrp.Position.X, 0, goalPos.Z - ctx.hrp.Position.Z)
			local dist = off.Magnitude
			if dist < (flag("LobMin") or 8) or dist > (flag("LobMax") or 24) then
				return
			end
			local vel = ctx.hrp.AssemblyLinearVelocity * Vector3.new(1, 0, 1)
			if vel.Magnitude < 4 or vel.Unit:Dot(off.Unit) < 0.6 then
				return
			end
			if selfLob() then
				lastLob = now
				if not told then
					told = true
				end
			end
		end

		Modules.LobTools = { SelfLob = selfLob, AlleyOop = alleyOop, PassOpen = passOpen }
		Modules.AutoLob = {
			Flag = "AutoLob",
			Start = function()
				if not passRemote() then
					Library:Notify({ Title = "Auto Lob", Content = "InputService.Pass remote not found.", Type = "Error" })
					return false
				end
				if not gameAttrs() then
					Library:Notify({ Title = "Auto Lob", Content = "Controllers.Attributes not reachable.", Type = "Error" })
					return false
				end
				acc, lastLob, told = 0, 0, false
				conn = RunService.Heartbeat:Connect(step)
				return true
			end,
			Stop = function()
				if conn then
					conn:Disconnect()
					conn = nil
				end
			end,
		}
	end

	do
		local movementObj, lastFind = nil, 0
		local MOVES = {
			["Crossover"] = { R = "Z", L = "C" },
			["Hesitation"] = { R = "C", L = "Z" },
			["Double Crossover"] = { R = "CC", L = "ZZ" },
			["Tween"] = { R = "ZZ", L = "CC" },
			["Behind The Back"] = { R = "CX", L = "ZX" },
			["Spin"] = { R = "CXZ", L = "ZXC" },
			["Double BTB"] = { R = "XZ", L = "XC" },
			["Stepback"] = { R = "X", L = "X" },
			["Snatchback"] = { R = "XX", L = "XX" },
			["Shammgod"] = { R = "VV", L = "VV" },
			["Double Tween"] = { R = "VC", L = "VZ" },
			["BTB Between Legs"] = { R = "VZ", L = "VC" },
			["Half Spin"] = { R = "V", L = "V" },
			["Jab Right"] = { R = "C", L = "C" },
			["Jab Left"] = { R = "Z", L = "Z" },
			["Jab Turn Around"] = { R = "X", L = "X" },
		}
		local running = false

		local function attrsFor(model)
			gameAttrs()
			if attrCtl and type(attrCtl.Get) == "function" then
				local ok, tbl = pcall(attrCtl.Get, attrCtl, model)
				if ok and type(tbl) == "table" then
					return tbl
				end
			end
			return nil
		end

		local function moveDirection()
			if not (movementObj and movementObj.Root and movementObj.Root.Parent) then
				movementObj = nil
				if typeof(getgc) == "function" and os.clock() - lastFind > 3 then
					lastFind = os.clock()
					for _, v in ipairs(getgc(true)) do
						if type(v) == "table" and rawget(v, "CurrentMovementType") ~= nil and rawget(v, "WalkSpring") ~= nil and rawget(v, "Root") ~= nil then
							movementObj = v
							break
						end
					end
				end
			end
			local d = movementObj and movementObj.lastMoveDirection
			return typeof(d) == "Vector3" and d or Vector3.new(0, 0, 0)
		end

		local function dribbleRemote()
			local r = ReplicatedStorage
			for _, n in ipairs({ "Aero", "AeroRemoteServices", "InputService", "Dribble" }) do
				r = r and r:FindFirstChild(n)
			end
			return r
		end

		local function fireMove(name)
			local r = dribbleRemote()
			if not r then
				return false
			end
			if name == "Switch Hand" then
				r:FireServer("H")
				return true
			end
			local entry = MOVES[name]
			if not entry then
				return false
			end
			local folder = Config.AutoGreen.Characters()
			local me = folder and folder:FindFirstChild(LocalPlayer.Name)
			local a = me and attrsFor(me)
			local hand = (a and a.Hand == "L") and "L" or "R"
			local sprint = flag("MacroSprint") == true or (a and a.Sprinting == true) or false
			r:FireServer(entry[hand], sprint, moveDirection())
			return true
		end

		local function runCombo(index)
			if running then
				return
			end
			running = true
			task.spawn(function()
				for slot = 1, 6 do
					local name = flag(("Combo%dMove%d"):format(index, slot))
					if name and name ~= "None" then
						fireMove(name)
						task.wait(flag("ComboGap") or 0.25)
					end
				end
				running = false
			end)
		end

		Modules.DribbleTools = { Move = fireMove, Combo = runCombo }
	end

	do
		local conn, movementObj, wrappedFn, mine, hadRaw
		local lastFind, acc = 0, 0
		local until_, cooldownUntil, targetModel = 0, 0, nil
		local told = false

		local function attrsFor(model)
			gameAttrs()
			if attrCtl and type(attrCtl.Get) == "function" then
				local ok, tbl = pcall(attrCtl.Get, attrCtl, model)
				if ok and type(tbl) == "table" then
					return tbl
				end
			end
			return nil
		end

		local function findMovement()
			if movementObj and movementObj.Root and movementObj.Root.Parent then
				return movementObj
			end
			movementObj = nil
			if typeof(getgc) ~= "function" or os.clock() - lastFind < 3 then
				return nil
			end
			lastFind = os.clock()
			for _, v in ipairs(getgc(true)) do
				if type(v) == "table" and rawget(v, "CurrentMovementType") ~= nil and rawget(v, "WalkSpring") ~= nil and rawget(v, "Root") ~= nil then
					movementObj = v
					break
				end
			end
			return movementObj
		end

		local function steer(self)
			if os.clock() > until_ or not targetModel or not targetModel.Parent then
				return
			end
			local hrp = targetModel:FindFirstChild("HumanoidRootPart")
			if not hrp then
				return
			end
			local off = Vector3.new(hrp.Position.X - self.Root.Position.X, 0, hrp.Position.Z - self.Root.Position.Z)
			if off.Magnitude < 0.5 then
				return
			end
			local dir = off.Unit
			self.MoveDirection = dir
			self.forwardValue = self.Root.CFrame.LookVector:Dot(dir)
			self.rightValue = self.Root.CFrame.RightVector:Dot(dir)
		end

		local function wrap()
			local mv = findMovement()
			if mv and not mine then
				local prev = mv.UpdateMoveDirection
				if type(prev) == "function" then
					wrappedFn = prev
					hadRaw = rawget(mv, "UpdateMoveDirection") ~= nil
					mine = function(self, dt)
						prev(self, dt)
						pcall(steer, self)
					end
					mv.UpdateMoveDirection = mine
				end
			end
		end

		local function step(dt)
			acc += dt
			if acc < 0.05 then
				return
			end
			acc = 0
			wrap()
			local now = os.clock()
			if now < cooldownUntil or now < until_ then
				return
			end
			local folder = Config.AutoGreen.Characters()
			local me = folder and folder:FindFirstChild(LocalPlayer.Name)
			local myHrp = me and me:FindFirstChild("HumanoidRootPart")
			local mineAttrs = me and attrsFor(me)
			if not (myHrp and mineAttrs) or mineAttrs.Basketball then
				return
			end
			local range = flag("FoulRange") or 10
			for _, c in ipairs(folder:GetChildren()) do
				if c ~= me then
					local a = attrsFor(c)
					local hrp = c:FindFirstChild("HumanoidRootPart")
					if a and hrp and a.Action == "Shooting"
						and (flag("FoulTeamCheck") ~= true or a.Team ~= mineAttrs.Team or mineAttrs.Team == 0)
						and (hrp.Position - myHrp.Position).Magnitude <= range then
						targetModel = c
						until_ = now + (flag("FoulRunTime") or 0.5)
						cooldownUntil = until_ + (flag("FoulCooldown") or 2)
						if not told then
							told = true
						end
						return
					end
				end
			end
		end

		Modules.FoulBait = {
			Flag = "FoulBait",
			Start = function()
				if typeof(getgc) ~= "function" then
					Library:Notify({ Title = "Foul Bait", Content = "Needs getgc to steer your character.", Type = "Error" })
					return false
				end
				if not gameAttrs() then
					Library:Notify({ Title = "Foul Bait", Content = "Controllers.Attributes not reachable.", Type = "Error" })
					return false
				end
				acc, until_, cooldownUntil, targetModel, told = 0, 0, 0, nil, false
				conn = RunService.Heartbeat:Connect(step)
				return true
			end,
			Stop = function()
				if conn then
					conn:Disconnect()
					conn = nil
				end
				if movementObj and mine and rawget(movementObj, "UpdateMoveDirection") == mine then
					pcall(function()
						movementObj.UpdateMoveDirection = hadRaw and wrappedFn or nil
					end)
				end
				mine, wrappedFn = nil, nil
			end,
		}
	end

	do
		local UserInputService = game:GetService("UserInputService")
		local HttpService = game:GetService("HttpService")
		local ORDER = { "Mascot", "Hats", "Hair", "Glasses", "FacialHair", "Shirt", "Pants", "Jersey", "Compression", "LegCompression", "Chain", "Backpack", "Shoes", "SkinTone" }
		local LABEL = { Mascot = "Mascots", Hats = "Hats", Hair = "Hair", Glasses = "Glasses", FacialHair = "Facial Hair", Shirt = "Shirt", Pants = "Pants",
			Jersey = "Jersey", Compression = "Arm Sleeve", LegCompression = "Leg Sleeve", Chain = "Chain", Backpack = "Backpack", Shoes = "Shoes", SkinTone = "Skin Tone" }
		local LIST_CATS = { Hats = 2, Hair = 1, Glasses = 2, FacialHair = 1, Chain = 1, Backpack = 1, Compression = 1, LegCompression = 1 }
		local STRING_CATS = { Shirt = true, Pants = true, Jersey = true, Mascot = true }
		local PER_PAGE = 18
		local cats = {}
		local overrides = {}
		local snapshot
		local gui, ui, conn
		local state = { cat = 1, page = 1, query = "" }
		local ctrl, lastFind = nil, 0
		local told = false

		local function myModel()
			local folder = Config.AutoGreen.Characters()
			return folder and folder:FindFirstChild(LocalPlayer.Name)
		end

		local function findController()
			local model = myModel()
			if not model then
				return nil
			end
			if ctrl and rawget(ctrl, "model") == model and type(ctrl.Appearance) == "table" and not ctrl.destroyed then
				return ctrl
			end
			ctrl = nil
			if typeof(getgc) ~= "function" or os.clock() - lastFind < 0.75 then
				return nil
			end
			lastFind = os.clock()
			for _, v in ipairs(getgc(true)) do
				if type(v) == "table" and rawget(v, "model") == model and type(rawget(v, "Appearance")) == "table" then
					local ok, fn = pcall(function()
						return v.Appearance.UpdateAppearance
					end)
					if ok and type(fn) == "function" then
						ctrl = v
						break
					end
				end
			end
			return ctrl
		end

		local function appearance()
			local c = findController()
			return c and c.Appearance
		end

		local function deepCopy(x)
			if type(x) ~= "table" then
				return x
			end
			local out = {}
			for k, v in pairs(x) do
				out[k] = deepCopy(v)
			end
			return out
		end

		local function toRGB(data)
			if typeof(data) == "Color3" then
				return { math.round(data.R * 255), math.round(data.G * 255), math.round(data.B * 255) }
			elseif type(data) == "table" then
				if type(data[1]) == "number" and type(data[2]) == "number" and type(data[3]) == "number" then
					return { data[1], data[2], data[3] }
				end
				if data.Color then
					return toRGB(data.Color)
				end
			end
			return nil
		end

		local function loadConfig()
			local out = {}
			local node = ReplicatedStorage
			for _, n in ipairs({ "Aero", "Shared", "Config", "Accessories" }) do
				node = node and node:FindFirstChild(n)
			end
			if node and node:IsA("ModuleScript") then
				local ok, t = pcall(require, node)
				if ok and type(t) == "table" then
					out = t
				end
			elseif node then
				for _, m in ipairs(node:GetChildren()) do
					if m:IsA("ModuleScript") then
						local ok, t = pcall(require, m)
						if ok and type(t) == "table" then
							out[m.Name] = t
						end
					end
				end
			end
			return out
		end

		local function buildCatalog()
			cats = {}
			local cfg = loadConfig()
			local root = ReplicatedStorage:FindFirstChild("Accessories")
			for _, key in ipairs(ORDER) do
				local tbl = cfg[key] or (key == "Mascot" and (cfg.Mascots or cfg.Mascot)) or (key == "SkinTone" and (cfg.SkinTone or cfg.SkinTones)) or nil
				local list = {}
				if type(tbl) == "table" then
					for k, v in pairs(tbl) do
						if type(k) == "string" then
							table.insert(list, { name = k, data = v })
						elseif type(v) == "string" then
							table.insert(list, { name = v, data = nil })
						end
					end
				end
				if #list == 0 and key == "Mascot" and root and root:FindFirstChild("Mascots") then
					for _, m in ipairs(root.Mascots:GetChildren()) do
						table.insert(list, { name = m.Name })
					end
				end
				table.sort(list, function(a, b)
					return a.name:lower() < b.name:lower()
				end)
				if #list == 0 then
					_N("[Cosmetics] no items found for " .. key .. " (config shape unknown): skipped")
				else
					table.insert(cats, { key = key, label = LABEL[key], items = list })
				end
			end
		end

		local function defaultColor(cat, item)

			local root = ReplicatedStorage:FindFirstChild("Accessories")
			local folder = root and root:FindFirstChild(cat.key)
			local tpl = folder and folder:FindFirstChild(item.name, true)
			if tpl and tpl:IsA("BasePart") then
				return toRGB(tpl.Color) or { 255, 255, 255 }
			end
			return { 255, 255, 255 }
		end

		local function shoeEntry(item)
			return { Model = item.name, Color = { 255, 255, 255 } }
		end

		local function currentValue(cat)
			local ap = appearance()
			local data = ap and ap.appearanceData
			return data and data[cat.key]
		end

		local function isWorn(cat, item)
			local v = currentValue(cat)
			if cat.key == "Shoes" then
				local r = type(v) == "table" and v.RightShoe
				return type(r) == "table" and (r.Model or r[1]) == item.name
			elseif cat.key == "SkinTone" then
				local rgb = toRGB(item.data)
				return type(v) == "table" and rgb ~= nil and v[1] == rgb[1] and v[2] == rgb[2] and v[3] == rgb[3]
			elseif STRING_CATS[cat.key] then
				return v == item.name
			end
			if type(v) == "table" then
				for _, e in ipairs(v) do
					if (e.Name or e[1]) == item.name then
						return true
					end
				end
			end
			return false
		end

		local wrappedAp, origUpdate
		local callsInWindow, windowStart = 0, os.clock()
		local ourApplies, ourWindow = 0, os.clock()
		local function applyTo(ap, tbl)
			local f = (wrappedAp == ap and origUpdate) or ap.UpdateAppearance
			if flag("CosmeticsDebug") then
				local keys = {}
				for k in pairs(tbl or {}) do
					table.insert(keys, tostring(k))
				end
				ourApplies += 1
				_N(("[Cosmetics] WE apply (%s) #%d, %.1fs since the last report"):format(table.concat(keys, ", "), ourApplies, os.clock() - ourWindow))
			end
			local ok, err = pcall(f, ap, tbl)
			if not ok then

				_N("[Cosmetics] UpdateAppearance raised an error: " .. tostring(err))
			end
		end
		local function unwrap()
			if wrappedAp and origUpdate and rawget(wrappedAp, "UpdateAppearance") ~= nil then
				pcall(function()
					wrappedAp.UpdateAppearance = nil
				end)
			end
			wrappedAp, origUpdate = nil, nil
		end
		local function ensureWrapped(ap)
			if wrappedAp == ap then
				return false
			end
			unwrap()
			local orig = ap.UpdateAppearance
			if type(orig) ~= "function" then
				return false
			end
			origUpdate = orig
			wrappedAp = ap
			ap.UpdateAppearance = function(self, changes)
				if flag("CosmeticsDebug") then
					callsInWindow += 1
					if callsInWindow <= 6 then
						local keys = {}
						if type(changes) == "table" then
							for k in pairs(changes) do
								table.insert(keys, tostring(k))
							end
						end
						_N("[Cosmetics] the GAME called UpdateAppearance with: " .. table.concat(keys, ", ") .. "\n" .. debug.traceback("", 2))
					end
					if os.clock() - windowStart >= 2 then
						_N(("[Cosmetics] the game called UpdateAppearance %d times in the last %.1fs"):format(callsInWindow, os.clock() - windowStart))
						windowStart, callsInWindow = os.clock(), 0
					end
				end
				if type(changes) == "table" then
					for k, v in pairs(overrides) do
						if changes[k] ~= nil then
							changes[k] = deepCopy(v)
						end
					end
				end
				return orig(self, changes)
			end
			return true
		end

		local function nameOf(e)
			return type(e) == "table" and (e.Name or e[1]) or e
		end
		local function sameValue(key, have, want)
			if key == "Shoes" then
				local a = type(have) == "table" and type(have.RightShoe) == "table" and (have.RightShoe.Model or have.RightShoe[1])
				local b = type(want) == "table" and type(want.RightShoe) == "table" and (want.RightShoe.Model or want.RightShoe[1])
				return a == b
			elseif key == "SkinTone" then
				return type(have) == "table" and type(want) == "table" and have[1] == want[1] and have[2] == want[2] and have[3] == want[3]
			elseif type(want) == "table" then
				if type(have) ~= "table" or #have ~= #want then
					return false
				end
				for i = 1, #want do
					if nameOf(have[i]) ~= nameOf(want[i]) then
						return false
					end
				end
				return true
			end
			return have == want
		end

		local function change(changes)
			local ap = appearance()
			if not ap then
				if not told then
					told = true
					Library:Notify({ Title = "Cosmetics", Content = "Could not find your character's Appearance object (needs getgc).", Type = "Error" })
				end
				return
			end
			if not snapshot and ap.appearanceData then
				snapshot = deepCopy(ap.appearanceData)
			end
			for k, v in pairs(changes) do
				overrides[k] = deepCopy(v)
			end
			ensureWrapped(ap)
			task.spawn(function()
				pcall(applyTo, ap, deepCopy(changes))
			end)
		end

		local function wear(cat, item)
			local key = cat.key
			if key == "Shoes" then
				if item then
					change({ Shoes = { RightShoe = shoeEntry(item), LeftShoe = shoeEntry(item) } })
				end
			elseif key == "SkinTone" then
				local rgb = item and toRGB(item.data)
				if rgb then
					change({ SkinTone = rgb })
				end
			elseif STRING_CATS[key] then
				change({ [key] = item and item.name or "None" })
			else
				local list = {}
				local cur = currentValue(cat)
				if type(cur) == "table" then
					for _, e in ipairs(cur) do
						table.insert(list, deepCopy(e))
					end
				end
				if not item then
					list = {}
				else
					local already
					for i, e in ipairs(list) do
						if (e.Name or e[1]) == item.name then
							already = i
						end
					end
					if already then
						table.remove(list, already)
					else
						table.insert(list, { item.name, defaultColor(cat, item) })
						while #list > (LIST_CATS[key] or 1) do
							table.remove(list, 1)
						end
					end
				end
				change({ [key] = list })
			end
		end

		local BG, CARD, LINE, TXT, SUB = Color3.fromRGB(22, 22, 25), Color3.fromRGB(33, 33, 37), Color3.fromRGB(52, 52, 58), Color3.fromRGB(235, 235, 238), Color3.fromRGB(150, 150, 158)
		local function mk(class, props, parent)
			local o = Instance.new(class)
			for k, v in pairs(props or {}) do
				o[k] = v
			end
			o.Parent = parent
			return o
		end
		local function corner(o, r)
			mk("UICorner", { CornerRadius = UDim.new(0, r) }, o)
		end
		local function stroke(o, color, thick)
			return mk("UIStroke", { Color = color or LINE, Thickness = thick or 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, o)
		end
		local function text(parent, props)
			props.BackgroundTransparency = 1
			props.Font = props.Font or Enum.Font.Gotham
			props.TextColor3 = props.TextColor3 or TXT
			props.TextSize = props.TextSize or 13
			return mk("TextLabel", props, parent)
		end

		local function filtered()
			local cat = cats[state.cat]
			if not cat then
				return {}
			end
			local q = state.query:lower()
			if q == "" then
				return cat.items
			end
			local out = {}
			for _, it in ipairs(cat.items) do
				if it.name:lower():find(q, 1, true) then
					table.insert(out, it)
				end
			end
			return out
		end

		local function viewportOf(parent, instance)
			local vp = mk("ViewportFrame", { Size = UDim2.new(1, -16, 0, 84), Position = UDim2.fromOffset(8, 8), BackgroundColor3 = Color3.fromRGB(26, 26, 29), BorderSizePixel = 0 }, parent)
			corner(vp, 8)
			local ok, clone = pcall(function()
				local was = instance.Archivable
				instance.Archivable = true
				local c = instance:Clone()
				instance.Archivable = was
				return c
			end)
			if not ok or not clone then
				return
			end
			for _, d in ipairs(clone:GetDescendants()) do
				if d:IsA("BaseScript") then
					d:Destroy()
				end
			end
			local center, extent
			if clone:IsA("Model") then
				local cf, size = clone:GetBoundingBox()
				center, extent = cf.Position, math.max(size.X, size.Y, size.Z, 0.2)
			else
				clone.Anchored = true
				clone.CFrame = CFrame.new(0, 0, 0)
				center, extent = Vector3.new(0, 0, 0), math.max(clone.Size.X, clone.Size.Y, clone.Size.Z, 0.2)
			end
			clone.Parent = vp
			local cam = Instance.new("Camera")
			cam.FieldOfView = 40
			cam.CFrame = CFrame.new(center + Vector3.new(extent * 0.9, extent * 0.5, extent * 1.9), center)
			cam.Parent = vp
			vp.CurrentCamera = cam
		end

		local function previewOf(parent, cat, item)
			local key = cat.key
			local root = ReplicatedStorage:FindFirstChild("Accessories")
			if key == "SkinTone" then
				local rgb = toRGB(item.data) or { 128, 128, 128 }
				local sw = mk("Frame", { Size = UDim2.new(1, -16, 0, 84), Position = UDim2.fromOffset(8, 8), BackgroundColor3 = Color3.fromRGB(rgb[1], rgb[2], rgb[3]), BorderSizePixel = 0 }, parent)
				corner(sw, 8)
			elseif key == "Mascot" then
				local m = root and root:FindFirstChild("Mascots") and root.Mascots:FindFirstChild(item.name)
				if m then
					viewportOf(parent, m)
				end
			elseif key == "Shirt" or key == "Pants" or key == "Jersey" or key == "Compression" or key == "LegCompression" then
				local asset = type(item.data) == "table" and item.data.AssetId
				local frame = mk("Frame", { Size = UDim2.new(1, -16, 0, 84), Position = UDim2.fromOffset(8, 8), BackgroundColor3 = Color3.fromRGB(26, 26, 29), BorderSizePixel = 0 }, parent)
				corner(frame, 8)
				if type(asset) == "string" then
					mk("ImageLabel", { BackgroundTransparency = 1, Image = asset, Size = UDim2.fromScale(1, 1), ScaleType = Enum.ScaleType.Fit }, frame)
				end
			elseif key == "Shoes" then
				local shoeId = type(item.data) == "table" and item.data.ShoeId
				if type(shoeId) == "string" and root and root:FindFirstChild("Shoes") then
					local parts = string.split(shoeId, "_")
					local base = root.Shoes:FindFirstChild(parts[1])
					local variant = base and base:FindFirstChild((parts[2] and parts[2] ~= "") and parts[2] or "Base")
					local shoe = variant and variant:FindFirstChild("RightShoe")
					if shoe then
						viewportOf(parent, shoe)
					end
				end
			else
				local folder = root and root:FindFirstChild(key)
				local tpl = folder and folder:FindFirstChild(item.name, true)
				if tpl then
					viewportOf(parent, tpl)
				end
			end
		end

		local refresh

		local function card(grid, cat, item, isNone)
			local f = mk("Frame", { BackgroundColor3 = CARD }, grid)
			corner(f, 10)
			local s = stroke(f, LINE, 1)
			if isNone then
				local circle = mk("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0, 50), Size = UDim2.fromOffset(30, 30), BackgroundTransparency = 1 }, f)
				corner(circle, 15)
				stroke(circle, SUB, 1.5)
				text(f, { Text = "None", Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(10, 100), Size = UDim2.new(1, -20, 0, 36) })
			else
				previewOf(f, cat, item)
				text(f, { Text = item.name, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, TextWrapped = true, TextSize = 11, TextColor3 = SUB, Position = UDim2.fromOffset(10, 98), Size = UDim2.new(1, -20, 0, 40) })
			end
			if (not isNone) and isWorn(cat, item) then
				s.Color, s.Thickness = Color3.new(1, 1, 1), 2
			end
			local btn = mk("TextButton", { Text = "", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 5 }, f)
			btn.MouseButton1Click:Connect(function()
				wear(cat, (not isNone) and item or nil)
				task.delay(0.6, refresh)
			end)
		end

		local function wornChips()
			local out = {}
			local ap = appearance()
			local data = ap and ap.appearanceData
			if not data then
				return out
			end
			for _, cat in ipairs(cats) do
				local v = data[cat.key]
				if cat.key == "Shoes" then
					local r = type(v) == "table" and v.RightShoe
					if type(r) == "table" and (r.Model or r[1]) then
						table.insert(out, { cat = cat, label = tostring(r.Model or r[1]) })
					end
				elseif cat.key == "SkinTone" then
					for _, it in ipairs(cat.items) do
						if isWorn(cat, it) then
							table.insert(out, { cat = cat, label = it.name })
						end
					end
				elseif STRING_CATS[cat.key] then
					if type(v) == "string" and v ~= "" and v ~= "None" and not v:lower():match("^rbxassetid") then
						table.insert(out, { cat = cat, label = v })
					end
				elseif type(v) == "table" then
					for _, e in ipairs(v) do
						table.insert(out, { cat = cat, label = tostring(e.Name or e[1]) })
					end
				end
			end
			return out
		end

		function refresh()
			if not ui or not gui or not gui.Enabled then
				return
			end
			local cat = cats[state.cat]
			if not cat then
				return
			end
			for i, row in ipairs(ui.catRows) do
				row.bg.BackgroundTransparency = (i == state.cat) and 0 or 1
			end
			for _, c in ipairs(ui.chips:GetChildren()) do
				if c:IsA("GuiObject") then
					c:Destroy()
				end
			end
			for _, w in ipairs(wornChips()) do
				local chip = mk("TextButton", { Text = "", AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 26), BackgroundColor3 = CARD, AutoButtonColor = false }, ui.chips)
				corner(chip, 6)
				stroke(chip, LINE, 1)
				mk("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }, chip)
				mk("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), VerticalAlignment = Enum.VerticalAlignment.Center }, chip)
				text(chip, { Text = w.cat.label, TextColor3 = SUB, TextSize = 11, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 26), LayoutOrder = 1 })
				text(chip, { Text = w.label, Font = Enum.Font.GothamMedium, TextSize = 12, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 26), LayoutOrder = 2 })
				text(chip, { Text = "x", TextColor3 = SUB, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 26), LayoutOrder = 3 })
				chip.MouseButton1Click:Connect(function()
					wear(w.cat, nil)
					task.delay(0.6, refresh)
				end)
			end
			for _, c in ipairs(ui.grid:GetChildren()) do
				if c:IsA("GuiObject") then
					c:Destroy()
				end
			end
			local list = filtered()
			local pages = math.max(1, math.ceil((#list + 1) / PER_PAGE))
			state.page = math.clamp(state.page, 1, pages)
			ui.title.Text = cat.label
			ui.sub.Text = ("%d items"):format(#list)
			ui.pager.Text = ("%d / %d"):format(state.page, pages)
			local first = (state.page - 1) * PER_PAGE
			for slot = first, first + PER_PAGE - 1 do
				if slot == 0 then
					card(ui.grid, cat, nil, true)
				elseif list[slot] then
					card(ui.grid, cat, list[slot], false)
				end
			end
		end

		local function build()
			if gui then
				return
			end
			local parent
			local ok, hui = pcall(function()
				return gethui and gethui()
			end)
			parent = (ok and hui) or game:GetService("CoreGui")
			gui = mk("ScreenGui", { Name = "7100_Catalog", ResetOnSpawn = false, DisplayOrder = 80, IgnoreGuiInset = true, Enabled = false }, parent)
			local W, H = 1000, 650
			local main = mk("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(W, H), BackgroundColor3 = BG }, gui)
			local camera = workspace.CurrentCamera
			if camera then
				local v = camera.ViewportSize
				mk("UIScale", { Scale = math.min(1, (v.X - 20) / W, (v.Y - 20) / H) }, main)
			end
			corner(main, 14)
			stroke(main, LINE, 1)
			text(main, { Text = "Cosmetics", Font = Enum.Font.GothamBold, TextSize = 20, TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(20, 14), Size = UDim2.fromOffset(110, 30) })
			text(main, { Text = "your screen only", TextColor3 = SUB, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(134, 14), Size = UDim2.fromOffset(150, 30) })
			local search = mk("TextBox", { PlaceholderText = "Search", Text = "", ClearTextOnFocus = false, Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = TXT, PlaceholderColor3 = SUB, TextXAlignment = Enum.TextXAlignment.Left, BackgroundColor3 = CARD, Position = UDim2.new(1, -330, 0, 14), Size = UDim2.fromOffset(260, 32) }, main)
			corner(search, 8)
			stroke(search, LINE, 1)
			mk("UIPadding", { PaddingLeft = UDim.new(0, 12) }, search)
			local close = mk("TextButton", { Text = "x", Font = Enum.Font.GothamMedium, TextSize = 16, TextColor3 = SUB, BackgroundTransparency = 1, Position = UDim2.new(1, -50, 0, 14), Size = UDim2.fromOffset(32, 32) }, main)
			mk("Frame", { BackgroundColor3 = LINE, BorderSizePixel = 0, Position = UDim2.fromOffset(0, 58), Size = UDim2.new(1, 0, 0, 1) }, main)
			text(main, { Text = "WEARING", Font = Enum.Font.GothamBold, TextColor3 = SUB, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(20, 66), Size = UDim2.fromOffset(70, 34) })
			local chips = mk("ScrollingFrame", { BackgroundTransparency = 1, BorderSizePixel = 0, Position = UDim2.fromOffset(96, 66), Size = UDim2.new(1, -116, 0, 34), CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.X, ScrollingDirection = Enum.ScrollingDirection.X, ScrollBarThickness = 0 }, main)
			mk("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8), VerticalAlignment = Enum.VerticalAlignment.Center }, chips)
			mk("Frame", { BackgroundColor3 = LINE, BorderSizePixel = 0, Position = UDim2.fromOffset(0, 106), Size = UDim2.new(1, 0, 0, 1) }, main)

			local catList = mk("ScrollingFrame", { BackgroundTransparency = 1, BorderSizePixel = 0, Position = UDim2.fromOffset(12, 118), Size = UDim2.fromOffset(210, 520), CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 2 }, main)
			mk("UIListLayout", { Padding = UDim.new(0, 2) }, catList)
			local catRows = {}
			for i, c in ipairs(cats) do
				local bg = mk("TextButton", { Text = "", AutoButtonColor = false, BackgroundColor3 = CARD, BackgroundTransparency = 1, Size = UDim2.new(1, -6, 0, 34), LayoutOrder = i }, catList)
				corner(bg, 8)
				text(bg, { Text = c.label, TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -60, 1, 0) })
				text(bg, { Text = tostring(#c.items), TextColor3 = SUB, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Right, Position = UDim2.new(1, -48, 0, 0), Size = UDim2.fromOffset(36, 34) })
				bg.MouseButton1Click:Connect(function()
					state.cat, state.page = i, 1
					refresh()
				end)
				catRows[i] = { bg = bg }
			end
			mk("Frame", { BackgroundColor3 = LINE, BorderSizePixel = 0, Position = UDim2.fromOffset(232, 118), Size = UDim2.fromOffset(1, 520) }, main)

			local title = text(main, { Text = "", Font = Enum.Font.GothamBold, TextSize = 15, TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(250, 118), Size = UDim2.fromOffset(220, 24) })
			local sub = text(main, { Text = "", TextColor3 = SUB, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(250, 142), Size = UDim2.fromOffset(220, 18) })
			local prev = mk("TextButton", { Text = "<", Font = Enum.Font.GothamMedium, TextSize = 14, TextColor3 = TXT, BackgroundColor3 = CARD, Position = UDim2.new(1, -170, 0, 120), Size = UDim2.fromOffset(34, 28) }, main)
			corner(prev, 8)
			local pager = text(main, { Text = "1 / 1", TextColor3 = SUB, TextSize = 12, Position = UDim2.new(1, -132, 0, 120), Size = UDim2.fromOffset(60, 28) })
			local nxt = mk("TextButton", { Text = ">", Font = Enum.Font.GothamMedium, TextSize = 14, TextColor3 = TXT, BackgroundColor3 = CARD, Position = UDim2.new(1, -68, 0, 120), Size = UDim2.fromOffset(34, 28) }, main)
			corner(nxt, 8)

			local grid = mk("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(250, 168), Size = UDim2.fromOffset(730, 470) }, main)
			mk("UIGridLayout", { CellSize = UDim2.fromOffset(112, 146), CellPadding = UDim2.fromOffset(10, 10), SortOrder = Enum.SortOrder.LayoutOrder }, grid)

			ui = { main = main, chips = chips, grid = grid, title = title, sub = sub, pager = pager, catRows = catRows }
			close.MouseButton1Click:Connect(function()
				gui.Enabled = false
			end)
			prev.MouseButton1Click:Connect(function()
				state.page -= 1
				refresh()
			end)
			nxt.MouseButton1Click:Connect(function()
				state.page += 1
				refresh()
			end)
			search:GetPropertyChangedSignal("Text"):Connect(function()
				state.query, state.page = search.Text, 1
				refresh()
			end)
			local dragging, dragStart, startPos
			main.InputBegan:Connect(function(input)
				if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and input.Position.Y - main.AbsolutePosition.Y < 56 then
					dragging, dragStart, startPos = true, input.Position, main.Position
				end
			end)
			UserInputService.InputChanged:Connect(function(input)
				if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
					local d = input.Position - dragStart
					main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
				end
			end)
			UserInputService.InputEnded:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					dragging = false
				end
			end)
		end

		local function toggle()
			if #cats == 0 then
				buildCatalog()
			end
			if #cats == 0 then
				Library:Notify({ Title = "Cosmetics", Content = "No items found in Config.Accessories.", Type = "Error" })
				return
			end
			build()
			gui.Enabled = not gui.Enabled
			if gui.Enabled then
				refresh()
			end
		end

		local function resetAll()
			overrides = {}
			if snapshot then
				change(snapshot)
				overrides = {}
				snapshot = nil
			end
			task.delay(0.8, refresh)
		end

		local acc = 0
		Modules.Cosmetics = {
			Toggle = toggle,
			Reset = resetAll,
			Flag = "CosmeticsOn",
			Start = function()
				acc = 0
				local sinceCheck = 0
				local reappliedAt, ignored = {}, {}
				conn = RunService.Heartbeat:Connect(function(dt)
					acc += dt
					if acc < 0.25 or next(overrides) == nil then
						return
					end
					sinceCheck += acc
					acc = 0
					local ap = appearance()
					local data = ap and ap.appearanceData
					if not data then
						return
					end

					if ensureWrapped(ap) then
						ignored, reappliedAt = {}, {}
						for k, v in pairs(overrides) do
							task.spawn(function()
								pcall(applyTo, ap, { [k] = deepCopy(v) })
							end)
						end
						return
					end

					if sinceCheck < 1 then
						return
					end
					sinceCheck = 0
					local now = os.clock()
					for k, v in pairs(overrides) do
						if not ignored[k] and not sameValue(k, data[k], v) then
							if reappliedAt[k] and now - reappliedAt[k] < 8 then
								ignored[k] = true
							else
								reappliedAt[k] = now
								task.spawn(function()
									pcall(applyTo, ap, { [k] = deepCopy(v) })
								end)
							end
						end
					end
				end)
				return true
			end,
			Stop = function()
				if conn then
					conn:Disconnect()
					conn = nil
				end
				resetAll()
				unwrap()
				if gui then
					gui:Destroy()
					gui, ui = nil, nil
				end
			end,
		}
	end

	do
		local target, origRun
		local function controller()
			local r = LocalPlayer:FindFirstChild("PlayerScripts")
			for _, n in ipairs({ "Aero", "Controllers", "Visuals", "Combined", "GreenEffects" }) do
				r = r and r:FindFirstChild(n)
			end
			if not (r and r:IsA("ModuleScript")) then
				return nil
			end
			local ok, mod = pcall(require, r)
			return ok and type(mod) == "table" and mod or nil
		end
		local function myModel()
			local folder = Config.AutoGreen.Characters()
			return folder and folder:FindFirstChild(LocalPlayer.Name)
		end

		Modules.GreenEffectOverride = {
			Flag = "GreenEffectOn",
			Start = function()
				local c = controller()
				if not c or type(c.RunEffect) ~= "function" then
					Library:Notify({ Title = "Green Effect", Content = "GreenEffects controller not reachable.", Type = "Error" })
					return false
				end
				target, origRun = c, c.RunEffect
				c.RunEffect = function(self, model, ball, goal, serverTime, name)
					local choice = flag("GreenEffectChoice")
					if choice and choice ~= "Default (yours)" and model == myModel() then
						name = choice
					end
					return origRun(self, model, ball, goal, serverTime, name)
				end
				return true
			end,
			Stop = function()
				if target and origRun then
					pcall(function()
						target.RunEffect = origRun
					end)
				end
				target, origRun = nil, nil
			end,
		}
	end

	do
		local conn
		local acc = 0
		local disabled = {}
		local mine

		local function myModel()
			local folder = Config.AutoGreen.Characters()
			return folder and folder:FindFirstChild(LocalPlayer.Name)
		end

		local function template()
			local r = ReplicatedStorage
			for _, n in ipairs({ "Assets", "Models", "HeadLogo" }) do
				r = r and r:FindFirstChild(n)
			end
			return r
		end

		local function restore()
			for g in pairs(disabled) do
				if g.Parent then
					g.Enabled = true
				end
			end
			disabled = {}
			if mine then
				mine:Destroy()
				mine = nil
			end
		end

		local function apply()
			local model = myModel()
			local head = model and model:FindFirstChild("Head")
			if not head then
				return
			end
			local choice = flag("HeadLogoChoice")
			if not choice or choice == "Default (yours)" then
				restore()
				return
			end

			for _, g in ipairs(head:GetChildren()) do
				if g:IsA("BillboardGui") and g ~= mine and (g:FindFirstChild("Owner") or g:FindFirstChild("Twitch")) then
					if g.Enabled then
						disabled[g] = true
						g.Enabled = false
					end
				end
			end
			if choice == "None" then
				if mine then
					mine:Destroy()
					mine = nil
				end
				return
			end
			if not (mine and mine.Parent == head) then
				local tpl = template()
				if not tpl then
					return
				end
				mine = tpl:Clone()
				mine.Name = "7100_HeadLogo"
				mine.Enabled = true
				mine.Parent = head
			end
			for _, child in ipairs(mine:GetChildren()) do
				if child:IsA("GuiObject") then
					child.Visible = child.Name == choice
				end
			end
		end

		Modules.HeadLogo = {
			Flag = "HeadLogoOn",
			Start = function()
				if not template() then
					Library:Notify({ Title = "Head Logo", Content = "Assets.Models.HeadLogo not found.", Type = "Error" })
					return false
				end
				acc = 0
				apply()
				conn = RunService.Heartbeat:Connect(function(dt)
					acc += dt
					if acc >= 1 then
						acc = 0
						apply()
					end
				end)
				return true
			end,
			Stop = function()
				if conn then
					conn:Disconnect()
					conn = nil
				end
				restore()
			end,
		}
	end

	do
		local told = false

		local function attrsFor(model)
			gameAttrs()
			if attrCtl and type(attrCtl.Get) == "function" then
				local ok, tbl = pcall(attrCtl.Get, attrCtl, model)
				if ok and type(tbl) == "table" then
					return tbl
				end
			end
			return nil
		end

		local function filter(arg)
			if flag("BadShotFake") ~= true or arg.Input ~= "E" or arg.UseSpace then
				return nil
			end
			local folder = Config.AutoGreen.Characters()
			local me = folder and folder:FindFirstChild(LocalPlayer.Name)
			local myHrp = me and me:FindFirstChild("HumanoidRootPart")
			local mine = me and attrsFor(me)
			if not (myHrp and mine and mine.Basketball) then
				return nil
			end
			local nearest
			for _, c in ipairs(folder:GetChildren()) do
				if c ~= me then
					local a = attrsFor(c)
					local hrp = c:FindFirstChild("HumanoidRootPart")
					if hrp and not (a and mine.Team ~= 0 and a.Team == mine.Team) then
						local d = (hrp.Position - myHrp.Position).Magnitude
						if not nearest or d < nearest then
							nearest = d
						end
					end
				end
			end
			local contest = nearest and math.max(0, (1 - nearest / 12) * 100) or 0
			if contest >= (flag("BadShotContest") or 27) then
				if not told then
					told = true
				end
				return { Shoot = false, Input = "E" }
			end
			return nil
		end

		Modules.BadShotFake = {
			Flag = "BadShotFake",
			Start = function()
				if typeof(hookmetamethod) ~= "function" then
					Library:Notify({ Title = "Bad Shot Fake", Content = "Needs hookmetamethod.", Type = "Error" })
					return false
				end
				if not gameAttrs() then
					Library:Notify({ Title = "Bad Shot Fake", Content = "Controllers.Attributes not reachable.", Type = "Error" })
					return false
				end
				told = false
				Library.ShootFilter = filter
				return true
			end,
			Stop = function()
				if Library.ShootFilter == filter then
					Library.ShootFilter = nil
				end
			end,
		}
	end

	local function rangeModule(name, flagName, key, finderKey)
		local conn
		Modules[name] = {
			Flag = flagName,
			Start = function()
				local cfg = Config[key]
				if not gated(name, cfg) then
					return false
				end
				local last = 0
				conn = RunService.Heartbeat:Connect(function()
					local root = myRoot()
					local target = cfg[finderKey]()
					if not root or not target then
						return
					end
					local part = target:IsA("BasePart") and target or target:FindFirstChild("HumanoidRootPart")
					if not part then
						return
					end
					local d = (part.Position - root.Position).Magnitude
					if finite(d) and d <= cfg.Range and os.clock() - last > 0.25 then
						last = os.clock()
						cfg.Remote:FireServer(unpack(cfg.Args(target)))
					end
				end)
				return true
			end,
			Stop = function()
				if conn then
					conn:Disconnect()
					conn = nil
				end
			end,
		}
	end

	for name, flagName in pairs({

	}) do
		Modules[name] = {
			Flag = flagName,
			Start = function()
				return gated(name, nil)
			end,
			Stop = function() end,
		}
	end

	local running = {}
	local conn = RunService.Heartbeat:Connect(function()
		for name, m in pairs(Modules) do
			local want = flag(m.Flag) == true
			if want and not running[name] then
				running[name] = true
				if not m.Start() then
					running[name] = nil
					local opt = Library.Options[m.Flag]
					if opt then
						opt:Set(false, true)
					end
					Library.Flags[m.Flag] = false
				end
			elseif not want and running[name] then
				running[name] = nil
				m.Stop()
			end
		end
	end)

	return {
		Config = Config,
		Modules = Modules,
		Unload = function()
			conn:Disconnect()
			for name, m in pairs(Modules) do
				if running[name] then
					m.Stop()
				end
			end
		end,
	}
end

	end)()(Library)
end)
if not okF then
	Library:Notify({ Title = "Features", Content = "Failed to load: " .. tostring(errF), Type = "Error" })
end

if okF and Library.Features then
	local features, baseUnload = Library.Features, Library.Unload
	Library.Unload = function(self, ...)
		pcall(features.Unload)
		if Library.AutoGreenStop then
			pcall(Library.AutoGreenStop)
		end
		return baseUnload(self, ...)
	end
end

local AUTO_METHOD = "Auto (all meters + no meter)"
do
	local okA, errA = pcall(function()
		local F = function() return Library.Flags end
		local SETTINGS = setmetatable({
			Mode = "Predict",
			PerfectExtreme = 1.0,
			Extreme = { Vertical = 1.46 },
			PingFactor = 0,
			ReferencePing = 75,
			PerType = {},
		}, {
			__index = function(_, k)
				local f = F()
				if k == "Enabled" then
					return f.AutoTime == true
				elseif k == "Calibrate" then
					return f.GreenCalibrate == true
				elseif k == "Debug" then
					return f.GreenDebug == true
				elseif k == "LeadExtra" then
					return (f.GreenLead or 0) / 1000
				elseif k == "HoldTime" then
					local h = f.GreenHold
					return (h and h > 0) and h / 1000 or nil
				elseif k == "FixStaleMeters" then
					return f.GreenFixStale ~= false
				end
				return nil
			end,
		})

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Stats = game:GetService("Stats")
local LocalPlayer = Players.LocalPlayer

local Env = (typeof(getgenv) == "function" and getgenv()) or _G
if Env.AutoGreen7100 then
	pcall(Env.AutoGreen7100.Stop)
end

local function path(root, names)
	local r = root
	for _, n in ipairs(names) do
		r = r and r:FindFirstChild(n)
	end
	return r
end

local Shoot = path(ReplicatedStorage, { "Aero", "AeroRemoteServices", "InputService", "Shoot" })
local MeterEvent = path(ReplicatedStorage, { "Aero", "AeroRemoteServices", "GameplayService", "Meter" })
local Output = path(ReplicatedStorage, { "Aero", "AeroRemoteServices", "InputService", "Output" })
if not (Shoot and MeterEvent) then
	_N("[AutoGreen] remotes not found: Shoot=" .. tostring(Shoot) .. " Meter=" .. tostring(MeterEvent))
	return
end

local function dbg(...)
	if SETTINGS.Debug then
		_N("[AutoGreen]", ...)
	end
end

local function finite(n)
	return typeof(n) == "number" and n == n and n ~= math.huge and n ~= -math.huge
end

local function getPing()
	local ok, v = pcall(function()
		return Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
	end)
	if ok and v then
		return math.floor(v)
	end
	return math.floor(LocalPlayer:GetNetworkPing() * 2000)
end

local function myChar()
	local folder = workspace:FindFirstChild("Characters")
	return folder and folder:FindFirstChild(LocalPlayer.Name)
end

local function findMeterGui(char, t)
	local name = tostring(t) .. "Meter"
	local gui
	for _, partName in ipairs({ "HumanoidRootPart", "Head" }) do
		local p = char:FindFirstChild(partName)
		gui = gui or (p and p:FindFirstChild(name))
	end
	return gui
end

local active, mtype, grad = false, nil, nil
local armed, fired, startedAt, dbgAt, warned = false, false, 0, 0, {}
local lastY
local lastTimedHold, sweepIndex = nil, 0
local lastGreenInfo, lastHoldActual = "?", nil
local stopped = false
local shotStart, shotToken, ownRelease = nil, 0, false
local meterSeenShot = -1
local pState
local samples, lastSampleAt = {}, 0

local function currentY(char)
	local v = char:GetAttribute("meterOffset")
	local y = typeof(v) == "Vector2" and v.Y or v
	if finite(y) then
		return y, v
	end
	if not (grad and grad.Parent) then
		local gui = findMeterGui(char, mtype)
		grad = gui and gui:FindFirstChild("FillGradient", true)
	end
	return grad and grad.Offset.Y, v
end

local function predictStep(char, dt)
	local vec = char:GetAttribute("meterOffset")
	if typeof(vec) ~= "Vector2" then
		if not (grad and grad.Parent) then
			local gui = findMeterGui(char, mtype)
			grad = gui and gui:FindFirstChild("FillGradient", true)
		end
		vec = grad and grad.Offset
	end
	if typeof(vec) ~= "Vector2" or not finite(vec.X) or not finite(vec.Y) then
		return
	end
	local now = os.clock()
	if not pState then
		pState = { t0 = now, v0 = vec }
		return
	end
	if not pState.axis then
		if now - pState.t0 < 0.08 then
			return
		end
		local dx, dy = vec.X - pState.v0.X, vec.Y - pState.v0.Y
		local axis = math.abs(dx) > math.abs(dy) and "X" or "Y"
		local d = axis == "X" and dx or dy
		if math.abs(d) < 0.05 then
			return
		end
		pState.axis, pState.dir, pState.speed = axis, d > 0 and 1 or -1, math.abs(d) / (now - pState.t0)
		_N(("[Predict] %s axis=%s dir=%d speed=%.2f/s"):format(tostring(mtype), axis, pState.dir, pState.speed))
		return
	end
	local val = vec[pState.axis]
	lastY = val
	if pState.fired then
		return
	end

	local hist = pState.hist
	if not hist then
		hist = {}
		pState.hist = hist
	end
	hist[#hist + 1] = { now, val }
	while #hist > 2 and now - hist[1][1] > 0.2 do
		table.remove(hist, 1)
	end
	local first = hist[1]
	if now - first[1] >= 0.06 then
		local s = math.abs(val - first[2]) / (now - first[1])
		if s > 0.05 then
			pState.speed = pState.speed * 0.5 + s * 0.5
		end
	end
	local rawPing = getPing()
	pState.ping = pState.ping and (pState.ping * 0.7 + rawPing * 0.3) or rawPing
	local ping = pState.ping
	local extreme = SETTINGS.Extreme[mtype] or SETTINGS.PerfectExtreme
	local remaining = (extreme * pState.dir - val) * pState.dir
	local lead = pState.speed * (ping / 1000 + dt / 2 + SETTINGS.LeadExtra)
	if remaining <= lead then
		pState.fired = true
		lastHoldActual = os.clock() - (shotStart or startedAt)
		ownRelease = true
		Shoot:FireServer({ Shoot = false })
		_N(("[AutoGreen] RELEASE (predict) %s at %s=%.3f, %.3f short of target (ping %d ms)"):format(
			tostring(mtype), pState.axis, val, remaining, ping))
	end
end

local conns = {}
conns.event = MeterEvent.OnClientEvent:Connect(function(on, c, t)
	if c ~= myChar() then
		return
	end
	dbg("Meter event", tostring(on), tostring(t))
	if SETTINGS.Calibrate then
		_N(("[Calib] Meter event on=%s type=%s"):format(tostring(on), tostring(t)))
	end
	pState = nil
	if on and t and t ~= "None" then
		active, mtype = true, t
		meterSeenShot = shotToken
		if SETTINGS.FixStaleMeters then

			task.defer(function()
				for _, partName in ipairs({ "HumanoidRootPart", "Head" }) do
					local p = c:FindFirstChild(partName)
					if p then
						for _, g in ipairs(p:GetChildren()) do
							if g:IsA("BillboardGui") and g.Name:match("Meter$") and g.Name ~= tostring(t) .. "Meter" and g.Enabled then
								g.Enabled = false
							end
						end
					end
				end
			end)
		end
		armed, fired, startedAt, lastY = false, false, os.clock(), nil
		grad = nil
		samples, lastSampleAt = {}, 0
		if SETTINGS.Calibrate then
			task.delay(0.15, function()
				local gui = findMeterGui(c, t)
				local green = gui and gui:FindFirstChild("Meter_Green")
				local gg = green and green:FindFirstChildWhichIsA("UIGradient", true)
				local fg = gui and gui:FindFirstChild("FillGradient", true)
				if gg then
					local parts = {}
					for _, k in ipairs(gg.Transparency.Keypoints) do
						table.insert(parts, ("%.3f:%.2f"):format(k.Time, k.Value))
					end
					lastGreenInfo = table.concat(parts, " ")
					_N(("[Calib] %s green gradient rot=%s keypoints(time:transparency) %s | fill rot=%s offset=%s"):format(
						t, tostring(gg.Rotation), table.concat(parts, " "), tostring(fg and fg.Rotation), tostring(fg and fg.Offset)))
				else
					_N("[Calib] " .. tostring(t) .. ": green gradient not found")
				end
			end)
		end
	else
		active = false
	end
end)

conns.step = RunService.RenderStepped:Connect(function(dt)
	if not active then
		return
	end
	local char = myChar()
	if not char then
		return
	end
	if SETTINGS.Mode == "Predict" then
		if SETTINGS.Enabled then
			predictStep(char, dt)
		end
		return
	end
	local y, v = currentY(char)
	if not finite(y) then
		return
	end
	lastY = y
	if SETTINGS.Calibrate then
		local el = os.clock() - startedAt
		if el - lastSampleAt >= 0.1 and #samples < 60 then
			lastSampleAt = el
			table.insert(samples, ("%.1f:%.2f"):format(el, y))
		end
	end
	local cfg = SETTINGS.PerType[mtype]
	if os.clock() - dbgAt > 0.25 then
		dbgAt = os.clock()
		dbg(("type=%s y=%.3f armed=%s fired=%s attr=%s rot=%s"):format(
			tostring(mtype), y, tostring(armed), tostring(fired), tostring(v), tostring(char:GetAttribute("meterRotation"))))
	end
	if not SETTINGS.Enabled or SETTINGS.Mode ~= "Meter" then
		return
	end
	if not cfg or cfg.Release == nil then
		if not warned[mtype] then
			warned[mtype] = true
			_N("[AutoGreen] meter '" .. tostring(mtype) .. "' has no measured release value (PerType." .. tostring(mtype) .. ".Release). Not auto-releasing; use Calibrate.")
		end
		return
	end
	local comp = 0
	if SETTINGS.PingCompensation then

		comp = 3.2 * (getPing() - SETTINGS.ReferencePing) / 1000
	end
	if cfg.Dir == "down" then
		local thr = cfg.Release + cfg.Margin + comp
		if y > thr + 0.25 then
			armed = true
		end
		if not fired and (armed or os.clock() - startedAt > 0.8) and y <= thr then
			fired = true
			Shoot:FireServer({ Shoot = false })
			_N(("[AutoGreen] RELEASE %s at y=%.3f"):format(mtype, y))
		end
	else
		local thr = cfg.Release - cfg.Margin - comp
		if y < thr - 0.25 then
			armed = true
		end
		if not fired and (armed or os.clock() - startedAt > 0.8) and y >= thr then
			fired = true
			Shoot:FireServer({ Shoot = false })
			_N(("[AutoGreen] RELEASE %s at y=%.3f"):format(mtype, y))
		end
	end
end)

if SETTINGS.Calibrate then

	conns.input = UserInputService.InputEnded:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.E and active and not (SETTINGS.Mode == "Timing" and SETTINGS.Enabled) then
			_N(("[Calib] you released %s at y=%s after %.2fs (ping %d ms) trace %s"):format(
				tostring(mtype), tostring(lastY), os.clock() - startedAt, getPing(), table.concat(samples, " ")))
		end
	end)
	if Output then
		conns.output = Output.OnClientEvent:Connect(function(kind, text)
			if kind == "Log" and type(text) == "string" and text:find("Shot Feedback", 1, true) then
				_N("[Calib] " .. text)
				_N(("[Row] meter=%s shot=%s hold=%s serverY=%s green(t:transp)=%s ping=%d -> %s%%"):format(
					tostring(mtype), tostring(text:match("Shot Type %- (%w+)")),
					lastHoldActual and ("%.3f"):format(lastHoldActual) or "?", lastY and ("%.3f"):format(lastY) or "?",
					lastGreenInfo, getPing(), tostring(text:match("Percentage %- ([%d%.]+)"))))
				if lastTimedHold then
					local pct = text:match("Percentage %- ([%d%.]+)")
					_N(("[Sweep] timed hold %.3fs (shot %d) -> %s%%"):format(lastTimedHold, sweepIndex, tostring(pct)))
				end
			end
		end)
	end
end

local function onShootStart()
	if Library.OnShoot then
		pcall(Library.OnShoot, "start")
	end
	shotStart = os.clock()
	shotToken += 1
	local token = shotToken
	local hold = SETTINGS.HoldTime
	local sweeping = false
	if not hold and SETTINGS.Sweep and sweepIndex < SETTINGS.Sweep.Count then
		hold = SETTINGS.Sweep.Start + sweepIndex * SETTINGS.Sweep.Step
		sweeping = true
	end
	lastTimedHold = nil

	if SETTINGS.Enabled and (SETTINGS.Mode == "Timing" or SETTINGS.Mode == "Predict") and hold then
		local ping = getPing()
		local delay = hold - SETTINGS.PingFactor * math.max(0, ping - SETTINGS.ReferencePing)

		local target = shotStart + math.max(0, delay)
		local hb
		hb = RunService.Heartbeat:Connect(function(dt)
			if stopped or shotToken ~= token then
				hb:Disconnect()
				return
			end
			if os.clock() + dt / 2 >= target then
				hb:Disconnect()
				if SETTINGS.Mode == "Predict" and meterSeenShot == token then
					return
				end
				lastTimedHold = hold
				if sweeping then
					sweepIndex += 1
				end
				lastHoldActual = os.clock() - shotStart
				ownRelease = true
				Shoot:FireServer({ Shoot = false })
				_N(("[AutoGreen] RELEASE by timing after %.3fs (target %.3fs, frame %.1f ms, ping %d ms)"):format(
					os.clock() - shotStart, target - shotStart, dt * 1000, ping))
			end
		end)
	end
end
local function onShootRelease()
	if Library.OnShoot then
		pcall(Library.OnShoot, "release")
	end
	local was = ownRelease
	if not was then
		lastHoldActual = shotStart and os.clock() - shotStart
	end
	ownRelease = false
	if was then
		return
	end
	shotToken += 1
	if SETTINGS.Calibrate and shotStart then
		_N(("[Calib] release (you or the game) after %.3fs hold (ping %d ms)"):format(os.clock() - shotStart, getPing()))
	end
end

if typeof(hookmetamethod) == "function" and typeof(getnamecallmethod) == "function" then
	local old
	old = hookmetamethod(game, "__namecall", (newcclosure or function(f) return f end)(function(self, ...)
		if not stopped and self == Shoot and getnamecallmethod() == "FireServer" then
			local arg = ...
			if typeof(arg) == "table" then
				if arg.Shoot == true and Library.ShootFilter and not stopped then

					local okF, replacement = pcall(Library.ShootFilter, arg)
					if okF and replacement then
						return old(self, replacement)
					end
				end
				if arg.Shoot == true then
					task.spawn(onShootStart)
				elseif arg.Shoot == false then
					task.spawn(onShootRelease)
				end
			end
		end
		return old(self, ...)
	end))
else
	_N("[AutoGreen] hookmetamethod unavailable: Timing mode cannot see your Shoot packets (calibration holds are not measured either).")
end

Env.AutoGreen7100 = {
	Settings = SETTINGS,
	Stop = function()
		stopped = true
		for _, c in pairs(conns) do
			c:Disconnect()
		end
		Env.AutoGreen7100 = nil
	end,
}
_N("[AutoGreen] loaded. Calibrate=" .. tostring(SETTINGS.Calibrate) .. " Debug=" .. tostring(SETTINGS.Debug))

		Library.AutoGreenStop = Env.AutoGreen7100 and Env.AutoGreen7100.Stop
	end)
	if not okA then
		Library:Notify({ Title = "Auto Time", Content = "Auto method failed to load: " .. tostring(errA), Type = "Error" })
	end
end
if arrivedByTeleport and Library:LoadConfig(TRANSFER_CONFIG) then
	Library:DeleteConfig(TRANSFER_CONFIG)
else
	Library:LoadAutoload()
end
if session.HideOnExecute then
	Library:Toggle(false)
end

return Library
