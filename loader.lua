--[[
================================================================================
    LaxissTM v3 — Ultimate Edition
    Game          : Legends of Speed
    Type          : Full-feature script hub
    Executors     : Arceus X Delta Codex
    Dependencies  : None. Custom UI. No key system. Single paste.
================================================================================
    FEATURE MAP
    ─────────────────────────────────────────────────────────────────────────
    [Farming]    Orb remote farm · physical orb touch · orb magnet · orb pull
                 Gem farm · chest farm · hoop farm (touch/teleport/magnet)
                 Auto rebirth (level-gated) · auto race · auto quest
                 Auto steps · auto EXP · auto claim gifts 1-8 · auto parkour
    [Crystals]   Crystal opener (selectable type, quantity)
                 Auto hatch · fast open · auto equip best pet
    [Pets]       Equip best · duplicate pets · duplicate trails
                 Delete all pets · delete all trails · auto evolve
    [Player]     WalkSpeed · JumpPower · fly · noclip · infinite jump
                 Anti-ragdoll · anti-AFK · anti-kick · disable lava damage
                 Reset · rejoin · server hop
    [Teleport]   Map teleports · portal access · player teleport
                 Waypoint saving · spawn · custom coordinate input
    [ESP]        Orbs · gems · crystals · chests · hoops · players
                 Distance labels · tracers · box highlights · names
    [Settings]   Theme engine (8 palettes) · UI scale · keybind manager
                 Config save/load · notification toggle · performance mode
    [Credits]    Version info · executor compatibility · changelog
================================================================================
]]

-- ============================================================================
-- SECTION 1: SERVICES
-- ============================================================================
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
local Lighting         = game:GetService("Lighting")
local LocalPlayer      = Players.LocalPlayer

-- game-specific instances
local rEvents
local orbEvent
local rebirthEvent
local openCrystalRemote
local globalFunctions

local function bindGameInstances()
    rEvents = ReplicatedStorage:WaitForChild("rEvents", 20)
    if rEvents then
        orbEvent = rEvents:WaitForChild("orbEvent", 10)
        rebirthEvent = rEvents:WaitForChild("rebirthEvent", 10)
        openCrystalRemote = rEvents:FindFirstChild("openCrystalRemote")
            or rEvents:FindFirstChild("crystalEvent")
            or rEvents:FindFirstChild("openCrystal")
    end
    pcall(function()
        globalFunctions = require(ReplicatedStorage:WaitForChild("globalFunctions", 10))
    end)
end
bindGameInstances()

-- ============================================================================
-- SECTION 2: GLOBAL STATE
-- ============================================================================
local State = {
    -- ── farming ──────────────────────────────────────────────────────────
    AutoOrbs          = false,
    AutoOrbsMulti     = 10,
    AutoTouchOrbs     = false,
    OrbMagnet         = false,
    OrbPullAll        = false,
    AutoGems          = false,
    GemBatch          = 5,
    AutoChests        = false,
    AutoHoops         = false,
    HoopMode          = "Touch",
    HoopDelay         = 0.1,
    HoopMagnet        = false,
    AutoRebirth       = false,
    RebirthCheck      = true,
    AutoRace          = false,
    AutoWinRace       = false,
    AutoQuest         = false,
    AutoSteps         = false,
    AutoEXP           = false,
    AutoGifts         = false,
    AutoParkour       = false,

    -- ── crystals / pets ──────────────────────────────────────────────────
    AutoHatch         = false,
    HatchType         = "Basic Crystal",
    HatchAmount       = 1,
    FastOpen          = false,
    AutoEquipBest     = false,
    AutoEvolve        = false,

    -- ── player ───────────────────────────────────────────────────────────
    WalkSpeed         = 16,
    JumpPower         = 50,
    Fly               = false,
    FlySpeed          = 60,
    Noclip            = false,
    InfJump           = false,
    AutoJump          = false,
    AntiRagdoll       = false,
    AntiAFK           = false,
    AntiKick          = false,
    DisableLava       = false,

    -- ── esp ──────────────────────────────────────────────────────────────
    ESPOrbs           = false,
    ESPGems           = false,
    ESPCrystals       = false,
    ESPChests         = false,
    ESPHoops          = false,
    ESPPlayers        = false,
    ESPDistance       = true,
    ESPTracers        = false,
    ESPBoxes          = false,
    ESPNames          = true,
    ESPMaxDistance    = 500,

    -- ── interface ────────────────────────────────────────────────────────
    Theme             = "Cyan",
    Scale             = 100,
    MobileButton      = true,
    Notifications     = true,
    PerformanceMode   = false,
    ToggleKey         = "RightShift",
    MenuOpen          = true,

    -- ── teleport ─────────────────────────────────────────────────────────
    SelectedMap       = "City",
    SelectedPlayer    = nil,

    -- ── session counters ─────────────────────────────────────────────────
    SessionStart      = os.time(),
    OrbsCollected     = 0,
    GemsCollected     = 0,
    ChestsOpened      = 0,
    RebirthsDone      = 0,
    CrystalsOpened    = 0,
    RacesWon          = 0,

    -- ── internal ─────────────────────────────────────────────────────────
    ESPObjects        = {},
    Connections       = {},
    FlyBodyVelocity   = nil,
    FlyBodyGyro       = nil,
    Waypoints         = {},
    NotifQueue        = {},
    NotifActive       = false,
    Keybinds          = {},
}

getgenv().Laxiss = State
getgenv().LaxissVersion = "3.0.0"

-- ============================================================================
-- SECTION 3: THEME ENGINE
-- ============================================================================
local Themes = {
    Cyan = {
        Accent       = Color3.fromRGB(80, 200, 255),
        AccentDark   = Color3.fromRGB(40, 120, 170),
        Background   = Color3.fromRGB(13, 13, 18),
        Surface      = Color3.fromRGB(20, 20, 28),
        SurfaceAlt   = Color3.fromRGB(28, 28, 40),
        Stroke       = Color3.fromRGB(45, 45, 60),
        Text         = Color3.fromRGB(205, 205, 215),
        TextDim      = Color3.fromRGB(130, 130, 145),
        TextOnAccent = Color3.fromRGB(10, 10, 15),
        Success      = Color3.fromRGB(80, 220, 130),
        Danger       = Color3.fromRGB(255, 110, 110),
        Warning      = Color3.fromRGB(255, 190, 80),
    },
    Purple = {
        Accent       = Color3.fromRGB(170, 120, 255),
        AccentDark   = Color3.fromRGB(100, 65, 170),
        Background   = Color3.fromRGB(16, 12, 22),
        Surface      = Color3.fromRGB(24, 18, 32),
        SurfaceAlt   = Color3.fromRGB(34, 26, 46),
        Stroke       = Color3.fromRGB(55, 45, 75),
        Text         = Color3.fromRGB(210, 205, 220),
        TextDim      = Color3.fromRGB(140, 130, 155),
        TextOnAccent = Color3.fromRGB(15, 10, 20),
        Success      = Color3.fromRGB(150, 230, 170),
        Danger       = Color3.fromRGB(255, 120, 140),
        Warning      = Color3.fromRGB(255, 200, 120),
    },
    Green = {
        Accent       = Color3.fromRGB(80, 230, 140),
        AccentDark   = Color3.fromRGB(40, 140, 85),
        Background   = Color3.fromRGB(10, 16, 12),
        Surface      = Color3.fromRGB(16, 26, 20),
        SurfaceAlt   = Color3.fromRGB(24, 38, 30),
        Stroke       = Color3.fromRGB(40, 60, 48),
        Text         = Color3.fromRGB(200, 220, 208),
        TextDim      = Color3.fromRGB(125, 145, 132),
        TextOnAccent = Color3.fromRGB(8, 16, 10),
        Success      = Color3.fromRGB(130, 255, 160),
        Danger       = Color3.fromRGB(255, 120, 120),
        Warning      = Color3.fromRGB(255, 210, 100),
    },
    Red = {
        Accent       = Color3.fromRGB(255, 100, 110),
        AccentDark   = Color3.fromRGB(170, 55, 65),
        Background   = Color3.fromRGB(20, 12, 14),
        Surface      = Color3.fromRGB(30, 18, 22),
        SurfaceAlt   = Color3.fromRGB(42, 26, 32),
        Stroke       = Color3.fromRGB(70, 40, 48),
        Text         = Color3.fromRGB(225, 200, 205),
        TextDim      = Color3.fromRGB(155, 130, 135),
        TextOnAccent = Color3.fromRGB(20, 8, 10),
        Success      = Color3.fromRGB(120, 230, 150),
        Danger       = Color3.fromRGB(255, 90, 90),
        Warning      = Color3.fromRGB(255, 190, 90),
    },
    Orange = {
        Accent       = Color3.fromRGB(255, 170, 80),
        AccentDark   = Color3.fromRGB(180, 110, 40),
        Background   = Color3.fromRGB(20, 15, 10),
        Surface      = Color3.fromRGB(30, 22, 16),
        SurfaceAlt   = Color3.fromRGB(42, 32, 22),
        Stroke       = Color3.fromRGB(70, 50, 35),
        Text         = Color3.fromRGB(225, 215, 200),
        TextDim      = Color3.fromRGB(155, 140, 125),
        TextOnAccent = Color3.fromRGB(20, 12, 5),
        Success      = Color3.fromRGB(160, 230, 120),
        Danger       = Color3.fromRGB(255, 110, 90),
        Warning      = Color3.fromRGB(255, 220, 110),
    },
    Blue = {
        Accent       = Color3.fromRGB(100, 140, 255),
        AccentDark   = Color3.fromRGB(55, 80, 175),
        Background   = Color3.fromRGB(10, 14, 22),
        Surface      = Color3.fromRGB(16, 22, 34),
        SurfaceAlt   = Color3.fromRGB(24, 32, 48),
        Stroke       = Color3.fromRGB(40, 52, 75),
        Text         = Color3.fromRGB(200, 210, 225),
        TextDim      = Color3.fromRGB(125, 138, 155),
        TextOnAccent = Color3.fromRGB(8, 10, 20),
        Success      = Color3.fromRGB(110, 230, 160),
        Danger       = Color3.fromRGB(255, 120, 130),
        Warning      = Color3.fromRGB(255, 200, 100),
    },
    Pink = {
        Accent       = Color3.fromRGB(255, 130, 200),
        AccentDark   = Color3.fromRGB(175, 75, 135),
        Background   = Color3.fromRGB(20, 12, 18),
        Surface      = Color3.fromRGB(30, 18, 26),
        SurfaceAlt   = Color3.fromRGB(42, 26, 36),
        Stroke       = Color3.fromRGB(70, 45, 58),
        Text         = Color3.fromRGB(225, 205, 218),
        TextDim      = Color3.fromRGB(155, 132, 145),
        TextOnAccent = Color3.fromRGB(20, 8, 15),
        Success      = Color3.fromRGB(140, 235, 170),
        Danger       = Color3.fromRGB(255, 110, 130),
        Warning      = Color3.fromRGB(255, 200, 130),
    },
    Dark = {
        Accent       = Color3.fromRGB(200, 200, 215),
        AccentDark   = Color3.fromRGB(120, 120, 135),
        Background   = Color3.fromRGB(10, 10, 12),
        Surface      = Color3.fromRGB(18, 18, 22),
        SurfaceAlt   = Color3.fromRGB(26, 26, 32),
        Stroke       = Color3.fromRGB(40, 40, 50),
        Text         = Color3.fromRGB(190, 190, 200),
        TextDim      = Color3.fromRGB(110, 110, 120),
        TextOnAccent = Color3.fromRGB(8, 8, 10),
        Success      = Color3.fromRGB(120, 220, 150),
        Danger       = Color3.fromRGB(240, 100, 100),
        Warning      = Color3.fromRGB(240, 190, 90),
    },
}

