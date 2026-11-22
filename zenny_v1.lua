if shared._ZennyV1Running then
	shared._ZennyV1Running = false
	task.wait(0.25)
end
if shared._ZennyV1Gui then
	pcall(function() shared._ZennyV1Gui:Destroy() end)
	shared._ZennyV1Gui = nil
end
if shared._ZennyV1Visualizer then
	pcall(function() shared._ZennyV1Visualizer:Destroy() end)
	shared._ZennyV1Visualizer = nil
end
shared._ZennyV1Running = true

cloneref = cloneref or function(x) return x end
repeat task.wait() until game:IsLoaded()

local Players = cloneref(game:GetService("Players"))
local RunService = cloneref(game:GetService("RunService"))
local TweenService = cloneref(game:GetService("TweenService"))
local UserInputService = cloneref(game:GetService("UserInputService"))
local CoreGui = cloneref(game:GetService("CoreGui"))
local LP = Players.LocalPlayer

local VISUALIZER_IMAGE_ID = "rbxassetid://126103687650989"

local Cfg = {
	ZennyV1 = true,
	ShowVisualizer = true,
	PhysicsSenderRateActive = "15",
	PhysicsSenderRateDefault = "60",
	Radius = 14,
	VelocitySpeed = 350,
	CamSmoothSpeed = 24,
	CamHeightOffset = 1.6,
	VisualizerSmoothSpeed = 18,
	StepInterval = 0.08,
}

local function GetChar()
	return LP.Character
end

local function GetHRP(char)
	return char and (char.PrimaryPart or char:FindFirstChild("HumanoidRootPart"))
end

local function GetHum(char)
	return char and char:FindFirstChildOfClass("Humanoid")
end

local ZennyCamAnchor = Instance.new("Part")
ZennyCamAnchor.Name = "ZennyV1CamAnchor"
ZennyCamAnchor.Size = Vector3.new(0.1, 0.1, 0.1)
ZennyCamAnchor.Transparency = 1
ZennyCamAnchor.CanCollide = false
ZennyCamAnchor.CanTouch = false
ZennyCamAnchor.CanQuery = false
ZennyCamAnchor.Anchored = true
ZennyCamAnchor.Parent = workspace

-- ================= POSITION VISUALIZER =================
local VisualizerFolder = Instance.new("Folder")
VisualizerFolder.Name = "ZennyV1Visualizer"
VisualizerFolder.Parent = workspace
shared._ZennyV1Visualizer = VisualizerFolder

local VisualizerPart = Instance.new("Part")
VisualizerPart.Name = "TargetPositionPart"
VisualizerPart.Size = Vector3.new(0.2, 0.2, 0.2)
VisualizerPart.Transparency = 1
VisualizerPart.CanCollide = false
VisualizerPart.CanTouch = false
VisualizerPart.CanQuery = false
VisualizerPart.Anchored = true
VisualizerPart.Parent = VisualizerFolder

local VisualizerBillboard = Instance.new("BillboardGui")
VisualizerBillboard.Name = "PositionBillboard"
VisualizerBillboard.Adornee = VisualizerPart
VisualizerBillboard.Size = UDim2.fromScale(2.5, 2.5)
VisualizerBillboard.AlwaysOnTop = true
VisualizerBillboard.LightInfluence = 0
VisualizerBillboard.Enabled = Cfg.ShowVisualizer and Cfg.ZennyV1
VisualizerBillboard.Parent = VisualizerFolder

local VisualizerImage = Instance.new("ImageLabel")
VisualizerImage.Name = "PosIcon"
VisualizerImage.Size = UDim2.fromScale(1, 1)
VisualizerImage.AnchorPoint = Vector2.new(0.5, 0.5)
VisualizerImage.Position = UDim2.fromScale(0.5, 0.5)
VisualizerImage.BackgroundTransparency = 1
VisualizerImage.Image = VISUALIZER_IMAGE_ID
VisualizerImage.ImageColor3 = Color3.fromRGB(255, 255, 255)
VisualizerImage.ImageTransparency = (Cfg.ShowVisualizer and Cfg.ZennyV1) and 0 or 1
VisualizerImage.ScaleType = Enum.ScaleType.Fit
VisualizerImage.Parent = VisualizerBillboard

local visFadeTween = nil
local visScaleTween = nil
local visColorTween = nil
local visCurrentTargetVisible = nil
local visHideToken = 0

local desiredTargetPos = nil
local smoothVisualPos = nil
local lastFakePos = nil
local lastStepIndex = nil

local FadeInInfo = TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local FadeOutInfo = TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
local ColorTweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)

