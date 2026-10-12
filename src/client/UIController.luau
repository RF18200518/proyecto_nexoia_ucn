local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage.Shared.GameConfig)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local ClientState = require(script.Parent.ClientState)

local player = Players.LocalPlayer

local UIController = {}

local PHASE_NAMES = {
	Waiting = "SALA DE ESPERA",
	Briefing = "INICIO DE TURNO",
	NormalShift = "TURNO NOCTURNO",
	Midnight = "MEDIANOCHE (APAGON)",
	Investigation = "INVESTIGACION",
	Chase = "CACERIA",
	Results = "RESULTADOS",
}

local ui
local clockLabel
local phaseLabel
local powerLabel
local powerFill
local coinLabel
local levelLabel
local taskList
local blackoutFrame
local warningLabel
local downedFrame
local bleedoutBar
local resultsFrame
local resultsText
local messageLabel
local sprintButton
local flashlightButton
local startButton
local shopButton
local shopFrame
local cctvFrame
local cctvCamLabel
local anomalyFrame
local staminaBar
local staminaLabel
local batteryBar
local batteryLabel
local powerValue = 100

local function tween(instance, time, props)
	local tw = TweenService:Create(instance, TweenInfo.new(time, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props)
	tw:Play()
	return tw
end

local function makeFrame(parent, name, position, size, bg, alpha, zIndex)
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.BackgroundColor3 = bg or Color3.new(0, 0, 0)
	frame.BackgroundTransparency = 1 - (alpha or 0.85)
	frame.BorderSizePixel = 0
	frame.Position = position
	frame.Size = size
	frame.ZIndex = zIndex or 1
	frame.Parent = parent
	return frame
end

local function makeLabel(parent, name, text, position, size, fontSize, color, align, zIndex)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.BackgroundTransparency = 1
	label.Position = position
	label.Size = size
	label.Font = Enum.Font.GothamBold
	label.Text = text
	label.TextColor3 = color or Config.Colors.White
	label.TextSize = fontSize or 14
	label.TextWrapped = true
	label.ZIndex = zIndex or 1
	if align == "center" then
		label.TextXAlignment = Enum.TextXAlignment.Center
		label.TextYAlignment = Enum.TextYAlignment.Center
	elseif align == "right" then
		label.TextXAlignment = Enum.TextXAlignment.Right
	else
		label.TextXAlignment = Enum.TextXAlignment.Left
	end
	label.Parent = parent
	return label
end

local function makeButton(parent, name, text, position, size, zIndex)
	local button = Instance.new("TextButton")
	button.Name = name
	button.BackgroundColor3 = Color3.fromRGB(24, 28, 38)
	button.BackgroundTransparency = 0.2
	button.BorderSizePixel = 1
	button.BorderColor3 = Config.Colors.Yellow
	button.Font = Enum.Font.GothamBold
	button.Text = text
	button.TextColor3 = Config.Colors.White
	button.TextSize = 14
	button.Position = position
	button.Size = size or UDim2.new(0, 110, 0, 44)
	button.ZIndex = zIndex or 2
	button.Parent = parent
	return button
end

local function buildHUD(parent)
	-- Panel Superior Izquierdo (Reloj, Fase, Monedas, Nivel)
	local topBar = makeFrame(parent, "TopBar", UDim2.new(0, 16, 0, 16), UDim2.new(0, 320, 0, 95), Color3.fromRGB(15, 18, 26), 0.9, 2)
	clockLabel = makeLabel(topBar, "Clock", "10:00 PM", UDim2.new(0, 12, 0, 8), UDim2.new(0, 140, 0, 26), 20, Config.Colors.Yellow)
	phaseLabel = makeLabel(topBar, "Phase", "SALA DE ESPERA", UDim2.new(0, 155, 0, 10), UDim2.new(0, 155, 0, 22), 12, Config.Colors.White, "right")

	coinLabel = makeLabel(topBar, "Coins", "🪙 Monedas: 0", UDim2.new(0, 12, 0, 40), UDim2.new(0, 140, 0, 20), 13, Color3.fromRGB(255, 215, 80))
	levelLabel = makeLabel(topBar, "Level", "⭐ Nivel: 1", UDim2.new(0, 155, 0, 40), UDim2.new(0, 155, 0, 20), 13, Color3.fromRGB(120, 210, 255), "right")

	-- Botón Tienda
	shopButton = makeButton(topBar, "OpenShopButton", "TIENDA [B]", UDim2.new(0, 12, 0, 64), UDim2.new(1, -24, 0, 24), 3)
	shopButton.BackgroundColor3 = Color3.fromRGB(35, 45, 65)

	-- Panel de Energía
	local powerBar = makeFrame(parent, "PowerPanel", UDim2.new(0, 16, 0, 120), UDim2.new(0, 320, 0, 48), Color3.fromRGB(15, 18, 26), 0.9, 2)
	powerLabel = makeLabel(powerBar, "PowerTitle", "ENERGIA: 100%", UDim2.new(0, 12, 0, 6), UDim2.new(0, 200, 0, 16), 12, Config.Colors.White)
	local pBg = makeFrame(powerBar, "PowerBg", UDim2.new(0, 12, 0, 26), UDim2.new(1, -24, 0, 12), Color3.fromRGB(30, 35, 45), 1, 3)
	powerFill = makeFrame(pBg, "PowerFill", UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 1, 0), Config.Colors.Green, 1, 4)

	-- Panel de Objetivos (Tareas)
	local taskPanel = makeFrame(parent, "TaskPanel", UDim2.new(1, -280, 0, 16), UDim2.new(0, 264, 0, 200), Color3.fromRGB(15, 18, 26), 0.9, 2)
	makeLabel(taskPanel, "Title", "TAREAS DEL TURNO", UDim2.new(0, 12, 0, 8), UDim2.new(1, -24, 0, 20), 14, Config.Colors.Yellow)

	taskList = Instance.new("ScrollingFrame")
	taskList.Name = "TaskList"
	taskList.BackgroundTransparency = 1
	taskList.Position = UDim2.new(0, 12, 0, 32)
	taskList.Size = UDim2.new(1, -24, 1, -40)
	taskList.CanvasSize = UDim2.new(0, 0, 0, 0)
	taskList.ScrollBarThickness = 4
	taskList.ZIndex = 3
	taskList.Parent = taskPanel

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 6)
	layout.Parent = taskList

	-- Barra de Stamina
	local staminaFrame = makeFrame(parent, "StaminaPanel", UDim2.new(0.5, -140, 1, -70), UDim2.new(0, 280, 0, 24), Color3.fromRGB(15, 18, 26), 0.85, 2)
	staminaLabel = makeLabel(staminaFrame, "StaminaLabel", "STAMINA [SHIFT]", UDim2.new(0, 8, 0, 2), UDim2.new(1, -16, 1, -4), 11, Config.Colors.White, "center", 4)
	staminaBar = makeFrame(staminaFrame, "StaminaFill", UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 1, 0), Config.Colors.Green, 0.7, 3)

	-- Barra de Batería de Linterna
	local batteryFrame = makeFrame(parent, "BatteryPanel", UDim2.new(0.5, -140, 1, -42), UDim2.new(0, 280, 0, 20), Color3.fromRGB(15, 18, 26), 0.85, 2)
	batteryLabel = makeLabel(batteryFrame, "BatteryLabel", "LINTERNA: 100% [F]", UDim2.new(0, 8, 0, 2), UDim2.new(1, -16, 1, -4), 11, Config.Colors.White, "center", 4)
	batteryBar = makeFrame(batteryFrame, "BatteryFill", UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 1, 0), Config.Colors.Cyan, 0.7, 3)

	-- Mensaje Central Flotante
	messageLabel = makeLabel(parent, "CenterMessage", "", UDim2.new(0.5, -250, 0.2, 0), UDim2.new(0, 500, 0, 40), 16, Config.Colors.Yellow, "center", 5)

	-- Advertencia de Monstruo
	warningLabel = makeLabel(parent, "MonsterWarning", "", UDim2.new(0.5, -300, 0.28, 0), UDim2.new(0, 600, 0, 50), 22, Config.Colors.NeonRed, "center", 5)

	-- Botón Iniciar Ronda Anticipado
	startButton = makeButton(parent, "StartRoundEarly", "INICIAR TURNO", UDim2.new(0.5, -80, 0.12, 0), UDim2.new(0, 160, 0, 36), 4)
	startButton.BackgroundColor3 = Color3.fromRGB(30, 80, 45)
	startButton.MouseButton1Click:Connect(function()
		Remotes.RequestStartRound:FireServer()
		startButton.Visible = false
	end)

	local Lighting = game:GetService("Lighting")
	local debugButton = makeButton(parent, "DayNightToggle", "DIA / NOCHE", UDim2.new(1, -130, 0, 16), UDim2.new(0, 114, 0, 32), 4)
	debugButton.BackgroundColor3 = Color3.fromRGB(80, 70, 20)
	local isDay = false
	debugButton.MouseButton1Click:Connect(function()
		isDay = not isDay
		if isDay then
			Lighting.ClockTime = 14
			Lighting.Brightness = 2.5
			Lighting.Ambient = Color3.fromRGB(180, 180, 180)
			Lighting.OutdoorAmbient = Color3.fromRGB(200, 200, 200)
			Lighting.FogEnd = 10000
			debugButton.Text = "NOCHE [ON]"
		else
			Lighting.ClockTime = 0.2
			Lighting.Brightness = 0.45
			Lighting.Ambient = Color3.fromRGB(28, 32, 42)
			Lighting.OutdoorAmbient = Color3.fromRGB(20, 24, 32)
			Lighting.FogEnd = 180
			debugButton.Text = "DIA / NOCHE"
		end
	end)
