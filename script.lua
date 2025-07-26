-- Auto reinject on teleport
local scriptURL = "https://raw.githubusercontent.com/bypassv5/SabChecker/refs/heads/main/script.lua"
if queue_on_teleport then
    queue_on_teleport("loadstring(game:HttpGet('"..scriptURL.."'))()")
end

local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local webhookURL = "https://discord.com/api/webhooks/1398765862835458110/yPDUCwGfwrDAkV9y1LwKDbawWTUWLE6810Y2Dh732FnKG1UiIgLnsMrSAJ3-opRkAAHu"

-- Models to check
local modelsToCheck = {
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
	"La Grande Combinasion"
}

-- Safe webhook sender (uses syn.request/http_request/fluxus.request)
local function sendSafeWebhook()
	local requestFunc = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request)
	if not requestFunc then
		warn("[Webhook] This executor does not support custom HTTP requests.")
		return
	end

	-- Check which models exist in workspace
	local foundModels = {}
	for _, name in ipairs(modelsToCheck) do
		if workspace:FindFirstChild(name) then
			table.insert(foundModels, name)
		end
	end

	local contentMsg = "✅ Script injected. JobId: `" .. game.JobId .. "`"
	if #foundModels > 0 then
		contentMsg = contentMsg .. "\nFound models:\n- " .. table.concat(foundModels, "\n- ")
	else
		contentMsg = contentMsg .. "\nNo specified models found in workspace."
	end

	local payload = {
		["content"] = contentMsg
	}

	local response = requestFunc({
		Url = webhookURL,
		Method = "POST",
		Headers = {
			["Content-Type"] = "application/json"
		},
		Body = HttpService:JSONEncode(payload)
	})

	if response and response.StatusCode == 204 then
		print("[Webhook] Sent successfully.")
	else
		warn("[Webhook] Failed to send:", response and response.StatusCode, response and response.Body)
	end
end

local teleporting = false
local function tryTeleportTo(serverId)
	if teleporting then return end
	teleporting = true
	local success, err = pcall(function()
		TeleportService:TeleportToPlaceInstance(game.PlaceId, serverId, LocalPlayer)
	end)
	teleporting = false
	return success, err
end

local function getOnePlayerServers()
	local success, data = pcall(function()
		return HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"))
	end)

	if not success or not data or not data.data then
		warn("[Server] Failed to fetch.")
		return {}
	end

	local servers = {}
	for _, server in ipairs(data.data) do
		if server.playing == 1 and server.id ~= game.JobId then
			table.insert(servers, server.id)
		end
	end
	return servers
end

local function startServerHop()
	while true do
		local servers = getOnePlayerServers()
		if #servers >= 30 then
			local serverId = servers[30]
			print("[Hop] Trying to teleport to:", serverId)
			local ok, err = tryTeleportTo(serverId)
			if ok then
				print("[Hop] Teleport initiated.")
				break
			else
				warn("[Teleport] Failed:", err)
				if tostring(err):lower():find("full") then
					task.wait(0.5)
				else
					TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
					break
				end
			end
		else
			warn("[Hop] Not enough 1-player servers. Retrying in 1s...")
			task.wait(1)
		end
	end
end

TeleportService.TeleportInitFailed:Connect(function()
	warn("[TeleportEvent] Failed to teleport, retrying...")
	TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
end)

-- Print models found locally as well
for _, name in ipairs(modelsToCheck) do
	if workspace:FindFirstChild(name) then
		print("[Found] Model in workspace: " .. name)
	else
		print("[Missing] Model NOT found: " .. name)
	end
end

sendSafeWebhook()
task.wait(0.2)
startServerHop()
