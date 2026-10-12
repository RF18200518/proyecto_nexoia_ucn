local Config = require(game:GetService("ReplicatedStorage").Shared.GameConfig)

local ClientState = {
	Phase = "Waiting",
	Stamina = 100,
	MaxStamina = 100,
	Battery = 100,
	MaxBattery = 100,
	Sprinting = false,
	SprintHeld = false,
	FlashlightOn = false,
	RequestFlashlightToggle = false,
	Downed = false,
	BleedoutRemaining = 45,
	InCCTV = false,
	CurrentCCTVIndex = 1,
	InAnomalyMenu = false,
	InShopMenu = false,
	PlayerData = {
		Coins = 0,
		XP = 0,
		Level = 1,
		RoundsWon = 0,
		EquippedSkin = "default",
		Inventory = { "default" },
		Upgrades = {},
	},
}

return ClientState
