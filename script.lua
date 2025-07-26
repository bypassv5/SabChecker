-- ✅ CONFIG
local webhookURL = "https://discord.com/api/webhooks/1398761075041894441/EbR_r1MMQvUQbdz25Hy1GkNYdi0P0Bzkk4Psul8ZQulEBS0X5F2M618Dpak8FP-4NpJy" -- Replace this!
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- ✅ Example check (replace this logic)
local checkPassed = false
if game.Workspace:FindFirstChild("MyRareItem") then
    checkPassed = true
end

-- ✅ Send Discord webhook
local data = {
    content = nil,
    embeds = {{
        title = "Server Hop Report",
        description = "Check passed: **" .. tostring(checkPassed) .. "**",
        color = checkPassed and 0x00FF00 or 0xFF0000,
        fields = {
            { name = "User", value = LocalPlayer.Name, inline = true },
            { name = "PlaceId", value = tostring(game.PlaceId), inline = true },
            { name = "JobId", value = game.JobId, inline = false },
        },
        footer = {
            text = os.date("Time: %Y-%m-%d %H:%M:%S"),
        }
    }}
}

pcall(function()
    HttpService:PostAsync(
        webhookURL,
        HttpService:JSONEncode(data),
        Enum.HttpContentType.ApplicationJson
    )
end)

-- ✅ Delay to allow webhook to send
task.wait(2)

-- ✅ Server Hop Logic
local function hop()
    local success, result = pcall(function()
        return HttpService:JSONDecode(game:HttpGet(
            "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
        ))
    end)

    if not success or not result.data then return end

    for _, server in ipairs(result.data) do
        if server.id ~= game.JobId and server.playing < server.maxPlayers then
            TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, LocalPlayer)
            break
        end
    end
end

hop()