local function SetVisualizerFaded(visible)
	if not VisualizerBillboard or not VisualizerImage then return end
	if visCurrentTargetVisible == visible then return end
	visCurrentTargetVisible = visible

	visHideToken += 1
	local currentToken = visHideToken

	if visFadeTween then
		visFadeTween:Cancel()
		visFadeTween = nil
	end
	if visScaleTween then
		visScaleTween:Cancel()
		visScaleTween = nil
	end

	if visible then
		VisualizerBillboard.Enabled = true
		VisualizerImage.Size = UDim2.fromScale(0.82, 0.82)

		visFadeTween = TweenService:Create(VisualizerImage, FadeInInfo, {
			ImageTransparency = 0.08
		})
		visScaleTween = TweenService:Create(VisualizerImage, FadeInInfo, {
			Size = UDim2.fromScale(1, 1)
		})

		visFadeTween:Play()
		visScaleTween:Play()
	else
		visFadeTween = TweenService:Create(VisualizerImage, FadeOutInfo, {
			ImageTransparency = 1
		})
		visScaleTween = TweenService:Create(VisualizerImage, FadeOutInfo, {
			Size = UDim2.fromScale(0.75, 0.75)
		})

		visFadeTween.Completed:Connect(function(playbackState)
			if playbackState == Enum.PlaybackState.Completed and visHideToken == currentToken and not visCurrentTargetVisible then
				if VisualizerBillboard then
					VisualizerBillboard.Enabled = false
				end
			end
		end)

		visFadeTween:Play()
		visScaleTween:Play()
	end
end

local function UpdateVisualizerVisibility()
	local char = GetChar()
	local hrp = GetHRP(char)
	local hum = GetHum(char)
	local charReady = (hrp ~= nil and hum ~= nil and hum.Health > 0)
	local active = Cfg.ShowVisualizer and Cfg.ZennyV1 and shared._ZennyV1Running and charReady
	SetVisualizerFaded(active)
end

local function SetDesiredTarget(pos, stepIndex)
	desiredTargetPos = pos
	if stepIndex ~= lastStepIndex then
		lastStepIndex = stepIndex

		local targetColor
		if stepIndex == 0 then
			targetColor = Color3.fromRGB(255, 255, 255)
		elseif stepIndex == 1 then
			targetColor = Color3.fromRGB(200, 200, 200)
		else
			targetColor = Color3.fromRGB(150, 150, 150)
		end

		if VisualizerImage then
			if visColorTween then
				visColorTween:Cancel()
			end
			visColorTween = TweenService:Create(VisualizerImage, ColorTweenInfo, {
				ImageColor3 = targetColor
			})
			visColorTween:Play()
		end
	end
end

local function GetCamAnchorPos(basePos)
	return basePos + Vector3.new(0, Cfg.CamHeightOffset, 0)
end

local function SyncFakeCamera(dt)
	if not ZennyCamAnchor or not ZennyCamAnchor.Parent then return end
	local cam = workspace.CurrentCamera
	local char = GetChar()
	local hrp = GetHRP(char)
	local hum = GetHum(char)

	if not shared._ZennyV1Running or not Cfg.ZennyV1 or not hrp or not hum or hum.Health <= 0 then
		lastFakePos = nil
		if cam and cam.CameraSubject == ZennyCamAnchor and hum then
			cam.CameraSubject = hum
		end
		return
	end

	local anchorPos = GetCamAnchorPos(lastFakePos or hrp.Position)
	local camAlpha = 1 - math.exp(-Cfg.CamSmoothSpeed * math.clamp(dt or 0.016, 0, 0.1))
	ZennyCamAnchor.CFrame = CFrame.new(ZennyCamAnchor.Position:Lerp(anchorPos, camAlpha))

	if cam and cam.CameraSubject ~= ZennyCamAnchor then
		cam.CameraSubject = ZennyCamAnchor
	end
end

local visualConn = RunService.RenderStepped:Connect(function(dt)
	if not shared._ZennyV1Running then return end

	SyncFakeCamera(dt)

	if not Cfg.ShowVisualizer or not Cfg.ZennyV1 then return end
	if not VisualizerPart or not VisualizerPart.Parent then return end

	local char = GetChar()
	local hrp = GetHRP(char)
	if not hrp then return end

	local alpha = 1 - math.exp(-Cfg.VisualizerSmoothSpeed * math.clamp(dt, 0, 0.1))

	if desiredTargetPos then
		if not smoothVisualPos then
			smoothVisualPos = desiredTargetPos
		else
			smoothVisualPos = smoothVisualPos:Lerp(desiredTargetPos, alpha)
		end
		VisualizerPart.CFrame = CFrame.new(smoothVisualPos)
	end
end)

local function SetPhysicsRate(rateStr)
	pcall(function()
		if setfflag then
			setfflag("S2PhysicsSenderRate", tostring(rateStr))
		end
	end)
end

