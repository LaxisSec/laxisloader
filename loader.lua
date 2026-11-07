--[[
    THE BEST LEGENDS OF SPEED SCRIPT
]]

-- ============================================================
-- SERVICES
-- ============================================================
local Players     = game:GetService("Players")
local RS          = game:GetService("ReplicatedStorage")
local WS          = game:GetService("Workspace")
local UIS         = game:GetService("UserInputService")
local RunS        = game:GetService("RunService")
local SG          = game:GetService("StarterGui")
local TS          = game:GetService("TeleportService")
local HS          = game:GetService("HttpService")
local Tween       = game:GetService("TweenService")
local CG          = game:GetService("CoreGui")
local LP          = Players.LocalPlayer

local rE          = RS:WaitForChild("rEvents")
local orbEvent    = rE:WaitForChild("orbEvent")
local rebirthEvent= rE:WaitForChild("rebirthEvent")
local gf; pcall(function() gf = require(RS:WaitForChild("globalFunctions")) end)

-- ============================================================
-- STATE
-- ============================================================
local S = {
    -- farm
    AutoOrbs=false, AutoTouchOrbs=false, OrbMagnet=false,
    AutoGems=false, AutoRebirth=false, AutoHoops=false,
    AutoRace=false, AutoCrystal=false, AutoQuest=false,
    -- player
    InfJump=false, AntiAFK=false, Noclip=false, Fly=false, JumpLoop=false,
    -- esp
    ESPOrbs=false, ESPGems=false, ESPCrystals=false, ESPHoops=false,
    ESPPlayers=false, ESPDist=true, ESPTracer=false, ESPBox=false,
    -- config
    OrbType="Ethereal Orb", OrbLoc="City",
    OrbBatch=10, GemBatch=5, HoopDelay=0.1, HoopMode="Touch",
    Walk=16, Jump=50, FlySpeed=60,
    RebirthCheck=true, Notify=true, Key="RightShift",
    Theme="Cyan", Scale=1.0, MobileBtn=true,
    -- session
    CollectedOrbs=0, CollectedGems=0, Rebirths=0, StartTime=os.time(),
    ESP={}, Conn={}, FlyBV=nil, FlyBG=nil,
}
getgenv().Laxiss = S

-- ============================================================
-- THEMES
-- ============================================================
local THEMES = {
    Cyan   = {accent=Color3.fromRGB(80,200,255), bg=Color3.fromRGB(13,13,18), bar=Color3.fromRGB(20,20,28), stroke=Color3.fromRGB(45,45,60)},
    Purple = {accent=Color3.fromRGB(170,120,255), bg=Color3.fromRGB(16,12,22), bar=Color3.fromRGB(24,18,32), stroke=Color3.fromRGB(55,45,75)},
    Green  = {accent=Color3.fromRGB(80,230,140), bg=Color3.fromRGB(10,16,12),  bar=Color3.fromRGB(16,26,20), stroke=Color3.fromRGB(40,60,48)},
    Red    = {accent=Color3.fromRGB(255,100,110), bg=Color3.fromRGB(20,12,14),  bar=Color3.fromRGB(30,18,22), stroke=Color3.fromRGB(70,40,48)},
    Orange = {accent=Color3.fromRGB(255,170,80), bg=Color3.fromRGB(20,15,10),  bar=Color3.fromRGB(30,22,16), stroke=Color3.fromRGB(70,50,35)},
    Dark   = {accent=Color3.fromRGB(200,200,215), bg=Color3.fromRGB(10,10,12), bar=Color3.fromRGB(18,18,22), stroke=Color3.fromRGB(40,40,50)},
}
local function theme() return THEMES[S.Theme] or THEMES.Cyan end

-- ============================================================
-- HELPERS
-- ============================================================
local function hum() local c=LP.Character return c and c:FindFirstChildOfClass("Humanoid") end
local function root() local c=LP.Character return c and c:FindFirstChild("HumanoidRootPart") end
local function place() local ok,v=pcall(function() return LP.currentMap.Value end) return ok and v or S.OrbLoc end
local function level() local ok,v=pcall(function() return LP.level.Value end) return ok and v or nil end
local function mult() local ok,v=pcall(function() return LP.rebirthMultiplier.Value end) return ok and v or nil end
local function fireOrb(t,l,n) n=n or 1 for _=1,n do pcall(function() orbEvent:FireServer("collectOrb",t,l) end) end end
local function fireReb() pcall(function() rebirthEvent:FireServer("rebirthRequest") end) end
local function notify(t,x,d)
    if not S.Notify then return end
    pcall(function() SG:SetCore("SendNotification",{Title=t,Text=x,Duration=d or 3}) end)
end
local function fmtTime(s)
    return string.format("%02d:%02d:%02d", math.floor(s/3600), math.floor((s%3600)/60), math.floor(s%60))
