local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local rootPart = character:WaitForChild("HumanoidRootPart")
local camera = workspace.CurrentCamera
local backpack = player:WaitForChild("Backpack")

local HOLD_DURATION = 14
local WAIT_BETWEEN_ATM = 1
local autoATM = false
local loopThread = nil
local camConnection = nil
local antiDetectConnection = nil
local circleConnection = nil
local lastHits = {}
local TP_POSITION = Vector3.new(-2544, 31, 4030)
local TP_WAIT_TIME = 5
local DETECT_RADIUS = 100
local MAX_BAGS = 8
local CIRCLE_RADIUS = 2000
local CIRCLE_SPEED = 10
local circleAngle = 0
local circleCenter = Vector3.new(0, 5000, 0)

lualocal Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local rootPart = character:WaitForChild("HumanoidRootPart")
local camera = workspace.CurrentCamera
local backpack = player:WaitForChild("Backpack")

local HOLD_DURATION = 6
local WAIT_BETWEEN_ATM = 1
local autoATM = false
local loopThread = nil
local camConnection = nil
local antiDetectConnection = nil
local circleConnection = nil
local lastHits = {}
local TP_POSITION = Vector3.new(-2544, 31, 4030)
local TP_WAIT_TIME = 5
local DETECT_RADIUS = 20
local MAX_BAGS = 8
local CIRCLE_RADIUS = 300
local CIRCLE_SPEED = 10
local circleAngle = 0
local circleCenter = Vector3.new(0, 5000, 0)
local isInAirDueToPlayer = false
local statusLabel

local function startCircle(centerPos)
    circleCenter = centerPos
    circleAngle = 0
    if circleConnection then circleConnection:Disconnect() end
    circleConnection = RunService.Heartbeat:Connect(function(dt)
        if not rootPart or not rootPart.Parent then return end
        circleAngle += dt * CIRCLE_SPEED
        local x = circleCenter.X + math.cos(circleAngle) * CIRCLE_RADIUS
        local z = circleCenter.Z + math.sin(circleAngle) * CIRCLE_RADIUS
        rootPart.CFrame = CFrame.new(x, circleCenter.Y, z)
        rootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
    end)
end

local function stopCircle()
    if circleConnection then
        circleConnection:Disconnect()
        circleConnection = nil
    end
end

local function countBags()
    local count = 0
    for _, item in ipairs(backpack:GetChildren()) do
        if item.Name == "CriminalMoneyBag" then count += 1 end
    end
    for _, item in ipairs(character:GetChildren()) do
        if item.Name == "CriminalMoneyBag" then count += 1 end
    end
    return count
end

local function enableCameraClip()
    if camConnection then return end
    camConnection = RunService.RenderStepped:Connect(function()
        local camPos = camera.CFrame.Position
        local charPos = rootPart.Position
        local direction = camPos - charPos
        for _, part in ipairs(lastHits) do
            if part and part.Parent then
                part.LocalTransparencyModifier = 0
            end
        end
        lastHits = {}
        local currentPos = charPos
        local remaining = direction
        local filterList = {character}
        for i = 1, 20 do
            local raycastParams = RaycastParams.new()
            raycastParams.FilterDescendantsInstances = filterList
            raycastParams.FilterType = Enum.RaycastFilterType.Exclude
            local result = workspace:Raycast(currentPos, remaining, raycastParams)
            if not result then break end
            local hit = result.Instance
            if hit and hit.Parent then
                hit.LocalTransparencyModifier = 1
                table.insert(lastHits, hit)
                table.insert(filterList, hit)
                for _, child in ipairs(hit.Parent:GetChildren()) do
                    if child:IsA("BasePart") then
                        child.LocalTransparencyModifier = 1
                        table.insert(lastHits, child)
                        table.insert(filterList, child)
                    end
                end
                currentPos = result.Position + direction.Unit * 0.01
                remaining = camPos - currentPos
            else
                break
            end
        end
    end)
end

local function disableCameraClip()
    if camConnection then
        camConnection:Disconnect()
        camConnection = nil
    end
    for _, part in ipairs(lastHits) do
        if part and part.Parent then
            part.LocalTransparencyModifier = 0
        end
    end
    lastHits = {}
