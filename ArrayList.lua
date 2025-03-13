local ArrayListUI = {}
ArrayListUI.__index = ArrayListUI

-- Configuration
local CONFIG = {
    BACKGROUND_COLOR = Color3.fromRGB(20, 20, 20),
    TEXT_COLOR = Color3.fromRGB(255, 50, 50),
    SECONDARY_TEXT_COLOR = Color3.fromRGB(200, 200, 200),
    BORDER_COLOR = Color3.fromRGB(255, 50, 50),
    FONT = Enum.Font.SourceSansBold,
    TEXT_SIZE = 16,
    PADDING = 8,
    CORNER_RADIUS = 0,
    ANIMATION_SPEED = 0.3,
    POSITION = UDim2.new(1, -10, 0, 10), -- Right top corner
}

-- Create a new ArrayList UI
function ArrayListUI.new()
    local self = setmetatable({}, ArrayListUI)
    
    -- Create main frame
    self.gui = Instance.new("ScreenGui")
    self.gui.Name = "ArrayListUI"
    self.gui.ResetOnSpawn = false
    self.gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    -- Container for all items
    self.container = Instance.new("Frame")
    self.container.Name = "Container"
    self.container.BackgroundTransparency = 1
    self.container.Size = UDim2.new(0, 200, 0, 500)
    self.container.Position = CONFIG.POSITION
    self.container.AnchorPoint = Vector2.new(1, 0) -- Anchor to right
    self.container.Parent = self.gui
    
    -- List of all items
    self.items = {}
    
    -- Parent to PlayerGui
    if game:GetService("RunService"):IsStudio() then
        self.gui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
    else
        self.gui.Parent = game:GetService("CoreGui")
    end
    
    return self
end

-- Add a new item to the ArrayList
function ArrayListUI:AddItem(name, value)
    -- Create item frame
    local item = Instance.new("Frame")
    item.Name = name
    item.BackgroundColor3 = CONFIG.BACKGROUND_COLOR
    item.BorderSizePixel = 0
    item.AutomaticSize = Enum.AutomaticSize.X
    item.Size = UDim2.new(0, 0, 0, CONFIG.TEXT_SIZE + CONFIG.PADDING * 2)
    item.Position = UDim2.new(1, 200, 0, 0) -- Start off-screen for animation
    item.AnchorPoint = Vector2.new(1, 0)
    item.Parent = self.container
    
    -- Add corner radius
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, CONFIG.CORNER_RADIUS)
    corner.Parent = item
    
    -- Add right border
    local border = Instance.new("Frame")
    border.Name = "Border"
    border.BackgroundColor3 = CONFIG.BORDER_COLOR
    border.BorderSizePixel = 0
    border.Size = UDim2.new(0, 2, 1, 0)
    border.Position = UDim2.new(1, 0, 0, 0)
    border.AnchorPoint = Vector2.new(0, 0)
    border.ZIndex = 2
    border.Parent = item
    
    -- Create text label for name
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "NameLabel"
    nameLabel.BackgroundTransparency = 1
    nameLabel.Size = UDim2.new(0, 0, 1, 0)
    nameLabel.AutomaticSize = Enum.AutomaticSize.X
    nameLabel.Position = UDim2.new(0, CONFIG.PADDING, 0, 0)
    nameLabel.Font = CONFIG.FONT
    nameLabel.TextSize = CONFIG.TEXT_SIZE
    nameLabel.TextColor3 = CONFIG.TEXT_COLOR
    nameLabel.Text = name
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Parent = item
    
    -- Create text label for value (if provided)
    local valueLabel = nil
    if value then
        valueLabel = Instance.new("TextLabel")
        valueLabel.Name = "ValueLabel"
        valueLabel.BackgroundTransparency = 1
        valueLabel.Size = UDim2.new(0, 0, 1, 0)
        valueLabel.AutomaticSize = Enum.AutomaticSize.X
        valueLabel.Position = UDim2.new(0, nameLabel.TextBounds.X + CONFIG.PADDING * 2, 0, 0)
        valueLabel.Font = CONFIG.FONT
        valueLabel.TextSize = CONFIG.TEXT_SIZE
        valueLabel.TextColor3 = CONFIG.SECONDARY_TEXT_COLOR
        valueLabel.Text = value
        valueLabel.TextXAlignment = Enum.TextXAlignment.Left
        valueLabel.Parent = item
    end
    
    -- Add to items table
    table.insert(self.items, {
        name = name,
        frame = item,
        nameLabel = nameLabel,
        valueLabel = valueLabel
    })
    
    -- Sort and update positions
    self:SortItems()
    self:UpdatePositions()
    
    -- Animate in
    self:AnimateItem(item, true)
    
    return item
