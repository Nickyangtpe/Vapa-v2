-- ArrayList UI Library for Roblox
-- Positioned in top-right corner with vertical line design
-- Each item has its own width based on content

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
    MainFrame.BackgroundTransparency = 1 -- Transparent main container
    MainFrame.BorderSizePixel = 0
    MainFrame.Position = config.position
    MainFrame.Size = UDim2.new(0, 0, 0, 0) -- Will auto-resize
    MainFrame.AnchorPoint = Vector2.new(1, 0) -- Anchor to top-right
    MainFrame.Parent = ScreenGui
    
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
        text, 
        textSize, 
        font, 
        Vector2.new(1000, 100)
    ).X
end

-- Add a new item to the ArrayList with animation
function ArrayListUI:AddItem(name, value, isActive)
    local itemColor = isActive and config.activeColor or config.inactiveColor
    local itemId = #self.items + 1
    local displayText = value and (name .. " " .. value) or name
    
    -- Calculate width based on text
    local textWidth = getTextWidth(displayText, config.textSize, config.font)
    local itemWidth = textWidth + (config.padding * 2) + config.verticalLine.width
    
    -- Create item container with its own background
    local itemFrame = Instance.new("Frame")
    itemFrame.Name = "Item_" .. itemId
    itemFrame.BackgroundColor3 = config.background.color
    itemFrame.BackgroundTransparency = config.background.transparency
    itemFrame.BorderSizePixel = 0
    itemFrame.Size = UDim2.new(0, itemWidth, 0, config.textSize + 4) -- Height based on text size, width based on content
    itemFrame.Position = UDim2.new(1, 0, 0, self:GetItemPosition(itemId)) -- Start from right (for animation)
    itemFrame.AnchorPoint = Vector2.new(1, 0) -- Anchor to right
    itemFrame.Parent = self.mainFrame
    
    -- Create text label for the item (right-aligned)
    local textLabel = Instance.new("TextLabel")
    textLabel.Name = "Text"
    textLabel.BackgroundTransparency = 1
    textLabel.Size = UDim2.new(1, -config.padding * 2 - config.verticalLine.width, 1, 0)
    textLabel.Position = UDim2.new(0, config.padding, 0, 0)
    textLabel.Font = config.font
    textLabel.TextSize = config.textSize
    textLabel.TextColor3 = itemColor
    textLabel.Text = displayText
    textLabel.TextXAlignment = Enum.TextXAlignment.Right -- Right-aligned text
    textLabel.Parent = itemFrame
    
    -- Create the vertical line on the right of each item
    local verticalLine = Instance.new("Frame")
    verticalLine.Name = "VerticalLine"
    verticalLine.BackgroundColor3 = config.verticalLine.color
    verticalLine.BorderSizePixel = 0
    verticalLine.Position = UDim2.new(1, 0, 0, 0) 
    verticalLine.Size = UDim2.new(0, config.verticalLine.width, 1, 0)
    verticalLine.AnchorPoint = Vector2.new(0, 0)
    verticalLine.ZIndex = 2
    verticalLine.Parent = itemFrame
    
    -- Store item data
    local itemData = {
        id = itemId,
        frame = itemFrame,
        text = textLabel,
        line = verticalLine,
        valueText = value,
        isActive = isActive,
        width = itemWidth
    }
    
    table.insert(self.items, itemData)
    ArrayListItems[itemId] = itemData
    
    -- Update frame height
    self:UpdateFrameHeight()
    
    -- Enhanced animation: slide in from right and fade in
    itemFrame.Position = UDim2.new(1, 0, 0, self:GetItemPosition(itemId))
    textLabel.TextTransparency = 1
    
    -- Slide animation
    itemFrame:TweenPosition(
        UDim2.new(1, -itemWidth, 0, self:GetItemPosition(itemId)), 
        config.animationDirection, 
        config.animationStyle, 
        config.animationTime, 
        true
    )
    
    -- Fade in animation
    game:GetService("TweenService"):Create(
        textLabel, 
        TweenInfo.new(config.animationTime, config.animationStyle, config.animationDirection), 
        {TextTransparency = 0}
    ):Play()
    
    return itemId
