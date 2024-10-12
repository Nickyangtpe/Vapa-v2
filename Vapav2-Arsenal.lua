-- 載入 UI 函式庫
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()
local Window = Library.CreateLib("Vapa v2 - Arsenal", "DarkTheme")
local CombatTab = Window:NewTab("Combat")
local AimbotSection = CombatTab:NewSection("Aimbot")
local VisualsTab = Window:NewTab("Visuals")
local ESPSection = VisualsTab:NewSection("ESP")
local FOVSection = VisualsTab:NewSection("FOV")
local OtherVisualsSection = VisualsTab:NewSection("Other")
local HitBoxSection = CombatTab:NewSection("HitBox")
local WeaponSection = CombatTab:NewSection("Weapon")
local CombatOtherSection = CombatTab:NewSection("Other")
local PlayerTab = Window:NewTab("Player")
local TeleportSection = PlayerTab:NewSection("Teleport")
local MoventTab = Window:NewTab("Movent")
local SpeedSection = MoventTab:NewSection("Speed")
local FlySection = MoventTab:NewSection("Fly")
local OtherSection = MoventTab:NewSection("Other")
local ClickTPSection = PlayerTab:NewSection("Click TP")
local MiscTab = Window:NewTab("Misc")
local GUISection = MiscTab:NewSection("GUI")
local InfoTab = Window:NewTab("Info")
local AuthorSection = InfoTab:NewSection("Author")


-- Aimbot 設定
local settings = {
    Aimbot = false,
    Aiming = false,
    Aimbot_TeamCheck = false,
    Aimbot_Draw_FOV = false,
    Aimbot_FOV_Radius = 1000,
    Aimbot_FOV_Color = Color3.fromRGB(255, 255, 255),
    Aimbot_AimPart = "Head", -- 預設瞄準部位
    WallCheck = false,
    ESP = false,
    ShowHealth = false,
    ShowTracers = false,
    TracersThickness = 1,
    ShowNameTag = false,
    NameTagSize = 10,
    SoftAim = false,
    HitBox = false,
    HitBoxSize = 10,
    Noclip = false,
    Fly = false,
    FlySpeed = 50,
    CustomWalk = false,
    CustomWalkSpeed = 16,
    WalkSpeedMode = "None",
    CustomJumpPower = 50,
    CustomJumpEnabled = false,
    infJump = false,
    airWalk = false,
    airWalkHeight = nil,
    clickTP = false,
    killall = false,
    Movementtrajectory = false,
    Rotationbot = false,
    RotationSpeed = 5
}

-- 瞄準部位映射
local aimPartMap = {
    ["Head"] = "Head",       -- 頭部
    ["Body"] = "UpperTorso", -- 身體
    ["Foot"] = "LowerTorso"  -- 腳部
}

-- 初始化 FOV 圓形
local fovCircle = Drawing.new("Circle")
fovCircle.Visible = settings.Aimbot_Draw_FOV
fovCircle.Radius = settings.Aimbot_FOV_Radius
fovCircle.Color = settings.Aimbot_FOV_Color
fovCircle.Thickness = 1
fovCircle.Filled = false
fovCircle.Transparency = 1

-- 更新 FOV 圓形位置
local function updateFOVPosition()
    local dwCamera = workspace.CurrentCamera
    fovCircle.Position = Vector2.new(dwCamera.ViewportSize.X / 2, dwCamera.ViewportSize.Y / 2)
end

-- 更新 FOV 設定
local function updateFOVSettings()
    fovCircle.Visible = settings.Aimbot_Draw_FOV
    fovCircle.Radius = settings.Aimbot_FOV_Radius
end

-- Aimbot 開關
AimbotSection:NewToggle("Aimbot", "Toggle Aimbot", function(state)
    settings.Aimbot = state
end)

-- 團隊檢查開關
AimbotSection:NewToggle("Team Check", "Toggle Team Check", function(state)
    settings.Aimbot_TeamCheck = state
end)

-- 牆壁檢查開關
AimbotSection:NewToggle("Wall Check", "Toggle Wall Check", function(state)
    settings.WallCheck = state
end)

-- 瞄準部位選擇
AimbotSection:NewDropdown("Aimbot Location", "Select Aim Part", { "Head", "Body", "Foot" }, function(AimbotLocation)
    settings.Aimbot_AimPart = aimPartMap[AimbotLocation] -- 根據映射更新部位
end)



-- 引入 UserInputService 來偵測鍵盤輸入
local dwUIS = game:GetService("UserInputService")

-- 監聽右鍵按下事件
dwUIS.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        settings.Aiming = true
    end
end)

-- 監聽右鍵鬆開事件
dwUIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        settings.Aiming = false
    end
end)

-- 主要的瞄準輔助功能邏輯
local dwRunService = game:GetService("RunService")
local dwEntities = game:GetService("Players")
local dwLocalPlayer = dwEntities.LocalPlayer
local dwMouse = dwLocalPlayer:GetMouse()
local dwCamera = workspace.CurrentCamera

-- 射線檢查牆壁阻礙
local function isVisible(character)
    if not character or not character:FindFirstChild("HumanoidRootPart") then
        return false
    end

    -- 確保指定部位存在
    local aimPart = character:FindFirstChild(settings.Aimbot_AimPart)
    if not aimPart then
        return false -- 如果部位未找到，返回 false
    end

    -- 射線原點
    local origin = dwCamera.CFrame.Position
    local direction = (aimPart.Position - origin).Unit * 500

    -- 定義射線參數
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = { dwLocalPlayer.Character } -- 過濾掉自己的角色
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.IgnoreWater = true

    -- 執行射線
    local result = workspace:Raycast(origin, direction, raycastParams)

    -- 如果沒有物體阻礙射線，則目標可見
    if result then
        if result.Instance:IsDescendantOf(character) then
            return true
        else
            return false
        end
    end

    return true
