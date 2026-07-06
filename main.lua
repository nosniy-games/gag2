local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer

local Networking = require(ReplicatedStorage.SharedModules.Networking)
local Event = ReplicatedStorage.SharedModules.Packet.RemoteEvent
local PS = require(ReplicatedStorage.ClientModules.PlayerStateClient)

---------------------------------------------------
-- PERFORMANCE OPTIMIZATION SYSTEM
---------------------------------------------------

local PerformanceSettings = {
    Enabled = false,
    OriginalSettings = {}
}

local function SaveOriginalSettings()
    pcall(function()
        PerformanceSettings.OriginalSettings.Brightness = Lighting.Brightness
        PerformanceSettings.OriginalSettings.GlobalShadows = Lighting.GlobalShadows
        PerformanceSettings.OriginalSettings.Technology = Lighting.Technology
        PerformanceSettings.OriginalSettings.GraphicsQuality = settings().Rendering.QualityLevel
    end)
end

local function ApplyPerformanceMode()
    if not PerformanceSettings.Enabled then return end
    
    -- Ultra-low graphics
    pcall(function()
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
    end)
    
    -- Lighting optimizations
    Lighting.GlobalShadows = false
    Lighting.Brightness = 2
    Lighting.Technology = Enum.Technology.Compatibility
    
    -- Remove post-processing
    for _, effect in ipairs(Lighting:GetChildren()) do
        if effect:IsA("PostEffect") then
            effect.Enabled = false
        end
    end
    
    -- Disable particles
    for _, descendant in ipairs(Workspace:GetDescendants()) do
        if descendant:IsA("ParticleEmitter") or descendant:IsA("Smoke") or 
           descendant:IsA("Fire") or descendant:IsA("Sparkles") or 
           descendant:IsA("Trail") or descendant:IsA("Beam") then
            descendant.Enabled = false
        end
    end
end

local function RemoveTextures()
    if not PerformanceSettings.Enabled then return end
    
    for _, descendant in ipairs(Workspace:GetDescendants()) do
        if descendant:IsA("Texture") or descendant:IsA("Decal") then
            descendant.Transparency = 1
        elseif descendant:IsA("SurfaceAppearance") then
            descendant:Destroy()
        elseif descendant:IsA("BasePart") then
            descendant.Material = Enum.Material.SmoothPlastic
            descendant.Reflectance = 0
        end
    end
end

local function OptimizeParts()
    if not PerformanceSettings.Enabled then return end
    
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end
    
    for _, part in ipairs(Workspace:GetDescendants()) do
        if part:IsA("BasePart") and part ~= rootPart then
            local distance = (part.Position - rootPart.Position).Magnitude
            
            if distance > 400 then
                part.Transparency = 1
                part.CanCollide = false
            end
        end
    end
end

local function EnablePerformanceMode()
    SaveOriginalSettings()
    PerformanceSettings.Enabled = true
    
    ApplyPerformanceMode()
    RemoveTextures()
    
    -- Continuous optimization
    task.spawn(function()
        while PerformanceSettings.Enabled do
            OptimizeParts()
            task.wait(3)
        end
    end)
end

local function DisablePerformanceMode()
    PerformanceSettings.Enabled = false
    
    pcall(function()
        if PerformanceSettings.OriginalSettings.GraphicsQuality then
            settings().Rendering.QualityLevel = PerformanceSettings.OriginalSettings.GraphicsQuality
        end
        Lighting.GlobalShadows = PerformanceSettings.OriginalSettings.GlobalShadows or true
        Lighting.Brightness = PerformanceSettings.OriginalSettings.Brightness or 1
        Lighting.Technology = PerformanceSettings.OriginalSettings.Technology or Enum.Technology.ShadowMap
    end)
end

-- FPS Monitor & Auto-Optimizer
local fps = 60
local lastFrameTime = tick()

RunService.RenderStepped:Connect(function()
    local currentTime = tick()
    fps = math.floor(1 / (currentTime - lastFrameTime))
    lastFrameTime = currentTime
    
    -- Auto-enable performance mode if FPS drops
    if fps < 30 and not PerformanceSettings.Enabled then
        EnablePerformanceMode()
    end
end)

---------------------------------------------------
-- MEGA MODE
---------------------------------------------------

local MegaMode = false

---------------------------------------------------
-- CHARACTER CACHE
---------------------------------------------------

local character = player.Character or player.CharacterAdded:Wait()
player.CharacterAdded:Connect(function(c)
    character = c
end)

local backpack = player:WaitForChild("Backpack")

---------------------------------------------------
-- CACHED INVENTORY
---------------------------------------------------

local inventoryCache = nil
local lastInventoryUpdate = 0

local function getInv()
    if inventoryCache and tick() - lastInventoryUpdate < 1 then
        return inventoryCache
    end
    
    local ok, r = pcall(function()
        return PS:WaitForLocalReplica(10)
    end)

    if not ok or not r or not r.Data then return nil end
    
    inventoryCache = r.Data.Inventory
    lastInventoryUpdate = tick()
    return inventoryCache
end

---------------------------------------------------
-- CACHED TOOL PICKER
---------------------------------------------------

local cachedTool = nil
local lastToolCheck = 0

local function getAnyTool()
    if cachedTool and cachedTool.Parent and tick() - lastToolCheck < 0.5 then
        return cachedTool
    end

    local function find(container)
        for _, v in ipairs(container:GetChildren()) do
            if v:IsA("Tool") and v:GetAttribute("SeedTool") then
                local seedName = v:GetAttribute("SeedTool") or v.Name

                -- ONLY allow Mega
                if seedName == "Mega" then
                    return v
                end
            end
        end
    end

    cachedTool = find(character) or find(backpack)
    lastToolCheck = tick()

    return cachedTool
end

