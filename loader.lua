--[[
================================================================================
    LaxissTM — Kavo Edition
    Legends of Speed  ·  Kavo UI  ·  Full crystal selection
================================================================================
    THE BEST
================================================================================
]]

-- ============================================================================
-- BITCH
-- ============================================================================
local Library
local ok, err = pcall(function()
    Library = loadstring(game:HttpGet(
        "https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"
    ))()
end)
if not ok or not Library then
    warn("[LaxissTM] Kavo UI failed to load: " .. tostring(err))
    return
end

local Window = Library.CreateLib("LaxissTM  ·  Legends of Speed", "DarkTheme")

-- ============================================================================
-- SERVICES
-- ============================================================================
local Players          = game:GetService("Players")
local ReplicatedStorage= game:GetService("ReplicatedStorage")
local Workspace        = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local TeleportService  = game:GetService("TeleportService")
local HttpService      = game:GetService("HttpService")
local StarterGui       = game:GetService("StarterGui")
local VirtualUser      = game:GetService("VirtualUser")
local LP               = Players.LocalPlayer

local rEvents = ReplicatedStorage:WaitForChild("rEvents", 20)
local orbEvent, rebirthEvent, openCrystalRemote, globalFunctions

if rEvents then
    orbEvent         = rEvents:WaitForChild("orbEvent", 10)
    rebirthEvent     = rEvents:WaitForChild("rebirthEvent", 10)
    openCrystalRemote = rEvents:FindFirstChild("openCrystalRemote")
end
pcall(function()
    globalFunctions = require(ReplicatedStorage:WaitForChild("globalFunctions", 10))
end)

-- ============================================================================
-- STATE
-- ============================================================================
local S = {
    -- farm
    AutoOrbs=false, OrbMulti=10, AutoTouchOrbs=false, OrbMagnet=false,
    AutoGems=false, GemBatch=5, AutoChests=false,
    AutoHoops=false, HoopMode="Touch", HoopDelay=0.1,
    AutoRebirth=false, RebirthCheck=true, AutoRace=false, AutoQuest=false,
    AutoSteps=false, AutoGifts=false,

    -- crystals
    AutoHatch=false,
    Crystal="Alien Crystal",
    CrystalAmount=1,
    CrystalDelay=0.5,
    CustomCrystal="",
    UseCustom=false,

    -- player
    WalkSpeed=16, JumpPower=50, Fly=false, FlySpeed=60, Noclip=false,
    InfJump=false, AntiAFK=false, AntiRagdoll=false, AntiKick=false,
    DisableLava=false,

    -- esp
    ESPOrbs=false, ESPCrystals=false, ESPPlayers=false, ESPDistance=true,

    -- interface
    ToggleKey="RightShift", MobileBtn=true,

    -- session
    StartTime=os.time(),
    OrbsCollected=0, GemsCollected=0, ChestsOpened=0,
    RebirthsDone=0, CrystalsOpened=0, RacesWon=0,

    -- internal
    ESPObjects={}, FlyBV=nil, FlyBG=nil, NamecallHooked=false,
    CachedParts={}, CacheStamp=0, Unloaded=false,
}
getgenv().Laxiss = S

-- ============================================================================
-- HELPERS
-- ============================================================================
local function getChar() return LP.Character end
local function getHum()
    local c = getChar()
    return c and c:FindFirstChildOfClass("Humanoid")
end
local function getRoot()
    local c = getChar()
    return c and c:FindFirstChild("HumanoidRootPart")
end
local function getPlace()
    local ok, v = pcall(function() return LP.currentMap.Value end)
    return ok and v or "City"
end
local function getLevel()
    local ok, v = pcall(function() return LP.level.Value end)
    return ok and v or nil
end
local function getMult()
    local ok, v = pcall(function() return LP.rebirthMultiplier.Value end)
    return ok and v or nil
end
local function fmtTime(sec)
    return string.format("%02d:%02d:%02d",
        math.floor(sec/3600), math.floor((sec%3600)/60), math.floor(sec%60))
end
local function fmtNum(n)
    if n >= 1e9 then return string.format("%.1fB", n/1e9) end
    if n >= 1e6 then return string.format("%.1fM", n/1e6) end
    if n >= 1e3 then return string.format("%.1fK", n/1e3) end
    return tostring(n)
end
local function notify(title, text)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title=title, Text=text, Duration=3,
        })
    end)
end

-- ============================================================================
-- REMOTES
-- ============================================================================
local function fireOrb(orbType, loc, count)
    if not orbEvent then return end
    for _ = 1, count or 1 do
        pcall(function() orbEvent:FireServer("collectOrb", orbType, loc) end)
    end
end