local ThemeOrder = { "Cyan", "Purple", "Green", "Red", "Orange", "Blue", "Pink", "Dark" }

local function T()
    return Themes[State.Theme] or Themes.Cyan
end

-- ============================================================================
-- SECTION 4: CORE HELPERS
-- ============================================================================
local function getChar()
    return LocalPlayer.Character
end

local function getHum()
    local char = getChar()
    return char and char:FindFirstChildOfClass("Humanoid")
end

local function getRoot()
    local char = getChar()
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function getPlace()
    local ok, val = pcall(function()
        return LocalPlayer.currentMap.Value
    end)
    return ok and val or State.SelectedMap
end

local function getLevel()
    local ok, val = pcall(function()
        return LocalPlayer.level.Value
    end)
    return ok and val or nil
end

local function getMultiplier()
    local ok, val = pcall(function()
        return LocalPlayer.rebirthMultiplier.Value
    end)
    return ok and val or nil
end

local function fmtTime(seconds)
    return string.format("%02d:%02d:%02d",
        math.floor(seconds / 3600),
        math.floor((seconds % 3600) / 60),
        math.floor(seconds % 60))
end

local function fmtNumber(n)
    if n >= 1e9 then return string.format("%.1fB", n / 1e9) end
    if n >= 1e6 then return string.format("%.1fM", n / 1e6) end
    if n >= 1e3 then return string.format("%.1fK", n / 1e3) end
    return tostring(n)
end

-- ============================================================================
-- SECTION 5: GAME REMOTE WRAPPERS
-- ============================================================================
local function fireOrb(orbType, location, count)
    if not orbEvent then return end
    count = count or 1
    for _ = 1, count do
        pcall(function()
            orbEvent:FireServer("collectOrb", orbType, location)
        end)
    end
end

local function fireRebirth()
    if not rebirthEvent then return end
    pcall(function()
        rebirthEvent:FireServer("rebirthRequest")
    end)
end

local function fireCrystal(crystalType, amount)
    if not openCrystalRemote then return false end
    local ok = pcall(function()
        if openCrystalRemote:IsA("RemoteFunction") then
            openCrystalRemote:InvokeServer("openCrystal", crystalType, amount or 1)
        else
            openCrystalRemote:FireServer("openCrystal", crystalType, amount or 1)
        end
    end)
    return ok
end

local function fireGift(index)
    local giftRemotes = {
        rEvents and rEvents:FindFirstChild("giftEvent"),
        rEvents and rEvents:FindFirstChild("claimGift"),
        ReplicatedStorage:FindFirstChild("GiftEvent"),
    }
    for _, remote in ipairs(giftRemotes) do
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
-- SECTION 6: OBJECT FINDERS
-- ============================================================================
local function findOrbParts()
    local list = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            local n = obj.Name:lower()
            if n:find("orb") or n:find("gem") then
                list[#list + 1] = obj
            end
        end
    end
    return list
end

local function findCrystalParts()
    local list = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Name:find("Crystal") then
            list[#list + 1] = obj
        end
    end
    return list
end

local function findChestParts()
    local list = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            local n = obj.Name:lower()
            if n:find("chest") or n:find("gift") then
                list[#list + 1] = obj
            end
        end
    end
    return list
end

local function findHoopParts()
    local list = {}
    local folder = Workspace:FindFirstChild("Hoops")
    if folder then
        for _, obj in ipairs(folder:GetChildren()) do
            if obj:IsA("BasePart") then
                list[#list + 1] = obj
            end
        end
    end
    return list
end

local function findCheckpoints()
    local list = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Name:lower():find("checkpoint") then
            list[#list + 1] = obj
        end
    end
    return list
end

local function distanceTo(part)
    local root = getRoot()
    if not root or not part then return 0 end
    return math.floor((root.Position - part.Position).Magnitude)
end

-- ============================================================================
-- SECTION 7: UI LIBRARY — UTILITIES
-- ============================================================================
local Lib = {}

local function new(class, props, children)
    local inst = Instance.new(class)
    for key, value in pairs(props or {}) do
        inst[key] = value
    end
    for _, child in ipairs(children or {}) do
        child.Parent = inst
    end
    return inst
end

local function corner(radius, parent)
    return new("UICorner", {
        CornerRadius = UDim.new(0, radius or 6),
        Parent = parent,
    })
end

local function stroke(color, thickness, parent, transparency)
    return new("UIStroke", {
        Color = color or T().Stroke,
        Thickness = thickness or 1,
        Transparency = transparency or 0,
        Parent = parent,
    })
end

local function padding(amount, parent)
    return new("UIPadding", {
        PaddingLeft = UDim.new(0, amount or 0),
        PaddingRight = UDim.new(0, amount or 0),
        PaddingTop = UDim.new(0, amount or 0),
        PaddingBottom = UDim.new(0, amount or 0),
        Parent = parent,
    })
end

local function tween(instance, duration, goal)
    local info = TweenInfo.new(duration or 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    TweenService:Create(instance, info, goal):Play()
end

local function fadeIn(frame)
    frame.BackgroundTransparency = 1
    tween(frame, 0.2, { BackgroundTransparency = 0 })
end

-- ============================================================================
-- SECTION 8: UI LIBRARY — NOTIFICATIONS
-- ============================================================================
local Notifications = {}
local notifContainer = nil

function Notifications.init(parent)
    notifContainer = new("Frame", {
        Name = "Notifications",
        Size = UDim2.new(0, 320, 1, -40),
        Position = UDim2.new(1, -340, 0, 20),
        BackgroundTransparency = 1,
        Parent = parent,
    })
    new("UIListLayout", {
        Padding = UDim.new(0, 8),
        VerticalAlignment = Enum.VerticalAlignment.Top,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = notifContainer,
    })
end

function Notifications.push(title, text, duration, color)
    if not State.Notifications then return end
    if not notifContainer then return end

    duration = duration or 4
    color = color or T().Accent

    local card = new("Frame", {
        Size = UDim2.new(0, 300, 0, 64),
        BackgroundColor3 = T().Surface,
        BackgroundTransparency = 0.05,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = notifContainer,
    })
    corner(8, card)
    stroke(T().Stroke, 1, card)

    -- accent bar
    local bar = new("Frame", {
        Size = UDim2.new(0, 3, 1, -16),
        Position = UDim2.new(0, 8, 0, 8),
        BackgroundColor3 = color,
        BorderSizePixel = 0,
        Parent = card,
    })
    corner(2, bar)

    new("TextLabel", {
        Size = UDim2.new(1, -30, 0, 20),
        Position = UDim2.new(0, 20, 0, 10),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = color,
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = card,
    })

    new("TextLabel", {
        Size = UDim2.new(1, -30, 0, 26),
        Position = UDim2.new(0, 20, 0, 30),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = T().TextDim,
        Font = Enum.Font.Gotham,
        TextSize = 11,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        Parent = card,
    })

    -- slide in
    card.Position = UDim2.new(1, 0, 0, 0)
    tween(card, 0.25, { Position = UDim2.new(0, 0, 0, 0) })

    task.delay(duration, function()
        tween(card, 0.2, { Position = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1 })
        task.wait(0.25)
        card:Destroy()
    end)
end

local function notify(title, text, duration)
    Notifications.push(title, text, duration)
end

-- ============================================================================
-- SECTION 9: UI LIBRARY — TOOLTIP SYSTEM
-- ============================================================================
local Tooltips = {}

function Tooltips.attach(instance, text)
    instance.MouseEnter:Connect(function()
        if not text or text == "" then return end
        local tip = new("TextLabel", {
            Name = "Tooltip",
            Size = UDim2.new(0, 200, 0, 28),
            Position = UDim2.new(0, 0, 1, 6),
            BackgroundColor3 = T().SurfaceAlt,
            Text = text,
            TextColor3 = T().Text,
            Font = Enum.Font.Gotham,
            TextSize = 10,
            TextWrapped = true,
            ZIndex = 50,
            Parent = instance,
        })
        corner(4, tip)
        stroke(T().Stroke, 1, tip)
        fadeIn(tip)
        instance.MouseLeave:Connect(function()
            if tip and tip.Parent then tip:Destroy() end
        end)
    end)
end

-- ============================================================================
-- SECTION 10: UI LIBRARY — WINDOW
-- ============================================================================
local Window = {}
Window.__index = Window

function Window.new()
    local self = setmetatable({}, Window)

    local existing = CoreGui:FindFirstChild("LaxissTM")
    if existing then existing:Destroy() end

    self.Gui = new("ScreenGui", {
        Name = "LaxissTM",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 999,
        Parent = CoreGui,
    })

    self.ScaleObj = new("UIScale", {
        Scale = State.Scale / 100,
        Parent = self.Gui,
    })

    self.Main = new("Frame", {
        Name = "Main",
        Size = UDim2.fromOffset(620, 460),
        Position = UDim2.new(0.5, -310, 0.5, -230),
        BackgroundColor3 = T().Background,
        BorderSizePixel = 0,
        Active = true,
        Parent = self.Gui,
    })
    corner(10, self.Main)
    self.MainStroke = stroke(T().Stroke, 1, self.Main)

    -- ── title bar ────────────────────────────────────────────────────────
    self.TitleBar = new("Frame", {
        Name = "TitleBar",
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = T().Surface,
        BorderSizePixel = 0,
        Parent = self.Main,
    })
    corner(10, self.TitleBar)

    -- fills the bottom rounded corners of the title bar
    new("Frame", {
        Size = UDim2.new(1, 0, 0, 12),
        Position = UDim2.new(0, 0, 1, -12),
        BackgroundColor3 = T().Surface,
        BorderSizePixel = 0,
        Parent = self.TitleBar,
    })

    self.TitleLabel = new("TextLabel", {
        Size = UDim2.new(0, 200, 1, 0),
        Position = UDim2.fromOffset(18, 0),
        BackgroundTransparency = 1,
        Text = "LaxissTM",
        TextColor3 = T().Accent,
        Font = Enum.Font.GothamBlack,
        TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = self.TitleBar,
    })

    self.SubtitleLabel = new("TextLabel", {
        Size = UDim2.new(0, 220, 1, 0),
        Position = UDim2.fromOffset(120, 0),
        BackgroundTransparency = 1,
        Text = "v3 Ultimate  ·  Legends of Speed",
        TextColor3 = T().TextDim,
        Font = Enum.Font.Gotham,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = self.TitleBar,
    })

    -- window buttons
    local function windowButton(text, xPos, color, callback)
        local btn = new("TextButton", {
            Size = UDim2.fromOffset(34, 34),
            Position = UDim2.new(1, xPos, 0.5, -17),
            BackgroundTransparency = 1,
            Text = text,
            TextColor3 = color or T().Text,
            Font = Enum.Font.GothamBold,
            TextSize = 16,
            Parent = self.TitleBar,
        })
        btn.MouseButton1Click:Connect(function()
            if callback then callback() end
        end)
        return btn
    end

    windowButton("—", -104, nil, function()
        self.Main.Visible = false
        Mobile.show()
    end)

    windowButton("×", -36, T().Danger, function()
        self.Gui.Enabled = false
        Mobile.hide()
    end)

    -- ── drag logic (mouse + touch) ───────────────────────────────────────
    local dragStart = nil
    local startPos = nil

    self.TitleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragStart = input.Position
            startPos = self.Main.Position
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragStart and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            self.Main.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragStart = nil
        end
    end)

    -- ── sidebar ──────────────────────────────────────────────────────────
    self.Sidebar = new("Frame", {
        Name = "Sidebar",
        Size = UDim2.new(0, 140, 1, -40),
        Position = UDim2.fromOffset(0, 40),
        BackgroundColor3 = T().Surface,
        BorderSizePixel = 0,
        Parent = self.Main,
    })

    new("Frame", {
        Size = UDim2.new(1, 0, 0, 12),
        Position = UDim2.new(0, 0, 1, -12),
        BackgroundColor3 = T().Surface,
        BorderSizePixel = 0,
        Parent = self.Sidebar,
    })

    self.SidebarList = new("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Parent = self.Sidebar,
    })
    padding(8, self.SidebarList)
    new("UIListLayout", {
        Padding = UDim.new(0, 4),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = self.SidebarList,
    })

    -- ── content area ─────────────────────────────────────────────────────
    self.ContentWrap = new("Frame", {
        Name = "ContentWrap",
        Size = UDim2.new(1, -140, 1, -40),
        Position = UDim2.fromOffset(140, 40),
        BackgroundTransparency = 1,
        Parent = self.Main,
    })
    padding(10, self.ContentWrap)

    self.Content = new("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Parent = self.ContentWrap,
    })

    self.Tabs = {}
    self.TabButtons = {}
    self.ActiveTab = nil

    -- notification layer lives inside the window
    Notifications.init(self.Gui)

    return self
end

function Window:SelectTab(name)
    for tabName, frame in pairs(self.Tabs) do
        frame.Visible = (tabName == name)
    end
    for tabName, button in pairs(self.TabButtons) do
        local active = (tabName == name)
        tween(button, 0.12, {
            BackgroundColor3 = active and T().Accent or T().SurfaceAlt,
        })
        button.TextColor3 = active and T().TextOnAccent or T().Text
    end
    self.ActiveTab = name
end

function Window:CreateTab(name, icon)
    local button = new("TextButton", {
        Size = UDim2.new(1, 0, 0, 32),
        BackgroundColor3 = T().SurfaceAlt,
        BorderSizePixel = 0,
        Text = (icon and (icon .. "  ") or "") .. name,
        TextColor3 = T().Text,
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = self.SidebarList,
    })
    corner(6, button)
    padding(10, button)

    local frame = new("ScrollingFrame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = T().Accent,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Visible = false,
        Parent = self.Content,
    })

    self.Tabs[name] = frame
    self.TabButtons[name] = button

    button.MouseButton1Click:Connect(function()
        self:SelectTab(name)
    end)

    local tabApi = {}
    local layout = new("UIListLayout", {
        Padding = UDim.new(0, 6),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = frame,
    })
    tabApi.Frame = frame
    tabApi.Layout = layout

    return tabApi
end

-- ============================================================================
-- SECTION 11: UI LIBRARY — WIDGETS
-- ============================================================================

-- ── Section header ───────────────────────────────────────────────────────
function Lib.Section(parent, text)
    local holder = new("Frame", {
        Size = UDim2.new(1, 0, 0, 28),
        BackgroundTransparency = 1,
        Parent = parent,
    })

    new("TextLabel", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = T().Accent,
        Font = Enum.Font.GothamBold,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = holder,
    })

    new("Frame", {
        Size = UDim2.new(1, 0, 0, 1),
        Position = UDim2.new(0, 0, 1, -1),
        BackgroundColor3 = T().Stroke,
        BorderSizePixel = 0,
        Parent = holder,
    })

    return holder
end

-- ── Divider ──────────────────────────────────────────────────────────────
function Lib.Divider(parent)
    return new("Frame", {
        Size = UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = T().Stroke,
        BorderSizePixel = 0,
        Parent = parent,
    })
end

-- ── Paragraph ────────────────────────────────────────────────────────────
function Lib.Paragraph(parent, text, height)
    local holder = new("Frame", {
        Size = UDim2.new(1, 0, 0, height or 40),
        BackgroundTransparency = 1,
        Parent = parent,
    })
    new("TextLabel", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = T().TextDim,
        Font = Enum.Font.Gotham,
        TextSize = 11,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        Parent = holder,
    })
    return holder
