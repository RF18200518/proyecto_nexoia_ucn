local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.GameConfig)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

local PowerService = {}

local lightsFolder
local emergencyFolder
local power = Config.Power.Start
local drain = 0
local blackoutUntil = 0
local blackedOut = false
local loopRunning = false

local function getLightsFolder()
	if lightsFolder and lightsFolder.Parent then
		return lightsFolder
	end
	local map = Workspace:FindFirstChild("Map")
	if map then
		lightsFolder = map:FindFirstChild("Lights")
	end
	return lightsFolder
end

local function getEmergencyFolder()
	if emergencyFolder and emergencyFolder.Parent then
		return emergencyFolder
	end
	local map = Workspace:FindFirstChild("Map")
	if map then
		emergencyFolder = map:FindFirstChild("EmergencyLights")
	end
	return emergencyFolder
end

local function allLights()
	local folder = getLightsFolder()
	local parts = {}
	if folder then
		for _, child in folder:GetChildren() do
			table.insert(parts, child)
		end
	end
	return parts
end

local function setEmergencyLights(on, pulse)
	local folder = getEmergencyFolder()
	if not folder then
		return
	end
	for _, part in folder:GetChildren() do
		local light = part:FindFirstChildOfClass("PointLight")
		if light then
			light.Enabled = on
			if on and pulse then
				light.Brightness = 0.5 + 0.5 * math.sin(os.clock() * 4)
			else
				light.Brightness = 0.9
			end
		end
	end
end

local function updateTier()
	if blackedOut then
		for _, part in allLights() do
			local light = part:FindFirstChildOfClass("PointLight")
			if light then
				light.Enabled = math.random() > 0.85
			end
		end
		setEmergencyLights(true, true)
		return
	end

	if power > 50 then
		for _, part in allLights() do
			local light = part:FindFirstChildOfClass("PointLight")
			if light then
				light.Enabled = true
				light.Brightness = 1.2
			end
		end
		setEmergencyLights(false)
	elseif power > 25 then
		for _, part in allLights() do
			local light = part:FindFirstChildOfClass("PointLight")
			if light then
				light.Enabled = math.random() > 0.25
				light.Brightness = 0.9
			end
		end
		setEmergencyLights(true, false)
	elseif power > 0 then
		for _, part in allLights() do
			local light = part:FindFirstChildOfClass("PointLight")
			if light then
				light.Enabled = math.random() > 0.65
				light.Brightness = 0.6
			end
		end
		setEmergencyLights(true, true)
	else
		for _, part in allLights() do
			local light = part:FindFirstChildOfClass("PointLight")
			if light then
				light.Enabled = false
			end
		end
		setEmergencyLights(true, true)
	end
end

local function powerLoop()
	if loopRunning then
		return
	end
	loopRunning = true
	while true do
		task.wait(0.35)
		local now = os.clock()

		if blackedOut then
			if now >= blackoutUntil then
				blackedOut = false
				updateTier()
			else
				updateTier()
			end
		elseif drain > 0 then
			power = math.max(0, power - drain * 0.35)
			Remotes.PowerChanged:FireAllClients(power)
			updateTier()
		end
	end
end

function PowerService.Init()
	getLightsFolder()
	getEmergencyFolder()
	task.spawn(powerLoop)
end

function PowerService.SetDrain(value)
	drain = value
end

function PowerService.Blackout(seconds)
	blackedOut = true
	blackoutUntil = os.clock() + seconds
	for _, part in allLights() do
		local light = part:FindFirstChildOfClass("PointLight")
		if light then
			light.Enabled = false
		end
	end
	setEmergencyLights(true, true)
	Remotes.PowerChanged:FireAllClients(power)
end

function PowerService.ResetPower()
	power = Config.Power.Start
	drain = 0
	blackedOut = false
	for _, part in allLights() do
		local light = part:FindFirstChildOfClass("PointLight")
		if light then
			light.Enabled = true
			light.Brightness = 1.2
		end
	end
	setEmergencyLights(false)
	Remotes.PowerChanged:FireAllClients(power)
end

function PowerService.AddPower(amount)
	power = math.min(100, power + amount)
	Remotes.PowerChanged:FireAllClients(power)
	updateTier()
end

function PowerService.GetPower()
	return power
end

return PowerService
