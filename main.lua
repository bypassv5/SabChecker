-- 🔁 Auto-Reinject Loader
local url = "https://raw.githubusercontent.com/bypassv5/SabChecker/refs/heads/main/script.lua"

if queue_on_teleport then
    queue_on_teleport("loadstring(game:HttpGet('" .. url .. "'))()")
end

-- Run immediately
loadstring(game:HttpGet(url))()