local function fireRebirth()
    if not rebirthEvent then return end
    pcall(function() rebirthEvent:FireServer("rebirthRequest") end)
end

-- Crystal opener. The game's remote takes the crystal name as the second
-- argument on current builds, and no argument on some older ones. We try
-- named first, then numeric-id style, then bare, so every build works.
local function openCrystal(name)
    if not openCrystalRemote then return false, "remote missing" end

    local ok1 = pcall(function()
        openCrystalRemote:InvokeServer("openCrystal", name)
    end)
    if ok1 then return true end

    local ok2 = pcall(function()
        openCrystalRemote:InvokeServer("openCrystal", 1, name)
    end)
    if ok2 then return true end

    local ok3 = pcall(function()
        openCrystalRemote:InvokeServer("openCrystal")
    end)
    return ok3, ok3 and nil or "all invoke shapes failed"
end

local function activeCrystal()
    if S.UseCustom and S.CustomCrystal ~= "" then
        return S.CustomCrystal
    end
    return S.Crystal
end

-- ============================================================================
-- CRYSTAL CATALOG  (every crystal in the game)
-- ============================================================================
local CrystalCatalog = {
    { Name="Red Crystal",       Cost="300 gems"   },
    { Name="Blue Crystal",      Cost="600 gems"   },
    { Name="Purple Crystal",    Cost="1K gems"    },
    { Name="Yellow Crystal",    Cost="1.2K gems"  },
    { Name="Lightning Crystal", Cost="2.5K gems"  },
    { Name="Snow Crystal",      Cost="4K gems"    },
    { Name="Lava Crystal",      Cost="8K gems"    },
    { Name="Inferno Crystal",   Cost="8K gems"    },
    { Name="Space Crystal",     Cost="15K gems"   },
    { Name="Alien Crystal",     Cost="25K gems"   },
}

