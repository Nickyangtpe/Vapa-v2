-- ArrayList UI Library for Roblox
-- Positioned in top-right corner with vertical line design

local ArrayListUI = {}
local ArrayListItems = {}

-- Configuration
local config = {
    position = UDim2.new(1, -10, 0, 10), -- Top right corner
    textSize = 16,
    font = Enum.Font.SourceSansBold,
    activeColor = Color3.fromRGB(255, 85, 85), -- Red for active items
    inactiveColor = Color3.fromRGB(180, 180, 180), -- Gray for inactive items
    background = {
        transparency = 0.2,
        color = Color3.fromRGB(20, 20, 20)
    },
    verticalLine = {
        width = 2,
        color = Color3.fromRGB(255, 85, 85) -- Red vertical line
    },
    padding = 8, -- Horizontal padding
    animationTime = 0.5, -- Duration of animation
    animationStyle = Enum.EasingStyle.Quart, -- Enhanced animation style
    animationDirection = Enum.EasingDirection.Out
}

-- Create main UI container
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
    MainFrame.Size = UDim2.new(0, 200, 0, 0) -- Will auto-resize
    MainFrame.AnchorPoint = Vector2.new(1, 0) -- Anchor to top-right
    MainFrame.Parent = ScreenGui
    
    -- Create the vertical line on the right
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

-- Initialize the UI
function ArrayListUI:Init()
    self.mainFrame = createMainFrame()
    self.items = {}
    return self
end

-- Calculate text width
local function getTextWidth(text, textSize, font)
    return game:GetService("TextService"):GetTextSize(
        text or "", 
        textSize, 
        font, 
        Vector2.new(1000, 100)
    ).X
end

-- Sort items by total length (longest to shortest)
function ArrayListUI:SortItems()
    -- Sort items by total length (longest to shortest)
    table.sort(self.items, function(a, b)
        local aText = a.name.Text .. (a.valueText or "")
        local bText = b.name.Text .. (b.valueText or "")
        return getTextWidth(aText, config.textSize, config.font) > 
               getTextWidth(bText, config.textSize, config.font)
    end)
    
    -- Update positions with animation
    for i, item in ipairs(self.items) do
        item.frame:TweenPosition(
            UDim2.new(0, 0, 0, self:GetItemPosition(i)),
            config.animationDirection,
            config.animationStyle,
            config.animationTime,
            true
        )
    end
end

-- Add a new item to the ArrayList with animation
function ArrayListUI:AddItem(name, value, isActive)
    local itemColor = isActive and config.activeColor or config.inactiveColor
    local itemId = #self.items + 1
    
    -- Create item container
    local itemFrame = Instance.new("Frame")
    itemFrame.Name = "Item_" .. itemId
    itemFrame.BackgroundTransparency = 1
    itemFrame.Size = UDim2.new(1, 0, 0, config.textSize + 4) -- Height based on text size
    itemFrame.Position = UDim2.new(1, 0, 0, self:GetTotalHeight()) -- Start from right (for animation)
    itemFrame.Parent = self.mainFrame
    
    -- Create name label (right-aligned)
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "Name"
    nameLabel.BackgroundTransparency = 1
    nameLabel.Size = UDim2.new(0.6, 0, 1, 0)
    nameLabel.Position = UDim2.new(0.4, -config.padding, 0, 0)
    nameLabel.Font = config.font
    nameLabel.TextSize = config.textSize
    nameLabel.TextColor3 = itemColor
    nameLabel.Text = name
    nameLabel.TextXAlignment = Enum.TextXAlignment.Right -- Right-aligned text
    nameLabel.Parent = itemFrame
    
    -- Create value label (right-aligned)
    local valueLabel = Instance.new("TextLabel")
    valueLabel.Name = "Value"
    valueLabel.BackgroundTransparency = 1
    valueLabel.Size = UDim2.new(0.4, -config.padding - config.verticalLine.width, 1, 0)
    valueLabel.Position = UDim2.new(0.6, 0, 0, 0)
    valueLabel.Font = config.font
    valueLabel.TextSize = config.textSize
    valueLabel.TextColor3 = Color3.fromRGB(120, 120, 120) -- Darker for the value
    valueLabel.Text = value or ""
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right -- Right-aligned text
    valueLabel.Parent = itemFrame
    
    -- Calculate width based on text
    local nameWidth = getTextWidth(name, config.textSize, config.font)
    local valueWidth = getTextWidth(value, config.textSize, config.font)
    
    local targetWidth = nameWidth + valueWidth + (config.padding * 3) + config.verticalLine.width
    
    -- Update main frame width if needed
    if targetWidth > self.mainFrame.Size.X.Offset then
        self.mainFrame.Size = UDim2.new(0, targetWidth, self.mainFrame.Size.Y)
    end
    
    -- Store item data
    local itemData = {
        id = itemId,
        frame = itemFrame,
        name = nameLabel,
        value = valueLabel,
        valueText = value,
        isActive = isActive
    }
    
    table.insert(self.items, itemData)
    ArrayListItems[itemId] = itemData
    
    -- Update vertical line and frame height
    self:UpdateFrameHeight()
    
    -- Enhanced animation: slide in from right and fade in
    itemFrame.Position = UDim2.new(1, 0, 0, self:GetItemPosition(itemId))
    itemFrame.BackgroundTransparency = 1
    nameLabel.TextTransparency = 1
    valueLabel.TextTransparency = 1
    
    -- Sort items by length (longest to shortest)
    self:SortItems()
    
    -- Slide animation
    itemFrame:TweenPosition(
        UDim2.new(0, 0, 0, self:GetItemPosition(self:GetItemIndex(itemId))), 
        config.animationDirection, 
        config.animationStyle, 
        config.animationTime, 
        true
    )
    
    -- Fade in animation
    game:GetService("TweenService"):Create(
        nameLabel, 
        TweenInfo.new(config.animationTime, config.animationStyle, config.animationDirection), 
        {TextTransparency = 0}
    ):Play()
    
    game:GetService("TweenService"):Create(
        valueLabel, 
        TweenInfo.new(config.animationTime, config.animationStyle, config.animationDirection), 
        {TextTransparency = 0}
    ):Play()
    
    return itemId
