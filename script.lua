-- Auto reinject URL (keep same)
local scriptURL = "https://raw.githubusercontent.com/bypassv5/SabChecker/refs/heads/main/script.lua"
if queue_on_teleport then
    queue_on_teleport("loadstring(game:HttpGet('"..scriptURL.."'))()")
end

local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local webhookURL = "https://webhook.lewisakura.moe/api/webhooks/1398765862835458110/yPDUCwGfwrDAkV9y1LwKDbawWTUWLE6810Y2Dh732FnKG1UiIgLnsMrSAJ3-opRkAAHu"

local function sendWebhook()
    local msg = { content = "Script active. JobId: "..game.JobId }
    local ok, err = pcall(function()
        HttpService:PostAsync(webhookURL, HttpService:JSONEncode(msg), Enum.HttpContentType.ApplicationJson)
    end)
    if ok then print("[Webhook] Sent.") else warn("[Webhook] Failed:", err) end
end

-- Returns table of server IDs with exactly 1 player
local function fetchOnePlayerServers()
    local servers, cursor = {}, ""
    for _ = 1, 10 do
        local ok, res = pcall(function()
            return HttpService:JSONDecode(game:HttpGet(
                "https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100".. (cursor ~= "" and "&cursor="..cursor or "")
            ))
        end)
        if not (ok and res and res.data) then
            warn("[ServerFetch] error")
            break
        end
        for _, s in ipairs(res.data) do
            if s.playing == 1 and s.id ~= game.JobId then
                table.insert(servers, s.id)
            end
        end
        if not res.nextPageCursor then break end
        cursor = res.nextPageCursor
        task.wait(0.5)
    end
    return servers
end

local teleportInProgress = false

local function attemptTeleportTo(serverId)
    if teleportInProgress then return false end
    teleportInProgress = true
    local ok, err = pcall(function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, serverId, LocalPlayer)
    end)
    teleportInProgress = false
    return ok, err
end

-- Retry loop
local function mainHopLoop()
    while true do
        local serverList = fetchOnePlayerServers()
        print("[Servers] found:", #serverList)
        if #serverList >= 30 then
            local sid = serverList[30]
            print("[Attempt] teleport to", sid)
            local ok, err = attemptTeleportTo(sid)
            if ok then
                print("[Teleport] initiated.")
                return
            else
                
                warn("[Teleport] error:", err)
                if tostring(err):find("GameFull") then
                    print("Server full, retrying...")
                    task.wait(2)
                else
                    TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
                    return
                end
            end
        else
            warn("Not enough servers, waiting...")
            task.wait(3)
        end
    end
end

TeleportService.TeleportInitFailed:Connect(function()
    warn("[TeleportEvent] failed! Rejoining current.")
    TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
end)

sendWebhook()
task.wait(1.5)
mainHopLoop()
