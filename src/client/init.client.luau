local Players = game:GetService("Players")
local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

local AudioController = require(script.AudioController)
local UIController = require(script.UIController)
local ClientController = require(script.ClientController)
local CameraController = require(script.CameraController)

ClientController.Start()
UIController.Start(PlayerGui)
AudioController.Start()
CameraController.Start()
