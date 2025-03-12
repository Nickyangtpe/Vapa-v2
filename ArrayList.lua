-- ArrayList UI Library for Roblox
-- Customizable, Dynamic UI Library with Animation

local ArrayList = {}
ArrayList.__index = ArrayList

-- Services
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

-- Constants
local SCREEN_GUI_NAME = "ArrayListGui"
local DEFAULT_COLOR = Color3.fromRGB(255, 60, 60) -- Default red color similar to the image
local GRAY_COLOR = Color3.fromRGB(200, 200, 200)
local BACKGROUND_COLOR = Color3.fromRGB(30, 30, 30)
local BACKGROUND_TRANSPARENCY = 0.3
local TEXT_SIZE = 18
local PADDING = 4
local ANIMATION_TIME = 0.3
local LINE_THICKNESS = 2

-- Initialize the ArrayList
function ArrayList.new(theme)
    local self = setmetatable({}, ArrayList)
    
    self.items = {}
    self.theme = theme or "Red" -- Default theme
    self.mainColor = DEFAULT_COLOR
    
    -- Set theme color
    if theme == "Blue" then
        self.mainColor = Color3.fromRGB(50, 100, 255)
    elseif theme == "Green" then
        self.mainColor = Color3.fromRGB(50, 255, 100)
    elseif theme == "Purple" then
        self.mainColor = Color3.fromRGB(150, 50, 255)
    end
    
    -- Create ScreenGui
    self.screenGui = Instance.new("ScreenGui")
    self.screenGui.Name = SCREEN_GUI_NAME
    self.screenGui.ResetOnSpawn = false
    self.screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    -- Create main frame container
    self.container = Instance.new("Frame")
    self.container.Name = "ArrayListContainer"
    self.container.BackgroundTransparency = 1
    self.container.Size = UDim2.new(0, 200, 0, 500)
    self.container.Position = UDim2.new(1, -210, 0, 10)
    self.container.AnchorPoint = Vector2.new(0, 0)
    self.container.Parent = self.screenGui
    
    -- Create accent line (vertical line on the right)
    self.accentLine = Instance.new("Frame")
    self.accentLine.Name = "AccentLine"
    self.accentLine.BackgroundColor3 = self.mainColor
    self.accentLine.BorderSizePixel = 0
    self.accentLine.Position = UDim2.new(1, 0, 0, 0) 
    self.accentLine.Size = UDim2.new(0, LINE_THICKNESS, 1, 0)
    self.accentLine.AnchorPoint = Vector2.new(0, 0)
    self.accentLine.Parent = self.container
    
    -- Parent the ScreenGui to the correct location
    if game:GetService("RunService"):IsStudio() then
        self.screenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
    else
        self.screenGui.Parent = game:GetService("CoreGui")
    end
    
    return self
end

-- Add new item to the ArrayList
function ArrayList:AddItem(name, state, customColor)
    -- Check if item already exists
    for _, item in ipairs(self.items) do
        if item.name == name then
            return item -- Return existing item
        end
    end
    
    -- Create item frame
    local itemFrame = Instance.new("Frame")
    itemFrame.Name = name .. "Frame"
    itemFrame.BackgroundColor3 = BACKGROUND_COLOR
    itemFrame.BackgroundTransparency = BACKGROUND_TRANSPARENCY
    itemFrame.BorderSizePixel = 0
    itemFrame.Size = UDim2.new(1, -LINE_THICKNESS, 0, TEXT_SIZE + PADDING * 2)
    itemFrame.Position = UDim2.new(0, 0, 0, 0) -- Will be updated in UpdatePositions
    itemFrame.Parent = self.container
    
    -- Create item name text
    local nameText = Instance.new("TextLabel")
    nameText.Name = "NameText"
    nameText.Text = name
    nameText.Font = Enum.Font.SourceSansBold
    nameText.TextSize = TEXT_SIZE
    nameText.TextColor3 = customColor or self.mainColor
    nameText.BackgroundTransparency = 1
    nameText.Size = UDim2.new(0.7, 0, 1, 0)
    nameText.Position = UDim2.new(0, PADDING, 0, 0)
    nameText.TextXAlignment = Enum.TextXAlignment.Left
    nameText.Parent = itemFrame
    
    -- Create state text
    local stateText = Instance.new("TextLabel")
    stateText.Name = "StateText"
    stateText.Text = state or ""
    stateText.Font = Enum.Font.SourceSans
    stateText.TextSize = TEXT_SIZE
    stateText.TextColor3 = GRAY_COLOR
    stateText.BackgroundTransparency = 1
    stateText.Size = UDim2.new(0.3, -PADDING, 1, 0)
    stateText.Position = UDim2.new(0.7, 0, 0, 0)
    stateText.TextXAlignment = Enum.TextXAlignment.Right
    stateText.Parent = itemFrame
    
    -- Apply initial transparency for animation
    itemFrame.BackgroundTransparency = 1
    nameText.TextTransparency = 1
    stateText.TextTransparency = 1
    
    -- Create item data
    local item = {
        name = name,
        state = state or "",
        frame = itemFrame,
        nameLabel = nameText,
        stateLabel = stateText,
        active = true,
        color = customColor or self.mainColor
    }
    
    -- Add to items list
    table.insert(self.items, item)
    
    -- Sort and update positions
    self:SortItems()
    self:UpdatePositions()
    
    -- Animate in
    self:AnimateItemIn(item)
    
    return item
