local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local ArrayList = {}
ArrayList.__index = ArrayList

function ArrayList.new(parent)
    local self = setmetatable({}, ArrayList)
    
    -- Main frame
    self.frame = Instance.new("Frame")
    self.frame.Name = "ArrayList"
    self.frame.Size = UDim2.new(0, 200, 0, 0) -- Height will be determined by content
    self.frame.Position = UDim2.new(1, 0, 0, 20) -- Start off-screen to the right
    self.frame.BackgroundTransparency = 1
    self.frame.Parent = parent or game.Players.LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("ScreenGui")
    
    -- List of items
    self.items = {}
    self.visible = false
    
    -- Show the list initially
    self:show()
    
    return self
end

function ArrayList:addItem(text, color)
    -- Create item frame
    local item = Instance.new("Frame")
    item.Name = text
    item.Size = UDim2.new(0, 0, 0, 25) -- Height fixed, width will be set based on text
    item.BackgroundColor3 = Color3.fromRGB(25, 25, 30) -- Dark background
    item.BackgroundTransparency = 0.2
    item.BorderSizePixel = 0
    
    -- Add text label
    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.Size = UDim2.new(1, -10, 1, 0)
    label.Position = UDim2.new(0, 5, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = color or Color3.fromRGB(255, 255, 255)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Font = Enum.Font.SourceSansBold
    label.TextSize = 14
    label.Parent = item
    
    -- Calculate width based on text
    local textBounds = game:GetService("TextService"):GetTextSize(
        text, 
        14, 
        Enum.Font.SourceSansBold, 
        Vector2.new(math.huge, 25)
    )
    
    -- Add padding
    local width = textBounds.X + 20
    item.Size = UDim2.new(0, width, 0, 25)
    
    -- Add to our items list
    table.insert(self.items, {
        frame = item,
        text = text,
        width = width
    })
    
    -- Sort items by width (shortest to longest)
    table.sort(self.items, function(a, b)
        return a.width < b.width
    end)
    
    -- Update layout
    self:updateLayout()
    
    return item
end

function ArrayList:removeItem(text)
    for i, item in ipairs(self.items) do
        if item.text == text then
            -- Animate out
            local tween = TweenService:Create(
                item.frame,
                TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {Position = UDim2.new(1, 0, item.frame.Position.Y.Scale, item.frame.Position.Y.Offset)}
            )
            tween:Play()
            
            tween.Completed:Connect(function()
                item.frame:Destroy()
                table.remove(self.items, i)
                self:updateLayout()
            end)
            
            break
        end
    end
end

function ArrayList:updateItem(oldText, newText, newColor)
    for i, item in ipairs(self.items) do
        if item.text == oldText then
            -- Update text
            local label = item.frame:FindFirstChild("Label")
            label.Text = newText
            if newColor then
                label.TextColor3 = newColor
            end
            
            -- Recalculate width
            local textBounds = game:GetService("TextService"):GetTextSize(
                newText, 
                14, 
                Enum.Font.SourceSansBold, 
                Vector2.new(math.huge, 25)
            )
            
            local width = textBounds.X + 20
            item.width = width
            item.text = newText
            
            -- Sort items by width (shortest to longest)
            table.sort(self.items, function(a, b)
                return a.width < b.width
            end)
            
            -- Update layout
            self:updateLayout()
            
            break
        end
    end
end

function ArrayList:updateLayout()
    -- Calculate total height
    local totalHeight = 0
    for _, item in ipairs(self.items) do
        totalHeight = totalHeight + item.frame.Size.Y.Offset + 5 -- 5px spacing
    end
    
    -- Update main frame height
    self.frame.Size = UDim2.new(0, 200, 0, totalHeight)
    
    -- Position each item
    local yOffset = 0
    for _, item in ipairs(self.items) do
        -- Set parent if not already set
        if item.frame.Parent ~= self.frame then
            item.frame.Parent = self.frame
        end
        
        -- Position the item
        item.frame.Position = UDim2.new(1, -item.width, 0, yOffset)
        item.frame.Size = UDim2.new(0, item.width, 0, 25)
        
        -- Add corner radius
        local corner = item.frame:FindFirstChild("UICorner") or Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 4)
        corner.Parent = item.frame
        
        -- Add stroke
        local stroke = item.frame:FindFirstChild("UIStroke") or Instance.new("UIStroke")
        stroke.Color = Color3.fromRGB(60, 60, 70)
        stroke.Thickness = 1
        stroke.Parent = item.frame
        
        -- Update yOffset for next item
        yOffset = yOffset + item.frame.Size.Y.Offset + 5
    end
end

function ArrayList:show()
    if self.visible then return end
    
    self.visible = true
    
    -- Animate in from right
    local tween = TweenService:Create(
        self.frame,
        TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {Position = UDim2.new(1, 0, 0, 20)}
    )
    tween:Play()
    
    -- Animate each item
    for i, item in ipairs(self.items) do
        local delay = i * 0.05
        local targetPos = item.frame.Position
        
        item.frame.Position = UDim2.new(1, 0, targetPos.Y.Scale, targetPos.Y.Offset)
        
        task.delay(delay, function()
            local itemTween = TweenService:Create(
                item.frame,
                TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {Position = targetPos}
            )
            itemTween:Play()
        end)
    end
end

function ArrayList:hide()
    if not self.visible then return end
    
    self.visible = false
    
    -- Animate each item out
    for i, item in ipairs(self.items) do
        local delay = i * 0.05
        
        task.delay(delay, function()
            local itemTween = TweenService:Create(
                item.frame,
                TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {Position = UDim2.new(1, 0, item.frame.Position.Y.Scale, item.frame.Position.Y.Offset)}
            )
            itemTween:Play()
        end)
    end
    
    -- Animate main frame out
    task.delay(#self.items * 0.05 + 0.3, function()
        local tween = TweenService:Create(
            self.frame,
            TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {Position = UDim2.new(1, 200, 0, 20)}
        )
        tween:Play()
    end)
end

function ArrayList:toggle()
    if self.visible then
        self:hide()
    else
        self:show()
    end
end

return ArrayList
