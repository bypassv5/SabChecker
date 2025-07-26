-- ✅ Auto reinject for when player teleports
local scriptURL = "https://raw.githubusercontent.com/bypassv5/SabChecker/refs/heads/main/script.lua"
if queue_on_teleport then
    queue_on_teleport("loadstring(game:HttpGet('"..scriptURL.."'))()")
end

-- 🧠 Services
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- ✅ Your real Discord webhook
local webhookURL = "https://discord.com/api/webhooks/1398765862835458110/yPDUCwGfwrDAkV9y1LwKDbawWTUWLE6810Y2Dh732FnKG1UiIgLnsMrSAJ3-opRkAAHu"

-- ✅ Safe webhook send (executor only — not HttpService)
local function sendSafeWebhook()
	local requestFunc = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request)
	if not requestFunc then
		warn("[Webhook] This executor does not support custom HTTP requests.")
		return
	end

	local payload = {
		["content"] = "✅ Script injected. JobId: `" .. game.JobId .. "`"
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

-- 🔁 Tries teleporting
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

-- 🔍 Gets a list of one-player servers (only 1 page for speed)
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

-- 🚀 Main teleport loop
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
				if tostring(err):find("full") then
					task.wait(0.5)
				else
					-- Something else failed, just rejoin current
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

-- 🔄 On teleport fail, rejoin same server
TeleportService.TeleportInitFailed:Connect(function()
	warn("[TeleportEvent] Failed to teleport, retrying...")
	TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
end)

-- ✅ Go
sendSafeWebhook()
task.wait(0.2)
startServerHop()