end
local function findOrbs()
    local t={}
    for _,o in ipairs(WS:GetDescendants()) do
        if o:IsA("BasePart") and (o.Name:lower():find("orb") or o.Name:lower():find("gem")) then
            t[#t+1]=o
        end
    end
    return t
end
local function findCrystals()
    local t={}
    for _,o in ipairs(WS:GetDescendants()) do
        if o:IsA("BasePart") and o.Name:find("Crystal") then t[#t+1]=o end
    end
    return t
end

-- ============================================================
-- GUI BUILD
-- ============================================================
local old = CG:FindFirstChild("LaxissTM"); if old then old:Destroy() end
local oldBtn = CG:FindFirstChild("LaxissMobile"); if oldBtn then oldBtn:Destroy() end

local function new(cl,p,c)
    local i=Instance.new(cl)
    for k,v in pairs(p or {}) do i[k]=v end
    for _,ch in ipairs(c or {}) do ch.Parent=i end
    return i
end
local function corner(r,p) return new("UICorner",{CornerRadius=UDim.new(0,r or 6),Parent=p}) end
local function pad(n,p) return new("UIPadding",{
    PaddingLeft=UDim.new(0,n or 0), PaddingRight=UDim.new(0,n or 0),
    PaddingTop=UDim.new(0,n or 0), PaddingBottom=UDim.new(0,n or 0), Parent=p
}) end

local gui = new("ScreenGui",{
    Name="LaxissTM", ResetOnSpawn=false, IgnoreGuiInset=true,
    ZIndexBehavior=Enum.ZIndexBehavior.Sibling, DisplayOrder=999,
    Parent=CG,
})

-- responsive scale
local uiScale = new("UIScale",{Scale=S.Scale, Parent=gui})

local main = new("Frame",{
    Name="Main", Size=UDim2.fromOffset(560,420),
    Position=UDim2.new(0.5,-280,0.5,-210),
    BackgroundColor3=theme().bg, BorderSizePixel=0, Active=true,
    Parent=gui,
})
corner(10,main)
local mainStroke = new("UIStroke",{Color=theme().stroke,Thickness=1,Parent=main})

-- title bar
local topBar = new("Frame",{
    Name="TopBar", Size=UDim2.new(1,0,0,38),
    BackgroundColor3=theme().bar, BorderSizePixel=0, Parent=main,
})
corner(10,topBar)
-- cover bottom corners of topbar with a small frame
new("Frame",{Size=UDim2.new(1,0,0,10),Position=UDim2.new(0,0,1,-10),BackgroundColor3=theme().bar,BorderSizePixel=0,Parent=topBar})

new("TextLabel",{
    Size=UDim2.new(1,-90,1,0), Position=UDim2.fromOffset(16,0),
    BackgroundTransparency=1, Text="LaxissTM",
    TextColor3=theme().accent, Font=Enum.Font.GothamBlack,
    TextSize=15, TextXAlignment=Enum.TextXAlignment.Left, Parent=topBar,
})
new("TextLabel",{
    Size=UDim2.new(1,-90,1,0), Position=UDim2.fromOffset(110,0),
    BackgroundTransparency=1, Text="v2  ·  Legends of Speed",
    TextColor3=Color3.fromRGB(130,130,145), Font=Enum.Font.Gotham,
    TextSize=11, TextXAlignment=Enum.TextXAlignment.Left, Parent=topBar,
})

local function titleBtn(text, x, color, cb)
    local b=new("TextButton",{
        Size=UDim2.fromOffset(32,32), Position=UDim2.new(1,x,0.5,-16),
        BackgroundTransparency=1, Text=text, TextColor3=color or Color3.fromRGB(190,190,205),
        Font=Enum.Font.GothamBold, TextSize=16, Parent=topBar,
    })
    b.MouseButton1Click:Connect(function() if cb then cb() end end)
    return b
end
titleBtn("—", -100, nil, function() main.Visible = false; enableMobile() end)
titleBtn("×", -34, Color3.fromRGB(220,120,120), function() gui.Enabled=false end)

-- drag logic for the whole top bar
local dragStart, startPos
topBar.InputBegan:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
        dragStart=i.Position; startPos=main.Position
    end
end)
UIS.InputChanged:Connect(function(i)
    if dragStart and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
        local d = i.Position - dragStart
        main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
    end
end)
UIS.InputEnded:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
        dragStart=nil
    end
end)

-- tab bar (left column, vertical)
local tabBar = new("Frame",{
    Size=UDim2.new(0,120,1,-38), Position=UDim2.fromOffset(0,38),
    BackgroundColor3=theme().bar, BorderSizePixel=0, Parent=main,
})
pad(8,tabBar)

-- close-to-bottom corners on tabBar
new("Frame",{Size=UDim2.new(1,0,0,10),Position=UDim2.new(0,0,1,-10),BackgroundColor3=theme().bar,BorderSizePixel=0,Parent=tabBar})

local tabList = new("Frame",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Parent=tabBar})
new("UIListLayout",{Padding=UDim.new(0,4),SortOrder=Enum.SortOrder.LayoutOrder,Parent=tabList})

