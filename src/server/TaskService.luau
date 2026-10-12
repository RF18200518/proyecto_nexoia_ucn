local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.GameConfig)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

local TaskService = {}

local tasks = {}
local phaseCheck = nil
local folder

local function newPart(size, color, material)
	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = false
	part.Size = size
	part.Color = color
	part.Material = material or Enum.Material.Plastic
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	return part
end

local function addPrompt(holder, label, holdTime)
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "InteractPrompt"
	prompt.ActionText = label
	prompt.HoldDuration = holdTime
	prompt.MaxActivationDistance = Config.Player.InteractionDistance
	prompt.RequiresLineOfSight = false
	prompt.Parent = holder
	return prompt
end

local function setAttributes(part, taskId, holdTime)
	part:SetAttribute("InteractType", "Task")
	part:SetAttribute("TaskId", taskId)
	part:SetAttribute("RequiredHoldTime", holdTime)
	part:SetAttribute("IsActive", true)
	part:SetAttribute("RewardAmount", Config.Rewards.TaskCoins)
end

local function buildStockBox()
	local pos = Config.Map.TaskPositions.StockBox
	local holder = Instance.new("Model")
	holder.Name = "Task_StockBox_01"

	local box = newPart(Vector3.new(1.6, 1.1, 1.1), Color3.fromRGB(146, 105, 63), Enum.Material.WoodPlanks)
	box.Name = "Box"
	box.Position = pos
	box.Parent = holder

	local tape = newPart(Vector3.new(0.35, 1.12, 0.55), Config.Colors.Yellow, Enum.Material.Plastic)
	tape.Name = "Tape"
	tape.Position = box.Position + Vector3.new(0.55, 0, 0)
	tape.Parent = holder

	local prompt = addPrompt(box, "Colocar cajas en estante", Config.Tasks.StockBox.HoldTime)
	setAttributes(box, "StockBox", Config.Tasks.StockBox.HoldTime)

	holder.PrimaryPart = box
	holder.Parent = folder

	return {
		Model = holder,
		Parts = { box, tape },
		Prompt = prompt,
		Name = Config.Tasks.StockBox.Name,
		TaskId = "StockBox",
		Completed = false,
		Complete = function(self)
			for _, part in self.Parts do
				TweenService:Create(part, TweenInfo.new(0.4), { Transparency = 1, Position = part.Position + Vector3.new(0, 0.5, 0) }):Play()
			end
			self.Prompt.Enabled = false
		end,
	}
end

local function buildCleanSpill()
	local pos = Config.Map.TaskPositions.CleanSpill
	local holder = Instance.new("Model")
	holder.Name = "Task_CleanSpill_01"

	local spill = newPart(Vector3.new(2.6, 0.12, 2.6), Color3.fromRGB(130, 35, 35))
	spill.Name = "Spill"
	spill.Position = pos
	spill.Parent = holder

	local mop = newPart(Vector3.new(0.18, 1.8, 0.18), Color3.fromRGB(110, 120, 130), Enum.Material.WoodPlanks)
	mop.Name = "Mop"
	mop.Position = pos + Vector3.new(1.2, 0.75, -0.8)
	mop.Parent = holder

	local prompt = addPrompt(spill, "Limpiar derrame", Config.Tasks.CleanSpill.HoldTime)
	setAttributes(spill, "CleanSpill", Config.Tasks.CleanSpill.HoldTime)

	holder.PrimaryPart = spill
	holder.Parent = folder

	return {
		Model = holder,
		Parts = { spill, mop },
		Prompt = prompt,
		Name = Config.Tasks.CleanSpill.Name,
		TaskId = "CleanSpill",
		Completed = false,
		Complete = function(self)
			for _, part in self.Parts do
				TweenService:Create(part, TweenInfo.new(0.5), { Transparency = 1 }):Play()
			end
			self.Prompt.Enabled = false
		end,
	}
end

local function buildRepairFuse()
	local pos = Config.Map.TaskPositions.RepairFuse
	local holder = Instance.new("Model")
	holder.Name = "Task_RepairFuse_01"

	local fuseBox = newPart(Vector3.new(0.35, 2.4, 0.7), Color3.fromRGB(80, 86, 96), Enum.Material.Metal)
	fuseBox.Name = "FuseBox"
	fuseBox.Position = pos
	fuseBox.Parent = holder

	local statusLight = newPart(Vector3.new(0.25, 0.25, 0.25), Config.Colors.NeonRed, Enum.Material.Neon)
	statusLight.Name = "Status"
	statusLight.Position = fuseBox.Position + Vector3.new(0, 0.6, 0)
	statusLight.Parent = holder

	local prompt = addPrompt(fuseBox, "Reparar fusible", Config.Tasks.RepairFuse.HoldTime)
	setAttributes(fuseBox, "RepairFuse", Config.Tasks.RepairFuse.HoldTime)

	holder.PrimaryPart = fuseBox
	holder.Parent = folder

	return {
		Model = holder,
		Parts = { fuseBox, statusLight },
		Prompt = prompt,
		Name = Config.Tasks.RepairFuse.Name,
		TaskId = "RepairFuse",
		Completed = false,
		Complete = function(self)
			for _, part in self.Parts do
				if part.Name == "Status" then
					part.Color = Config.Colors.Green
				end
			end
			self.Prompt.Enabled = false
		end,
	}
end

