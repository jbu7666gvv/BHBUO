-- 跨服自动加载器（添加在脚本开头）
-- 在 CandyFarm2.lua 的最开头添加这个修正版跨服代码
do
    -- 增强版跨服加载器
    local crossServerKey = "BHBUO_CrossServer_v2"
    if _G[crossServerKey] then return end
    _G[crossServerKey] = true
    
    -- 保存原始跨服函数
    local originalQueueTeleport = (syn and syn.queue_on_teleport) or queue_on_teleport or (fluxus and fluxus.queue_on_teleport)
    
    if originalQueueTeleport then
        -- 正确构建跨服代码（避免字符串格式化问题）
        local teleportCode = [[
            -- 跨服后重新加载脚本
            wait(1)  -- 等待服务器稳定
            
            -- 加载第一个脚本
            local success1, err1 = pcall(function()
                loadstring(game:HttpGet("https://raw.githubusercontent.com/jbu7666gvv/BHBUO/refs/heads/main/CandyFarm2.lua"))()
            end)
            
            wait(0.5)
            
            -- 加载第二个脚本
            local success2, err2 = pcall(function()
                loadstring(game:HttpGet("https://raw.githubusercontent.com/jbu7666gvv/BHBUO/refs/heads/main/candyf"))()
            end)
            
            if success1 and success2 then
                warn("跨服加载成功")
            end
        ]]
        
        -- 设置跨服代码
        originalQueueTeleport(teleportCode)
        
        -- 同时设置事件监听（双重保险）
        if game.Players.LocalPlayer then
            game.Players.LocalPlayer.OnTeleport:Connect(function(state)
                if state == Enum.TeleportState.Started then
                    originalQueueTeleport(teleportCode)
                end
            end)
        end
    end
end

