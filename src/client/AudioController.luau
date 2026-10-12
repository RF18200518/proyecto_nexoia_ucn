local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.GameConfig)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local ClientState = require(script.Parent.ClientState)

local AudioController = {}

local sounds = {}

local function getSound(name)
	local cached = sounds[name]
	if cached then
		return cached
	end
	local def = Config.Sounds[name]
	if not def or def.SoundId == "" then
		return nil
	end
	local sound = Instance.new("Sound")
	sound.Name = name
	sound.SoundId = "rbxassetid://" .. def.SoundId
	sound.Volume = def.Volume
	sound.Parent = SoundService
	sounds[name] = sound
	return sound
end

local function play(name)
	local sound = getSound(name)
	if sound then
		sound:Play()
	end
end

local function playWarningSequence()
	local sequence = Config.Sounds.WarningSequence
	task.delay(sequence.Cart, function()
		play("Cart")
	end)
	task.delay(sequence.Cart + sequence.Beep, function()
		play("Beep")
	end)
end

function AudioController.Start()
	Remotes.MonsterWarning.OnClientEvent:Connect(function(kind)
		if kind == "appear" then
			playWarningSequence()
		else
			play("MonsterGrowl")
		end
	end)

	Remotes.RoundStateChanged.OnClientEvent:Connect(function(phase)
		if phase == "Midnight" then
			play("Blackout")
		end
	end)

	Remotes.ShowResults.OnClientEvent:Connect(function(data)
		play(data.Survived and "Victory" or "Defeat")
	end)
end

return AudioController
