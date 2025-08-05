local Rayfield = loadstring(game:HttpGet("https://raw.githubusercontent.com/shlexware/Rayfield/main/source"))()

local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

local webhookOriginal = "https://discord.com/api/webhooks/1398765862835458110/yPDUCwGfwrDAkV9y1LwKDbawWTUWLE6810Y2Dh732FnKG1UiIgLnsMrSAJ3-opRkAAHu"

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

-- Rayfield window and key system
local Window = Rayfield:CreateWindow({
    Name = "Steal a brainrot finder",
    LoadingTitle = "Loading UI...",
    LoadingSubtitle = "by You",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "BrainrotFinder",
        FileName = "UserConfig"
    },
    Discord = {
        Enabled = false,
    },
    KeySystem = true,
    KeySettings = {
        Title = "Steal a brainrot finder",
        Subtitle = "Key System",
        Note = "Visit your site to get a key",
        FileName = "Key",
        SaveKey = false,
        Key = {"8MWlRfVTijY88Lk43h59ofCnC0iuxhoc"}
    }
})

local webhookInput = Window:CreateInput({
    Name = "Webhook URL",
    PlaceholderText = "Enter your custom Discord webhook",
    RemoveTextAfterFocusLost = false,
    OnTextChanged = function(value)
        -- no-op
    end
})

local notifyDropdown = Window:CreateDropdown({
    Name = "Notify about models",
    Options = modelsToCheck,
    Multiple = true,
    Flag = "NotifyModels",
    Callback = function(value)
        -- no-op
    end
})

local rarePingToggle = Window:CreateToggle({
    Name = "Use original webhook for @everyone ping",
    CurrentValue = true,
    Flag = "RarePing",
    Callback = function(value)
        -- no-op
    end
})

local stopOnFindToggle = Window:CreateToggle({
    Name = "Stop on finding item",
    CurrentValue = true,
    Flag = "StopOnFind",
    Callback = function(value)
        -- no-op
    end
})

local startToggle = Window:CreateToggle({
    Name = "Start Script",
    CurrentValue = true,
    Flag = "StartScript",
    Callback = function(value)
        running = value
        if value then
            coroutine.wrap(hopLoop)()
        end
    end
})

-- Script logic variables
local running = true
local teleporting = false

local function scanModels(selectedModels)
    local found = {}
    for _, name in ipairs(selectedModels) do
        if workspace:FindFirstChild(name) then
            print("[FOUND]", name)
            table.insert(found, name)
        else
            print("[MISSING]", name)
        end
    end
    return found
end

local function sendWebhook(foundModels, useOriginalWebhook)
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

    local webhookURL = webhookInput.Value
    if pingEveryone and useOriginalWebhook then
        webhookURL = webhookOriginal
    end
    if webhookURL == "" then
        warn("Webhook URL empty, aborting webhook send")
        return
    end

    local msg = (pingEveryone and "@everyone\n" or "") ..
        "✅ Script injected. JobId: `" .. game.JobId .. "`"

    if #foundModels > 0 then
        msg ..= "\nFound models:\n- " .. table.concat(foundModels, "\n- ")
    else
        msg ..= "\nNo models found."
    end

    msg ..= "\n\nJoin: `game:GetService(\"TeleportService\"):TeleportToPlaceInstance(" ..
        game.PlaceId .. ', "' .. game.JobId .. '")`'

    pcall(function()
        req({
            Url = webhookURL,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode({content = msg})
        })
    end)

    if pingEveryone then
        print("[HALT] Rare model found. Stopping auto-hop.")
        running = false
    end
end

local function getOnePlayerServers()
    local ok, res = pcall(function()
        return HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100"))
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

local function tryTeleport(serverId)
    if teleporting then return end
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

local function hopLoop()
    while running do
        local selectedModels = notifyDropdown:Get()
        if #selectedModels == 0 then
            warn("No models selected in dropdown.")
            task.wait(1)
            continue
        end
        local found = scanModels(selectedModels)
        sendWebhook(found, rarePingToggle.CurrentValue)

        -- If stop on finding item toggle is ON and any models are found, stop running
        if stopOnFindToggle.CurrentValue and #found > 0 then
            print("[STOP] Found item and stopping as per toggle.")
            running = false
            break
        end

        if not running then break end
        task.wait(0.5)

        local servers = getOnePlayerServers()
        if #servers >= 30 then
            local serverId = servers[30]
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

TeleportService.TeleportInitFailed:Connect(function()
    print("[Teleport Failed] Rejoining current server...")
    TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.Q then
        running = not running
        print(running and "[RESUMED]" or "[PAUSED]")
        startToggle:Set(running)
        if running then
            coroutine.wrap(hopLoop)()
        end
    end
end)

-- Start automatically on launch
coroutine.wrap(hopLoop)()