end

-- Update an existing item
function ArrayList:UpdateItem(name, newState, newColor)
    for _, item in ipairs(self.items) do
        if item.name == name then
            -- Update state if provided
            if newState ~= nil then
                item.state = newState
                item.stateLabel.Text = newState
            end
            
            -- Update color if provided
            if newColor then
                item.color = newColor
                item.nameLabel.TextColor3 = newColor
            end
            
            -- Resort and update positions
            self:SortItems()
            self:UpdatePositions()
            
            return item
        end
    end
    
    -- If item doesn't exist, create it
    return self:AddItem(name, newState, newColor)
end

-- Remove an item from the ArrayList
function ArrayList:RemoveItem(name)
    for i, item in ipairs(self.items) do
        if item.name == name then
            -- Animate out
            self:AnimateItemOut(item, function()
                -- Remove from items list
                table.remove(self.items, i)
                -- Update positions
                self:UpdatePositions()
            end)
            return true
        end
    end
    return false
end

-- Sort items alphabetically
function ArrayList:SortItems()
    table.sort(self.items, function(a, b)
        return a.name < b.name
    end)
end

-- Update positions of all items
function ArrayList:UpdatePositions()
    local yOffset = 0
    
    for i, item in ipairs(self.items) do
        if item.active then
            -- Create tween to move item to new position
            local newPosition = UDim2.new(0, 0, 0, yOffset)
            
            if item.frame.Position ~= newPosition then
                local tween = TweenService:Create(
                    item.frame,
                    TweenInfo.new(ANIMATION_TIME, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
                    {Position = newPosition}
                )
                tween:Play()
            else
                item.frame.Position = newPosition
            end
            
            yOffset = yOffset + item.frame.Size.Y.Offset
        end
    end
    
    -- Update container size
    self.container.Size = UDim2.new(0, 200, 0, math.max(10, yOffset))
end

-- Animation for new items
function ArrayList:AnimateItemIn(item)
    item.frame.BackgroundTransparency = 1
    item.nameLabel.TextTransparency = 1
    item.stateLabel.TextTransparency = 1
    
    local tweenInfo = TweenInfo.new(ANIMATION_TIME, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    
    -- Background fade in
    local bgTween = TweenService:Create(
        item.frame,
        tweenInfo,
        {BackgroundTransparency = BACKGROUND_TRANSPARENCY}
    )
    
    -- Text fade in
    local nameTween = TweenService:Create(
        item.nameLabel,
        tweenInfo,
        {TextTransparency = 0}
    )
    
    local stateTween = TweenService:Create(
        item.stateLabel,
        tweenInfo,
        {TextTransparency = 0}
    )
    
    bgTween:Play()
    nameTween:Play()
    stateTween:Play()
end

-- Animation for removing items
function ArrayList:AnimateItemOut(item, callback)
    local tweenInfo = TweenInfo.new(ANIMATION_TIME, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
    
    -- Background fade out
    local bgTween = TweenService:Create(
        item.frame,
        tweenInfo,
        {BackgroundTransparency = 1}
    )
    
    -- Text fade out
    local nameTween = TweenService:Create(
        item.nameLabel,
        tweenInfo,
        {TextTransparency = 1}
    )
    
    local stateTween = TweenService:Create(
        item.stateLabel,
        tweenInfo,
        {TextTransparency = 1}
    )
    
    -- Connect to the Completed event of the last tween
    stateTween.Completed:Connect(function()
        item.frame:Destroy()
        if callback then callback() end
    end)
    
    bgTween:Play()
    nameTween:Play()
    stateTween:Play()
end

-- Change theme color
function ArrayList:SetTheme(color)
    self.mainColor = color
    self.accentLine.BackgroundColor3 = color
    
    -- Update all item colors if they are using the default color
    for _, item in ipairs(self.items) do
        if item.color == self.mainColor then
            item.nameLabel.TextColor3 = color
            item.color = color
        end
    end
end

-- Toggle visibility
function ArrayList:SetVisible(visible)
    self.container.Visible = visible
end

-- Destroy the ArrayList
function ArrayList:Destroy()
    self.screenGui:Destroy()
end

return ArrayList
