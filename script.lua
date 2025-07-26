-- ✅ Config
local webhookURL = "https://discord.com/api/webhooks/1398761075041894441/EbR_r1MMQvUQbdz25Hy1GkNYdi0P0Bzkk4Psul8ZQulEBS0X5F2M618Dpak8FP-4NpJy"

local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- ✅ Send Discord webhook
local function sendWebhook()
    local data = {
        embeds = {{
            title = "🛰️ Server Hop Triggered",
            description = "Hopping to a low-pop server (≤5 players).",
            color = 0x00FFFF,
            fields = {
                { name = "Username", value = LocalPlayer.Name, inline = true },
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

-- ✅ Server hop to server with ≤5 players
local function serverHopToSmall()
    local cursor = ""
    local tried = 0

    while tried < 10 do
        local url = ("https://games.roblox.com/v1/games/%s/servers/Public?sortOrder=Asc&limit=100%s"):format(
            game.PlaceId,
            cursor ~= "" and ("&cursor=" .. cursor) or ""
        )

        local success, result = pcall(function()
            return HttpService:JSONDecode(game:HttpGet(url))
        end)

        if success and result and result.data then
            for _, server in ipairs(result.data) do
                if server.playing <= 5 and server.id ~= game.JobId then
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

        tried += 1
        task.wait(1)
    end

    warn("No suitable low-population server found.")
end

-- ✅ Run it
sendWebhook()
task.wait(2)
serverHopToSmall()
