local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = {}

local names = {
	-- Ronda y Flujo
	"RequestInteract",
	"RequestStartRound",
	"RoundStateChanged",
	"ClockChanged",
	"PowerChanged",
	"TaskProgressChanged",
	"PlayerStateChanged",
	"MonsterWarning",
	"ShowResults",
	"ShowMessage",
	
	-- Fase 3: Cámaras CCTV
	"SetCCTVCamera",
	"ExitCCTVCamera",
	
	-- Fase 4: Downed & Revive
	"PlayerDowned",
	"PlayerRevived",
	"RequestRevive",
	
	-- Fase 5: Anomalías
	"SubmitAnomalyGuess",
	"AnomalyRevealed",
	
	-- Fase 6: Tienda & DataStore
	"RequestBuyItem",
	"RequestEquipSkin",
	"PlayerDataUpdated",
}

local function ensureFolder()
	local folder = ReplicatedStorage:FindFirstChild("Remotes")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "Remotes"
		folder.Parent = ReplicatedStorage
	end
	return folder
end

local folder = ensureFolder()

for _, name in names do
	local remote = folder:FindFirstChild(name)
	if not remote then
		remote = Instance.new("RemoteEvent")
		remote.Name = name
		remote.Parent = folder
	end
	Remotes[name] = remote
end

return Remotes