end

dwRunService.RenderStepped:Connect(function()
    local dist = math.huge
    local closestChar = nil

    -- 只有在啟用 Aimbot 且正在瞄準時（即按下右鍵）才執行瞄準輔助
    if settings.Aimbot and settings.Aiming then
        for _, player in ipairs(dwEntities:GetPlayers()) do
            if player ~= dwLocalPlayer and player.Character then
                local humanoid = player.Character:FindFirstChild("Humanoid")
                local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
                if humanoid and rootPart and humanoid.Health > 0 then
                    if not settings.Aimbot_TeamCheck or (player.Team ~= dwLocalPlayer.Team) then
                        -- 檢查目標是否在 FOV 半徑內
                        local aimPart = player.Character:FindFirstChild(settings.Aimbot_AimPart) -- 確保檢查每個玩家指定的部位
                        if aimPart then
                            local aimPartPos, onScreen = dwCamera:WorldToViewportPoint(aimPart.Position)
                            if onScreen then
                                local distance = (Vector2.new(dwMouse.X, dwMouse.Y) - Vector2.new(aimPartPos.X, aimPartPos.Y))
                                    .Magnitude
                                if distance < dist and distance < settings.Aimbot_FOV_Radius then
                                    -- 檢查牆壁阻礙
                                    if settings.WallCheck then
                                        if isVisible(player.Character) then
                                            dist = distance
                                            closestChar = player.Character
                                        end
                                    else
                                        dist = distance
                                        closestChar = player.Character
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end

        -- 如果找到最近的目標，則瞄準該目標
        if closestChar then
            local aimPartPos = closestChar[settings.Aimbot_AimPart].Position
            dwCamera.CFrame = CFrame.new(dwCamera.CFrame.Position, aimPartPos)
        end
    end

    -- 每幀更新 FOV 圓形位置
    updateFOVPosition()
end)



-- 顯示 FOV 圓形開關
FOVSection:NewToggle("Show FOV", "Toggle Show FOV Circle", function(state)
    settings.Aimbot_Draw_FOV = state
    updateFOVSettings()
end)

-- FOV 圓形大小調整
FOVSection:NewSlider("FOV Size", "Adjust FOV Circle Size", 1000, 10, function(Size)
    settings.Aimbot_FOV_Radius = Size
    updateFOVSettings()
end)



local Players = game:GetService("Players")
local RunService = game:GetService("RunService")


-- 旋轉機制
local function rotatePlayer()
    local player = Players.LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

    -- 持續旋轉
    while settings.Rotationbot do
        -- 獲取當前的 CFrame
        local currentCFrame = humanoidRootPart.CFrame
        -- 旋轉角色
        humanoidRootPart.CFrame = currentCFrame * CFrame.Angles(0, math.rad(settings.RotationSpeed), 0)
        RunService.RenderStepped:Wait() -- 每幀等待
    end
end

-- 創建旋轉開關
CombatOtherSection:NewToggle("Rotation bot", "Toggle Rotation bot", function(state)
    settings.Rotationbot = state
    if state then
        rotatePlayer() -- 開始旋轉
    end
end)

-- 創建旋轉速度滑桿
CombatOtherSection:NewSlider("Rotation Speed", "Change Rotation Speed", 20, 1, function(speed)
    settings.RotationSpeed = speed -- 更新旋轉速度
end)

-- 將旋轉邏輯與視角分開
RunService.RenderStepped:Connect(function()
    if settings.Rotationbot then
        local player = Players.LocalPlayer
        local character = player.Character
        if character and character:FindFirstChild("HumanoidRootPart") then
            local hrp = character.HumanoidRootPart
            -- 讓玩家的攝影機不受到旋轉影響
            hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(settings.RotationSpeed), 0)
        end
    end
end)



-- ESP 腳本
local lplr = game.Players.LocalPlayer
local camera = game:GetService("Workspace").CurrentCamera
local worldToViewportPoint = camera.WorldToViewportPoint

local HeadOff = Vector3.new(0, 0.5, 0)
local LegOff = Vector3.new(0, 3, 0)

