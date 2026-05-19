local Settings = getgenv and getgenv().ParrySettings or {}

local FORCE = tonumber(Settings.Force) or 300
local HEIGHT = tonumber(Settings.Height) or 205

local COOLDOWN = tonumber(Settings.Cooldown) or 2
local FLASH_TIME = tonumber(Settings.FlashTime) or 0.5
local FLASH_TRANSPARENCY = tonumber(Settings.FlashTransparency) or 0.5

local SOUND_ID = Settings.Sound1 or "rbxassetid://98660468032974"
local SOUND2_ID = Settings.Sound2 or "rbxassetid://139557908315922"
local VOLUME = tonumber(Settings.Volume) or 2

local IMAGE_ID = Settings.Image or "rbxassetid://124367011666371"
local IMAGE_TIME = tonumber(Settings.ImageTime) or 0.5

--// DEFAULTS
local FLASH_TRANSPARENCY = 0.5

local SOUND_ID = "rbxassetid://98660468032974"
local SOUND2_ID = "rbxassetid://139557908315922"
local VOLUME = 2

local IMAGE_ID = "rbxassetid://124367011666371"
local IMAGE_TIME = 0.5

--// SERVICES
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")

local player = Players.LocalPlayer
if not player then
	return
end

local playerGui = player:WaitForChild("PlayerGui")

--// REMOVE OLD GUI
local old = playerGui:FindFirstChild("ParryFlingGUI")
if old then
	old:Destroy()
end

--// GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ParryFlingGUI"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui

--// FLASH
local flash = Instance.new("Frame")
flash.Parent = screenGui
flash.Size = UDim2.new(1,0,1,0)
flash.BackgroundColor3 = Color3.new(1,1,1)
flash.BorderSizePixel = 0
flash.BackgroundTransparency = 1
flash.ZIndex = 999

--// SOUNDS
local sound1 = Instance.new("Sound")
sound1.Parent = screenGui
sound1.SoundId = SOUND_ID
sound1.Volume = VOLUME

local sound2 = Instance.new("Sound")
sound2.Parent = screenGui
sound2.SoundId = SOUND2_ID
sound2.Volume = VOLUME

--// IMAGE
local image = Instance.new("ImageLabel")
image.Parent = screenGui
image.Size = UDim2.new(1,0,1,0)
image.Position = UDim2.new(0,0,0,0)
image.BackgroundTransparency = 1
image.Image = IMAGE_ID
image.Visible = false
image.ImageTransparency = 0
image.ZIndex = 998

--// MAIN BUTTON
local button = Instance.new("TextButton")
button.Parent = screenGui
button.Size = UDim2.new(0,150,0,60)
button.Position = UDim2.new(0.5,-75,0.85,0)
button.Text = "FLING"
button.TextScaled = true
button.Font = Enum.Font.GothamBold
button.BackgroundColor3 = Color3.fromRGB(30,30,30)
button.TextColor3 = Color3.new(1,1,1)
button.Active = true
button.AutoButtonColor = true
button.BorderSizePixel = 0

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0,12)
corner.Parent = button

--// CLOSE BUTTON
local close = Instance.new("TextButton")
close.Parent = screenGui
close.Size = UDim2.new(0,50,0,50)
close.Position = UDim2.new(0.5,80,0.75,0)
close.Text = "X"
close.TextScaled = true
close.Font = Enum.Font.GothamBold
close.BackgroundColor3 = Color3.fromRGB(150,0,0)
close.TextColor3 = Color3.new(1,1,1)
close.BorderSizePixel = 0

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0,12)
closeCorner.Parent = close

close.MouseButton1Click:Connect(function()
	screenGui:Destroy()
end)

--// DRAGGING
local dragging = false
local dragStart
local startPos

button.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1
	or input.UserInputType == Enum.UserInputType.Touch then

		dragging = true
		dragStart = input.Position
		startPos = button.Position

		local changedConn
		changedConn = input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
				if changedConn then
					changedConn:Disconnect()
				end
			end
		end)
	end
end)

UIS.InputChanged:Connect(function(input)
	if dragging and (
		input.UserInputType == Enum.UserInputType.MouseMovement
		or input.UserInputType == Enum.UserInputType.Touch
	) then

		local delta = input.Position - dragStart

		button.Position = UDim2.new(
			startPos.X.Scale,
			startPos.X.Offset + delta.X,
			startPos.Y.Scale,
			startPos.Y.Offset + delta.Y
		)
	end
end)

--// ABILITY
local debounce = false

local function doEffect(character)
	if not character then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")
	local head = character:FindFirstChild("Head")

	if not humanoid or not root or not head then
		return
	end

	-- SOUND 1
	sound1:Play()

	-- FLASH
	flash.BackgroundTransparency = FLASH_TRANSPARENCY

	task.delay(FLASH_TIME, function()
		if flash then
			flash.BackgroundTransparency = 1
		end
	end)

	-- SOUND 2 + IMAGE
	task.delay(0.5, function()

		if not screenGui.Parent then
			return
		end

		sound2:Stop()
		sound2.TimePosition = 0
		sound2:Play()

		image.Visible = true
		image.ImageTransparency = 0

		task.spawn(function()

			task.wait(IMAGE_TIME)

			for i = 1, 20 do
				if not image.Parent then
					return
				end

				image.ImageTransparency = i / 20
				task.wait(0.02)
			end

			image.Visible = false
			image.ImageTransparency = 0
		end)
	end)

	-- FREEZE
	local oldWalk = humanoid.WalkSpeed
	local oldJump = humanoid.JumpPower

	humanoid.WalkSpeed = 0
	humanoid.JumpPower = 0

	local conn
	conn = RunService.Heartbeat:Connect(function()
		if root and root.Parent then
			root.AssemblyLinearVelocity = Vector3.zero
		end
	end)

	task.wait(0.4)

	if conn then
		conn:Disconnect()
	end

	-- RESTORE
	humanoid.WalkSpeed = oldWalk
	humanoid.JumpPower = oldJump

	-- FLING
	local dir = head.CFrame.LookVector.Unit

	root.AssemblyLinearVelocity =
		(dir * FORCE) + Vector3.new(0, HEIGHT, 0)

	-- SPIN
	local spin = Instance.new("BodyAngularVelocity")
	spin.AngularVelocity = Vector3.new(
		math.random(-80,80),
		math.random(-80,80),
		math.random(-80,80)
	)

	spin.MaxTorque = Vector3.new(1e6,1e6,1e6)
	spin.P = 1e5
	spin.Parent = root

	task.delay(0.25, function()
		if spin and spin.Parent then
			spin:Destroy()
		end
	end)

	-- EXTRA SAFETY
	task.delay(0.1, function()
		if humanoid and humanoid.Parent then
			humanoid.WalkSpeed = oldWalk
			humanoid.JumpPower = oldJump
		end
	end)
end

--// CLICK
button.MouseButton1Click:Connect(function()

	if debounce then
		return
	end

	debounce = true
	button.Text = "GO"

	local char = player.Character or player.CharacterAdded:Wait()

	pcall(function()
		doEffect(char)
	end)

	task.wait(COOLDOWN)

	if button and button.Parent then
		button.Text = "FLING"
	end

	debounce = false
end)