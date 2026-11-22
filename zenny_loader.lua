-- zenny private loader
-- host this file on YOUR github raw, then share loadstring(game:HttpGet("..."))()
-- EDIT the 2 URLs below to point to your own hosted scripts

if shared._ZennyLoaderGui then
	pcall(function() shared._ZennyLoaderGui:Destroy() end)
	shared._ZennyLoaderGui = nil
end

repeat task.wait() until game:IsLoaded()

local Players = cloneref and cloneref(game:GetService("Players")) or game:GetService("Players")
local TweenService = cloneref and cloneref(game:GetService("TweenService")) or game:GetService("TweenService")
local UserInputService = cloneref and cloneref(game:GetService("UserInputService")) or game:GetService("UserInputService")
local CoreGui = cloneref and cloneref(game:GetService("CoreGui")) or game:GetService("CoreGui")
local LP = Players.LocalPlayer

-- ===== EDIT THESE URLS to your own hosted scripts =====
local URL_ZENNY_V1      = "https://raw.githubusercontent.com/zeremonys/RobloxScript/main/zenny_v1.lua"
local URL_ZENNY_PRIVATE = "https://raw.githubusercontent.com/zeremonys/RobloxScript/main/zenny_private.lua"

local Selected = { Private = false, V1 = false }

local Palette = {
	MainBgStart = Color3.fromRGB(10, 10, 10),
	MainBgMid   = Color3.fromRGB(22, 22, 22),
	MainBgEnd   = Color3.fromRGB(6, 6, 6),
	BorderStart = Color3.fromRGB(245, 245, 245),
	BorderMid   = Color3.fromRGB(115, 115, 115),
	BorderEnd   = Color3.fromRGB(220, 220, 220),
	RowStart    = Color3.fromRGB(16, 16, 16),
	RowEnd      = Color3.fromRGB(34, 34, 34),
	RowStroke   = Color3.fromRGB(180, 180, 180),
	TitleStart  = Color3.fromRGB(255, 255, 255),
	TitleMid    = Color3.fromRGB(210, 210, 210),
	TitleEnd    = Color3.fromRGB(150, 150, 150),
	LightSoft   = Color3.fromRGB(235, 235, 235),
	LightBright = Color3.fromRGB(255, 255, 255),
	BtnBg       = Color3.fromRGB(24, 24, 24),
	KnobDark    = Color3.fromRGB(12, 12, 12),
}

local function AddGradient(parent, seq, rot)
	local g = Instance.new("UIGradient")
	g.Color, g.Rotation, g.Parent = seq, rot or 0, parent
	return g
end

local function RunRemote(url, label)
	task.spawn(function()
		local ok, err = pcall(function()
			local src = game:HttpGet(url)
			local fn = loadstring(src)
			if type(fn) == "function" then fn() else warn("[zenny] invalid chunk: " .. label) end
		end)
		if not ok then warn("[zenny] failed " .. label .. ": " .. tostring(err)) end
	end)
end

local gui = Instance.new("ScreenGui")
gui.Name = "ZennyLoaderGui"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local ok = pcall(function() gui.Parent = (gethui and gethui()) or CoreGui end)
if not ok or not gui.Parent then gui.Parent = LP:WaitForChild("PlayerGui") end
shared._ZennyLoaderGui = gui

local Main = Instance.new("Frame")
Main.Size = UDim2.fromOffset(252, 198)
Main.Position = UDim2.new(0.5, -126, 0.5, -99)
Main.BackgroundColor3 = Color3.new(1,1,1)
Main.BorderSizePixel = 0
Main.ClipsDescendants = true
Main.Active = true
Main.Parent = gui

AddGradient(Main, ColorSequence.new({
	ColorSequenceKeypoint.new(0, Palette.MainBgStart),
	ColorSequenceKeypoint.new(0.5, Palette.MainBgMid),
	ColorSequenceKeypoint.new(1, Palette.MainBgEnd),
}), 135)
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 12)