-- 創建 ESP
local function createESP(player)
    local BoxOutline = Drawing.new("Square")
    BoxOutline.Visible = false
    BoxOutline.Color = Color3.new(0, 0, 0)
    BoxOutline.Thickness = 3
    BoxOutline.Transparency = 1
    BoxOutline.Filled = false

    local Box = Drawing.new("Square")
    Box.Visible = false
    Box.Color = Color3.new(1, 1, 1)
    Box.Thickness = 1
    Box.Transparency = 1
    Box.Filled = false

    local HealthBarOutline = Drawing.new("Square")
    HealthBarOutline.Thickness = 3
    HealthBarOutline.Filled = false
    HealthBarOutline.Color = Color3.new(0, 0, 0)
    HealthBarOutline.Visible = false

    local HealthBar = Drawing.new("Square")
    HealthBar.Filled = true
    HealthBar.Transparency = 1
    HealthBar.Visible = false

    local Tracer = Drawing.new("Line")
    Tracer.Visible = false
    Tracer.Color = Color3.new(1, 1, 1) -- 追蹤線顏色
    Tracer.Thickness = settings.TracersThickness

    local function boxesp()
        game:GetService("RunService").RenderStepped:Connect(function()
            if player.Character and player.Character:FindFirstChild("Humanoid") and player.Character:FindFirstChild("HumanoidRootPart") and player ~= lplr and player.Character.Humanoid.Health > 0 then
                local Vector, onScreen = camera:WorldToViewportPoint(player.Character.HumanoidRootPart.Position)

                local RootPart = player.Character.HumanoidRootPart
                local Head = player.Character.Head
                local RootPosition, RootVis = worldToViewportPoint(camera, RootPart.Position)
                local HeadPosition = worldToViewportPoint(camera, Head.Position + HeadOff)
                local LegPosition = worldToViewportPoint(camera, RootPart.Position - LegOff)

                if onScreen then
                    BoxOutline.Size = Vector2.new(2000 / RootPosition.Z, HeadPosition.Y - LegPosition.Y)
                    BoxOutline.Position = Vector2.new(RootPosition.X - BoxOutline.Size.X / 2,
                        RootPosition.Y - BoxOutline.Size.Y / 2)
                    BoxOutline.Visible = settings.ESP -- 根據設定顯示或隱藏

                    Box.Size = Vector2.new(2000 / RootPosition.Z, HeadPosition.Y - LegPosition.Y)
                    Box.Position = Vector2.new(RootPosition.X - Box.Size.X / 2, RootPosition.Y - Box.Size.Y / 2)
                    Box.Visible = settings.ESP -- 根據設定顯示或隱藏

                    HealthBarOutline.Size = Vector2.new(2, HeadPosition.Y - LegPosition.Y)
                    HealthBarOutline.Position = BoxOutline.Position - Vector2.new(6, 0)
                    HealthBarOutline.Visible = settings.ESP and settings.ShowHealth -- 根據設定顯示或隱藏生命條外框

                    HealthBar.Size = Vector2.new(2,
                        (HeadPosition.Y - LegPosition.Y) /
                        (player.NRPBS.MaxHealth.Value / math.clamp(player.NRPBS.Health.Value, 0, player.NRPBS:WaitForChild("MaxHealth").Value)))
                    HealthBar.Position = Vector2.new(Box.Position.X - 6, Box.Position.Y + (1 / HealthBar.Size.Y))
                    HealthBar.Color = Color3.fromRGB(
                        255 - 255 / (player.NRPBS.MaxHealth.Value / player.NRPBS.Health.Value),
                        255 / (player.NRPBS.MaxHealth.Value / player.NRPBS.Health.Value), 0)
                    HealthBar.Visible = settings.ESP and settings.ShowHealth -- 根據設定顯示或隱藏生命條

                    if player.TeamColor == lplr.TeamColor then
                        -- 同隊
                        BoxOutline.Visible = false
                        Box.Visible = false
                        HealthBarOutline.Visible = false
                        HealthBar.Visible = false
                        Tracer.Visible = false -- 同隊則隱藏追蹤線
                        Tracer.Thickness = settings.TracersThickness
                    else
                        -- 敵隊
                        BoxOutline.Visible = settings.ESP
                        Box.Visible = settings.ESP
                        HealthBarOutline.Visible = settings.ShowHealth
                        HealthBar.Visible = settings.ShowHealth

                        -- 顯示追蹤線
                        Tracer.From = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y) -- 從螢幕底部開始
                        Tracer.To = Vector2.new(RootPosition.X, RootPosition.Y)                     -- 指向玩家的頭部
                        Tracer.Visible = settings.ShowTracers                                       -- 根據設定顯示或隱藏追蹤線
                        Tracer.Thickness = settings.TracersThickness
                    end
                else
                    BoxOutline.Visible = false
                    Box.Visible = false
                    HealthBarOutline.Visible = false
                    HealthBar.Visible = false
                    Tracer.Visible = false -- 隱藏追蹤線
                end
            else
                BoxOutline.Visible = false
                Box.Visible = false
                HealthBarOutline.Visible = false
                HealthBar.Visible = false
                Tracer.Visible = false -- 隱藏追蹤線
            end
        end)
    end

    coroutine.wrap(boxesp)()
end

-- 為現有玩家創建 ESP
for _, player in ipairs(game.Players:GetPlayers()) do
    if player ~= lplr then
        createESP(player)
    end
end

-- 為新加入的玩家創建 ESP
game.Players.PlayerAdded:Connect(function(player)
    createESP(player)
end)

-- ESP 設定開關
ESPSection:NewToggle("ESP", "Toggle ESP", function(state)
    settings.ESP = state -- 更新設定
end)

ESPSection:NewToggle("Health", "Toggle Show Health", function(state)
    settings.ShowHealth = state -- 更新設定
end)

ESPSection:NewToggle("Tracers", "Toggle Show Tracers", function(state)
    settings.ShowTracers = state -- 更新設定
end)

ESPSection:NewSlider("Tracers Thickness", "Adjust the thickness of the Tracers", 10, 1, function(Thickness)
    settings.TracersThickness = Thickness
end)



