
local Players          = game:GetService("Players")
local ReplicatedStorage= game:GetService("ReplicatedStorage")
local Workspace        = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local StarterGui       = game:GetService("StarterGui")
local TeleportService  = game:GetService("TeleportService")
local HttpService      = game:GetService("HttpService")
local TweenService     = game:GetService("TweenService")
local CoreGui          = game:GetService("CoreGui")
local VirtualUser      = game:GetService("VirtualUser")
local LocalPlayer      = Players.LocalPlayer

local rEvents, orbEvent, rebirthEvent, openCrystalRemote, globalFunctions

local function bindGameInstances()
    rEvents = ReplicatedStorage:WaitForChild("rEvents", 20)
    if not rEvents then return end
    orbEvent         = rEvents:WaitForChild("orbEvent", 10)
    rebirthEvent     = rEvents:WaitForChild("rebirthEvent", 10)
    openCrystalRemote = rEvents:FindFirstChild("openCrystalRemote")
    pcall(function()
        globalFunctions = require(ReplicatedStorage:WaitForChild("globalFunctions", 10))
    end)
end
bindGameInstances()

-- ============================================================================
-- STATE
-- ============================================================================
local S = {
    -- farming
    AutoOrbs=false, OrbMulti=10, AutoTouchOrbs=false, OrbMagnet=false,
    InstantCollect=false, AutoGems=false, GemBatch=5, AutoChests=false,
    AutoHoops=false, HoopMode="Touch", HoopDelay=0.1, HoopMagnet=false,
    AutoRebirth=false, RebirthCheck=true, AutoRace=false, AutoJoinRace=false,
    AutoLeaveRace=false, AutoWinRace=false, AutoQuest=false, AutoSteps=false,
    AutoGifts=false, AutoParkour=false,

    -- crystals  (location-based, matching competitor signatures)
    AutoHatch=false, CrystalLocation="City", CrystalAmount=1,
    CrystalDelay=0.5, FastOpen=false,

    -- pets
    AutoEquipBest=false, AutoEvolve=false,

    -- player
    WalkSpeed=16, JumpPower=50, Fly=false, FlySpeed=60, Noclip=false,
    InfJump=false, AutoJump=false, AntiRagdoll=false, AntiAFK=false,
    AntiKick=false, DisableLava=false, AntiVoid=false,

    -- esp
    ESPOrbs=false, ESPGems=false, ESPCrystals=false, ESPChests=false,
    ESPHoops=false, ESPPlayers=false, ESPDistance=true, ESPTracers=false,
    ESPBoxes=false, ESPMaxDist=800,

    -- interface
    Theme="Cyan", Scale=100, MobileButton=true, Notifications=true,
    ToggleKey="RightShift", RailExpanded=false, PerformanceMode=false,

    -- teleport
    SelectedMap="City", SelectedPlayer=nil, Waypoints={},

    -- session
    SessionStart=os.time(), OrbsCollected=0, GemsCollected=0,
    ChestsOpened=0, RebirthsDone=0, CrystalsOpened=0, RacesWon=0,
    FPS=0, Ping=0,

    -- internal
    ESPObjects={}, TracerLines={}, CachedParts={}, CacheStamp=0,
    FlyBV=nil, FlyBG=nil, NamecallHooked=false,
    Unloaded=false,
}

getgenv().Laxiss = S
getgenv().LaxissVersion = "4.0.0"

-- ============================================================================
-- THEME ENGINE
-- ============================================================================
local Themes = {
    Cyan = {
        Accent=Color3.fromRGB(90,205,255), AccentEnd=Color3.fromRGB(150,120,255),
        Bg=Color3.fromRGB(11,12,17), Surface=Color3.fromRGB(18,20,28),
        Card=Color3.fromRGB(23,25,34), Stroke=Color3.fromRGB(38,42,56),
        Text=Color3.fromRGB(215,218,228), Dim=Color3.fromRGB(120,126,142),
        OnAccent=Color3.fromRGB(8,10,16), Danger=Color3.fromRGB(255,95,110),
        Success=Color3.fromRGB(80,220,140), Warn=Color3.fromRGB(255,185,75),
    },
    Violet = {
        Accent=Color3.fromRGB(175,125,255), AccentEnd=Color3.fromRGB(255,120,200),
        Bg=Color3.fromRGB(13,10,19), Surface=Color3.fromRGB(21,17,30),
        Card=Color3.fromRGB(27,22,38), Stroke=Color3.fromRGB(52,42,72),
        Text=Color3.fromRGB(220,214,232), Dim=Color3.fromRGB(135,125,152),
        OnAccent=Color3.fromRGB(12,8,18), Danger=Color3.fromRGB(255,110,140),
        Success=Color3.fromRGB(140,235,175), Warn=Color3.fromRGB(255,205,120),
    },
    Emerald = {
        Accent=Color3.fromRGB(70,235,145), AccentEnd=Color3.fromRGB(130,220,255),
        Bg=Color3.fromRGB(8,14,11), Surface=Color3.fromRGB(14,24,19),
        Card=Color3.fromRGB(19,32,25), Stroke=Color3.fromRGB(34,56,43),
        Text=Color3.fromRGB(205,228,214), Dim=Color3.fromRGB(112,142,124),
        OnAccent=Color3.fromRGB(6,14,9), Danger=Color3.fromRGB(255,115,115),
        Success=Color3.fromRGB(120,255,160), Warn=Color3.fromRGB(255,215,105),
    },
    Crimson = {
        Accent=Color3.fromRGB(255,95,115), AccentEnd=Color3.fromRGB(255,165,85),
        Bg=Color3.fromRGB(17,10,13), Surface=Color3.fromRGB(26,16,20),
        Card=Color3.fromRGB(35,22,27), Stroke=Color3.fromRGB(64,36,44),
        Text=Color3.fromRGB(232,208,212), Dim=Color3.fromRGB(152,122,128),
        OnAccent=Color3.fromRGB(17,6,9), Danger=Color3.fromRGB(255,80,80),
        Success=Color3.fromRGB(115,230,150), Warn=Color3.fromRGB(255,195,95),
    },
    Amber = {
        Accent=Color3.fromRGB(255,175,75), AccentEnd=Color3.fromRGB(255,220,120),
        Bg=Color3.fromRGB(17,13,8), Surface=Color3.fromRGB(26,20,13),
        Card=Color3.fromRGB(36,28,18), Stroke=Color3.fromRGB(62,47,30),
        Text=Color3.fromRGB(232,220,202), Dim=Color3.fromRGB(152,136,116),
        OnAccent=Color3.fromRGB(16,10,4), Danger=Color3.fromRGB(255,105,85),
        Success=Color3.fromRGB(160,230,115), Warn=Color3.fromRGB(255,225,115),
    },
    Ocean = {
        Accent=Color3.fromRGB(75,150,255), AccentEnd=Color3.fromRGB(80,225,220),
        Bg=Color3.fromRGB(8,12,20), Surface=Color3.fromRGB(14,20,32),
        Card=Color3.fromRGB(19,28,44), Stroke=Color3.fromRGB(34,48,70),
        Text=Color3.fromRGB(204,216,232), Dim=Color3.fromRGB(112,128,152),
        OnAccent=Color3.fromRGB(6,9,17), Danger=Color3.fromRGB(255,120,130),
        Success=Color3.fromRGB(105,230,165), Warn=Color3.fromRGB(255,200,95),
    },
    Rose = {
        Accent=Color3.fromRGB(255,130,190), AccentEnd=Color3.fromRGB(255,180,140),
        Bg=Color3.fromRGB(17,10,15), Surface=Color3.fromRGB(26,16,23),
        Card=Color3.fromRGB(36,23,31), Stroke=Color3.fromRGB(64,40,52),
        Text=Color3.fromRGB(234,208,220), Dim=Color3.fromRGB(155,125,138),
        OnAccent=Color3.fromRGB(17,7,12), Danger=Color3.fromRGB(255,100,125),
        Success=Color3.fromRGB(145,235,175), Warn=Color3.fromRGB(255,205,130),
    },
    Mono = {
        Accent=Color3.fromRGB(210,210,222), AccentEnd=Color3.fromRGB(150,150,168),
        Bg=Color3.fromRGB(9,9,11), Surface=Color3.fromRGB(16,16,20),
        Card=Color3.fromRGB(22,22,28), Stroke=Color3.fromRGB(38,38,48),
        Text=Color3.fromRGB(195,195,205), Dim=Color3.fromRGB(108,108,120),
        OnAccent=Color3.fromRGB(6,6,8), Danger=Color3.fromRGB(235,95,95),
        Success=Color3.fromRGB(115,215,145), Warn=Color3.fromRGB(235,190,90),
    },
}
local ThemeOrder = {"Cyan","Violet","Emerald","Crimson","Amber","Ocean","Rose","Mono"}
local function T() return Themes[S.Theme] or Themes.Cyan end

-- ============================================================================
-- UTIL
-- ============================================================================
local function new(class, props, children)
    local inst = Instance.new(class)
    for k, v in pairs(props or {}) do inst[k] = v end
    for _, ch in ipairs(children or {}) do ch.Parent = inst end
    return inst
end
local function corner(r, p) return new("UICorner", {CornerRadius=UDim.new(0,r or 6), Parent=p}) end
local function stroke(c, t, p, tr)
    return new("UIStroke", {Color=c or T().Stroke, Thickness=t or 1, Transparency=tr or 0, Parent=p})
end
local function pad(n, p)
    return new("UIPadding", {
        PaddingLeft=UDim.new(0,n), PaddingRight=UDim.new(0,n),
        PaddingTop=UDim.new(0,n), PaddingBottom=UDim.new(0,n), Parent=p})
