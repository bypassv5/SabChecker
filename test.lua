-- Auto-reinject on teleport
local scriptURL = "https://raw.githubusercontent.com/bypassv5/SabChecker/refs/heads/main/script.lua"
if queue_on_teleport then
    queue_on_teleport("loadstring(game:HttpGet('"..scriptURL.."'))()")
end

local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

local webhookURL = "https://discord.com/api/webhooks/1398765862835458110/yPDUCwGfwrDAkV9y1LwKDbawWTUWLE6810Y2Dh732FnKG1UiIgLnsMrSAJ3-opRkAAHu"

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
    "La Grande Combinasion",
    "Matteo"
}

local pingModels = {
    ["La Vacca Saturno Saturnita"] = true,
    ["Graipuss Medussi"] = true,
    ["La Grande Combinasion"] = true,
    ["Los Tralaleritos"] = true
}

local running = false
local teleporting = false

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "Brainrot Finder",
    LoadingTitle = "Loading Brainrot Finder...",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "BrainrotFinder",
        FileName = "BrainrotFinderConfig",
    },
    KeySystem = true,
    KeySettings = {
        Title = "Brainrot Finder Key System",
        Subtitle = "Enter your key below",
        Note = "Get your key from https://link-center.net/1375465/YAC3CDe8HuMX\nKey copied to clipboard!",
        FileName = "BrainrotKey",
        SaveKey = true,
        Key = {"8MWlRfVTijY88Lk43h59ofCnC0iuxhoc"}
    }
})

-- Copy key link to clipboard immediately on script load
pcall(function()
    setclipboard("https://link-center.net/1375465/YAC3CDe8HuMX")
end)

local Tab = Window:CreateTab("Main")

-- Webhook input
local webhookInput = Tab:CreateInput({
    Name = "Webhook URL (for normal pings)",
    PlaceholderText = "Enter your Discord webhook URL",
    RemoveTextAfterFocusLost = false,
    OnChanged = function(text)
        webhookURL = text
    end
})

-- Dropdown for models to detect (multi-select)
local selectedModels = modelsToCheck -- default: all selected

local detectDropdown = Tab:CreateDropdown({
    Name = "Select models to detect",
    MultiSelect = true,
    Options = modelsToCheck,
    CurrentOptions = modelsToCheck,
    Flag = "DetectDropdown",
    Callback = function(selection)
        selectedModels = selection
    end
})

-- Toggle stop hopping when rare found
local stopOnRare = false
local stopToggle = Tab:CreateToggle({
    Name = "Stop hopping when rare found",
    CurrentValue = false,
    Flag = "StopOnRareToggle",
    Callback = function(value)
        stopOnRare = value
    end
})

-- Toggle hopping start/stop
local hoppingToggle = Tab:CreateToggle({
    Name = "Start Hopping (Toggle with Q)",
    CurrentValue = false,
    Flag = "HoppingToggle",
    Callback = function(value)
        running = value
        if running then
            task.spawn(hopLoop)
        end
    end
})

-- Scans workspace for selected models
local function scanModels()
    local found = {}
    for _, name in ipairs(selectedModels) do
        if workspace:FindFirstChild(name) then
            table.insert(found, name)
        end
    end
    return found
end

-- Send webhook message
local function sendWebhook(foundModels)
    local req = (syn and syn.request) or http_request or (fluxus and fluxus.request)
    if not req then
        warn("No HTTP request function found.")
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
        "✅ Script injected. JobId: `" .. game.JobId .. "`\n"

    if #foundModels > 0 then
        msg = msg .. "Found models:\n- " .. table.concat(foundModels, "\n- ")
    else
        msg = msg .. "No models found."
    end

    msg = msg .. "\n\nJoin: `game:GetService(\"TeleportService\"):TeleportToPlaceInstance(" ..
        game.PlaceId .. ', "' .. game.JobId .. '")`'

    pcall(function()
        req({
            Url = webhookURL,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode({content = msg})
        })
    end)

    if pingEveryone and stopOnRare then
        print("[HALT] Rare model found. Stopping hopping.")
        running = false
        hoppingToggle:Set(false)
    end
end

-- Get servers with exactly one player (to hop)
local function getOnePlayerServers()
    local ok, res = pcall(function()
        return HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"))
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

-- Teleport to server
local function tryTeleport(serverId)
    if teleporting then return false end
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

-- Main hopping loop
function hopLoop()
    while running do
        local found = scanModels()
        sendWebhook(found)
        if not running then break end
        task.wait(0.5)

        local servers = getOnePlayerServers()
        if #servers >= 30 then
            local serverId = servers[30]
            if tryTeleport(serverId) then
                print("[HOP] Teleporting to server", serverId)
                break
            else
                task.wait(1)
            end
        else
            task.wait(1)
        end
    end
end

-- Teleport failure fallback
TeleportService.TeleportInitFailed:Connect(function()
    print("[Teleport Failed] Rejoining current server...")
    TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
end)

-- Toggle hopping with Q key
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.Q then
        running = not running
        hoppingToggle:Set(running)
        print(running and "[RESUMED]" or "[PAUSED]")
        if running then
            task.spawn(hopLoop)
        end
    end
end)

Rayfield:Notify({
    Title = "Brainrot Finder",
    Content = "Loaded! Press Q to toggle hopping. Configure webhook and models to detect.",
    Duration = 5,
    Image = 4483362458
})

-- Load Rayfield config
Rayfield:LoadConfiguration()