local function createNameTags()
    local RunService = game:GetService("RunService")
    local Players = game:GetService("Players")
    local camera = workspace.CurrentCamera -- 確保使用當前的攝像頭
    local lplr = Players.LocalPlayer       -- 本地玩家

    -- 創建名稱標籤
    local function createNameTag(player)
        local NameTag = Drawing.new("Text")
        NameTag.Visible = false
        NameTag.Color = Color3.new(1, 1, 1)        -- 名稱顏色
        NameTag.Size = settings.NameTagSize or 10  -- 使用設置的大小或預設大小
        NameTag.Center = true
        NameTag.Outline = true                     -- 添加外框
        NameTag.OutlineColor = Color3.new(0, 0, 0) -- 外框顏色

        -- 更新名稱標籤位置
        local function updateNameTag()
            if player.Character and player.Character:FindFirstChild("Humanoid") and player.Character:FindFirstChild("HumanoidRootPart") then
                local humanoid = player.Character.Humanoid
                if humanoid.Health > 0 then
                    local rootPart = player.Character.HumanoidRootPart
                    local rootPosition, onScreen = worldToViewportPoint(camera, rootPart.Position + Vector3.new(0, 3, 0)) -- 將名稱標籤放在角色頭部上方
                    NameTag.Position = Vector2.new(rootPosition.X, rootPosition.Y * 1.05)
                    NameTag.Text = player.Name
                    NameTag.Visible = settings.ShowNameTag
                else
                    NameTag.Visible = false
                end
            else
                NameTag.Visible = false
            end
        end

        -- 持續更新名稱標籤
        RunService.RenderStepped:Connect(updateNameTag)
    end

    -- 為現有玩家創建名稱標籤
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= lplr then
            createNameTag(player)
        end
    end

    -- 為新加入的玩家創建名稱標籤
    Players.PlayerAdded:Connect(function(player)
        createNameTag(player)
    end)
end

-- 調用函數以創建名稱標籤
createNameTags()

-- 設定名稱標籤的開關
ESPSection:NewToggle("NameTag", "Toggle Show NameTag", function(state)
    settings.ShowNameTag = state -- 更新設定
end)

ESPSection:NewSlider("NameTag Size", "Adjust the size of the NameTag", 100, 10, function(Size)
    settings.NameTagSize = Size
end)



local TweenService = game:GetService("TweenService")
local points = {} -- 儲存運動軌跡點的表
local trajectoryLine = Instance.new("Folder") -- 用於存放運動軌跡的線條
trajectoryLine.Parent = game:GetService("Workspace")

-- 創建運動軌跡的線條
local function createTrajectoryLine(startPos, endPos)
    local line = Instance.new("Part")
    line.Size = Vector3.new(0.1, 0.1, (endPos - startPos).Magnitude) -- 根據起始和結束位置設置大小
    line.Position = (startPos + endPos) / 2 -- 線條的中心位置
    line.CFrame = CFrame.new(startPos, endPos) -- 設定方向
    line.Anchored = true
    line.CanCollide = false
    line.BrickColor = BrickColor.new("White") -- 設定顏色為白色
    line.Material = Enum.Material.Neon -- 設定材質為霓虹
    line.Parent = trajectoryLine -- 將線條加入到工作空間

    -- 使用 TweenService 讓線條慢慢消失
    local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
    local tween = TweenService:Create(line, tweenInfo, {Transparency = 1})

    tween:Play()
    tween.Completed:Connect(function()
        line:Destroy() -- 當淡出結束後銷毀線條
    end)
end

-- Catmull-Rom 曲線生成
local function catmullRom(p0, p1, p2, p3, numPoints)
    local points = {}
    for i = 0, numPoints do
        local t = i / numPoints
        local tt = t * t
        local ttt = tt * t

        local q0 = -0.5 * p0 + 1.5 * p1 - 1.5 * p2 + 0.5 * p3
        local q1 = 1.0 * p0 - 2.5 * p1 + 2.0 * p2 - 0.5 * p3
        local q2 = -0.5 * p0 + 0.5 * p2
        local q3 = p1

        local point = (q0 * ttt) + (q1 * tt) + (q2 * t) + q3
        table.insert(points, point)
    end
    return points
end