end
local function tween(inst, dur, goal, style)
    local info = TweenInfo.new(dur or 0.15, style or Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local t = TweenService:Create(inst, info, goal)
    t:Play()
    return t
end
local function gradient(p, c1, c2, rot)
    local g = new("UIGradient", {Parent=p, Rotation=rot or 0})
    g.Color = ColorSequence.new(c1 or T().Accent, c2 or T().AccentEnd)
    return g
end

local function getChar() return LocalPlayer.Character end
local function getHum()
    local c = getChar()
    return c and c:FindFirstChildOfClass("Humanoid")
end
local function getRoot()
    local c = getChar()
    return c and c:FindFirstChild("HumanoidRootPart")
end
local function getPlace()
    local ok, v = pcall(function() return LocalPlayer.currentMap.Value end)
    return ok and v or S.SelectedMap
end
local function getLevel()
    local ok, v = pcall(function() return LocalPlayer.level.Value end)
    return ok and v or nil
end
local function getMult()
    local ok, v = pcall(function() return LocalPlayer.rebirthMultiplier.Value end)
    return ok and v or nil
end
local function fmtTime(s)
    return string.format("%02d:%02d:%02d",
        math.floor(s/3600), math.floor((s%3600)/60), math.floor(s%60))
end
local function fmtNum(n)
    if n >= 1e9 then return string.format("%.1fB", n/1e9) end
    if n >= 1e6 then return string.format("%.1fM", n/1e6) end
    if n >= 1e3 then return string.format("%.1fK", n/1e3) end
    return tostring(n)
end

-- ============================================================================
-- GAME REMOTES  (crystal signature corrected)
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

-- The real signature used by LoS Ultimate, SP Hub and every working pastebin:
--   openCrystalRemote:InvokeServer("openCrystal", location)
-- The second argument is the AREA the crystal spawns in, not a tier name.
-- Some builds accept no second argument and default to the player's area,
-- so we try the location form first and fall back to the bare call.
local function openCrystal(location)
    if not openCrystalRemote then return false, "remote missing" end
    local ok = pcall(function()
        openCrystalRemote:InvokeServer("openCrystal", location)
    end)
    if ok then return true end
    local ok2 = pcall(function()
        openCrystalRemote:InvokeServer("openCrystal")
    end)
    return ok2, ok2 and nil or "invoke failed"
end

local function fireGift(index)
    local candidates = {
        rEvents and rEvents:FindFirstChild("giftEvent"),
        rEvents and rEvents:FindFirstChild("claimGift"),
        ReplicatedStorage:FindFirstChild("GiftEvent"),
    }
    for _, remote in ipairs(candidates) do
        if remote then
            pcall(function()
                if remote:IsA("RemoteFunction") then
                    remote:InvokeServer("claimGift", index)
                else
                    remote:FireServer("claimGift", index)
                end
            end)
            return true
        end
    end
    return false
end

-- ============================================================================
-- NOTIFICATION QUEUE
-- ============================================================================
local Notif = {queue = {}, active = 0, container = nil, max = 4}

function Notif.init(parent)
    Notif.container = new("Frame", {
        Name="Notifs", Size=UDim2.new(0,320,1,-40), Position=UDim2.new(1,-332,0,20),
        BackgroundTransparency=1, Parent=parent,
    })
    new("UIListLayout", {
        Padding=UDim.new(0,8), VerticalAlignment=Enum.VerticalAlignment.Top,
        HorizontalAlignment=Enum.HorizontalAlignment.Right,
        SortOrder=Enum.SortOrder.LayoutOrder, Parent=Notif.container,
    })
end

local function pump()
    while #Notif.queue > 0 and Notif.active < Notif.max do
        local job = table.remove(Notif.queue, 1)
        Notif.active = Notif.active + 1
        task.spawn(function()
            local title, text, dur, color = job[1], job[2], job[3], job[4]
            local card = new("Frame", {
                Size=UDim2.new(0,304,0,66), BackgroundColor3=T().Card,
                BackgroundTransparency=0.02, BorderSizePixel=0,
                ClipsDescendants=true, Parent=Notif.container,
            })
            corner(9, card)
            stroke(T().Stroke, 1, card)

            local bar = new("Frame", {
                Size=UDim2.new(0,3,1,-18), Position=UDim2.new(0,8,0,9),
                BackgroundColor3=color, BorderSizePixel=0, Parent=card,
            })
            corner(2, bar)

            new("TextLabel", {
                Size=UDim2.new(1,-30,0,20), Position=UDim2.new(0,20,0,10),
                BackgroundTransparency=1, Text=title, TextColor3=color,
                Font=Enum.Font.GothamBold, TextSize=13,
                TextXAlignment=Enum.TextXAlignment.Left, Parent=card,
            })
            new("TextLabel", {
                Size=UDim2.new(1,-30,0,28), Position=UDim2.new(0,20,0,30),
                BackgroundTransparency=1, Text=text, TextColor3=T().Dim,
                Font=Enum.Font.Gotham, TextSize=11, TextWrapped=true,
                TextXAlignment=Enum.TextXAlignment.Left,
                TextYAlignment=Enum.TextYAlignment.Top, Parent=card,
            })

            -- progress drain
            local prog = new("Frame", {
                Size=UDim2.new(1,0,0,2), Position=UDim2.new(0,0,1,-2),
                BackgroundColor3=color, BorderSizePixel=0,
                BackgroundTransparency=0.5, Parent=card,
            })
            prog.Size = UDim2.new(1,0,0,2)
            tween(prog, dur, {Size=UDim2.new(0,0,0,2)}, Enum.EasingStyle.Linear)

            card.Position = UDim2.new(1,40,0,0)
            tween(card, 0.28, {Position=UDim2.new(0,0,0,0)})

            task.wait(dur)
            tween(card, 0.22, {Position=UDim2.new(1,60,0,0), BackgroundTransparency=1})
            task.wait(0.24)
            card:Destroy()
            Notif.active = Notif.active - 1
            pump()
        end)
    end
end

local function notify(title, text, dur, color)
    if not S.Notifications or not Notif.container then return end
    table.insert(Notif.queue, {title, text or "", dur or 4, color or T().Accent})
    pump()
end

-- ============================================================================
-- ESP INFRASTRUCTURE  (defined before tabs so toggles can call it)
-- ============================================================================
local ESPFolder = nil
local TracerLines = {}

local function clearESP(category)
    for key, obj in pairs(S.ESPObjects) do
        if obj.Category == category then
            if obj.Billboard then obj.Billboard:Destroy() end
            if obj.Box then obj.Box:Destroy() end
            S.ESPObjects[key] = nil
        end
    end
    if category == "Tracer" then
        for _, line in pairs(TracerLines) do
            pcall(function() line:Remove() end)
        end
        TracerLines = {}
    end
end

-- ============================================================================
-- WINDOW
-- ============================================================================
local UI = {}
UI.Window = nil
UI.Main = nil
UI.ScaleObj = nil
UI.Tabs = {}
UI.TabButtons = {}
UI.Rail = nil
UI.RailList = nil
UI.Content = nil
UI.Search = nil

local existing = CoreGui:FindFirstChild("LaxissTM")
if existing then existing:Destroy() end
local existingMobile = CoreGui:FindFirstChild("LaxissMobile")
if existingMobile then existingMobile:Destroy() end

UI.Gui = new("ScreenGui", {
    Name="LaxissTM", ResetOnSpawn=false, IgnoreGuiInset=true,
    ZIndexBehavior=Enum.ZIndexBehavior.Sibling, DisplayOrder=999, Parent=CoreGui,
})
UI.ScaleObj = new("UIScale", {Scale=S.Scale/100, Parent=UI.Gui})

UI.Window = new("Frame", {
    Name="Main", Size=UDim2.fromOffset(640,470),
    Position=UDim2.new(0.5,-320,0.5,-235),
    BackgroundColor3=T().Bg, BorderSizePixel=0, Active=true,
    ClipsDescendants=true, Parent=UI.Gui,
})
corner(12, UI.Window)
UI.WindowStroke = stroke(T().Stroke, 1, UI.Window)

-- header
UI.Header = new("Frame", {
    Name="Header", Size=UDim2.new(1,0,0,46),
    BackgroundColor3=T().Surface, BorderSizePixel=0, Parent=UI.Window,
})
corner(12, UI.Header)
new("Frame", {
    Size=UDim2.new(1,0,0,14), Position=UDim2.new(0,0,1,-14),
    BackgroundColor3=T().Surface, BorderSizePixel=0, Parent=UI.Header,
})

local headerGrad = new("Frame", {
    Size=UDim2.new(0,3,0,26), Position=UDim2.fromOffset(16,10),
    BackgroundColor3=T().Accent, BorderSizePixel=0, Parent=UI.Header,
})
corner(2, headerGrad)
gradient(headerGrad, T().Accent, T().AccentEnd, 90)

new("TextLabel", {
    Size=UDim2.new(0,110,0,22), Position=UDim2.fromOffset(28,12),
    BackgroundTransparency=1, Text="LaxissTM",
    TextColor3=T().Text, Font=Enum.Font.GothamBlack, TextSize=16,
    TextXAlignment=Enum.TextXAlignment.Left, Parent=UI.Header,
})
new("TextLabel", {
    Size=UDim2.new(0,150,0,14), Position=UDim2.fromOffset(29,31),
    BackgroundTransparency=1, Text="v4 Reforged",
    TextColor3=T().Dim, Font=Enum.Font.Gotham, TextSize=10,
    TextXAlignment=Enum.TextXAlignment.Left, Parent=UI.Header,
})

-- search box
UI.Search = new("TextBox", {
    Size=UDim2.fromOffset(150,26), Position=UDim2.new(1,-250,0.5,-13),
    BackgroundColor3=T().Card, BorderSizePixel=0,
    Text="", PlaceholderText="Search features…",
    TextColor3=T().Text, PlaceholderColor3=T().Dim,
    Font=Enum.Font.Gotham, TextSize=11,
    ClearTextOnFocus=false, Parent=UI.Header,
})
corner(6, UI.Search)
pad(8, UI.Search)

local function filterTabs(query)
    query = query:lower()
    for _, tabFrame in pairs(UI.Tabs) do
        for _, child in ipairs(tabFrame:GetChildren()) do
            local tag = child:GetAttribute("SearchText")
            if tag then
                child.Visible = (query == "" or tag:lower():find(query, 1, true) ~= nil)
            end
        end
    end
end
UI.Search:GetPropertyChangedSignal("Text"):Connect(function()
    filterTabs(UI.Search.Text)
end)

-- header buttons
local function headerBtn(text, x, color, cb)
    local b = new("TextButton", {
        Size=UDim2.fromOffset(30,30), Position=UDim2.new(1,x,0.5,-15),
        BackgroundTransparency=1, Text=text,
        TextColor3=color or T().Dim, Font=Enum.Font.GothamBold,
        TextSize=16, Parent=UI.Header,
    })
    b.MouseEnter:Connect(function() tween(b, 0.1, {TextColor3=color or T().Text}) end)
    b.MouseLeave:Connect(function() tween(b, 0.1, {TextColor3=color or T().Dim}) end)
    b.MouseButton1Click:Connect(function() if cb then cb() end end)
    return b
end

headerBtn("—", -96, nil, function()
    UI.Window.Visible = false
    MobileShow()
end)
headerBtn("×", -32, T().Danger, function()
    UI.Gui.Enabled = false
    MobileShow()
end)

-- open animation
UI.Window.Size = UDim2.fromOffset(600,440)
UI.Window.BackgroundTransparency = 1
tween(UI.Window, 0.32, {
    Size=UDim2.fromOffset(640,470), BackgroundTransparency=0,
}, Enum.EasingStyle.Back)

-- drag
local dragStart, startPos
UI.Header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        dragStart = input.Position
        startPos = UI.Window.Position
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragStart and (input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch) then
        local d = input.Position - dragStart
        UI.Window.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + d.X,
            startPos.Y.Scale, startPos.Y.Offset + d.Y)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        dragStart = nil
    end
