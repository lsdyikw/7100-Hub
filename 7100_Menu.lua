--[[
	7100 menu
	Loads the UI library from GitHub, then builds the menu.
	Replace LIBRARY_URL with the raw link to 7100_UI.lua in your repo.
]]

local LIBRARY_URL = "https://raw.githubusercontent.com/lsdyikw/7100-Hub/main/7100_UI.lua"

local Library = loadstring(game:HttpGet(LIBRARY_URL))()

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local new = Library.Create
local rgb = Library.RGB


-- Branding: purple / black theme and the 7100 name (both before CreateWindow)
Library:SetTheme("Purple")
Library.Name = "7100"

--[[
	The 7100 wordmark, drawn with frames so it needs no uploaded image.
	Shapes are traced from the logo (1372 x 253 units) and scaled to fit the header.
	Clip frames are never rotated, so the rotated pieces inside them get cut cleanly.
]]
local LOGO_PURPLE = Color3.fromRGB(132, 10, 255)
-- Draw7100(holder, height, sevenOnly, colour): full wordmark, or just the "7" (used for the cursor)
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
		local t = 64 -- stroke thickness; the stroke is drawn outside the inner frame
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

	-- 7: top bar, bevelled left end, diagonal stroke
	rect(62, 0, 373, 58)
	rotated(100.5, -41.8, 200, 200, 44.06, clip(0, 0, 62, 60))
	rotated(189.5, 101.5, 440, 81.5, 141.87, clip(52, 53, 383, 200))
	if sevenOnly then
		return logo
	end
	-- 1
	rect(470, 0, 88, 253)
	-- 0 0 (rounded rectangles)
	ring(589, 369)
	ring(988, 384)
	return logo
end

-- Key system (optional). Remove this block if the script has no keys.
local USE_KEY_SYSTEM = false
if USE_KEY_SYSTEM then
	Library:KeySystem({
		Title = "7100",
		Note = "Get a key from our Discord to continue.",
		Link = "https://discord.gg/your-invite",
		Validate = function(key)
			return key == "6L4M-DEMO-KEY" -- replace with your real check
		end,
	})
end

--[[
	Logo cursor: the "7" from the wordmark. Its sharp top-left corner is the click point,
	so it works like a normal pointer. A soft dark copy behind it keeps it readable on
	any background. It shrinks a little when you click.
]]
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

local Window = Library:CreateWindow({
	Title = "7100",
	LogoBuilder = Draw7100,            -- drawn purple 7100 wordmark
	MobileIcon = function(frame)       -- the "7" on the phone / tablet open button
		Draw7100(frame, 16, true)
	end,
	-- MobileButton = true,             -- force the mobile button on PC (for testing)
	-- Logo = "rbxassetid://0000000",   -- or an uploaded wordmark image (transparent PNG)
	-- TabStyle = "Outline",            -- OT's white outline on the selected tab
	Footer = "v" .. Library.Version .. " · " .. Library.Device:upper() .. " · " .. LocalPlayer.Name, -- e.g. "v1.2.0 · MOBILE · name"
	Intro = true,
})

-- 6L4M HUB ------------------------------------------------------------------
local Home = Window:AddTab("7100")

local Status = Home:AddSection("Status", "Left")
Status:AddLabel("Game: Placeholder")
Status:AddLabel("Access: all access")
Status:AddLabel("Unlocked 0   Locked 0")

local Configs = Home:AddSection("Configs", "Left")
Configs:AddLabel({ Text = "Saved on 6l4m.xyz -- the same list as your dashboard's Saved Configs.", Small = true })
Configs:AddConfigManager()

local Account = Home:AddSection("Account", "Right")
Account:AddLabel("Real key: no ads. Thank you!")

local Session = Home:AddSection("Session", "Right")
Session:AddToggle({ Name = "Re-run after teleport", Default = true, Flag = "Rerun" })
Session:AddToggle({ Name = "Hide Menu On Execute", Default = true, Flag = "HideOnExecute" })
Session:AddToggle({ Name = "Streamer Mode", Flag = "StreamerMode", Tooltip = "Hides your name in the menu" })

-- SHOOTING ------------------------------------------------------------------
local Shooting = Window:AddTab("Shooting")

local AutoTime = Shooting:AddSection("Auto Time", "Left")
AutoTime:AddToggle({ Name = "Auto Time", Default = true, Flag = "AutoTime" }):AddKeybind({ Default = Enum.KeyCode.T, Flag = "AutoTimeKey" })
local atOptions = AutoTime:AddOptions("Options")
atOptions:AddSlider({ Name = "Timing Offset", Min = -100, Max = 100, Default = 0, Suffix = "ms", Flag = "TimingOffset" })
atOptions:AddDropdown({ Name = "Release", Options = { "Perfect", "Early", "Late" }, Default = "Perfect", Flag = "Release" })