-- content area
local contentWrap = new("Frame",{
    Size=UDim2.new(1,-120,1,-38), Position=UDim2.fromOffset(120,38),
    BackgroundTransparency=1, Parent=main,
})
pad(10,contentWrap)
local content = new("Frame",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Parent=contentWrap})

local tabs, tabBtns = {}, {}
local function selectTab(n)
    for k,f in pairs(tabs) do f.Visible=(k==n) end
    for k,b in pairs(tabBtns) do
        b.BackgroundColor3 = (k==n) and theme().accent or Color3.fromRGB(28,28,38)
        b.TextColor3 = (k==n) and Color3.fromRGB(10,10,15) or Color3.fromRGB(180,180,195)
    end
end
local function makeTab(n)
    local b=new("TextButton",{
        Size=UDim2.new(1,0,0,30), BackgroundColor3=Color3.fromRGB(28,28,38),
        BorderSizePixel=0, Text=n, TextColor3=Color3.fromRGB(180,180,195),
        Font=Enum.Font.GothamBold, TextSize=12, Parent=tabList,
    })
    corner(6,b)
    tabBtns[n]=b
    local f=new("ScrollingFrame",{
        Size=UDim2.fromScale(1,1), BackgroundTransparency=1, BorderSizePixel=0,
        ScrollBarThickness=4, ScrollBarImageColor3=theme().accent,
        CanvasSize=UDim2.new(0,0,0,0), AutomaticCanvasSize=Enum.AutomaticSize.Y,
        Visible=false, Parent=content,
    })
    tabs[n]=f
    b.MouseButton1Click:Connect(function() selectTab(n) end)
    return f
end

local function section(p,t,y)
    local l = new("TextLabel",{
        Size=UDim2.new(1,0,0,22), Position=UDim2.fromOffset(0,y),
        BackgroundTransparency=1, Text=t, TextColor3=theme().accent,
        Font=Enum.Font.GothamBold, TextSize=11,
        TextXAlignment=Enum.TextXAlignment.Left, Parent=p,
    })
    new("Frame",{Size=UDim2.new(1,0,0,1),Position=UDim2.new(0,0,1,-1),BackgroundColor3=theme().stroke,BorderSizePixel=0,Parent=l})
end

-- ============================================================
-- WIDGETS
-- ============================================================
local function toggle(p,lbl,def,cb,y)
    local r=new("Frame",{Size=UDim2.new(1,0,0,32),Position=UDim2.fromOffset(0,y),BackgroundTransparency=1,Parent=p})
    new("TextLabel",{Size=UDim2.new(1,-70,1,0),BackgroundTransparency=1,Text=lbl,
        TextColor3=Color3.fromRGB(205,205,215),Font=Enum.Font.Gotham,TextSize=12,
        TextXAlignment=Enum.TextXAlignment.Left,Parent=r})
    local b=new("TextButton",{
        Size=UDim2.fromOffset(46,22),Position=UDim2.new(1,-46,0.5,-11),
        BackgroundColor3=def and theme().accent or Color3.fromRGB(35,35,48),
        BorderSizePixel=0,Text=def and "ON" or "OFF",
        TextColor3=def and Color3.fromRGB(10,10,15) or Color3.fromRGB(220,220,230),
        Font=Enum.Font.GothamBold,TextSize=10,Parent=r})
    corner(11,b)
    local s=def
    b.MouseButton1Click:Connect(function()
        s=not s; b.Text=s and "ON" or "OFF"
        b.BackgroundColor3 = s and theme().accent or Color3.fromRGB(35,35,48)
        b.TextColor3 = s and Color3.fromRGB(10,10,15) or Color3.fromRGB(220,220,230)
        if cb then cb(s) end
    end)
end

local function slider(p,lbl,mn,mx,def,cb,y)
    local c=new("Frame",{Size=UDim2.new(1,0,0,48),Position=UDim2.fromOffset(0,y),BackgroundTransparency=1,Parent=p})
    local lb=new("TextLabel",{Size=UDim2.new(1,0,0,18),BackgroundTransparency=1,
        Text=lbl..": "..tostring(def),TextColor3=Color3.fromRGB(205,205,215),
        Font=Enum.Font.Gotham,TextSize=12,TextXAlignment=Enum.TextXAlignment.Left,Parent=c})
    local tr=new("Frame",{Size=UDim2.new(1,-12,0,5),Position=UDim2.fromOffset(0,30),
        BackgroundColor3=Color3.fromRGB(35,35,48),BorderSizePixel=0,Parent=c}); corner(3,tr)
    local fl=new("Frame",{Size=UDim2.fromScale((def-mn)/(mx-mn),1),
        BackgroundColor3=theme().accent,BorderSizePixel=0,Parent=tr}); corner(3,fl)
    local kn=new("Frame",{Size=UDim2.fromOffset(12,12),
        Position=UDim2.new(fl.Size.X.Scale,-6,0.5,-6),
        BackgroundColor3=Color3.fromRGB(200,225,255),BorderSizePixel=0,Parent=tr}); corner(6,kn)
    local dr,val=false,def
    local function upd(x)
        local rel=math.clamp((x-tr.AbsolutePosition.X)/tr.AbsoluteSize.X,0,1)
        val=math.floor(mn+(mx-mn)*rel+0.5)
        fl.Size=UDim2.fromScale(rel,1); kn.Position=UDim2.new(rel,-6,0.5,-6)
        lb.Text=lbl..": "..tostring(val)
        if cb then cb(val) end
    end
    tr.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
            dr=true; upd(i.Position.X)
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if dr and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
            upd(i.Position.X)
        end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dr=false end
    end)
