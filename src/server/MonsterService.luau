local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.GameConfig)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local Workspace = game:GetService("Workspace")
local PathfindingService = game:GetService("PathfindingService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local MonsterService = {}

local monster
local active = false
local isChasing = false
local lastAttackTime = 0

local function newBodyPart(name, size, color, material)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide = false
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.CastShadow = true
	return part
end

local function buildMonster()
	local model = Instance.new("Model")
	model.Name = "ClienteCero"

	local root = newBodyPart("Torso", Vector3.new(1.4, 2.6, 0.8), Config.Colors.Monster)
	local head = newBodyPart("Head", Vector3.new(0.65, 0.65, 0.65), Config.Colors.Monster)
	local leftArm = newBodyPart("LeftArm", Vector3.new(0.35, 2.4, 0.35), Config.Colors.Monster)
	local rightArm = newBodyPart("RightArm", Vector3.new(0.35, 2.4, 0.35), Config.Colors.Monster)
	local leftLeg = newBodyPart("LeftLeg", Vector3.new(0.4, 1.6, 0.4), Config.Colors.Monster)
	local rightLeg = newBodyPart("RightLeg", Vector3.new(0.4, 1.6, 0.4), Config.Colors.Monster)
	local eye = newBodyPart("Eye", Vector3.new(0.18, 0.18, 0.18), Config.Colors.MonsterEye, Enum.Material.Neon)
	eye:SetAttribute("IsEye", true)

	model.PrimaryPart = root

	for _, part in { root, head, leftArm, rightArm, leftLeg, rightLeg, eye } do
		part.Parent = model
	end

	root.Position = Vector3.new(0, 3, 0)
	head.Position = root.Position + Vector3.new(0, 1.65, 0)
	leftArm.Position = root.Position + Vector3.new(-0.95, 0.2, 0)
	rightArm.Position = root.Position + Vector3.new(0.95, 0.2, 0)
	leftLeg.Position = root.Position + Vector3.new(-0.4, -2.1, 0)
	rightLeg.Position = root.Position + Vector3.new(0.4, -2.1, 0)
	eye.Position = head.Position + Vector3.new(0, 0, -0.35)

	local glow = Instance.new("PointLight")
	glow.Name = "Glow"
	glow.Color = Config.Colors.MonsterEye
	glow.Brightness = 1.6
	glow.Range = 14
	glow.Enabled = false
	glow.Parent = head

	-- Sonido 3D ambiental del monstruo
	local stepSound = Instance.new("Sound")
	stepSound.Name = "MonsterAura"
	stepSound.Volume = 0.6
	stepSound.RollOffMaxDistance = 60
	stepSound.RollOffMinDistance = 6
	stepSound.Looped = true
	stepSound.Parent = root

	return model
end

local function getAlivePlayers()
	local alive = {}
	for _, player in Players:GetPlayers() do
		local char = player.Character
		if char and char:FindFirstChild("HumanoidRootPart") then
			local humanoid = char:FindFirstChildOfClass("Humanoid")
			local isDowned = char:GetAttribute("IsDowned") or false
			if humanoid and humanoid.Health > 0 and not isDowned then
				table.insert(alive, player)
			end
		end
	end
	return alive
end

local function hasLineOfSight(startPos, targetPos)
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	local ignoreList = {}
	if monster then
		table.insert(ignoreList, monster)
	end
	for _, p in Players:GetPlayers() do
		if p.Character then
			table.insert(ignoreList, p.Character)
		end
	end
	rayParams.FilterDescendantsInstances = ignoreList

	local direction = targetPos - startPos
	local result = Workspace:Raycast(startPos, direction, rayParams)
	return result == nil
end

local function findBestTarget()
	if not monster or not monster.PrimaryPart then
		return nil, math.huge, false
	end

	local monsterPos = monster.PrimaryPart.Position
	local monsterLook = monster.PrimaryPart.CFrame.LookVector

	local bestTarget = nil
	local bestDist = math.huge
	local hasSight = false

	for _, player in getAlivePlayers() do
		local hrp = player.Character.HumanoidRootPart
		local targetPos = hrp.Position
		local dist = (targetPos - monsterPos).Magnitude

		if dist < Config.Monster.DetectionRange then
			local toTarget = (targetPos - monsterPos).Unit
			local dot = monsterLook:Dot(toTarget)
			local inFOV = dot > math.cos(math.rad(Config.Monster.VisionFOV / 2))
			local inSight = inFOV and hasLineOfSight(monsterPos + Vector3.new(0, 1.5, 0), targetPos)

			-- Si está en línea de visión o muy cerca (audición)
			if inSight or dist < Config.Monster.HearingRange then
				if dist < bestDist then
					bestDist = dist
					bestTarget = player
					hasSight = inSight
				end
			end
		end
	end

	return bestTarget, bestDist, hasSight
end

local function onCaught(player)
	if os.clock() - lastAttackTime < Config.Monster.AttackCooldown then
		return
	end
	lastAttackTime = os.clock()

	local char = player.Character
	if char then
		char:SetAttribute("IsDowned", true)
		local humanoid = char:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = Config.Player.DownedSpeed
		end
	end

	Remotes.PlayerDowned:FireAllClients(player.Name)
	Remotes.PlayerStateChanged:FireAllClients(player.Name, "Downed")
	Remotes.ShowMessage:FireAllClients(player.Name .. " ha sido alcanzado por el Cliente Cero!")
end

local function getPatrolPoints()
	local map = Workspace:FindFirstChild("Map")
	local points = {}
	if map then
		local spawnFolder = map:FindFirstChild("MonsterSpawnPoints")
		if spawnFolder then
			for _, child in spawnFolder:GetChildren() do
				if child:IsA("BasePart") then
					table.insert(points, child.Position)
				end
			end
		end
	end
	if #points == 0 then
		table.insert(points, Vector3.new(0, 1, 0))
	end
	return points
end

local function spawnMonster()
	local points = getPatrolPoints()
	local point = points[math.random(1, #points)]
	monster:PivotTo(CFrame.new(point + Vector3.new(0, 2.5, 0)))

	for _, part in monster:GetChildren() do
		if part:IsA("BasePart") then
			part.Transparency = 1
			TweenService:Create(part, TweenInfo.new(0.5), { Transparency = 0 }):Play()
		end
	end

	local head = monster:FindFirstChild("Head")
	if head then
		local glow = head:FindFirstChild("Glow")
		if glow then
			glow.Enabled = true
		end
	end

	return true
end

local function moveStepTowards(targetPos, speed, dt)
	if not monster or not monster.PrimaryPart then
		return
	end
	local primary = monster.PrimaryPart
	local direction = targetPos - primary.Position
	direction = Vector3.new(direction.X, 0, direction.Z)
	local dist = direction.Magnitude
	if dist < 0.1 then
		return
	end

	local step = math.min(speed * dt, dist)
	local newPos = primary.Position + direction.Unit * step
	local lookTarget = newPos + direction.Unit * 3
	monster:PivotTo(CFrame.lookAt(newPos, Vector3.new(lookTarget.X, newPos.Y, lookTarget.Z)))
end

local function moveLoop(seconds, baseSpeed)
	local start = os.clock()
	local path = PathfindingService:CreatePath({
		AgentRadius = Config.Monster.AgentRadius,
		AgentHeight = Config.Monster.AgentHeight,
		AgentCanJump = false,
		WaypointSpacing = 3,
	})

	local waypoints = {}
	local currentWaypointIndex = 1
	local lastPathCompute = 0

	while active and monster and monster.Parent and os.clock() - start < seconds do
		local dt = 0.1
		task.wait(dt)

		local target, dist, hasSight = findBestTarget()
		local speed = if target and hasSight then Config.Monster.ChaseSpeed else baseSpeed

		if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
			local targetPos = target.Character.HumanoidRootPart.Position

			-- Ataque si está a rango
			if dist < Config.Monster.AttackRange then
				onCaught(target)
			end

			-- Si hay línea de visión directa, corre hacia él
			if hasSight then
				moveStepTowards(targetPos, speed, dt)
			else
				-- Navegación con Pathfinding
				if os.clock() - lastPathCompute > 0.8 then
					lastPathCompute = os.clock()
					local success = pcall(function()
						path:ComputeAsync(monster.PrimaryPart.Position, targetPos)
					end)
					if success and path.Status == Enum.PathStatus.Success then
						waypoints = path:GetWaypoints()
						currentWaypointIndex = 2
					end
				end

				if waypoints and currentWaypointIndex <= #waypoints then
					local wp = waypoints[currentWaypointIndex]
					moveStepTowards(wp.Position, speed, dt)
					if (monster.PrimaryPart.Position - wp.Position).Magnitude < 2.5 then
						currentWaypointIndex += 1
					end
				else
					moveStepTowards(targetPos, speed, dt)
				end
			end
		else
			-- Patrullaje aleatorio
			local patrolPoints = getPatrolPoints()
			local randomDest = patrolPoints[math.random(1, #patrolPoints)]
			moveStepTowards(randomDest, baseSpeed, dt)
		end
	end
end

local function retreat()
	if not monster then
		return
	end
	local head = monster:FindFirstChild("Head")
	if head then
		local glow = head:FindFirstChild("Glow")
		if glow then
			glow.Enabled = false
		end
	end
	for _, part in monster:GetChildren() do
		if part:IsA("BasePart") then
			TweenService:Create(part, TweenInfo.new(1.2), { Transparency = 1 }):Play()
		end
	end
	task.wait(1.3)
	if monster then
		monster:Destroy()
		monster = nil
	end
end

local function ensureMonster()
	if not monster then
		monster = buildMonster()
		monster.Parent = Workspace
	end
end

function MonsterService.Activate()
	active = true
end

function MonsterService.WarnAndAppear(appearTime)
	if not active then
		return
	end
	Remotes.MonsterWarning:FireAllClients("appear")
	local sequence = Config.Sounds.WarningSequence
	task.wait(sequence.Cart + sequence.Beep + sequence.Silence)
	if not active then
		return
	end
	ensureMonster()
	if not spawnMonster() then
		return
	end
	moveLoop(appearTime, Config.Monster.WalkSpeed)
	if active then
		retreat()
	end
end

function MonsterService.RunChase(chaseTime)
	if not active then
		return
	end
	ensureMonster()
	spawnMonster()
	moveLoop(chaseTime, Config.Monster.ChaseSpeed)
	if active then
		retreat()
	end
end

function MonsterService.Reset()
	active = false
	if monster then
		monster:Destroy()
		monster = nil
	end
end

function MonsterService.GetMonsterPosition()
	if monster and monster.PrimaryPart then
		return monster.PrimaryPart.Position
	end
	return nil
end

return MonsterService
