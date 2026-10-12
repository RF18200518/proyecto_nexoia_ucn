local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.GameConfig)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local AnomalyService = {}

local currentAnomaly = nil
local playerGuesses = {}
local spawnedInstances = {}

local function cleanup()
	for _, inst in spawnedInstances do
		if inst and inst.Parent then
			inst:Destroy()
		end
	end
	spawnedInstances = {}
	playerGuesses = {}
	currentAnomaly = nil
end

local function spawnMannequin()
	local mannequin = Instance.new("Model")
	mannequin.Name = "Anomaly_Mannequin"

	local body = Instance.new("Part")
	body.Name = "Body"
	body.Size = Vector3.new(1.2, 4.5, 0.8)
	body.Position = Vector3.new(-19.5, 3.5, -6)
	body.Color = Color3.fromRGB(220, 215, 200)
	body.Material = Enum.Material.SmoothPlastic
	body.Anchored = true
	body.CanCollide = true
	body.Parent = mannequin

	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = Vector3.new(0.8, 0.8, 0.8)
	head.Position = body.Position + Vector3.new(0, 2.6, 0)
	head.Color = Color3.fromRGB(220, 215, 200)
	head.Material = Enum.Material.SmoothPlastic
	head.Anchored = true
	head.CanCollide = false
	head.Parent = mannequin

	mannequin.PrimaryPart = body
	mannequin.Parent = Workspace
	table.insert(spawnedInstances, mannequin)
end

local function spawnFloatingProducts()
	local folder = Instance.new("Folder")
	folder.Name = "Anomaly_FloatingProducts"
	folder.Parent = Workspace

	for i = 1, 6 do
		local p = Instance.new("Part")
		p.Name = "FloatingProduct_" .. i
		p.Size = Vector3.new(0.6, 0.8, 0.6)
		p.Position = Vector3.new(-6.5 + (i % 2) * 1.5, 5.2 + (i * 0.3), -8 + i * 2.5)
		p.Color = Color3.fromRGB(255, 180, 50)
		p.Material = Enum.Material.Neon
		p.Anchored = true
		p.CanCollide = false
		p.Parent = folder

		local light = Instance.new("PointLight")
		light.Color = Color3.fromRGB(255, 180, 50)
		light.Brightness = 0.5
		light.Range = 6
		light.Parent = p

		table.insert(spawnedInstances, p)
	end
	table.insert(spawnedInstances, folder)
end

local function spawnGlitchedClock()
	local map = Workspace:FindFirstChild("Map")
	if not map then
		return
	end
	local deco = map:FindFirstChild("Decorations")
	if not deco then
		return
	end
	local clock = deco:FindFirstChild("WallClock")
	if clock then
		local gui = clock:FindFirstChild("Gui")
		if gui then
			local label = gui:FindFirstChildOfClass("TextLabel")
			if label then
				label.Text = "66:66"
				label.TextColor3 = Config.Colors.NeonRed
			end
		end
	end
end

local function spawnShadowClerk()
	local shadow = Instance.new("Part")
	shadow.Name = "Anomaly_ShadowClerk"
	shadow.Size = Vector3.new(1.4, 5, 1)
	shadow.Position = Vector3.new(-58, 3.5, -36)
	shadow.Color = Color3.fromRGB(5, 5, 8)
	shadow.Material = Enum.Material.SmoothPlastic
	shadow.Transparency = 0.2
	shadow.Anchored = true
	shadow.CanCollide = false
	shadow.Parent = Workspace
	table.insert(spawnedInstances, shadow)
end

function AnomalyService.Init()
	Remotes.SubmitAnomalyGuess.OnServerEvent:Connect(function(player, guessId)
		playerGuesses[player.UserId] = guessId
		Remotes.ShowMessage:FireClient(player, "Has registrado tu sospecha de anomalia.")
	end)
end

function AnomalyService.StartRound()
	cleanup()
	local list = Config.Anomalies
	currentAnomaly = list[math.random(1, #list)]

	if currentAnomaly.Id == "Mannequin" then
		spawnMannequin()
	elseif currentAnomaly.Id == "FloatingProducts" then
		spawnFloatingProducts()
	elseif currentAnomaly.Id == "GlitchedClock" then
		spawnGlitchedClock()
	elseif currentAnomaly.Id == "ShadowClerk" then
		spawnShadowClerk()
	end
end

function AnomalyService.GetResultForPlayer(player)
	if not currentAnomaly then
		return false, "Ninguna", nil
	end
	local guess = playerGuesses[player.UserId]
	local correct = (guess == currentAnomaly.Id)
	return correct, currentAnomaly.Name, currentAnomaly
end

function AnomalyService.GetCurrentAnomaly()
	return currentAnomaly
end

function AnomalyService.Reset()
	cleanup()
end

return AnomalyService