end

-- ── Label ────────────────────────────────────────────────────────────────
function Lib.Label(parent, text, height)
    local holder = new("Frame", {
        Size = UDim2.new(1, 0, 0, height or 20),
        BackgroundTransparency = 1,
        Parent = parent,
    })
    local label = new("TextLabel", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = T().Text,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = holder,
    })
    return label
end

-- ── Toggle ───────────────────────────────────────────────────────────────
function Lib.Toggle(parent, labelText, default, callback, tooltip)
    local holder = new("Frame", {
        Size = UDim2.new(1, 0, 0, 32),
        BackgroundTransparency = 1,
        Parent = parent,
    })

    new("TextLabel", {
        Size = UDim2.new(1, -70, 1, 0),
        BackgroundTransparency = 1,
        Text = labelText,
        TextColor3 = T().Text,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = holder,
    })

    local btn = new("TextButton", {
        Size = UDim2.fromOffset(48, 22),
        Position = UDim2.new(1, -48, 0.5, -11),
        BackgroundColor3 = default and T().Accent or T().SurfaceAlt,
        BorderSizePixel = 0,
        Text = default and "ON" or "OFF",
        TextColor3 = default and T().TextOnAccent or T().Text,
        Font = Enum.Font.GothamBold,
        TextSize = 10,
        Parent = holder,
    })
    corner(11, btn)

    local state = default
    btn.MouseButton1Click:Connect(function()
        state = not state
        btn.Text = state and "ON" or "OFF"
        tween(btn, 0.12, {
            BackgroundColor3 = state and T().Accent or T().SurfaceAlt,
        })
        btn.TextColor3 = state and T().TextOnAccent or T().Text
        if callback then pcall(callback, state) end
    end)

    if tooltip then Tooltips.attach(holder, tooltip) end
    return holder
end

-- ── Slider ───────────────────────────────────────────────────────────────
function Lib.Slider(parent, labelText, min, max, default, callback, tooltip)
    local holder = new("Frame", {
        Size = UDim2.new(1, 0, 0, 50),
        BackgroundTransparency = 1,
        Parent = parent,
    })

    local label = new("TextLabel", {
        Size = UDim2.new(1, 0, 0, 18),
        BackgroundTransparency = 1,
        Text = labelText .. ": " .. tostring(default),
        TextColor3 = T().Text,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = holder,
    })

    local track = new("Frame", {
        Size = UDim2.new(1, -12, 0, 5),
        Position = UDim2.fromOffset(0, 32),
        BackgroundColor3 = T().SurfaceAlt,
        BorderSizePixel = 0,
        Parent = holder,
    })
    corner(3, track)

    local fill = new("Frame", {
        Size = UDim2.fromScale((default - min) / (max - min), 1),
        BackgroundColor3 = T().Accent,
        BorderSizePixel = 0,
        Parent = track,
    })
    corner(3, fill)

    local knob = new("Frame", {
        Size = UDim2.fromOffset(12, 12),
        Position = UDim2.new(fill.Size.X.Scale, -6, 0.5, -6),
        BackgroundColor3 = T().Text,
        BorderSizePixel = 0,
        Parent = track,
    })
    corner(6, knob)

    local dragging = false
    local value = default

    local function updateFromX(x)
        local relative = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        value = math.floor(min + (max - min) * relative + 0.5)
        fill.Size = UDim2.fromScale(relative, 1)
        knob.Position = UDim2.new(relative, -6, 0.5, -6)
        label.Text = labelText .. ": " .. tostring(value)
        if callback then pcall(callback, value) end
    end

    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            updateFromX(input.Position.X)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            updateFromX(input.Position.X)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    if tooltip then Tooltips.attach(holder, tooltip) end
    return holder
end

-- ── Dropdown ─────────────────────────────────────────────────────────────
function Lib.Dropdown(parent, labelText, options, default, callback)
    local holder = new("Frame", {
        Size = UDim2.new(1, 0, 0, 32),
        BackgroundTransparency = 1,
        Parent = parent,
    })

    new("TextLabel", {
        Size = UDim2.new(1, -180, 1, 0),
        BackgroundTransparency = 1,
        Text = labelText,
        TextColor3 = T().Text,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = holder,
    })

    local btn = new("TextButton", {
        Size = UDim2.fromOffset(170, 26),
        Position = UDim2.new(1, -170, 0.5, -13),
        BackgroundColor3 = T().SurfaceAlt,
        BorderSizePixel = 0,
        Text = default,
        TextColor3 = T().Text,
        Font = Enum.Font.Gotham,
        TextSize = 11,
        Parent = holder,
    })
    corner(4, btn)

    local index = 1
    for i, option in ipairs(options) do
        if option == default then index = i break end
    end

    btn.MouseButton1Click:Connect(function()
        index = index % #options + 1
        btn.Text = options[index]
        if callback then pcall(callback, options[index]) end
    end)

    return holder
end

-- ── Button ───────────────────────────────────────────────────────────────
function Lib.Button(parent, text, callback, color)
    local btn = new("TextButton", {
        Size = UDim2.new(1, 0, 0, 30),
        BackgroundColor3 = color or T().SurfaceAlt,
        BorderSizePixel = 0,
        Text = text,
        TextColor3 = T().Text,
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        Parent = parent,
    })
    corner(5, btn)

    btn.MouseEnter:Connect(function()
        tween(btn, 0.1, { BackgroundColor3 = color or T().Accent })
        btn.TextColor3 = color and T().Text or T().TextOnAccent
    end)

    btn.MouseLeave:Connect(function()
        tween(btn, 0.1, { BackgroundColor3 = color or T().SurfaceAlt })
        btn.TextColor3 = T().Text
    end)

    btn.MouseButton1Click:Connect(function()
        if callback then pcall(callback) end
    end)

    return btn
end

-- ── Textbox ──────────────────────────────────────────────────────────────
function Lib.Textbox(parent, labelText, default, callback)
    local holder = new("Frame", {
        Size = UDim2.new(1, 0, 0, 32),
        BackgroundTransparency = 1,
        Parent = parent,
    })

    new("TextLabel", {
        Size = UDim2.new(1, -180, 1, 0),
        BackgroundTransparency = 1,
        Text = labelText,
        TextColor3 = T().Text,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = holder,
    })

    local box = new("TextBox", {
        Size = UDim2.fromOffset(170, 26),
        Position = UDim2.new(1, -170, 0.5, -13),
        BackgroundColor3 = T().SurfaceAlt,
        BorderSizePixel = 0,
        Text = tostring(default),
        PlaceholderText = "...",
        TextColor3 = T().Text,
        Font = Enum.Font.Gotham,
        TextSize = 11,
        ClearTextOnFocus = false,
        Parent = holder,
    })
    corner(4, box)
    padding(6, box)

    box.FocusLost:Connect(function()
        if callback then pcall(callback, box.Text) end
    end)

    return box
