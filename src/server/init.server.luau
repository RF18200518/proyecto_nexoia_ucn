local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local status = Instance.new("Part")
status.Name = "ServerStatus"
status.Anchored = true
status.CanCollide = false
status.Size = Vector3.new(12, 4, 0.1)
status.Position = Vector3.new(0, 30, 0)
status.Color = Color3.fromRGB(60, 60, 70)
status.Transparency = 0.2
status.Parent = Workspace

local gui = Instance.new("BillboardGui")
gui.Name = "StatusGui"
gui.Size = UDim2.new(12, 0, 4, 0)
gui.StudsOffset = Vector3.new(0, 3, 0)
gui.AlwaysOnTop = true
gui.Parent = status

local label = Instance.new("TextLabel")
label.BackgroundTransparency = 1
label.Size = UDim2.new(1, 0, 1, 0)
label.TextColor3 = Color3.fromRGB(255, 220, 60)
label.TextScaled = true
label.Font = Enum.Font.GothamBold
label.Text = "[SERVER] Iniciando..."
label.Parent = gui

local function say(text)
	label.Text = text
	task.wait(0.05)
end

local STAFF_ROOM_CFRAME = CFrame.new(0, 3.5, 38) * CFrame.Angles(0, math.rad(180), 0)

local function teleportInside(character)
	local hrp = character:WaitForChild("HumanoidRootPart")
	hrp.CFrame = STAFF_ROOM_CFRAME
	hrp.AssemblyLinearVelocity = Vector3.zero
end

-- Conecta el teletransporte SIEMPRE, antes de construir el mapa,
-- para que ningún error pueda dejarte fuera del supermercado.
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(teleportInside)
end)
for _, player in Players:GetPlayers() do
	if player.Character then
		task.spawn(teleportInside, player.Character)
	end
	player.CharacterAdded:Connect(teleportInside)
end

-- Vigilante ANTICAIDAS: solo te rescata si caes al vacío (Y < -20).
-- NO te teletransporta por estar fuera del super, para que puedas explorar libremente.
task.spawn(function()
	while true do
		task.wait(2)
		for _, player in Players:GetPlayers() do
			local char = player.Character
			if char then
				local hrp = char:FindFirstChild("HumanoidRootPart")
				if hrp then
					local p = hrp.Position
					if p.Y < -20 then
						hrp.CFrame = STAFF_ROOM_CFRAME
					end
					if #Players:GetPlayers() == 1 then
						say(string.format("POS [%d,%d,%d]", math.floor(p.X), math.floor(p.Y), math.floor(p.Z)))
					end
				end
			end
		end
	end
end)

local ok, err = pcall(function()
	say("[SERVER] Cargando modulos...")

	local MapBuilder = require(script.MapBuilder)
	local PowerService = require(script.PowerService)
	local TaskService = require(script.TaskService)
	local MonsterService = require(script.MonsterService)
	local AnomalyService = require(script.AnomalyService)
	local DataService = require(script.DataService)
	local RoundService = require(script.RoundService)

	say("[SERVER] Modulos cargados - construyendo mapa...")

	MapBuilder.Build()

	local map = Workspace:FindFirstChild("Map")
	local count = 0
	if map then
		for _, child in map:GetDescendants() do
			if child:IsA("BasePart") then
				count += 1
			end
		end
	end
	say("[SERVER] Build OK - " .. tostring(count) .. " partes")

	TaskService.Init()
	say("[SERVER] Tareas OK")

	PowerService.Init()
	say("[SERVER] Electricidad OK")

	AnomalyService.Init()
	say("[SERVER] Anomalias OK")

	DataService.Init()
	say("[SERVER] Datos OK")

	RoundService.Start()
	say("[SERVER] Ronda lista - TODO FUNCIONA")
end)

if not ok then
	say("[SERVER] ERROR: " .. tostring(err))
	warn("[SERVER] Error:", err)
end