end

local function dropdown(p,lbl,opts,def,cb,y)
    local r=new("Frame",{Size=UDim2.new(1,0,0,32),Position=UDim2.fromOffset(0,y),BackgroundTransparency=1,Parent=p})
    new("TextLabel",{Size=UDim2.new(1,-170,1,0),BackgroundTransparency=1,Text=lbl,
        TextColor3=Color3.fromRGB(205,205,215),Font=Enum.Font.Gotham,TextSize=12,
        TextXAlignment=Enum.TextXAlignment.Left,Parent=r})
    local b=new("TextButton",{
        Size=UDim2.fromOffset(160,24),Position=UDim2.new(1,-160,0.5,-12),
        BackgroundColor3=Color3.fromRGB(28,28,40),BorderSizePixel=0,
        Text=def,TextColor3=Color3.fromRGB(200,200,215),
        Font=Enum.Font.Gotham,TextSize=11,Parent=r}); corner(4,b)
    local i=1
    for k,v in ipairs(opts) do if v==def then i=k break end end
    b.MouseButton1Click:Connect(function()
        i=i%#opts+1; b.Text=opts[i]; if cb then cb(opts[i]) end
    end)
end

local function button(p,t,cb,y,col)
    local b=new("TextButton",{
        Size=UDim2.new(1,0,0,28),Position=UDim2.fromOffset(0,y),
        BackgroundColor3=col or Color3.fromRGB(32,32,46),BorderSizePixel=0,
        Text=t,TextColor3=Color3.fromRGB(210,210,225),
        Font=Enum.Font.Gotham,TextSize=12,Parent=p}); corner(4,b)
    b.MouseButton1Click:Connect(function() if cb then pcall(cb) end end)
    return b
end

local function label(p,t,y,h)
    return new("TextLabel",{
        Size=UDim2.new(1,0,0,h or 18),Position=UDim2.fromOffset(0,y),
        BackgroundTransparency=1,Text=t,TextColor3=Color3.fromRGB(140,140,155),
        Font=Enum.Font.Gotham,TextSize=11,TextXAlignment=Enum.TextXAlignment.Left,
        TextWrapped=true,Parent=p})
end

-- forward decl
local clearESP
local espFolder = new("Folder",{Name="LaxissESP",Parent=gui})

-- ============================================================
-- TAB: FARMING
-- ============================================================
local fT = makeTab("Farming"); local y = 4
section(fT,"ORBS",y); y=y+26
dropdown(fT,"Orb Type",{"Ethereal Orb","Red Orb","Blue Orb","Yellow Orb","Orange Orb","Rainbow Orb"},S.OrbType,function(v) S.OrbType=v end,y); y=y+34
dropdown(fT,"Location",{"City","Desert","Magma City","Grassland","Jungle","Legends Highway"},S.OrbLoc,function(v) S.OrbLoc=v end,y); y=y+34
slider(fT,"Orb Batch",1,50,S.OrbBatch,function(v) S.OrbBatch=v end,y); y=y+50
toggle(fT,"Auto Orbs (remote)",false,function(v) S.AutoOrbs=v end,y); y=y+34
toggle(fT,"Auto Orb Touch (physical)",false,function(v) S.AutoTouchOrbs=v end,y); y=y+34
toggle(fT,"Orb Magnet",false,function(v) S.OrbMagnet=v end,y); y=y+34
section(fT,"GEMS",y); y=y+26
slider(fT,"Gem Batch",1,20,S.GemBatch,function(v) S.GemBatch=v end,y); y=y+50
toggle(fT,"Auto Gems",false,function(v) S.AutoGems=v end,y); y=y+34
section(fT,"REBIRTH",y); y=y+26
toggle(fT,"Auto Rebirth",false,function(v) S.AutoRebirth=v end,y); y=y+34
toggle(fT,"Level Check",true,function(v) S.RebirthCheck=v end,y); y=y+34
section(fT,"HOOPS",y); y=y+26
dropdown(fT,"Hoop Mode",{"Touch","Teleport"},S.HoopMode,function(v) S.HoopMode=v end,y); y=y+34
slider(fT,"Hoop Delay (ms)",50,1000,S.HoopDelay*1000,function(v) S.HoopDelay=v/1000 end,y); y=y+50
toggle(fT,"Auto Hoops",false,function(v) S.AutoHoops=v end,y); y=y+34
section(fT,"OTHER",y); y=y+26
toggle(fT,"Auto Crystal",false,function(v) S.AutoCrystal=v end,y); y=y+34
toggle(fT,"Auto Race",false,function(v) S.AutoRace=v end,y); y=y+34
toggle(fT,"Auto Quest",false,function(v) S.AutoQuest=v end,y)