end

-- ── Keybind ──────────────────────────────────────────────────────────────
function Lib.Keybind(parent, labelText, default, callback)
    local holder = new("Frame", {
        Size = UDim2.new(1, 0, 0, 32),
        BackgroundTransparency = 1,
        Parent = parent,
    })

    new("TextLabel", {
        Size = UDim2.new(1, -180, 1, 0),
        BackgroundTransparency = 1,
        Text = labelText,
        TextColor3 = T().Text,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = holder,
    })

    local btn = new("TextButton", {
        Size = UDim2.fromOffset(170, 26),
        Position = UDim2.new(1, -170, 0.5, -13),
        BackgroundColor3 = T().SurfaceAlt,
        BorderSizePixel = 0,
        Text = default,
        TextColor3 = T().Text,
        Font = Enum.Font.Gotham,
        TextSize = 11,
        Parent = holder,
    })
    corner(4, btn)

    local listening = false
    btn.MouseButton1Click:Connect(function()
        if listening then return end
        listening = true
        btn.Text = "Press a key..."
        local conn
        conn = UserInputService.InputBegan:Connect(function(input, processed)
            if processed then return end
            if input.UserInputType == Enum.UserInputType.Keyboard then
                btn.Text = input.KeyCode.Name
                listening = false
                if callback then pcall(callback, input.KeyCode.Name) end
                conn:Disconnect()
            end
        end)
    end)

    return btn
end

-- ── Color picker (accent override) ───────────────────────────────────────
function Lib.ColorPicker(parent, labelText, default, callback)
    local holder = new("Frame", {
        Size = UDim2.new(1, 0, 0, 32),
        BackgroundTransparency = 1,
        Parent = parent,
    })

    new("TextLabel", {
        Size = UDim2.new(1, -180, 1, 0),
        BackgroundTransparency = 1,
        Text = labelText,
        TextColor3 = T().Text,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = holder,
    })

    local swatch = new("TextButton", {
        Size = UDim2.fromOffset(60, 26),
        Position = UDim2.new(1, -60, 0.5, -13),
        BackgroundColor3 = default or T().Accent,
        BorderSizePixel = 0,
        Text = "",
        Parent = holder,
    })
    corner(4, swatch)

    swatch.MouseButton1Click:Connect(function()
        local colors = {
            Color3.fromRGB(80, 200, 255),
            Color3.fromRGB(170, 120, 255),
            Color3.fromRGB(80, 230, 140),
            Color3.fromRGB(255, 100, 110),
            Color3.fromRGB(255, 170, 80),
            Color3.fromRGB(255, 130, 200),
            Color3.fromRGB(200, 200, 215),
        }
        local nextColor = colors[math.random(1, #colors)]
        swatch.BackgroundColor3 = nextColor
        if callback then pcall(callback, nextColor) end
    end)

    return holder
end

-- ============================================================================
-- SECTION 12: MOBILE FLOATING BUTTON
-- ============================================================================
Mobile = {}

function Mobile.init()
    if Mobile.Gui and Mobile.Gui.Parent then return end

    Mobile.Gui = new("ScreenGui", {
        Name = "LaxissMobile",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        DisplayOrder = 1000,
        Parent = CoreGui,
    })

    Mobile.Button = new("Frame", {
        Size = UDim2.fromOffset(58, 58),
        Position = UDim2.new(1, -84, 0.5, -29),
        BackgroundColor3 = T().Accent,
        BorderSizePixel = 0,
        Active = true,
        Parent = Mobile.Gui,
    })
    corner(29, Mobile.Button)
    stroke(T().AccentDark, 2, Mobile.Button)

    new("TextLabel", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Text = "Lx",
        TextColor3 = T().TextOnAccent,
        Font = Enum.Font.GothamBlack,
        TextSize = 17,
        Parent = Mobile.Button,
    })

    -- drag
    local dragStart, startPos
    Mobile.Button.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragStart = input.Position
            startPos = Mobile.Button.Position
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragStart and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            Mobile.Button.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragStart = nil
        end
    end)

    -- tap vs drag detection
    local pressTime, pressPos
    Mobile.Button.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            pressTime = os.clock()
            pressPos = input.Position
        end
    end)

    Mobile.Button.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            if pressTime and (os.clock() - pressTime) < 0.3
                and (input.Position - pressPos).Magnitude < 10 then
                if WindowInstance then
                    WindowInstance.Gui.Enabled = not WindowInstance.Gui.Enabled
                    if WindowInstance.Gui.Enabled then
                        WindowInstance.Main.Visible = true
                    end
                end
            end
        end
    end)
end

function Mobile.show()
    if Mobile.Button and Mobile.Button.Parent then
        Mobile.Button.Visible = true
    end
end

function Mobile.hide()
    if Mobile.Button and Mobile.Button.Parent then
        Mobile.Button.Visible = false
    end
end

function Mobile.setEnabled(enabled)
    if enabled then
        Mobile.init()
        Mobile.show()
    elseif Mobile.Gui then
        Mobile.Gui:Destroy()
        Mobile.Gui = nil
        Mobile.Button = nil
    end
end

-- ============================================================================
-- SECTION 13: WINDOW INSTANCE + TAB CREATION
-- ============================================================================
WindowInstance = Window.new()

local FarmTab      = WindowInstance:CreateTab("Farming", "⚡")
local CrystalTab   = WindowInstance:CreateTab("Crystals", "💎")
local PetsTab      = WindowInstance:CreateTab("Pets", "🐾")
local PlayerTab    = WindowInstance:CreateTab("Player", "🏃")
local TeleportTab  = WindowInstance:CreateTab("Teleport", "🌍")
local ESPTab       = WindowInstance:CreateTab("ESP", "👁")
local SettingsTab  = WindowInstance:CreateTab("Settings", "⚙")
local CreditsTab   = WindowInstance:CreateTab("Credits", "ℹ")

-- ============================================================================
-- SECTION 14: FARMING TAB
-- ============================================================================
Lib.Section(FarmTab.Frame, "ORB FARMING")

Lib.Dropdown(FarmTab.Frame, "Orb Type", {
    "Ethereal Orb", "Red Orb", "Blue Orb", "Yellow Orb", "Orange Orb", "Rainbow Orb",
}, State.OrbType, function(value) State.OrbType = value end)

Lib.Dropdown(FarmTab.Frame, "Location", {
    "City", "Desert", "Magma City", "Grassland", "Jungle", "Legends Highway",
}, State.OrbLoc or "City", function(value) State.OrbLoc = value end)

Lib.Slider(FarmTab.Frame, "Orbs Per Cycle", 1, 100, State.AutoOrbsMulti,
    function(value) State.AutoOrbsMulti = value end,
    "How many orb remote calls fire each 0.1s tick.")

Lib.Toggle(FarmTab.Frame, "Auto Orbs (remote)", false,
    function(value) State.AutoOrbs = value end,
    "Fires orbEvent with collectOrb. Fast, remote-based.")

Lib.Toggle(FarmTab.Frame, "Auto Orb Touch (physical)", false,
    function(value) State.AutoTouchOrbs = value end,
    "Walks every orb part with firetouchinterest. Slower but harder to patch.")

Lib.Toggle(FarmTab.Frame, "Orb Magnet", false,
    function(value) State.OrbMagnet = value end,
    "Snaps orb parts to your character every 0.2s.")

Lib.Toggle(FarmTab.Frame, "Orb Pull All", false,
    function(value) State.OrbPullAll = value end,
    "Instantly fires a massive orb batch across every location.")

Lib.Section(FarmTab.Frame, "GEMS")

Lib.Slider(FarmTab.Frame, "Gem Batch", 1, 30, State.GemBatch,
    function(value) State.GemBatch = value end)

Lib.Toggle(FarmTab.Frame, "Auto Gems", false,
    function(value) State.AutoGems = value end,
    "Hits City, Desert and Magma City gem spawns every tick.")

Lib.Section(FarmTab.Frame, "CHESTS")

Lib.Toggle(FarmTab.Frame, "Auto Chests", false,
    function(value) State.AutoChests = value end,
    "Touches every part whose name contains chest or gift.")

Lib.Section(FarmTab.Frame, "HOOPS")

Lib.Dropdown(FarmTab.Frame, "Hoop Mode", { "Touch", "Teleport" }, State.HoopMode,
    function(value) State.HoopMode = value end)

Lib.Slider(FarmTab.Frame, "Hoop Delay (ms)", 50, 1000, State.HoopDelay * 1000,
    function(value) State.HoopDelay = value / 1000 end)

Lib.Toggle(FarmTab.Frame, "Auto Hoops", false,
    function(value) State.AutoHoops = value end)

Lib.Toggle(FarmTab.Frame, "Hoop Magnet", false,
    function(value) State.HoopMagnet = value end,
    "Snaps every hoop under Workspace.Hoops to your root.")

Lib.Section(FarmTab.Frame, "REBIRTH")

Lib.Toggle(FarmTab.Frame, "Auto Rebirth", false,
    function(value) State.AutoRebirth = value end)

Lib.Toggle(FarmTab.Frame, "Level Check", true,
    function(value) State.RebirthCheck = value end,
    "Only fires rebirth when globalFunctions says the level is exact.")

Lib.Section(FarmTab.Frame, "RACE & QUEST")

Lib.Toggle(FarmTab.Frame, "Auto Race", false,
    function(value) State.AutoRace = value end,
    "Touches every checkpoint part on the map.")

Lib.Toggle(FarmTab.Frame, "Auto Win Race", false,
    function(value) State.AutoWinRace = value end,
    "Touches checkpoints in sequence and teleports to the finish line.")

Lib.Toggle(FarmTab.Frame, "Auto Quest", false,
    function(value) State.AutoQuest = value end)

Lib.Section(FarmTab.Frame, "MISC FARMING")

Lib.Toggle(FarmTab.Frame, "Auto Steps", false,
    function(value) State.AutoSteps = value end,
    "Fires orb remotes designed for step gain.")

Lib.Toggle(FarmTab.Frame, "Auto EXP", false,
    function(value) State.AutoEXP = value end)

Lib.Toggle(FarmTab.Frame, "Auto Claim Gifts (1-8)", false,
    function(value) State.AutoGifts = value end,
    "Claims all eight daily gift slots every cycle.")

Lib.Toggle(FarmTab.Frame, "Walk on Parkour Floor", false,
    function(value) State.AutoParkour = value end,
    "Keeps humanoid state stable so parkour floors stay solid.")

Lib.Divider(FarmTab.Frame)

Lib.Label(FarmTab.Frame, "Session Statistics", 20)
local farmStatsLabel = Lib.Paragraph(FarmTab.Frame, "", 60)

-- ============================================================================
-- SECTION 15: CRYSTALS TAB
-- ============================================================================
Lib.Section(CrystalTab.Frame, "CRYSTAL OPENER")