local Contest = Shooting:AddSection("Contest Detector", "Left")
Contest:AddToggle({ Name = "Contest Detector", Flag = "ContestDetector" })
Contest:AddToggle({ Name = "Contest Highlight", Flag = "ContestHighlight" }):AddColorPicker({ Default = rgb(255, 255, 255), Flag = "ContestColor" })

local Foul = Shooting:AddSection("Foul Bait", "Left")
Foul:AddToggle({ Name = "Foul Bait Helper", Flag = "FoulBait" })
Foul:AddOptions("Options"):AddSlider({ Name = "Delay", Min = 0, Max = 500, Default = 120, Suffix = "ms", Flag = "FoulDelay" })

local Legit = Shooting:AddSection("Legit Check", "Right")
Legit:AddToggle({ Name = "Legit Warnings (HUD)", Flag = "LegitWarnings" })
Legit:AddSlider({ Name = "Warn Above Perfect %", Min = 0, Max = 100, Default = 50, Flag = "WarnAbove" })
Legit:AddButton({ Name = "Reset All-Time Stats", Callback = function()
	Library:Notify({ Title = "Stats", Content = "All-time stats reset.", Type = "Success" })
end })

local Stepback = Shooting:AddSection("Stepback Helper", "Right")
Stepback:AddToggle({ Name = "Stepback Helper", Default = true, Flag = "Stepback" })
Stepback:AddDropdown({ Name = "Help On", Options = { "Backstep", "Sidestep", "Hop" }, Multi = true, Default = { "Backstep", "Sidestep" }, Flag = "HelpOn" })

local Dunk = Shooting:AddSection("Dunk Key", "Right")
Dunk:AddKeybind({ Name = "Dunk Key", Default = Enum.KeyCode.E, Flag = "DunkKey" })

-- PLAYER --------------------------------------------------------------------
local PlayerTab = Window:AddTab("Player")

local LegitSpeed = PlayerTab:AddSection("Legit Speed", "Left")
LegitSpeed:AddToggle({ Name = "Legit Speed", Default = true, Flag = "LegitSpeed" })
LegitSpeed:AddOptions("Options"):AddSlider({ Name = "Boost", Min = 0, Max = 10, Default = 2, Increment = 0.1, Flag = "LegitBoost" })

local Illegal = PlayerTab:AddSection("Anti Illegal Screen", "Left")
Illegal:AddToggle({ Name = "Anti Illegal Screen", Flag = "AntiIllegal" })

local Turn = PlayerTab:AddSection("Instant Turn & Anti Decel", "Left")
Turn:AddToggle({ Name = "Instant Turn", Flag = "InstantTurn" })
Turn:AddSlider({ Name = "Turn Time (ms)", Min = 0, Max = 500, Default = 120, Flag = "TurnTime" })

local Utility = PlayerTab:AddSection("Utility", "Right")
Utility:AddToggle({ Name = "Anti Stun", Flag = "AntiStun" })
Utility:AddToggle({ Name = "Infinite Dribble Stamina", Flag = "InfStamina", Locked = true, LockReason = "Premium" })

local Speed = PlayerTab:AddSection("Speed", "Right")
Speed:AddToggle({ Name = "Screening Speed", Flag = "ScreenSpeed" })
Speed:AddSlider({ Name = "Speed (studs/sec)", Min = 0, Max = 30, Default = 15.2, Increment = 0.001, Flag = "ScreenSpeedVal" })
Speed:AddToggle({ Name = "With Ball Speed", Flag = "BallSpeed" })
Speed:AddSlider({ Name = "Speed (studs/sec)", Min = 0, Max = 30, Default = 15.2, Increment = 0.001, Flag = "BallSpeedVal" })