end

local function buildCCTVUI(parent)
	cctvFrame = makeFrame(parent, "CCTVFrame", UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 1, 0), Color3.fromRGB(0, 5, 10), 0.3, 10)
	cctvFrame.Visible = false

	-- Header CCTV
	makeLabel(cctvFrame, "RecIndicator", "● REC  [ CCTV MOONMART 24 ]", UDim2.new(0, 30, 0, 30), UDim2.new(0, 400, 0, 30), 18, Config.Colors.NeonRed, "left", 11)
	cctvCamLabel = makeLabel(cctvFrame, "CurrentCamTitle", "CAM 01", UDim2.new(0.5, -200, 0, 30), UDim2.new(0, 400, 0, 30), 18, Config.Colors.Green, "center", 11)

	-- Botón Salir
	local exitBtn = makeButton(cctvFrame, "ExitCCTV", "SALIR DE CAMARAS [ESC]", UDim2.new(1, -220, 0, 30), UDim2.new(0, 190, 0, 38), 12)
	exitBtn.BackgroundColor3 = Color3.fromRGB(80, 25, 25)
	exitBtn.MouseButton1Click:Connect(function()
		cctvFrame.Visible = false
		local CameraController = require(script.Parent.CameraController)
		CameraController.ExitCCTV()
	end)

	-- Botones de cámaras inferiores
	local btnBar = makeFrame(cctvFrame, "CamButtons", UDim2.new(0.5, -260, 1, -80), UDim2.new(0, 520, 0, 50), Color3.fromRGB(15, 18, 26), 0.9, 11)
	for i, cam in Config.CCTV do
		local btn = makeButton(btnBar, "CamBtn_" .. i, "CAM " .. i, UDim2.new(0, 10 + (i - 1) * 128, 0, 6), UDim2.new(0, 118, 0, 38), 12)
		btn.MouseButton1Click:Connect(function()
			local CameraController = require(script.Parent.CameraController)
			CameraController.SetCCTV(i)
			cctvCamLabel.Text = cam.Name
		end)
	end