local function RestoreCameraAndPhysics()
	lastFakePos = nil
	local cam = workspace.CurrentCamera
	local hum = GetHum(GetChar())
	if cam and cam.CameraSubject == ZennyCamAnchor and hum then
		cam.CameraSubject = hum
	end
	SetPhysicsRate(Cfg.PhysicsSenderRateDefault)
	UpdateVisualizerVisibility()
end

local function StepZennyV1()
	if not shared._ZennyV1Running then
		RestoreCameraAndPhysics()
		return
	end

	local char = GetChar()
	local hrp = GetHRP(char)
	local hum = GetHum(char)
	local cam = workspace.CurrentCamera

	if not hrp or not hum or hum.Health <= 0 or not cam then
		lastFakePos = nil
		if cam and cam.CameraSubject == ZennyCamAnchor and hum then
			cam.CameraSubject = hum
		end
		SetVisualizerFaded(false)
		return
	end

	if not Cfg.ZennyV1 then
		RestoreCameraAndPhysics()
		return
	end

	local baseCF = hrp.CFrame + Vector3.new(0, 0.01, 0)
	hrp.CFrame = baseCF
	lastFakePos = baseCF.Position

	if ZennyCamAnchor and ZennyCamAnchor.Parent then
		ZennyCamAnchor.CFrame = CFrame.new(GetCamAnchorPos(baseCF.Position))
	end
	if cam.CameraSubject ~= ZennyCamAnchor then
		cam.CameraSubject = ZennyCamAnchor
	end
	SetPhysicsRate(Cfg.PhysicsSenderRateActive)

	local t = tick()
	local stepIndex = math.floor(t / Cfg.StepInterval) % 3
	local radius = Cfg.Radius
	local spd = Cfg.VelocitySpeed

	local lv = baseCF.LookVector
	local rv = baseCF.RightVector

	local offset = Vector3.zero
	local vel = Vector3.zero

	if stepIndex == 0 then
		offset = (-rv * radius) + (lv * (radius * 0.5))
		vel = -rv * spd
	elseif stepIndex == 1 then
		offset = (rv * radius) + (lv * (radius * 0.5))
		vel = rv * spd
	else
		offset = -lv * radius
		vel = -lv * spd
	end

	local origCF = baseCF
	local origVel = hrp.AssemblyLinearVelocity
	local targetCF = origCF * CFrame.new(offset)

	UpdateVisualizerVisibility()
	if Cfg.ShowVisualizer then
		SetDesiredTarget(targetCF.Position, stepIndex)
	end

	hrp.CFrame = targetCF
	hrp.AssemblyLinearVelocity = vel

	RunService.RenderStepped:Wait()

	if hrp and hrp.Parent then
		hrp.CFrame = origCF
		hrp.AssemblyLinearVelocity = origVel
		lastFakePos = origCF.Position
	end
end

local conn = RunService.Heartbeat:Connect(StepZennyV1)

local charAddedConn = LP.CharacterAdded:Connect(function()
	lastFakePos = nil
	smoothVisualPos = nil
	task.wait(0.1)
	if shared._ZennyV1Running and Cfg.ZennyV1 then
		local hrp = GetHRP(GetChar())
		if hrp and ZennyCamAnchor and ZennyCamAnchor.Parent then
			ZennyCamAnchor.CFrame = CFrame.new(GetCamAnchorPos(hrp.Position))
			lastFakePos = hrp.Position
		end
		UpdateVisualizerVisibility()
	end
end)

local ScreenGui
local UpdateToggleVisual
local UpdateVisToggleVisual
local UpdateRangeVisual

local function SetZennyV1(enabled)
	Cfg.ZennyV1 = (enabled == true)
	if not Cfg.ZennyV1 then
		RestoreCameraAndPhysics()
	else
		local hrp = GetHRP(GetChar())
		if hrp and ZennyCamAnchor and ZennyCamAnchor.Parent then
			lastFakePos = hrp.Position
			ZennyCamAnchor.CFrame = CFrame.new(GetCamAnchorPos(hrp.Position))
		end
		UpdateVisualizerVisibility()
	end
	if UpdateToggleVisual then
		UpdateToggleVisual(Cfg.ZennyV1)
	end
end

local function SetShowVisualizer(enabled)
	Cfg.ShowVisualizer = (enabled == true)
	UpdateVisualizerVisibility()
	if UpdateVisToggleVisual then
		UpdateVisToggleVisual(Cfg.ShowVisualizer)
	end
end

local function SetRange(val)
	Cfg.Radius = math.clamp(math.round(val), 1, 50)
	if UpdateRangeVisual then
		UpdateRangeVisual(Cfg.Radius)
	end
end