-- ============================================================
-- TAB: PLAYER
-- ============================================================
local pT = makeTab("Player"); y=4
section(pT,"MOVEMENT",y); y=y+26
slider(pT,"WalkSpeed",16,300,S.Walk,function(v) S.Walk=v; local h=hum(); if h then h.WalkSpeed=v end end,y); y=y+50
slider(pT,"JumpPower",50,300,S.Jump,function(v) S.Jump=v; local h=hum(); if h then h.JumpPower=v; h.UseJumpPower=true end end,y); y=y+50
toggle(pT,"Infinite Jump",false,function(v) S.InfJump=v end,y); y=y+34
toggle(pT,"Auto Jump",false,function(v) S.JumpLoop=v end,y); y=y+34
toggle(pT,"Fly",false,function(v) S.Fly=v end,y); y=y+34
slider(pT,"Fly Speed",20,300,S.FlySpeed,function(v) S.FlySpeed=v end,y); y=y+50
toggle(pT,"Noclip",false,function(v) S.Noclip=v end,y); y=y+34
section(pT,"UTILITY",y); y=y+26
toggle(pT,"Anti-AFK",false,function(v) S.AntiAFK=v end,y); y=y+34
button(pT,"Reset Character",function()
    local c=LP.Character; if c then c:BreakJoints() end
end,y); y=y+32
button(pT,"Rejoin Server",function() TS:Teleport(game.PlaceId,LP) end,y); y=y+32
button(pT,"Server Hop",function()
    local list=HS:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100"))
    for _,s in ipairs(list.data or {}) do
        if s.playing < s.maxPlayers and s.id ~= game.JobId then
            TS:TeleportToPlaceInstance(game.PlaceId, s.id, LP); return
        end
    end
    notify("LaxissTM","No open servers found.",3)
end,y)

