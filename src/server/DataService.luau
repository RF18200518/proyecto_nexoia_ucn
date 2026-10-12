local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.GameConfig)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local DataService = {}

local dataStore = nil
pcall(function()
	dataStore = DataStoreService:GetDataStore("NightShift_PlayerData_v1")
end)

local profiles = {}

local function deepCopy(t)
	local copy = {}
	for k, v in t do
		if type(v) == "table" then
			copy[k] = deepCopy(v)
		else
			copy[k] = v
		end
	end
	return copy
end

local function syncClient(player)
	local data = profiles[player.UserId]
	if data then
		Remotes.PlayerDataUpdated:FireClient(player, data)
	end
end

local function loadData(player)
	local data = deepCopy(Config.DefaultPlayerData)
	if dataStore then
		local ok, saved = pcall(function()
			return dataStore:GetAsync("Player_" .. player.UserId)
		end)
		if ok and type(saved) == "table" then
			for k, v in saved do
				data[k] = v
			end
		end
	end
	profiles[player.UserId] = data
	syncClient(player)
end

local function saveData(player)
	local data = profiles[player.UserId]
	if data and dataStore then
		pcall(function()
			dataStore:SetAsync("Player_" .. player.UserId, data)
		end)
	end
	profiles[player.UserId] = nil
end

function DataService.Init()
	Players.PlayerAdded:Connect(function(player)
		loadData(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		saveData(player)
	end)

	for _, player in Players:GetPlayers() do
		loadData(player)
	end

	-- Manejo de compras en la tienda
	Remotes.RequestBuyItem.OnServerEvent:Connect(function(player, itemType, itemId)
		local profile = profiles[player.UserId]
		if not profile then
			return
		end

		if itemType == "Flashlight" then
			local item = nil
			for _, flash in Config.Shop.Flashlights do
				if flash.Id == itemId then
					item = flash
					break
				end
			end

			if item and profile.Coins >= item.Price then
				if not table.find(profile.Inventory, itemId) then
					profile.Coins -= item.Price
					table.insert(profile.Inventory, itemId)
					profile.EquippedSkin = itemId
					syncClient(player)
					Remotes.ShowMessage:FireClient(player, "Has adquirido la skin: " .. item.Name)
				end
			else
				Remotes.ShowMessage:FireClient(player, "Monedas insuficientes.")
			end
		elseif itemType == "Upgrade" then
			local item = nil
			for _, upg in Config.Shop.Upgrades do
				if upg.Id == itemId then
					item = upg
					break
				end
			end

			if item and profile.Coins >= item.Price then
				if not table.find(profile.Upgrades, itemId) then
					profile.Coins -= item.Price
					table.insert(profile.Upgrades, itemId)
					syncClient(player)
					Remotes.ShowMessage:FireClient(player, "Mejora desbloqueada: " .. item.Name)
				end
			else
				Remotes.ShowMessage:FireClient(player, "Monedas insuficientes.")
			end
		end
	end)

	-- Manejo de equipar skin
	Remotes.RequestEquipSkin.OnServerEvent:Connect(function(player, skinId)
		local profile = profiles[player.UserId]
		if profile and table.find(profile.Inventory, skinId) then
			profile.EquippedSkin = skinId
			syncClient(player)
			Remotes.ShowMessage:FireClient(player, "Skin equipada.")
		end
	end)
end

function DataService.AddReward(player, coins, xp, survived)
	local profile = profiles[player.UserId]
	if not profile then
		return
	end

	profile.Coins += coins
	profile.XP += xp
	if survived then
		profile.RoundsWon += 1
	end

	-- Subida de nivel cada 100 XP
	local newLevel = math.floor(profile.XP / 100) + 1
	if newLevel > profile.Level then
		profile.Level = newLevel
		Remotes.ShowMessage:FireClient(player, "¡Subiste al nivel " .. tostring(newLevel) .. "!")
	end

	syncClient(player)
end

function DataService.GetData(player)
	return profiles[player.UserId] or deepCopy(Config.DefaultPlayerData)
end

return DataService
