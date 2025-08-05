-- ✅ Auto-reinject on teleport
local scriptURL = "https://raw.githubusercontent.com/bypassv5/SabChecker/main/script.lua"
if queue_on_teleport then
    queue_on_teleport("loadstring(game:HttpGet('" .. scriptURL .. "'))()")
end

-- ✅ Services
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

-- ✅ Webhook URL
local webhookURL = "https://discord.com/api/webhooks/1398765862835458110/yPDUCwGfwrDAkV9y1LwKDbawWTUWLE6810Y2Dh732FnKG1UiIgLnsMrSAJ3-opRkAAHu"

-- ✅ Models to scan
local modelsToCheck = {
	"Cocofanto Elephanto", "Girafa Celestre", "Tralalero Tralala", "Odin Din Din Dun",
	"Tigroligre Frutonni", "Espresso Signora", "Orcalero Orcala", "La Vacca Saturno Saturnita",
	"Los Tralaleritos", "Graipuss Medussi", "La Grande Combinasion", "Matteo",
	"Statutino Libertino", "Chimpanzini Spiderini", "Las Tralaleritas", "Las Vaquitas Saturnitas",
}

-- ✅ Models that trigger @everyone ping and stop hopping
local pingModels = {
	["La Vacca Saturno Saturnita"] = true, ["Graipuss Medussi"] = true,
	["La Grande Combinasion"] = true, ["Los Tralaleritos"] = true,
	["Statutino Libertino"] = true, ["Chimpanzini Spiderini"] = true,
	["Las Tralaleritas"] = true, ["Las Vaquitas Saturnitas"] = true,
}

-- ✅ State
local running = true
local teleporting = false

-- ✅ Scan workspace for model names
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

-- ✅ Send Discord webhook
local function sendWebhook(foundModels)
	local req = syn and syn.request or http_request or (fluxus and fluxus.request)
	if not req then
		warn("No supported HTTP request function found.")
		return
	end

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

	msg ..= "\n\nJoin:\n```lua\nTeleportService:TeleportToPlaceInstance(" ..
		game.PlaceId .. ', "' .. game.JobId .. '")\n```'

	pcall(function()
		req({
			Url = webhookURL,
			Method = "POST",
			Headers = {["Content-Type"] = "application/json"},
			Body = HttpService:JSONEncode({content = msg}),
		})
	end)

	if pingEveryone then
		print("[STOP] Rare model found. Halting server hop.")
		running = false
	end
end

-- ✅ Get list of other public servers
local function getOtherServers()
	local success, result = pcall(function()
		local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
		return HttpService:JSONDecode(game:HttpGet(url))
	end)
	if not success or not result or not result.data then
		return {}
	end

	local servers = {}
	for _, server in ipairs(result.data) do
		if server.id ~= game.JobId then
			table.insert(servers, server.id)
		end
	end
	return servers
end

-- ✅ Attempt teleport
local function tryTeleport(serverId)
	if teleporting then return false end
	teleporting = true

	local ok, err = pcall(function()
		TeleportService:TeleportToPlaceInstance(game.PlaceId, serverId, LocalPlayer)
	end)

	if not ok then
		warn("[TELEPORT ERROR]", err)
	end

	return ok
end

-- ✅ Hopping loop
local function hopLoop()
	while running do
		local found = scanModels()
		sendWebhook(found)

		if not running then break end
		task.wait(0.5)

		local servers = getOtherServers()
		if #servers > 0 then
			local targetServer = servers[math.random(1, #servers)]
			print("[HOP] Attempting to hop to", targetServer)
			if tryTeleport(targetServer) then
				break
			else
				task.wait(2)
			end
		else
			warn("[HOP] No other servers found.")
			task.wait(5)
		end
	end
end

-- ✅ Fallback if teleport fails
TeleportService.TeleportInitFailed:Connect(function()
	warn("[Teleport Failed] Rejoining current server...")
	TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
end)

-- ✅ Toggle hopping with Q
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.Q then
		running = not running
		print(running and "[RESUMED]" or "[PAUSED]")
		if running then
			task.spawn(hopLoop)
		end
	end
end)

-- ✅ Start immediately
task.spawn(hopLoop)