local function UnloadZennyV1()
	shared._ZennyV1Running = false
	Cfg.ZennyV1 = false
	if conn then
		conn:Disconnect()
		conn = nil
	end
	if visualConn then
		visualConn:Disconnect()
		visualConn = nil
	end
	if charAddedConn then
		charAddedConn:Disconnect()
		charAddedConn = nil
	end
	RestoreCameraAndPhysics()
	if ZennyCamAnchor then
		ZennyCamAnchor:Destroy()
		ZennyCamAnchor = nil
	end
	if VisualizerFolder then
		pcall(function() VisualizerFolder:Destroy() end)
		VisualizerFolder = nil
	end
	shared._ZennyV1Visualizer = nil
	if ScreenGui then
		pcall(function() ScreenGui:Destroy() end)
		ScreenGui = nil
	end
	shared._ZennyV1Gui = nil
end

local function AddGradient(parent, colorSequence, rotation)
	local grad = Instance.new("UIGradient")
	grad.Color = colorSequence
	grad.Rotation = rotation or 0
	grad.Parent = parent
	return grad
end

-- ================= MONOCHROME PALETTE =================
local MonoPalette = {
	MainBgStart = Color3.fromRGB(10, 10, 10),
	MainBgMid = Color3.fromRGB(20, 20, 20),
	MainBgEnd = Color3.fromRGB(6, 6, 6),

	BorderStart = Color3.fromRGB(255, 255, 255),
	BorderMid = Color3.fromRGB(110, 110, 110),
	BorderEnd = Color3.fromRGB(220, 220, 220),

	RowStart = Color3.fromRGB(15, 15, 15),
	RowEnd = Color3.fromRGB(30, 30, 30),
	RowStroke = Color3.fromRGB(180, 180, 180),

	TitleStart = Color3.fromRGB(255, 255, 255),
	TitleMid = Color3.fromRGB(210, 210, 210),
	TitleEnd = Color3.fromRGB(150, 150, 150),

	WhiteSoft = Color3.fromRGB(240, 240, 240),
	WhiteBright = Color3.fromRGB(255, 255, 255),
	GrayDeep = Color3.fromRGB(90, 90, 90),
	GrayMuted = Color3.fromRGB(165, 165, 165),
	OffTrackStart = Color3.fromRGB(24, 24, 24),
	OffTrackEnd = Color3.fromRGB(48, 48, 48),
	OffKnob = Color3.fromRGB(130, 130, 130),
	OffDot = Color3.fromRGB(75, 75, 75),
	BtnBg = Color3.fromRGB(22, 22, 22),
	KnobDark = Color3.fromRGB(12, 12, 12),
}