end

-- Remove an item from the ArrayList
function ArrayListUI:RemoveItem(name)
    for i, item in ipairs(self.items) do
        if item.name == name then
            -- Animate out
            self:AnimateItem(item.frame, false, function()
                -- Remove from items table
                table.remove(self.items, i)
                -- Destroy frame
                item.frame:Destroy()
                -- Update positions
                self:UpdatePositions()
            end)
            break
        end
    end
end

-- Update an item's value
function ArrayListUI:UpdateItem(name, value)
    for _, item in ipairs(self.items) do
        if item.name == name then
            if value then
                if item.valueLabel then
                    item.valueLabel.Text = value
                else
                    -- Create value label if it doesn't exist
                    local valueLabel = Instance.new("TextLabel")
                    valueLabel.Name = "ValueLabel"
                    valueLabel.BackgroundTransparency = 1
                    valueLabel.Size = UDim2.new(0, 0, 1, 0)
                    valueLabel.AutomaticSize = Enum.AutomaticSize.X
                    valueLabel.Position = UDim2.new(0, item.nameLabel.TextBounds.X + CONFIG.PADDING * 2, 0, 0)
                    valueLabel.Font = CONFIG.FONT
                    valueLabel.TextSize = CONFIG.TEXT_SIZE
                    valueLabel.TextColor3 = CONFIG.SECONDARY_TEXT_COLOR
                    valueLabel.Text = value
                    valueLabel.TextXAlignment = Enum.TextXAlignment.Left
                    valueLabel.Parent = item.frame
                    
                    item.valueLabel = valueLabel
                end
            elseif item.valueLabel then
                -- Remove value label if value is nil
                item.valueLabel:Destroy()
                item.valueLabel = nil
            end
            
            -- Sort and update positions after changing text
            self:SortItems()
            self:UpdatePositions()
            break
        end
    end
end

-- Sort items by text length (longest to shortest)
function ArrayListUI:SortItems()
    table.sort(self.items, function(a, b)
        local aLength = a.nameLabel.TextBounds.X
        if a.valueLabel then
            aLength = aLength + a.valueLabel.TextBounds.X + CONFIG.PADDING
        end
        
        local bLength = b.nameLabel.TextBounds.X
        if b.valueLabel then
            bLength = bLength + b.valueLabel.TextBounds.X + CONFIG.PADDING
        end
        
        -- Changed from < to > to sort from longest to shortest
        return aLength > bLength
    end)
end

-- Update positions of all items
function ArrayListUI:UpdatePositions()
    local yOffset = 0
    
    for _, item in ipairs(self.items) do
        -- Tween to new position
        game:GetService("TweenService"):Create(
            item.frame,
            TweenInfo.new(CONFIG.ANIMATION_SPEED, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
            {Position = UDim2.new(1, 0, 0, yOffset)}
        ):Play()
        
        -- No gap between items (removed +2)
        yOffset = yOffset + item.frame.Size.Y.Offset
    end
end

-- Animate item in or out
function ArrayListUI:AnimateItem(item, isIn, callback)
    local targetX = isIn and 0 or 200
    
    local tween = game:GetService("TweenService"):Create(
        item,
        TweenInfo.new(CONFIG.ANIMATION_SPEED, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
        {Position = UDim2.new(1, targetX, item.Position.Y.Scale, item.Position.Y.Offset)}
    )
    
    if callback then
        tween.Completed:Connect(callback)
    end
    
    tween:Play()
end

-- Clear all items
function ArrayListUI:Clear()
    for i = #self.items, 1, -1 do
        local item = self.items[i]
        item.frame:Destroy()
    end
    
    self.items = {}
end

-- Destroy the UI
function ArrayListUI:Destroy()
    self.gui:Destroy()
end

return ArrayListUI