-- ============================================================
-- TAB: TELEPORT
-- ============================================================
local tT = makeTab("Teleport"); y=4
local maps = {
    ["City"]=Vector3.new(-130,5,10), ["Desert"]=Vector3.new(1050,10,250),
    ["Magma City"]=Vector3.new(-150,5,1450), ["Grassland"]=Vector3.new(500,5,-400),
    ["Jungle"]=Vector3.new(-900,5,-900), ["Legends Highway"]=Vector3.new(2000,10,2000),
}
local mapNames = {}
for n in pairs(maps) do mapNames[#mapNames+1]=n end
table.sort(mapNames)
local selMap = mapNames[1] or "City"
section(tT,"MAPS",y); y=y+26
dropdown(tT,"Destination",mapNames,selMap,function(v) selMap=v end,y); y=y+34
button(tT,"Teleport to Map",function()
    local r=root(); local p=maps[selMap]
    if r and p then r.CFrame=CFrame.new(p) end
end,y); y=y+32
button(tT,"Teleport to Spawn",function()
    local sp=WS:FindFirstChildOfClass("SpawnLocation"); local r=root()
    if sp and r then r.CFrame=sp.CFrame+Vector3.new(0,4,0) end
end,y); y=y+32
section(tT,"PLAYERS",y); y=y+26
local pList,pTarget = {},nil
local function refreshPlayers()
    pList={}
    for _,p in ipairs(Players:GetPlayers()) do if p~=LP then pList[#pList+1]=p.Name end end
    if #pList==0 then pList={"<none>"} end
    pTarget=pList[1]
end
refreshPlayers()
dropdown(tT,"Target Player",pList,pTarget,function(v) pTarget=v end,y); y=y+34
button(tT,"Teleport to Player",function()
    for _,p in ipairs(Players:GetPlayers()) do
        if p.Name==pTarget and p.Character then
            local hr=p.Character:FindFirstChild("HumanoidRootPart"); local r=root()
            if hr and r then r.CFrame=hr.CFrame+Vector3.new(0,2,0) end
        end
    end
end,y); y=y+32
button(tT,"Refresh Player List",function() refreshPlayers(); notify("LaxissTM","Refreshed.",2) end,y)

-- ============================================================
-- TAB: ESP
-- ============================================================
local eT = makeTab("ESP"); y=4
section(eT,"TOGGLES",y); y=y+26
toggle(eT,"ESP Orbs",false,function(v) S.ESPOrbs=v; if not v then clearESP("Orb") end end,y); y=y+34
toggle(eT,"ESP Gems",false,function(v) S.ESPGems=v; if not v then clearESP("Gem") end end,y); y=y+34
toggle(eT,"ESP Crystals",false,function(v) S.ESPCrystals=v; if not v then clearESP("Crystal") end end,y); y=y+34
toggle(eT,"ESP Hoops",false,function(v) S.ESPHoops=v; if not v then clearESP("Hoop") end end,y); y=y+34
toggle(eT,"ESP Players",false,function(v) S.ESPPlayers=v; if not v then clearESP("Player") end end,y); y=y+34
section(eT,"OPTIONS",y); y=y+26
toggle(eT,"Show Distance",true,function(v) S.ESPDist=v end,y); y=y+34
toggle(eT,"Player Tracers",false,function(v) S.ESPTracer=v; if not v then clearESP("Tracer") end end,y); y=y+34
section(eT,"INFO",y); y=y+26
local infoL = label(eT,"",y,80)

-- ============================================================
-- TAB: SETTINGS
-- ============================================================
local sT = makeTab("Settings"); y=4
section(sT,"APPEARANCE",y); y=y+26
dropdown(sT,"Theme",{"Cyan","Purple","Green","Red","Orange","Dark"},S.Theme,function(v)
    S.Theme=v
    notify("LaxissTM","Theme set to "..v..". Reopen to apply fully.",3)
    applyTheme()
end,y); y=y+34
slider(sT,"UI Scale",70,150,S.Scale*100,function(v) S.Scale=v/100; uiScale.Scale=v/100 end,y); y=y+50
toggle(sT,"Mobile Toggle Button",true,function(v) S.MobileBtn=v; if v then enableMobile() else disableMobile() end end,y); y=y+34
section(sT,"CONTROLS",y); y=y+26
local keyBtn
keyBtn = button(sT,"Toggle Key: "..S.Key,function()
    keyBtn.Text="Press any key..."
    local conn
    conn = UIS.InputBegan:Connect(function(i,proc)
        if proc then return end
        if i.UserInputType==Enum.UserInputType.Keyboard then
            S.Key=i.KeyCode.Name
            keyBtn.Text="Toggle Key: "..S.Key
            conn:Disconnect()
        end
    end)
end,y); y=y+32
toggle(sT,"Notifications",true,function(v) S.Notify=v end,y); y=y+34
section(sT,"CONFIG",y); y=y+26
button(sT,"Save Config",function()
    local save={}
    for k,v in pairs(S) do
        if type(v)=="boolean" or type(v)=="number" or type(v)=="string" then save[k]=v end
    end
    pcall(function() writefile("LaxissTM_v2_config.json", HS:JSONEncode(save)) end)
    notify("LaxissTM","Config saved.",2)
end,y); y=y+32
button(sT,"Load Config",function()
    pcall(function()
        local d=HS:JSONDecode(readfile("LaxissTM_v2_config.json"))
        for k,v in pairs(d) do if S[k]~=nil then S[k]=v end end
        local h=hum(); if h then h.WalkSpeed=S.Walk; h.JumpPower=S.Jump; h.UseJumpPower=true end
        uiScale.Scale=S.Scale
    end)
    notify("LaxissTM","Config loaded. Some toggles need re-applying.",3)
end,y); y=y+32
section(sT,"SESSION",y); y=y+26
local statsL = label(sT,"",y,90); y=y+94
section(sT,"ABOUT",y); y=y+26
label(sT,"LaxissTM v2 · Full Build\nExecutor-agnostic · No key system\nAll remotes sourced from live game dumps.",y,60)

-- ============================================================
-- THEME APPLY
-- ============================================================
function applyTheme()
    local t=theme()
    main.BackgroundColor3=t.bg
    topBar.BackgroundColor3=t.bar
    tabBar.BackgroundColor3=t.bar
    mainStroke.Color=t.stroke
    for _,b in pairs(tabBtns) do
        if b.TextColor3 ~= Color3.fromRGB(10,10,15) then b.BackgroundColor3=Color3.fromRGB(28,28,38) end
    end
    for _,f in pairs(tabs) do
        local sb = f:FindFirstChildOfClass("ScrollBarImageColor3") or nil
        f.ScrollBarImageColor3 = t.accent
    end
end

-- ============================================================
-- MOBILE TOGGLE BUTTON
-- ============================================================
local mobileBtn
local function enableMobile()
    if mobileBtn and mobileBtn.Parent then return end
    if not S.MobileBtn then return end
    mobileBtn = new("ScreenGui",{Name="LaxissMobile",ResetOnSpawn=false,IgnoreGuiInset=true,DisplayOrder=1000,Parent=CG})
    local f = new("Frame",{
        Size=UDim2.fromOffset(56,56), Position=UDim2.new(1,-80,0.5,-28),
        BackgroundColor3=theme().accent, BorderSizePixel=0, Active=true, Parent=mobileBtn,
    })
    corner(28,f)
    new("TextLabel",{
        Size=UDim2.fromScale(1,1), BackgroundTransparency=1, Text="Lx",
        TextColor3=Color3.fromRGB(10,10,15), Font=Enum.Font.GothamBlack, TextSize=16, Parent=f,
    })
    local dragStart, startPos
    f.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
            dragStart=i.Position; startPos=f.Position
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if dragStart and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
            local d=i.Position-dragStart
            f.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+d.X,startPos.Y.Scale,startPos.Y.Offset+d.Y)
        end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dragStart=nil end
    end)
    -- tap vs drag
    local pressTime, pressPos
    f.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
            pressTime=os.clock(); pressPos=i.Position
        end
    end)
    f.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
            if pressTime and (os.clock()-pressTime)<0.3 and (i.Position-pressPos).Magnitude<10 then
                gui.Enabled = not gui.Enabled
                main.Visible = true
                if gui.Enabled then f.BackgroundColor3=theme().accent else f.BackgroundColor3=Color3.fromRGB(80,80,90) end
            end
        end
    end)
    f.BackgroundColor3 = gui.Enabled and theme().accent or Color3.fromRGB(80,80,90)