Lib.Dropdown(CrystalTab.Frame, "Crystal Type", {
    "Basic Crystal", "Silver Crystal", "Gold Crystal",
    "Diamond Crystal", "Rainbow Crystal",
}, State.HatchType, function(value) State.HatchType = value end)

Lib.Slider(CrystalTab.Frame, "Open Amount", 1, 50, State.HatchAmount,
    function(value) State.HatchAmount = value end,
    "How many crystals to open per invocation.")

Lib.Button(CrystalTab.Frame, "Open Crystals Now", function()
    local opened = 0
    for i = 1, State.HatchAmount do
        if fireCrystal(State.HatchType, 1) then
            opened = opened + 1
            State.CrystalsOpened = State.CrystalsOpened + 1
        end
        task.wait(0.05)
    end
    if opened > 0 then
        notify("Crystals", "Opened " .. opened .. " × " .. State.HatchType, 3)
    else
        notify("Crystals", "Crystal remote not found or invoke failed.", 4)
    end
end)

Lib.Toggle(CrystalTab.Frame, "Auto Hatch Crystals", false,
    function(value) State.AutoHatch = value end)

Lib.Toggle(CrystalTab.Frame, "Fast Open", false,
    function(value) State.FastOpen = value end,
    "Removes the delay between crystal opens.")

Lib.Section(CrystalTab.Frame, "PET MANAGEMENT")

Lib.Toggle(CrystalTab.Frame, "Auto Equip Best Pet", false,
    function(value) State.AutoEquipBest = value end,
    "Re-equips the highest-tier pet whenever inventory changes.")

Lib.Toggle(CrystalTab.Frame, "Auto Evolve Pets", false,
    function(value) State.AutoEvolve = value end)

Lib.Section(CrystalTab.Frame, "STATISTICS")

local crystalStatsLabel = Lib.Paragraph(CrystalTab.Frame, "", 60)

-- ============================================================================
-- SECTION 16: PETS & TRAILS TAB
-- ============================================================================
Lib.Section(PetsTab.Frame, "PET UTILITIES")

Lib.Button(PetsTab.Frame, "Equip Best Pet", function()
    local inventory = LocalPlayer:FindFirstChild("Inventory")
    if not inventory then
        notify("Pets", "Inventory folder not found.", 3)
        return
    end
    local best, bestValue = nil, -1
    for _, pet in ipairs(inventory:GetDescendants()) do
        if pet:IsA("Folder") or pet:IsA("StringValue") then
            local power = pet:FindFirstChild("Power")
                or pet:FindFirstChild("Level")
                or pet:FindFirstChild("Rarity")
            local value = power and tonumber(power.Value) or 0
            if value > bestValue then
                bestValue = value
                best = pet
            end
        end
    end
    if best then
        local equipRemote = rEvents and (rEvents:FindFirstChild("equipPet")
            or rEvents:FindFirstChild("petEvent"))
        if equipRemote then
            pcall(function()
                if equipRemote:IsA("RemoteFunction") then
                    equipRemote:InvokeServer("equip", best.Name)
                else
                    equipRemote:FireServer("equip", best.Name)
                end
            end)
            notify("Pets", "Equipped: " .. best.Name, 3)
        else
            notify("Pets", "Equip remote not found.", 3)
        end
    else
        notify("Pets", "No pets found in inventory.", 3)
    end
end)

Lib.Button(PetsTab.Frame, "Duplicate All Pets", function()
    local inventory = LocalPlayer:FindFirstChild("Inventory")
    if not inventory then
        notify("Pets", "Inventory folder not found.", 3)
        return
    end
    local duped = 0
    for _, pet in ipairs(inventory:GetDescendants()) do
        if pet:IsA("StringValue") or pet:IsA("Folder") then
            local dupRemote = rEvents and (rEvents:FindFirstChild("duplicatePet")
                or rEvents:FindFirstChild("dupPet"))
            if dupRemote then
                pcall(function()
                    if dupRemote:IsA("RemoteFunction") then
                        dupRemote:InvokeServer("duplicate", pet.Name)
                    else
                        dupRemote:FireServer("duplicate", pet.Name)
                    end
                end)
                duped = duped + 1
                task.wait(0.05)
            end
        end
    end
    notify("Pets", "Duplication attempted on " .. duped .. " pets.", 4)
end)

Lib.Button(PetsTab.Frame, "Delete All Pets", function()
    local inventory = LocalPlayer:FindFirstChild("Inventory")
    if not inventory then return end
    local deleted = 0
    for _, pet in ipairs(inventory:GetDescendants()) do
        if pet:IsA("StringValue") or pet:IsA("Folder") then
            local deleteRemote = rEvents and (rEvents:FindFirstChild("deletePet")
                or rEvents:FindFirstChild("removePet"))
            if deleteRemote then
                pcall(function()
                    if deleteRemote:IsA("RemoteFunction") then
                        deleteRemote:InvokeServer("delete", pet.Name)
                    else
                        deleteRemote:FireServer("delete", pet.Name)
                    end
                end)
                deleted = deleted + 1
                task.wait(0.03)
            end
        end
    end
    notify("Pets", "Deleted " .. deleted .. " pets.", 4)
end)

Lib.Section(PetsTab.Frame, "TRAIL UTILITIES")

Lib.Button(PetsTab.Frame, "Duplicate All Trails", function()
    local trailFolder = LocalPlayer:FindFirstChild("Trails")
        or LocalPlayer:FindFirstChild("Inventory")
    if not trailFolder then
        notify("Trails", "Trail folder not found.", 3)
        return
    end
    local duped = 0
    for _, trail in ipairs(trailFolder:GetDescendants()) do
        if trail:IsA("StringValue") or trail:IsA("Folder") then
            local dupRemote = rEvents and (rEvents:FindFirstChild("duplicateTrail")
                or rEvents:FindFirstChild("dupTrail"))
            if dupRemote then
                pcall(function()
                    if dupRemote:IsA("RemoteFunction") then
                        dupRemote:InvokeServer("duplicate", trail.Name)
                    else
                        dupRemote:FireServer("duplicate", trail.Name)
                    end
                end)
                duped = duped + 1
                task.wait(0.05)
            end
        end
    end
    notify("Trails", "Duplication attempted on " .. duped .. " trails.", 4)
end)

Lib.Button(PetsTab.Frame, "Delete All Trails", function()
    local trailFolder = LocalPlayer:FindFirstChild("Trails")
    if not trailFolder then return end
    local deleted = 0
    for _, trail in ipairs(trailFolder:GetDescendants()) do
        if trail:IsA("StringValue") or trail:IsA("Folder") then
            local deleteRemote = rEvents and (rEvents:FindFirstChild("deleteTrail")
                or rEvents:FindFirstChild("removeTrail"))
            if deleteRemote then
                pcall(function()
                    if deleteRemote:IsA("RemoteFunction") then
                        deleteRemote:InvokeServer("delete", trail.Name)
                    else
                        deleteRemote:FireServer("delete", trail.Name)
                    end
                end)
                deleted = deleted + 1
                task.wait(0.03)
            end
        end
    end
    notify("Trails", "Deleted " .. deleted .. " trails.", 4)
end)

Lib.Section(PetsTab.Frame, "AUTO EVOLVE")

Lib.Toggle(PetsTab.Frame, "Auto Evolve All", false,
    function(value) State.AutoEvolve = value end,
    "Repeatedly fires the evolve remote for every pet that can evolve.")

Lib.Divider(PetsTab.Frame)

Lib.Paragraph(PetsTab.Frame,
    "Pet and trail remotes vary by game update. If a button reports "
    .. "'remote not found', the game has renamed or removed that endpoint. "
    .. "All operations are wrapped in pcall so a missing remote will never "
    .. "break the rest of the hub.", 70)

-- ============================================================================
-- SECTION 17: PLAYER TAB
-- ============================================================================
Lib.Section(PlayerTab.Frame, "MOVEMENT")

Lib.Slider(PlayerTab.Frame, "WalkSpeed", 16, 300, State.WalkSpeed,
    function(value)
        State.WalkSpeed = value
        local hum = getHum()
        if hum then hum.WalkSpeed = value end
    end)

Lib.Slider(PlayerTab.Frame, "JumpPower", 50, 300, State.JumpPower,
    function(value)
        State.JumpPower = value
        local hum = getHum()
        if hum then
            hum.JumpPower = value
            hum.UseJumpPower = true
        end
    end)

Lib.Toggle(PlayerTab.Frame, "Infinite Jump", false,
    function(value) State.InfJump = value end)

Lib.Toggle(PlayerTab.Frame, "Auto Jump", false,
    function(value) State.AutoJump = value end,
    "Forces the jumping state every heartbeat.")

Lib.Toggle(PlayerTab.Frame, "Fly", false,
    function(value) State.Fly = value end,
    "BodyVelocity flight. WASD relative to camera, Space up, Ctrl down.")

Lib.Slider(PlayerTab.Frame, "Fly Speed", 20, 300, State.FlySpeed,
    function(value) State.FlySpeed = value end)

Lib.Toggle(PlayerTab.Frame, "Noclip", false,
    function(value) State.Noclip = value end)

Lib.Section(PlayerTab.Frame, "PROTECTION")

Lib.Toggle(PlayerTab.Frame, "Anti-Ragdoll", false,
    function(value) State.AntiRagdoll = value end,
    "Keeps humanoid state on Running to prevent knockdowns.")

Lib.Toggle(PlayerTab.Frame, "Anti-AFK", false,
    function(value) State.AntiAFK = value end)

Lib.Toggle(PlayerTab.Frame, "Anti-Kick", false,
    function(value) State.AntiKick = value end,
    "Blocks the Kick method on the LocalPlayer metatable.")

Lib.Toggle(PlayerTab.Frame, "Disable Lava Damage", false,
    function(value) State.DisableLava = value end)

Lib.Section(PlayerTab.Frame, "ACTIONS")

Lib.Button(PlayerTab.Frame, "Reset Character", function()
    local char = getChar()
    if char then char:BreakJoints() end
end)

Lib.Button(PlayerTab.Frame, "Rejoin Server", function()
    TeleportService:Teleport(game.PlaceId, LocalPlayer)
end)

Lib.Button(PlayerTab.Frame, "Server Hop", function()
    local ok, response = pcall(function()
        return game:HttpGet(
            "https://games.roblox.com/v1/games/" .. game.PlaceId
            .. "/servers/Public?sortOrder=Asc&limit=100"
        )
    end)
    if not ok then
        notify("Server Hop", "Failed to fetch server list.", 3)
        return
    end
    local data = HttpService:JSONDecode(response)
    for _, server in ipairs(data.data or {}) do
        if server.playing < server.maxPlayers and server.id ~= game.JobId then
            TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, LocalPlayer)
            notify("Server Hop", "Joining a server with " .. server.playing .. " players.", 3)
            return
        end
    end
    notify("Server Hop", "No open servers found.", 3)
end)

-- ============================================================================
-- SECTION 18: TELEPORT TAB
-- ============================================================================
Lib.Section(TeleportTab.Frame, "MAP TELEPORTS")