---------------------------------------------------
-- PLOT LOAD (OPTIMIZED)
---------------------------------------------------

local beds = {}

task.spawn(function()
    local gardens = workspace:WaitForChild("Gardens", 30)
    if not gardens then return end

    local plotId = player:GetAttribute("PlotId")
    if not plotId then
        player:GetAttributeChangedSignal("PlotId"):Wait()
        plotId = player:GetAttribute("PlotId")
    end

    local plot = gardens:WaitForChild("Plot" .. tostring(plotId), 30)
    if not plot then return end

    local visual = plot:WaitForChild("Visual", 30)
    if not visual then return end

    for _, bed in ipairs(visual:GetDescendants()) do
        if bed.Name and bed.Name:lower():find("bedsection") then
            local points = {}

            for _, d in ipairs(bed:GetDescendants()) do
                if d:IsA("Attachment") then
                    points[#points+1] = d.WorldPosition
                elseif d:IsA("BasePart") then
                    points[#points+1] = d.Position
                end
            end

            if #points > 0 then
                beds[#beds+1] = points
            end
        end
    end
end)

---------------------------------------------------
-- HIGHLY DIVERSE RANDOM POSITIONS
---------------------------------------------------

local randomSeed = tick() * 1000

local function preciseRandom()
    -- Linear congruential generator for precision
    randomSeed = (randomSeed * 9301 + 49297) % 233280
    local base = randomSeed / 233280
    
    -- Add microsecond precision
    local micro = ((tick() * 1000000) % 1000) / 1000
    
    return (base + micro / 1000) % 1
end

local function randomOffset(pos)
    -- EXTREMELY diverse positioning
    local spreadX = 4.5  -- Much larger spread
    local spreadZ = 4.5
    
    -- High precision random offsets
    local offsetX = (preciseRandom() - 0.5) * 2 * spreadX
    local offsetZ = (preciseRandom() - 0.5) * 2 * spreadZ
    
    -- Add ultra-precise micro variations
    local microX = (math.random() * 1000 - 500) / 100000  -- 0.00001 precision
    local microZ = (math.random() * 1000 - 500) / 100000
    
    -- Additional noise layer
    local noiseX = math.sin(tick() * 1000) / 1000
    local noiseZ = math.cos(tick() * 1000) / 1000
    
    return Vector3.new(
        pos.X + offsetX + microX + noiseX,
        pos.Y,
        pos.Z + offsetZ + microZ + noiseZ
    )
end

---------------------------------------------------
-- ULTRA-FAST PLANT
---------------------------------------------------

local lastPlantTime = 0

local function plantRandom()
    if tick() - lastPlantTime < 0.02 then return false end
    if #beds == 0 then return false end

    local tool = getAnyTool()
    if not tool then return false end

    -- ONLY allow Mega seeds
    local seedName = tool:GetAttribute("SeedTool") or tool.Name
    if seedName ~= "Mega" then
        return false
    end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return false end

    if tool.Parent ~= character then
        humanoid:EquipTool(tool)
        task.wait(0.02)
    end

    local bedPoints = beds[math.random(1, #beds)]
    local basePos = bedPoints[math.random(1, #bedPoints)]
    local pos = randomOffset(basePos)

    Networking.Plant.PlantSeed:Fire(pos, "Mega", tool)
    lastPlantTime = tick()

    return true
end

---------------------------------------------------
-- UI
---------------------------------------------------

if not Fluent or type(Fluent.CreateWindow) ~= "function" then
    warn("Fluent not loaded")
    return
end

local Window = Fluent:CreateWindow({
    Title = "Developer Menu",
    SubTitle = "MEGA + Performance",
    TabWidth = 160,
    Size = UDim2.fromOffset(500, 400),
    Acrylic = false,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

local Main = Window:AddTab({ Title = "Main", Icon = "home" })
local Performance = Window:AddTab({ Title = "Performance", Icon = "settings" })

Main:AddButton({
    Title = "Fire Packet & Rejoin",
    Callback = function()
        Event:FireServer(buffer.fromstring("6\0\1\255"))
        task.wait(3)
        TeleportService:Teleport(game.PlaceId, player)
    end
})

Main:AddToggle("MegaMode", {
    Title = "Mega Plant Mode (Ultra Fast)",
    Default = false,
    Callback = function(v)
        MegaMode = v
        if v then
            task.spawn(function()
                while MegaMode do
                    plantRandom()
                    task.wait(0.02)  -- Ultra-fast planting
                end
            end)
        end
    end
})

---------------------------------------------------
-- PERFORMANCE TAB
---------------------------------------------------

Performance:AddToggle("PerformanceMode", {
    Title = "Auto Performance Mode (FPS Saver)",
    Default = false,
    Callback = function(v)
        if v then
            EnablePerformanceMode()
        else
            DisablePerformanceMode()
        end
    end
})

Performance:AddButton({
    Title = "Remove All Textures NOW",
    Callback = RemoveTextures
})

Performance:AddButton({
    Title = "Optimize Distant Objects",
    Callback = OptimizeParts
})

local fpsLabel = Performance:AddParagraph({
    Title = "FPS Monitor",
    Content = "Current FPS: Calculating..."
})

task.spawn(function()
    while task.wait(1) do
        pcall(function()
            fpsLabel:SetDesc("Current FPS: " .. tostring(fps) .. "\nAuto-optimization: " .. (PerformanceSettings.Enabled and "ON" or "OFF"))
        end)
    end
end)

Window:SelectTab(1)

-- Auto-enable performance on low FPS startup
task.wait(3)
if fps < 35 then
    EnablePerformanceMode()
end

queue_on_teleport([[
loadstring(game:HttpGet("https://raw.githubusercontent.com/nosniy-games/gag2/refs/heads/main/main.lua"))()
]])