-- 创建自制通知UI
local function createNotify(content, duration)
    duration = duration or 3
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "BHBUONotifyGUI"
    screenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
    
    local notifyFrame = Instance.new("Frame")
    notifyFrame.Name = "BHBUONotify"
    notifyFrame.Size = UDim2.new(0, 300, 0, 80)
    notifyFrame.Position = UDim2.new(1, -320, 1, -100)
    notifyFrame.AnchorPoint = Vector2.new(0, 0)
    notifyFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    notifyFrame.BackgroundTransparency = 0.1
    notifyFrame.BorderSizePixel = 0
    
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 25)
    titleBar.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    titleBar.BorderSizePixel = 0
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Size = UDim2.new(1, -10, 1, 0)
    titleLabel.Position = UDim2.new(0, 5, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "BHBUO刷拐杖糖果"
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.Font = Enum.Font.SourceSansBold
    titleLabel.TextSize = 14
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    
    local contentLabel = Instance.new("TextLabel")
    contentLabel.Name = "Content"
    contentLabel.Size = UDim2.new(1, -10, 1, -25)
    contentLabel.Position = UDim2.new(0, 5, 0, 25)
    contentLabel.BackgroundTransparency = 1
    contentLabel.Text = content or ""
    contentLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    contentLabel.Font = Enum.Font.SourceSans
    contentLabel.TextSize = 12
    contentLabel.TextWrapped = true
    contentLabel.TextXAlignment = Enum.TextXAlignment.Left
    contentLabel.TextYAlignment = Enum.TextYAlignment.Top
    
    titleLabel.Parent = titleBar
    titleBar.Parent = notifyFrame
    contentLabel.Parent = notifyFrame
    notifyFrame.Parent = screenGui
    
    notifyFrame.Position = UDim2.new(1, 300, 1, -100)
    local tween = game:GetService("TweenService"):Create(
        notifyFrame,
        TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {Position = UDim2.new(1, -320, 1, -100)}
    )
    tween:Play()
    
    delay(duration, function()
        if notifyFrame and notifyFrame.Parent then
            local tweenOut = game:GetService("TweenService"):Create(
                notifyFrame,
                TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
                {Position = UDim2.new(1, 300, 1, -100)}
            )
            tweenOut:Play()
            delay(0.3, function()
                screenGui:Destroy()
            end)
        end
    end)
end

-- 检查是否有梯子蓝图
local function hasLadderBlueprint()
    local player = game.Players.LocalPlayer
    local inventory = player:FindFirstChild("Inventory")
    
    if inventory then
        for _, item in ipairs(inventory:GetChildren()) do
            if string.find(item.Name, "Ladder") then
                return item
            end
        end
    end
    
    return nil
end

-- 购买梯子
local function buyLadder()
    createNotify("购买梯子", 2)
    
    local success = pcall(function()
        local args = {"Ladder"}
        game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvents"):WaitForChild("RequestBuySantaSack"):FireServer(unpack(args))
    end)
    
    return success
end

-- 拖拽硬币到玩家头上（最多3个）
local function dragCoinsToPlayer()
    createNotify("正在获取硬币...", 2)  -- 只显示这个通知
    
    local player = game.Players.LocalPlayer
    local character = player.Character
    if not character then 
        createNotify("角色未加载", 2)
        return false 
    end
    
    local playerRoot = character:FindFirstChild("HumanoidRootPart")
    if not playerRoot then 
        createNotify("找不到玩家位置", 2)
        return false 
    end
    
    -- 查找硬币堆
    local itemsFolder = workspace:WaitForChild("Items")
    local coins = {}
    
    for _, item in ipairs(itemsFolder:GetChildren()) do
        if item:IsA("Model") and item.Name == "Coin Stack" then
            table.insert(coins, item)
            if #coins >= 3 then break end
        end
    end
    
    if #coins == 0 then
        createNotify("没有找到硬币堆", 2)
        return false
    end
    
    -- 拖拽硬币到玩家头上
    for i, coin in ipairs(coins) do
        local targetPosition = playerRoot.Position + Vector3.new(0, 4 + (i-1) * 1.5, 0)
        
        if coin:FindFirstChild("Handle") then
            coin.Handle.CFrame = CFrame.new(targetPosition)
        elseif coin.PrimaryPart then
            coin.PrimaryPart.CFrame = CFrame.new(targetPosition)
        else
            for _, part in ipairs(coin:GetChildren()) do
                if part:IsA("BasePart") then
                    part.CFrame = CFrame.new(targetPosition)
                    break
                end
            end
        end
        
        local dragSuccess = pcall(function()
            game:GetService("ReplicatedStorage").RemoteEvents.RequestStartDraggingItem:FireServer(coin)
            wait(0)
            game:GetService("ReplicatedStorage").RemoteEvents.StopDraggingItem:FireServer(coin)
        end)
        
        wait(0)
    end
    
    return true
end

-- 收集硬币（使用远程事件）
local function collectCoinsRemote()
    createNotify("正在获取硬币...", 2)  -- 只显示这个通知，持续显示
    
    local itemsFolder = workspace:WaitForChild("Items")
    local coinStacks = {}
    
    for _, item in ipairs(itemsFolder:GetChildren()) do
        if item:IsA("Model") and item.Name == "Coin Stack" then
            table.insert(coinStacks, item)
        end
    end
    
    if #coinStacks == 0 then
        createNotify("附近没有硬币堆", 2)
        return false
    end
    
    -- 执行3次硬币收集
    for i = 1, 3 do
        if #coinStacks > 0 then
            local coinStack = coinStacks[1]
            
            local success = pcall(function()
                local args = {[1] = coinStack}
                game:GetService("ReplicatedStorage").RemoteEvents.RequestCollectCoints:InvokeServer(unpack(args))
            end)
            
            if success then
                table.remove(coinStacks, 1)
            end
            
            wait(0)
        else
            break
        end
    end
    
    createNotify("硬币获取完成", 2)  -- 结束后显示完成通知
    return true
end

-- 确保死亡函数
local function ensureDeath()
    createNotify("确保死亡", 1)
    
    local player = game.Players.LocalPlayer
    local character = player.Character
    
    if character then
        local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
        if humanoidRootPart then
            -- 传送到虚空确保死亡
            humanoidRootPart.CFrame = CFrame.new(0, -775, 0)
            wait(0.2)  -- 等待死亡
        end
    end
end

-- 执行重进流程（连续100次）
local function executeReenterLoop()
    createNotify("开始连续重进100次", 2)
    
    for i = 1, 100 do
        createNotify(string.format("重进 %d/100", i), 1)
        
        -- 先确保死亡
        ensureDeath()
        wait(0.1)
        
        -- 执行重进
        local reenterSuccess = pcall(function()
            game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvents"):WaitForChild("AcceptPlayAgain"):FireServer()
        end)
        
        if reenterSuccess then
            createNotify(string.format("重进成功 %d/100", i), 1)
        else
            createNotify(string.format("重进失败 %d/100", i), 1)
        end
        
        -- 每次重进间隔0.1秒
        wait(0.1)
    end
    
    createNotify("连续重进完成", 3)
end

-- 主要刷糖果函数（执行完成后会自动重进）
local function executeCandyFarm()
    createNotify("开始刷糖果流程", 2)
    
    local player = game.Players.LocalPlayer
    repeat wait() until player.Character
    repeat wait() until player.Character:FindFirstChild("HumanoidRootPart")
    
    -- 步骤1: 先购买梯子
    createNotify("购买梯子", 2)
    
    local buySuccess = buyLadder()
    wait(0.01)
    
    -- 步骤2: 检查是否有梯子蓝图
    createNotify("检查梯子蓝图", 2)
    
    local ladderBlueprint = hasLadderBlueprint()
    
    if not ladderBlueprint then
        createNotify("购买梯子但没有蓝图，需要硬币", 2)
        
        -- 收集硬币流程
        createNotify("开始收集硬币", 2)
        
        -- 先拖拽硬币到玩家
        local dragSuccess = dragCoinsToPlayer()
        wait(0.1)
        
        -- 再收集硬币
        local collectSuccess = collectCoinsRemote()
        wait(0.1)
        
        -- 再次购买梯子
        createNotify("再次购买梯子", 2)
        buySuccess = buyLadder()
        
        if not buySuccess then
            createNotify("再次购买梯子失败，死亡重进", 3)
            ensureDeath()
            wait(0.2)
            executeReenterLoop()
            return
        end
        
        wait(1)
        
        -- 再次检查是否有梯子蓝图
        ladderBlueprint = hasLadderBlueprint()
        
        if not ladderBlueprint then
            createNotify("购买后还是没有梯子蓝图，死亡重进", 3)
            ensureDeath()
            wait(0.2)
            executeReenterLoop()
            return
        end
    end
    
    createNotify("有梯子蓝图，继续流程", 2)
    
    -- 步骤3: 放置梯子
    createNotify("放置梯子", 2)
    
    local elfObject = workspace:WaitForChild("Map"):WaitForChild("Landmarks"):WaitForChild("Elf Tree"):WaitForChild("Functional"):WaitForChild("Stuck Elf")
    local elfPosition = nil
    
    if elfObject then
        if elfObject:IsA("BasePart") then
            elfPosition = elfObject.Position
        elseif elfObject:FindFirstChild("HumanoidRootPart") then
            elfPosition = elfObject.HumanoidRootPart.Position
        elseif elfObject.PrimaryPart then
            elfPosition = elfObject.PrimaryPart.Position
        end
    end
    
    if not elfPosition then
        createNotify("无法获取精灵位置，死亡重进", 3)
        ensureDeath()
        wait(0.2)
        executeReenterLoop()
        return
    end
    
    local placementPosition = elfPosition + Vector3.new(0, -40, 0) + Vector3.new(0, 0, -10)
    local placementCFrame = CFrame.new(placementPosition)
    
    local placeSuccess = pcall(function()
        local args = {
            [1] = ladderBlueprint,
            [2] = {
                ["Valid"] = true,
                ["CFrame"] = placementCFrame,
                ["Position"] = placementPosition
            },
            [3] = CFrame.Angles(0, 0, 0)
        }
        return game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvents"):WaitForChild("RequestPlaceStructure"):InvokeServer(unpack(args))
    end)
    
    if not placeSuccess then
        createNotify("放置梯子失败，死亡重进", 3)
        ensureDeath()
        wait(0.2)
        executeReenterLoop()
        return
    end
    
    createNotify("梯子放置成功", 2)
    wait(1)
    
    -- 步骤4: 执行救援
    createNotify("执行救援", 2)
    
    local rescueSuccess = pcall(function()
        local args = {
            workspace:WaitForChild("Map"):WaitForChild("Landmarks"):WaitForChild("Elf Tree"):WaitForChild("Functional"):WaitForChild("Stuck Elf"),
            workspace:WaitForChild("Structures"):WaitForChild("Ladder")
        }
        game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvents"):WaitForChild("Elf_StuckInTree"):FireServer(unpack(args))
    end)
    
    if not rescueSuccess then
        createNotify("救援失败，死亡重进", 3)
        ensureDeath()
        wait(0.2)
        executeReenterLoop()
        return
    end
    
    createNotify("救援成功！等待礼物生成...", 2)
    
    -- 步骤5: 等待礼物生成
    local giftFound = false
    local maxWaitTime = 9
    local startTime = tick()
    local checkRadius = 50
    local lastNotifyTime = 0

    while tick() - startTime < maxWaitTime do
        local items = workspace:WaitForChild("Items")
        for _, gift in ipairs(items:GetChildren()) do
            if gift:IsA("Model") and string.find(gift.Name, "Present") then
                local giftPart = gift:FindFirstChild("Main") or gift.PrimaryPart
                if giftPart then
                    local distance = (giftPart.Position - elfPosition).Magnitude
                    
                    if distance <= checkRadius then
                        if not gift:GetAttribute(tostring(player.UserId) .. "Opened") then
                            local openSuccess = pcall(function()
                                local args = { gift }
                                game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvents"):WaitForChild("RequestOpenItemChest"):FireServer(unpack(args))
                            end)
                            
                            if openSuccess then
                                giftFound = true
                                createNotify("成功开启礼物！", 2)
                                
                                wait(0.5)
                                
                                -- 步骤6: 获取糖果
                                createNotify("获取糖果", 2)
                                
                                local candyCount = 0
                                for i = 1, 5 do
                                    local candySuccess = pcall(function()
                                        local args = {1, "Present"}
                                        game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvents"):WaitForChild("RequestCollectCandyCane"):FireServer(unpack(args))
                                    end)
                                    
                                    if candySuccess then
                                        candyCount = candyCount + 1
                                        createNotify(string.format("获取糖果 %d/5", i), 0.5)
                                    end
                                    
                                    wait(0)
                                end
                                
                                createNotify(string.format("✓ 获得%d个糖果", candyCount), 2)
                                
                                -- 步骤7: 死亡后重进
                                createNotify("死亡并开始连续重进", 2)
                                ensureDeath()
                                wait(0.2)
                                executeReenterLoop()
                                return
                            end
                        end
                    end
                end
            end
        end
        
        local elapsed = math.floor(tick() - startTime)
        local currentTime = tick()
        
        if currentTime - lastNotifyTime >= 1 then
            createNotify(string.format("等待礼物... %d/%d秒", elapsed, maxWaitTime), 1)
            lastNotifyTime = currentTime
        end
        
        wait(0.01)
    end
    
    if not giftFound then
        createNotify("未找到礼物，死亡重进", 3)
        ensureDeath()
        wait(0.2)
        executeReenterLoop()
        return
    end
end

-- 启动脚本
createNotify("BHBUO刷糖果脚本启动", 3)
executeCandyFarm()