end

local function tpInAir()
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local airPos = Vector3.new(rootPart.Position.X, 5000, rootPart.Position.Z)
    rootPart.CFrame = CFrame.new(airPos)
    rootPart.Anchored = true
    rootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
    if humanoid then humanoid.PlatformStand = true end
    startCircle(airPos)
end

local function unfreezePlayer()
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    stopCircle()
    rootPart.Anchored = false
    if humanoid then humanoid.PlatformStand = false end
end

local function startAntiDetect()
    if antiDetectConnection then return end
    antiDetectConnection = task.spawn(function()
        while autoATM do
            local playerNearby = false

            for _, otherPlayer in ipairs(Players:GetPlayers()) do
                if otherPlayer == player then continue end
                local otherChar = otherPlayer.Character
                if not otherChar then continue end
                local otherRoot = otherChar:FindFirstChild("HumanoidRootPart")
                if not otherRoot then continue end

                local distance = (rootPart.Position - otherRoot.Position).Magnitude
                if distance <= DETECT_RADIUS then
                    playerNearby = true
                    if not isInAirDueToPlayer then
                        isInAirDueToPlayer = true
                        statusLabel:Set("⚠️ Joueur proche ! TP dans les airs !")
                        tpInAir()
                    end
                    break
                end
            end

            if not playerNearby and isInAirDueToPlayer then
                isInAirDueToPlayer = false
                statusLabel:Set("✅ Zone libre, on reprend !")
                unfreezePlayer()
            end

            task.wait(0.1)
        end
    end)
end

local function stopAntiDetect()
    if antiDetectConnection then
        task.cancel(antiDetectConnection)
        antiDetectConnection = nil
    end
    isInAirDueToPlayer = false
end

local function getAllATMs()
    local atms = {}
    for _, v in ipairs(workspace:GetDescendants()) do
        if v.Name == "CriminalATMSpawner" then
            for _, child in ipairs(v:GetDescendants()) do
                if child:IsA("ProximityPrompt") and child.Enabled then
                    table.insert(atms, {part = v, prompt = child})
                end
            end
        end
    end
    return atms
end

local function interactWithATM(atm)
    local part = atm.part
    local prompt = atm.prompt
    if not prompt or not prompt.Enabled then return false end
    local targetCFrame
    if part:IsA("BasePart") then
        targetCFrame = part.CFrame + Vector3.new(0, 0, 3)
    elseif part:IsA("Model") and part.PrimaryPart then
        targetCFrame = part.PrimaryPart.CFrame + Vector3.new(0, 0, 3)
    end
    if not targetCFrame then return false end
    rootPart.CFrame = targetCFrame
    task.wait(1.5)
    if not prompt.Enabled or not autoATM then return false end
    prompt:InputHoldBegin()
    local elapsed = 0
    while elapsed < HOLD_DURATION and autoATM do
        task.wait(0.1)
        elapsed += 0.1
        if not prompt or not prompt.Enabled then break end
        if isInAirDueToPlayer then
            prompt:InputHoldEnd()
            repeat task.wait(0.1) until not isInAirDueToPlayer or not autoATM
            if not autoATM then return false end
            return false
        end
    end
    prompt:InputHoldEnd()
    return true
end

local function startLoop()
    loopThread = task.spawn(function()
        enableCameraClip()
        startAntiDetect()
        while autoATM do
            if isInAirDueToPlayer then
                task.wait(0.1)
                continue
            end
            local bags = countBags()
            statusLabel:Set("💼 Sacs: " .. bags .. "/" .. MAX_BAGS)
            if bags >= MAX_BAGS then
                statusLabel:Set("💼 " .. bags .. " sacs ! TP à la base...")
                unfreezePlayer()
                rootPart.CFrame = CFrame.new(TP_POSITION)
                for i = TP_WAIT_TIME, 1, -1 do
                    if not autoATM then break end
                    statusLabel:Set("⏳ Pause à la base... " .. i .. "s")
                    rootPart.CFrame = CFrame.new(TP_POSITION)
                    task.wait(1)
                end
                statusLabel:Set("🔁 Pause terminée, on recommence !")
                continue
            end
            local atms = getAllATMs()
            if #atms == 0 then
                statusLabel:Set("⏳ Aucun ATM... Cercle dans les airs !")
                tpInAir()
                task.wait(5)
            else
                unfreezePlayer()
                for _, atm in ipairs(atms) do
                    if not autoATM then break end
                    if isInAirDueToPlayer then
                        repeat task.wait(0.1) until not isInAirDueToPlayer or not autoATM
                        break
                    end
                    local currentBags = countBags()
                    if currentBags >= MAX_BAGS then break end
                    statusLabel:Set("💰 ATM en cours... Sacs: " .. currentBags .. "/" .. MAX_BAGS)
                    interactWithATM(atm)
                    task.wait(WAIT_BETWEEN_ATM)
                end
            end
        end
        disableCameraClip()
        stopAntiDetect()
        stopCircle()
    end)
