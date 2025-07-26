-- Auto reinject
local scriptURL = "https://raw.githubusercontent.com/bypassv5/SabChecker/refs/heads/main/script.lua"
if queue_on_teleport then
    queue_on_teleport("loadstring(game:HttpGet('"..scriptURL.."'))()")
end

local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local LocalPlayer = game:GetService("Players").LocalPlayer

local webhookURL = "https://webhook.lewisakura.moe/api/webhooks/1398765862835458110/yPDUCwGfwrDAkV9y1LwKDbawWTUWLE6810Y2Dh732FnKG1UiIgLnsMrSAJ3-opRkAAHu"

local function sendWebhook()
    local success, err = pcall(function()
        HttpService:PostAsync(webhookURL, HttpService:JSONEncode({ content = "JobId: "..game.JobId }), Enum.HttpContentType.ApplicationJson)
    end)
    if success then print("[Webhook] OK") else warn("[Webhook] Err:", err) end
end

local teleportInProgress = false
local function attemptTeleport(serverId)
    if teleportInProgress then return false end
    teleportInProgress = true
    local ok, err = pcall(function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, serverId, LocalPlayer)
    end)
    teleportInProgress = false
    return ok, err
end

-- Fetch only one page, quickly filter
local function fetchQuickServers()
    local ok, res = pcall(function()
        return HttpService:JSONDecode(game:HttpGet(
            ("https://games.roblox.com/v1/games/%s/servers/Public?sortOrder=Asc&limit=100"):format(game.PlaceId)
        ))
    end)
    if not (ok and res and res.data) then
        warn("[Fetch] Failed first page")
        return {}
    end

    local list = {}
    for _, s in ipairs(res.data) do
        if s.playing == 1 and s.id ~= game.JobId then
            table.insert(list, s.id)
        end
    end
    return list
end

-- Main fast hop logic
local function fastHop()
    local list = fetchQuickServers()
    print("[List] Found", #list, "one-player servers")
    if #list >= 30 then
        local sid = list[30]
        print("[Hop] Teleporting to", sid)
        local ok, err = attemptTeleport(sid)
        if ok then
            print("[Hop] Started")
            return
        else
            warn("[Teleport] Err:", err)
            if tostring(err):find("GameFull") then
                print("[Retry] Full server, retrying quick")
                task.wait(0.5)
                fastHop()
            else
                TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
            end
        end
    else
        warn("[Hop] Less than 30 servers, rejoining")
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
    end
end

TeleportService.TeleportInitFailed:Connect(function()
    warn("[Event] TeleportInitFailed, rejoining")
    TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
end)

sendWebhook()
task.wait(0.2)
fastHop()