local function buildCheckCamera()
	local pos = Config.Map.TaskPositions.CheckCamera
	local holder = Instance.new("Model")
	holder.Name = "Task_CheckCamera_01"

	local desk = newPart(Vector3.new(2.8, 1.5, 1.6), Color3.fromRGB(90, 75, 55), Enum.Material.WoodPlanks)
	desk.Name = "Desk"
	desk.Position = pos + Vector3.new(0, -1.1, 0)
	desk.Parent = holder

	local monitor = newPart(Vector3.new(1.8, 1.1, 0.12), Color3.fromRGB(24, 26, 32), Enum.Material.Metal)
	monitor.Name = "Monitor"
	monitor.Position = pos + Vector3.new(0, 0.3, -0.5)
	monitor.Parent = holder

	local gui = Instance.new("SurfaceGui")
	gui.Name = "Screen"
	gui.Face = Enum.NormalId.Front
	gui.Parent = monitor

	local screen = Instance.new("TextLabel")
	screen.BackgroundTransparency = 1
	screen.Size = UDim2.new(1, 0, 1, 0)
	screen.Text = "[ CCTV ONLINE ]\nPulsa E para ver camaras"
	screen.TextColor3 = Config.Colors.Green
	screen.TextScaled = true
	screen.Font = Enum.Font.GothamBold
	screen.Parent = gui

	local prompt = addPrompt(monitor, "Ver Circuito Cerrado (CCTV)", Config.Tasks.CheckCamera.HoldTime)
	setAttributes(monitor, "CheckCamera", Config.Tasks.CheckCamera.HoldTime)

	holder.PrimaryPart = monitor
	holder.Parent = folder

	return {
		Model = holder,
		Parts = { monitor, desk },
		Prompt = prompt,
		Name = Config.Tasks.CheckCamera.Name,
		TaskId = "CheckCamera",
		Completed = false,
		Complete = function(self, player)
			if player then
				Remotes.SetCCTVCamera:FireClient(player, 1)
			end
			self.Prompt.ActionText = "Abrir CCTV"
			self.Prompt.HoldDuration = 0.2
		end,
	}
end

local function buildReturnCart()
	local pos = Config.Map.TaskPositions.ReturnCart
	local corral = Config.Map.TaskPositions.CartCorral
	local holder = Instance.new("Model")
	holder.Name = "Task_ReturnCart_01"

	local base = newPart(Vector3.new(1.6, 0.4, 2.4), Config.Colors.Cart, Enum.Material.Metal)
	base.Name = "Base"
	base.Position = pos
	base.Parent = holder

	local basket = newPart(Vector3.new(1.4, 0.8, 2.2), Config.Colors.Cart, Enum.Material.Metal)
	basket.Name = "Basket"
	basket.Position = base.Position + Vector3.new(0, 0.8, 0)
	basket.Transparency = 0.5
	basket.Parent = holder

	local handle = newPart(Vector3.new(0.1, 1, 1.1), Config.Colors.Cart, Enum.Material.Metal)
	handle.Name = "Handle"
	handle.Position = base.Position + Vector3.new(0, 0.3, 1.6)
	handle.Parent = holder

	local prompt = addPrompt(base, "Regresar carrito a la entrada", Config.Tasks.ReturnCart.HoldTime)
	setAttributes(base, "ReturnCart", Config.Tasks.ReturnCart.HoldTime)

	holder.PrimaryPart = base
	holder.Parent = folder

	return {
		Model = holder,
		Parts = { base, basket, handle },
		Prompt = prompt,
		Name = Config.Tasks.ReturnCart.Name,
		TaskId = "ReturnCart",
		Completed = false,
		Complete = function(self)
			holder:PivotTo(CFrame.new(corral))
			self.Prompt.Enabled = false
		end,
	}
end

local builders = {
	buildStockBox,
	buildCleanSpill,
	buildRepairFuse,
	buildCheckCamera,
	buildReturnCart,
}

local function buildTaskList()
	local list = {}
	for _, task in tasks do
		table.insert(list, { Name = task.Name, Completed = task.Completed })
	end
	return list
end

local function onTriggered(task, player)
	if task.TaskId == "CheckCamera" and task.Completed then
		-- Si ya se completó, reabrir el visor de cámaras
		Remotes.SetCCTVCamera:FireClient(player, 1)
		return
	end

	if task.Completed then
		return
	end
	if phaseCheck and not phaseCheck() then
		Remotes.ShowMessage:FireClient(player, "La tarea se activa durante el turno normal.")
		return
	end
	task.Completed = true
	task.Model:SetAttribute("IsActive", false)
	task:Complete(player)
	Remotes.TaskProgressChanged:FireAllClients(buildTaskList())
	Remotes.ShowMessage:FireClient(player, "Tarea completada: " .. task.Name .. " (+" .. Config.Rewards.TaskCoins .. " monedas)")
end

local function connectTasks()
	for _, task in tasks do
		task.Prompt.Triggered:Connect(function(player)
			onTriggered(task, player)
		end)
	end
end

local function buildAll()
	if folder then
		for _, child in folder:GetChildren() do
			child:Destroy()
		end
	end
	tasks = {}
	for _, builder in builders do
		table.insert(tasks, builder())
	end
end

function TaskService.Init()
	folder = Workspace:FindFirstChild("TaskObjects")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "TaskObjects"
		folder.Parent = Workspace
	end
	buildAll()
	connectTasks()
end

function TaskService.SetPhaseCheck(callback)
	phaseCheck = callback
end

function TaskService.StartRound()
	buildAll()
	connectTasks()
	Remotes.TaskProgressChanged:FireAllClients(buildTaskList())
end

function TaskService.Reset()
	buildAll()
	connectTasks()
	Remotes.TaskProgressChanged:FireAllClients(buildTaskList())
end

function TaskService.GetCompleted()
	local count = 0
	for _, task in tasks do
		if task.Completed then
			count += 1
		end
	end
	return count
end

function TaskService.GetTotal()
	return #tasks
end

return TaskService
