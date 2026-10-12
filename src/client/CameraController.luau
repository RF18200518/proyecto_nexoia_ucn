local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.GameConfig)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local ClientState = require(script.Parent.ClientState)

local CameraController = {}

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera
local bobTimer = 0

local function updateHeadBob(dt)
	if ClientState.InCCTV then
		return
	end

	local char = player.Character
	if not char then
		return
	end

	local hrp = char:FindFirstChild("HumanoidRootPart")
	local humanoid = char:FindFirstChildOfClass("Humanoid")
	if not hrp or not humanoid then
		return
	end

	local speed = hrp.AssemblyLinearVelocity.Magnitude
	if speed > 1 and humanoid.FloorMaterial ~= Enum.Material.Air then
		local bobFreq = if ClientState.Sprinting then 14 else 8
		local bobAmpX = if ClientState.Sprinting then 0.12 else 0.06
		local bobAmpY = if ClientState.Sprinting then 0.16 else 0.08

		bobTimer += dt * bobFreq
		local offsetX = math.cos(bobTimer) * bobAmpX
		local offsetY = math.abs(math.sin(bobTimer)) * bobAmpY

		camera.CFrame = camera.CFrame * CFrame.new(offsetX, offsetY, 0)
	else
		bobTimer = 0
	end

	-- Efecto de estar caído (cámara baja pegada al piso)
	if ClientState.Downed then
		camera.CFrame = camera.CFrame * CFrame.new(0, -1.8, 0) * CFrame.Angles(0, 0, math.rad(15))
	end
end

function CameraController.SetCCTV(camIndex)
	local cctvList = Config.CCTV
	if camIndex < 1 or camIndex > #cctvList then
		return
	end

	local camDef = cctvList[camIndex]
	ClientState.InCCTV = true
	ClientState.CurrentCCTVIndex = camIndex

	camera.CameraType = Enum.CameraType.Scriptable
	camera.CFrame = CFrame.lookAt(camDef.Position, camDef.LookAt)
end

function CameraController.ExitCCTV()
	ClientState.InCCTV = false
	camera.CameraType = Enum.CameraType.Custom
	if player.Character and player.Character:FindFirstChild("Humanoid") then
		camera.CameraSubject = player.Character.Humanoid
	end
end

function CameraController.Start()
	Remotes.SetCCTVCamera.OnClientEvent:Connect(function(camIndex)
		CameraController.SetCCTV(camIndex)
	end)

	Remotes.ExitCCTVCamera.OnClientEvent:Connect(function()
		CameraController.ExitCCTV()
	end)

	RunService.RenderStepped:Connect(function(dt)
		updateHeadBob(dt)
	end)
end

return CameraController