end)

-- rail
UI.Rail = new("Frame", {
    Name="Rail", Size=UDim2.new(0,58,1,-76),
    Position=UDim2.fromOffset(0,46),
    BackgroundColor3=T().Surface, BorderSizePixel=0, Parent=UI.Window,
})
new("Frame", {
    Size=UDim2.new(1,0,0,14), Position=UDim2.new(0,0,1,-14),
    BackgroundColor3=T().Surface, BorderSizePixel=0, Parent=UI.Rail,
})
UI.RailList = new("Frame", {
    Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, Parent=UI.Rail,
})
pad(6, UI.RailList)
new("UIListLayout", {
    Padding=UDim.new(0,4), SortOrder=Enum.SortOrder.LayoutOrder,
    Parent=UI.RailList,
})

local railExpanded = false
local function setRail(expand)
    railExpanded = expand
    tween(UI.Rail, 0.18, {Size=UDim2.new(0, expand and 168 or 58, 1, -76)})
    tween(UI.ContentWrap, 0.18, {
        Size=UDim2.new(1, expand and -168 or -58, 1, -76),
        Position=UDim2.fromOffset(expand and 168 or 58, 46),
    })
end

UI.Rail.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        setRail(true)
    end
end)
UI.Rail.MouseLeave:Connect(function()
    if not S.RailExpanded then setRail(false) end
end)

-- content
UI.ContentWrap = new("Frame", {
    Name="ContentWrap", Size=UDim2.new(1,-58,1,-76),
    Position=UDim2.fromOffset(58,46), BackgroundTransparency=1, Parent=UI.Window,
})
pad(12, UI.ContentWrap)
UI.Content = new("Frame", {
    Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, Parent=UI.ContentWrap,
})

-- status bar
local statusBar = new("Frame", {
    Size=UDim2.new(1,0,0,30), Position=UDim2.new(0,0,1,-30),
    BackgroundColor3=T().Surface, BorderSizePixel=0, Parent=UI.Window,
})
corner(12, statusBar)
new("Frame", {
    Size=UDim2.new(1,0,0,12), Position=UDim2.new(0,0,0,0),
    BackgroundColor3=T().Surface, BorderSizePixel=0, Parent=statusBar,
})
local statusLeft = new("TextLabel", {
    Size=UDim2.new(0.5,-12,1,0), Position=UDim2.fromOffset(14,0),
    BackgroundTransparency=1, Text="",
    TextColor3=T().Dim, Font=Enum.Font.Gotham, TextSize=10,
    TextXAlignment=Enum.TextXAlignment.Left, Parent=statusBar,
})
local statusRight = new("TextLabel", {
    Size=UDim2.new(0.5,-12,1,0), Position=UDim2.new(0.5,0,0,0),
    BackgroundTransparency=1, Text="",
    TextColor3=T().Dim, Font=Enum.Font.Gotham, TextSize=10,
    TextXAlignment=Enum.TextXAlignment.Right, Parent=statusBar,
})

Notif.init(UI.Gui)

-- ============================================================================
-- TAB SYSTEM
-- ============================================================================
local function selectTab(name)
    for tabName, frame in pairs(UI.Tabs) do
        frame.Visible = (tabName == name)
    end
    for tabName, btn in pairs(UI.TabButtons) do
        local active = (tabName == name)
        tween(btn, 0.12, {
            BackgroundColor3 = active and T().Card or T().Surface,
        })
        local icon = btn:FindFirstChild("Icon")
        local label = btn:FindFirstChild("Label")
        if icon then icon.TextColor3 = active and T().Accent or T().Dim end
        if label then
            label.TextColor3 = active and T().Text or T().Dim
            label.TextTransparency = railExpanded and 0 or 1
        end
        local bar = btn:FindFirstChild("ActiveBar")
        if bar then bar.Visible = active end
    end
end

local function makeTab(name, icon)
    local btn = new("TextButton", {
        Size=UDim2.new(1,0,0,36), BackgroundColor3=T().Surface,
        BorderSizePixel=0, Text="", Parent=UI.RailList,
    })
    corner(8, btn)

    local activeBar = new("Frame", {
        Name="ActiveBar", Size=UDim2.new(0,3,0,18),
        Position=UDim2.new(0,0,0.5,-9),
        BackgroundColor3=T().Accent, BorderSizePixel=0,
        Visible=false, Parent=btn,
    })
    corner(2, activeBar)
    gradient(activeBar, T().Accent, T().AccentEnd, 90)

    new("TextLabel", {
        Name="Icon", Size=UDim2.fromOffset(38,36),
        Position=UDim2.fromOffset(3,0), BackgroundTransparency=1,
        Text=icon, TextColor3=T().Dim, Font=Enum.Font.GothamBold,
        TextSize=16, Parent=btn,
    })
    new("TextLabel", {
        Name="Label", Size=UDim2.new(1,-52,1,0),
        Position=UDim2.fromOffset(46,0), BackgroundTransparency=1,
        Text=name, TextColor3=T().Dim, Font=Enum.Font.GothamBold,
        TextSize=12, TextXAlignment=Enum.TextXAlignment.Left,
        TextTransparency=1, Parent=btn,
    })

    local frame = new("ScrollingFrame", {
        Size=UDim2.fromScale(1,1), BackgroundTransparency=1, BorderSizePixel=0,
        ScrollBarThickness=3, ScrollBarImageColor3=T().Accent,
        CanvasSize=UDim2.new(0,0,0,0),
        AutomaticCanvasSize=Enum.AutomaticSize.Y,
        Visible=false, Parent=UI.Content,
    })
    new("UIListLayout", {
        Padding=UDim.new(0,7), SortOrder=Enum.SortOrder.LayoutOrder,
        Parent=frame,
    })

    UI.Tabs[name] = frame
    UI.TabButtons[name] = btn

    btn.MouseButton1Click:Connect(function() selectTab(name) end)
    return frame
end

-- rail auto-expand keeps labels in sync
UI.Rail.MouseEnter:Connect(function()
    for _, btn in pairs(UI.TabButtons) do
        local label = btn:FindFirstChild("Label")
        if label then tween(label, 0.15, {TextTransparency=0}) end
    end
end)
UI.Rail.MouseLeave:Connect(function()
    if S.RailExpanded then return end
    for _, btn in pairs(UI.TabButtons) do
        local label = btn:FindFirstChild("Label")
        if label then tween(label, 0.15, {TextTransparency=1}) end
    end
end)

-- ============================================================================
-- WIDGETS
-- ============================================================================
local W = {}

local function tagHolder(holder, text)
    holder:SetAttribute("SearchText", text or "")
    return holder
end

function W.Section(parent, text)
    local h = new("Frame", {
        Size=UDim2.new(1,0,0,26), BackgroundTransparency=1, Parent=parent,
    })
    new("TextLabel", {
        Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, Text=text,
        TextColor3=T().Accent, Font=Enum.Font.GothamBold, TextSize=11,
        TextXAlignment=Enum.TextXAlignment.Left, Parent=h,
    })
    local line = new("Frame", {
        Size=UDim2.new(1,0,0,1), Position=UDim2.new(0,0,1,-1),
        BackgroundColor3=T().Stroke, BorderSizePixel=0, Parent=h,
    })
    local g = new("UIGradient", {Parent=line})
    g.Color = ColorSequence.new(T().Stroke, T().Bg)
    return h
end

function W.Label(parent, text, height)
    local h = new("Frame", {
        Size=UDim2.new(1,0,0,height or 20), BackgroundTransparency=1,
        Parent=parent,
    })
    local l = new("TextLabel", {
        Size=UDim2.fromScale(1,1), BackgroundTransparency=1, Text=text,
        TextColor3=T().Text, Font=Enum.Font.Gotham, TextSize=12,
        TextXAlignment=Enum.TextXAlignment.Left, Parent=h,
    })
    tagHolder(h, text)
    return l
end

