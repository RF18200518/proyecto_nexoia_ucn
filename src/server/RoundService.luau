local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.GameConfig)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local Players = game:GetService("Players")

local MapBuilder = require(script.Parent.MapBuilder)
local TaskService = require(script.Parent.TaskService)
local PowerService = require(script.Parent.PowerService)
local MonsterService = require(script.Parent.MonsterService)
local AnomalyService = require(script.Parent.AnomalyService)
local DataService = require(script.Parent.DataService)

local RoundService = {}

local currentPhase = "Waiting"
local earlyStart = false
local roundDone = false
local roundInProgress = false
local shiftStartTime = 0
local downedPlayers = {}

local function fireAll(name, ...)
	Remotes[name]:FireAllClients(...)
end

local function message(player, text)
	Remotes.ShowMessage:FireClient(player, text)
end

local function formatTime(minuteOfDay)
	local hour = math.floor(minuteOfDay / 60) % 24
	local minute = math.floor(minuteOfDay % 60)
	local period = if hour >= 12 then "PM" else "AM"
	local displayHour = hour % 12
	if displayHour == 0 then
		displayHour = 12
	end
	return string.format("%02d:%02d %s", displayHour, minute, period)
end

local function fireClock(forceMidnight)
	local minute
	if forceMidnight then
		minute = Config.Clock.MidnightMinuteOfDay
	else
		local elapsed = Config.Clock.StartMinuteOfDay
		if currentPhase == "NormalShift" then
			local elapsedSeconds = math.min(os.clock() - shiftStartTime, Config.Round.NormalShift)
			local progress = elapsedSeconds / Config.Round.NormalShift
			elapsed += progress * (Config.Clock.MidnightMinuteOfDay - Config.Clock.StartMinuteOfDay)
		else
			elapsed = Config.Clock.MidnightMinuteOfDay
		end
		minute = elapsed
	end
	Remotes.ClockChanged:FireAllClients(formatTime(minute))
end

local function buildResultsForPlayer(player, survived)
	local completed = TaskService.GetCompleted()
	local coins = completed * Config.Rewards.TaskCoins
	local xp = completed * Config.Rewards.TaskXP

	if survived then
		coins += Config.Rewards.SurviveCoins
		xp += Config.Rewards.SurviveXP
	end

	local anomalyCorrect, anomalyName = AnomalyService.GetResultForPlayer(player)
	if anomalyCorrect then
		coins += Config.Rewards.AnomalyCoins
		xp += Config.Rewards.AnomalyXP
	end

	-- Guardar recompensas en DataService
	DataService.AddReward(player, coins, xp, survived)

	return {
		Survived = survived,
		TasksCompleted = completed,
		TotalTasks = TaskService.GetTotal(),
		AnomalyCorrect = anomalyCorrect,
		AnomalyName = anomalyName,
		Coins = coins,
		XP = xp,
	}
end

local function lockExit(locked)
	if MapBuilder.ExitDoor then
		MapBuilder.ExitDoor:SetAttribute("Locked", locked)
	end
	if MapBuilder.ExitPrompt then
		MapBuilder.ExitPrompt.Enabled = not locked
	end
	if MapBuilder.GlassDoor then
		MapBuilder.GlassDoor.CanCollide = locked
	end
end

local function resetAllPlayers()
	downedPlayers = {}
	for _, player in Players:GetPlayers() do
		local char = player.Character
		if char then
			char:SetAttribute("IsDowned", false)
			local humanoid = char:FindFirstChildOfClass("Humanoid")
			if humanoid then
				humanoid.WalkSpeed = Config.Player.WalkSpeed
			end
		end
	end
end

local function finishRound()
	roundInProgress = false
	lockExit(false)
	MonsterService.Reset()
	TaskService.Reset()
	AnomalyService.Reset()
	PowerService.ResetPower()
	resetAllPlayers()
end

local function requestEnd(survived)
	if roundDone then
		return
	end
	if currentPhase ~= "Investigation" and currentPhase ~= "Chase" then
		return
	end
	roundDone = true
	currentPhase = "Results"
	fireAll("RoundStateChanged", currentPhase)

	for _, player in Players:GetPlayers() do
		local res = buildResultsForPlayer(player, survived)
		Remotes.ShowResults:FireClient(player, res)
	end

	task.wait(Config.Round.Results)
	finishRound()
end

