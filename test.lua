-- // Auto-inject on teleport
local scriptURL = "https://raw.githubusercontent.com/bypassv5/SabChecker/refs/heads/main/script.lua"
if queue_on_teleport then
    queue_on_teleport("loadstring(game:HttpGet('"..scriptURL.."'))()")
end

-- // Services
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

-- // Clipboard (Key Copy)
if setclipboard then
    setclipboard("https://link-center.net/1375465/YAC3CDe8HuMX")
end

-- // Rayfield UI Load
loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

-- // Key Verification
local requiredKey = "8MWlRfVTijY88Lk43h59ofCnC0iuxhoc"
local userKey = ""
local webhookURL = ""

local modelsToCheck = {
	"Cocofanto Elephanto", "Girafa Celestre", "Tralalero Tralala", "Odin Din Din Dun",
	"Tigroligre Frutonni", "Espresso Signora", "Orcalero Orcala", "La Vacca Saturno Saturnita",
	"Los Tralaleritos", "Graipuss Medussi", "La Grande Combinasion", "Matteo"
}

local pingModels = {
	["La Vacca Saturno Saturnita"] = true,
	["Graipuss Medussi"] = true,
	["La Grande Combinasion"] = true,
	["Los Tralaleritos"] = true
}

local running, teleporting = false, false

-- // Functions
local function scanModels()
	local found = {}
	for _, name in ipairs(modelsToCheck) do
		local obj = workspace:FindFirstChild(name)
		if obj then
			print("[FOUND]", name)
			table.insert(found, name)
		else
			print("[MISSING]", name)
		end
	end
	return found
end

local function sendWebhook(foundModels)
	local req = (syn and syn.request) or http_request or (fluxus and fluxus.request)
	if not req then warn("No HTTP request function found."); return end

	local pingEveryone = false
	for _, name in ipairs(foundModels) do
		if pingModels[name] then
			pingEveryone = true
			break
		end
	end

	local msg = (pingEveryone and "@everyone\n" or "") ..
		"✅ Script injected. JobId: `" .. game.JobId .. "`"

	if #foundModels > 0 then
		msg ..= "\nFound models:\n- " .. table.concat(foundModels, "\n- ")
	else
		msg ..= "\nNo models found."
	end

	msg ..= "\n\nJoin: `game:GetService(\"TeleportService\"):TeleportToPlaceInstance(" ..
		game.PlaceId .. ', "' .. game.JobId .. '")`'

	pcall(function()
		req({
			Url = webhookURL,
			Method = "POST",
			Headers = {["Content-Type"] = "application/json"},
			Body = HttpService:JSONEncode({content = msg})
		})
	end)

	if pingEveryone then
		print("[HALT] Rare model found. Stopping auto-hop.")
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
	if teleporting then return end
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
		local found = scanModels()
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

-- // Teleport Fallback
TeleportService.TeleportInitFailed:Connect(function()
	print("[Teleport Failed] Rejoining current server...")
	TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
end)

-- // Q key toggle
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.Q then
		running = not running
		print(running and "[RESUMED]" or "[PAUSED]")
		if running then
			coroutine.wrap(hopLoop)()
		end
	end
end)

-- // Rayfield Setup
local Window = Rayfield:CreateWindow({
	Name = "Sab Checker",
	LoadingTitle = "Sab Checker Loader",
	LoadingSubtitle = "with Rayfield UI",
	ConfigurationSaving = {
		Enabled = true,
		FolderName = "SabChecker",
		FileName = "SabSettings"
	}
})

Rayfield:Notify({
	Title = "Key Link Copied!",
	Content = "Paste in browser, complete steps, use the provided key.",
	Duration = 8
})

local Tab = Window:CreateTab("Main", 4483362458)

Tab:CreateInput({
	Name = "Enter Your Key",
	PlaceholderText = "Paste your key here...",
	RemoveTextAfterFocusLost = false,
	Callback = function(input)
		userKey = input
	end
})

Tab:CreateInput({
	Name = "Your Webhook",
	PlaceholderText = "Paste your Discord Webhook",
	RemoveTextAfterFocusLost = false,
	Callback = function(input)
		webhookURL = input
	end
})

Tab:CreateButton({
	Name = "Start Script",
	Callback = function()
		if userKey ~= requiredKey then
			Rayfield:Notify({
				Title = "Key Invalid",
				Content = "The key you entered is incorrect.",
				Duration = 6
			})
			return
		end
		if webhookURL == "" then
			Rayfield:Notify({
				Title = "Webhook Missing",
				Content = "You must enter a Discord webhook.",
				Duration = 6
			})
			return
		end
		Rayfield:Notify({
			Title = "Script Started",
			Content = "Now scanning and hopping...",
			Duration = 6
		})
		running = true
		coroutine.wrap(hopLoop)()
	end
})