function W.Paragraph(parent, text, height)
    local h = new("Frame", {
        Size=UDim2.new(1,0,0,height or 44), BackgroundTransparency=1,
        Parent=parent,
    })
    new("TextLabel", {
        Size=UDim2.fromScale(1,1), BackgroundTransparency=1, Text=text,
        TextColor3=T().Dim, Font=Enum.Font.Gotham, TextSize=11,
        TextWrapped=true, TextXAlignment=Enum.TextXAlignment.Left,
        TextYAlignment=Enum.TextYAlignment.Top, Parent=h,
    })
    return h
end

function W.Divider(parent)
    return new("Frame", {
        Size=UDim2.new(1,0,0,1), BackgroundColor3=T().Stroke,
        BorderSizePixel=0, Parent=parent,
    })
end

-- ── Toggle pill ──────────────────────────────────────────────────────────
function W.Toggle(parent, label, default, cb)
    local h = new("Frame", {
        Size=UDim2.new(1,0,0,34), BackgroundTransparency=1, Parent=parent,
    })
    new("TextLabel", {
        Size=UDim2.new(1,-64,1,0), BackgroundTransparency=1, Text=label,
        TextColor3=T().Text, Font=Enum.Font.Gotham, TextSize=12,
        TextXAlignment=Enum.TextXAlignment.Left, Parent=h,
    })

    local track = new("Frame", {
        Size=UDim2.fromOffset(42,22), Position=UDim2.new(1,-42,0.5,-11),
        BackgroundColor3=default and T().Accent or T().Card,
        BorderSizePixel=0, Parent=h,
    })
    corner(11, track)
    local trackStroke = stroke(default and T().Accent or T().Stroke, 1, track)

    local knob = new("Frame", {
        Size=UDim2.fromOffset(16,16),
        Position=UDim2.new(0, default and 23 or 3, 0.5, -8),
        BackgroundColor3=default and T().OnAccent or T().Dim,
        BorderSizePixel=0, Parent=track,
    })
    corner(8, knob)

    local state = default
    local btn = new("TextButton", {
        Size=UDim2.fromScale(1,1), BackgroundTransparency=1, Text="",
        Parent=track,
    })

    btn.MouseButton1Click:Connect(function()
        state = not state
        tween(track, 0.16, {BackgroundColor3 = state and T().Accent or T().Card})
        tween(knob, 0.16, {
            Position = UDim2.new(0, state and 23 or 3, 0.5, -8),
            BackgroundColor3 = state and T().OnAccent or T().Dim,
        }, Enum.EasingStyle.Back)
        trackStroke.Color = state and T().Accent or T().Stroke
        if cb then pcall(cb, state) end
    end)

    tagHolder(h, label)
    return h
end

-- ── Slider with value bubble ─────────────────────────────────────────────
function W.Slider(parent, label, min, max, default, cb)
    local h = new("Frame", {
        Size=UDim2.new(1,0,0,52), BackgroundTransparency=1, Parent=parent,
    })
    local title = new("TextLabel", {
        Size=UDim2.new(1,0,0,18), BackgroundTransparency=1,
        Text=label .. ": " .. tostring(default),
        TextColor3=T().Text, Font=Enum.Font.Gotham, TextSize=12,
        TextXAlignment=Enum.TextXAlignment.Left, Parent=h,
    })

    local track = new("Frame", {
        Size=UDim2.new(1,-14,0,5), Position=UDim2.fromOffset(0,33),
        BackgroundColor3=T().Card, BorderSizePixel=0, Parent=h,
    })
    corner(3, track)

    local fill = new("Frame", {
        Size=UDim2.fromScale((default-min)/(max-min),1),
        BackgroundColor3=T().Accent, BorderSizePixel=0, Parent=track,
    })
    corner(3, fill)
    gradient(fill, T().Accent, T().AccentEnd)

    local knob = new("Frame", {
        Size=UDim2.fromOffset(13,13),
        Position=UDim2.new(fill.Size.X.Scale,-6.5,0.5,-6.5),
        BackgroundColor3=T().Text, BorderSizePixel=0, Parent=track,
    })
    corner(7, knob)

    local bubble = new("TextLabel", {
        Size=UDim2.fromOffset(40,20),
        Position=UDim2.new(fill.Size.X.Scale,-20,-2.4,0),
        BackgroundColor3=T().Card, Text=tostring(default),
        TextColor3=T().Text, Font=Enum.Font.GothamBold, TextSize=10,
        Visible=false, ZIndex=5, Parent=track,
    })
    corner(4, bubble)
    stroke(T().Stroke, 1, bubble)

    local dragging, value = false, default
    local function setFromX(x)
        local rel = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        value = math.floor(min + (max-min)*rel + 0.5)
        fill.Size = UDim2.fromScale(rel, 1)
        knob.Position = UDim2.new(rel, -6.5, 0.5, -6.5)
        bubble.Position = UDim2.new(rel, -20, -2.4, 0)
        bubble.Text = tostring(value)
        title.Text = label .. ": " .. tostring(value)
        if cb then pcall(cb, value) end
    end

    track.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
            or i.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            bubble.Visible = true
            setFromX(i.Position.X)
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement
            or i.UserInputType == Enum.UserInputType.Touch) then
            setFromX(i.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
            or i.UserInputType == Enum.UserInputType.Touch then
            dragging = false
            bubble.Visible = false
        end
    end)

    tagHolder(h, label)
    return h
end

-- ── Dropdown with cycling ────────────────────────────────────────────────
function W.Dropdown(parent, label, options, default, cb)
    local h = new("Frame", {
        Size=UDim2.new(1,0,0,34), BackgroundTransparency=1, Parent=parent,
    })
    new("TextLabel", {
        Size=UDim2.new(1,-190,1,0), BackgroundTransparency=1, Text=label,
        TextColor3=T().Text, Font=Enum.Font.Gotham, TextSize=12,
        TextXAlignment=Enum.TextXAlignment.Left, Parent=h,
    })

    local btn = new("TextButton", {
        Size=UDim2.fromOffset(180,26), Position=UDim2.new(1,-180,0.5,-13),
        BackgroundColor3=T().Card, BorderSizePixel=0, Text="◂  " .. default .. "  ▸",
        TextColor3=T().Text, Font=Enum.Font.Gotham, TextSize=11, Parent=h,
    })
    corner(6, btn)

    local index = 1
    for i, opt in ipairs(options) do
        if opt == default then index = i break end
    end

    btn.MouseButton1Click:Connect(function()
        index = index % #options + 1
        btn.Text = "◂  " .. options[index] .. "  ▸"
        if cb then pcall(cb, options[index]) end
    end)

    tagHolder(h, label)
    return h
end

-- ── Button ───────────────────────────────────────────────────────────────
function W.Button(parent, text, cb, color)
    local btn = new("TextButton", {
        Size=UDim2.new(1,0,0,32), BackgroundColor3=color or T().Card,
        BorderSizePixel=0, Text=text, TextColor3=T().Text,
        Font=Enum.Font.GothamBold, TextSize=12, Parent=parent,
    })
    corner(7, btn)
    local s = stroke(T().Stroke, 1, btn)

    btn.MouseEnter:Connect(function()
        tween(btn, 0.12, {BackgroundColor3 = color or T().Accent})
        btn.TextColor3 = color and T().Text or T().OnAccent
        s.Color = color or T().Accent
    end)
    btn.MouseLeave:Connect(function()
        tween(btn, 0.12, {BackgroundColor3 = color or T().Card})
        btn.TextColor3 = T().Text
        s.Color = T().Stroke
    end)
    btn.MouseButton1Click:Connect(function() if cb then pcall(cb) end end)

    tagHolder(btn, text)
    return btn
end

-- ── Textbox ──────────────────────────────────────────────────────────────
function W.Textbox(parent, label, default, cb)
    local h = new("Frame", {
        Size=UDim2.new(1,0,0,34), BackgroundTransparency=1, Parent=parent,
    })
    new("TextLabel", {
        Size=UDim2.new(1,-180,1,0), BackgroundTransparency=1, Text=label,
        TextColor3=T().Text, Font=Enum.Font.Gotham, TextSize=12,
        TextXAlignment=Enum.TextXAlignment.Left, Parent=h,
    })
    local box = new("TextBox", {
        Size=UDim2.fromOffset(180,26), Position=UDim2.new(1,-180,0.5,-13),
        BackgroundColor3=T().Card, BorderSizePixel=0, Text=tostring(default),
        PlaceholderText="…", TextColor3=T().Text, Font=Enum.Font.Gotham,
        TextSize=11, ClearTextOnFocus=false, Parent=h,
    })
    corner(6, box)
    pad(8, box)
    box.FocusLost:Connect(function()
        if cb then pcall(cb, box.Text) end
    end)
    tagHolder(h, label)
    return box
end

-- ── Keybind ──────────────────────────────────────────────────────────────
function W.Keybind(parent, label, default, cb)
    local h = new("Frame", {
        Size=UDim2.new(1,0,0,34), BackgroundTransparency=1, Parent=parent,
    })
    new("TextLabel", {
        Size=UDim2.new(1,-180,1,0), BackgroundTransparency=1, Text=label,
        TextColor3=T().Text, Font=Enum.Font.Gotham, TextSize=12,
        TextXAlignment=Enum.TextXAlignment.Left, Parent=h,
    })
    local btn = new("TextButton", {
        Size=UDim2.fromOffset(180,26), Position=UDim2.new(1,-180,0.5,-13),
        BackgroundColor3=T().Card, BorderSizePixel=0, Text=default,
        TextColor3=T().Text, Font=Enum.Font.Gotham, TextSize=11, Parent=h,
    })
    corner(6, btn)
    local listening = false
    btn.MouseButton1Click:Connect(function()
        if listening then return end
        listening = true
        btn.Text = "Press a key…"
        local conn
        conn = UserInputService.InputBegan:Connect(function(i, proc)
            if proc then return end
            if i.UserInputType == Enum.UserInputType.Keyboard then
                btn.Text = i.KeyCode.Name
                listening = false
                if cb then pcall(cb, i.KeyCode.Name) end
                conn:Disconnect()
            end
        end)
    end)
    tagHolder(h, label)
    return btn