local function handleExit(player)
	if currentPhase == "Waiting" or currentPhase == "Briefing" then
		message(player, "El turno comienza a las 10:00 PM.")
		return
	end
	if currentPhase == "NormalShift" then
		message(player, "La salida se abre a medianoche.")
		return
	end
	if currentPhase == "Midnight" then
		message(player, "La puerta esta bloqueada por el corte de luz.")
		return
	end
	if currentPhase == "Investigation" or currentPhase == "Chase" then
		requestEnd(true)
	end
end

local function runRound()
	roundDone = false

	currentPhase = "Waiting"
	fireAll("RoundStateChanged", currentPhase)
	earlyStart = false

	local deadline = os.clock() + Config.Round.Waiting
	while os.clock() < deadline and not earlyStart do
		task.wait(0.25)
	end
	if roundDone then
		return
	end

	currentPhase = "Briefing"
	fireAll("RoundStateChanged", currentPhase)
	roundInProgress = true
	PowerService.ResetPower()
	TaskService.StartRound()
	AnomalyService.StartRound()
	MonsterService.Reset()
	PowerService.SetDrain(Config.Power.DrainPerSecond)
	task.wait(Config.Round.Briefing)
	if roundDone then
		return
	end

	currentPhase = "NormalShift"
	fireAll("RoundStateChanged", currentPhase)
	shiftStartTime = os.clock()
	while os.clock() - shiftStartTime < Config.Round.NormalShift and TaskService.GetCompleted() < Config.Round.RequiredTasks do
		fireClock()
		task.wait(0.25)
		if roundDone then
			return
		end
	end
	fireClock()

	currentPhase = "Midnight"
	fireAll("RoundStateChanged", currentPhase)
	lockExit(true)
	PowerService.Blackout(Config.Round.Midnight)
	fireClock(true)
	task.wait(Config.Round.Midnight)
	if roundDone then
		return
	end

	currentPhase = "Investigation"
	fireAll("RoundStateChanged", currentPhase)
	lockExit(false)
	MonsterService.Activate()
	task.spawn(MonsterService.WarnAndAppear, Config.Round.MonsterAppearTime)
	task.wait(Config.Round.Investigation)
	if roundDone then
		return
	end

	currentPhase = "Chase"
	fireAll("RoundStateChanged", currentPhase)
	PowerService.SetDrain(Config.Power.ChaseDrainPerSecond)
	MonsterService.Activate()
	task.spawn(MonsterService.RunChase, Config.Round.MonsterChaseTime)
	task.wait(Config.Round.Chase)
	if roundDone then
		return
	end

	PowerService.SetDrain(Config.Power.DrainPerSecond)

	currentPhase = "Results"
	fireAll("RoundStateChanged", currentPhase)
	for _, player in Players:GetPlayers() do
		local res = buildResultsForPlayer(player, false)
		Remotes.ShowResults:FireClient(player, res)
	end
	task.wait(Config.Round.Results)
	finishRound()
end

function RoundService.Start()
	if MapBuilder.ExitPrompt then
		MapBuilder.ExitPrompt.Triggered:Connect(function(player)
			handleExit(player)
		end)
	end

	Remotes.RequestStartRound.OnServerEvent:Connect(function()
		if currentPhase == "Waiting" then
			earlyStart = true
		end
	end)

	TaskService.SetPhaseCheck(function()
		return currentPhase == "NormalShift" or currentPhase == "Investigation"
	end)

	-- Mecánica de Revivir Compañeros (Fase 4)
	Remotes.RequestRevive.OnServerEvent:Connect(function(healerPlayer, targetPlayerName)
		local targetPlayer = Players:FindFirstChild(targetPlayerName)
		if targetPlayer and targetPlayer.Character then
			local targetChar = targetPlayer.Character
			local isDowned = targetChar:GetAttribute("IsDowned")
			if isDowned then
				targetChar:SetAttribute("IsDowned", false)
				local humanoid = targetChar:FindFirstChildOfClass("Humanoid")
				if humanoid then
					humanoid.WalkSpeed = Config.Player.WalkSpeed
				end
				Remotes.PlayerRevived:FireAllClients(targetPlayer.Name)
				Remotes.PlayerStateChanged:FireAllClients(targetPlayer.Name, "Alive")
				Remotes.ShowMessage:FireClient(healerPlayer, "Has revivido a " .. targetPlayer.Name .. " (+" .. Config.Rewards.ReviveCoins .. " monedas)")
				Remotes.ShowMessage:FireClient(targetPlayer, healerPlayer.Name .. " te ha reanimado!")
				DataService.AddReward(healerPlayer, Config.Rewards.ReviveCoins, Config.Rewards.ReviveXP, false)
			end
		end
	end)

	task.spawn(function()
		while true do
			runRound()
			task.wait(2)
		end
	end)
end

return RoundService