end

local function buildDownedUI(parent)
	downedFrame = makeFrame(parent, "DownedOverlay", UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 1, 0), Color3.fromRGB(60, 0, 0), 0.6, 8)
	downedFrame.Visible = false

	local title = makeLabel(downedFrame, "DownedTitle", "¡ESTAS HERIDO!", UDim2.new(0.5, -250, 0.35, 0), UDim2.new(0, 500, 0, 40), 28, Config.Colors.NeonRed, "center", 9)
	local sub = makeLabel(downedFrame, "DownedSub", "Pide ayuda a tus companeros de equipo para que te reanimen.", UDim2.new(0.5, -250, 0.44, 0), UDim2.new(0, 500, 0, 24), 14, Config.Colors.White, "center", 9)

	local barBg = makeFrame(downedFrame, "BleedoutBg", UDim2.new(0.5, -150, 0.52, 0), UDim2.new(0, 300, 0, 16), Color3.fromRGB(20, 20, 20), 1, 9)
	bleedoutBar = makeFrame(barBg, "BleedoutFill", UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 1, 0), Config.Colors.NeonRed, 1, 10)
end

local function buildShopUI(parent)
	shopFrame = makeFrame(parent, "ShopModal", UDim2.new(0.5, -280, 0.5, -220), UDim2.new(0, 560, 0, 440), Color3.fromRGB(15, 18, 26), 0.95, 15)
	shopFrame.Visible = false

	makeLabel(shopFrame, "ShopTitle", "TIENDA DE EMPLEADOS — MOONMART 24", UDim2.new(0, 20, 0, 16), UDim2.new(1, -40, 0, 26), 18, Config.Colors.Yellow, "center", 16)

	local closeBtn = makeButton(shopFrame, "CloseShop", "X", UDim2.new(1, -44, 0, 12), UDim2.new(0, 32, 0, 32), 17)
	closeBtn.BackgroundColor3 = Color3.fromRGB(80, 25, 25)
	closeBtn.MouseButton1Click:Connect(function()
		shopFrame.Visible = false
	end)

	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = "ShopScroll"
	scroll.BackgroundTransparency = 1
	scroll.Position = UDim2.new(0, 20, 0, 54)
	scroll.Size = UDim2.new(1, -40, 1, -70)
	scroll.CanvasSize = UDim2.new(0, 0, 0, 500)
	scroll.ScrollBarThickness = 4
	scroll.ZIndex = 16
	scroll.Parent = shopFrame

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 8)
	layout.Parent = scroll

	-- Linternas
	for _, skin in Config.Shop.Flashlights do
		local card = makeFrame(scroll, "SkinCard_" .. skin.Id, UDim2.new(0, 0, 0, 0), UDim2.new(1, -8, 0, 52), Color3.fromRGB(24, 28, 38), 0.8, 17)
		makeLabel(card, "Name", skin.Name, UDim2.new(0, 12, 0, 8), UDim2.new(0, 220, 0, 20), 14, skin.Color)
		makeLabel(card, "Price", "🪙 " .. tostring(skin.Price) .. " monedas", UDim2.new(0, 12, 0, 28), UDim2.new(0, 220, 0, 16), 11, Config.Colors.Yellow)

		local actionBtn = makeButton(card, "ActionBtn", "COMPRAR", UDim2.new(1, -120, 0, 8), UDim2.new(0, 108, 0, 36), 18)
		actionBtn.MouseButton1Click:Connect(function()
			local inv = ClientState.PlayerData.Inventory or {}
			if table.find(inv, skin.Id) then
				Remotes.RequestEquipSkin:FireServer(skin.Id)
			else
				Remotes.RequestBuyItem:FireServer("Flashlight", skin.Id)
			end
		end)
	end

	-- Mejoras
	for _, upg in Config.Shop.Upgrades do
		local card = makeFrame(scroll, "UpgCard_" .. upg.Id, UDim2.new(0, 0, 0, 0), UDim2.new(1, -8, 0, 52), Color3.fromRGB(24, 28, 38), 0.8, 17)
		makeLabel(card, "Name", upg.Name, UDim2.new(0, 12, 0, 8), UDim2.new(0, 240, 0, 20), 14, Config.Colors.Cyan)
		makeLabel(card, "Desc", upg.Description .. " — 🪙 " .. tostring(upg.Price), UDim2.new(0, 12, 0, 28), UDim2.new(0, 300, 0, 16), 11, Config.Colors.White)

		local buyBtn = makeButton(card, "BuyBtn", "DESBLOQUEAR", UDim2.new(1, -120, 0, 8), UDim2.new(0, 108, 0, 36), 18)
		buyBtn.MouseButton1Click:Connect(function()
			Remotes.RequestBuyItem:FireServer("Upgrade", upg.Id)
		end)
	end