local Stroke = Instance.new("UIStroke")
Stroke.Color = Color3.new(1,1,1); Stroke.Transparency = 0.22; Stroke.Thickness = 1.2; Stroke.Parent = Main
AddGradient(Stroke, ColorSequence.new({
	ColorSequenceKeypoint.new(0, Palette.BorderStart),
	ColorSequenceKeypoint.new(0.5, Palette.BorderMid),
	ColorSequenceKeypoint.new(1, Palette.BorderEnd),
}), 45)

local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 34); Header.BackgroundTransparency = 1; Header.Active = true; Header.Parent = Main

local Dot = Instance.new("Frame")
Dot.Size = UDim2.fromOffset(8, 8); Dot.Position = UDim2.fromOffset(14, 13)
Dot.BackgroundColor3 = Palette.LightBright; Dot.BorderSizePixel = 0; Dot.Parent = Header
Instance.new("UICorner", Dot).CornerRadius = UDim.new(1, 0)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -68, 1, 0); Title.Position = UDim2.fromOffset(28, 0)
Title.BackgroundTransparency = 1
Title.Text = "zenny loader"
Title.TextColor3 = Color3.new(1,1,1); Title.TextSize = 13
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left; Title.Parent = Header
AddGradient(Title, ColorSequence.new({
	ColorSequenceKeypoint.new(0, Palette.TitleStart),
	ColorSequenceKeypoint.new(0.6, Palette.TitleMid),
	ColorSequenceKeypoint.new(1, Palette.TitleEnd),
}), 0)

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.fromOffset(24, 24); CloseBtn.Position = UDim2.new(1, -32, 0, 5)
CloseBtn.BackgroundColor3 = Palette.BtnBg; CloseBtn.Text = "×"; CloseBtn.TextColor3 = Palette.LightSoft
CloseBtn.TextSize = 16; CloseBtn.Font = Enum.Font.Cartoon; CloseBtn.BorderSizePixel = 0; CloseBtn.Parent = Header
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 7)
CloseBtn.MouseButton1Click:Connect(function()
	if shared._ZennyLoaderGui then
		pcall(function() shared._ZennyLoaderGui:Destroy() end)
		shared._ZennyLoaderGui = nil
	end
end)

local Divider = Instance.new("Frame")
Divider.Size = UDim2.new(1, -24, 0, 1); Divider.Position = UDim2.fromOffset(12, 34)
Divider.BackgroundColor3 = Color3.new(1,1,1); Divider.BackgroundTransparency = 0.15
Divider.BorderSizePixel = 0; Divider.Parent = Main
AddGradient(Divider, ColorSequence.new({
	ColorSequenceKeypoint.new(0, Palette.RowStart),
	ColorSequenceKeypoint.new(0.5, Palette.LightBright),
	ColorSequenceKeypoint.new(1, Palette.RowStart),
}), 0)