end

local Window = Rayfield:CreateWindow({
    Name = "💰 Auto ATM",
    LoadingTitle = "Auto ATM",
    LoadingSubtitle = "Chargement...",
    ConfigurationSaving = { Enabled = false },
})

local Tab = Window:CreateTab("ATM", 4483362458)
local CamTab = Window:CreateTab("Caméra", 4483362458)

statusLabel = Tab:CreateLabel("⛔ Auto ATM : Désactivé")

Tab:CreateToggle({
    Name = "Auto ATM",
    CurrentValue = false,
    Flag = "AutoATM",
    Callback = function(value)
        autoATM = value
        if autoATM then
            statusLabel:Set("✅ Auto ATM : Actif")
            startLoop()
        else
            statusLabel:Set("⛔ Auto ATM : Désactivé")
            unfreezePlayer()
            disableCameraClip()
            stopAntiDetect()
            stopCircle()
            if loopThread then
                task.cancel(loopThread)
                loopThread = nil
            end
        end
    end,
})

Tab:CreateSlider({
    Name = "Sacs avant TP",
    Range = {1, 20},
    Increment = 1,
    CurrentValue = MAX_BAGS,
    Flag = "MaxBags",
    Callback = function(value)
        MAX_BAGS = value
    end,
})

Tab:CreateSlider({
    Name = "Durée appui (secondes)",
    Range = {1, 15},
    Increment = 1,
    CurrentValue = HOLD_DURATION,
    Flag = "HoldDuration",
    Callback = function(value)
        HOLD_DURATION = value
    end,
})

Tab:CreateSlider({
    Name = "Délai entre ATM (secondes)",
    Range = {1, 10},
    Increment = 1,
    CurrentValue = WAIT_BETWEEN_ATM,
    Flag = "WaitBetween",
    Callback = function(value)
        WAIT_BETWEEN_ATM = value
    end,
})

Tab:CreateSlider({
    Name = "Temps pause à la base (secondes)",
    Range = {5, 120},
    Increment = 5,
    CurrentValue = TP_WAIT_TIME,
    Flag = "TPWaitTime",
    Callback = function(value)
        TP_WAIT_TIME = value
    end,
})

Tab:CreateSlider({
    Name = "Rayon détection joueurs",
    Range = {5, 100},
    Increment = 5,
    CurrentValue = DETECT_RADIUS,
    Flag = "DetectRadius",
    Callback = function(value)
        DETECT_RADIUS = value
    end,
})

Tab:CreateSlider({
    Name = "Rayon du cercle",
    Range = {50, 500},
    Increment = 10,
    CurrentValue = CIRCLE_RADIUS,
    Flag = "CircleRadius",
    Callback = function(value)
        CIRCLE_RADIUS = value
    end,
})

Tab:CreateSlider({
    Name = "Vitesse du cercle",
    Range = {1, 10},
    Increment = 1,
    CurrentValue = CIRCLE_SPEED,
    Flag = "CircleSpeed",
    Callback = function(value)
        CIRCLE_SPEED = value
    end,
})

CamTab:CreateLabel("La caméra s'active automatiquement avec l'Auto ATM")

CamTab:CreateToggle({
    Name = "Caméra traverse tout (manuel)",
    CurrentValue = false,
    Flag = "CamClip",
    Callback = function(value)
        if value then
            enableCameraClip()
        else
            disableCameraClip()
        end
    end,
})