-- ================= GUI =================
local function CreateGUI()
	local EXPANDED_HEIGHT = 224
	local COLLAPSED_HEIGHT = 34

	local gui = Instance.new("ScreenGui")
	gui.Name = "ZennyV1Gui"
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	local parentOk = pcall(function()
		gui.Parent = (gethui and gethui()) or CoreGui
	end)
	if not parentOk or not gui.Parent then
		gui.Parent = LP:WaitForChild("PlayerGui")
	end

	shared._ZennyV1Gui = gui

	local Main = Instance.new("Frame")
	Main.Name = "Main"
	Main.Size = UDim2.fromOffset(236, EXPANDED_HEIGHT)
	Main.Position = UDim2.new(0.5, -118, 0.18, 0)
	Main.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	Main.BorderSizePixel = 0
	Main.ClipsDescendants = true
	Main.Active = true
	Main.Parent = gui

	AddGradient(Main, ColorSequence.new({
		ColorSequenceKeypoint.new(0, MonoPalette.MainBgStart),
		ColorSequenceKeypoint.new(0.5, MonoPalette.MainBgMid),
		ColorSequenceKeypoint.new(1, MonoPalette.MainBgEnd),
	}), 135)

	local MainCorner = Instance.new("UICorner")
	MainCorner.CornerRadius = UDim.new(0, 12)
	MainCorner.Parent = Main

	local MainStroke = Instance.new("UIStroke")
	MainStroke.Color = Color3.fromRGB(255, 255, 255)
	MainStroke.Transparency = 0.22
	MainStroke.Thickness = 1.2
	MainStroke.Parent = Main

	AddGradient(MainStroke, ColorSequence.new({
		ColorSequenceKeypoint.new(0, MonoPalette.BorderStart),
		ColorSequenceKeypoint.new(0.5, MonoPalette.BorderMid),
		ColorSequenceKeypoint.new(1, MonoPalette.BorderEnd),
	}), 45)

	local Header = Instance.new("Frame")
	Header.Name = "Header"
	Header.Size = UDim2.new(1, 0, 0, COLLAPSED_HEIGHT)
	Header.BackgroundTransparency = 1
	Header.Active = true
	Header.Parent = Main

	local Dot = Instance.new("Frame")
	Dot.Size = UDim2.fromOffset(8, 8)
	Dot.Position = UDim2.fromOffset(14, 13)
	Dot.BackgroundColor3 = MonoPalette.WhiteBright
	Dot.BorderSizePixel = 0
	Dot.Parent = Header
	Instance.new("UICorner", Dot).CornerRadius = UDim.new(1, 0)

	local Title = Instance.new("TextLabel")
	Title.Size = UDim2.new(1, -96, 1, 0)
	Title.Position = UDim2.fromOffset(28, 0)
	Title.BackgroundTransparency = 1
	Title.Text = "ZENNY V1"
	Title.TextColor3 = Color3.fromRGB(255, 255, 255)
	Title.TextSize = 13
	Title.Font = Enum.Font.GothamBold -- คงฟอนต์ชื่อ UI ไว้ตามเดิม
	Title.TextXAlignment = Enum.TextXAlignment.Left
	Title.Parent = Header

	AddGradient(Title, ColorSequence.new({
		ColorSequenceKeypoint.new(0, MonoPalette.TitleStart),
		ColorSequenceKeypoint.new(0.6, MonoPalette.TitleMid),
		ColorSequenceKeypoint.new(1, MonoPalette.TitleEnd),
	}), 0)

	local CollapseBtn = Instance.new("TextButton")
	CollapseBtn.Name = "CollapseBtn"
	CollapseBtn.Size = UDim2.fromOffset(24, 24)
	CollapseBtn.Position = UDim2.new(1, -60, 0, 5)
	CollapseBtn.BackgroundColor3 = MonoPalette.BtnBg
	CollapseBtn.Text = "−"
	CollapseBtn.TextColor3 = MonoPalette.WhiteSoft
	CollapseBtn.TextSize = 15
	CollapseBtn.Font = Enum.Font.Cartoon
	CollapseBtn.BorderSizePixel = 0
	CollapseBtn.Parent = Header
	Instance.new("UICorner", CollapseBtn).CornerRadius = UDim.new(0, 7)

	local CloseBtn = Instance.new("TextButton")
	CloseBtn.Name = "CloseBtn"
	CloseBtn.Size = UDim2.fromOffset(24, 24)
	CloseBtn.Position = UDim2.new(1, -32, 0, 5)
	CloseBtn.BackgroundColor3 = MonoPalette.BtnBg
	CloseBtn.Text = "×"
	CloseBtn.TextColor3 = MonoPalette.WhiteSoft
	CloseBtn.TextSize = 16
	CloseBtn.Font = Enum.Font.Cartoon
	CloseBtn.BorderSizePixel = 0
	CloseBtn.Parent = Header
	Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 7)

	CollapseBtn.MouseEnter:Connect(function()
		TweenService:Create(CollapseBtn, TweenInfo.new(0.15), {
			BackgroundColor3 = MonoPalette.WhiteSoft,
			TextColor3 = MonoPalette.KnobDark
		}):Play()
	end)
	CollapseBtn.MouseLeave:Connect(function()
		TweenService:Create(CollapseBtn, TweenInfo.new(0.15), {
			BackgroundColor3 = MonoPalette.BtnBg,
			TextColor3 = MonoPalette.WhiteSoft
		}):Play()
	end)

	CloseBtn.MouseEnter:Connect(function()
		TweenService:Create(CloseBtn, TweenInfo.new(0.15), {
			BackgroundColor3 = MonoPalette.WhiteBright,
			TextColor3 = MonoPalette.KnobDark
		}):Play()
	end)
	CloseBtn.MouseLeave:Connect(function()
		TweenService:Create(CloseBtn, TweenInfo.new(0.15), {
			BackgroundColor3 = MonoPalette.BtnBg,
			TextColor3 = MonoPalette.WhiteSoft
		}):Play()
	end)
	CloseBtn.MouseButton1Click:Connect(function()
		UnloadZennyV1()
	end)

	local Body = Instance.new("Frame")
	Body.Name = "Body"
	Body.Size = UDim2.new(1, 0, 0, EXPANDED_HEIGHT - COLLAPSED_HEIGHT)
	Body.Position = UDim2.fromOffset(0, COLLAPSED_HEIGHT)
	Body.BackgroundTransparency = 1
	Body.Parent = Main

	local Divider = Instance.new("Frame")
	Divider.Size = UDim2.new(1, -24, 0, 1)
	Divider.Position = UDim2.fromOffset(12, 0)
	Divider.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	Divider.BackgroundTransparency = 0.15
	Divider.BorderSizePixel = 0
	Divider.Parent = Body

	AddGradient(Divider, ColorSequence.new({
		ColorSequenceKeypoint.new(0, MonoPalette.RowStart),
		ColorSequenceKeypoint.new(0.5, MonoPalette.WhiteBright),
		ColorSequenceKeypoint.new(1, MonoPalette.RowStart),
	}), 0)

	local ToggleRow = Instance.new("TextButton")
	ToggleRow.Name = "ToggleRow"
	ToggleRow.Size = UDim2.new(1, -24, 0, 40)
	ToggleRow.Position = UDim2.fromOffset(12, 9)
	ToggleRow.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	ToggleRow.Text = ""
	ToggleRow.BorderSizePixel = 0
	ToggleRow.Parent = Body
	Instance.new("UICorner", ToggleRow).CornerRadius = UDim.new(0, 10)

	AddGradient(ToggleRow, ColorSequence.new({
		ColorSequenceKeypoint.new(0, MonoPalette.RowStart),
		ColorSequenceKeypoint.new(1, MonoPalette.RowEnd),
	}), 90)

	local RowStroke = Instance.new("UIStroke")
	RowStroke.Color = MonoPalette.RowStroke
	RowStroke.Transparency = 0.68
	RowStroke.Thickness = 1
	RowStroke.Parent = ToggleRow

	local StatusLabel = Instance.new("TextLabel")
	StatusLabel.Size = UDim2.new(1, -72, 1, 0)
	StatusLabel.Position = UDim2.fromOffset(12, 0)
	StatusLabel.BackgroundTransparency = 1
	StatusLabel.Text = "Status: ON"
	StatusLabel.TextColor3 = MonoPalette.TitleStart
	StatusLabel.TextSize = 12
	StatusLabel.Font = Enum.Font.Cartoon
	StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
	StatusLabel.Parent = ToggleRow

	local Track = Instance.new("Frame")
	Track.Size = UDim2.fromOffset(44, 24)
	Track.Position = UDim2.new(1, -54, 0.5, -12)
	Track.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	Track.BorderSizePixel = 0
	Track.Parent = ToggleRow
	Instance.new("UICorner", Track).CornerRadius = UDim.new(1, 0)

	local TrackGrad = AddGradient(Track, ColorSequence.new({
		ColorSequenceKeypoint.new(0, MonoPalette.WhiteBright),
		ColorSequenceKeypoint.new(1, MonoPalette.WhiteSoft),
	}), 0)

	local Knob = Instance.new("Frame")
	Knob.Size = UDim2.fromOffset(18, 18)
	Knob.Position = UDim2.fromOffset(23, 3)
	Knob.BackgroundColor3 = MonoPalette.KnobDark
	Knob.BorderSizePixel = 0
	Knob.Parent = Track
	Instance.new("UICorner", Knob).CornerRadius = UDim.new(1, 0)

	local VisRow = Instance.new("TextButton")
	VisRow.Name = "VisRow"
	VisRow.Size = UDim2.new(1, -24, 0, 40)
	VisRow.Position = UDim2.fromOffset(12, 55)
	VisRow.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	VisRow.Text = ""
	VisRow.BorderSizePixel = 0
	VisRow.Parent = Body
	Instance.new("UICorner", VisRow).CornerRadius = UDim.new(0, 10)

	AddGradient(VisRow, ColorSequence.new({
		ColorSequenceKeypoint.new(0, MonoPalette.RowStart),
		ColorSequenceKeypoint.new(1, MonoPalette.RowEnd),
	}), 90)

	local VisStroke = Instance.new("UIStroke")
	VisStroke.Color = MonoPalette.RowStroke
	VisStroke.Transparency = 0.68
	VisStroke.Thickness = 1
	VisStroke.Parent = VisRow

	local VisLabel = Instance.new("TextLabel")
	VisLabel.Size = UDim2.new(1, -72, 1, 0)
	VisLabel.Position = UDim2.fromOffset(12, 0)
	VisLabel.BackgroundTransparency = 1
	VisLabel.Text = "Visualizer: ON"
	VisLabel.TextColor3 = MonoPalette.TitleStart
	VisLabel.TextSize = 12
	VisLabel.Font = Enum.Font.Cartoon
	VisLabel.TextXAlignment = Enum.TextXAlignment.Left
	VisLabel.Parent = VisRow

	local VisTrack = Instance.new("Frame")
	VisTrack.Size = UDim2.fromOffset(44, 24)
	VisTrack.Position = UDim2.new(1, -54, 0.5, -12)
	VisTrack.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	VisTrack.BorderSizePixel = 0
	VisTrack.Parent = VisRow
	Instance.new("UICorner", VisTrack).CornerRadius = UDim.new(1, 0)

	local VisTrackGrad = AddGradient(VisTrack, ColorSequence.new({
		ColorSequenceKeypoint.new(0, MonoPalette.WhiteBright),
		ColorSequenceKeypoint.new(1, MonoPalette.WhiteSoft),
	}), 0)

	local VisKnob = Instance.new("Frame")
	VisKnob.Size = UDim2.fromOffset(18, 18)
	VisKnob.Position = UDim2.fromOffset(23, 3)
	VisKnob.BackgroundColor3 = MonoPalette.KnobDark
	VisKnob.BorderSizePixel = 0
	VisKnob.Parent = VisTrack
	Instance.new("UICorner", VisKnob).CornerRadius = UDim.new(1, 0)

	local RangeRow = Instance.new("Frame")
	RangeRow.Name = "RangeRow"
	RangeRow.Size = UDim2.new(1, -24, 0, 52)
	RangeRow.Position = UDim2.fromOffset(12, 101)
	RangeRow.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	RangeRow.BorderSizePixel = 0
	RangeRow.Parent = Body
	Instance.new("UICorner", RangeRow).CornerRadius = UDim.new(0, 10)

	AddGradient(RangeRow, ColorSequence.new({
		ColorSequenceKeypoint.new(0, MonoPalette.RowStart),
		ColorSequenceKeypoint.new(1, MonoPalette.RowEnd),
	}), 90)

	local RangeStroke = Instance.new("UIStroke")
	RangeStroke.Color = MonoPalette.RowStroke
	RangeStroke.Transparency = 0.68
	RangeStroke.Thickness = 1
	RangeStroke.Parent = RangeRow

	local RangeLabel = Instance.new("TextLabel")
	RangeLabel.Size = UDim2.new(0.65, -12, 0, 20)
	RangeLabel.Position = UDim2.fromOffset(12, 5)
	RangeLabel.BackgroundTransparency = 1
	RangeLabel.Text = "Range"
	RangeLabel.TextColor3 = MonoPalette.TitleStart
	RangeLabel.TextSize = 12
	RangeLabel.Font = Enum.Font.Cartoon
	RangeLabel.TextXAlignment = Enum.TextXAlignment.Left
	RangeLabel.Parent = RangeRow

	local RangeValueLabel = Instance.new("TextLabel")
	RangeValueLabel.Size = UDim2.new(0.35, -12, 0, 20)
	RangeValueLabel.Position = UDim2.new(0.65, 0, 0, 5)
	RangeValueLabel.BackgroundTransparency = 1
	RangeValueLabel.Text = tostring(Cfg.Radius)
	RangeValueLabel.TextColor3 = MonoPalette.WhiteSoft
	RangeValueLabel.TextSize = 12
	RangeValueLabel.Font = Enum.Font.Cartoon
	RangeValueLabel.TextXAlignment = Enum.TextXAlignment.Right
	RangeValueLabel.Parent = RangeRow

	local SliderHitbox = Instance.new("TextButton")
	SliderHitbox.Name = "SliderHitbox"
	SliderHitbox.Size = UDim2.new(1, -24, 0, 18)
	SliderHitbox.Position = UDim2.fromOffset(12, 27)
	SliderHitbox.BackgroundTransparency = 1
	SliderHitbox.Text = ""
	SliderHitbox.Parent = RangeRow

	local SliderBg = Instance.new("Frame")
	SliderBg.Size = UDim2.new(1, 0, 0, 6)
	SliderBg.Position = UDim2.new(0, 0, 0.5, -3)
	SliderBg.BackgroundColor3 = MonoPalette.BtnBg
	SliderBg.BorderSizePixel = 0
	SliderBg.Parent = SliderHitbox
	Instance.new("UICorner", SliderBg).CornerRadius = UDim.new(1, 0)

	local SliderFill = Instance.new("Frame")
	SliderFill.Size = UDim2.new(0, 0, 1, 0)
	SliderFill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	SliderFill.BorderSizePixel = 0
	SliderFill.Parent = SliderBg
	Instance.new("UICorner", SliderFill).CornerRadius = UDim.new(1, 0)

	AddGradient(SliderFill, ColorSequence.new({
		ColorSequenceKeypoint.new(0, MonoPalette.GrayDeep),
		ColorSequenceKeypoint.new(1, MonoPalette.WhiteBright),
	}), 0)

	local SliderKnob = Instance.new("Frame")
	SliderKnob.Size = UDim2.fromOffset(14, 14)
	SliderKnob.AnchorPoint = Vector2.new(0.5, 0.5)
	SliderKnob.Position = UDim2.new(0, 0, 0.5, 0)
	SliderKnob.BackgroundColor3 = MonoPalette.TitleStart
	SliderKnob.BorderSizePixel = 0
	SliderKnob.Parent = SliderBg
	Instance.new("UICorner", SliderKnob).CornerRadius = UDim.new(1, 0)

	local MinRange, MaxRange = 1, 50

	UpdateRangeVisual = function(val)
		local alpha = math.clamp((val - MinRange) / (MaxRange - MinRange), 0, 1)
		RangeValueLabel.Text = tostring(val)
		SliderFill.Size = UDim2.new(alpha, 0, 1, 0)
		SliderKnob.Position = UDim2.new(alpha, 0, 0.5, 0)
	end

	local sliding = false

	local function UpdateSliderFromX(inputX)
		local absPos = SliderBg.AbsolutePosition.X
		local absSize = SliderBg.AbsoluteSize.X
		if absSize <= 0 then return end
		local alpha = math.clamp((inputX - absPos) / absSize, 0, 1)
		local newVal = MinRange + alpha * (MaxRange - MinRange)
		SetRange(newVal)
	end

	SliderHitbox.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			sliding = true
			UpdateSliderFromX(input.Position.X)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			sliding = false
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			UpdateSliderFromX(input.Position.X)
		end
	end)

	local HintLabel = Instance.new("TextLabel")
	HintLabel.Size = UDim2.new(1, -24, 0, 16)
	HintLabel.Position = UDim2.fromOffset(12, 164)
	HintLabel.BackgroundTransparency = 1
	HintLabel.Text = "Drag header • − collapse • × unload"
	HintLabel.TextColor3 = MonoPalette.GrayMuted
	HintLabel.TextSize = 10
	HintLabel.Font = Enum.Font.Cartoon
	HintLabel.TextXAlignment = Enum.TextXAlignment.Left
	HintLabel.Parent = Body

	local collapsed = false
	CollapseBtn.MouseButton1Click:Connect(function()
		collapsed = not collapsed
		local targetHeight = collapsed and COLLAPSED_HEIGHT or EXPANDED_HEIGHT
		CollapseBtn.Text = collapsed and "+" or "−"
		Body.Visible = not collapsed
		TweenService:Create(Main, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
			Size = UDim2.fromOffset(236, targetHeight)
		}):Play()
	end)

	UpdateToggleVisual = function(state)
		local info = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		if state then
			StatusLabel.Text = "Status: ON"
			TrackGrad.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, MonoPalette.WhiteBright),
				ColorSequenceKeypoint.new(1, MonoPalette.WhiteSoft),
			})
			TweenService:Create(Knob, info, {
				Position = UDim2.fromOffset(23, 3),
				BackgroundColor3 = MonoPalette.KnobDark
			}):Play()
			TweenService:Create(Dot, info, { BackgroundColor3 = MonoPalette.WhiteBright }):Play()
		else
			StatusLabel.Text = "Status: OFF"
			TrackGrad.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, MonoPalette.OffTrackStart),
				ColorSequenceKeypoint.new(1, MonoPalette.OffTrackEnd),
			})
			TweenService:Create(Knob, info, {
				Position = UDim2.fromOffset(3, 3),
				BackgroundColor3 = MonoPalette.OffKnob
			}):Play()
			TweenService:Create(Dot, info, { BackgroundColor3 = MonoPalette.OffDot }):Play()
		end
	end

	UpdateVisToggleVisual = function(state)
		local info = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		if state then
			VisLabel.Text = "Visualizer: ON"
			VisTrackGrad.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, MonoPalette.WhiteBright),
				ColorSequenceKeypoint.new(1, MonoPalette.WhiteSoft),
			})
			TweenService:Create(VisKnob, info, {
				Position = UDim2.fromOffset(23, 3),
				BackgroundColor3 = MonoPalette.KnobDark
			}):Play()
		else
			VisLabel.Text = "Visualizer: OFF"
			VisTrackGrad.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, MonoPalette.OffTrackStart),
				ColorSequenceKeypoint.new(1, MonoPalette.OffTrackEnd),
			})
			TweenService:Create(VisKnob, info, {
				Position = UDim2.fromOffset(3, 3),
				BackgroundColor3 = MonoPalette.OffKnob
			}):Play()
		end
	end

	ToggleRow.MouseButton1Click:Connect(function()
		SetZennyV1(not Cfg.ZennyV1)
	end)

	VisRow.MouseButton1Click:Connect(function()
		SetShowVisualizer(not Cfg.ShowVisualizer)
	end)

	local dragging = false
	local dragInput, dragStart, startPos

	Header.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = Main.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	Header.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			local delta = input.Position - dragStart
			Main.Position = UDim2.new(
				startPos.X.Scale,
				startPos.X.Offset + delta.X,
				startPos.Y.Scale,
				startPos.Y.Offset + delta.Y
			)
		end
	end)

	UpdateToggleVisual(Cfg.ZennyV1)
	UpdateVisToggleVisual(Cfg.ShowVisualizer)
	UpdateRangeVisual(Cfg.Radius)
	return gui
end

ScreenGui = CreateGUI()