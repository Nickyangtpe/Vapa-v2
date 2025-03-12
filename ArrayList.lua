-- ArrayList UI Library for Roblox
-- 功能：每個選項寬度獨立、右側對齊、並依照寬度由上到下（長到短）排序

local ArrayListUI = {}
local ArrayListItems = {}

-- Configuration
local config = {
    position = UDim2.new(1, -10, 0, 10), -- 位於螢幕右上角
    textSize = 16,
    font = Enum.Font.SourceSansBold,
    activeColor = Color3.fromRGB(255, 85, 85),    -- 主動項目的文字顏色
    inactiveColor = Color3.fromRGB(180, 180, 180), -- 非主動項目的文字顏色
    background = {
        transparency = 0.2,
        color = Color3.fromRGB(20, 20, 20)
    },
    verticalLine = {
        width = 2,
        color = Color3.fromRGB(255, 85, 85) -- 右側垂直線顏色
    },
    padding = 8,           -- 文字左右內距
    animationTime = 0.5,   -- 動畫時間
    animationStyle = Enum.EasingStyle.Quart,
    animationDirection = Enum.EasingDirection.Out
}

-- 建立主容器
local function createMainFrame()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "ArrayListUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent = game.CoreGui

    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainContainer"
    MainFrame.BackgroundColor3 = config.background.color
    MainFrame.BackgroundTransparency = config.background.transparency
    MainFrame.BorderSizePixel = 0
    MainFrame.Position = config.position
    MainFrame.Size = UDim2.new(0, 200, 0, 0) -- 寬度和高度會依項目動態更新
    MainFrame.AnchorPoint = Vector2.new(1, 0) -- 靠右上角對齊
    MainFrame.Parent = ScreenGui

    -- 在主容器右側建立一條垂直線
    local verticalLine = Instance.new("Frame")
    verticalLine.Name = "VerticalLine"
    verticalLine.BackgroundColor3 = config.verticalLine.color
    verticalLine.BorderSizePixel = 0
    verticalLine.Position = UDim2.new(1, 0, 0, 0) -- 停靠在右邊
    verticalLine.Size = UDim2.new(0, config.verticalLine.width, 1, 0)
    verticalLine.AnchorPoint = Vector2.new(0, 0)
    verticalLine.ZIndex = 2
    verticalLine.Parent = MainFrame

    return MainFrame
end

-- 初始化 UI
function ArrayListUI:Init()
    self.mainFrame = createMainFrame()
    self.items = {}  -- 儲存每個項目的資料
    return self
end

-- 重新排序並更新佈局
-- 依據每個項目計算出的寬度，從大到小排序，並重新排列（右對齊）
function ArrayListUI:UpdateLayout(animate)
    -- 依寬度由大到小排序
    table.sort(self.items, function(a, b) return a.width > b.width end)

    local yOffset = 0
    local maxWidth = 0

    for index, item in ipairs(self.items) do
        local targetPos = UDim2.new(1, 0, 0, yOffset)
        if animate then
            item.frame:TweenPosition(targetPos, config.animationDirection, config.animationStyle, config.animationTime, true)
        else
            item.frame.Position = targetPos
        end

        yOffset = yOffset + item.frame.Size.Y.Offset

        if item.width > maxWidth then
            maxWidth = item.width
        end
    end

    -- 更新主容器的寬度（以最大的項目寬度為準）和高度
    if animate then
        game:GetService("TweenService"):Create(
            self.mainFrame,
            TweenInfo.new(config.animationTime, config.animationStyle, config.animationDirection),
            {Size = UDim2.new(0, maxWidth, 0, yOffset)}
        ):Play()
    else
        self.mainFrame.Size = UDim2.new(0, maxWidth, 0, yOffset)
    end

    -- 更新垂直線的尺寸（高度保持與主容器一致）
    local verticalLine = self.mainFrame:FindFirstChild("VerticalLine")
    if verticalLine then
        verticalLine.Size = UDim2.new(0, config.verticalLine.width, 1, 0)
    end
end

-- 新增項目
-- 每個項目的寬度依照文字內容計算，並加入項目後重新排序佈局
function ArrayListUI:AddItem(name, value, isActive)
    local itemColor = isActive and config.activeColor or config.inactiveColor
    local itemId = #self.items + 1

    -- 建立項目框架，稍後會根據文字寬度設定 Size
    local itemFrame = Instance.new("Frame")
    itemFrame.Name = "Item_" .. itemId
    itemFrame.BackgroundTransparency = 1
    itemFrame.AnchorPoint = Vector2.new(1, 0)  -- 右對齊
    itemFrame.Position = UDim2.new(1.5, 0, 0, 0) -- 初始位置在螢幕外右側
    itemFrame.Parent = self.mainFrame

    -- 建立文字標籤
    local textLabel = Instance.new("TextLabel")
    textLabel.Name = "Text"
    textLabel.BackgroundTransparency = 1
    textLabel.Font = config.font
    textLabel.TextSize = config.textSize
    textLabel.TextColor3 = itemColor
    textLabel.Text = value and (name .. " " .. value) or name
    textLabel.TextXAlignment = Enum.TextXAlignment.Right
    textLabel.Parent = itemFrame

    -- 使用 TextService 計算文字尺寸
    local TextService = game:GetService("TextService")
    local textSize = TextService:GetTextSize(textLabel.Text, config.textSize, config.font, Vector2.new(1000, config.textSize + 4))
    local computedWidth = textSize.X + config.padding * 2

    -- 設定項目框架的 Size（寬度獨立，高度固定）
    itemFrame.Size = UDim2.new(0, computedWidth, 0, config.textSize + 4)
    textLabel.Size = UDim2.new(1, -config.padding * 2, 1, 0)
    textLabel.Position = UDim2.new(0, config.padding, 0, 0)

    -- 儲存項目資料（包含計算出的寬度，供排序用）
    local itemData = {
        id = itemId,
        frame = itemFrame,
        text = textLabel,
        width = computedWidth,
        isActive = isActive,
        name = name,
        value = value
    }

    table.insert(self.items, itemData)
    ArrayListItems[itemId] = itemData

    -- 更新佈局，並加入動畫
    self:UpdateLayout(true)

    -- 新增項目時，讓項目從右側滑入，並淡入文字
    itemFrame:TweenPosition(UDim2.new(1, 0, 0, itemFrame.Position.Y.Offset), config.animationDirection, config.animationStyle, config.animationTime, true)
    textLabel.TextTransparency = 1
    game:GetService("TweenService"):Create(
        textLabel,
        TweenInfo.new(config.animationTime, config.animationStyle, config.animationDirection),
        {TextTransparency = 0}
    ):Play()

    return itemId