local function CreateCheckbox(y, text, key)
	local Row = Instance.new("TextButton")
	Row.Size = UDim2.new(1, -24, 0, 42); Row.Position = UDim2.fromOffset(12, y)
	Row.BackgroundColor3 = Color3.new(1,1,1); Row.Text = ""
	Row.AutoButtonColor = false; Row.BorderSizePixel = 0; Row.Parent = Main
	Instance.new("UICorner", Row).CornerRadius = UDim.new(0, 10)
	AddGradient(Row, ColorSequence.new({
		ColorSequenceKeypoint.new(0, Palette.RowStart),
		ColorSequenceKeypoint.new(1, Palette.RowEnd),
	}), 90)
	local RowStroke = Instance.new("UIStroke")
	RowStroke.Color = Palette.RowStroke; RowStroke.Transparency = 0.68; RowStroke.Thickness = 1; RowStroke.Parent = Row

	local Box = Instance.new("Frame")
	Box.Size = UDim2.fromOffset(20, 20); Box.Position = UDim2.fromOffset(12, 11)
	Box.BackgroundColor3 = Palette.BtnBg; Box.BorderSizePixel = 0; Box.Parent = Row
	Instance.new("UICorner", Box).CornerRadius = UDim.new(0, 6)
	local BS = Instance.new("UIStroke"); BS.Color = Palette.LightSoft; BS.Transparency = 0.45; BS.Thickness = 1.1; BS.Parent = Box

	local Check = Instance.new("TextLabel")
	Check.Size = UDim2.fromScale(1,1); Check.BackgroundTransparency = 1
	Check.Text = "✓"; Check.TextColor3 = Palette.KnobDark
	Check.TextSize = 13; Check.Font = Enum.Font.Cartoon; Check.TextTransparency = 1; Check.Parent = Box

	local Label = Instance.new("TextLabel")
	Label.Size = UDim2.new(1, -44, 1, 0); Label.Position = UDim2.fromOffset(40, 0)
	Label.BackgroundTransparency = 1; Label.Text = text; Label.TextColor3 = Palette.TitleStart
	Label.TextSize = 12; Label.Font = Enum.Font.Cartoon
	Label.TextXAlignment = Enum.TextXAlignment.Left; Label.Parent = Row

	local function refresh()
		local on = Selected[key]
		local info = TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		if on then
			TweenService:Create(Box, info, { BackgroundColor3 = Palette.LightBright }):Play()
			TweenService:Create(BS, info, { Transparency = 0.1 }):Play()
			TweenService:Create(Check, info, { TextTransparency = 0 }):Play()
			TweenService:Create(RowStroke, info, { Transparency = 0.25 }):Play()
		else
			TweenService:Create(Box, info, { BackgroundColor3 = Palette.BtnBg }):Play()
			TweenService:Create(BS, info, { Transparency = 0.45 }):Play()
			TweenService:Create(Check, info, { TextTransparency = 1 }):Play()
			TweenService:Create(RowStroke, info, { Transparency = 0.68 }):Play()
		end
	end
	Row.MouseButton1Click:Connect(function()
		Selected[key] = not Selected[key]
		refresh()
	end)
	refresh()
end

CreateCheckbox(44, "zenny private (main hub)", "Private")
CreateCheckbox(92, "zenny v1 (fake-position)", "V1")

local LoadBtn = Instance.new("TextButton")
LoadBtn.Size = UDim2.new(1, -24, 0, 38); LoadBtn.Position = UDim2.fromOffset(12, 146)
LoadBtn.BackgroundColor3 = Color3.new(1,1,1); LoadBtn.Text = "LOAD"
LoadBtn.TextColor3 = Palette.KnobDark; LoadBtn.TextSize = 12; LoadBtn.Font = Enum.Font.Cartoon
LoadBtn.AutoButtonColor = false; LoadBtn.BorderSizePixel = 0; LoadBtn.Parent = Main
Instance.new("UICorner", LoadBtn).CornerRadius = UDim.new(0, 10)
AddGradient(LoadBtn, ColorSequence.new({
	ColorSequenceKeypoint.new(0, Palette.LightBright),
	ColorSequenceKeypoint.new(1, Palette.LightSoft),
}), 0)

local loading = false
LoadBtn.MouseButton1Click:Connect(function()
	if loading then return end
	if not Selected.Private and not Selected.V1 then
		LoadBtn.Text = "SELECT SCRIPT FIRST"
		task.delay(1, function()
			if not loading and LoadBtn and LoadBtn.Parent then LoadBtn.Text = "LOAD" end
		end)
		return
	end
	loading = true
	LoadBtn.Text = "LOADING..."
	if Selected.Private then RunRemote(URL_ZENNY_PRIVATE, "zenny private") end
	if Selected.V1 then RunRemote(URL_ZENNY_V1, "zenny v1") end
	local fade = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(Main, fade, { Size = UDim2.fromOffset(252, 0) }):Play()
	task.wait(0.2)
	if shared._ZennyLoaderGui then
		pcall(function() shared._ZennyLoaderGui:Destroy() end)
		shared._ZennyLoaderGui = nil
	end
end)

-- drag
local dragging, dragInput, dragStart, startPos = false
Header.InputBegan:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
		dragging = true; dragStart = i.Position; startPos = Main.Position
		i.Changed:Connect(function() if i.UserInputState == Enum.UserInputState.End then dragging = false end end)
	end
end)
Header.InputChanged:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch then dragInput = i end
end)
UserInputService.InputChanged:Connect(function(i)
	if i == dragInput and dragging then
		local d = i.Position - dragStart
		Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
	end
end)