end

local function buildAnomalyUI(parent)
	anomalyFrame = makeFrame(parent, "AnomalyModal", UDim2.new(0.5, -240, 0.5, -180), UDim2.new(0, 480, 0, 360), Color3.fromRGB(15, 18, 26), 0.95, 15)
	anomalyFrame.Visible = false

	makeLabel(anomalyFrame, "Title", "REGISTRO DE ANOMALIA DE TURNO", UDim2.new(0, 20, 0, 16), UDim2.new(1, -40, 0, 24), 16, Config.Colors.Yellow, "center", 16)
	makeLabel(anomalyFrame, "Desc", "Elige qué manifestación paranormal encontraste en el supermercado:", UDim2.new(0, 20, 0, 44), UDim2.new(1, -40, 0, 20), 12, Config.Colors.White, "center", 16)

	local closeBtn = makeButton(anomalyFrame, "CloseAnomaly", "X", UDim2.new(1, -40, 0, 12), UDim2.new(0, 28, 0, 28), 17)
	closeBtn.BackgroundColor3 = Color3.fromRGB(80, 25, 25)
	closeBtn.MouseButton1Click:Connect(function()
		anomalyFrame.Visible = false
	end)

	local yOff = 75
	for _, ano in Config.Anomalies do
		local btn = makeButton(anomalyFrame, "AnoBtn_" .. ano.Id, ano.Name .. " — " .. ano.Description, UDim2.new(0, 20, 0, yOff), UDim2.new(1, -40, 0, 48), 16)
		btn.TextSize = 12
		btn.MouseButton1Click:Connect(function()
			Remotes.SubmitAnomalyGuess:FireServer(ano.Id)
			anomalyFrame.Visible = false
		end)
		yOff += 56
	end