end

-- 移除項目（帶動畫）
function ArrayListUI:RemoveItem(itemId)
    local removeIndex = nil
    for i, item in ipairs(self.items) do
        if item.id == itemId then
            removeIndex = i
            break
        end
    end

    if removeIndex then
        local item = self.items[removeIndex]
        -- 淡出文字
        local tween = game:GetService("TweenService"):Create(
            item.text,
            TweenInfo.new(config.animationTime, config.animationStyle, config.animationDirection),
            {TextTransparency = 1}
        )
        tween:Play()

        -- 向右滑出項目框架
        item.frame:TweenPosition(UDim2.new(1.5, 0, 0, item.frame.Position.Y.Offset), config.animationDirection, config.animationStyle, config.animationTime, true, function()
            item.frame:Destroy()
        end)

        table.remove(self.items, removeIndex)
        ArrayListItems[itemId] = nil

        -- 更新剩餘項目的佈局
        self:UpdateLayout(true)
        return true
    end
    return false
end

-- 切換項目的啟用狀態（帶動畫效果）
function ArrayListUI:ToggleItem(itemId)
    for _, item in ipairs(self.items) do
        if item.id == itemId then
            item.isActive = not item.isActive
            local targetColor = item.isActive and config.activeColor or config.inactiveColor
            game:GetService("TweenService"):Create(
                item.text,
                TweenInfo.new(config.animationTime, config.animationStyle, config.animationDirection),
                {TextColor3 = targetColor}
            ):Play()

            -- 簡單的縮放動畫
            local originalSize = item.text.Size
            item.text.Size = UDim2.new(originalSize.X.Scale, originalSize.X.Offset, originalSize.Y.Scale, originalSize.Y.Offset * 1.2)
            game:GetService("TweenService"):Create(
                item.text,
                TweenInfo.new(config.animationTime, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out),
                {Size = originalSize}
            ):Play()
            return true
        end
    end
    return false
end

-- 清除所有項目（帶動畫）
function ArrayListUI:ClearAll()
    for i, item in ipairs(self.items) do
        game:GetService("TweenService"):Create(
            item.text,
            TweenInfo.new(config.animationTime * 0.8, config.animationStyle, config.animationDirection),
            {TextTransparency = 1}
        ):Play()

        local delayTime = math.min(i * 0.05, 0.5)
        task.delay(delayTime, function()
            item.frame:TweenPosition(UDim2.new(1.5, 0, 0, item.frame.Position.Y.Offset), config.animationDirection, config.animationStyle, config.animationTime * 0.8, true, function()
                item.frame:Destroy()
            end)
        end)
    end

    task.delay(config.animationTime + 0.5, function()
        self.items = {}
        ArrayListItems = {}
        self.mainFrame.Size = UDim2.new(0, 200, 0, 0)
    end)
end

-- 範例：自動執行示範
local function Example()
    local arrayList = ArrayListUI:Init()

    -- 新增一些範例項目（名稱、數值、是否啟用）
    arrayList:AddItem("FakeLag", "Dynamic", true)
    arrayList:AddItem("NoItemRelease", nil, true)
    arrayList:AddItem("Velocity", "Normal", false)
    arrayList:AddItem("Trajectories", nil, true)
    arrayList:AddItem("AutoClicker", nil, true)
    arrayList:AddItem("SilentAura", nil, true)
    arrayList:AddItem("Indicators", nil, true)
    arrayList:AddItem("AntiBot", nil, true)
    arrayList:AddItem("Reach", nil, true)
    arrayList:AddItem("Sprint", nil, true)
    arrayList:AddItem("ESP", nil, true)

    -- 3 秒後切換第三項目的狀態
    task.delay(3, function()
        arrayList:ToggleItem(3)
    end)

    -- 5 秒後新增一個項目
    task.delay(5, function()
        arrayList:AddItem("NewItem", "Active", true)
    end)

    -- 7 秒後移除第四個項目
    task.delay(7, function()
        arrayList:RemoveItem(4)
    end)
end

local API = {
    Init = function() return ArrayListUI:Init() end,
    RunExample = Example
}

-- 若腳本名稱為 "ArrayListLoader" 則自動執行範例
if script and script.Name == "ArrayListLoader" then
    Example()
end

return API