end

-- Remove an item with animation
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
        
        -- Enhanced removal animation: fade out and slide right
        local fadeOutTween = game:GetService("TweenService"):Create(
            item.text, 
            TweenInfo.new(config.animationTime, config.animationStyle, config.animationDirection), 
            {TextTransparency = 1}
        )
        
        fadeOutTween:Play()
        
        -- Slide out animation to the right
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
        
        -- Reposition all items after the removed one with animation
        for i = itemIndex, #self.items do
            local currentItem = self.items[i]
            currentItem.frame:TweenPosition(
                UDim2.new(1, -currentItem.width, 0, self:GetItemPosition(i)),
                config.animationDirection,
                config.animationStyle,
                config.animationTime,
                true
            )
        end
        
        -- Update frame height
        self:UpdateFrameHeight()
        return true
    end
    
    return false
end

-- Toggle item active state with animation
function ArrayListUI:ToggleItem(itemId)
    for _, item in ipairs(self.items) do
        if item.id == itemId then
            item.isActive = not item.isActive
            local targetColor = item.isActive and config.activeColor or config.inactiveColor
            
            -- Color change animation
            game:GetService("TweenService"):Create(
                item.text, 
                TweenInfo.new(config.animationTime, config.animationStyle, config.animationDirection), 
                {TextColor3 = targetColor}
            ):Play()
            
            -- Scale animation for emphasis
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
    
    -- Update main frame size
    self.mainFrame.Size = UDim2.new(0, 0, 0, totalHeight)
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
    
    -- Update all items
    for i, item in ipairs(self.items) do
        -- Update vertical line
        item.line.BackgroundColor3 = config.verticalLine.color
        item.line.Size = UDim2.new(0, config.verticalLine.width, 1, 0)
        
        -- Update background
        item.frame.BackgroundColor3 = config.background.color
        item.frame.BackgroundTransparency = config.background.transparency
        
        -- Recalculate width based on text
        local displayText = item.valueText and (item.text.Text) or item.text.Text
        local textWidth = getTextWidth(displayText, config.textSize, config.font)
        local itemWidth = textWidth + (config.padding * 2) + config.verticalLine.width
        item.width = itemWidth
        
        -- Update text properties
        item.text.Font = config.font
        item.text.TextSize = config.textSize
        item.text.TextColor3 = item.isActive and config.activeColor or config.inactiveColor
        
        -- Animate text properties
        game:GetService("TweenService"):Create(
            item.text, 
            TweenInfo.new(config.animationTime, config.animationStyle, config.animationDirection), 
            {
                TextColor3 = item.isActive and config.activeColor or config.inactiveColor,
                Size = UDim2.new(1, -config.padding * 2 - config.verticalLine.width, 1, 0)
            }
        ):Play()
        
        -- Update frame size
        game:GetService("TweenService"):Create(
            item.frame, 
            TweenInfo.new(config.animationTime, config.animationStyle, config.animationDirection), 
            {Size = UDim2.new(0, itemWidth, 0, config.textSize + 4)}
        ):Play()
        
        -- Reposition item
        item.frame:TweenPosition(
            UDim2.new(1, -itemWidth, 0, self:GetItemPosition(i)),
            config.animationDirection,
            config.animationStyle,
            config.animationTime,
            true
        )
    end
    
    -- Update main frame position
    self.mainFrame:TweenPosition(
        config.position,
        config.animationDirection,
        config.animationStyle,
        config.animationTime,
        true
    )
    
    -- Update frame height
    self:UpdateFrameHeight()
end

-- Clear all items with animation
function ArrayListUI:ClearAll()
    -- Animate all items sliding out to the right
    for i, item in ipairs(self.items) do
        -- Fade out
        game:GetService("TweenService"):Create(
            item.text, 
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
        self.mainFrame.Size = UDim2.new(0, 0, 0, 0)
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