end
local function disableMobile()
    if mobileBtn then mobileBtn:Destroy(); mobileBtn=nil end
end

-- ============================================================
-- ESP IMPL
-- ============================================================
clearESP = function(cat)
    for k,o in pairs(S.ESP) do
        if o.Cat==cat then
            if o.BB then o.BB:Destroy() end
            if o.Tracer then o.Tracer:Destroy() end
            S.ESP[k]=nil
        end
    end
end
local function mkBB(ador,text,col)
    local b=new("BillboardGui",{Size=UDim2.fromOffset(130,24),StudsOffset=Vector3.new(0,3,0),AlwaysOnTop=true,Adornee=ador,Parent=espFolder})
    new("TextLabel",{Name="Lbl",Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Text=text,TextColor3=col,Font=Enum.Font.GothamBold,TextSize=11,TextStrokeTransparency=0.5,Parent=b})
    return b
end
local function distTo(part)
    local r=root(); if not r or not part then return 0 end
    return math.floor((r.Position-part.Position).Magnitude)
end
local function updateESP()
    if S.ESPOrbs then
        for _,o in ipairs(findOrbs()) do
            if not S.ESP[o] then
                S.ESP[o]={BB=mkBB(o,o.Name,Color3.fromRGB(255,220,100)),Cat="Orb",Base=o.Name}
            end
            local e=S.ESP[o]
            if e and e.BB and S.ESPDist then e.BB.Lbl.Text=e.Base.." ["..distTo(o).."m]"
            elseif e and e.BB then e.BB.Lbl.Text=e.Base end
        end
    end
    if S.ESPGems then
        for _,o in ipairs(findOrbs()) do
            if o.Name:lower():find("gem") and not S.ESP[o] then
                S.ESP[o]={BB=mkBB(o,o.Name,Color3.fromRGB(120,255,180)),Cat="Gem",Base=o.Name}
            end
        end
    end
    if S.ESPCrystals then
        for _,o in ipairs(findCrystals()) do
            if not S.ESP[o] then
                S.ESP[o]={BB=mkBB(o,"Crystal",Color3.fromRGB(120,230,255)),Cat="Crystal",Base="Crystal"}
            end
        end
    end
    if S.ESPHoops then
        local hf=WS:FindFirstChild("Hoops")
        if hf then for _,o in ipairs(hf:GetChildren()) do
            if o:IsA("BasePart") and not S.ESP[o] then
                S.ESP[o]={BB=mkBB(o,"Hoop",Color3.fromRGB(180,255,150)),Cat="Hoop",Base="Hoop"}
            end
        end end
    end
    if S.ESPPlayers then
        for _,p in ipairs(Players:GetPlayers()) do
            if p~=LP and p.Character then
                local h=p.Character:FindFirstChild("Head")
                if h and not S.ESP[p] then
                    S.ESP[p]={BB=mkBB(h,p.Name,Color3.fromRGB(255,120,120)),Cat="Player",Base=p.Name}
                end
            end
        end
    end
end

-- ============================================================
-- LOOPS
-- ============================================================
task.spawn(function() while task.wait(0.1) do
    if S.AutoOrbs then fireOrb(S.OrbType,place(),S.OrbBatch); S.CollectedOrbs=S.CollectedOrbs+S.OrbBatch end
end end)

task.spawn(function() while task.wait(0.1) do
    if S.AutoGems then
        for _,l in ipairs({"City","Desert","Magma City"}) do fireOrb("Gem",l,S.GemBatch) end
        S.CollectedGems=S.CollectedGems+S.GemBatch*3
    end
end end)

task.spawn(function() while task.wait(0.1) do
    if S.AutoTouchOrbs then
        local r=root()
        if r then
            for _,o in ipairs(findOrbs()) do
                pcall(function() firetouchinterest(r,o,0); task.wait(); firetouchinterest(r,o,1) end)
            end
        end
    end
end end)

task.spawn(function() while task.wait(0.2) do
    if S.OrbMagnet then
        local r=root()
        if r then
            for _,o in ipairs(findOrbs()) do
                pcall(function() o.CFrame=r.CFrame end)
            end
        end
    end
end end)

task.spawn(function() while task.wait(1) do
    if S.AutoRebirth then
        local ok=true
        if S.RebirthCheck and gf then pcall(function()
            local lv,mul=level(),mult()
            if lv and mul then ok=(tonumber(gf.calculateRequiredRebirthLevel(mul-1))==tonumber(lv)) end
        end) end
        if ok then fireReb(); S.Rebirths=S.Rebirths+1 end
    end
end end)