-- 創建曲線運動軌跡
local function updateMovementTrajectory(character)
    local hrp = character:WaitForChild("HumanoidRootPart")
    local currentPos = hrp.Position - Vector3.new(0, 2, 0) -- 調整到腳部的位置

    -- 儲存當前位置
    table.insert(points, currentPos)

    -- 限制儲存的點數，避免佔用過多記憶體
    if #points > 4 then -- 至少保留 4 個點以生成曲線
        table.remove(points, 1) -- 移除最早的點
    end

    -- 畫出運動軌跡的曲線
    if #points >= 4 then
        local curvePoints = catmullRom(points[#points-3], points[#points-2], points[#points-1], points[#points], 20)
        for i = 1, #curvePoints - 1 do
            createTrajectoryLine(curvePoints[i], curvePoints[i + 1]) -- 生成連接曲線點的線條
        end
    end
end

-- 切換運動軌跡顯示的選項
OtherVisualsSection:NewToggle("Movement trajectory", "Toggle Show Movement trajectory", function(state)
    local player = game.Players.LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()

    if state then
        settings.Movementtrajectory = true
        local updateCount = 0 -- 計數器，用於減少更新頻率
        -- 持續更新運動軌跡
        local updateConnection = game:GetService("RunService").Heartbeat:Connect(function()
            updateCount = updateCount + 1
            if settings.Movementtrajectory and updateCount % 5 == 0 then -- 每 5 幀更新一次
                updateMovementTrajectory(character)
            end
        end)
        character:SetAttribute("TrajectoryUpdateConnection", updateConnection)
    else
        settings.Movementtrajectory = false
        -- 斷開更新連接
        local updateConnection = character:GetAttribute("TrajectoryUpdateConnection")
        if updateConnection then
            updateConnection:Disconnect()
            character:SetAttribute("TrajectoryUpdateConnection", nil)
        end
        -- 清空點數
        points = {}
    end
end)


local Lighting = game:GetService("Lighting")

-- 儲存原始的環境光設置
local originalAmbient = Lighting.Ambient
local originalOutdoorAmbient = Lighting.OutdoorAmbient

-- 切換夜視功能
OtherVisualsSection:NewToggle("Night Vision", "Toggle night vision", function(state)
    if state then
        -- 開啟夜視效果，增加 Ambient 和 OutdoorAmbient 的亮度
        Lighting.Ambient = Color3.fromRGB(200, 200, 200) -- 增加環境光
        Lighting.OutdoorAmbient = Color3.fromRGB(200, 200, 200) -- 增加戶外環境光
    else
        -- 恢復原始的環境光設置
        Lighting.Ambient = originalAmbient
        Lighting.OutdoorAmbient = originalOutdoorAmbient
    end
end)





local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local mouse = LocalPlayer:GetMouse()
local Camera = workspace.CurrentCamera

local fov = settings.Aimbot_FOV_Radius
local fovCircle = true
local target = nil

if fovCircle then
    local fovc = Drawing.new('Circle')
    fovc.Transparency = 1
    fovc.Thickness = 1.5
    fovc.Visible = false
    fovc.Color = Color3.fromRGB(255, 255, 255)
    fovc.Radius = fov

    -- 將 FOV 圓圈放在螢幕中心並隨時更新
    RunService:BindToRenderStep("FovCircle", 1, function()
        local screenSize = workspace.CurrentCamera.ViewportSize
        fovc.Position = Vector2.new(screenSize.X / 2, screenSize.Y / 2)
    end)
end


-- 設置 HitBox 的開關和大小調整
HitBoxSection:NewToggle("HitBox", "Toggle HitBox", function(state)
    settings.HitBox = state
end)

HitBoxSection:NewSlider("HitBox Size", "Adjust HitBox Size", 30, 10, function(Size)
    settings.HitBoxSize = Size
end)

-- 獲取玩家對象的函數
local players = game:GetService("Players")
local plr = players.LocalPlayer

-- 處理 HitBox 大小和透明度的邏輯
local function AdjustHitBox(character, size, transparency)
    if character and character:FindFirstChild("HumanoidRootPart") then
        -- 修改右大腿
        local rightLeg = character:FindFirstChild("RightUpperLeg")
        if rightLeg then
            rightLeg.CanCollide = false
            rightLeg.Transparency = transparency
            rightLeg.Size = Vector3.new(size, size, size)
        end

        -- 修改左大腿
        local leftLeg = character:FindFirstChild("LeftUpperLeg")
        if leftLeg then
            leftLeg.CanCollide = false
            leftLeg.Transparency = transparency
            leftLeg.Size = Vector3.new(size, size, size)
        end

        -- 修改頭部的 HitBox
        local headHB = character:FindFirstChild("HeadHB")
        if headHB then
            headHB.CanCollide = false
            headHB.Transparency = transparency
            headHB.Size = Vector3.new(size, size, size)
        end

        -- 修改 HumanoidRootPart
        local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
        if humanoidRootPart then
            humanoidRootPart.CanCollide = false
            humanoidRootPart.Transparency = transparency / 2 -- 減少透明度
            humanoidRootPart.Size = Vector3.new(size, size, size)
        end
    end
end

-- 持續修改其他玩家的 HitBox
coroutine.wrap(function()
    while true do
        if settings.HitBox then
            for _, v in pairs(players:GetPlayers()) do
                if v ~= plr and v.Character then
                    AdjustHitBox(v.Character, settings.HitBoxSize or 13, 0.5)
                end
            end
        end
        wait(1) -- 每隔一秒檢查一次
    end
end)()


-- 定義獲取武器的函數
local function GetGun()
    local GunFromGui = game.Players.LocalPlayer.PlayerGui.GUI.Client.Variables.gun.Value
    if GunFromGui then
        local GunFromStorage = game:GetService("ReplicatedStorage").Weapons:FindFirstChild(tostring(GunFromGui))
        if GunFromStorage then
            return GunFromStorage
        end
    end
    return nil
end

-- 無限彈藥功能
local function UnlimitedAmmo()
    while wait() do
        local PlayerGui = game:GetService("Players").LocalPlayer.PlayerGui.GUI.Client.Variables
        PlayerGui.ammocount.Value = 999
        PlayerGui.ammocount2.Value = 999
    end
end

-- 無後座力功能
local function NoRecoil()
    while wait() do
        local gun = GetGun()
        if gun and gun:FindFirstChild("RecoilControl") then
            gun.RecoilControl.Value = 0
        end
    end
end

-- 快速射擊功能
local function RapidFire()
    while wait() do
        local gun = GetGun()
        if gun and gun:FindFirstChild("FireRate") then
            gun.FireRate.Value = 0.02
        end
    end
end

-- 自動射擊功能
local function AutoGun()
    while wait() do
        local gun = GetGun()
        if gun and gun:FindFirstChild("Auto") then
            gun.Auto.Value = true
        end
    end
end

-- 設置按鈕並綁定功能
WeaponSection:NewButton("Unlimited Ammo", "Enables unlimited ammo", function()
    UnlimitedAmmo()
end)

WeaponSection:NewButton("No Recoil", "Disables recoil", function()
    NoRecoil()
end)

WeaponSection:NewButton("Rapid Fire", "Enables rapid fire", function()
    RapidFire()
end)

WeaponSection:NewButton("Auto Gun", "Enables automatic firing", function()
    AutoGun()
end)



-- 切換 Noclip 的選項
OtherSection:NewToggle("Noclip", "Toggle Noclip", function(state)
    settings.Noclip = state -- 設置 Noclip 狀態
    local player = game.Players.LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()

    -- 啟用或禁用 Noclip
    if settings.Noclip then
        -- 當 Noclip 被啟用時，執行以下操作
        for _, part in pairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false -- 使部件不再碰撞
            end
        end

        -- 持續檢查是否要保持 Noclip
        while settings.Noclip do
            wait()
            for _, part in pairs(character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false -- 持續保持部件不碰撞
                end
            end
        end
    else
        -- 禁用 Noclip，恢復碰撞
        for _, part in pairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = true -- 恢復部件的碰撞
            end
        end
    end
end)



-- 控制飛行方向的函數
local function updateFlyDirection(character, camera)
    local direction = Vector3.new(0, 0, 0)
    local userInputService = game:GetService("UserInputService")

    if userInputService:IsKeyDown(Enum.KeyCode.Space) then
        direction = direction + Vector3.new(0, 1, 0) -- 向上
    end
    if userInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
        direction = direction + Vector3.new(0, -1, 0) -- 向下
    end
    if userInputService:IsKeyDown(Enum.KeyCode.W) then
        direction = direction + camera.CFrame.LookVector -- 向前
    end
    if userInputService:IsKeyDown(Enum.KeyCode.S) then
        direction = direction - camera.CFrame.LookVector -- 向後
    end
    if userInputService:IsKeyDown(Enum.KeyCode.A) then
        direction = direction - camera.CFrame.RightVector -- 向左
    end
    if userInputService:IsKeyDown(Enum.KeyCode.D) then
        direction = direction + camera.CFrame.RightVector -- 向右
    end

    -- 更新角色位置
    if direction.Magnitude > 0 then
        local newPosition = character.HumanoidRootPart.Position +
            direction.Unit * settings.FlySpeed * game:GetService("RunService").RenderStepped:Wait()
        character:SetPrimaryPartCFrame(CFrame.new(newPosition))
    end
end

-- 切換 Fly 的選項
FlySection:NewToggle("Fly", "Toggle Fly", function(state)
    local player = game.Players.LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()
    local humanoid = character:WaitForChild("Humanoid")
    local hrp = character:WaitForChild("HumanoidRootPart")

    if state then
        settings.Fly = true
        -- 禁用重力
        if not hrp:FindFirstChild("BodyVelocity") then
            local bodyVelocity = Instance.new("BodyVelocity")
            bodyVelocity.Velocity = Vector3.new(0, 0, 0)
            bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
            bodyVelocity.Parent = hrp
        end

        -- 獲取攝像頭
        local camera = workspace.CurrentCamera

        -- 持續更新飛行方向
        local updateConnection = game:GetService("RunService").RenderStepped:Connect(function()
            if settings.Fly then
                updateFlyDirection(character, camera)
            end
        end)

        -- 存儲連接以便之後斷開
        character:SetAttribute("FlyUpdateConnection", updateConnection)
    else
        settings.Fly = false
        -- 移除 BodyVelocity
        local bodyVelocity = hrp:FindFirstChild("BodyVelocity")
        if bodyVelocity then
            bodyVelocity:Destroy()
        end

        -- 斷開更新連接
        local updateConnection = character:GetAttribute("FlyUpdateConnection")
        if updateConnection then
            updateConnection:Disconnect()
            character:SetAttribute("FlyUpdateConnection", nil)
        end

        -- 重置角色狀態
        humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
    end
end)

-- 飛行速度滑塊
FlySection:NewSlider("FlySpeed", "Change Fly Speed", 1000, 10, function(speed)
    settings.FlySpeed = speed -- 設置飛行速度
end)

-- 控制角色移動的函數
local function updateWalkDirection(character)
    local userInputService = game:GetService("UserInputService")
    local camera = workspace.CurrentCamera
    local hrp = character:WaitForChild("HumanoidRootPart")
    local humanoid = character:WaitForChild("Humanoid")

    -- 獲取相機的前方和右方向量，但忽略Y軸
    local cameraLook = camera.CFrame.LookVector
    local cameraRight = camera.CFrame.RightVector
    local flatLook = Vector3.new(cameraLook.X, 0, cameraLook.Z).Unit
    local flatRight = Vector3.new(cameraRight.X, 0, cameraRight.Z).Unit

    local moveDirection = Vector3.new(0, 0, 0)

    -- 檢查按鍵輸入
    if userInputService:IsKeyDown(Enum.KeyCode.W) then
        moveDirection = moveDirection + flatLook
    end
    if userInputService:IsKeyDown(Enum.KeyCode.S) then
        moveDirection = moveDirection - flatLook
    end
    if userInputService:IsKeyDown(Enum.KeyCode.A) then
        moveDirection = moveDirection - flatRight
    end
    if userInputService:IsKeyDown(Enum.KeyCode.D) then
        moveDirection = moveDirection + flatRight
    end

    -- 當移動方向有變化時，標準化移動方向
    if moveDirection.Magnitude > 0 then
        moveDirection = moveDirection.Unit
        local moveAmount = moveDirection * settings.CustomWalkSpeed * 0.016 -- 0.016 是基於 60 FPS
        local newPosition = hrp.Position + moveAmount

        -- Raycast 檢測前方障礙物
        local rayOrigin = hrp.Position
        local rayDirection = moveAmount
        local raycastParams = RaycastParams.new()
        raycastParams.FilterType = Enum.RaycastFilterType.Exclude
        raycastParams.FilterDescendantsInstances = { character }
        local raycastResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)

        -- 如果沒有碰撞，更新角色位置
        if not raycastResult then
            hrp.CFrame = CFrame.new(newPosition, newPosition + flatLook)
        else
            hrp.Velocity = Vector3.new(0, hrp.Velocity.Y, 0)
        end
    else
        -- 沒有移動輸入，保持角色朝向不變
        hrp.Velocity = Vector3.new(0, hrp.Velocity.Y, 0)
    end

    -- BHop模式處理：當角色觸地時自動跳躍，並在空中加速
    if settings.WalkSpeedMode == "BHop" then
        -- 當角色觸地時自動跳躍
        if humanoid:GetState() == Enum.HumanoidStateType.Running then
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping) -- 自動跳躍
        else
            -- 在空中時增加速度
            local additionalSpeed = Vector3.new(moveDirection.X, 0, moveDirection.Z) * settings.CustomWalkSpeed * 0.02
            hrp.Velocity = hrp.Velocity + additionalSpeed
        end
    end
end

-- 切換自訂步行功能的選項
SpeedSection:NewToggle("WalkSpeed", "Toggle Custom Walk", function(state)
    local player = game.Players.LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()

    if state then
        settings.CustomWalk = true
        local updateConnection = game:GetService("RunService").Heartbeat:Connect(function(dt)
            if settings.CustomWalk then
                updateWalkDirection(character)
            end
        end)
        character:SetAttribute("WalkUpdateConnection", updateConnection)
    else
        settings.CustomWalk = false
        local updateConnection = character:GetAttribute("WalkUpdateConnection")
        if updateConnection then
            updateConnection:Disconnect()
            character:SetAttribute("WalkUpdateConnection", nil)
        end
    end
end)

-- 創建步行速度滑塊
SpeedSection:NewSlider("WalkSpeed", "Change Custom WalkSpeed", 500, 1, function(speed)
    settings.CustomWalkSpeed = speed
end)

-- WalkSpeed模式下拉選單
SpeedSection:NewDropdown("WalkSpeed Mode", "WalkSpeed Mode", { "None", "BHop" }, function(Mode)
    settings.WalkSpeedMode = Mode
end)


local function setupJumpSystem()
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local UserInputService = game:GetService("UserInputService")

    local player = Players.LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()
    local humanoid = character:WaitForChild("Humanoid")
    local originalJump = humanoid.Jump

    -- 檢查是否在地面上的函數
    local function isOnGround(character)
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if not humanoid then return false end

        return humanoid:GetState() == Enum.HumanoidStateType.Running or
            humanoid:GetState() == Enum.HumanoidStateType.RunningNoPhysics or
            humanoid:GetState() == Enum.HumanoidStateType.Landed
    end

    -- 修改跳躍行為的函數
    local function modifyJump()
        if isOnGround(character) then
            local root = character:WaitForChild("HumanoidRootPart")
            root.Velocity = Vector3.new(root.Velocity.X, settings.CustomJumpPower, root.Velocity.Z)
        end
    end

    -- 切換自訂跳躍功能的選項
    SpeedSection:NewToggle("JumpPower", "Toggle Custom Jump Power", function(state)
        settings.CustomJumpEnabled = state
        if state then
            humanoid.Jump = false
            UserInputService.JumpRequest:Connect(function()
                if settings.CustomJumpEnabled then
                    modifyJump()
                end
            end)
        else
            humanoid.Jump = originalJump
        end
    end)

    -- 創建新的跳躍力滑塊
    SpeedSection:NewSlider("JumpPower", "Change Custom Jump Power", 150, 1, function(power)
        settings.CustomJumpPower = power
    end)

    -- 監聽角色重生事件
    player.CharacterAdded:Connect(function(newCharacter)
        character = newCharacter
        humanoid = character:WaitForChild("Humanoid")
        originalJump = humanoid.Jump
        if settings.CustomJumpEnabled then
            humanoid.Jump = false
        end
    end)

    -- 確保跳躍力變化即時生效
    RunService.Heartbeat:Connect(function()
        if settings.CustomJumpEnabled and humanoid.Jump ~= false then
            humanoid.Jump = false
        end
    end)
end

-- 調用設置函數來初始化整個系統
setupJumpSystem()


-- 連接到角色的Humanoid
local function getHumanoid()
    -- 本地變量
    local player = game.Players.LocalPlayer
    local userInputService = game:GetService("UserInputService")
    local character = player.Character or player.CharacterAdded:Wait()
    return character:WaitForChild("Humanoid")
end

-- 無限跳躍功能
local function enableInfiniteJump()
    -- 本地變量
    local player = game.Players.LocalPlayer
    local userInputService = game:GetService("UserInputService")
    local humanoid = getHumanoid()

    -- 當玩家按下空格鍵時執行跳躍
    userInputService.JumpRequest:Connect(function()
        if settings.infJump and humanoid then
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end)
end

-- 切換無限跳躍的開關
local function toggleInfiniteJump(state)
    settings.infJump = state
end

-- 初始化無限跳躍
enableInfiniteJump()

OtherSection:NewToggle("Infinite Jump", "Toggle Infinite Jump", function(state)
    toggleInfiniteJump(state)
end)



local player = game.Players.LocalPlayer

-- 主 AirWalk 功能
local function toggleAirWalk(state)
    -- 定義所需的服務和變數
    local runService = game:GetService("RunService")
    local humanoidRootPart = player.Character and player.Character:WaitForChild("HumanoidRootPart")

    -- 如果狀態是啟用
    if state then
        settings.airWalk = true

        -- 玩家碰到地板時設置當前高度
        if humanoidRootPart and player.Character:FindFirstChild("Humanoid") then
            if player.Character.Humanoid.FloorMaterial ~= Enum.Material.Air then
                settings.airWalkHeight = humanoidRootPart.Position.Y
            end
        end

        -- 持續更新角色位置，保持在碰到地板時的高度
        local updateConnection
        updateConnection = runService.RenderStepped:Connect(function()
            if settings.airWalk and humanoidRootPart then
                local currentPosition = humanoidRootPart.Position

                -- 停止任何垂直運動
                humanoidRootPart.Velocity = Vector3.new(0, 0, 0)

                -- 若角色接觸地面，設置空中行走高度
                if player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.FloorMaterial ~= Enum.Material.Air then
                    settings.airWalkHeight = currentPosition.Y
                end

                -- 強制保持在設置的高度
                humanoidRootPart.Position = Vector3.new(currentPosition.X, settings.airWalkHeight, currentPosition.Z)
            else
                -- 如果 AirWalk 停用，斷開更新連接
                if updateConnection then
                    updateConnection:Disconnect()
                    updateConnection = nil
                end
            end
        end)
    else
        settings.airWalk = false
    end
end

-- 監控角色重生
player.CharacterAdded:Connect(function(character)
    -- 當角色重生時，禁用 AirWalk
    settings.airWalk = false
    settings.airWalkHeight = nil -- 重置高度設定

    -- 確保重新啟用 AirWalk
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    humanoidRootPart.AncestryChanged:Connect(function()
        if settings.airWalk then
            toggleAirWalk(true) -- 重新啟用 AirWalk
        end
    end)
end)

-- 觸發 AirWalk 功能
OtherSection:NewToggle("AirWalk", "Toggle AirWalk", function(state)
    toggleAirWalk(state)
end)

local player = game.Players.LocalPlayer
local mouse = player:GetMouse()

-- 點擊傳送功能
local function toggleClickTP(state)
    settings.clickTP = state
end

-- 熱鍵功能
ClickTPSection:NewToggle("Click TP", "Toggle Click TP", function(state)
    toggleClickTP(state)
end)

ClickTPSection:NewKeybind("Click TP hotkey", "Click TP hotkey", Enum.KeyCode.X, function()
    if settings.clickTP then
        local targetPosition = mouse.Hit.Position
        -- 確保角色存在
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local humanoidRootPart = player.Character.HumanoidRootPart
            -- 傳送角色到鼠標點擊的位置
            humanoidRootPart.CFrame = CFrame.new(targetPosition)
        end
    end
end)


local Players = game:GetService("Players")

-- 傳送到玩家的功能
local function teleportToPlayer(playerName)
    local targetPlayer = Players:FindFirstChild(playerName) -- 根據名稱獲取玩家對象

    if targetPlayer then
        -- 等待角色加載
        local character = targetPlayer.Character or targetPlayer.CharacterAdded:Wait() -- 等待角色創建

        if character then
            local humanoidRootPart = character:FindFirstChild("HumanoidRootPart") -- 查找HumanoidRootPart

            if humanoidRootPart then
                local targetPosition = humanoidRootPart.Position

                -- 確保本地玩家的角色存在
                local localPlayer = Players.LocalPlayer
                if localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    local localHumanoidRootPart = localPlayer.Character.HumanoidRootPart
                    -- 傳送角色到目標玩家的位置
                    localHumanoidRootPart.CFrame = CFrame.new(targetPosition)
                else
                    warn("Local player character not found.")
                end
            else
                warn("Target player's HumanoidRootPart not found.")
            end
        else
            warn("Target player's character not found.")
        end
    else
        warn("Player not found.")
    end
end

-- 創建文本框用於輸入玩家名稱
TeleportSection:NewTextBox("Teleport to Player", "Enter Player Name", function(playerName)
    if playerName and playerName ~= "" then
        teleportToPlayer(playerName) -- 調用傳送功能
    else
        warn("Invalid Player Name.")
    end
end)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- 創建切換按鈕
TeleportSection:NewToggle("KillAll", "KillAll", function(state)
    settings.killall = state
end)

-- 獲取所有其他隊伍的玩家
local function getOtherTeamPlayers()
    local otherPlayers = {}
    local localPlayer = Players.LocalPlayer
    local localTeam = localPlayer.Team

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= localPlayer and player.Team ~= localTeam then
            table.insert(otherPlayers, player)
        end
    end

    return otherPlayers
end

-- 傳送到玩家後面
local function teleportBehindPlayer(targetPlayer)
    local character = Players.LocalPlayer.Character
    local targetCharacter = targetPlayer.Character

    if character and targetCharacter then
        local hrp = character:FindFirstChild("HumanoidRootPart")
        local targetHrp = targetCharacter:FindFirstChild("HumanoidRootPart")

        if hrp and targetHrp then
            -- 計算 X 和 Y 座標差距
            local deltaX = math.abs(targetHrp.Position.X - hrp.Position.X)
            local deltaY = math.abs(targetHrp.Position.Y - hrp.Position.Y)

            -- 設定最大傳送距離
            local maxXDistance = 300-- 設定您希望的最大 X 距離
            local maxYDistance = 100 -- 設定您希望的最大 Y 距離

            -- 確保不會離得太遠
            if deltaX <= maxXDistance and deltaY <= maxYDistance then
                -- 計算目標玩家的後方位置，距離設為2
                local behind = targetHrp.CFrame * CFrame.new(0, 0, 2) -- 在目標玩家的後方2個單位
                hrp.CFrame = behind
            else
                warn("Target player is too far away to teleport.")
            end
        end
    end
end

-- 主要邏輯
RunService.Heartbeat:Connect(function()
    if settings.killall then
        local otherPlayers = getOtherTeamPlayers()
        if #otherPlayers > 0 then
            for _, player in ipairs(otherPlayers) do
                teleportBehindPlayer(player) -- 對所有其他隊伍玩家進行傳送
            end
        end
    end
end)
GUISection:NewKeybind("Hide GUI", "Hide GUI", Enum.KeyCode.P, function()
    Library:ToggleUI()
end)

AuthorSection:NewButton("Make By BriefBassoon117 (Discord)", "ENJOY :)))))", function()
end)
AuthorSection:NewButton("UI Lirary: Kavo", "Thanks", function()
end)
