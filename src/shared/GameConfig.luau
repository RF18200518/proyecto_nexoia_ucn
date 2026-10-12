local Config = {}

-- Mapa y Dimensiones
Config.WallHeight = 16
Config.WallThickness = 1
Config.StoreSize = Vector3.new(140, 12, 90)

Config.Map = {
	FloorY = 0.5,
	FloorTop = 1.0,
	HalfWidth = 70,
	HalfDepth = 45,
	AisleSpacing = 13,
	ShelfOffset = 3.6,
	ShelfDepth = 1.4,
	ShelfHeight = 7.2,
	ShelfLength = 56,
	ShelfCenterZ = -6,
	RegisterZ = 26,
	EntranceZ = 44.5,
}

Config.Exit = {
	Position = Vector3.new(0, 4, 44.5),
	Size = Vector3.new(8, 7, 1),
}

Config.Aisles = {
	{ X = -32.5, Name = "Pasillo 1 - Limpieza" },
	{ X = -19.5, Name = "Pasillo 2 - Enlatados" },
	{ X = -6.5, Name = "Pasillo 3 - Snacks" },
	{ X = 6.5, Name = "Pasillo 4 - Bebidas" },
	{ X = 19.5, Name = "Pasillo 5 - Lacteos" },
	{ X = 32.5, Name = "Pasillo 6 - Panaderia" },
}

Config.Map.Rooms = {
	Staff = { Center = Vector3.new(38, 0, -28), Size = Vector3.new(24, 0, 16), Color = "staff", Door = { side = "north", gap = 4 } },
	Security = { Center = Vector3.new(-52, 0, -24), Size = Vector3.new(18, 0, 14), Color = "security", Door = { side = "east", gap = 3.5 } },
	Warehouse = { Center = Vector3.new(-58, 0, 2), Size = Vector3.new(28, 0, 30), Color = "warehouse", Door = { side = "east", gap = 4 } },
	LoadingDock = { Center = Vector3.new(-58, 0, -36), Size = Vector3.new(28, 0, 14), Color = "dock", Door = { side = "east", gap = 4 } },
	Freezers = { Center = Vector3.new(52, 0, 0), Size = Vector3.new(22, 0, 34), Color = "freezer", Door = { side = "west", gap = 4 } },
	Bathrooms = { Center = Vector3.new(58, 0, -28), Size = Vector3.new(14, 0, 12), Color = "bathroom", Door = { side = "west", gap = 3 } },
}

Config.Map.TaskPositions = {
	StockBox = Vector3.new(-56, 2.5, 4),
	CleanSpill = Vector3.new(19.5, 1.05, -6),
	RepairFuse = Vector3.new(-56, 4.5, -4),
	CheckCamera = Vector3.new(-52, 2.5, -22),
	ReturnCart = Vector3.new(19.5, 1.8, 16),
	CartCorral = Vector3.new(12, 1.8, 38),
}

-- Paleta de colores
Config.Colors = {
	DarkBlue = Color3.fromRGB(15, 20, 30),
	DarkerBlue = Color3.fromRGB(10, 12, 18),
	Yellow = Color3.fromRGB(245, 197, 66),
	Red = Color3.fromRGB(200, 35, 35),
	NeonRed = Color3.fromRGB(255, 30, 30),
	White = Color3.fromRGB(220, 228, 235),
	Green = Color3.fromRGB(60, 185, 90),
	Cyan = Color3.fromRGB(50, 190, 220),
	Purple = Color3.fromRGB(160, 70, 220),
	Floor = Color3.fromRGB(205, 210, 215),
	Wall = Color3.fromRGB(178, 184, 190),
	Shelf = Color3.fromRGB(96, 106, 118),
	ShelfDark = Color3.fromRGB(70, 78, 88),
	Ceiling = Color3.fromRGB(35, 38, 44),
	Cart = Color3.fromRGB(120, 128, 138),
	Monster = Color3.fromRGB(8, 8, 12),
	MonsterEye = Color3.fromRGB(255, 20, 20),
}

-- Jugador & Movimiento
Config.Player = {
	WalkSpeed = 16,
	SprintSpeed = 22,
	DownedSpeed = 4,
	JumpHeight = 1,
	InteractionDistance = 9,
	Stamina = {
		Max = 100,
		SprintDrain = 18,
		Regeneration = 14,
		RegenerationDelay = 1.0,
		LowThreshold = 25,
	},
	Flashlight = {
		MaxBattery = 100,
		BatteryDrain = 1.2,
		BatteryRegenRate = 3.5,
		BatteryWarning = 20,
		Range = 44,
		Angle = 62,
		Brightness = 2.4,
	},
	Downed = {
		BleedoutTime = 45,
		ReviveHoldTime = 2.5,
		ReviveDistance = 8,
	},
}

-- Sistema de Energia
Config.Power = {
	Start = 100,
	DrainPerSecond = 0.16,
	ChaseDrainPerSecond = 0.40,
	GeneratorRepair = 25,
}

-- Tiempos de Ronda
Config.Round = {
	Waiting = 10,
	Briefing = 12,
	NormalShift = 90,
	Midnight = 8,
	Investigation = 40,
	Chase = 35,
	Results = 18,
	AssignedTasks = 5,
	RequiredTasks = 3,
	MonsterAppearTime = 6,
	MonsterChaseTime = 14,
}

-- Reloj del Juego
Config.Clock = {
	StartMinuteOfDay = 22 * 60,
	MidnightMinuteOfDay = 24 * 60,
}

