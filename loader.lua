--[[ LaxissTM | Full Build | Legends of Speed | single paste, no deps ]]
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local WS = game:GetService("Workspace")
local UIS = game:GetService("UserInputService")
local RunS = game:GetService("RunService")
local SG = game:GetService("StarterGui")
local TS = game:GetService("TeleportService")
local HS = game:GetService("HttpService")
local LP = Players.LocalPlayer
local rE = RS:WaitForChild("rEvents")
local orbEvent = rE:WaitForChild("orbEvent")
local rebirthEvent = rE:WaitForChild("rebirthEvent")
local gf; pcall(function() gf = require(RS:WaitForChild("globalFunctions")) end)

-- ============================================================
-- STATE
-- ============================================================
local S = {
    Orbs=false, Gems=false, Rebirth=false, Hoops=false, Magnet=false, TouchOrbs=false,
    InfJump=false, AntiAFK=false, Noclip=false, Fly=false,
    ESPOrbs=false, ESPCrystals=false, ESPPlayers=false, ESPHoops=false, ESPDist=true,
    OrbType="Ethereal Orb", OrbLoc="City", OrbBatch=10, GemBatch=5,
    HoopMode="Touch", HoopDelay=0.1, Walk=16, Jump=50, FlySpeed=60,
    RebirthCheck=true, Notify=true, Key="RightShift",
    CollectedOrbs=0, CollectedGems=0, Rebirths=0, StartTime=os.time(),
    ESP={}
}
getgenv().Laxiss = S

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
local function notify(t,x,d) if not S.Notify then return end pcall(function() SG:SetCore("SendNotification",{Title=t,Text=x,Duration=d or 3}) end) end
local function fmtTime(s) return string.format("%02d:%02d:%02d", math.floor(s/3600), math.floor(s%3600/60), math.floor(s%60)) end
local function findOrbs()
    local t={}
    for _,o in ipairs(WS:GetDescendants()) do
        if o:IsA("BasePart") and (o.Name:lower():find("orb") or o.Name:lower():find("gem")) then t[#t+1]=o end
    end
    return t
end

-- ============================================================
-- GUI BASE
-- ============================================================
local old = game:GetService("CoreGui"):FindFirstChild("LaxissTM"); if old then old:Destroy() end
local function new(cl,p,c)
    local i=Instance.new(cl)
    for k,v in pairs(p or {}) do i[k]=v end
    for _,ch in ipairs(c or {}) do ch.Parent=i end
    return i
end
local function corner(r,p) return new("UICorner",{CornerRadius=UDim.new(0,r or 6),Parent=p}) end
local gui = new("ScreenGui",{Name="LaxissTM",ResetOnSpawn=false,IgnoreGuiInset=true,ZIndexBehavior=Enum.ZIndexBehavior.Sibling,Parent=game:GetService("CoreGui")})
local main = new("Frame",{Size=UDim2.fromOffset(500,360),Position=UDim2.fromOffset(80,80),BackgroundColor3=Color3.fromRGB(13,13,18),BorderSizePixel=0,Active=true,Draggable=true,Parent=gui})
corner(8,main)
new("UIStroke",{Color=Color3.fromRGB(45,45,60),Thickness=1,Parent=main})
local top = new("Frame",{Size=UDim2.new(1,0,0,34),BackgroundColor3=Color3.fromRGB(20,20,28),BorderSizePixel=0,Parent=main})
corner(8,top)
new("TextLabel",{Size=UDim2.new(1,-40,1,0),Position=UDim2.fromOffset(14,0),BackgroundTransparency=1,Text="LaxissTM  |  Legends of Speed",TextColor3=Color3.fromRGB(170,210,255),Font=Enum.Font.GothamBold,TextSize=13,TextXAlignment=Enum.TextXAlignment.Left,Parent=top})
local close = new("TextButton",{Size=UDim2.fromOffset(34,34),Position=UDim2.new(1,-34,0,0),BackgroundTransparency=1,Text="×",TextColor3=Color3.fromRGB(200,120,120),Font=Enum.Font.GothamBold,TextSize=18,Parent=top})
close.MouseButton1Click:Connect(function() gui.Enabled=false end)
local tabBar = new("Frame",{Size=UDim2.new(1,0,0,30),Position=UDim2.fromOffset(0,34),BackgroundColor3=Color3.fromRGB(16,16,23),BorderSizePixel=0,Parent=main})
local content = new("Frame",{Size=UDim2.new(1,-16,1,-78),Position=UDim2.fromOffset(8,70),BackgroundTransparency=1,Parent=main})
local tabs, order = {}, {}
local function selectTab(n) for k,f in pairs(tabs) do f.Visible=(k==n) end end
local function makeTab(n)
    local b=new("TextButton",{Size=UDim2.fromOffset(90,30),Position=UDim2.fromOffset(#order*92+4,0),BackgroundColor3=Color3.fromRGB(20,20,28),BorderSizePixel=0,Text=n,TextColor3=Color3.fromRGB(150,150,165),Font=Enum.Font.Gotham,TextSize=12,Parent=tabBar})
    corner(4,b)
    local f=new("ScrollingFrame",{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=4,ScrollBarImageColor3=Color3.fromRGB(60,60,80),CanvasSize=UDim2.new(0,0,0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y,Visible=false,Parent=content})
    tabs[n]=f; order[#order+1]=b
    b.MouseButton1Click:Connect(function()
        selectTab(n)
        for _,x in ipairs(order) do x.BackgroundColor3=Color3.fromRGB(20,20,28); x.TextColor3=Color3.fromRGB(150,150,165) end
        b.BackgroundColor3=Color3.fromRGB(30,30,45); b.TextColor3=Color3.fromRGB(200,225,255)
    end)
    return f
end
local function section(p,t,y) new("TextLabel",{Size=UDim2.new(1,0,0,22),Position=UDim2.fromOffset(0,y),BackgroundTransparency=1,Text=t,TextColor3=Color3.fromRGB(110,160,230),Font=Enum.Font.GothamBold,TextSize=11,TextXAlignment=Enum.TextXAlignment.Left,Parent=p}) end

-- ============================================================
-- WIDGETS
-- ============================================================
local function toggle(p,lbl,def,cb,y)
    local r=new("Frame",{Size=UDim2.new(1,0,0,32),Position=UDim2.fromOffset(0,y),BackgroundTransparency=1,Parent=p})
    new("TextLabel",{Size=UDim2.new(1,-70,1,0),BackgroundTransparency=1,Text=lbl,TextColor3=Color3.fromRGB(205,205,215),Font=Enum.Font.Gotham,TextSize=12,TextXAlignment=Enum.TextXAlignment.Left,Parent=r})
    local b=new("TextButton",{Size=UDim2.fromOffset(46,22),Position=UDim2.new(1,-46,0.5,-11),BackgroundColor3=def and Color3.fromRGB(40,95,60) or Color3.fromRGB(35,35,48),BorderSizePixel=0,Text=def and "ON" or "OFF",TextColor3=Color3.fromRGB(220,220,230),Font=Enum.Font.GothamBold,TextSize=10,Parent=r})
    corner(11,b)
    local s=def
    b.MouseButton1Click:Connect(function() s=not s; b.Text=s and "ON" or "OFF"; b.BackgroundColor3=s and Color3.fromRGB(40,95,60) or Color3.fromRGB(35,35,48); if cb then cb(s) end end)
end
local function slider(p,lbl,mn,mx,def,cb,y)
    local c=new("Frame",{Size=UDim2.new(1,0,0,48),Position=UDim2.fromOffset(0,y),BackgroundTransparency=1,Parent=p})
    local lb=new("TextLabel",{Size=UDim2.new(1,0,0,18),BackgroundTransparency=1,Text=lbl..": "..tostring(def),TextColor3=Color3.fromRGB(205,205,215),Font=Enum.Font.Gotham,TextSize=12,TextXAlignment=Enum.TextXAlignment.Left,Parent=c})
    local tr=new("Frame",{Size=UDim2.new(1,-12,0,5),Position=UDim2.fromOffset(0,30),BackgroundColor3=Color3.fromRGB(35,35,48),BorderSizePixel=0,Parent=c}); corner(3,tr)
    local fl=new("Frame",{Size=UDim2.fromScale((def-mn)/(mx-mn),1),BackgroundColor3=Color3.fromRGB(80,150,230),BorderSizePixel=0,Parent=tr}); corner(3,fl)
    local kn=new("Frame",{Size=UDim2.fromOffset(12,12),Position=UDim2.new(fl.Size.X.Scale,-6,0.5,-6),BackgroundColor3=Color3.fromRGB(200,225,255),BorderSizePixel=0,Parent=tr}); corner(6,kn)
    local dr,val=false,def
    local function upd(x)
        local rel=math.clamp((x-tr.AbsolutePosition.X)/tr.AbsoluteSize.X,0,1)
        val=math.floor(mn+(mx-mn)*rel+0.5)
        fl.Size=UDim2.fromScale(rel,1); kn.Position=UDim2.new(rel,-6,0.5,-6); lb.Text=lbl..": "..tostring(val)
        if cb then cb(val) end
    end
    tr.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dr=true; upd(i.Position.X) end end)
    UIS.InputChanged:Connect(function(i) if dr and i.UserInputType==Enum.UserInputType.MouseMovement then upd(i.Position.X) end end)
    UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dr=false end end)
end
local function dropdown(p,lbl,opts,def,cb,y)
    local r=new("Frame",{Size=UDim2.new(1,0,0,32),Position=UDim2.fromOffset(0,y),BackgroundTransparency=1,Parent=p})
    new("TextLabel",{Size=UDim2.new(1,-160,1,0),BackgroundTransparency=1,Text=lbl,TextColor3=Color3.fromRGB(205,205,215),Font=Enum.Font.Gotham,TextSize=12,TextXAlignment=Enum.TextXAlignment.Left,Parent=r})
    local b=new("TextButton",{Size=UDim2.fromOffset(150,24),Position=UDim2.new(1,-150,0.5,-12),BackgroundColor3=Color3.fromRGB(28,28,40),BorderSizePixel=0,Text=def,TextColor3=Color3.fromRGB(200,200,215),Font=Enum.Font.Gotham,TextSize=11,Parent=r}); corner(4,b)
    local i=1 for k,v in ipairs(opts) do if v==def then i=k break end end
    b.MouseButton1Click:Connect(function() i=i%#opts+1; b.Text=opts[i]; if cb then cb(opts[i]) end end)
    return b
end
local function button(p,t,cb,y,col)
    local b=new("TextButton",{Size=UDim2.new(1,0,0,28),Position=UDim2.fromOffset(0,y),BackgroundColor3=col or Color3.fromRGB(32,32,46),BorderSizePixel=0,Text=t,TextColor3=Color3.fromRGB(210,210,225),Font=Enum.Font.Gotham,TextSize=12,Parent=p}); corner(4,b)
    b.MouseButton1Click:Connect(function() if cb then pcall(cb) end end)
    return b
end
local function label(p,t,y,h) return new("TextLabel",{Size=UDim2.new(1,0,0,h or 18),Position=UDim2.fromOffset(0,y),BackgroundTransparency=1,Text=t,TextColor3=Color3.fromRGB(140,140,155),Font=Enum.Font.Gotham,TextSize=11,TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true,Parent=p}) end

-- forward decl for esp clear (used by toggles)
local clearESP
local espFolder = new("Folder",{Name="LaxissESP",Parent=gui})

-- ============================================================
-- TAB: FARMING
-- ============================================================
local fT = makeTab("Farming"); local y = 4
section(fT,"ORBS",y); y=y+26
dropdown(fT,"Orb Type",{"Ethereal Orb","Red Orb","Blue Orb","Yellow Orb","Orange Orb"},S.OrbType,function(v) S.OrbType=v end,y); y=y+34
dropdown(fT,"Location",{"City","Desert","Magma City","Grassland","Jungle","Legends Highway"},S.OrbLoc,function(v) S.OrbLoc=v end,y); y=y+34
slider(fT,"Orb Batch",1,50,S.OrbBatch,function(v) S.OrbBatch=v end,y); y=y+50
toggle(fT,"Auto Orbs (remote)",false,function(v) S.Orbs=v end,y); y=y+34
toggle(fT,"Auto Orb Touch (physical)",false,function(v) S.TouchOrbs=v end,y); y=y+34
toggle(fT,"Orb Magnet",false,function(v) S.Magnet=v end,y); y=y+34
section(fT,"GEMS",y); y=y+26
slider(fT,"Gem Batch",1,20,S.GemBatch,function(v) S.GemBatch=v end,y); y=y+50
toggle(fT,"Auto Gems",false,function(v) S.Gems=v end,y); y=y+34
section(fT,"REBIRTH",y); y=y+26
toggle(fT,"Auto Rebirth",false,function(v) S.Rebirth=v end,y); y=y+34
toggle(fT,"Level Check",true,function(v) S.RebirthCheck=v end,y); y=y+34
section(fT,"HOOPS",y); y=y+26
dropdown(fT,"Hoop Mode",{"Touch","Teleport"},S.HoopMode,function(v) S.HoopMode=v end,y); y=y+34
slider(fT,"Hoop Delay (ms)",50,1000,S.HoopDelay*1000,function(v) S.HoopDelay=v/1000 end,y); y=y+50
toggle(fT,"Auto Hoops",false,function(v) S.Hoops=v end,y)

-- ============================================================
-- TAB: PLAYER
-- ============================================================
local pT = makeTab("Player"); y=4
section(pT,"MOVEMENT",y); y=y+26
slider(pT,"WalkSpeed",16,250,16,function(v) S.Walk=v; local h=hum(); if h then h.WalkSpeed=v end end,y); y=y+50
slider(pT,"JumpPower",50,250,50,function(v) S.Jump=v; local h=hum(); if h then h.JumpPower=v; h.UseJumpPower=true end end,y); y=y+50
toggle(pT,"Infinite Jump",false,function(v) S.InfJump=v end,y); y=y+34
toggle(pT,"Fly",false,function(v) S.Fly=v end,y); y=y+34
slider(pT,"Fly Speed",20,300,S.FlySpeed,function(v) S.FlySpeed=v end,y); y=y+50
toggle(pT,"Noclip",false,function(v) S.Noclip=v end,y); y=y+34
section(pT,"UTILITY",y); y=y+26
toggle(pT,"Anti-AFK",false,function(v) S.AntiAFK=v end,y); y=y+34
button(pT,"Reset Character",function() local c=LP.Character; if c then c:BreakJoints() end end,y); y=y+32
button(pT,"Rejoin Server",function() TS:Teleport(game.PlaceId,LP) end,y)

-- ============================================================
-- TAB: TELEPORTS
-- ============================================================
local tT = makeTab("Teleports"); y=4
local maps = {
    ["City"]=Vector3.new(-130,5,10), ["Desert"]=Vector3.new(1050,10,250),
    ["Magma City"]=Vector3.new(-150,5,1450), ["Grassland"]=Vector3.new(500,5,-400),
    ["Jungle"]=Vector3.new(-900,5,-900), ["Legends Highway"]=Vector3.new(2000,10,2000),
}
local mapNames = {}
for n in pairs(maps) do mapNames[#mapNames+1]=n end
table.sort(mapNames)
local selectedMap = mapNames[1] or "City"
section(tT,"MAP",y); y=y+26
dropdown(tT,"Destination",mapNames,selectedMap,function(v) selectedMap=v end,y); y=y+34
button(tT,"Teleport",function()
    local r=root(); local p=maps[selectedMap]
    if r and p then r.CFrame=CFrame.new(p) end
end,y); y=y+32
button(tT,"Teleport to Spawn",function()
    local sp=WS:FindFirstChildOfClass("SpawnLocation"); local r=root()
    if sp and r then r.CFrame=sp.CFrame+Vector3.new(0,4,0) end
end,y); y=y+32
section(tT,"PLAYERS",y); y=y+26
local playerTarget = nil
local pList = {}
local function refreshPlayers()
    pList = {}
    for _,p in ipairs(Players:GetPlayers()) do if p~=LP then pList[#pList+1]=p.Name end end
    if #pList==0 then pList={"<none>"} end
    playerTarget = pList[1]
end
refreshPlayers()
dropdown(tT,"Target Player",pList,playerTarget,function(v) playerTarget=v end,y); y=y+34
button(tT,"Teleport to Player",function()
    for _,p in ipairs(Players:GetPlayers()) do
        if p.Name==playerTarget and p.Character then
            local hr=p.Character:FindFirstChild("HumanoidRootPart"); local r=root()
            if hr and r then r.CFrame=hr.CFrame+Vector3.new(0,2,0) end
        end
    end
end,y); y=y+32
button(tT,"Refresh Player List",function() refreshPlayers(); notify("LaxissTM","Player list refreshed.",2) end,y)

-- ============================================================
-- TAB: ESP
-- ============================================================
local eT = makeTab("ESP"); y=4
section(eT,"ESP TOGGLES",y); y=y+26
toggle(eT,"ESP Orbs",false,function(v) S.ESPOrbs=v; if not v then clearESP("Orb") end end,y); y=y+34
toggle(eT,"ESP Crystals",false,function(v) S.ESPCrystals=v; if not v then clearESP("Crystal") end end,y); y=y+34
toggle(eT,"ESP Hoops",false,function(v) S.ESPHoops=v; if not v then clearESP("Hoop") end end,y); y=y+34
toggle(eT,"ESP Players",false,function(v) S.ESPPlayers=v; if not v then clearESP("Player") end end,y); y=y+34
toggle(eT,"Show Distance",true,function(v) S.ESPDist=v end,y); y=y+34
section(eT,"INFO",y); y=y+26
local infoL = label(eT,"",y,80)

-- ============================================================
-- TAB: SETTINGS
-- ============================================================
local sT = makeTab("Settings"); y=4
section(sT,"GUI",y); y=y+26
local keyBtn
keyBtn = button(sT,"Toggle Key: "..S.Key,function()
    keyBtn.Text = "Press any key..."
    local conn
    conn = UIS.InputBegan:Connect(function(i,proc)
        if proc then return end
        if i.UserInputType==Enum.UserInputType.Keyboard then
            S.Key = i.KeyCode.Name
            keyBtn.Text = "Toggle Key: "..S.Key
            conn:Disconnect()
        end
    end)
end,y); y=y+32
toggle(sT,"Notifications",true,function(v) S.Notify=v end,y); y=y+34
section(sT,"CONFIG",y); y=y+26
button(sT,"Save Config",function()
    local save = {}
    for k,v in pairs(S) do
        if type(v)=="boolean" or type(v)=="number" or type(v)=="string" then save[k]=v end
    end
    pcall(function() writefile("LaxissTM_config.json", HS:JSONEncode(save)) end)
    notify("LaxissTM","Config saved.",2)
end,y); y=y+32
button(sT,"Load Config",function()
    pcall(function()
        local raw = readfile("LaxissTM_config.json")
        local d = HS:JSONDecode(raw)
        for k,v in pairs(d) do if S[k]~=nil then S[k]=v end end
        local h=hum(); if h then h.WalkSpeed=S.Walk; h.JumpPower=S.Jump; h.UseJumpPower=true end
    end)
    notify("LaxissTM","Config loaded. Some toggles need re-apply.",3)
end,y); y=y+32
section(sT,"SESSION STATS",y); y=y+26
local statsL = label(sT,"",y,80)

-- ============================================================
-- ESP IMPLEMENTATION
-- ============================================================
clearESP = function(cat)
    for k,o in pairs(S.ESP) do
        if o.Cat==cat then
            if o.BB then o.BB:Destroy() end
            S.ESP[k]=nil
        end
    end
end
local function mkBB(ador,text,col)
    local b=new("BillboardGui",{Size=UDim2.fromOffset(120,24),StudsOffset=Vector3.new(0,3,0),AlwaysOnTop=true,Adornee=ador,Parent=espFolder})
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
            if e and e.BB and S.ESPDist then
                e.BB.Lbl.Text = e.Base.." ["..distTo(o).."m]"
            elseif e and e.BB then e.BB.Lbl.Text = e.Base end
        end
    end
    if S.ESPCrystals then
        for _,o in ipairs(WS:GetDescendants()) do
            if o:IsA("BasePart") and o.Name:find("Crystal") and not S.ESP[o] then
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
            if p~=LP and p.Character and not S.ESP[p] then
                local h=p.Character:FindFirstChild("Head")
                if h then S.ESP[p]={BB=mkBB(h,p.Name,Color3.fromRGB(255,120,120)),Cat="Player",Base=p.Name} end
            end
        end
    end
end

-- ============================================================
-- LOOPS
-- ============================================================
task.spawn(function() while task.wait(0.1) do
    if S.Orbs then fireOrb(S.OrbType, place(), S.OrbBatch); S.CollectedOrbs=S.CollectedOrbs+S.OrbBatch end
end end)

task.spawn(function() while task.wait(0.1) do
    if S.Gems then
        for _,l in ipairs({"City","Desert","Magma City"}) do fireOrb("Gem", l, S.GemBatch) end
        S.CollectedGems=S.CollectedGems+S.GemBatch*3
    end
end end)

task.spawn(function() while task.wait(0.1) do
    if S.TouchOrbs then
        local r=root()
        if r then
            for _,o in ipairs(findOrbs()) do
                pcall(function() firetouchinterest(r,o,0); task.wait(); firetouchinterest(r,o,1) end)
            end
        end
    end
end end)

task.spawn(function() while task.wait(0.2) do
    if S.Magnet then
        local r=root()
        if r then
            for _,o in ipairs(findOrbs()) do
                pcall(function() o.CFrame = r.CFrame end)
            end
        end
    end
end end)

task.spawn(function() while task.wait(1) do
    if S.Rebirth then
        local ok=true
        if S.RebirthCheck and gf then pcall(function()
            local lv,mul = level(),mult()
            if lv and mul then ok=(tonumber(gf.calculateRequiredRebirthLevel(mul-1))==tonumber(lv)) end
        end) end
        if ok then fireReb(); S.Rebirths=S.Rebirths+1 end
    end
end end)

task.spawn(function() while task.wait(S.HoopDelay) do
    if S.Hoops then
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

UIS.JumpRequest:Connect(function()
    if S.InfJump then local h=hum(); if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end end
end)

-- fly via BodyVelocity
local flyBV, flyBG
local function stopFly()
    if flyBV then flyBV:Destroy(); flyBV=nil end
    if flyBG then flyBG:Destroy(); flyBG=nil end
end
RunS.Heartbeat:Connect(function()
    local char = LP.Character
    local hr = char and char:FindFirstChild("HumanoidRootPart")
    if not hr then stopFly(); return end
    if S.Fly then
        if not flyBV or flyBV.Parent ~= hr then
            stopFly()
            flyBV = Instance.new("BodyVelocity", hr)
            flyBV.MaxForce = Vector3.new(1e5,1e5,1e5)
            flyBG = Instance.new("BodyGyro", hr)
            flyBG.MaxTorque = Vector3.new(1e5,1e5,1e5)
            flyBG.P = 3000
            flyBG.D = 200
        end
        local cam = WS.CurrentCamera
        local dir = Vector3.zero
        if UIS:IsKeyDown(Enum.KeyCode.W) then dir = dir + cam.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.S) then dir = dir - cam.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.A) then dir = dir - cam.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then dir = dir + cam.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0,1,0) end
        if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then dir = dir - Vector3.new(0,1,0) end
        if dir.Magnitude > 0 then dir = dir.Unit end
        flyBV.Velocity = dir * S.FlySpeed
        flyBG.CFrame = cam.CFrame
    else
        stopFly()
    end
    if S.Noclip then
        for _,o in ipairs(char:GetDescendants()) do
            if o:IsA("BasePart") and o.CanCollide then o.CanCollide=false end
        end
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
        "Level: %s   |   Multiplier: %s\nCurrent Map: %s\nESP tracked: %d",
        tostring(level() or "?"), tostring(mult() or "?"), tostring(place() or "?"), (function() local n=0 for _ in pairs(S.ESP) do n=n+1 end return n end)()
    )
    statsL.Text = string.format(
        "Session: %s\nOrbs: %d   Gems: %d   Rebirths: %d",
        fmtTime(os.time()-S.StartTime), S.CollectedOrbs, S.CollectedGems, S.Rebirths
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
if order[1] then order[1].BackgroundColor3=Color3.fromRGB(30,30,45); order[1].TextColor3=Color3.fromRGB(200,225,255) end
UIS.InputBegan:Connect(function(i,proc)
    if proc then return end
    local code = i.KeyCode.Name
    if code == S.Key then gui.Enabled = not gui.Enabled end
end)
notify("LaxissTM","Loaded. Toggle key: "..S.Key,4)
print("[LaxissTM] full build loaded.")