end

-- Get item index by id
function ArrayListUI:GetItemIndex(itemId)
    for i, item in ipairs(self.items) do
        if item.id == itemId then
            return i
        end
    end
    return nil
end

-- Remove an item with animation
function ArrayListUI:RemoveItem(itemId)
    local itemIndex = self:GetItemIndex(itemId)
    
    if itemIndex then
        local item = self.items[itemIndex]
        
        -- Enhanced removal animation: fade out and slide right
        local fadeOutTweenName = game:GetService("TweenService"):Create(
            item.name, 
            TweenInfo.new(config.animationTime, config.animationStyle, config.animationDirection), 
            {TextTransparency = 1}
        )
        
        local fadeOutTweenValue = game:GetService("TweenService"):Create(
            item.value, 
            TweenInfo.new(config.animationTime, config.animationStyle, config.animationDirection), 
            {TextTransparency = 1}
        )
        
        fadeOutTweenName:Play()
        fadeOutTweenValue:Play()
        
        -- Slide out animation
        item.frame:TweenPosition(
            UDim2.new(1, 0, 0, item.frame.Position.Y.Offset), 
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
        
        -- Sort and reposition all items
        self:SortItems()
        
        -- Update frame height
        self:UpdateFrameHeight()
        return true
    end
    
    return false
end

-- Toggle item active state with animation
function ArrayListUI:ToggleItem(itemId)
    local itemIndex = self:GetItemIndex(itemId)
    
    if itemIndex then
        local item = self.items[itemIndex]
        item.isActive = not item.isActive
        local targetColor = item.isActive and config.activeColor or config.inactiveColor
        
        -- Color change animation
        game:GetService("TweenService"):Create(
            item.name, 
            TweenInfo.new(config.animationTime, config.animationStyle, config.animationDirection), 
            {TextColor3 = targetColor}
        ):Play()
        
        -- Scale animation for emphasis
        local originalSize = item.name.Size
        item.name.Size = UDim2.new(originalSize.X.Scale, originalSize.X.Offset, originalSize.Y.Scale, originalSize.Y.Offset * 1.2)
        game:GetService("TweenService"):Create(
            item.name, 
            TweenInfo.new(config.animationTime, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out), 
            {Size = originalSize}
        ):Play()
        
        return true
    end
    
    return false
end

-- Get the total height of all items
function ArrayListUI:GetTotalHeight()
    local height = 0
    for _, item in ipairs(self.items) do
        height = height + item.frame.Size.Y.Offset
    end
    return height
end

-- Update main frame height
function ArrayListUI:UpdateFrameHeight()
    local totalHeight = self:GetTotalHeight()
    
    -- Animate height change
    game:GetService("TweenService"):Create(
        self.mainFrame, 
        TweenInfo.new(config.animationTime, config.animationStyle, config.animationDirection), 
        {Size = UDim2.new(0, self.mainFrame.Size.X.Offset, 0, totalHeight)}
    ):Play()
    
    -- Update vertical line height
    local verticalLine = self.mainFrame:FindFirstChild("VerticalLine")
    if verticalLine then
        verticalLine.Size = UDim2.new(0, config.verticalLine.width, 1, 0)
    end
end

-- Get position for item at index
function ArrayListUI:GetItemPosition(index)
    local position = 0
    for i = 1, index - 1 do
        position = position + self.items[i].frame.Size.Y.Offset
    end
    return position
end

-- Change the configuration
function ArrayListUI:UpdateConfig(newConfig)
    for key, value in pairs(newConfig) do
        if type(value) == "table" then
            for subKey, subValue in pairs(value) do
                config[key][subKey] = subValue
            end
        else
            config[key] = value
        end
    end
    
    -- Update vertical line
    local verticalLine = self.mainFrame:FindFirstChild("VerticalLine")
    if verticalLine then
        verticalLine.BackgroundColor3 = config.verticalLine.color
        verticalLine.Size = UDim2.new(0, config.verticalLine.width, 1, 0)
    end
    
    -- Update main frame with animation
    game:GetService("TweenService"):Create(
        self.mainFrame, 
        TweenInfo.new(config.animationTime, config.animationStyle, config.animationDirection), 
        {
            BackgroundColor3 = config.background.color,
            BackgroundTransparency = config.background.transparency,
            Position = config.position
        }
    ):Play()
    
    -- Update all items
    for _, item in ipairs(self.items) do
        item.name.Font = config.font
        item.name.TextSize = config.textSize
        item.name.TextColor3 = item.isActive and config.activeColor or config.inactiveColor
        
        item.value.Font = config.font
        item.value.TextSize = config.textSize
        
        -- Animate text properties
        game:GetService("TweenService"):Create(
            item.name, 
            TweenInfo.new(config.animationTime, config.animationStyle, config.animationDirection), 
            {
                TextColor3 = item.isActive and config.activeColor or config.inactiveColor,
                Size = UDim2.new(0.6, 0, 1, 0),
                Position = UDim2.new(0.4, -config.padding, 0, 0)
            }
        ):Play()
        
        game:GetService("TweenService"):Create(
            item.value, 
            TweenInfo.new(config.animationTime, config.animationStyle, config.animationDirection), 
            {
                Size = UDim2.new(0.4, -config.padding - config.verticalLine.width, 1, 0),
                Position = UDim2.new(0.6, 0, 0, 0)
            }
        ):Play()
        
        item.frame.Size = UDim2.new(1, 0, 0, config.textSize + 4)
    end
    
    -- Sort and reposition items
    self:SortItems()
    
    -- Update frame height
    self:UpdateFrameHeight()
end

-- Clear all items with animation
function ArrayListUI:ClearAll()
    -- Animate all items sliding out
    for i, item in ipairs(self.items) do
        -- Fade out
        game:GetService("TweenService"):Create(
            item.name, 
            TweenInfo.new(config.animationTime * 0.8, config.animationStyle, config.animationDirection), 
            {TextTransparency = 1}
        ):Play()
        
        game:GetService("TweenService"):Create(
            item.value, 
            TweenInfo.new(config.animationTime * 0.8, config.animationStyle, config.animationDirection), 
            {TextTransparency = 1}
        ):Play()
        
        -- Slide out with delay based on position
        local delay = i * 0.05
        delay = math.min(delay, 0.5) -- Cap the delay
        
        task.delay(delay, function()
            item.frame:TweenPosition(
                UDim2.new(1, 0, 0, item.frame.Position.Y.Offset),
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
    
    -- Clear arrays after animations
    task.delay(config.animationTime + 0.5, function()
        self.items = {}
        ArrayListItems = {}
        self.mainFrame.Size = UDim2.new(0, self.mainFrame.Size.X.Offset, 0, 0)
    end)
end

-- Example usage
local function Example()
    local arrayList = ArrayListUI:Init()
    
    -- Add some example items with active/inactive states
    arrayList:AddItem("FakeLag", "Dynamic", true)
    arrayList:AddItem("NoItemRelease", nil, true) -- Example with no value
    arrayList:AddItem("Velocity", "Normal", false)
    arrayList:AddItem("Trajectories", nil, true)
    arrayList:AddItem("AutoClicker", nil, true)
    arrayList:AddItem("SilentAura", nil, true)
    arrayList:AddItem("Indicators", nil, true)
    arrayList:AddItem("AntiBot", nil, true)
    arrayList:AddItem("Reach", nil, true)
    arrayList:AddItem("Sprint", nil, true)
    arrayList:AddItem("ESP", nil, true)
    
    -- Toggle some items after delay
    task.delay(3, function()
        arrayList:ToggleItem(3) -- Toggle Velocity after 3 seconds
    end)
    
    -- Update a value after delay
    task.delay(5, function()
        arrayList:AddItem("NewItem", "Active", true) -- Add new item after 5 seconds
    end)
    
    -- Remove an item after delay
    task.delay(7, function()
        arrayList:RemoveItem(4) -- Remove an item after 7 seconds
    end)
end

-- Return the API
local API = {
    Init = function() return ArrayListUI:Init() end,
    RunExample = Example
}

-- Auto-run example if loaded with loadstring
if script and script.Name == "ArrayListLoader" then
    Example()
end

return API