end

-- ============================================================================
-- TABS
-- ============================================================================
local FarmTab     = makeTab("Farming", "◈")
local CrystalTab  = makeTab("Crystals", "✦")
local PlayerTab   = makeTab("Player", "▶")
local TeleportTab = makeTab("Teleport", "◉")
local ESPTab      = makeTab("ESP", "◎")
local SettingsTab = makeTab("Settings", "⚙")
local CreditsTab  = makeTab("Credits", "ℹ")

-- ── FARM ─────────────────────────────────────────────────────────────────
W.Section(FarmTab, "ORBS")
W.Dropdown(FarmTab, "Orb Type",
    {"Ethereal Orb","Red Orb","Blue Orb","Yellow Orb","Orange Orb","Rainbow Orb"},
    "Ethereal Orb", function(v) S.OrbType = v end)
W.Dropdown(FarmTab, "Location",
    {"City","Desert","Magma City","Grassland","Jungle","Legends Highway"},
    "City", function(v) S.OrbLoc = v end)
W.Slider(FarmTab, "Orbs Per Tick", 1, 100, 10, function(v) S.OrbMulti = v end)
W.Toggle(FarmTab, "Auto Orbs (remote)", false, function(v) S.AutoOrbs = v end)
W.Toggle(FarmTab, "Auto Orb Touch", false, function(v) S.AutoTouchOrbs = v end)
W.Toggle(FarmTab, "Orb Magnet", false, function(v) S.OrbMagnet = v end)
W.Toggle(FarmTab, "Instant Collect ×10,000", false, function(v) S.InstantCollect = v end)

W.Section(FarmTab, "GEMS & CHESTS")
W.Slider(FarmTab, "Gem Batch", 1, 30, 5, function(v) S.GemBatch = v end)
W.Toggle(FarmTab, "Auto Gems", false, function(v) S.AutoGems = v end)
W.Toggle(FarmTab, "Auto Chests", false, function(v) S.AutoChests = v end)

W.Section(FarmTab, "HOOPS")
W.Dropdown(FarmTab, "Hoop Mode", {"Touch","Teleport"}, "Touch",
    function(v) S.HoopMode = v end)
W.Slider(FarmTab, "Hoop Delay (ms)", 50, 1000, 100,
    function(v) S.HoopDelay = v/1000 end)
W.Toggle(FarmTab, "Auto Hoops", false, function(v) S.AutoHoops = v end)
W.Toggle(FarmTab, "Hoop Magnet", false, function(v) S.HoopMagnet = v end)

W.Section(FarmTab, "REBIRTH")
W.Toggle(FarmTab, "Auto Rebirth", false, function(v) S.AutoRebirth = v end)
W.Toggle(FarmTab, "Level Check", true, function(v) S.RebirthCheck = v end)

W.Section(FarmTab, "RACE & QUEST")
W.Toggle(FarmTab, "Auto Join Race", false, function(v) S.AutoJoinRace = v end)
W.Toggle(FarmTab, "Auto Leave Race", false, function(v) S.AutoLeaveRace = v end)
W.Toggle(FarmTab, "Auto Win Race", false, function(v) S.AutoWinRace = v end)
W.Toggle(FarmTab, "Auto Quest", false, function(v) S.AutoQuest = v end)
W.Toggle(FarmTab, "Auto Steps", false, function(v) S.AutoSteps = v end)

W.Section(FarmTab, "MISC")
W.Toggle(FarmTab, "Auto Claim Gifts 1–8", false, function(v) S.AutoGifts = v end)
W.Toggle(FarmTab, "Walk on Parkour Floor", false, function(v) S.AutoParkour = v end)

W.Divider(FarmTab)
local farmStats = W.Paragraph(FarmTab, "", 62)

-- ── CRYSTALS  (corrected to competitor signature) ────────────────────────
W.Section(CrystalTab, "CRYSTAL OPENER")
W.Paragraph(CrystalTab,
    "Opens crystals through openCrystalRemote:InvokeServer(\"openCrystal\", location). "
    .. "The location selects which area's crystal pool is used. Amount is a "
    .. "client-side loop, same as LoS Ultimate and SP Hub.", 62)

W.Dropdown(CrystalTab, "Crystal Area",
    {"City","Desert","Snow City","Forest City","Magma City","Grassland","Jungle"},
    "City", function(v) S.CrystalLocation = v end)

W.Slider(CrystalTab, "Open Amount", 1, 100, 1, function(v) S.CrystalAmount = v end)
W.Slider(CrystalTab, "Open Delay (ms)", 100, 1000, 500,
    function(v) S.CrystalDelay = v/1000 end,
    "500ms matches the default every working script uses. Drop to 100ms for fast open.")

W.Button(CrystalTab, "Open Crystals Now", function()
    local ok, opened = true, 0
    for _ = 1, S.CrystalAmount do
        local success, err = openCrystal(S.CrystalLocation)
        if not success then ok = false; break end
        opened = opened + 1
        S.CrystalsOpened = S.CrystalsOpened + 1
        task.wait(S.FastOpen and 0.1 or S.CrystalDelay)
    end
    if ok then
        notify("Crystals", "Opened " .. opened .. " × " .. S.CrystalLocation .. " crystal", 3, T().Success)
    else
        notify("Crystals", "Invoke failed — remote may have been renamed.", 4, T().Danger)
    end
end)

W.Toggle(CrystalTab, "Auto Hatch", false, function(v) S.AutoHatch = v end)
W.Toggle(CrystalTab, "Fast Open (100ms)", false, function(v) S.FastOpen = v end)

W.Section(CrystalTab, "PETS")
W.Toggle(CrystalTab, "Auto Equip Best Pet", false, function(v) S.AutoEquipBest = v end)
W.Toggle(CrystalTab, "Auto Evolve Pets", false, function(v) S.AutoEvolve = v end)
W.Button(CrystalTab, "Equip Best Pet Now", function()
    local inv = LocalPlayer:FindFirstChild("Inventory")
    if not inv then
        notify("Pets", "No Inventory folder found.", 3, T().Warn); return
    end
    local best, bestVal = nil, -1
    for _, pet in ipairs(inv:GetDescendants()) do
        if pet:IsA("StringValue") or pet:IsA("Folder") then
            local p = pet:FindFirstChild("Power") or pet:FindFirstChild("Level")
            local v = p and tonumber(p.Value) or 0
            if v > bestVal then bestVal = v; best = pet end
        end
    end
    if best then
        local remote = rEvents and (rEvents:FindFirstChild("equipPet")
            or rEvents:FindFirstChild("petEvent"))
        if remote then
            pcall(function()
                if remote:IsA("RemoteFunction") then
                    remote:InvokeServer("equip", best.Name)
                else
                    remote:FireServer("equip", best.Name)
                end
            end)
            notify("Pets", "Equipped " .. best.Name, 3, T().Success)
        else
            notify("Pets", "Equip remote not found.", 3, T().Warn)
        end
    end
end)

W.Section(CrystalTab, "STATISTICS")
local crystalStats = W.Paragraph(CrystalTab, "", 52)

-- ── PLAYER ───────────────────────────────────────────────────────────────
W.Section(PlayerTab, "MOVEMENT")
W.Slider(PlayerTab, "WalkSpeed", 16, 300, 16, function(v)
    S.WalkSpeed = v
    local h = getHum(); if h then h.WalkSpeed = v end
end)
W.Slider(PlayerTab, "JumpPower", 50, 300, 50, function(v)
    S.JumpPower = v
    local h = getHum(); if h then h.JumpPower = v; h.UseJumpPower = true end
end)
W.Toggle(PlayerTab, "Infinite Jump", false, function(v) S.InfJump = v end)
W.Toggle(PlayerTab, "Auto Jump", false, function(v) S.AutoJump = v end)
W.Toggle(PlayerTab, "Fly", false, function(v) S.Fly = v end)
W.Slider(PlayerTab, "Fly Speed", 20, 300, 60, function(v) S.FlySpeed = v end)
W.Toggle(PlayerTab, "Noclip", false, function(v) S.Noclip = v end)

W.Section(PlayerTab, "PROTECTION")
W.Toggle(PlayerTab, "Anti-Ragdoll", false, function(v) S.AntiRagdoll = v end)
W.Toggle(PlayerTab, "Anti-AFK", false, function(v) S.AntiAFK = v end)
W.Toggle(PlayerTab, "Anti-Kick", false, function(v) S.AntiKick = v end)
W.Toggle(PlayerTab, "Disable Lava Damage", false, function(v) S.DisableLava = v end)
W.Toggle(PlayerTab, "Anti-Void", false, function(v) S.AntiVoid = v end)

W.Section(PlayerTab, "ACTIONS")
W.Button(PlayerTab, "Reset Character", function()
    local c = getChar(); if c then c:BreakJoints() end
end)
W.Button(PlayerTab, "Rejoin Server", function()
    TeleportService:Teleport(game.PlaceId, LocalPlayer)
end)
W.Button(PlayerTab, "Server Hop", function()
    local ok, res = pcall(function()
        return game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId
            .. "/servers/Public?sortOrder=Asc&limit=100")
    end)
    if not ok then notify("Server Hop", "Fetch failed.", 3, T().Danger); return end
    local data = HttpService:JSONDecode(res)
    for _, srv in ipairs(data.data or {}) do
        if srv.playing < srv.maxPlayers and srv.id ~= game.JobId then
            TeleportService:TeleportToPlaceInstance(game.PlaceId, srv.id, LocalPlayer)
            notify("Server Hop", "Joining " .. srv.playing .. " player server.", 3, T().Success)
            return
        end
    end
    notify("Server Hop", "No open servers.", 3, T().Warn)
