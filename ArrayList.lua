-- ArrayList UI Library for Roblox  
-- 位於右上角，右側有一條垂直線，且項目依寬度由長到短排列

local ArrayListUI = {}  
local ArrayListItems = {}  

-- Configuration  
local config = {  
    position = UDim2.new(1, -10, 0, 10), -- 右上角  
    textSize = 16,  
    font = Enum.Font.SourceSansBold,  
    activeColor = Color3.fromRGB(255, 85, 85), -- 主動項目為紅色  
    inactiveColor = Color3.fromRGB(180, 180, 180), -- 非主動項目為灰色  
    background = {  
        transparency = 0.2,  
        color = Color3.fromRGB(20, 20, 20)  
    },  
    verticalLine = {  
        width = 2,  
        color = Color3.fromRGB(255, 85, 85) -- 右側紅色垂直線  
    },  
    padding = 8, -- 文字左右內邊距  
    animationTime = 0.5, -- 動畫持續時間  
    animationStyle = Enum.EasingStyle.Quart,  
    animationDirection = Enum.EasingDirection.Out  
}  

-- 建立主 UI 容器  
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
    MainFrame.Size = UDim2.new(0, 200, 0, 0) -- 初始高度為 0，之後自動調整  
    MainFrame.AnchorPoint = Vector2.new(1, 0) -- 固定在右上角  
    MainFrame.Parent = ScreenGui  
      
    -- 在右側建立垂直線  
    local verticalLine = Instance.new("Frame")  
    verticalLine.Name = "VerticalLine"  
    verticalLine.BackgroundColor3 = config.verticalLine.color  
    verticalLine.BorderSizePixel = 0  
    verticalLine.Position = UDim2.new(1, 0, 0, 0)  
    verticalLine.Size = UDim2.new(0, config.verticalLine.width, 1, 0)  
    verticalLine.AnchorPoint = Vector2.new(0, 0)  
    verticalLine.ZIndex = 2  
    verticalLine.Parent = MainFrame  
      
    return MainFrame  
end  

-- 初始化 UI  
function ArrayListUI:Init()  
    self.mainFrame = createMainFrame()  
    self.items = {}  
    return self  
end  

-- 依寬度降冪排序並重新排列所有項目  
function ArrayListUI:ReorderItems()  
    -- 根據項目寬度（獨立計算的值）排序  
    table.sort(self.items, function(a, b)
        return a.width > b.width
    end)
    
    local posY = 0  
    for i, item in ipairs(self.items) do  
        -- 以項目右側對齊主容器，位置 X 固定為 1（表示主容器的右邊界）  
        item.frame:TweenPosition(  
            UDim2.new(1, 0, 0, posY),  
            config.animationDirection,  
            config.animationStyle,  
            config.animationTime,  
            true  
        )  
        posY = posY + item.frame.Size.Y.Offset  
    end  
    -- 以動畫方式更新主容器高度  
    game:GetService("TweenService"):Create(  
        self.mainFrame,  
        TweenInfo.new(config.animationTime, config.animationStyle, config.animationDirection),  
        {Size = UDim2.new(0, self.mainFrame.Size.X.Offset, 0, posY)}  
    ):Play()  
end  

-- 取得目前所有項目的總高度  
function ArrayListUI:GetTotalHeight()  
    local height = 0  
    for _, item in ipairs(self.items) do  
        height = height + item.frame.Size.Y.Offset  
    end  
    return height  
end  