end

local function buildResultsUI(parent)
	resultsFrame = makeFrame(parent, "ResultsModal", UDim2.new(0.5, -260, 0.5, -190), UDim2.new(0, 520, 0, 380), Color3.fromRGB(12, 15, 22), 0.95, 20)
	resultsFrame.Visible = false

	makeLabel(resultsFrame, "Title", "REPORTE DE TURNO", UDim2.new(0, 20, 0, 20), UDim2.new(1, -40, 0, 30), 22, Config.Colors.Yellow, "center", 21)

	resultsText = makeLabel(resultsFrame, "Content", "", UDim2.new(0, 30, 0, 60), UDim2.new(1, -60, 1, -120), 14, Config.Colors.White, "left", 21)

	local closeBtn = makeButton(resultsFrame, "CloseResults", "CONTINUAR", UDim2.new(0.5, -90, 1, -50), UDim2.new(0, 180, 0, 38), 22)
	closeBtn.BackgroundColor3 = Color3.fromRGB(35, 75, 45)
	closeBtn.MouseButton1Click:Connect(function()
		resultsFrame.Visible = false
	end)
end

function UIController.Start(playerGui)
	ui = Instance.new("ScreenGui")
	ui.Name = "NightShiftUI"
	ui.ResetOnSpawn = false
	ui.Parent = playerGui

	buildHUD(ui)
	buildCCTVUI(ui)
	buildDownedUI(ui)
	buildShopUI(ui)
	buildAnomalyUI(ui)
	buildResultsUI(ui)

	shopButton.MouseButton1Click:Connect(function()
		shopFrame.Visible = not shopFrame.Visible
	end)

	UserInputService.InputBegan:Connect(function(input, gp)
		if gp then
			return
		end
		if input.KeyCode == Enum.KeyCode.B then
			shopFrame.Visible = not shopFrame.Visible
		elseif input.KeyCode == Enum.KeyCode.Escape and cctvFrame.Visible then
			cctvFrame.Visible = false
			local CameraController = require(script.Parent.CameraController)
			CameraController.ExitCCTV()
		end
	end)

	Remotes.ClockChanged.OnClientEvent:Connect(function(text)
		if clockLabel then
			clockLabel.Text = text
		end
	end)

	Remotes.RoundStateChanged.OnClientEvent:Connect(function(phase)
		if phaseLabel then
			phaseLabel.Text = PHASE_NAMES[phase] or phase
		end
		if startButton then
			startButton.Visible = (phase == "Waiting")
		end
		if phase == "Results" then
			if cctvFrame then
				cctvFrame.Visible = false
			end
		end
	end)

	Remotes.PowerChanged.OnClientEvent:Connect(function(p)
		powerValue = p
		if powerLabel then
			powerLabel.Text = string.format("ENERGIA: %d%%", math.floor(p))
		end
		if powerFill then
			powerFill.Size = UDim2.new(math.clamp(p / 100, 0, 1), 0, 1, 0)
			powerFill.BackgroundColor3 = if p > 50 then Config.Colors.Green elseif p > 25 then Config.Colors.Yellow else Config.Colors.NeonRed
		end
	end)

	Remotes.TaskProgressChanged.OnClientEvent:Connect(function(list)
		if not taskList then
			return
		end
		for _, child in taskList:GetChildren() do
			if child:IsA("GuiObject") then
				child:Destroy()
			end
		end
		local completedCount = 0
		for _, item in list do
			local line = makeFrame(taskList, "TaskLine", UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0, 24), Color3.fromRGB(20, 24, 34), 0.6, 4)
			local col = if item.Completed then Config.Colors.Green else Config.Colors.White
			local check = if item.Completed then "✓ " else "○ "
			makeLabel(line, "Text", check .. item.Name, UDim2.new(0, 6, 0, 2), UDim2.new(1, -12, 1, -4), 12, col, "left", 5)
			if item.Completed then
				completedCount += 1
			end
		end
		taskList.CanvasSize = UDim2.new(0, 0, 0, #list * 30)
	end)

	Remotes.ShowMessage.OnClientEvent:Connect(function(text)
		if messageLabel then
			messageLabel.Text = text
			tween(messageLabel, 0.3, { TextTransparency = 0 })
			task.delay(3.5, function()
				if messageLabel.Text == text then
					tween(messageLabel, 0.5, { TextTransparency = 1 })
				end
			end)
		end
	end)

	Remotes.MonsterWarning.OnClientEvent:Connect(function(kind)
		if warningLabel then
			warningLabel.Text = if kind == "appear" then "¡CLIENTE CERO HA ENTRADO AL SUPERMERCADO!" else "¡EL MONSTRUO TE HA VISTO!"
			warningLabel.TextTransparency = 0
			task.delay(4, function()
				tween(warningLabel, 0.8, { TextTransparency = 1 })
			end)
		end
	end)

	Remotes.SetCCTVCamera.OnClientEvent:Connect(function(camIndex)
		if cctvFrame then
			cctvFrame.Visible = true
			local camDef = Config.CCTV[camIndex]
			if camDef and cctvCamLabel then
				cctvCamLabel.Text = camDef.Name
			end
		end
	end)

	Remotes.ShowResults.OnClientEvent:Connect(function(data)
		if resultsFrame and resultsText then
			resultsFrame.Visible = true
			local stateStr = if data.Survived then "¡ESCAPASTE CON VIDA!" else "ATRAPADO EN EL TURNO"
			local anoStr = if data.AnomalyCorrect then "¡Correcta! (+60 monedas)" else "No deducida"

			resultsText.Text = string.format(
				"Estado: %s\n\nTareas completadas: %d / %d\nAnomalia del turno: %s (%s)\n\n🪙 Monedas obtenidas: +%d\n⭐ XP obtenida: +%d",
				stateStr,
				data.TasksCompleted or 0,
				data.TotalTasks or 5,
				data.AnomalyName or "Ninguna",
				anoStr,
				data.Coins or 0,
				data.XP or 0
			)
		end
	end)

	-- Render loop para actualizar HUD reactivo
	RunService.RenderStepped:Connect(function(dt)
		if staminaBar then
			staminaBar.Size = UDim2.new(math.clamp(ClientState.Stamina / ClientState.MaxStamina, 0, 1), 0, 1, 0)
			staminaBar.BackgroundColor3 = if ClientState.Sprinting then Config.Colors.Yellow else Config.Colors.Green
		end

		if batteryBar then
			batteryBar.Size = UDim2.new(math.clamp(ClientState.Battery / ClientState.MaxBattery, 0, 1), 0, 1, 0)
			if batteryLabel then
				batteryLabel.Text = string.format("LINTERNA: %d%% [F]", math.floor(ClientState.Battery))
			end
		end

		if downedFrame then
			downedFrame.Visible = ClientState.Downed
			if ClientState.Downed and bleedoutBar then
				local frac = math.clamp(ClientState.BleedoutRemaining / Config.Player.Downed.BleedoutTime, 0, 1)
				bleedoutBar.Size = UDim2.new(frac, 0, 1, 0)
			end
		end

		if coinLabel and ClientState.PlayerData then
			coinLabel.Text = "🪙 Monedas: " .. tostring(ClientState.PlayerData.Coins or 0)
		end
		if levelLabel and ClientState.PlayerData then
			levelLabel.Text = "⭐ Nivel: " .. tostring(ClientState.PlayerData.Level or 1)
		end
	end)
end

return UIController
