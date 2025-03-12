-- 修改後的 AddItem（右對齊版本）
function ArrayListUI:AddItem(name, value, isActive)
    local itemColor = isActive and config.activeColor or config.inactiveColor
    local itemId = #self.items + 1

    -- 建立選項容器，設定 AnchorPoint 為右上角
    local itemFrame = Instance.new("Frame")
    itemFrame.Name = "Item_" .. itemId
    itemFrame.AnchorPoint = Vector2.new(1, 0)  -- 以右側作為錨點
    itemFrame.BackgroundTransparency = 1
    itemFrame.Size = UDim2.new(1, 0, 0, config.textSize + 4)
    -- 初始位置設定在主容器右側之外，待 Tween 回到右側對齊
    itemFrame.Position = UDim2.new(1.2, 0, 0, self:GetTotalHeight())
    itemFrame.Parent = self.mainFrame

    local textLabel = Instance.new("TextLabel")
    textLabel.Name = "Text"
    textLabel.BackgroundTransparency = 1
    textLabel.Size = UDim2.new(1, -config.padding * 2 - config.verticalLine.width, 1, 0)
    textLabel.Position = UDim2.new(0, config.padding, 0, 0)
    textLabel.Font = config.font
    textLabel.TextSize = config.textSize
    textLabel.TextColor3 = itemColor
    textLabel.Text = value and (name .. " " .. value) or name
    textLabel.TextXAlignment = Enum.TextXAlignment.Right  -- 文字靠右
    textLabel.Parent = itemFrame

    -- 計算所需寬度，並更新主容器寬度
    local textWidth = game:GetService("TextService"):GetTextSize(
        textLabel.Text, 
        config.textSize, 
        config.font, 
        Vector2.new(1000, 100)
    ).X

    local targetWidth = textWidth + (config.padding * 2) + config.verticalLine.width
    if targetWidth > self.mainFrame.Size.X.Offset then
        self.mainFrame.Size = UDim2.new(0, targetWidth, self.mainFrame.Size.Y)
    end

    local itemData = {
        id = itemId,
        frame = itemFrame,
        text = textLabel,
        valueText = value,
        isActive = isActive
    }
    table.insert(self.items, itemData)
    ArrayListItems[itemId] = itemData

    -- 更新主容器高度
    self:UpdateFrameHeight()

    -- 動畫：從右側滑入到最終位置（右側對齊，即 Position.x = 1）
    itemFrame:TweenPosition(
        UDim2.new(1, 0, 0, self:GetItemPosition(itemId)), 
        config.animationDirection, 
        config.animationStyle, 
        config.animationTime, 
        true
    )

    -- 漸入效果
    game:GetService("TweenService"):Create(
        textLabel, 
        TweenInfo.new(config.animationTime, config.animationStyle, config.animationDirection), 
        {TextTransparency = 0}
    ):Play()

    return itemId
end