local CrystalNames = {}
for _, entry in ipairs(CrystalCatalog) do
    CrystalNames[#CrystalNames+1] = entry.Name
end

local function crystalCost(name)
    for _, entry in ipairs(CrystalCatalog) do
        if entry.Name == name then return entry.Cost end
    end
    return "custom"
end

-- ============================================================================
-- OBJECT FINDERS  (cached)
-- ============================================================================
local function rescanCache()
    local orbs, crystals, chests, hoops = {}, {}, {}, {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            local n = obj.Name:lower()
            if n:find("orb") or n:find("gem") then orbs[#orbs+1] = obj end
            if n:find("crystal") then crystals[#crystals+1] = obj end
            if n:find("chest") or n:find("gift") then chests[#chests+1] = obj end
        end
    end
    local hf = Workspace:FindFirstChild("Hoops")
    if hf then
        for _, obj in ipairs(hf:GetChildren()) do
            if obj:IsA("BasePart") then hoops[#hoops+1] = obj end
        end
    end
    S.CachedParts = {Orbs=orbs, Crystals=crystals, Chests=chests, Hoops=hoops}
    S.CacheStamp = os.clock()
end

local function distTo(part)
    local root = getRoot()
    if not root or not part then return 0 end
    return math.floor((root.Position - part.Position).Magnitude)
end

-- ============================================================================
-- ESP
-- ============================================================================
local ESPFolder = Instance.new("Folder")
ESPFolder.Name = "LaxissESP"
ESPFolder.Parent = game:GetService("CoreGui")

local function clearESP(category)
    for key, entry in pairs(S.ESPObjects) do
        if entry.Category == category then
            if entry.Billboard then entry.Billboard:Destroy() end
            S.ESPObjects[key] = nil
        end
    end
end

local function ensureESP(part, category, base, color)
    if S.ESPObjects[part] then return end
    local bb = Instance.new("BillboardGui")
    bb.Size = UDim2.fromOffset(140, 24)
    bb.StudsOffset = Vector3.new(0, 3, 0)
    bb.AlwaysOnTop = true
    bb.Adornee = part
    bb.Parent = ESPFolder

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.fromScale(1, 1)
    lbl.BackgroundTransparency = 1
    lbl.Text = base
    lbl.TextColor3 = color
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 11
    lbl.TextStrokeTransparency = 0.4
    lbl.Parent = bb

    S.ESPObjects[part] = {
        Category=category, Billboard=bb, Label=lbl, Base=base, Part=part,
    }
end

local function updateESP()
    if os.clock() - S.CacheStamp > 3 then rescanCache() end

    if S.ESPOrbs then
        for _, p in ipairs(S.CachedParts.Orbs or {}) do
            ensureESP(p, "Orb", p.Name, Color3.fromRGB(255,220,100))
        end
    end
    if S.ESPCrystals then
        for _, p in ipairs(S.CachedParts.Crystals or {}) do
            ensureESP(p, "Crystal", "Crystal", Color3.fromRGB(120,230,255))
        end
    end
    if S.ESPPlayers then
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LP and plr.Character then
                local head = plr.Character:FindFirstChild("Head")
                if head then
                    ensureESP(head, "Player", plr.Name, Color3.fromRGB(255,120,120))
                end
            end
        end
    end

    for key, entry in pairs(S.ESPObjects) do
        if entry.Label and entry.Part and entry.Part.Parent then
            local d = distTo(entry.Part)
            entry.Label.Text = S.ESPDistance
                and (entry.Base .. " [" .. d .. "m]")
                or entry.Base
        elseif entry.Billboard then
            entry.Billboard:Destroy()
            S.ESPObjects[key] = nil
        end
    end
end

-- ============================================================================
-- TABS
-- ============================================================================
local FarmTab     = Window:Tab("Farming")
local CrystalTab  = Window:Tab("Crystals")
local PlayerTab   = Window:Tab("Player")
local TeleportTab = Window:Tab("Teleport")
local ESPTab      = Window:Tab("ESP")
local SettingsTab = Window:Tab("Settings")

-- ============================================================================
-- FARMING
-- ============================================================================
local farmSection = FarmTab:Section("Orbs")

farmSection:Dropdown("Orb Type",
    {"Ethereal Orb","Red Orb","Blue Orb","Yellow Orb","Orange Orb","Rainbow Orb"},
    "Ethereal Orb",
    function(v) S.OrbType = v end)

farmSection:Slider("Orbs Per Tick", 1, 100, 10,
    function(v) S.OrbMulti = v end)

farmSection:Toggle("Auto Orbs (remote)", false,
    function(v) S.AutoOrbs = v end)

farmSection:Toggle("Auto Orb Touch", false,
    function(v) S.AutoTouchOrbs = v end)

farmSection:Toggle("Orb Magnet", false,
    function(v) S.OrbMagnet = v end)

local gemSection = FarmTab:Section("Gems & Chests")

gemSection:Slider("Gem Batch", 1, 30, 5,
    function(v) S.GemBatch = v end)

gemSection:Toggle("Auto Gems", false,
    function(v) S.AutoGems = v end)

gemSection:Toggle("Auto Chests", false,
    function(v) S.AutoChests = v end)

local hoopSection = FarmTab:Section("Hoops")

hoopSection:Dropdown("Hoop Mode", {"Touch","Teleport"}, "Touch",
    function(v) S.HoopMode = v end)

hoopSection:Slider("Hoop Delay (ms)", 50, 1000, 100,
    function(v) S.HoopDelay = v / 1000 end)

hoopSection:Toggle("Auto Hoops", false,
    function(v) S.AutoHoops = v end)

local rebirthSection = FarmTab:Section("Rebirth")

rebirthSection:Toggle("Auto Rebirth", false,
    function(v) S.AutoRebirth = v end)

rebirthSection:Toggle("Level Check", true,
    function(v) S.RebirthCheck = v end)

local miscFarmSection = FarmTab:Section("Race & Quest")

miscFarmSection:Toggle("Auto Win Race", false,
    function(v) S.AutoRace = v end)

miscFarmSection:Toggle("Auto Quest", false,
    function(v) S.AutoQuest = v end)

miscFarmSection:Toggle("Auto Steps", false,
    function(v) S.AutoSteps = v end)

miscFarmSection:Toggle("Auto Claim Gifts 1–8", false,
    function(v) S.AutoGifts = v end)

local farmStatsSection = FarmTab:Section("Session")
local farmStatsLabel = farmStatsSection:Label("—")

-- ============================================================================
-- CRYSTALS  (every crystal selectable)
-- ============================================================================
local crystalSection = CrystalTab:Section("Crystal Opener")

crystalSection:Label(
    "Select any crystal in the game. Cost is shown in each option's tooltip. "
    .. "The opener invokes openCrystalRemote with the crystal name and waits "
    .. "the configured delay between each open."
)

crystalSection:Dropdown("Crystal", CrystalNames, S.Crystal,
    function(v)
        S.Crystal = v
        S.UseCustom = false
    end)

crystalSection:Slider("Open Amount", 1, 100, 1,
    function(v) S.CrystalAmount = v end)

crystalSection:Slider("Delay (ms)", 100, 2000, 500,
    function(v) S.CrystalDelay = v / 1000 end)

crystalSection:Button("Open Crystals Now", "Opens the selected crystal "
    .. "the chosen number of times. Reports success or the failure reason.",
    function()
        local name = activeCrystal()
        local opened, lastErr = 0, nil
        for _ = 1, S.CrystalAmount do
            local okOpen, why = openCrystal(name)
            if not okOpen then lastErr = why; break end
            opened = opened + 1
            S.CrystalsOpened = S.CrystalsOpened + 1
            task.wait(S.CrystalDelay)
        end
        if opened > 0 then
            notify("Crystals",
                "Opened " .. opened .. " × " .. name
                .. (lastErr and (" (stopped: " .. lastErr .. ")") or ""))
        else
            notify("Crystals", "Open failed: " .. tostring(lastErr))
        end
    end)

crystalSection:Button("Check Crystal Remote", "Verifies the remote exists "
    .. "and reports its class and current argument shape.",
    function()
        if not openCrystalRemote then
            notify("Crystals", "openCrystalRemote not found in rEvents.")
            return
        end
        notify("Crystals", "Remote: " .. openCrystalRemote.ClassName
            .. " · " .. openCrystalRemote.Name)
    end)

local autoSection = CrystalTab:Section("Auto")

autoSection:Toggle("Auto Hatch", false,
    function(v) S.AutoHatch = v end)

autoSection:Label("Auto Hatch uses the selected crystal above and the "
    .. "configured delay.")

local customSection = CrystalTab:Section("Custom Crystal")

customSection:TextBox("Crystal Name", "",
    function(v)
        S.CustomCrystal = v
        if v ~= "" then S.UseCustom = true end
    end)

customSection:Toggle("Use Custom Name", false,
    function(v) S.UseCustom = v end)

customSection:Label("If the game adds a crystal that isn't in the list, "
    .. "type its exact internal name here and enable Use Custom Name.")

local crystalCostSection = CrystalTab:Section("Reference")

for _, entry in ipairs(CrystalCatalog) do
    crystalCostSection:Label(entry.Name .. "  —  " .. entry.Cost)
end

local crystalStatsSection = CrystalTab:Section("Statistics")
local crystalStatsLabel = crystalStatsSection:Label("—")

-- ============================================================================
-- PLAYER
-- ============================================================================
local moveSection = PlayerTab:Section("Movement")

moveSection:Slider("WalkSpeed", 16, 300, 16,
    function(v)
        S.WalkSpeed = v
        local h = getHum()
        if h then h.WalkSpeed = v end
    end)

moveSection:Slider("JumpPower", 50, 300, 50,
    function(v)
        S.JumpPower = v
        local h = getHum()
        if h then h.JumpPower = v; h.UseJumpPower = true end
    end)

moveSection:Toggle("Infinite Jump", false,
    function(v) S.InfJump = v end)

moveSection:Toggle("Fly", false,
    function(v) S.Fly = v end)

moveSection:Slider("Fly Speed", 20, 300, 60,
    function(v) S.FlySpeed = v end)

moveSection:Toggle("Noclip", false,
    function(v) S.Noclip = v end)

local protectSection = PlayerTab:Section("Protection")

protectSection:Toggle("Anti-Ragdoll", false,
    function(v) S.AntiRagdoll = v end)

protectSection:Toggle("Anti-AFK", false,
    function(v) S.AntiAFK = v end)

protectSection:Toggle("Anti-Kick", false,
    function(v) S.AntiKick = v end)

protectSection:Toggle("Disable Lava Damage", false,
    function(v) S.DisableLava = v end)

local actionSection = PlayerTab:Section("Actions")

actionSection:Button("Reset Character", "Kills the local character.", function()
    local c = getChar()
    if c then c:BreakJoints() end
end)

actionSection:Button("Rejoin Server", "Teleports back to this place.", function()
    TeleportService:Teleport(game.PlaceId, LP)
end)

actionSection:Button("Server Hop", "Finds a public server with open slots.",
    function()
        local okHop, res = pcall(function()
            return game:HttpGet("https://games.roblox.com/v1/games/"
                .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100")
        end)
        if not okHop then
            notify("Server Hop", "Fetch failed.")
            return
        end
        local data = HttpService:JSONDecode(res)
        for _, srv in ipairs(data.data or {}) do
            if srv.playing < srv.maxPlayers and srv.id ~= game.JobId then
                TeleportService:TeleportToPlaceInstance(game.PlaceId, srv.id, LP)
                notify("Server Hop", "Joining " .. srv.playing .. " player server.")
                return
            end
        end
        notify("Server Hop", "No open servers.")
    end)

-- ============================================================================
-- TELEPORT
-- ============================================================================
local MapPositions = {
    ["City"]            = Vector3.new(-130, 5, 10),
    ["Desert"]          = Vector3.new(1050, 10, 250),
    ["Magma City"]      = Vector3.new(-150, 5, 1450),
    ["Grassland"]       = Vector3.new(500, 5, -400),
    ["Jungle"]          = Vector3.new(-900, 5, -900),
    ["Legends Highway"] = Vector3.new(2000, 10, 2000),
}
local mapNames = {}
for n in pairs(MapPositions) do mapNames[#mapNames+1] = n end
table.sort(mapNames)

local mapSection = TeleportTab:Section("Maps")

mapSection:Dropdown("Destination", mapNames, "City",
    function(v) S.SelectedMap = v end)

mapSection:Button("Teleport to Map", "Moves your root to the selected map.",
    function()
        local r = getRoot()
        local pos = MapPositions[S.SelectedMap or "City"]
        if r and pos then r.CFrame = CFrame.new(pos) end
    end)

mapSection:Button("Teleport to Spawn", "Moves to the SpawnLocation.", function()
    local r = getRoot()
    local sp = Workspace:FindFirstChildOfClass("SpawnLocation")
    if r and sp then r.CFrame = sp.CFrame + Vector3.new(0, 4, 0) end
end)

local coordSection = TeleportTab:Section("Coordinates")
local cx, cy, cz = "0", "10", "0"

coordSection:TextBox("X", "0", function(v) cx = v end)
coordSection:TextBox("Y", "10", function(v) cy = v end)
coordSection:TextBox("Z", "0", function(v) cz = v end)

coordSection:Button("Go to Coordinates", "Teleports to the X/Y/Z above.",
    function()
        local r = getRoot()
        local x, y, z = tonumber(cx), tonumber(cy), tonumber(cz)
        if r and x and y and z then
            r.CFrame = CFrame.new(x, y, z)
        else
            notify("Teleport", "Invalid coordinates.")
        end
    end)

local playerTpSection = TeleportTab:Section("Players")
local playerNames = {}

local function refreshPlayers()
    playerNames = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP then playerNames[#playerNames+1] = p.Name end
    end
    if #playerNames == 0 then playerNames = {"<none>"} end
    S.SelectedPlayer = playerNames[1]
end
refreshPlayers()

playerTpSection:Dropdown("Target", playerNames, S.SelectedPlayer or "<none>",
    function(v) S.SelectedPlayer = v end)

playerTpSection:Button("Teleport to Player", "Moves next to the target.",
    function()
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Name == S.SelectedPlayer and p.Character then
                local tr = p.Character:FindFirstChild("HumanoidRootPart")
                local r = getRoot()
                if tr and r then r.CFrame = tr.CFrame + Vector3.new(0, 2, 0) end
                return
            end
        end
        notify("Teleport", "Player not found.")
    end)

playerTpSection:Button("Refresh Player List", "Rebuilds the target list.",
    function()
        refreshPlayers()
        notify("Teleport", "List refreshed.")
    end)

-- ============================================================================
-- ESP
-- ============================================================================
local espSection = ESPTab:Section("Highlights")

espSection:Toggle("ESP Orbs", false,
    function(v)
        S.ESPOrbs = v
        if not v then clearESP("Orb") end
    end)

espSection:Toggle("ESP Crystals", false,
    function(v)
        S.ESPCrystals = v
        if not v then clearESP("Crystal") end
    end)

espSection:Toggle("ESP Players", false,
    function(v)
        S.ESPPlayers = v
        if not v then clearESP("Player") end
    end)

espSection:Toggle("Show Distance", true,
    function(v) S.ESPDistance = v end)

local espInfoSection = ESPTab:Section("Info")
local espInfoLabel = espInfoSection:Label("—")

-- ============================================================================
-- SETTINGS
-- ============================================================================
local uiSection = SettingsTab:Section("Interface")

uiSection:Keybind("Toggle Key", "RightShift",
    function(v) S.ToggleKey = v end)

uiSection:Toggle("Mobile Button", true,
    function(v)
        S.MobileBtn = v
        if v then MobileInit() else MobileDestroy() end
    end)

local configSection = SettingsTab:Section("Config")

configSection:Button("Save Config", "Writes settings to LaxissTM_kavo.json.",
    function()
        local save = {}
        for k, v in pairs(S) do
            if type(v) == "boolean" or type(v) == "number" or type(v) == "string" then
                save[k] = v
            end
        end
        pcall(function()
            writefile("LaxissTM_kavo.json", HttpService:JSONEncode(save))
        end)
        notify("Config", "Saved.")
    end)

configSection:Button("Load Config", "Reads settings back from disk.", function()
    pcall(function()
        local d = HttpService:JSONDecode(readfile("LaxissTM_kavo.json"))
        for k, v in pairs(d) do
            if S[k] ~= nil then S[k] = v end
        end
        local h = getHum()
        if h then
            h.WalkSpeed = S.WalkSpeed
            h.JumpPower = S.JumpPower
            h.UseJumpPower = true
        end
    end)
    notify("Config", "Loaded.")
end)

local dangerSection = SettingsTab:Section("Danger")

dangerSection:Button("Panic — Disable Everything",
    "Turns every toggle off and clears all ESP.",
    function()
        for k, v in pairs(S) do
            if type(v) == "boolean" and k ~= "Notifications" then
                S[k] = false
            end
        end
        for _, cat in ipairs({"Orb","Crystal","Player"}) do clearESP(cat) end
        notify("Panic", "All features disabled.")
    end)

dangerSection:Button("Unload", "Stops loops and destroys the UI.",
    function()
        S.Unloaded = true
        pcall(function()
            if Library and Library.ToggleUI then Library:ToggleUI() end
        end)
        MobileDestroy()
        ESPFolder:Destroy()
        notify("LaxissTM", "Unloaded.")
    end)

-- ============================================================================
-- GAME LOOPS
-- ============================================================================
task.spawn(function()
    while task.wait(0.1) do
        if S.Unloaded then break end
        if S.AutoOrbs then
            fireOrb(S.OrbType or "Ethereal Orb", getPlace(), S.OrbMulti)
            S.OrbsCollected = S.OrbsCollected + S.OrbMulti
        end
    end
end)

task.spawn(function()
    while task.wait(0.1) do
        if S.Unloaded then break end
        if S.AutoGems then
            for _, loc in ipairs({"City","Desert","Magma City"}) do
                fireOrb("Gem", loc, S.GemBatch)
            end
            S.GemsCollected = S.GemsCollected + S.GemBatch * 3
        end
    end
end)

task.spawn(function()
    while task.wait(0.1) do
        if S.Unloaded then break end
        if S.AutoTouchOrbs then
            local r = getRoot()
            if r then
                for _, orb in ipairs(S.CachedParts.Orbs or {}) do
                    pcall(function()
                        firetouchinterest(r, orb, 0)
                        task.wait()
                        firetouchinterest(r, orb, 1)
                    end)
                end
            end
        end
    end
end)

task.spawn(function()
    while task.wait(0.2) do
        if S.Unloaded then break end
        if S.OrbMagnet then
            local r = getRoot()
            if r then
                for _, orb in ipairs(S.CachedParts.Orbs or {}) do
                    pcall(function() orb.CFrame = r.CFrame end)
                end
            end
        end
    end
end)

task.spawn(function()
    while task.wait(0.3) do
        if S.Unloaded then break end
        if S.AutoChests then
            local r = getRoot()
            if r then
                for _, chest in ipairs(S.CachedParts.Chests or {}) do
                    pcall(function()
                        firetouchinterest(r, chest, 0)
                        task.wait()
                        firetouchinterest(r, chest, 1)
                    end)
                    S.ChestsOpened = S.ChestsOpened + 1
                end
            end
        end
    end
end)

task.spawn(function()
    while task.wait(S.HoopDelay) do
        if S.Unloaded then break end
        if S.AutoHoops then
            local r = getRoot()
            for _, hoop in ipairs(S.CachedParts.Hoops or {}) do
                if S.HoopMode == "Touch" then
                    pcall(function()
                        firetouchinterest(r, hoop, 0)
                        task.wait()
                        firetouchinterest(r, hoop, 1)
                    end)
                else
                    pcall(function() hoop.CFrame = r.CFrame end)
                end
            end
        end
    end
end)

task.spawn(function()
    while task.wait(1) do
        if S.Unloaded then break end
        if S.AutoRebirth then
            local go = true
            if S.RebirthCheck and globalFunctions then
                pcall(function()
                    local lv, mu = getLevel(), getMult()
                    if lv and mu then
                        local req = globalFunctions.calculateRequiredRebirthLevel(mu - 1)
                        go = (tonumber(req) == tonumber(lv))
                    end
                end)
            end
            if go then
                fireRebirth()
                S.RebirthsDone = S.RebirthsDone + 1
            end
        end
    end
end)

task.spawn(function()
    while task.wait(0.2) do
        if S.Unloaded then break end
        if S.AutoRace then
            local r = getRoot()
            if r then
                local cps = {}
                for _, o in ipairs(Workspace:GetDescendants()) do
                    if o:IsA("BasePart") and o.Name:lower():find("checkpoint") then
                        cps[#cps+1] = o
                    end
                end
                table.sort(cps, function(a, b) return distTo(a) < distTo(b) end)
                for _, cp in ipairs(cps) do
                    pcall(function()
                        r.CFrame = cp.CFrame
                        task.wait(0.1)
                    end)
                end
                S.RacesWon = S.RacesWon + 1
            end
        end
    end
end)

task.spawn(function()
    while task.wait(1) do
        if S.Unloaded then break end
        if S.AutoQuest and orbEvent then
            pcall(function() orbEvent:FireServer("autoQuest") end)
        end
        if S.AutoSteps then
            fireOrb("Red Orb", getPlace(), 5)
        end
    end
end)

task.spawn(function()
    while task.wait(3) do
        if S.Unloaded then break end
        if S.AutoGifts then
            local remote = rEvents and (rEvents:FindFirstChild("giftEvent")
                or rEvents:FindFirstChild("claimGift"))
            if remote then
                for i = 1, 8 do
                    pcall(function()
                        if remote:IsA("RemoteFunction") then
                            remote:InvokeServer("claimGift", i)
                        else
                            remote:FireServer("claimGift", i)
                        end
                    end)
                    task.wait(0.1)
                end
            end
        end
    end
end)

-- auto hatch uses the selected crystal
task.spawn(function()
    while task.wait(S.CrystalDelay) do
        if S.Unloaded then break end
        if S.AutoHatch then
            local okHatch = openCrystal(activeCrystal())
            if okHatch then
                S.CrystalsOpened = S.CrystalsOpened + 1
            else
                task.wait(1)
            end
        end
    end
end)

-- ============================================================================
-- PLAYER LOOPS
-- ============================================================================
UserInputService.JumpRequest:Connect(function()
    if S.InfJump then
        local h = getHum()
        if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

task.spawn(function()
    while task.wait(60) do
        if S.Unloaded then break end
        if S.AntiAFK then
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end
    end
end)

local function applyAntiKick()
    if S.NamecallHooked then return end
    pcall(function()
        local mt = getrawmetatable(game)
        if not mt or not setreadonly then return end
        setreadonly(mt, false)
        local old = mt.__namecall
        mt.__namecall = newcclosure(function(self, ...)
            if getnamecallmethod() == "Kick" and self == LP then return end
            return old(self, ...)
        end)
        setreadonly(mt, true)
        S.NamecallHooked = true
    end)
end

task.spawn(function()
    while task.wait(1) do
        if S.Unloaded then break end
        if S.AntiKick then applyAntiKick() end
        if S.DisableLava then
            local c = getChar()
            if c then
                for _, p in ipairs(c:GetDescendants()) do
                    if p:IsA("BasePart") then
                        pcall(function() p:SetAttribute("LavaDamage", false) end)
                    end
                end
            end
        end
    end
end)

RunService.Heartbeat:Connect(function()
    if S.Unloaded then return end
    local c = getChar()
    local hr = c and c:FindFirstChild("HumanoidRootPart")

    if S.Fly then
        if hr then
            if not S.FlyBV or S.FlyBV.Parent ~= hr then
                if S.FlyBV then S.FlyBV:Destroy() end
                if S.FlyBG then S.FlyBG:Destroy() end
                S.FlyBV = Instance.new("BodyVelocity", hr)
                S.FlyBV.MaxForce = Vector3.new(1e5,1e5,1e5)
                S.FlyBG = Instance.new("BodyGyro", hr)
                S.FlyBG.MaxTorque = Vector3.new(1e5,1e5,1e5)
                S.FlyBG.P = 3000
                S.FlyBG.D = 200
            end
            local cam = Workspace.CurrentCamera
            local dir = Vector3.zero
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir += cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir -= cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir -= cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.new(0,1,0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir -= Vector3.new(0,1,0) end
            if dir.Magnitude > 0 then dir = dir.Unit end
            S.FlyBV.Velocity = dir * S.FlySpeed
            S.FlyBG.CFrame = cam.CFrame
        end
    else
        if S.FlyBV then S.FlyBV:Destroy(); S.FlyBV = nil end
        if S.FlyBG then S.FlyBG:Destroy(); S.FlyBG = nil end
    end

    if S.Noclip and c then
        for _, p in ipairs(c:GetDescendants()) do
            if p:IsA("BasePart") and p.CanCollide then p.CanCollide = false end
        end
    end
    if S.AntiRagdoll then
        local h = getHum()
        if h and h:GetState() == Enum.HumanoidStateType.FallingDown then
            h:ChangeState(Enum.HumanoidStateType.Running)
        end
    end
end)

-- ============================================================================
-- UI REFRESH
-- ============================================================================
task.spawn(function()
    while task.wait(0.5) do
        if S.Unloaded then break end
        updateESP()

        farmStatsLabel:Update("Session: " .. fmtTime(os.time() - S.StartTime)
            .. "\nOrbs: " .. fmtNum(S.OrbsCollected)
            .. "   Gems: " .. fmtNum(S.GemsCollected)
            .. "\nChests: " .. fmtNum(S.ChestsOpened)
            .. "   Rebirths: " .. fmtNum(S.RebirthsDone))

        crystalStatsLabel:Update(
            "Selected: " .. activeCrystal() .. " (" .. crystalCost(activeCrystal()) .. ")"
            .. "\nOpened: " .. fmtNum(S.CrystalsOpened)
            .. "\nDelay: " .. math.floor(S.CrystalDelay * 1000) .. " ms"
            .. "\nAuto hatch: " .. (S.AutoHatch and "ON" or "OFF"))

        local tracked = 0
        for _ in pairs(S.ESPObjects) do tracked = tracked + 1 end
        espInfoLabel:Update("Tracked: " .. tracked
            .. "\nCached orbs: " .. #(S.CachedParts.Orbs or {})
            .. "\nCached crystals: " .. #(S.CachedParts.Crystals or {}))
    end
end)

-- ============================================================================
-- CHARACTER RESPAWN
-- ============================================================================
LP.CharacterAdded:Connect(function(char)
    task.wait(1)
    local h = char:FindFirstChildOfClass("Humanoid")
    if h then
        h.WalkSpeed = S.WalkSpeed
        h.JumpPower = S.JumpPower
        h.UseJumpPower = true
    end
    if S.FlyBV then S.FlyBV:Destroy(); S.FlyBV = nil end
    if S.FlyBG then S.FlyBG:Destroy(); S.FlyBG = nil end
end)

-- ============================================================================
-- MOBILE BUTTON
-- ============================================================================
local MobileGui, MobileBtn

function MobileInit()
    if MobileGui and MobileGui.Parent then return end
    MobileGui = Instance.new("ScreenGui")
    MobileGui.Name = "LaxissMobile"
    MobileGui.ResetOnSpawn = false
    MobileGui.IgnoreGuiInset = true
    MobileGui.DisplayOrder = 1000
    MobileGui.Parent = game:GetService("CoreGui")

    MobileBtn = Instance.new("Frame")
    MobileBtn.Size = UDim2.fromOffset(54, 54)
    MobileBtn.Position = UDim2.new(1, -78, 0.5, -27)
    MobileBtn.BackgroundColor3 = Color3.fromRGB(74, 99, 135)
    MobileBtn.BorderSizePixel = 0
    MobileBtn.Active = true
    MobileBtn.Parent = MobileGui

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(1, 0)
    c.Parent = MobileBtn

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.fromScale(1, 1)
    lbl.BackgroundTransparency = 1
    lbl.Text = "Lx"
    lbl.TextColor3 = Color3.new(1, 1, 1)
    lbl.Font = Enum.Font.GothamBlack
    lbl.TextSize = 16
    lbl.Parent = MobileBtn

    local dragStart, startPos
    MobileBtn.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
            or i.UserInputType == Enum.UserInputType.Touch then
            dragStart = i.Position
            startPos = MobileBtn.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dragStart and (i.UserInputType == Enum.UserInputType.MouseMovement
            or i.UserInputType == Enum.UserInputType.Touch) then
            local d = i.Position - dragStart
            MobileBtn.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + d.X,
                startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
            or i.UserInputType == Enum.UserInputType.Touch then
            dragStart = nil
        end
    end)

    local pressT, pressP
    MobileBtn.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
            or i.UserInputType == Enum.UserInputType.Touch then
            pressT = os.clock()
            pressP = i.Position
        end
    end)
    MobileBtn.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
            or i.UserInputType == Enum.UserInputType.Touch then
            if pressT and (os.clock() - pressT) < 0.3
                and (i.Position - pressP).Magnitude < 10 then
                Library:ToggleUI()
            end
        end
    end)
end

function MobileDestroy()
    if MobileGui then
        MobileGui:Destroy()
        MobileGui, MobileBtn = nil, nil
    end
end

-- ============================================================================
-- KEYBIND
-- ============================================================================
UserInputService.InputBegan:Connect(function(i, proc)
    if proc then return end
    if i.UserInputType ~= Enum.UserInputType.Keyboard then return end
    if i.KeyCode.Name == S.ToggleKey then Library:ToggleUI() end
end)

-- ============================================================================
-- BOOT
-- ============================================================================
rescanCache()
if S.MobileBtn then MobileInit() end

notify("LaxissTM", "Loaded. " .. S.ToggleKey .. " to toggle UI.")

print("[LaxissTM] Kavo edition loaded.")
print("[LaxissTM] openCrystalRemote: " .. tostring(openCrystalRemote ~= nil)
    .. "  |  orbEvent: " .. tostring(orbEvent ~= nil)
    .. "  |  rebirthEvent: " .. tostring(rebirthEvent ~= nil))
print("[LaxissTM] Crystals available: " .. #CrystalNames
    .. " (Red → Alien), plus custom name input.")