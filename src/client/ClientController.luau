local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.GameConfig)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local ClientState = require(script.Parent.ClientState)

local player = Players.LocalPlayer

local ClientController = {}

local flashlightPart
local flashlightSpot
local regenTimer = 0

local function getEquippedSkinData()
	local skinId = ClientState.PlayerData.EquippedSkin or "default"
	for _, skin in Config.Shop.Flashlights do
		if skin.Id == skinId then
			return skin
		end
	end
	return Config.Shop.Flashlights[1]
end

local function hasUpgrade(upgId)
	if ClientState.PlayerData and ClientState.PlayerData.Upgrades then
		return table.find(ClientState.PlayerData.Upgrades, upgId) ~= nil
	end
	return false
end

local function setupFlashlight()
	flashlightPart = Instance.new("Part")
	flashlightPart.Name = "Flashlight"
	flashlightPart.Size = Vector3.new(0.3, 0.3, 0.3)
	flashlightPart.Transparency = 1
	flashlightPart.Anchored = true
	flashlightPart.CanCollide = false
	flashlightPart.CastShadow = false
	flashlightPart.Parent = Workspace

	flashlightSpot = Instance.new("SpotLight")
	flashlightSpot.Range = Config.Player.Flashlight.Range
	flashlightSpot.Angle = Config.Player.Flashlight.Angle
	flashlightSpot.Brightness = Config.Player.Flashlight.Brightness
	flashlightSpot.Color = Config.Colors.White
	flashlightSpot.Shadows = true
	flashlightSpot.Enabled = false
	flashlightSpot.Parent = flashlightPart
end

local function updateFlashlightStyle()
	if not flashlightSpot then
		return
	end
	local skin = getEquippedSkinData()
	flashlightSpot.Color = skin.Color
	flashlightSpot.Brightness = skin.Brightness or Config.Player.Flashlight.Brightness
end

local function updateStamina(dt)
	if ClientState.Downed then
		ClientState.Sprinting = false
		ClientState.SprintHeld = false
		return
	end

	local sprintHeld = ClientState.SprintHeld
	local drainRate = Config.Player.Stamina.SprintDrain
	local regenRate = Config.Player.Stamina.Regeneration

	if hasUpgrade("speed_boots") then
		regenRate *= 1.25
	end

	if sprintHeld and ClientState.Stamina > 0 then
		ClientState.Stamina = math.max(0, ClientState.Stamina - drainRate * dt)
		regenTimer = 0
	else
		sprintHeld = false
		regenTimer += dt
		if regenTimer > Config.Player.Stamina.RegenerationDelay then
			ClientState.Stamina = math.min(ClientState.MaxStamina, ClientState.Stamina + regenRate * dt)
		end
	end
	ClientState.Sprinting = sprintHeld

	local char = player.Character
	if char and not ClientState.Downed then
		local humanoid = char:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = if sprintHeld then Config.Player.SprintSpeed else Config.Player.WalkSpeed
		end
	end
end

local function updateFlashlight(dt)
	if ClientState.Downed or ClientState.InCCTV then
		ClientState.FlashlightOn = false
	end

	if ClientState.Battery <= 0 then
		ClientState.Battery = 0
		ClientState.FlashlightOn = false
	end

	local drainRate = Config.Player.Flashlight.BatteryDrain
	if hasUpgrade("heavy_battery") then
		drainRate *= 0.75
	end

	if ClientState.FlashlightOn then
		ClientState.Battery = math.max(0, ClientState.Battery - drainRate * dt)
		local camera = Workspace.CurrentCamera
		if camera then
			flashlightPart.CFrame = camera.CFrame * CFrame.new(0, 0, -1.2)
		end
		flashlightSpot.Enabled = true
	else
		ClientState.Battery = math.min(ClientState.MaxBattery, ClientState.Battery + Config.Player.Flashlight.BatteryRegenRate * dt)
		flashlightSpot.Enabled = false
	end
end

local function updateBleedout(dt)
	if ClientState.Downed then
		ClientState.BleedoutRemaining = math.max(0, ClientState.BleedoutRemaining - dt)
		local char = player.Character
		if char then
			local humanoid = char:FindFirstChildOfClass("Humanoid")
			if humanoid then
				humanoid.WalkSpeed = Config.Player.DownedSpeed
			end
		end
	else
		ClientState.BleedoutRemaining = Config.Player.Downed.BleedoutTime
	end
end

local function bindInput()
	ContextActionService:BindAction("SprintKey", function(_, inputState)
		if ClientState.Downed then
			ClientState.SprintHeld = false
			return Enum.ContextActionResult.Pass
		end
		ClientState.SprintHeld = (inputState == Enum.UserInputState.Begin or inputState == Enum.UserInputState.Change)
		return Enum.ContextActionResult.Sink
	end, false, Enum.KeyCode.LeftShift)

	ContextActionService:BindAction("FlashlightKey", function(_, inputState)
		if inputState == Enum.UserInputState.Begin then
			ClientState.RequestFlashlightToggle = true
		end
		return Enum.ContextActionResult.Sink
	end, false, Enum.KeyCode.F)
end

local function onCharacterAdded(char)
	local humanoid = char:WaitForChild("Humanoid")
	humanoid.WalkSpeed = Config.Player.WalkSpeed
	humanoid.JumpHeight = Config.Player.JumpHeight
	ClientState.Downed = false
	ClientState.Sprinting = false
	ClientState.BleedoutRemaining = Config.Player.Downed.BleedoutTime
end

function ClientController.Start()
	setupFlashlight()
	bindInput()

	if player.Character then
		onCharacterAdded(player.Character)
	end
	player.CharacterAdded:Connect(onCharacterAdded)

	Remotes.PlayerDataUpdated.OnClientEvent:Connect(function(data)
		ClientState.PlayerData = data
		updateFlashlightStyle()
	end)

	Remotes.PlayerDowned.OnClientEvent:Connect(function(downedPlayerName)
		if downedPlayerName == player.Name then
			ClientState.Downed = true
			ClientState.BleedoutRemaining = Config.Player.Downed.BleedoutTime
			local char = player.Character
			if char then
				local humanoid = char:FindFirstChildOfClass("Humanoid")
				if humanoid then
					humanoid.WalkSpeed = Config.Player.DownedSpeed
				end
			end
		end
	end)

	Remotes.PlayerRevived.OnClientEvent:Connect(function(revivedPlayerName)
		if revivedPlayerName == player.Name then
			ClientState.Downed = false
			local char = player.Character
			if char then
				local humanoid = char:FindFirstChildOfClass("Humanoid")
				if humanoid then
					humanoid.WalkSpeed = Config.Player.WalkSpeed
				end
			end
		end
	end)

	Remotes.RoundStateChanged.OnClientEvent:Connect(function(phase)
		ClientState.Phase = phase
		if phase == "Waiting" or phase == "Briefing" then
			ClientState.Downed = false
		end
	end)

	RunService.RenderStepped:Connect(function(dt)
		updateStamina(dt)
		updateFlashlight(dt)
		updateBleedout(dt)

		if ClientState.RequestFlashlightToggle then
			ClientState.RequestFlashlightToggle = false
			if not ClientState.Downed and not ClientState.InCCTV then
				ClientState.FlashlightOn = not ClientState.FlashlightOn
				updateFlashlightStyle()
			end
		end
	end)
end

return ClientController
