local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.GameConfig)

local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")

local MapBuilder = {}

local mapFolder
local exitDoor
local glassDoor
local exitPrompt

local MAP = Config.Map
local FLOOR_Y = MAP.FloorY
local FLOOR_TOP = MAP.FloorTop
local WALL_H = Config.WallHeight
local WALL_T = Config.WallThickness
local HALF_W = MAP.HalfWidth
local HALF_D = MAP.HalfDepth

local COLORS = {
	floor = Color3.fromRGB(224, 214, 190),
	floorDark = Color3.fromRGB(188, 172, 140),
	foundation = Color3.fromRGB(120, 124, 130),
	wallA = Color3.fromRGB(64, 96, 140),
	wallB = Color3.fromRGB(52, 78, 116),
	trim = Color3.fromRGB(245, 197, 66),
	ceiling = Color3.fromRGB(200, 208, 216),
	ceilingDark = Color3.fromRGB(150, 158, 166),
	staff = Color3.fromRGB(120, 96, 66),
	security = Color3.fromRGB(58, 76, 96),
	warehouse = Color3.fromRGB(146, 128, 92),
	dock = Color3.fromRGB(110, 110, 116),
	freezer = Color3.fromRGB(150, 196, 214),
	bathroom = Color3.fromRGB(120, 172, 186),
	shelf = Color3.fromRGB(64, 74, 96),
	shelfDark = Color3.fromRGB(44, 52, 70),
	cart = Color3.fromRGB(170, 180, 192),
	beacon = Color3.fromRGB(255, 60, 40),
}

local ROOM_COLORS = {
	staff = COLORS.staff,
	security = COLORS.security,
	warehouse = COLORS.warehouse,
	dock = COLORS.dock,
	freezer = COLORS.freezer,
	bathroom = COLORS.bathroom,
}

local productColors = {
	Color3.fromRGB(220, 90, 90),
	Color3.fromRGB(90, 160, 220),
	Color3.fromRGB(240, 210, 100),
	Color3.fromRGB(120, 200, 120),
	Color3.fromRGB(200, 140, 220),
	Color3.fromRGB(240, 150, 80),
	Color3.fromRGB(250, 250, 250),
	Color3.fromRGB(80, 200, 170),
}