-- Tareas
Config.Tasks = {
	StockBox = { Name = "Colocar cajas", HoldTime = 2, Coins = 15, XP = 20 },
	CleanSpill = { Name = "Limpiar derrame", HoldTime = 2.5, Coins = 15, XP = 20 },
	RepairFuse = { Name = "Reparar fusible", HoldTime = 2.0, Coins = 20, XP = 25 },
	CheckCamera = { Name = "Revisar camaras", HoldTime = 1.0, Coins = 15, XP = 20 },
	ReturnCart = { Name = "Regresar carrito", HoldTime = 1.5, Coins = 15, XP = 20 },
}

-- Sistema de Camaras CCTV
Config.CCTV = {
	{
		Id = "CAM_01",
		Name = "CAM 01 - Pasillos Centrales",
		Position = Vector3.new(0, 14.5, -12),
		LookAt = Vector3.new(0, 2, 4),
	},
	{
		Id = "CAM_02",
		Name = "CAM 02 - Zona de Cajas",
		Position = Vector3.new(24, 14.5, 34),
		LookAt = Vector3.new(0, 2, 26),
	},
	{
		Id = "CAM_03",
		Name = "CAM 03 - Congeladores",
		Position = Vector3.new(48, 14.5, 4),
		LookAt = Vector3.new(52, 2, 0),
	},
	{
		Id = "CAM_04",
		Name = "CAM 04 - Bodega & Generador",
		Position = Vector3.new(-64, 14.5, 2),
		LookAt = Vector3.new(-56, 2, 2),
	},
}

-- Anomalías Aleatorias
Config.Anomalies = {
	{
		Id = "Mannequin",
		Name = "Maniqui Errante",
		Description = "Una figura inerte que cambia de posicion en los pasillos.",
		Hint = "Se escuchan crujidos de plastico cerca de los estantes.",
	},
	{
		Id = "FloatingProducts",
		Name = "Gravedad Cero",
		Description = "Varios articulos flotan suspendidos en el aire.",
		Hint = "Los productos no tocan los estantes en el pasillo 3.",
	},
	{
		Id = "GlitchedClock",
		Name = "Desfase Temporal",
		Description = "El reloj de pared de descanso corre en reversa.",
		Hint = "Las manecillas no siguen el tiempo real en la sala de empleados.",
	},
	{
		Id = "ShadowClerk",
		Name = "Sombra del Pasillo 0",
		Description = "Una silueta oscura que observa desde los rincones.",
		Hint = "Una figura desaparece al apuntarle con la linterna.",
	},
}

-- Recompensas & Economia
Config.Rewards = {
	TaskCoins = 15,
	TaskXP = 20,
	SurviveCoins = 80,
	SurviveXP = 110,
	TeamBonus = 30,
	ReviveCoins = 25,
	ReviveXP = 40,
	AnomalyCoins = 60,
	AnomalyXP = 120,
}

-- Monstruo (Cliente Cero) & Pathfinding
Config.Monster = {
	WalkSpeed = 10,
	ChaseSpeed = 18.5,
	DetectionRange = 60,
	AttackRange = 4.2,
	AttackCooldown = 6,
	HearingRange = 45,
	VisionFOV = 120,
	AgentRadius = 2.2,
	AgentHeight = 5.0,
	AgentCanJump = false,
}

-- Tienda del Lobby
Config.Shop = {
	Flashlights = {
		{ Id = "default", Name = "Linterna Estandar", Color = Color3.fromRGB(255, 250, 235), Price = 0, Brightness = 2.4 },
		{ Id = "cyan_neon", Name = "Luz Neon Cyan", Color = Color3.fromRGB(60, 220, 255), Price = 120, Brightness = 2.6 },
		{ Id = "tactical_red", Name = "Luz Tactica Roja", Color = Color3.fromRGB(255, 60, 60), Price = 180, Brightness = 2.5 },
		{ Id = "uv_purple", Name = "Luz Ultravioleta", Color = Color3.fromRGB(190, 80, 255), Price = 250, Brightness = 2.8 },
	},
	Upgrades = {
		{ Id = "speed_boots", Name = "Zapatillas Ligeras", Description = "+15% Regeneracion de Stamina", Price = 200 },
		{ Id = "heavy_battery", Name = "Bateria de Litio", Description = "+25% Duracion de Linterna", Price = 200 },
	},
}

-- Datos por defecto de jugador
Config.DefaultPlayerData = {
	Coins = 0,
	XP = 0,
	Level = 1,
	RoundsWon = 0,
	EquippedSkin = "default",
	Inventory = { "default" },
	Upgrades = {},
}

-- Configuracion de Sonidos
Config.Sounds = {
	Cart = { SoundId = "", Volume = 0.5 },
	Beep = { SoundId = "", Volume = 0.5 },
	Footstep = { SoundId = "", Volume = 0.4 },
	MonsterStep = { SoundId = "", Volume = 0.7 },
	Blackout = { SoundId = "", Volume = 0.7 },
	MonsterGrowl = { SoundId = "", Volume = 0.8 },
	Heartbeat = { SoundId = "", Volume = 0.6 },
	Victory = { SoundId = "", Volume = 0.6 },
	Defeat = { SoundId = "", Volume = 0.6 },
	WarningSequence = {
		Cart = 1.0,
		Beep = 0.6,
		Silence = 0.8,
	},
}

return Config