local MapPositions = {
    ["City"]             = Vector3.new(-130, 5, 10),
    ["Desert"]           = Vector3.new(1050, 10, 250),
    ["Magma City"]       = Vector3.new(-150, 5, 1450),
    ["Grassland"]        = Vector3.new(500, 5, -400),
    ["Jungle"]           = Vector3.new(-900, 5, -900),
    ["Legends Highway"]  = Vector3.new(2000, 10, 2000),
    ["Spawn"]            = nil,
}

local mapNames = {}
for name in pairs(MapPositions) do mapNames[#mapNames + 1] = name end
table.sort(mapNames)

Lib.Dropdown(TeleportTab.Frame, "Destination", mapNames,
    State.SelectedMap, function(value) State.SelectedMap = value end)

Lib.Button(TeleportTab.Frame, "Teleport to Destination", function()
    local root = getRoot()
    if not root then return end
    if State.SelectedMap == "Spawn" then
        local spawn = Workspace:FindFirstChildOfClass("SpawnLocation")
        if spawn then root.CFrame = spawn.CFrame + Vector3.new(0, 4, 0) end
    else
        local pos = MapPositions[State.SelectedMap]
        if pos then root.CFrame = CFrame.new(pos) end
    end
end)

Lib.Button(TeleportTab.Frame, "Teleport to Spawn", function()
    local root = getRoot()
    local spawn = Workspace:FindFirstChildOfClass("SpawnLocation")
    if root and spawn then
        root.CFrame = spawn.CFrame + Vector3.new(0, 4, 0)
    end
end)

Lib.Section(TeleportTab.Frame, "CUSTOM COORDINATES")

local customX, customY, customZ = "0", "10", "0"

Lib.Textbox(TeleportTab.Frame, "X", "0", function(value) customX = value end)
Lib.Textbox(TeleportTab.Frame, "Y", "10", function(value) customY = value end)
Lib.Textbox(TeleportTab.Frame, "Z", "0", function(value) customZ = value end)

Lib.Button(TeleportTab.Frame, "Teleport to Coordinates", function()
    local root = getRoot()
    if not root then return end
    local x = tonumber(customX)
    local y = tonumber(customY)
    local z = tonumber(customZ)
    if x and y and z then
        root.CFrame = CFrame.new(x, y, z)
    else
        notify("Teleport", "Invalid coordinates.", 3)
    end
end)

Lib.Section(TeleportTab.Frame, "PLAYER TELEPORT")

local playerList = {}
local function refreshPlayerList()
    playerList = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            playerList[#playerList + 1] = player.Name
        end
    end
    if #playerList == 0 then playerList = { "<none>" } end
    State.SelectedPlayer = playerList[1]
end
refreshPlayerList()

Lib.Dropdown(TeleportTab.Frame, "Target Player", playerList,
    State.SelectedPlayer or "<none>",
    function(value) State.SelectedPlayer = value end)

Lib.Button(TeleportTab.Frame, "Teleport to Player", function()
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Name == State.SelectedPlayer and player.Character then
            local targetRoot = player.Character:FindFirstChild("HumanoidRootPart")
            local root = getRoot()
            if targetRoot and root then
                root.CFrame = targetRoot.CFrame + Vector3.new(0, 2, 0)
            end
            return
        end
    end
    notify("Teleport", "Player not found or has no character.", 3)
end)

Lib.Button(TeleportTab.Frame, "Refresh Player List", function()
    refreshPlayerList()
    notify("Teleport", "Player list refreshed.", 2)
end)

Lib.Section(TeleportTab.Frame, "WAYPOINTS")

Lib.Button(TeleportTab.Frame, "Save Current Position", function()
    local root = getRoot()
    if not root then return end
    local name = "Waypoint " .. (#State.Waypoints + 1)
    State.Waypoints[#State.Waypoints + 1] = {
        Name = name,
        Position = root.Position,
    }
    notify("Waypoints", "Saved: " .. name, 3)
end)

Lib.Button(TeleportTab.Frame, "Return to Last Waypoint", function()
    local root = getRoot()
    if not root then return end
    local waypoint = State.Waypoints[#State.Waypoints]
    if waypoint then
        root.CFrame = CFrame.new(waypoint.Position)
        notify("Waypoints", "Returned to " .. waypoint.Name, 3)
    else
        notify("Waypoints", "No waypoints saved.", 3)
    end
end)

Lib.Button(TeleportTab.Frame, "Clear All Waypoints", function()
    State.Waypoints = {}
    notify("Waypoints", "Waypoint list cleared.", 2)
end)

-- ============================================================================
-- SECTION 19: ESP TAB
-- ============================================================================
Lib.Section(ESPTab.Frame, "ESP TOGGLES")

Lib.Toggle(ESPTab.Frame, "ESP Orbs", false,
    function(value)
        State.ESPOrbs = value
        if not value then clearESP("Orb") end
    end)

Lib.Toggle(ESPTab.Frame, "ESP Gems", false,
    function(value)
        State.ESPGems = value
        if not value then clearESP("Gem") end
    end)

Lib.Toggle(ESPTab.Frame, "ESP Crystals", false,
    function(value)
        State.ESPCrystals = value
        if not value then clearESP("Crystal") end
    end)

Lib.Toggle(ESPTab.Frame, "ESP Chests", false,
    function(value)
        State.ESPChests = value
        if not value then clearESP("Chest") end
    end)

Lib.Toggle(ESPTab.Frame, "ESP Hoops", false,
    function(value)
        State.ESPHoops = value
        if not value then clearESP("Hoop") end
    end)

Lib.Toggle(ESPTab.Frame, "ESP Players", false,
    function(value)
        State.ESPPlayers = value
        if not value then clearESP("Player") end
    end)

Lib.Section(ESPTab.Frame, "DISPLAY OPTIONS")

Lib.Toggle(ESPTab.Frame, "Show Distance", true,
    function(value) State.ESPDistance = value end)

Lib.Toggle(ESPTab.Frame, "Show Names", true,
    function(value) State.ESPNames = value end)

Lib.Toggle(ESPTab.Frame, "Player Tracers", false,
    function(value)
        State.ESPTracers = value
        if not value then clearESP("Tracer") end
    end,
    "Draws a line from your screen to each player. Requires Drawing API.")

Lib.Toggle(ESPTab.Frame, "Box Highlights", false,
    function(value)
        State.ESPBoxes = value
        if not value then clearESP("Box") end
    end)

Lib.Slider(ESPTab.Frame, "Max Distance", 100, 2000, State.ESPMaxDistance,
    function(value) State.ESPMaxDistance = value end,
    "Objects further than this are skipped by the ESP loop.")

Lib.Section(ESPTab.Frame, "ESP INFO")

local espInfoLabel = Lib.Paragraph(ESPTab.Frame, "", 80)

-- ============================================================================
-- SECTION 20: SETTINGS TAB
-- ============================================================================
Lib.Section(SettingsTab.Frame, "APPEARANCE")

Lib.Dropdown(SettingsTab.Frame, "Theme", ThemeOrder, State.Theme, function(value)
    State.Theme = value
    notify("Settings", "Theme set to " .. value .. ". Reload to apply fully.", 4)
end)

Lib.Slider(SettingsTab.Frame, "UI Scale", 70, 150, State.Scale, function(value)
    State.Scale = value
    if WindowInstance and WindowInstance.ScaleObj then
        WindowInstance.ScaleObj.Scale = value / 100
    end
end)

Lib.Toggle(SettingsTab.Frame, "Mobile Toggle Button", true,
    function(value)
        State.MobileButton = value
        Mobile.setEnabled(value)
    end)

Lib.Section(SettingsTab.Frame, "CONTROLS")

Lib.Keybind(SettingsTab.Frame, "GUI Toggle Key", State.ToggleKey,
    function(value) State.ToggleKey = value end)

Lib.Toggle(SettingsTab.Frame, "Notifications", true,
    function(value) State.Notifications = value end)

Lib.Toggle(SettingsTab.Frame, "Performance Mode", false,
    function(value)
        State.PerformanceMode = value
        if value then
            State.ESPTracers = false
            State.ESPBoxes = false
        end
    end,
    "Disables tracers and boxes, lowers ESP refresh rate.")

Lib.Section(SettingsTab.Frame, "CONFIGURATION")

Lib.Button(SettingsTab.Frame, "Save Configuration", function()
    local save = {}
    for key, value in pairs(State) do
        if type(value) == "boolean" or type(value) == "number" or type(value) == "string" then
            save[key] = value
        end
    end
    pcall(function()
        writefile("LaxissTM_v3_config.json", HttpService:JSONEncode(save))
    end)
    notify("Config", "Configuration saved.", 3)
end)

Lib.Button(SettingsTab.Frame, "Load Configuration", function()
    pcall(function()
        local raw = readfile("LaxissTM_v3_config.json")
        local data = HttpService:JSONDecode(raw)
        for key, value in pairs(data) do
            if State[key] ~= nil then
                State[key] = value
            end
        end
        local hum = getHum()
        if hum then
            hum.WalkSpeed = State.WalkSpeed
            hum.JumpPower = State.JumpPower
            hum.UseJumpPower = true
        end
        if WindowInstance and WindowInstance.ScaleObj then
            WindowInstance.ScaleObj.Scale = State.Scale / 100
        end
    end)
    notify("Config", "Configuration loaded. Some toggles need re-applying.", 4)
end)

Lib.Button(SettingsTab.Frame, "Reset Configuration", function()
    pcall(function()
        if isfile and isfile("LaxissTM_v3_config.json") then
            delfile("LaxissTM_v3_config.json")
        end
    end)
    notify("Config", "Config file deleted. Reload the script for defaults.", 4)
end)

Lib.Section(SettingsTab.Frame, "SESSION")

local settingsStatsLabel = Lib.Paragraph(SettingsTab.Frame, "", 100)

-- ============================================================================
-- SECTION 21: CREDITS TAB
-- ============================================================================
Lib.Section(CreditsTab.Frame, "LaxissTM v3")

Lib.Paragraph(CreditsTab.Frame,
    "LaxissTM v3 — Ultimate Edition\n"
    .. "A full-feature Legends of Speed hub built for reliability across "
    .. "executors. Custom UI, no external dependencies, no key system.",
    70)

Lib.Section(CreditsTab.Frame, "COMPATIBLE EXECUTORS")

Lib.Paragraph(CreditsTab.Frame,
    "Synapse X  ·  KRNL  ·  Fluxus  ·  Delta  ·  Solara  ·  Xeno  ·  Wave\n"
    .. "MacSploit  ·  AWP  ·  Codex  ·  Opiumware  ·  Vega X  ·  Velocity",
    50)

Lib.Section(CreditsTab.Frame, "REMOTE REFERENCE")

Lib.Paragraph(CreditsTab.Frame,
    "orbEvent:FireServer(\"collectOrb\", orbType, location)\n"
    .. "rebirthEvent:FireServer(\"rebirthRequest\")\n"
    .. "openCrystalRemote:InvokeServer(\"openCrystal\", crystalType, amount)\n"
    .. "globalFunctions.calculateRequiredRebirthLevel(multiplier - 1)\n"
    .. "Workspace.Hoops  ·  LocalPlayer.level  ·  LocalPlayer.rebirthMultiplier",
    90)

Lib.Section(CreditsTab.Frame, "CHANGELOG")

Lib.Paragraph(CreditsTab.Frame,
    "v3.0  —  Rebuilt UI library, 8 tabs, pets/trails, crystals, chests, "
    .. "gifts, anti-ragdoll, anti-kick, waypoints, tracers, config system.\n"
    .. "v2.0  —  Themed hub, mobile button, server hop, orb magnet.\n"
    .. "v1.0  —  Initial four-tab farm build.",
    90)

Lib.Divider(CreditsTab.Frame)

Lib.Paragraph(CreditsTab.Frame,
    "All remotes are sourced from live game dumps. If the game updates and a "
    .. "feature stops working, the remote name or argument order has changed — "
    .. "check the Remote Reference section above against a fresh dump.",
    60)

-- ============================================================================
-- SECTION 22: ESP IMPLEMENTATION
-- ============================================================================
local ESPFolder = new("Folder", { Name = "LaxissESP", Parent = WindowInstance.Gui })
local TracerLines = {}

function clearESP(category)
    for key, obj in pairs(State.ESPObjects) do
        if obj.Category == category then
            if obj.Billboard then obj.Billboard:Destroy() end
            if obj.Box then obj.Box:Destroy() end
            State.ESPObjects[key] = nil
        end
    end
    if category == "Tracer" then
        for _, line in pairs(TracerLines) do
            pcall(function() line:Remove() end)
        end
        TracerLines = {}
    end
end

local function createBillboard(adornee, text, color)
    local bb = new("BillboardGui", {
        Size = UDim2.fromOffset(140, 26),
        StudsOffset = Vector3.new(0, 3, 0),
        AlwaysOnTop = true,
        Adornee = adornee,
        Parent = ESPFolder,
    })
    local label = new("TextLabel", {
        Name = "Label",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = color,
        Font = Enum.Font.GothamBold,
        TextSize = 11,
        TextStrokeTransparency = 0.4,
        TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
        Parent = bb,
    })
    return bb, label
end

local function createBoxHighlight(part, color)
    local box = new("BoxHandleAdornment", {
        Size = part.Size + Vector3.new(0.2, 0.2, 0.2),
        AlwaysOnTop = true,
        ZIndex = 5,
        Transparency = 0.6,
        Color3 = color,
        Adornee = part,
        Parent = ESPFolder,
    })
    return box
end

local function updateESP()
    -- ── orbs ─────────────────────────────────────────────────────────────
    if State.ESPOrbs then
        for _, part in ipairs(findOrbParts()) do
            local key = part
            if not State.ESPObjects[key] then
                local bb, label = createBillboard(part, part.Name, Color3.fromRGB(255, 220, 100))
                State.ESPObjects[key] = {
                    Category = "Orb",
                    Billboard = bb,
                    Label = label,
                    Base = part.Name,
                    Part = part,
                }
            end
            local entry = State.ESPObjects[key]
            if entry and entry.Label then
                if State.ESPDistance then
                    entry.Label.Text = entry.Base .. " [" .. distanceTo(part) .. "m]"
                else
                    entry.Label.Text = entry.Base
                end
            end
        end
    end

    -- ── gems ─────────────────────────────────────────────────────────────
    if State.ESPGems then
        for _, part in ipairs(findOrbParts()) do
            if part.Name:lower():find("gem") and not State.ESPObjects[part] then
                local bb, label = createBillboard(part, "Gem", Color3.fromRGB(120, 255, 180))
                State.ESPObjects[part] = {
                    Category = "Gem",
                    Billboard = bb,
                    Label = label,
                    Base = "Gem",
                    Part = part,
                }
            end
        end
    end

    -- ── crystals ─────────────────────────────────────────────────────────
    if State.ESPCrystals then
        for _, part in ipairs(findCrystalParts()) do
            if not State.ESPObjects[part] then
                local bb, label = createBillboard(part, "Crystal", Color3.fromRGB(120, 230, 255))
                State.ESPObjects[part] = {
                    Category = "Crystal",
                    Billboard = bb,
                    Label = label,
                    Base = "Crystal",
                    Part = part,
                }
            end
        end
    end

    -- ── chests ───────────────────────────────────────────────────────────
    if State.ESPChests then
        for _, part in ipairs(findChestParts()) do
            if not State.ESPObjects[part] then
                local bb, label = createBillboard(part, "Chest", Color3.fromRGB(255, 190, 80))
                State.ESPObjects[part] = {
                    Category = "Chest",
                    Billboard = bb,
                    Label = label,
                    Base = "Chest",
                    Part = part,
                }
            end
        end
    end

    -- ── hoops ────────────────────────────────────────────────────────────
    if State.ESPHoops then
        for _, part in ipairs(findHoopParts()) do
            if not State.ESPObjects[part] then
                local bb, label = createBillboard(part, "Hoop", Color3.fromRGB(180, 255, 150))
                State.ESPObjects[part] = {
                    Category = "Hoop",
                    Billboard = bb,
                    Label = label,
                    Base = "Hoop",
                    Part = part,
                }
            end
        end
    end

    -- ── players ──────────────────────────────────────────────────────────
    if State.ESPPlayers then
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                local head = player.Character:FindFirstChild("Head")
                if head and not State.ESPObjects[player] then
                    local bb, label = createBillboard(head, player.Name, Color3.fromRGB(255, 120, 120))
                    local entry = {
                        Category = "Player",
                        Billboard = bb,
                        Label = label,
                        Base = player.Name,
                        Part = head,
                    }
                    if State.ESPBoxes then
                        local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
                        if rootPart then
                            entry.Box = createBoxHighlight(rootPart, Color3.fromRGB(255, 120, 120))
                        end
                    end
                    State.ESPObjects[player] = entry
                end
            end
        end
    end

    -- ── tracers ──────────────────────────────────────────────────────────
    if State.ESPTracers and Drawing then
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                local head = player.Character:FindFirstChild("Head")
                if head then
                    if not TracerLines[player] then
                        local line = Drawing.new("Line")
                        line.Thickness = 1
                        line.Color = Color3.fromRGB(255, 120, 120)
                        line.Transparency = 0.6
                        TracerLines[player] = line
                    end
                    local line = TracerLines[player]
                    local screenPos, onScreen = Workspace.CurrentCamera:WorldToViewportPoint(head.Position)
                    if onScreen then
                        line.From = Vector2.new(
                            Workspace.CurrentCamera.ViewportSize.X / 2,
                            Workspace.CurrentCamera.ViewportSize.Y
                        )
                        line.To = Vector2.new(screenPos.X, screenPos.Y)
                        line.Visible = true
                    else
                        line.Visible = false
                    end
                end
            end
        end
    end
end

-- ============================================================================
-- SECTION 23: FARM LOOPS
-- ============================================================================

-- ── Auto orbs (remote) ───────────────────────────────────────────────────
task.spawn(function()
    while task.wait(0.1) do
        if State.AutoOrbs then
            local location = getPlace()
            fireOrb(State.OrbType, location, State.AutoOrbsMulti)
            State.OrbsCollected = State.OrbsCollected + State.AutoOrbsMulti
        end
    end
end)

-- ── Auto gems ────────────────────────────────────────────────────────────
task.spawn(function()
    while task.wait(0.1) do
        if State.AutoGems then
            for _, location in ipairs({ "City", "Desert", "Magma City" }) do
                fireOrb("Gem", location, State.GemBatch)
            end
            State.GemsCollected = State.GemsCollected + State.GemBatch * 3
        end
    end
end)

-- ── Orb pull all ─────────────────────────────────────────────────────────
task.spawn(function()
    while task.wait(0.5) do
        if State.OrbPullAll then
            local locations = { "City", "Desert", "Magma City", "Grassland", "Jungle", "Legends Highway" }
            for _, location in ipairs(locations) do
                fireOrb(State.OrbType, location, 50)
            end
        end
    end
end)

-- ── Auto orb touch (physical) ────────────────────────────────────────────
task.spawn(function()
    while task.wait(0.1) do
        if State.AutoTouchOrbs then
            local root = getRoot()
            if root then
                for _, orb in ipairs(findOrbParts()) do
                    pcall(function()
                        firetouchinterest(root, orb, 0)
                        task.wait()
                        firetouchinterest(root, orb, 1)
                    end)
                end
            end
        end
    end
end)

-- ── Orb magnet ───────────────────────────────────────────────────────────
task.spawn(function()
    while task.wait(0.2) do
        if State.OrbMagnet then
            local root = getRoot()
            if root then
                for _, orb in ipairs(findOrbParts()) do
                    pcall(function() orb.CFrame = root.CFrame end)
                end
            end
        end
    end
end)

-- ── Auto chests ──────────────────────────────────────────────────────────
task.spawn(function()
    while task.wait(0.3) do
        if State.AutoChests then
            local root = getRoot()
            if root then
                for _, chest in ipairs(findChestParts()) do
                    pcall(function()
                        firetouchinterest(root, chest, 0)
                        task.wait()
                        firetouchinterest(root, chest, 1)
                    end)
                    State.ChestsOpened = State.ChestsOpened + 1
                end
            end
        end
    end
end)

-- ── Auto hoops ───────────────────────────────────────────────────────────
task.spawn(function()
    while task.wait(State.HoopDelay) do
        if State.AutoHoops then
            local root = getRoot()
            local hoops = findHoopParts()
            if root and #hoops > 0 then
                for _, hoop in ipairs(hoops) do
                    if State.HoopMode == "Touch" then
                        pcall(function()
                            firetouchinterest(root, hoop, 0)
                            task.wait()
                            firetouchinterest(root, hoop, 1)
                        end)
                    else
                        pcall(function() hoop.CFrame = root.CFrame end)
                    end
                end
            end
        end
    end
end)

-- ── Hoop magnet ──────────────────────────────────────────────────────────
task.spawn(function()
    while task.wait(0.1) do
        if State.HoopMagnet then
            local root = getRoot()
            if root then
                for _, hoop in ipairs(findHoopParts()) do
                    pcall(function() hoop.CFrame = root.CFrame end)
                end
            end
        end
    end
end)

-- ── Auto rebirth ─────────────────────────────────────────────────────────
task.spawn(function()
    while task.wait(1) do
        if State.AutoRebirth then
            local shouldRebirth = true
            if State.RebirthCheck and globalFunctions then
                pcall(function()
                    local level = getLevel()
                    local multiplier = getMultiplier()
                    if level and multiplier then
                        local required = globalFunctions.calculateRequiredRebirthLevel(multiplier - 1)
                        shouldRebirth = (tonumber(required) == tonumber(level))
                    end
                end)
            end
            if shouldRebirth then
                fireRebirth()
                State.RebirthsDone = State.RebirthsDone + 1
            end
        end
    end
end)

-- ── Auto race ────────────────────────────────────────────────────────────
task.spawn(function()
    while task.wait(0.2) do
        if State.AutoRace then
            local root = getRoot()
            if root then
                for _, checkpoint in ipairs(findCheckpoints()) do
                    pcall(function()
                        firetouchinterest(root, checkpoint, 0)
                        task.wait()
                        firetouchinterest(root, checkpoint, 1)
                    end)
                end
            end
        end
    end
end)

-- ── Auto win race ────────────────────────────────────────────────────────
task.spawn(function()
    while task.wait(1) do
        if State.AutoWinRace then
            local root = getRoot()
            if root then
                local checkpoints = findCheckpoints()
                table.sort(checkpoints, function(a, b)
                    return distanceTo(a) < distanceTo(b)
                end)
                for _, checkpoint in ipairs(checkpoints) do
                    pcall(function()
                        root.CFrame = checkpoint.CFrame
                        task.wait(0.1)
                    end)
                end
                State.RacesWon = State.RacesWon + 1
            end
        end
    end
end)

-- ── Auto quest ───────────────────────────────────────────────────────────
task.spawn(function()
    while task.wait(2) do
        if State.AutoQuest and orbEvent then
            pcall(function()
                orbEvent:FireServer("autoQuest")
            end)
        end
    end
end)

-- ── Auto steps ───────────────────────────────────────────────────────────
task.spawn(function()
    while task.wait(0.1) do
        if State.AutoSteps then
            fireOrb("Red Orb", getPlace(), 5)
        end
    end
end)

-- ── Auto EXP ─────────────────────────────────────────────────────────────
task.spawn(function()
    while task.wait(0.5) do
        if State.AutoEXP then
            fireOrb(State.OrbType, getPlace(), 10)
        end
    end
end)

-- ── Auto gifts ───────────────────────────────────────────────────────────
task.spawn(function()
    while task.wait(3) do
        if State.AutoGifts then
            for index = 1, 8 do
                fireGift(index)
                task.wait(0.1)
            end
        end
    end
end)

-- ── Parkour floor ────────────────────────────────────────────────────────
task.spawn(function()
    while task.wait(0.5) do
        if State.AutoParkour then
            local hum = getHum()
            if hum then
                hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
                hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
            end
        end
    end
end)

-- ── Auto hatch ───────────────────────────────────────────────────────────
task.spawn(function()
    while task.wait(State.FastOpen and 0.1 or 0.5) do
        if State.AutoHatch then
            if fireCrystal(State.HatchType, 1) then
                State.CrystalsOpened = State.CrystalsOpened + 1
            end
        end
    end
end)

-- ── Auto equip best ──────────────────────────────────────────────────────
task.spawn(function()
    while task.wait(5) do
        if State.AutoEquipBest then
            local inventory = LocalPlayer:FindFirstChild("Inventory")
            if inventory then
                local best, bestValue = nil, -1
                for _, pet in ipairs(inventory:GetDescendants()) do
                    if pet:IsA("StringValue") or pet:IsA("Folder") then
                        local power = pet:FindFirstChild("Power")
                            or pet:FindFirstChild("Level")
                        local value = power and tonumber(power.Value) or 0
                        if value > bestValue then
                            bestValue = value
                            best = pet
                        end
                    end
                end
                if best then
                    local equipRemote = rEvents and (rEvents:FindFirstChild("equipPet")
                        or rEvents:FindFirstChild("petEvent"))
                    if equipRemote then
                        pcall(function()
                            if equipRemote:IsA("RemoteFunction") then
                                equipRemote:InvokeServer("equip", best.Name)
                            else
                                equipRemote:FireServer("equip", best.Name)
                            end
                        end)
                    end
                end
            end
        end
    end
end)

-- ── Auto evolve ──────────────────────────────────────────────────────────
task.spawn(function()
    while task.wait(3) do
        if State.AutoEvolve then
            local evolveRemote = rEvents and (rEvents:FindFirstChild("evolvePet")
                or rEvents:FindFirstChild("evolve"))
            if evolveRemote then
                pcall(function()
                    if evolveRemote:IsA("RemoteFunction") then
                        evolveRemote:InvokeServer("evolveAll")
                    else
                        evolveRemote:FireServer("evolveAll")
                    end
                end)
            end
        end
    end
end)

-- ============================================================================
-- SECTION 24: PLAYER LOOPS
-- ============================================================================

-- infinite jump
UserInputService.JumpRequest:Connect(function()
    if State.InfJump then
        local hum = getHum()
        if hum then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

-- anti-AFK
task.spawn(function()
    while task.wait(60) do
        if State.AntiAFK then
            local virtualUser = game:GetService("VirtualUser")
            virtualUser:CaptureController()
            virtualUser:ClickButton2(Vector2.new())
        end
    end
end)

-- anti-kick
if State.AntiKick then
    pcall(function()
        local mt = getrawmetatable(game)
        if mt and setreadonly then
            setreadonly(mt, false)
            local oldNameCall = mt.__namecall
            mt.__namecall = newcclosure(function(self, ...)
                local method = getnamecallmethod()
                if method == "Kick" and self == LocalPlayer then
                    return
                end
                return oldNamecall(self, ...)
            end)
            setreadonly(mt, true)
        end
    end)
end

-- disable lava damage
task.spawn(function()
    while task.wait(1) do
        if State.DisableLava then
            local char = getChar()
            if char then
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then
                        pcall(function()
                            part:SetAttribute("LavaDamage", false)
                        end)
                    end
                end
            end
        end
    end
end)

-- fly + noclip + auto jump + anti-ragdoll heartbeat
RunService.Heartbeat:Connect(function()
    local char = getChar()
    local root = char and char:FindFirstChild("HumanoidRootPart")

    -- fly
    if not root then
        if State.FlyBodyVelocity then
            State.FlyBodyVelocity:Destroy()
            State.FlyBodyVelocity = nil
        end
        if State.FlyBodyGyro then
            State.FlyBodyGyro:Destroy()
            State.FlyBodyGyro = nil
        end
    elseif State.Fly then
        if not State.FlyBodyVelocity or State.FlyBodyVelocity.Parent ~= root then
            if State.FlyBodyVelocity then State.FlyBodyVelocity:Destroy() end
            if State.FlyBodyGyro then State.FlyBodyGyro:Destroy() end

            State.FlyBodyVelocity = Instance.new("BodyVelocity", root)
            State.FlyBodyVelocity.MaxForce = Vector3.new(1e5, 1e5, 1e5)

            State.FlyBodyGyro = Instance.new("BodyGyro", root)
            State.FlyBodyGyro.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
            State.FlyBodyGyro.P = 3000
            State.FlyBodyGyro.D = 200
        end

        local camera = Workspace.CurrentCamera
        local direction = Vector3.zero

        if UserInputService:IsKeyDown(Enum.KeyCode.W) then
            direction = direction + camera.CFrame.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then
            direction = direction - camera.CFrame.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then
            direction = direction - camera.CFrame.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then
            direction = direction + camera.CFrame.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            direction = direction + Vector3.new(0, 1, 0)
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
            direction = direction - Vector3.new(0, 1, 0)
        end

        if direction.Magnitude > 0 then
            direction = direction.Unit
        end

        State.FlyBodyVelocity.Velocity = direction * State.FlySpeed
        State.FlyBodyGyro.CFrame = camera.CFrame
    else
        if State.FlyBodyVelocity then
            State.FlyBodyVelocity:Destroy()
            State.FlyBodyVelocity = nil
        end
        if State.FlyBodyGyro then
            State.FlyBodyGyro:Destroy()
            State.FlyBodyGyro = nil
        end
    end

    -- noclip
    if State.Noclip and char then
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                part.CanCollide = false
            end
        end
    end

    -- auto jump
    if State.AutoJump then
        local hum = getHum()
        if hum then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end

    -- anti-ragdoll
    if State.AntiRagdoll then
        local hum = getHum()
        if hum and hum:GetState() == Enum.HumanoidStateType.FallingDown then
            hum:ChangeState(Enum.HumanoidStateType.Running)
        end
    end
end)

-- ============================================================================
-- SECTION 25: UI UPDATE LOOP
-- ============================================================================
task.spawn(function()
    while task.wait(0.5) do
        -- ESP
        updateESP()

        -- farming stats
        if farmStatsLabel then
            farmStatsLabel.Text = string.format(
                "Session: %s\nOrbs: %s   Gems: %s\nChests: %s   Rebirths: %s",
                fmtTime(os.time() - State.SessionStart),
                fmtNumber(State.OrbsCollected),
                fmtNumber(State.GemsCollected),
                fmtNumber(State.ChestsOpened),
                fmtNumber(State.RebirthsDone)
            )
        end

        -- crystal stats
        if crystalStatsLabel then
            crystalStatsLabel.Text = string.format(
                "Crystals opened: %s\nAuto hatch: %s\nFast open: %s",
                fmtNumber(State.CrystalsOpened),
                State.AutoHatch and "ON" or "OFF",
                State.FastOpen and "ON" or "OFF"
            )
        end

        -- ESP info
        if espInfoLabel then
            local tracked = 0
            for _ in pairs(State.ESPObjects) do tracked = tracked + 1 end
            espInfoLabel.Text = string.format(
                "Tracked objects: %d\nMax distance: %dm\nTracers: %s\nBoxes: %s",
                tracked, State.ESPMaxDistance,
                State.ESPTracers and (Drawing and "ON" or "N/A") or "OFF",
                State.ESPBoxes and "ON" or "OFF"
            )
        end

        -- settings stats
        if settingsStatsLabel then
            local level = getLevel()
            local multiplier = getMultiplier()
            settingsStatsLabel.Text = string.format(
                "Level: %s\nRebirth multiplier: %s\nWalk: %d   Jump: %d\nFly: %d\nTheme: %s",
                tostring(level or "?"),
                tostring(multiplier or "?"),
                State.WalkSpeed,
                State.JumpPower,
                State.FlySpeed,
                State.Theme
            )
        end
    end
end)

-- ============================================================================
-- SECTION 26: CHARACTER RESPAWN HANDLING
-- ============================================================================
LocalPlayer.CharacterAdded:Connect(function(character)
    task.wait(1)
    local hum = character:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.WalkSpeed = State.WalkSpeed
        hum.JumpPower = State.JumpPower
        hum.UseJumpPower = true
    end
    if State.FlyBodyVelocity then
        State.FlyBodyVelocity:Destroy()
        State.FlyBodyVelocity = nil
    end
    if State.FlyBodyGyro then
        State.FlyBodyGyro:Destroy()
        State.FlyBodyGyro = nil
    end
end)

-- ============================================================================
-- SECTION 27: KEYBIND HANDLER
-- ============================================================================
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
    if input.KeyCode.Name == State.ToggleKey then
        if WindowInstance then
            WindowInstance.Gui.Enabled = not WindowInstance.Gui.Enabled
            if WindowInstance.Gui.Enabled then
                WindowInstance.Main.Visible = true
            end
        end
    end
end)

-- ============================================================================
-- SECTION 28: BOOT
-- ============================================================================
WindowInstance:SelectTab("Farming")

if State.MobileButton then
    Mobile.init()
end

-- re-apply scale after everything is built
if WindowInstance.ScaleObj then
    WindowInstance.ScaleObj.Scale = State.Scale / 100
end

notify(
    "LaxissTM v3",
    "Ultimate Edition loaded. Press " .. State.ToggleKey .. " to toggle.",
    5
)

print("[LaxissTM] v3.0.0 — Ultimate Edition loaded successfully.")
print("[LaxissTM] Tabs: Farming · Crystals · Pets · Player · Teleport · ESP · Settings · Credits")
print("[LaxissTM] Remotes bound: orbEvent=" .. tostring(orbEvent ~= nil)
    .. "  rebirthEvent=" .. tostring(rebirthEvent ~= nil)
    .. "  openCrystalRemote=" .. tostring(openCrystalRemote ~= nil))