local function randomColor()
	return productColors[math.random(1, #productColors)]
end

local function newPart(parent, name, size, position, color, material, canCollide)
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.CanCollide = if canCollide == nil then true else canCollide
	part.Size = size
	part.Position = position
	part.Color = color
	part.Material = material or Enum.Material.Plastic
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

local function addPointLight(parentPart, range, brightness, color, enabled)
	local light = Instance.new("PointLight")
	light.Range = range
	light.Brightness = brightness
	light.Color = color
	light.Enabled = if enabled == nil then true else enabled
	light.Shadows = true
	light.Parent = parentPart
	return light
end

local function makeSurfaceText(part, face, text, textColor, bgColor)
	local gui = Instance.new("SurfaceGui")
	gui.Name = "Gui"
	gui.Face = face
	gui.Parent = part
	local label = Instance.new("TextLabel")
	label.BackgroundColor3 = bgColor or Color3.fromRGB(18, 22, 30)
	label.BackgroundTransparency = if bgColor then 0 else 1
	label.Size = UDim2.new(1, 0, 1, 0)
	label.Text = text
	label.TextColor3 = textColor or Config.Colors.White
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.Parent = gui
	return gui
end

local function buildWall(parent, cx, cz, length, alongZ, gap, wallColor)
	local height = WALL_H
	local thickness = WALL_T
	local color = wallColor or COLORS.wallA
	local yCenter = FLOOR_TOP + height / 2

	local function place(centerPos, size)
		local wall = newPart(parent, "Wall", size, centerPos, color, Enum.Material.Plastic)
		wall:SetAttribute("IsWall", true)
		return wall
	end

	if gap then
		local half = (length - gap) / 2
		for _, sign in { -1, 1 } do
			local centerPos
			local size
			if alongZ then
				size = Vector3.new(thickness, height, half)
				centerPos = Vector3.new(cx, yCenter, cz + sign * (gap / 2 + half / 2))
			else
				size = Vector3.new(half, height, thickness)
				centerPos = Vector3.new(cx + sign * (gap / 2 + half / 2), yCenter, cz)
			end
			place(centerPos, size)
		end
	else
		local size = if alongZ then Vector3.new(thickness, height, length) else Vector3.new(length, height, thickness)
		place(Vector3.new(cx, yCenter, cz), size)
	end
end

local function buildRoom(name, roomConfig)
	local cx = roomConfig.Center.X
	local cz = roomConfig.Center.Z
	local width = roomConfig.Size.X
	local depth = roomConfig.Size.Z
	local floorColor = ROOM_COLORS[roomConfig.Color] or COLORS.wallB
	local door = roomConfig.Door

	local room = Instance.new("Folder")
	room.Name = name
	room.Parent = mapFolder

	newPart(room, "Floor", Vector3.new(width - 0.4, 0.12, depth - 0.4), Vector3.new(cx, FLOOR_Y, cz), floorColor, Enum.Material.Plastic, false)

	local walls = Instance.new("Folder")
	walls.Name = "Walls"
	walls.Parent = room

	local doors = { north = nil, south = nil, east = nil, west = nil }
	if door then
		doors[door.side] = door.gap
	end

	local wallColor = floorColor
	buildWall(walls, cx, cz + depth / 2, width, false, doors.north, wallColor)
	buildWall(walls, cx, cz - depth / 2, width, false, doors.south, wallColor)
	buildWall(walls, cx + width / 2, cz, depth, true, doors.east, wallColor)
	buildWall(walls, cx - width / 2, cz, depth, true, doors.west, wallColor)

	local labelPart = newPart(room, "RoomLabel", Vector3.new(4, 1, 0.15), Vector3.new(cx, FLOOR_TOP + 3, cz + depth / 2 - 0.4), Color3.fromRGB(20, 24, 34), Enum.Material.Plastic, false)
	makeSurfaceText(labelPart, Enum.NormalId.Front, string.upper(name:gsub("(%l)(%u)", "%1 %2")), COLORS.trim)

	return room
end

local function buildCart(parent, x, z)
	local cart = Instance.new("Model")
	cart.Name = "Cart"
	local base = newPart(cart, "Base", Vector3.new(1.6, 0.4, 2.4), Vector3.new(x, FLOOR_TOP + 0.8, z), COLORS.cart, Enum.Material.Metal)
	local basket = newPart(cart, "Basket", Vector3.new(1.4, 0.8, 2.2), Vector3.new(x, FLOOR_TOP + 1.6, z), COLORS.cart, Enum.Material.Metal)
	basket.Transparency = 0.4
	newPart(cart, "Handle", Vector3.new(0.1, 1, 1.1), Vector3.new(x, FLOOR_TOP + 1.1, z + 1.5), COLORS.cart, Enum.Material.Metal)
	cart.PrimaryPart = base
	cart.Parent = parent
	return cart
end

local function buildFoundationAndFloor()
	newPart(mapFolder, "Foundation", Vector3.new(148, 1.5, 96), Vector3.new(0, -0.25, 0), COLORS.foundation, Enum.Material.Concrete)
	newPart(mapFolder, "Floor", Vector3.new(140, 1, 90), Vector3.new(0, FLOOR_Y, 0), COLORS.floor, Enum.Material.Plastic)

	for i = -66, 66, 8 do
		newPart(mapFolder, "FloorStrip", Vector3.new(4, 0.05, 86), Vector3.new(i, FLOOR_TOP + 0.02, 0), COLORS.floorDark, Enum.Material.Plastic, false)
	end
end

local function buildCeiling()
	local ceilingFolder = Instance.new("Folder")
	ceilingFolder.Name = "Ceiling"
	ceilingFolder.Parent = mapFolder

	local y = FLOOR_TOP + WALL_H - 0.1
	local beamColor = Color3.fromRGB(120, 125, 132)

	newPart(ceilingFolder, "MainCeiling", Vector3.new(138, 0.5, 88), Vector3.new(0, y, 0), COLORS.ceiling, Enum.Material.Concrete, false)

	for x = -60, 40, 40 do
		newPart(ceilingFolder, "BeamX", Vector3.new(138, 0.6, 0.8), Vector3.new(0, y + 0.2, x), beamColor, Enum.Material.Metal, false)
	end
	for z = -40, 30, 30 do
		newPart(ceilingFolder, "BeamZ", Vector3.new(0.8, 0.6, 88), Vector3.new(z, y + 0.2, 0), beamColor, Enum.Material.Metal, false)
	end

	for x = -60, 60, 24 do
		for z = -30, 30, 22 do
			newPart(ceilingFolder, "CeilingTile", Vector3.new(22, 0.06, 20), Vector3.new(x, y + 0.15, z), COLORS.ceilingDark, Enum.Material.SmoothPlastic, false)
		end
	end
end

local function buildColumns()
	local folder = Instance.new("Folder")
	folder.Name = "Columns"
	folder.Parent = mapFolder

	local colColor = Color3.fromRGB(140, 144, 152)
	local colH = WALL_H - 0.5
	local yCenter = FLOOR_TOP + colH / 2

	for x = -40, 40, 20 do
		for z = -30, 30, 20 do
			local edge = (math.abs(x) > 60) or (math.abs(z) > 40)
			if not edge then
				newPart(folder, "Col", Vector3.new(1.2, colH, 1.2), Vector3.new(x, yCenter, z), colColor, Enum.Material.Concrete)
			end
		end
	end
end

local function buildParkingLot()
	local folder = Instance.new("Folder")
	folder.Name = "ParkingLot"
	folder.Parent = mapFolder

	local entranceZ = MAP.EntranceZ
	newPart(folder, "Asphalt", Vector3.new(160, 0.15, 50), Vector3.new(0, -0.2, entranceZ + 30), Color3.fromRGB(50, 52, 56), Enum.Material.Asphalt, false)

	local lineColor = Color3.fromRGB(220, 220, 220)
	for x = -60, 60, 8 do
		newPart(folder, "ParkingLine", Vector3.new(0.2, 0.02, 6), Vector3.new(x, 0.01, entranceZ + 24), lineColor, Enum.Material.Neon, false)
		newPart(folder, "ParkingLine", Vector3.new(0.2, 0.02, 6), Vector3.new(x, 0.01, entranceZ + 32), lineColor, Enum.Material.Neon, false)
	end

	local lampColor = Color3.fromRGB(80, 84, 90)
	for x = -52, 52, 52 do
		local pole = newPart(folder, "LampPole", Vector3.new(0.5, 12, 0.5), Vector3.new(x, 6, entranceZ + 20), lampColor, Enum.Material.Metal)
		local lamp = newPart(folder, "LampHead", Vector3.new(3, 0.3, 3), Vector3.new(x, 12.2, entranceZ + 20), Color3.fromRGB(255, 240, 200), Enum.Material.Neon, false)
		addPointLight(lamp, 30, 0.8, Color3.fromRGB(255, 240, 200))
	end

	local cartReturn = newPart(folder, "CartReturn", Vector3.new(8, 2, 3), Vector3.new(20, 1.1, entranceZ + 18), COLORS.cart, Enum.Material.Metal)

	newPart(folder, "Curb", Vector3.new(160, 0.5, 1.5), Vector3.new(0, 0.05, entranceZ + 6.5), Color3.fromRGB(180, 180, 180), Enum.Material.Concrete, false)
end

local function buildShell()
	local walls = Instance.new("Folder")
	walls.Name = "OuterWalls"
	walls.Parent = mapFolder

	buildWall(walls, 0, HALF_D, 140, false, 10, COLORS.wallB)
	buildWall(walls, 0, -HALF_D, 140, false, nil, COLORS.wallB)
	buildWall(walls, HALF_W, 0, 90, true, nil, COLORS.wallB)
	buildWall(walls, -HALF_W, 0, 90, true, nil, COLORS.wallB)
end

local function buildAisles()
	local aislesFolder = Instance.new("Folder")
	aislesFolder.Name = "Aisles"
	aislesFolder.Parent = mapFolder

	local shelfLen = MAP.ShelfLength
	local shelfH = MAP.ShelfHeight
	local offset = MAP.ShelfOffset
	local centerZ = MAP.ShelfCenterZ

	for _, aisle in Config.Aisles do
		local x = aisle.X
		local aisleFolder = Instance.new("Folder")
		aisleFolder.Name = "Aisle_" .. x
		aisleFolder.Parent = aislesFolder

		local sign = newPart(aisleFolder, "AisleSign", Vector3.new(6, 1.4, 0.2), Vector3.new(x, FLOOR_TOP + WALL_H - 3, centerZ + shelfLen / 2 - 4), Color3.fromRGB(25, 30, 42), Enum.Material.Plastic)
		makeSurfaceText(sign, Enum.NormalId.Front, aisle.Name or ("Pasillo " .. tostring(x)), COLORS.trim)

		for _, side in { -1, 1 } do
			local shelfX = x + side * offset
			newPart(aisleFolder, "Shelf", Vector3.new(MAP.ShelfDepth, shelfH, shelfLen), Vector3.new(shelfX, FLOOR_TOP + shelfH / 2, centerZ), COLORS.shelf, Enum.Material.Plastic)

			for _, shelfY in { 2.4, 4.8, 6.8 } do
				newPart(aisleFolder, "Board", Vector3.new(MAP.ShelfDepth + 0.05, 0.15, shelfLen), Vector3.new(shelfX, FLOOR_TOP + shelfY, centerZ), COLORS.shelfDark, Enum.Material.Plastic)
			end

			for z = centerZ - shelfLen / 2 + 2, centerZ + shelfLen / 2 - 2, 3.5 do
				for _, shelfY in { 2.75, 5.15, 7.15 } do
					newPart(aisleFolder, "Product", Vector3.new(0.55, 0.65, 0.55), Vector3.new(shelfX + side * 0.35, FLOOR_TOP + shelfY, z), randomColor(), Enum.Material.Plastic)
				end
			end
		end

		newPart(aisleFolder, "EndCap", Vector3.new(7.5, 5, 1.2), Vector3.new(x, FLOOR_TOP + 2.5, centerZ - shelfLen / 2 - 0.8), COLORS.trim, Enum.Material.Plastic)
		newPart(aisleFolder, "EndCap", Vector3.new(7.5, 5, 1.2), Vector3.new(x, FLOOR_TOP + 2.5, centerZ + shelfLen / 2 + 0.8), COLORS.trim, Enum.Material.Plastic)
	end
end

local function buildRegisters()
	local folder = Instance.new("Folder")
	folder.Name = "Registers"
	folder.Parent = mapFolder

	local registerZ = MAP.RegisterZ
	for _, x in { -19.5, -6.5, 6.5, 19.5 } do
		newPart(folder, "Counter", Vector3.new(7, 3.2, 2.4), Vector3.new(x, FLOOR_TOP + 1.6, registerZ), COLORS.wallB, Enum.Material.Plastic)
		newPart(folder, "Register", Vector3.new(1.4, 0.9, 1.1), Vector3.new(x, FLOOR_TOP + 3.6, registerZ + 0.2), COLORS.trim, Enum.Material.Metal)
		newPart(folder, "Conveyor", Vector3.new(6, 0.25, 1.6), Vector3.new(x, FLOOR_TOP + 0.65, registerZ + 1.4), Color3.fromRGB(60, 64, 70), Enum.Material.Metal)
		newPart(folder, "BagRack", Vector3.new(1.2, 1.8, 1.2), Vector3.new(x + 3.6, FLOOR_TOP + 1.9, registerZ), Color3.fromRGB(150, 154, 160), Enum.Material.Metal)
		newPart(folder, "LaneDivider", Vector3.new(0.2, 2.5, 8), Vector3.new(x + 4.2, FLOOR_TOP + 1.25, registerZ - 4), Color3.fromRGB(180, 185, 192), Enum.Material.Metal)
	end

	newPart(folder, "QueueMat", Vector3.new(52, 0.08, 6), Vector3.new(0, FLOOR_TOP + 0.04, registerZ + 5), Color3.fromRGB(200, 50, 50), Enum.Material.Fabric, false)
end

local function buildRooms()
	for roomName, roomConfig in Config.Map.Rooms do
		buildRoom(roomName, roomConfig)
	end
end

local function buildEntrance()
	local entrance = Instance.new("Folder")
	entrance.Name = "Entrance"
	entrance.Parent = mapFolder

	local entranceZ = MAP.EntranceZ

	local canopy = newPart(entrance, "Canopy", Vector3.new(34, 0.5, 10), Vector3.new(0, FLOOR_TOP + WALL_H + 0.5, entranceZ + 3), Color3.fromRGB(30, 34, 44), Enum.Material.Metal)
	local frameColor = Color3.fromRGB(40, 44, 52)
	for _, x in { -16, 16 } do
		newPart(entrance, "CanopySupport", Vector3.new(0.6, WALL_H + 0.5, 0.6), Vector3.new(x, FLOOR_TOP + (WALL_H + 0.5) / 2, entranceZ + 7), frameColor, Enum.Material.Metal)
	end

	newPart(entrance, "FrameTop", Vector3.new(12, 0.6, 0.6), Vector3.new(0, FLOOR_TOP + WALL_H - 0.3, entranceZ), frameColor, Enum.Material.Metal)
	newPart(entrance, "FrameLeft", Vector3.new(0.6, WALL_H, 0.6), Vector3.new(-6, FLOOR_TOP + WALL_H / 2, entranceZ), frameColor, Enum.Material.Metal)
	newPart(entrance, "FrameRight", Vector3.new(0.6, WALL_H, 0.6), Vector3.new(6, FLOOR_TOP + WALL_H / 2, entranceZ), frameColor, Enum.Material.Metal)

	glassDoor = newPart(entrance, "ExitGlass", Vector3.new(10, 8, 0.25), Vector3.new(0, FLOOR_TOP + 4.5, entranceZ), Color3.fromRGB(180, 220, 235), Enum.Material.Glass)
	glassDoor.Transparency = 0.35
	glassDoor.CanCollide = false

	exitDoor = newPart(entrance, "MainExit", Config.Exit.Size, Config.Exit.Position, Color3.fromRGB(120, 130, 140), Enum.Material.Metal)
	exitDoor.CanCollide = false
	exitDoor.Transparency = 0.6
	exitDoor:SetAttribute("InteractType", "Exit")
	exitDoor:SetAttribute("TaskId", "MainExit")
	exitDoor:SetAttribute("IsActive", true)

	exitPrompt = Instance.new("ProximityPrompt")
	exitPrompt.Name = "ExitPrompt"
	exitPrompt.ActionText = "ABRIR SALIDA"
	exitPrompt.HoldDuration = 1.5
	exitPrompt.MaxActivationDistance = Config.Player.InteractionDistance
	exitPrompt.RequiresLineOfSight = false
	exitPrompt.Enabled = false
	exitPrompt.Parent = exitDoor

	local sign = newPart(entrance, "Sign", Vector3.new(36, 5, 0.7), Vector3.new(0, FLOOR_TOP + WALL_H + 3.5, entranceZ + 0.5), Color3.fromRGB(20, 24, 34), Enum.Material.Plastic)
	makeSurfaceText(sign, Enum.NormalId.Front, "MOONMART 24", COLORS.trim)
	makeSurfaceText(sign, Enum.NormalId.Back, "ABIERTO 24 HORAS", Config.Colors.White)

	local subSign = newPart(entrance, "SubSign", Vector3.new(20, 1.5, 0.25), Vector3.new(0, FLOOR_TOP + WALL_H + 1.2, entranceZ + 0.3), Color3.fromRGB(200, 35, 35), Enum.Material.Neon, false)
	makeSurfaceText(subSign, Enum.NormalId.Front, "TURNO NOCTURNO", Config.Colors.White)

	local pole = newPart(entrance, "BeaconPole", Vector3.new(1.2, 9, 1.2), Vector3.new(0, FLOOR_TOP + 4.5, entranceZ + 8), COLORS.beacon, Enum.Material.Metal)
	addPointLight(pole, 28, 1.8, COLORS.beacon)

	local frameLight = newPart(entrance, "FrameLight", Vector3.new(11, 0.25, 0.25), Vector3.new(0, FLOOR_TOP + WALL_H - 1, entranceZ), Config.Colors.Red, Enum.Material.Neon, false)

	for _, x in { -10, 10 } do
		buildCart(entrance, x, entranceZ - 5)
	end

	newPart(entrance, "CartCorral", Vector3.new(10, 0.15, 6), Vector3.new(12, FLOOR_TOP + 0.08, 38), COLORS.trim, Enum.Material.Neon, false)
end

local function buildEntranceStairs()
	local stairs = Instance.new("Folder")
	stairs.Name = "EntranceStairs"
	stairs.Parent = mapFolder

	local entranceZ = MAP.EntranceZ
	local stepColor = COLORS.foundation
	for i = 1, 4 do
		newPart(stairs, "Step" .. i, Vector3.new(16, 0.6, 2.2), Vector3.new(0, FLOOR_TOP - 0.3 + i * 0.6, entranceZ + 3 + (4 - i) * 2.2), stepColor, Enum.Material.Concrete)
	end

	for _, side in { -1, 1 } do
		newPart(stairs, "Rail" .. side, Vector3.new(0.2, 2, 10), Vector3.new(side * 8.5, FLOOR_TOP + 1.2, entranceZ + 4), Color3.fromRGB(60, 66, 72), Enum.Material.Metal)
	end
end

local function buildLights()
	local folder = Instance.new("Folder")
	folder.Name = "Lights"
	folder.Parent = mapFolder

	local lightY = FLOOR_TOP + WALL_H - 0.5
	for x = -45, 45, 22 do
		for z = -25, 25, 20 do
			local lightPart = newPart(folder, "Light", Vector3.new(3, 0.2, 8), Vector3.new(x, lightY, z), Color3.fromRGB(255, 250, 235), Enum.Material.Neon, false)
			addPointLight(lightPart, 32, 1.2, Color3.fromRGB(255, 240, 215))
		end
	end

	local roomLights = {
		{ Vector3.new(-58, lightY, 2), 22, 1.0, Color3.fromRGB(255, 230, 180) },
		{ Vector3.new(-52, lightY, -24), 18, 0.85, Color3.fromRGB(220, 230, 245) },
		{ Vector3.new(52, lightY, 0), 22, 1.0, Color3.fromRGB(180, 215, 255) },
		{ Vector3.new(0, lightY, 30), 26, 1.1, Color3.fromRGB(255, 240, 215) },
	}

	for i, entry in roomLights do
		local lightPart = newPart(folder, "RoomLight_" .. i, Vector3.new(2.5, 0.2, 2.5), entry[1], Color3.fromRGB(255, 250, 235), Enum.Material.Neon, false)
		addPointLight(lightPart, entry[2], entry[3], entry[4])
	end
end

local function buildEmergencyLights()
	local folder = Instance.new("Folder")
	folder.Name = "EmergencyLights"
	folder.Parent = mapFolder

	local positions = {
		Vector3.new(0, FLOOR_TOP + WALL_H - 1, 28),
		Vector3.new(38, FLOOR_TOP + WALL_H - 1, -28),
		Vector3.new(-52, FLOOR_TOP + WALL_H - 1, -24),
		Vector3.new(-58, FLOOR_TOP + WALL_H - 1, 2),
		Vector3.new(52, FLOOR_TOP + WALL_H - 1, 0),
		Vector3.new(0, FLOOR_TOP + WALL_H - 1, MAP.EntranceZ - 2),
	}

	for i, pos in positions do
		local lightPart = newPart(folder, "Emergency_" .. i, Vector3.new(1.2, 0.15, 1.2), pos, Config.Colors.NeonRed, Enum.Material.Neon, false)
		addPointLight(lightPart, 16, 0.9, Config.Colors.NeonRed, false)
	end
end

local function buildCCTVMounts()
	local folder = Instance.new("Folder")
	folder.Name = "CCTVMounts"
	folder.Parent = mapFolder

	for _, cam in Config.CCTV do
		local mount = newPart(folder, cam.Id, Vector3.new(0.7, 0.7, 0.9), cam.Position, Color3.fromRGB(40, 44, 52), Enum.Material.Metal)
		local lens = newPart(folder, cam.Id .. "_Lens", Vector3.new(0.3, 0.3, 0.3), cam.Position + Vector3.new(0, -0.35, 0), Config.Colors.NeonRed, Enum.Material.Neon, false)
		local redLight = Instance.new("PointLight")
		redLight.Color = Config.Colors.NeonRed
		redLight.Brightness = 0.5
		redLight.Range = 5
		redLight.Parent = lens
	end
end

local function buildSpawns()
	local folder = Instance.new("Folder")
	folder.Name = "PlayerSpawnPoints"
	folder.Parent = mapFolder

	local spawnPositions = {
		Vector3.new(0, FLOOR_TOP + 0.5, 38),
		Vector3.new(5, FLOOR_TOP + 0.5, 38),
		Vector3.new(-5, FLOOR_TOP + 0.5, 38),
		Vector3.new(10, FLOOR_TOP + 0.5, 38),
	}

	for i, pos in spawnPositions do
		local spawn = Instance.new("SpawnLocation")
		spawn.Name = "Spawn_" .. i
		spawn.Position = pos
		spawn.Size = Vector3.new(4, 1, 4)
		spawn.Anchored = true
		spawn.CanCollide = false
		spawn.Neutral = true
		spawn.Duration = 0
		spawn.Transparency = 0.7
		spawn.Color = COLORS.trim
		spawn.Material = Enum.Material.Neon
		spawn.Parent = folder
	end
end

local function buildMonsterSpawns()
	local folder = Instance.new("Folder")
	folder.Name = "MonsterSpawnPoints"
	folder.Parent = mapFolder

	local positions = {
		Vector3.new(32.5, FLOOR_TOP + 0.5, -10),
		Vector3.new(58, FLOOR_TOP + 0.5, -28),
		Vector3.new(-58, FLOOR_TOP + 0.5, 2),
		Vector3.new(52, FLOOR_TOP + 0.5, -8),
		Vector3.new(0, FLOOR_TOP + 0.5, -22),
		Vector3.new(-58, FLOOR_TOP + 0.5, -36),
		Vector3.new(-6.5, FLOOR_TOP + 0.5, -30),
	}

	for i, pos in positions do
		local point = newPart(folder, "Spawn_" .. i, Vector3.new(1, 1, 1), pos, Config.Colors.Red, Enum.Material.Plastic, false)
		point.Transparency = 1
	end
end

local function buildWaypoints()
	local folder = Instance.new("Folder")
	folder.Name = "Waypoints"
	folder.Parent = Workspace

	for x = -30, 30, 12 do
		for z = -28, 18, 10 do
			local wp = newPart(folder, "WP_" .. x .. "_" .. z, Vector3.new(1, 1, 1), Vector3.new(x, FLOOR_TOP + 0.5, z), Color3.fromRGB(0, 255, 0), Enum.Material.Neon, false)
			wp.Transparency = 1
			wp.CanQuery = false
		end
	end
end

local function buildDecorations()
	local deco = Instance.new("Folder")
	deco.Name = "Decorations"
	deco.Parent = mapFolder

	local staff = Config.Map.Rooms.Staff
	local security = Config.Map.Rooms.Security
	local warehouse = Config.Map.Rooms.Warehouse

	for i = 0, 3 do
		newPart(deco, "Locker", Vector3.new(1.2, 4.2, 0.9), Vector3.new(staff.Center.X - 6 + i * 1.4, FLOOR_TOP + 2.1, staff.Center.Z + 2), Color3.fromRGB(140, 146, 152), Enum.Material.Metal)
	end
	newPart(deco, "Table", Vector3.new(3, 0.25, 1.8), Vector3.new(staff.Center.X + 4, FLOOR_TOP + 0.9, staff.Center.Z - 2), Color3.fromRGB(120, 90, 60), Enum.Material.WoodPlanks)
	newPart(deco, "Microwave", Vector3.new(1.4, 0.8, 1), Vector3.new(staff.Center.X - 2, FLOOR_TOP + 1.3, staff.Center.Z - 4), Color3.fromRGB(80, 84, 90), Enum.Material.Metal)

	local clock = newPart(deco, "WallClock", Vector3.new(0.2, 2.2, 2.2), Vector3.new(staff.Center.X - staff.Size.X / 2 + 0.4, FLOOR_TOP + 5, staff.Center.Z), Color3.fromRGB(240, 240, 240), Enum.Material.Plastic)
	clock:SetAttribute("IsClock", true)
	makeSurfaceText(clock, Enum.NormalId.Right, "12:00", Color3.fromRGB(200, 35, 35))

	local board = newPart(deco, "AnomalyBoard", Vector3.new(0.15, 3, 5), Vector3.new(security.Center.X - security.Size.X / 2 + 0.2, FLOOR_TOP + 4.5, security.Center.Z), Color3.fromRGB(24, 28, 36), Enum.Material.Plastic)
	board:SetAttribute("InteractType", "AnomalyBoard")
	local boardPrompt = Instance.new("ProximityPrompt")
	boardPrompt.Name = "BoardPrompt"
	boardPrompt.ActionText = "REGISTRAR ANOMALIA"
	boardPrompt.HoldDuration = 0.5
	boardPrompt.MaxActivationDistance = 9
	boardPrompt.Parent = board
	makeSurfaceText(board, Enum.NormalId.Right, "REGISTRO DE ANOMALIAS\n\n[E] Deducir evento extrano\nRecompensa extra al escapar", Config.Colors.Yellow)

	newPart(deco, "Generator", Vector3.new(3, 2.2, 2.2), Vector3.new(warehouse.Center.X + 4, FLOOR_TOP + 1.1, warehouse.Center.Z + 6), Color3.fromRGB(70, 74, 80), Enum.Material.Metal)
	newPart(deco, "GeneratorLight", Vector3.new(0.25, 0.25, 0.25), Vector3.new(warehouse.Center.X + 4, FLOOR_TOP + 2.4, warehouse.Center.Z + 6), Config.Colors.Green, Enum.Material.Neon, false)

	local freezerRoom = Config.Map.Rooms.Freezers
	for z = -12, 12, 8 do
		newPart(deco, "FreezerUnit", Vector3.new(1.8, 5.5, 5), Vector3.new(freezerRoom.Center.X - 4, FLOOR_TOP + 2.75, z), Color3.fromRGB(200, 210, 220), Enum.Material.Metal)
		newPart(deco, "FreezerUnit", Vector3.new(1.8, 5.5, 5), Vector3.new(freezerRoom.Center.X + 4, FLOOR_TOP + 2.75, z), Color3.fromRGB(200, 210, 220), Enum.Material.Metal)
	end

	local bath = Config.Map.Rooms.Bathrooms
	for i = 0, 2 do
		newPart(deco, "StallWall", Vector3.new(0.2, 5, 3.5), Vector3.new(bath.Center.X - 3 + i * 3, FLOOR_TOP + 2.5, bath.Center.Z), Color3.fromRGB(150, 155, 162), Enum.Material.Plastic)
	end
	newPart(deco, "StallBack", Vector3.new(10, 5, 0.2), Vector3.new(bath.Center.X, FLOOR_TOP + 2.5, bath.Center.Z - bath.Size.Z / 2 + 0.3), Color3.fromRGB(150, 155, 162), Enum.Material.Plastic)
	newPart(deco, "Sink", Vector3.new(3, 1, 0.6), Vector3.new(bath.Center.X - 2, FLOOR_TOP + 0.6, bath.Center.Z + bath.Size.Z / 2 - 1), Color3.fromRGB(190, 195, 200), Enum.Material.Metal)

	local dock = Config.Map.Rooms.LoadingDock
	for i = 1, 6 do
		newPart(deco, "Crate", Vector3.new(2.2, 1.2, 2.2), Vector3.new(dock.Center.X - 6 + (i % 3) * 4, FLOOR_TOP + 0.6, dock.Center.Z - 2 + math.floor((i - 1) / 3) * 3), Color3.fromRGB(140, 110, 70), Enum.Material.WoodPlanks)
	end

	for i = 1, 8 do
		newPart(deco, "Pallet", Vector3.new(2.4, 0.35, 2.4), Vector3.new(warehouse.Center.X - 8 + ((i - 1) % 4) * 3, FLOOR_TOP + 0.18, warehouse.Center.Z - 8 + math.floor((i - 1) / 4) * 3), Color3.fromRGB(120, 100, 70), Enum.Material.WoodPlanks)
	end

	for i = 1, 5 do
		newPart(deco, "WarehouseBox", Vector3.new(1.6, 1.6, 1.6), Vector3.new(warehouse.Center.X + 6, FLOOR_TOP + 0.8 + (i - 1) * 1.7, warehouse.Center.Z - 4), Color3.fromRGB(146, 105, 63), Enum.Material.WoodPlanks)
	end
end

local function buildTerrain()
	local ok, err = pcall(function()
		local Terrain = game:GetService("Terrain")
		Terrain:FillBlock(CFrame.new(0, -1, 10), Vector3.new(260, 3, 220), Enum.Material.Grass)
		Terrain:FillBlock(CFrame.new(0, -1.5, 10), Vector3.new(300, 4, 260), Enum.Material.Mud)
	end)
	if not ok then warn("[MapBuilder] Terrain skip:", err) end
end

local function buildTrees()
	local folder = Instance.new("Folder")
	folder.Name = "Trees"
	folder.Parent = mapFolder

	local trunkC = Color3.fromRGB(90, 60, 30)
	local leafC = Color3.fromRGB(28, 110, 40)
	local leafL = Color3.fromRGB(42, 140, 55)
	local leafD = Color3.fromRGB(20, 85, 30)

	local positions = {
		{ x = -90, z = -45, h = 10, s = 1.0 },
		{ x = -92, z = 10, h = 12, s = 1.1 },
		{ x = -88, z = 55, h = 9, s = 0.9 },
		{ x = -60, z = -58, h = 8, s = 0.85 },
		{ x = -20, z = -60, h = 11, s = 1.0 },
		{ x = 25, z = -58, h = 10, s = 0.95 },
		{ x = 60, z = -56, h = 9, s = 0.9 },
		{ x = 90, z = -40, h = 11, s = 1.05 },
		{ x = 92, z = 15, h = 12, s = 1.1 },
		{ x = 88, z = 60, h = 10, s = 1.0 },
		{ x = -50, z = 90, h = 9, s = 0.9 },
		{ x = 30, z = 92, h = 11, s = 1.0 },
		{ x = 70, z = 88, h = 10, s = 0.95 },
		{ x = -85, z = 85, h = 8, s = 0.85 },
	}

	for i, t in positions do
		local s = t.s
		local baseY = -0.5
		local trunkH = t.h * s
		newPart(folder, "Trunk_"..i, Vector3.new(0.9*s, trunkH, 0.9*s), Vector3.new(t.x, baseY + trunkH/2, t.z), trunkC, Enum.Material.Wood)

		local canopyY = baseY + trunkH + 1.5 * s
		newPart(folder, "Canopy_"..i, Vector3.new(7*s, 5*s, 7*s), Vector3.new(t.x, canopyY, t.z), leafC, Enum.Material.LeafyGrass)

		local offsets = {
			Vector3.new(2.5, 0.8, 2.5), Vector3.new(-2.5, 0.5, -2.5),
			Vector3.new(2.5, 0.5, -2.5), Vector3.new(-2.5, 0.8, 2.5),
			Vector3.new(0, 2.2, 0), Vector3.new(1.5, 1.5, -1.5),
			Vector3.new(-1.5, 1.8, 1.5),
		}
		for j, off in offsets do
			local sz = (2.5 + math.random() * 1.5) * s
			local clr = if j % 2 == 0 then leafL else leafD
			newPart(folder, "Leaf_"..i.."_"..j, Vector3.new(sz, sz, sz), Vector3.new(t.x + off.X * s, canopyY + off.Y * s, t.z + off.Z * s), clr, Enum.Material.LeafyGrass)
		end
	end
end

local function buildSidewalk()
	local folder = Instance.new("Folder")
	folder.Name = "Sidewalk"
	folder.Parent = mapFolder

	local swC = Color3.fromRGB(175, 175, 175)
	local curbC = Color3.fromRGB(155, 155, 155)
	local sw = 4

	newPart(folder, "SW_Front", Vector3.new(160, 0.25, sw), Vector3.new(0, 0.08, MAP.EntranceZ + sw/2 + 1), swC, Enum.Material.Concrete, false)
	newPart(folder, "SW_Back", Vector3.new(160, 0.25, sw), Vector3.new(0, 0.08, -HALF_D - sw/2 - 1), swC, Enum.Material.Concrete, false)
	newPart(folder, "SW_Left", Vector3.new(sw, 0.25, 90 + sw*2 + 2), Vector3.new(-HALF_W - sw/2 - 1, 0.08, 0), swC, Enum.Material.Concrete, false)
	newPart(folder, "SW_Right", Vector3.new(sw, 0.25, 90 + sw*2 + 2), Vector3.new(HALF_W + sw/2 + 1, 0.08, 0), swC, Enum.Material.Concrete, false)

	newPart(folder, "Curb_Front", Vector3.new(160, 0.4, 0.6), Vector3.new(0, 0.15, MAP.EntranceZ + sw + 1.3), curbC, Enum.Material.Concrete, false)
end

local function buildStreet()
	local folder = Instance.new("Folder")
	folder.Name = "Street"
	folder.Parent = mapFolder

	local streetZ = MAP.EntranceZ + 18
	local roadC = Color3.fromRGB(45, 45, 50)
	local lineC = Color3.fromRGB(210, 210, 60)

	newPart(folder, "Road", Vector3.new(220, 0.2, 18), Vector3.new(0, -0.15, streetZ), roadC, Enum.Material.Asphalt, false)

	for x = -100, 100, 6 do
		newPart(folder, "Dash_"..x, Vector3.new(3, 0.03, 0.3), Vector3.new(x, 0.02, streetZ), lineC, Enum.Material.Neon, false)
	end

	newPart(folder, "EdgeN", Vector3.new(220, 0.03, 0.25), Vector3.new(0, 0.02, streetZ - 8.5), Color3.fromRGB(220, 220, 220), Enum.Material.Neon, false)
	newPart(folder, "EdgeS", Vector3.new(220, 0.03, 0.25), Vector3.new(0, 0.02, streetZ + 8.5), Color3.fromRGB(220, 220, 220), Enum.Material.Neon, false)
end

local function buildExteriorDetails()
	local folder = Instance.new("Folder")
	folder.Name = "ExteriorDetails"
	folder.Parent = mapFolder

	local bushC = Color3.fromRGB(28, 95, 38)
	local bushL = Color3.fromRGB(42, 120, 52)
	for x = -55, 55, 7 do
		newPart(folder, "Bush", Vector3.new(2.5, 2.2, 2.5), Vector3.new(x, 0.9, MAP.EntranceZ + 8), bushC, Enum.Material.LeafyGrass)
		newPart(folder, "BushTop", Vector3.new(1.8, 1.2, 1.8), Vector3.new(x, 2.3, MAP.EntranceZ + 8), bushL, Enum.Material.LeafyGrass)
	end

	local dockC = Config.Map.Rooms.LoadingDock.Center
	local dumpC = Color3.fromRGB(45, 75, 45)
	newPart(folder, "Dumpster", Vector3.new(6, 3, 4), Vector3.new(dockC.X + 2, 1.2, dockC.Z - 9), dumpC, Enum.Material.Metal)
	newPart(folder, "DumpsterLid", Vector3.new(5.6, 0.3, 3.6), Vector3.new(dockC.X + 2, 2.85, dockC.Z - 9), Color3.fromRGB(35, 60, 35), Enum.Material.Metal)
	local dp = Instance.new("ProximityPrompt")
	dp.ActionText = "Abrir basurero"
	dp.HoldDuration = 0.5
	dp.MaxActivationDistance = 6
	dp.Parent = folder.Dumpster

	local benchW = Color3.fromRGB(115, 85, 55)
	newPart(folder, "BenchSeat", Vector3.new(4, 0.3, 1.4), Vector3.new(-18, 0.85, MAP.EntranceZ + 9), benchW, Enum.Material.WoodPlanks)
	newPart(folder, "BenchBack", Vector3.new(4, 1.2, 0.25), Vector3.new(-18, 1.7, MAP.EntranceZ + 9.6), benchW, Enum.Material.WoodPlanks)
	for _, x in { -19.4, -16.6 } do
		newPart(folder, "BenchLeg", Vector3.new(0.25, 0.7, 1.2), Vector3.new(x, 0.4, MAP.EntranceZ + 9), Color3.fromRGB(55, 55, 55), Enum.Material.Metal)
	end

	newPart(folder, "Mailbox", Vector3.new(0.8, 3.5, 0.8), Vector3.new(26, 1.75, MAP.EntranceZ + 9), Color3.fromRGB(18, 45, 110), Enum.Material.Metal)
	newPart(folder, "MailboxHead", Vector3.new(1, 0.7, 1.3), Vector3.new(26, 3.8, MAP.EntranceZ + 9), Color3.fromRGB(18, 45, 110), Enum.Material.Metal)
	local mb = Instance.new("ProximityPrompt")
	mb.ActionText = "Revisar buzon"
	mb.HoldDuration = 0.5
	mb.MaxActivationDistance = 5
	mb.Parent = folder.Mailbox

	for _, z in { MAP.EntranceZ + 14, MAP.EntranceZ + 22, MAP.EntranceZ + 30 } do
		newPart(folder, "SpeedBump", Vector3.new(14, 0.25, 0.7), Vector3.new(0, 0.08, z), Color3.fromRGB(200, 180, 25), Enum.Material.Neon, false)
	end

	local lampC = Color3.fromRGB(70, 74, 80)
	for _, x in { -40, 0, 40 } do
		local pole = newPart(folder, "StreetLamp", Vector3.new(0.4, 8, 0.4), Vector3.new(x, 4, MAP.EntranceZ + 14), lampC, Enum.Material.Metal)
		local head = newPart(folder, "LampHead", Vector3.new(2.5, 0.25, 2.5), Vector3.new(x, 8.2, MAP.EntranceZ + 14), Color3.fromRGB(255, 240, 190), Enum.Material.Neon, false)
		addPointLight(head, 35, 1.0, Color3.fromRGB(255, 240, 190))
	end
end

local function buildInteriorDetails()
	local folder = Instance.new("Folder")
	folder.Name = "InteriorDetails"
	folder.Parent = mapFolder

	newPart(folder, "EntranceMat", Vector3.new(10, 0.06, 3.5), Vector3.new(0, FLOOR_TOP + 0.03, MAP.EntranceZ - 3), Color3.fromRGB(70, 25, 25), Enum.Material.Fabric, false)

	local basketC = Color3.fromRGB(190, 195, 200)
	for x = -3, 3, 3 do
		local b = newPart(folder, "Basket", Vector3.new(1.4, 0.9, 1.4), Vector3.new(x, FLOOR_TOP + 0.45, MAP.EntranceZ - 6), basketC, Enum.Material.Plastic)
		b.Transparency = 0.3
		b.CanCollide = false
	end

	local exitPositions = {
		Vector3.new(0, FLOOR_TOP + WALL_H - 1.5, MAP.EntranceZ - 0.5),
		Vector3.new(-63, FLOOR_TOP + WALL_H - 1.5, 0),
		Vector3.new(63, FLOOR_TOP + WALL_H - 1.5, 0),
		Vector3.new(-52, FLOOR_TOP + WALL_H - 1.5, -31),
		Vector3.new(38, FLOOR_TOP + WALL_H - 1.5, -36),
	}
	for i, pos in exitPositions do
		local sg = newPart(folder, "ExitSign_"..i, Vector3.new(3, 1, 0.2), pos, Color3.fromRGB(0, 80, 20), Enum.Material.Neon, false)
		makeSurfaceText(sg, Enum.NormalId.Front, "SALIDA", Color3.fromRGB(255, 255, 255))
	end

	local prodC = { Color3.fromRGB(200, 50, 40), Color3.fromRGB(220, 160, 30), Color3.fromRGB(40, 160, 50) }
	for _, x in { -22, 22 } do
		local z = MAP.RegisterZ + 7
		newPart(folder, "ProdBin", Vector3.new(6, 1.5, 4), Vector3.new(x, FLOOR_TOP + 0.75, z), Color3.fromRGB(140, 100, 60), Enum.Material.WoodPlanks)
		for pi, clr in prodC do
			for pj = 0, 2 do
				newPart(folder, "Produce", Vector3.new(0.8, 0.6, 0.8), Vector3.new(x - 2 + pi * 2, FLOOR_TOP + 1.6 + pj * 0.3, z - 1 + pj * 1), clr, Enum.Material.LeafyGrass)
			end
		end
	end

	local mop = newPart(folder, "MopBucket", Vector3.new(1.2, 1.2, 1.2), Vector3.new(19.5, FLOOR_TOP + 0.6, MAP.ShelfCenterZ + 10), Color3.fromRGB(50, 120, 200), Enum.Material.Plastic)
	local mp = Instance.new("ProximityPrompt")
	mp.ActionText = "Tomar cubeta"
	mp.HoldDuration = 0.5
	mp.MaxActivationDistance = 5
	mp.Parent = mop

	local clipboard = newPart(folder, "Clipboard", Vector3.new(0.1, 1.2, 0.8), Vector3.new(-52, FLOOR_TOP + 3.5, -27), Color3.fromRGB(180, 170, 140), Enum.Material.WoodPlanks, false)
	local cp = Instance.new("ProximityPrompt")
	cp.ActionText = "Leer reporte"
	cp.HoldDuration = 0.5
	cp.MaxActivationDistance = 5
	cp.Parent = clipboard

	local firstAid = newPart(folder, "FirstAidKit", Vector3.new(1.5, 1.2, 0.4), Vector3.new(38, FLOOR_TOP + 5, -20), Color3.fromRGB(200, 40, 40), Enum.Material.Metal)
	makeSurfaceText(firstAid, Enum.NormalId.Front, "+", Color3.fromRGB(255, 255, 255))
	local fa = Instance.new("ProximityPrompt")
	fa.ActionText = "Abrir botiquin"
	fa.HoldDuration = 0.8
	fa.MaxActivationDistance = 5
	fa.Parent = firstAid

	local coffee = newPart(folder, "CoffeeMachine", Vector3.new(1.8, 2, 1.5), Vector3.new(38 + 4, FLOOR_TOP + 1.2, -28 + 6), Color3.fromRGB(60, 50, 40), Enum.Material.Metal)
	local cf = Instance.new("ProximityPrompt")
	cf.ActionText = "Preparar cafe"
	cf.HoldDuration = 1.5
	cf.MaxActivationDistance = 5
	cf.Parent = coffee
end

local function setupLighting()
	local ok, err = pcall(function()
		Lighting.Technology = Enum.Technology.ShadowMap
		Lighting.ClockTime = 0.2
		Lighting.Brightness = 0.45
		Lighting.Ambient = Color3.fromRGB(28, 32, 42)
		Lighting.OutdoorAmbient = Color3.fromRGB(20, 24, 32)
		Lighting.GlobalShadows = true
		Lighting.FogColor = Color3.fromRGB(18, 22, 32)
		Lighting.FogStart = 40
		Lighting.FogEnd = 180

		for _, child in Lighting:GetChildren() do
			if child:IsA("PostEffect") or child:IsA("Atmosphere") then
				child:Destroy()
			end
		end

		local atmosphere = Instance.new("Atmosphere")
		atmosphere.Density = 0.35
		atmosphere.Offset = 0.15
		atmosphere.Color = Color3.fromRGB(180, 190, 210)
		atmosphere.Decay = Color3.fromRGB(40, 45, 60)
		atmosphere.Glare = 0.1
		atmosphere.Haze = 1.2
		atmosphere.Parent = Lighting

		local colorCorrection = Instance.new("ColorCorrectionEffect")
		colorCorrection.Brightness = -0.05
		colorCorrection.Contrast = 0.15
		colorCorrection.Saturation = -0.2
		colorCorrection.TintColor = Color3.fromRGB(210, 215, 230)
		colorCorrection.Parent = Lighting

		local bloom = Instance.new("BloomEffect")
		bloom.Intensity = 0.4
		bloom.Size = 24
		bloom.Threshold = 1.2
		bloom.Parent = Lighting
	end)
	if not ok then
		warn("[MapBuilder] Lighting skip (no critical):", err)
	end
end

function MapBuilder.Build()
	local existing = Workspace:FindFirstChild("Map")
	if existing then
		existing:Destroy()
	end

	local existingWaypoints = Workspace:FindFirstChild("Waypoints")
	if existingWaypoints then
		existingWaypoints:Destroy()
	end

	mapFolder = Instance.new("Folder")
	mapFolder.Name = "Map"
	mapFolder.Parent = Workspace

	for _, name in { "TaskObjects", "EvidenceObjects", "Interactables" } do
		local folder = Workspace:FindFirstChild(name)
		if not folder then
			folder = Instance.new("Folder")
			folder.Name = name
			folder.Parent = Workspace
		end
	end

	buildFoundationAndFloor()
	buildShell()
	buildCeiling()
	buildColumns()
	buildRooms()
	buildAisles()
	buildRegisters()
	buildEntrance()
	buildEntranceStairs()
	buildParkingLot()
	buildLights()
	buildEmergencyLights()
	buildCCTVMounts()
	buildSpawns()
	buildMonsterSpawns()
	buildWaypoints()
	buildDecorations()
	buildTerrain()
	buildTrees()
	buildSidewalk()
	buildStreet()
	buildExteriorDetails()
	buildInteriorDetails()
	setupLighting()

	MapBuilder.ExitDoor = exitDoor
	MapBuilder.GlassDoor = glassDoor
	MapBuilder.ExitPrompt = exitPrompt
end

return MapBuilder