task.spawn(function() while task.wait(S.HoopDelay) do
    if S.AutoHoops then
        local r=root(); local hp=WS:FindFirstChild("Hoops")
        if r and hp then
            for _,h in ipairs(hp:GetChildren()) do
                if h:IsA("BasePart") then
                    if S.HoopMode=="Touch" then
                        pcall(function() firetouchinterest(r,h,0); task.wait(); firetouchinterest(r,h,1) end)
                    else
                        pcall(function() h.CFrame=r.CFrame end)
                    end
                end
            end
        end
    end
end end)

task.spawn(function() while task.wait(0.3) do
    if S.AutoCrystal then
        local r=root()
        if r then for _,c in ipairs(findCrystals()) do
            pcall(function() firetouchinterest(r,c,0); task.wait(); firetouchinterest(r,c,1) end)
        end end
    end
end end)

task.spawn(function() while task.wait(0.1) do
    if S.AutoRace then
        local r=root()
        if r then for _,rp in ipairs(WS:GetDescendants()) do
            if rp:IsA("BasePart") and rp.Name:lower():find("checkpoint") then
                pcall(function() firetouchinterest(r,rp,0); task.wait(); firetouchinterest(r,rp,1) end)
            end
        end end
    end
end end)

task.spawn(function() while task.wait(2) do
    if S.AutoQuest then
        pcall(function() orbEvent:FireServer("autoQuest") end)
    end
end end)

UIS.JumpRequest:Connect(function()
    if S.InfJump then local h=hum(); if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end end
end)

-- fly/noclip
local function stopFly()
    if S.FlyBV then S.FlyBV:Destroy(); S.FlyBV=nil end
    if S.FlyBG then S.FlyBG:Destroy(); S.FlyBG=nil end
end
RunS.Heartbeat:Connect(function()
    local char=LP.Character
    local hr=char and char:FindFirstChild("HumanoidRootPart")
    if not hr then stopFly(); return end
    if S.Fly then
        if not S.FlyBV or S.FlyBV.Parent~=hr then
            stopFly()
            S.FlyBV=Instance.new("BodyVelocity",hr)
            S.FlyBV.MaxForce=Vector3.new(1e5,1e5,1e5)
            S.FlyBG=Instance.new("BodyGyro",hr)
            S.FlyBG.MaxTorque=Vector3.new(1e5,1e5,1e5)
            S.FlyBG.P=3000; S.FlyBG.D=200
        end
        local cam=WS.CurrentCamera
        local dir=Vector3.zero
        if UIS:IsKeyDown(Enum.KeyCode.W) then dir=dir+cam.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.S) then dir=dir-cam.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.A) then dir=dir-cam.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then dir=dir+cam.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then dir=dir+Vector3.new(0,1,0) end
        if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then dir=dir-Vector3.new(0,1,0) end
        if dir.Magnitude>0 then dir=dir.Unit end
        S.FlyBV.Velocity=dir*S.FlySpeed
        S.FlyBG.CFrame=cam.CFrame
    else
        stopFly()
    end
    if S.Noclip then
        for _,o in ipairs(char:GetDescendants()) do
            if o:IsA("BasePart") and o.CanCollide then o.CanCollide=false end
        end
    end
    if S.JumpLoop then
        local h=hum(); if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

task.spawn(function() while task.wait(60) do
    if S.AntiAFK then
        local v=game:GetService("VirtualUser")
        v:CaptureController(); v:ClickButton2(Vector2.new())
    end
end end)

task.spawn(function() while task.wait(0.5) do
    updateESP()
    infoL.Text = string.format(
        "Level: %s  |  Multiplier: %s\nMap: %s\nTracked ESP: %d",
        tostring(level() or "?"), tostring(mult() or "?"), tostring(place() or "?"),
        (function() local n=0 for _ in pairs(S.ESP) do n=n+1 end return n end)()
    )
    statsL.Text = string.format(
        "Session: %s\nOrbs: %d   Gems: %d   Rebirths: %d\nWalk: %d   Jump: %d   Fly: %d",
        fmtTime(os.time()-S.StartTime), S.CollectedOrbs, S.CollectedGems, S.Rebirths,
        S.Walk, S.Jump, S.FlySpeed
    )
end end)

LP.CharacterAdded:Connect(function(ch)
    task.wait(1)
    local h=ch:FindFirstChildOfClass("Humanoid")
    if h then h.WalkSpeed=S.Walk; h.JumpPower=S.Jump; h.UseJumpPower=true end
    stopFly()
end)

-- ============================================================
-- INIT
-- ============================================================
selectTab("Farming")
applyTheme()
if S.MobileBtn then enableMobile() end

UIS.InputBegan:Connect(function(i,proc)
    if proc then return end
    if i.KeyCode.Name==S.Key then
        gui.Enabled=not gui.Enabled
        if gui.Enabled then main.Visible=true end
    end
end)

notify("LaxissTM v2","Loaded. Key: "..S.Key.."  ·  Mobile button active.",5)
print("[LaxissTM] v2 loaded.")