-- 新增項目：依照內容計算獨立寬度，並在新增後依寬度排序  
function ArrayListUI:AddItem(name, value, isActive)  
    local itemColor = isActive and config.activeColor or config.inactiveColor  
    local itemId = #self.items + 1  
      
    local text = value and (name .. " " .. value) or name  
    local textWidth = game:GetService("TextService"):GetTextSize(  
        text,  
        config.textSize,  
        config.font,  
        Vector2.new(1000, 100)  
    ).X  
      
    -- 每個項目的寬度：文字寬 + 左右內邊距  
    local itemWidth = textWidth + config.padding * 2  
      
    -- 建立項目容器（以 anchor (1,0) 使右側對齊）  
    local itemFrame = Instance.new("Frame")  
    itemFrame.Name = "Item_" .. itemId  
    itemFrame.BackgroundTransparency = 1  
    itemFrame.Size = UDim2.new(0, itemWidth, 0, config.textSize + 4)  
    itemFrame.AnchorPoint = Vector2.new(1, 0)  
    -- 初始位置設在主容器右側外部（以便滑入）  
    itemFrame.Position = UDim2.new(1, itemWidth, 0, self:GetTotalHeight())  
    itemFrame.Parent = self.mainFrame  
      
    -- 建立文字標籤，滿版後再靠右顯示  
    local textLabel = Instance.new("TextLabel")  
    textLabel.Name = "Text"  
    textLabel.BackgroundTransparency = 1  
    textLabel.Position = UDim2.new(0, config.padding, 0, 0)  
    textLabel.Size = UDim2.new(1, -config.padding * 2, 1, 0)  
    textLabel.Font = config.font  
    textLabel.TextSize = config.textSize  
    textLabel.TextColor3 = itemColor  
    textLabel.Text = text  
    textLabel.TextXAlignment = Enum.TextXAlignment.Right  
    textLabel.Parent = itemFrame  
      
    -- 封裝項目資料，並記錄獨立寬度  
    local itemData = {  
        id = itemId,  
        frame = itemFrame,  
        text = textLabel,  
        valueText = value,  
        isActive = isActive,  
        width = itemWidth  
    }  
    table.insert(self.items, itemData)  
      
    -- 更新主容器寬度（主容器寬度 = 最長項目寬度 + 垂直線寬）  
    local newParentWidth = itemWidth + config.verticalLine.width  
    if newParentWidth > self.mainFrame.Size.X.Offset then  
        self.mainFrame.Size = UDim2.new(0, newParentWidth, self.mainFrame.Size.Y.Scale, self.mainFrame.Size.Y.Offset)  
    end  
      
    -- 文字漸顯動畫  
    textLabel.TextTransparency = 1  
    game:GetService("TweenService"):Create(  
        textLabel,  
        TweenInfo.new(config.animationTime, config.animationStyle, config.animationDirection),  
        {TextTransparency = 0}  
    ):Play()  
      
    -- 新增後重新排序，依寬度從大到小排列  
    self:ReorderItems()  
      
    return itemId  
end  

-- 刪除項目：移除後呼叫重新排序  
function ArrayListUI:RemoveItem(itemId)  
    local itemIndex = nil  
    for i, item in ipairs(self.items) do  
        if item.id == itemId then  
            itemIndex = i  
            break  
        end  
    end  
      
    if itemIndex then  
        local item = self.items[itemIndex]  
          
        -- 淡出動畫  
        local fadeOutTween = game:GetService("TweenService"):Create(  
            item.text,  
            TweenInfo.new(config.animationTime, config.animationStyle, config.animationDirection),  
            {TextTransparency = 1}  
        )  
        fadeOutTween:Play()  
          
        -- 向右滑出移除  
        item.frame:TweenPosition(  
            UDim2.new(1, item.frame.Size.X.Offset, 0, item.frame.Position.Y.Offset),  
            config.animationDirection,  
            config.animationStyle,  
            config.animationTime,  
            true,  
            function()  
                item.frame:Destroy()  
            end  
        )  
          
        table.remove(self.items, itemIndex)  
        ArrayListItems[itemId] = nil  
          
        -- 刪除後重新排序  
        self:ReorderItems()  
        return true  
    end  
      
    return false  
end  

-- 切換項目的啟用狀態（動畫改變文字顏色及縮放效果）  
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

-- 清除所有項目（附帶滑出及淡出動畫）  
function ArrayListUI:ClearAll()  
    for i, item in ipairs(self.items) do  
        game:GetService("TweenService"):Create(  
            item.text,  
            TweenInfo.new(config.animationTime * 0.8, config.animationStyle, config.animationDirection),  
            {TextTransparency = 1}  
        ):Play()  
          
        local delay = math.min(i * 0.05, 0.5)  
        task.delay(delay, function()  
            item.frame:TweenPosition(  
                UDim2.new(1, item.frame.Size.X.Offset, 0, item.frame.Position.Y.Offset),  
                config.animationDirection,  
                config.animationStyle,  
                config.animationTime * 0.8,  
                true,  
                function()  
                    item.frame:Destroy()  
                end  
            )  
        end)  
    end  
      
    task.delay(config.animationTime + 0.5, function()  
        self.items = {}  
        ArrayListItems = {}  
        self.mainFrame.Size = UDim2.new(0, self.mainFrame.Size.X.Offset, 0, 0)  
    end)  
end  

-- 範例使用  
local function Example()  
    local arrayList = ArrayListUI:Init()  
      
    -- 新增一些範例項目，內容各不相同  
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
      
    -- 延遲後切換某項目的啟用狀態  
    task.delay(3, function()  
        arrayList:ToggleItem(3)  
    end)  
      
    -- 延遲後新增項目  
    task.delay(5, function()  
        arrayList:AddItem("NewItem", "Active", true)  
    end)  
      
    -- 延遲後刪除一個項目  
    task.delay(7, function()  
        arrayList:RemoveItem(4)  
    end)  
end  

-- 回傳 API  
local API = {  
    Init = function() return ArrayListUI:Init() end,  
    RunExample = Example  
}  

-- 若以 loadstring 載入，則自動執行範例  
if script and script.Name == "ArrayListLoader" then  
    Example()  
end  

return API
