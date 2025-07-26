-- 🔁 Auto-reinject support
local scriptURL = "https://raw.githubusercontent.com/bypassv5/SabChecker/refs/heads/main/script.lua"
if queue_on_teleport then
    queue_on_teleport("loadstring(game:HttpGet('" .. scriptURL .. "'))()")
end

-- ✅ CONFIG
local webhookURL = "https://discord.com/api/webhooks/1398761075041894441/EbR_r1MMQvUQbdz25Hy1GkNYdi0P0Bzkk4Psul8ZQulEBS0X5F2M618Dpak8FP-4NpJy"

local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- ✅ Send webhook
local function sendWebhook()
    local data = {
        embeds = {{
            title = "📡 Ascending Server Hop Started",
            description = "Looking for a server with **1 player**.",
            color = 0x00FFAA,
            fields = {
                { name = "User", value = LocalPlayer.Name, inline = true },
                { name = "PlaceId", value = tostring(game.PlaceId), inline = true },
                { name = "JobId", value = game.JobId, inline = false },
            },
            footer = {
                text = "Time: " .. os.date("%Y-%m-%d %H:%M:%S"),
            }
        }}
    }

    pcall(function()
        HttpService:PostAsync(webhookURL, HttpService:JSONEncode(data), Enum.HttpContentType.ApplicationJson)
    end)
end

-- ✅ Server hop to ascending, 1-player servers
local function hopTo1PlayerServer()
    local cursor = ""
    local maxTries = 10
    local attempt = 0

    while attempt < maxTries do
        local url = string.format(
            "https://games.roblox.com/v1/games/%s/servers/Public?sortOrder=Asc&limit=100%s",
            tostring(game.PlaceId),
            cursor ~= "" and ("&cursor=" .. cursor) or ""
        )

        local success, result = pcall(function()
            return HttpService:JSONDecode(game:HttpGet(url))
        end)

        if success and result and result.data then
            for _, server in ipairs(result.data) do
                if server.playing == 1 and server.id ~= game.JobId then
                    TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, LocalPlayer)
                    return
                end
            end

            if result.nextPageCursor then
                cursor = result.nextPageCursor
            else
                break
            end
        else
            warn("Failed to fetch server list")
            break
        end

        attempt += 1
        task.wait(1)
    end

    warn("❌ No server with 1 player found.")
end

-- ✅ Execute steps
sendWebhook()
task.wait(2)
hopTo1PlayerServer()