end)
W.Button(PlayerTab, "Redeem All Codes", function()
    local codes = {"1K","2K","3K","4K","5K","10K","FREESTEPS","SPEED","LUCKY","SUMMER"}
    local remote = rEvents and (rEvents:FindFirstChild("codeEvent")
        or rEvents:FindFirstChild("redeemCode"))
    if not remote then
        notify("Codes", "Code remote not found.", 3, T().Warn); return
    end
    for _, code in ipairs(codes) do
        pcall(function()
            if remote:IsA("RemoteFunction") then
                remote:InvokeServer("redeem", code)
            else
                remote:FireServer("redeem", code)
            end
        end)
        task.wait(0.3)
    end
    notify("Codes", "Redeemed " .. #codes .. " codes.", 3, T().Success)
end)

-- ── TELEPORT ─────────────────────────────────────────────────────────────
W.Section(TeleportTab, "MAP TELEPORT")
local MapPos = {
    ["City"]=Vector3.new(-130,5,10), ["Desert"]=Vector3.new(1050,10,250),
    ["Magma City"]=Vector3.new(-150,5,1450), ["Grassland"]=Vector3.new(500,5,-400),
    ["Jungle"]=Vector3.new(-900,5,-900), ["Legends Highway"]=Vector3.new(2000,10,2000),
}
local mapNames = {}
for n in pairs(MapPos) do mapNames[#mapNames+1] = n end
table.sort(mapNames)

W.Dropdown(TeleportTab, "Destination", mapNames, "City",
    function(v) S.SelectedMap = v end)
W.Button(TeleportTab, "Teleport to Map", function()
    local r = getRoot()
    local p = MapPos[S.SelectedMap]
    if r and p then r.CFrame = CFrame.new(p) end
end)
W.Button(TeleportTab, "Teleport to Spawn", function()
    local r, sp = getRoot(), Workspace:FindFirstChildOfClass("SpawnLocation")
    if r and sp then r.CFrame = sp.CFrame + Vector3.new(0,4,0) end
end)

W.Section(TeleportTab, "CUSTOM COORDINATES")
local cx, cy, cz = "0", "10", "0"
W.Textbox(TeleportTab, "X", "0", function(v) cx = v end)
W.Textbox(TeleportTab, "Y", "10", function(v) cy = v end)
W.Textbox(TeleportTab, "Z", "0", function(v) cz = v end)
W.Button(TeleportTab, "Go to Coordinates", function()
    local r = getRoot()
    local x, y, z = tonumber(cx), tonumber(cy), tonumber(cz)
    if r and x and y and z then
        r.CFrame = CFrame.new(x, y, z)
    else
        notify("Teleport", "Invalid coordinates.", 3, T().Warn)
    end
end)

W.Section(TeleportTab, "PLAYER TELEPORT")
local playerNames = {}
local function refreshPlayers()
    playerNames = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then playerNames[#playerNames+1] = p.Name end
    end
    if #playerNames == 0 then playerNames = {"<none>"} end
    S.SelectedPlayer = playerNames[1]
end
refreshPlayers()

W.Dropdown(TeleportTab, "Target", playerNames, S.SelectedPlayer or "<none>",
    function(v) S.SelectedPlayer = v end)
W.Button(TeleportTab, "Teleport to Player", function()
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Name == S.SelectedPlayer and p.Character then
            local tr = p.Character:FindFirstChild("HumanoidRootPart")
            local r = getRoot()
            if tr and r then r.CFrame = tr.CFrame + Vector3.new(0,2,0) end
            return
        end
    end
    notify("Teleport", "Player not found.", 3, T().Warn)
end)
W.Button(TeleportTab, "Refresh Player List", function()
    refreshPlayers()
    notify("Teleport", "List refreshed.", 2)
end)

W.Section(TeleportTab, "WAYPOINTS")
W.Button(TeleportTab, "Save Current Position", function()
    local r = getRoot()
    if not r then return end
    local name = "WP" .. (#S.Waypoints + 1)
    table.insert(S.Waypoints, {Name=name, Pos=r.Position})
    notify("Waypoints", "Saved " .. name, 2, T().Success)
end)
W.Button(TeleportTab, "Return to Last Waypoint", function()
    local r = getRoot()
    local wp = S.Waypoints[#S.Waypoints]
    if r and wp then
        r.CFrame = CFrame.new(wp.Pos)
        notify("Waypoints", "Returned to " .. wp.Name, 2, T().Success)
    else
        notify("Waypoints", "No waypoint saved.", 2, T().Warn)
    end
end)
W.Button(TeleportTab, "Clear Waypoints", function()
    S.Waypoints = {}
    notify("Waypoints", "Cleared.", 2)
end)

-- ── ESP ──────────────────────────────────────────────────────────────────
W.Section(ESPTab, "ESP TOGGLES")
W.Toggle(ESPTab, "ESP Orbs", false, function(v)
    S.ESPOrbs = v; if not v then clearESP("Orb") end
end)
W.Toggle(ESPTab, "ESP Gems", false, function(v)
    S.ESPGems = v; if not v then clearESP("Gem") end
end)
W.Toggle(ESPTab, "ESP Crystals", false, function(v)
    S.ESPCrystals = v; if not v then clearESP("Crystal") end
end)
W.Toggle(ESPTab, "ESP Chests", false, function(v)
    S.ESPChests = v; if not v then clearESP("Chest") end
end)
W.Toggle(ESPTab, "ESP Hoops", false, function(v)
    S.ESPHoops = v; if not v then clearESP("Hoop") end
end)
W.Toggle(ESPTab, "ESP Players", false, function(v)
    S.ESPPlayers = v; if not v then clearESP("Player") end
end)

W.Section(ESPTab, "DISPLAY")
W.Toggle(ESPTab, "Show Distance", true, function(v) S.ESPDistance = v end)
W.Toggle(ESPTab, "Player Tracers", false, function(v)
    S.ESPTracers = v; if not v then clearESP("Tracer") end
end)
W.Toggle(ESPTab, "Box Highlights", false, function(v)
    S.ESPBoxes = v; if not v then clearESP("Box") end
end)
W.Slider(ESPTab, "Max Distance", 100, 2000, 800, function(v) S.ESPMaxDist = v end)

W.Section(ESPTab, "INFO")
local espInfo = W.Paragraph(ESPTab, "", 62)

-- ── SETTINGS ─────────────────────────────────────────────────────────────
W.Section(SettingsTab, "APPEARANCE")
W.Dropdown(SettingsTab, "Theme", ThemeOrder, "Cyan", function(v)
    S.Theme = v
    notify("Theme", "Set to " .. v .. ". Reload to apply fully.", 4)
end)
W.Slider(SettingsTab, "UI Scale", 70, 150, 100, function(v)
    S.Scale = v
    if UI.ScaleObj then UI.ScaleObj.Scale = v/100 end
end)
W.Toggle(SettingsTab, "Mobile Toggle Button", true, function(v)
    S.MobileButton = v
    if v then MobileInit() else MobileDestroy() end
end)

W.Section(SettingsTab, "CONTROLS")
W.Keybind(SettingsTab, "GUI Toggle Key", "RightShift", function(v) S.ToggleKey = v end)
W.Toggle(SettingsTab, "Notifications", true, function(v) S.Notifications = v end)
W.Toggle(SettingsTab, "Performance Mode", false, function(v)
    S.PerformanceMode = v
    if v then
        S.ESPTracers = false
        S.ESPBoxes = false
        clearESP("Tracer")
        clearESP("Box")
    end
end)

W.Section(SettingsTab, "CONFIGURATION")
W.Button(SettingsTab, "Save Config", function()
    local save = {}
    for k, v in pairs(S) do
        if type(v) == "boolean" or type(v) == "number" or type(v) == "string" then
            save[k] = v
        end
    end
    pcall(function()
        writefile("LaxissTM_v4_config.json", HttpService:JSONEncode(save))
    end)
    notify("Config", "Saved.", 3, T().Success)
end)
W.Button(SettingsTab, "Load Config", function()
    pcall(function()
        local d = HttpService:JSONDecode(readfile("LaxissTM_v4_config.json"))
        for k, v in pairs(d) do
            if S[k] ~= nil then S[k] = v end
        end
        local h = getHum()
        if h then
            h.WalkSpeed = S.WalkSpeed
            h.JumpPower = S.JumpPower
            h.UseJumpPower = true
        end
        if UI.ScaleObj then UI.ScaleObj.Scale = S.Scale/100 end
    end)
    notify("Config", "Loaded. Re-apply toggles as needed.", 4, T().Success)
end)
W.Button(SettingsTab, "Reset Config", function()
    pcall(function()
        if isfile and isfile("LaxissTM_v4_config.json") then
            delfile("LaxissTM_v4_config.json")
        end
    end)
    notify("Config", "Config deleted.", 3, T().Warn)
end)

W.Section(SettingsTab, "DANGER ZONE")
W.Button(SettingsTab, "Disable Everything (Panic)", function()
    for k, v in pairs(S) do
        if type(v) == "boolean" and k ~= "Notifications" then
            S[k] = false
        end
    end
    for _, cat in ipairs({"Orb","Gem","Crystal","Chest","Hoop","Player","Tracer","Box"}) do
        clearESP(cat)
    end
    notify("Panic", "All features disabled.", 4, T().Danger)
end, T().Danger)
W.Button(SettingsTab, "Unload Script", function()
    S.Unloaded = true
    pcall(function()
        if UI.Gui then UI.Gui:Destroy() end
        if MobileGui then MobileGui:Destroy() end
    end)
    print("[LaxissTM] unloaded.")
end, T().Danger)

-- ── CREDITS ──────────────────────────────────────────────────────────────
W.Section(CreditsTab, "LAXISSTM v4 — REFORGED")
W.Paragraph(CreditsTab,
    "Full-feature Legends of Speed hub. Custom UI, no dependencies, no key. "
    .. "Crystal opener matches the live signature used by LoS Ultimate, SP Hub "
    .. "and every working pastebin: openCrystalRemote:InvokeServer(\"openCrystal\", location).", 62)

W.Section(CreditsTab, "EXECUTORS")
W.Paragraph(CreditsTab,
    "Synapse X · KRNL · Fluxus · Delta · Solara · Xeno · Wave · MacSploit "
    .. "· AWP · Codex · Opiumware · Vega X · Velocity", 44)

W.Section(CreditsTab, "REMOTE REFERENCE")
W.Paragraph(CreditsTab,
    "orbEvent:FireServer(\"collectOrb\", orbType, location)\n"
    .. "rebirthEvent:FireServer(\"rebirthRequest\")\n"
    .. "openCrystalRemote:InvokeServer(\"openCrystal\", location)\n"
    .. "globalFunctions.calculateRequiredRebirthLevel(mult - 1)\n"
    .. "Workspace.Hoops · LocalPlayer.level · LocalPlayer.rebirthMultiplier", 92)

W.Section(CreditsTab, "CHANGELOG")
W.Paragraph(CreditsTab,
    "v4 — Corrected crystal signature (location arg, client loop, 500ms). "
    .. "Cached ESP scans, dynamic anti-kick, notification queue, instant collect, "
    .. "redeem codes, panic/unload, animated UI.\n"
    .. "v3 — 8 tabs, pets, chests, gifts, waypoints, tracers, config.\n"
    .. "v2 — Themes, mobile button, server hop.\n"
    .. "v1 — Initial farm build.", 96)

-- ============================================================================
-- ESP IMPLEMENTATION  (cached)
-- ============================================================================
ESPFolder = new("Folder", {Name="LaxissESP", Parent=UI.Gui})

local function mkBB(ador, text, color)
    local bb = new("BillboardGui", {
        Size=UDim2.fromOffset(140,24), StudsOffset=Vector3.new(0,3,0),
        AlwaysOnTop=true, Adornee=ador, Parent=ESPFolder,
    })
    local lbl = new("TextLabel", {
        Name="Lbl", Size=UDim2.fromScale(1,1), BackgroundTransparency=1,
        Text=text, TextColor3=color, Font=Enum.Font.GothamBold, TextSize=11,
        TextStrokeTransparency=0.4, TextStrokeColor3=Color3.new(0,0,0),
        Parent=bb,
    })
    return bb, lbl
end

local function mkBox(part, color)
    return new("BoxHandleAdornment", {
        Size=part.Size + Vector3.new(0.2,0.2,0.2), AlwaysOnTop=true,
        ZIndex=5, Transparency=0.65, Color3=color, Adornee=part,
        Parent=ESPFolder,
    })
end

local function distTo(part)
    local r = getRoot()
    if not r or not part then return 0 end
    return math.floor((r.Position - part.Position).Magnitude)
end

-- rescan cached parts every 3s instead of every frame
local function rescanCache()
    local orbs, crystals, chests, hoops = {}, {}, {}, {}
    for _, o in ipairs(Workspace:GetDescendants()) do
        if o:IsA("BasePart") then
            local n = o.Name:lower()
            if n:find("orb") or n:find("gem") then orbs[#orbs+1] = o end
            if n:find("crystal") then crystals[#crystals+1] = o end
            if n:find("chest") or n:find("gift") then chests[#chests+1] = o end
        end
    end
    local hf = Workspace:FindFirstChild("Hoops")
    if hf then
        for _, o in ipairs(hf:GetChildren()) do
            if o:IsA("BasePart") then hoops[#hoops+1] = o end
        end
    end
    S.CachedParts = {Orbs=orbs, Crystals=crystals, Chests=chests, Hoops=hoops}
    S.CacheStamp = os.clock()
end

local function ensureBB(part, category, base, color)
    if S.ESPObjects[part] then return S.ESPObjects[part] end
    local bb, lbl = mkBB(part, base, color)
    local entry = {Category=category, Billboard=bb, Label=lbl, Base=base, Part=part}
    S.ESPObjects[part] = entry
    return entry
end

local function updateESPLabels()
    for key, entry in pairs(S.ESPObjects) do
        if entry.Label and entry.Part and entry.Part.Parent then
            local d = distTo(entry.Part)
            if d > S.ESPMaxDist then
                entry.Billboard.Enabled = false
            else
                entry.Billboard.Enabled = true
                entry.Label.Text = S.ESPDistance
                    and (entry.Base .. " [" .. d .. "m]")
                    or entry.Base
            end
        elseif entry.Billboard then
            entry.Billboard:Destroy()
            if entry.Box then entry.Box:Destroy() end
            S.ESPObjects[key] = nil
        end
    end
end

local function updateESPObjects()
    local cache = S.CachedParts
    if not cache.Orbs then return end

    if S.ESPOrbs then
        for _, p in ipairs(cache.Orbs) do
            ensureBB(p, "Orb", p.Name, Color3.fromRGB(255,220,100))
        end
    end
    if S.ESPGems then
        for _, p in ipairs(cache.Orbs) do
            if p.Name:lower():find("gem") then
                ensureBB(p, "Gem", "Gem", Color3.fromRGB(120,255,180))
            end
        end
    end
    if S.ESPCrystals then
        for _, p in ipairs(cache.Crystals) do
            ensureBB(p, "Crystal", "Crystal", Color3.fromRGB(120,230,255))
        end
    end
    if S.ESPChests then
        for _, p in ipairs(cache.Chests) do
            ensureBB(p, "Chest", "Chest", Color3.fromRGB(255,190,80))
        end
    end
    if S.ESPHoops then
        for _, p in ipairs(cache.Hoops) do
            ensureBB(p, "Hoop", "Hoop", Color3.fromRGB(180,255,150))
        end
    end
    if S.ESPPlayers then
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character then
                local head = plr.Character:FindFirstChild("Head")
                if head and not S.ESPObjects[plr] then
                    local bb, lbl = mkBB(head, plr.Name, Color3.fromRGB(255,120,120))
                    local entry = {Category="Player", Billboard=bb, Label=lbl,
                        Base=plr.Name, Part=head}
                    if S.ESPBoxes then
                        local rp = plr.Character:FindFirstChild("HumanoidRootPart")
                        if rp then entry.Box = mkBox(rp, Color3.fromRGB(255,120,120)) end
                    end
                    S.ESPObjects[plr] = entry
                end
            end
        end
    end
end

local function updateTracers()
    if not S.ESPTracers or not Drawing then return end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local head = plr.Character:FindFirstChild("Head")
            if head then
                if not TracerLines[plr] then
                    local line = Drawing.new("Line")
                    line.Thickness = 1
                    line.Color = Color3.fromRGB(255,120,120)
                    line.Transparency = 0.55
                    TracerLines[plr] = line
                end
                local line = TracerLines[plr]
                local sp, on = Workspace.CurrentCamera:WorldToViewportPoint(head.Position)
                if on then
                    line.From = Vector2.new(
                        Workspace.CurrentCamera.ViewportSize.X/2,
                        Workspace.CurrentCamera.ViewportSize.Y)
                    line.To = Vector2.new(sp.X, sp.Y)
                    line.Visible = true
                else
                    line.Visible = false
                end
            end
        end
    end
end

-- ============================================================================
-- GAME LOOPS
-- ============================================================================

-- orbs (remote)
task.spawn(function()
    while task.wait(0.1) do
        if S.Unloaded then break end
        if S.AutoOrbs then
            fireOrb(S.OrbType, getPlace(), S.OrbMulti)
            S.OrbsCollected = S.OrbsCollected + S.OrbMulti
        end
    end
end)

-- instant collect x10k  (LoS Ultimate pattern)
task.spawn(function()
    while task.wait(0.1) do
        if S.Unloaded then break end
        if S.InstantCollect then
            local loc = getPlace()
            for _ = 1, 100 do
                pcall(function()
                    orbEvent:FireServer("collectOrb", S.OrbType, loc)
                end)
            end
            S.OrbsCollected = S.OrbsCollected + 10000
        end
    end
end)

-- gems
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

-- orb touch
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

-- orb magnet
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

-- chests
task.spawn(function()
    while task.wait(0.3) do
        if S.Unloaded then break end
        if S.AutoChests then
            local r = getRoot()
            if r then
                for _, c in ipairs(S.CachedParts.Chests or {}) do
                    pcall(function()
                        firetouchinterest(r, c, 0)
                        task.wait()
                        firetouchinterest(r, c, 1)
                    end)
                    S.ChestsOpened = S.ChestsOpened + 1
                end
            end
        end
    end
end)

-- hoops
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

-- hoop magnet
task.spawn(function()
    while task.wait(0.1) do
        if S.Unloaded then break end
        if S.HoopMagnet then
            local r = getRoot()
            if r then
                for _, hoop in ipairs(S.CachedParts.Hoops or {}) do
                    pcall(function() hoop.CFrame = r.CFrame end)
                end
            end
        end
    end
end)

-- rebirth
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

-- race checkpoints
task.spawn(function()
    while task.wait(0.2) do
        if S.Unloaded then break end
        if S.AutoWinRace then
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
                    pcall(function() r.CFrame = cp.CFrame; task.wait(0.1) end)
                end
                S.RacesWon = S.RacesWon + 1
            end
        end
    end
end)

-- join / leave race
task.spawn(function()
    while task.wait(2) do
        if S.Unloaded then break end
        if S.AutoJoinRace or S.AutoLeaveRace then
            local remote = rEvents and (rEvents:FindFirstChild("raceEvent")
                or rEvents:FindFirstChild("joinRace"))
            if remote then
                pcall(function()
                    if remote:IsA("RemoteFunction") then
                        remote:InvokeServer(S.AutoJoinRace and "join" or "leave")
                    else
                        remote:FireServer(S.AutoJoinRace and "join" or "leave")
                    end
                end)
            end
        end
    end
end)

-- quest / steps
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

-- gifts
task.spawn(function()
    while task.wait(3) do
        if S.Unloaded then break end
        if S.AutoGifts then
            for i = 1, 8 do
                fireGift(i)
                task.wait(0.1)
            end
        end
    end
end)

-- parkour floor
task.spawn(function()
    while task.wait(0.5) do
        if S.Unloaded then break end
        if S.AutoParkour then
            local h = getHum()
            if h then
                h:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
                h:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
            end
        end
    end
end)

-- AUTO HATCH  (the corrected crystal loop)
task.spawn(function()
    while task.wait(S.FastOpen and 0.1 or S.CrystalDelay) do
        if S.Unloaded then break end
        if S.AutoHatch then
            local ok = openCrystal(S.CrystalLocation)
            if ok then
                S.CrystalsOpened = S.CrystalsOpened + 1
            else
                task.wait(1)
            end
        end
    end
end)

-- auto equip best
task.spawn(function()
    while task.wait(5) do
        if S.Unloaded then break end
        if S.AutoEquipBest then
            local inv = LocalPlayer:FindFirstChild("Inventory")
            if inv then
                local best, bestVal = nil, -1
                for _, pet in ipairs(inv:GetDescendants()) do
                    if pet:IsA("StringValue") or pet:IsA("Folder") then
                        local p = pet:FindFirstChild("Power") or pet:FindFirstChild("Level")
                        local v = p and tonumber(p.Value) or 0
                        if v > bestVal then bestVal = v; best = pet end
                    end
                end
                if best then
                    local remote = rEvents and (rEvents:FindFirstChild("equipPet")
                        or rEvents:FindFirstChild("petEvent"))
                    if remote then
                        pcall(function()
                            if remote:IsA("RemoteFunction") then
                                remote:InvokeServer("equip", best.Name)
                            else
                                remote:FireServer("equip", best.Name)
                            end
                        end)
                    end
                end
            end
        end
    end
end)

-- auto evolve
task.spawn(function()
    while task.wait(3) do
        if S.Unloaded then break end
        if S.AutoEvolve then
            local remote = rEvents and (rEvents:FindFirstChild("evolvePet")
                or rEvents:FindFirstChild("evolve"))
            if remote then
                pcall(function()
                    if remote:IsA("RemoteFunction") then
                        remote:InvokeServer("evolveAll")
                    else
                        remote:FireServer("evolveAll")
                    end
                end)
            end
        end
    end
end)

-- ============================================================================
-- PLAYER LOOPS
-- ============================================================================
UserInputService.JumpRequest:Connect(function()
    if S.InfJump then
        local h = getHum(); if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
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

-- dynamic anti-kick
local function applyAntiKick()
    if S.NamecallHooked then return end
    pcall(function()
        local mt = getrawmetatable(game)
        if not mt or not setreadonly then return end
        setreadonly(mt, false)
        local old = mt.__namecall
        mt.__namecall = newcclosure(function(self, ...)
            if getnamecallmethod() == "Kick" and self == LocalPlayer then
                return
            end
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

-- fly / noclip / auto jump / anti-ragdoll / anti-void
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
                S.FlyBG.P = 3000; S.FlyBG.D = 200
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
    if S.AutoJump then
        local h = getHum(); if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
    if S.AntiRagdoll then
        local h = getHum()
        if h and h:GetState() == Enum.HumanoidStateType.FallingDown then
            h:ChangeState(Enum.HumanoidStateType.Running)
        end
    end
    if S.AntiVoid and hr and hr.Position.Y < -50 then
        local sp = Workspace:FindFirstChildOfClass("SpawnLocation")
        if sp then hr.CFrame = sp.CFrame + Vector3.new(0,6,0) end
    end
end)

-- ============================================================================
-- UI UPDATE LOOP
-- ============================================================================
task.spawn(function()
    local lastCache = 0
    local frames, fpsClock = 0, os.clock()
    RunService.RenderStepped:Connect(function()
        frames = frames + 1
        local now = os.clock()
        if now - fpsClock >= 1 then
            S.FPS = math.floor(frames / (now - fpsClock) + 0.5)
            frames = 0; fpsClock = now
        end
    end)

    while task.wait(0.5) do
        if S.Unloaded then break end

        if os.clock() - lastCache > 3 then
            rescanCache()
            lastCache = os.clock()
        end

        updateESPObjects()
        updateESPLabels()
        updateTracers()

        local tracked = 0
        for _ in pairs(S.ESPObjects) do tracked = tracked + 1 end

        farmStats.Text = string.format(
            "Session: %s\nOrbs: %s   Gems: %s\nChests: %s   Rebirths: %s",
            fmtTime(os.time() - S.SessionStart),
            fmtNum(S.OrbsCollected), fmtNum(S.GemsCollected),
            fmtNum(S.ChestsOpened), fmtNum(S.RebirthsDone))

        crystalStats.Text = string.format(
            "Crystals opened: %s\nAuto hatch: %s   Fast open: %s\nCurrent area: %s",
            fmtNum(S.CrystalsOpened),
            S.AutoHatch and "ON" or "OFF",
            S.FastOpen and "ON" or "OFF",
            S.CrystalLocation)

        espInfo.Text = string.format(
            "Tracked: %d   Max range: %dm\nTracers: %s   Boxes: %s\nCached orbs: %d   hoops: %d",
            tracked, S.ESPMaxDist,
            S.ESPTracers and (Drawing and "ON" or "N/A") or "OFF",
            S.ESPBoxes and "ON" or "OFF",
            #(S.CachedParts.Orbs or {}), #(S.CachedParts.Hoops or {}))

        local lv, mu = getLevel(), getMult()
        statusLeft.Text = string.format(
            "Level %s  ·  ×%s  ·  %s",
            tostring(lv or "?"), tostring(mu or "?"), S.Theme)
        statusRight.Text = string.format(
            "%d FPS  ·  %s  ·  %s",
            S.FPS,
            S.CachedParts.Orbs and (#S.CachedParts.Orbs .. " orbs") or "—",
            fmtTime(os.time() - S.SessionStart))

        pcall(function()
            local ping = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()
            S.Ping = math.floor(ping)
        end)
    end
end)

-- ============================================================================
-- CHARACTER RESPAWN
-- ============================================================================
LocalPlayer.CharacterAdded:Connect(function(char)
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
MobileGui = nil
MobileBtn = nil

function MobileInit()
    if MobileGui and MobileGui.Parent then return end
    MobileGui = new("ScreenGui", {
        Name="LaxissMobile", ResetOnSpawn=false, IgnoreGuiInset=true,
        DisplayOrder=1000, Parent=CoreGui,
    })
    MobileBtn = new("Frame", {
        Size=UDim2.fromOffset(54,54), Position=UDim2.new(1,-78,0.5,-27),
        BackgroundColor3=T().Accent, BorderSizePixel=0, Active=true,
        Parent=MobileGui,
    })
    corner(27, MobileBtn)
    stroke(T().AccentEnd, 2, MobileBtn)

    new("TextLabel", {
        Size=UDim2.fromScale(1,1), BackgroundTransparency=1, Text="Lx",
        TextColor3=T().OnAccent, Font=Enum.Font.GothamBlack, TextSize=16,
        Parent=MobileBtn,
    })

    local dragS, startP
    MobileBtn.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
            or i.UserInputType == Enum.UserInputType.Touch then
            dragS = i.Position; startP = MobileBtn.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dragS and (i.UserInputType == Enum.UserInputType.MouseMovement
            or i.UserInputType == Enum.UserInputType.Touch) then
            local d = i.Position - dragS
            MobileBtn.Position = UDim2.new(
                startP.X.Scale, startP.X.Offset + d.X,
                startP.Y.Scale, startP.Y.Offset + d.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
            or i.UserInputType == Enum.UserInputType.Touch then
            dragS = nil
        end
    end)

    local pressT, pressP
    MobileBtn.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
            or i.UserInputType == Enum.UserInputType.Touch then
            pressT = os.clock(); pressP = i.Position
        end
    end)
    MobileBtn.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
            or i.UserInputType == Enum.UserInputType.Touch then
            if pressT and (os.clock() - pressT) < 0.3
                and (i.Position - pressP).Magnitude < 10 then
                UI.Gui.Enabled = not UI.Gui.Enabled
                if UI.Gui.Enabled then UI.Window.Visible = true end
            end
        end
    end)
end

function MobileShow()
    if MobileBtn and MobileBtn.Parent then MobileBtn.Visible = true end
end

function MobileDestroy()
    if MobileGui then MobileGui:Destroy(); MobileGui = nil; MobileBtn = nil end
end

-- ============================================================================
-- KEYBINDS
-- ============================================================================
UserInputService.InputBegan:Connect(function(i, proc)
    if proc then return end
    if i.UserInputType ~= Enum.UserInputType.Keyboard then return end
    if i.KeyCode.Name == S.ToggleKey then
        UI.Gui.Enabled = not UI.Gui.Enabled
        if UI.Gui.Enabled then UI.Window.Visible = true end
    end
end)

-- ============================================================================
-- BOOT
-- ============================================================================
selectTab("Farming")
rescanCache()

if S.MobileButton then MobileInit() end
if UI.ScaleObj then UI.ScaleObj.Scale = S.Scale/100 end

-- rail labels start hidden until hover
for _, btn in pairs(UI.TabButtons) do
    local lbl = btn:FindFirstChild("Label")
    if lbl then lbl.TextTransparency = 1 end
end

notify("LaxissTM v4", "Reforged loaded. " .. S.ToggleKey .. " to toggle.", 5, T().Success)

print("[LaxissTM] v4.0.0 Reforged loaded.")
print("[LaxissTM] Crystal remote: " .. tostring(openCrystalRemote ~= nil)
    .. "  |  orbEvent: " .. tostring(orbEvent ~= nil)
    .. "  |  rebirthEvent: " .. tostring(rebirthEvent ~= nil))
print("[LaxissTM] Crystal signature: openCrystalRemote:InvokeServer(\"openCrystal\", location)")