-- section with a subtitle line (like OT's "INBOUND OPTIONS / AUTO JOIN SPOT")
local Inbound = PlayerTab:AddSection("Inbound Options", "Right", { Subtitle = "Auto Join Spot" })
Inbound:AddToggle({ Name = "Auto Join Spot", Flag = "AutoJoinSpot" })
Inbound:AddSlider({ Name = "Fire Interval (sec)", Min = 0.1, Max = 2, Default = 0.1, Increment = 0.01, Flag = "FireInterval" })
Inbound:AddToggle({ Name = "Burst All Courts", Flag = "BurstCourts" })
Inbound:AddHeader("Pass Type")
Inbound:AddToggle({ Name = "Force Simple Pass", Flag = "SimplePass" })
Inbound:AddToggle({ Name = "Smart Pass Type", Flag = "SmartPass" })

local Legit2 = PlayerTab:AddSection("Legit Speed Ratings", "Left")
Legit2:AddSlider({ Name = "Speed Rating", Min = 25, Max = 99, Default = 89, Flag = "SpeedRating" })
Legit2:AddSlider({ Name = "With Ball Speed Rating", Min = 25, Max = 99, Default = 91, Flag = "BallSpeedRating" })
Legit2:AddDropdown({
	Name = "Legit Speed...",
	Dim = true,
	Options = { "Sprint", "Jog", "Dribble", "Defense", "Screen", "Cut", "Post", "Transition", "Fast Break", "Half Court" },
	Multi = true,
	Default = { "Sprint", "Jog", "Dribble" },
	Flag = "LegitSpeedModes",
})

-- placeholder tabs ----------------------------------------------------------
for _, name in ipairs({ "Cosmetics", "Dribbling", "Defense" }) do
	local t = Window:AddTab(name)
	t:AddSection("Placeholder", "Left"):AddToggle({ Name = name .. " Option", Flag = name .. "Option" })
end

-- BADGES --------------------------------------------------------------------
local Badges = Window:AddTab("Badges")
local Sim = Badges:AddSection("Badge Simulation", "Left")
Sim:AddToggle({ Name = "Badge Simulation", Flag = "BadgeSim" })
Sim:AddSlider({ Name = "Badge Strength (%)", Min = 0, Max = 100, Default = 100, Flag = "BadgeStrength" })
Sim:AddLabel({ Text = "Your ratings scale every effect. Adjust strength to taste.", Centered = true })

local LEVELS = { "Off", "Bronze", "Silver", "Gold", "HOF" }
local Handles = Badges:AddSection("Handles", "Left")
Handles:AddDropdown({ Name = "Space Maker", Options = LEVELS, Default = "Off", Flag = "SpaceMaker" })
Handles:AddDropdown({ Name = "Quick Handles", Options = LEVELS, Default = "Off", Flag = "QuickHandles" })

local Finishing = Badges:AddSection("Finishing", "Right")
Finishing:AddDropdown({ Name = "Gymnast", Options = LEVELS, Default = "Off", Flag = "Gymnast" })

local DefenseB = Badges:AddSection("Defense", "Right")
DefenseB:AddDropdown({ Name = "Locks", Options = LEVELS, Default = "Off", Flag = "Locks" })

-- SETTINGS ------------------------------------------------------------------
-- ready-made tab: Configuration (config manager) + Interface; returns the tab for extra sections
local Settings = Window:AddSettingsTab()

local Menu = Settings:AddSection("Menu Mode", "Left")
Menu:AddDropdown({ Name = "Mode", Options = { "Simple", "Advanced" }, Default = "Simple", Flag = "MenuMode" })

local Diag = Settings:AddSection("Diagnostics", "Left")
Diag:AddToggle({ Name = "Scope Readout (HUD)", Flag = "ScopeReadout" })
Diag:AddToggle({ Name = "Draw court box + range ring", Flag = "CourtBox" }):AddColorPicker({ Default = rgb(255, 255, 255), Flag = "CourtBoxColor" })

local Fps = Settings:AddSection("FPS Booster", "Right")
Fps:AddToggle({ Name = "FPS Booster", Flag = "FpsBooster" })
Fps:AddDropdown({
	Name = "Boost",
	Options = { "Shadows", "Particles", "Textures", "Decals", "Lighting", "Water", "Post FX" },
	Multi = true,
	Default = { "Shadows", "Particles", "Textures", "Decals", "Lighting", "Water", "Post FX" },
	Flag = "Boost",
})
Fps:AddSlider({ Name = "FPS Cap", Min = 30, Max = 360, Default = 240, Flag = "FpsCap" })
Fps:AddSlider({ Name = "Graphics Level", Min = 1, Max = 10, Default = 6, Flag = "GraphicsLevel" })
Fps:AddSlider({ Name = "Player Distance", Min = 0, Max = 300, Default = 100, Flag = "PlayerDistance" })

local Movement = Settings:AddSection("Movement", "Right")
Movement:AddToggle({ Name = "Movement Option", Flag = "MovementOption" })

Library:LoadAutoload()

return Library
