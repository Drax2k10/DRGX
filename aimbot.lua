local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local VirtualInputManager = game:GetService("VirtualInputManager") 

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local CFG = {
    AIM_KEY        = Enum.UserInputType.MouseButton2, 
    AIM_PART       = "Head",     
    MAX_DIST       = 500,        
    TRIGGER_DELAY  = 0.01,
    TRACER_COLOR   = Color3.new(1, 0, 0),
}

local flags = {
    AIM_ENABLED     = true,  
    AUTO_CLICK      = true,  
    ESP_ENABLED     = true   
}

local isAiming = false
local lastClick = 0
local Tracers = {} 
local ignoredPlayers = {} 
local GuiService = game:GetService("CoreGui")
local guiParent
pcall(function() guiParent = GuiService end)
if not guiParent then guiParent = LocalPlayer:WaitForChild("PlayerGui") end

if guiParent:FindFirstChild("HM_GOD_GUI") then
    guiParent.HM_GOD_GUI:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "HM_GOD_GUI"
ScreenGui.Parent = guiParent

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 200, 0, 300)
MainFrame.Position = UDim2.new(0, 20, 0.5, 0) -- Nằm bên trái, ở giữa (chiều dọc)
MainFrame.AnchorPoint = Vector2.new(0, 0.5)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
MainFrame.BorderSizePixel = 0

local UICorner = Instance.new("UICorner", MainFrame)
UICorner.CornerRadius = UDim.new(0, 8)

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.BackgroundTransparency = 1
Title.Text = "IGNORE LIST (Bỏ qua)"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 14

local ScrollFrame = Instance.new("ScrollingFrame", MainFrame)
ScrollFrame.Size = UDim2.new(1, -10, 1, -40)
ScrollFrame.Position = UDim2.new(0, 5, 0, 35)
ScrollFrame.BackgroundTransparency = 1
ScrollFrame.ScrollBarThickness = 4
ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)

local UIListLayout = Instance.new("UIListLayout", ScrollFrame)
UIListLayout.SortOrder = Enum.SortOrder.Name
UIListLayout.Padding = UDim.new(0, 5)

local function createPlayerButton(player)
    if player == LocalPlayer then return end
    
    local Btn = Instance.new("TextButton", ScrollFrame)
    Btn.Name = player.Name
    Btn.Size = UDim2.new(1, -8, 0, 30)
    Btn.BackgroundColor3 = Color3.fromRGB(200, 50, 50) 
    Btn.Text = player.Name
    Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    Btn.Font = Enum.Font.GothamSemibold
    Btn.TextSize = 12
    
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 4)
    
    Btn.MouseButton1Click:Connect(function()
        ignoredPlayers[player.Name] = not ignoredPlayers[player.Name]
        if ignoredPlayers[player.Name] then
            Btn.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
            Btn.Text = player.Name .. " [IGNORED]"
        else
            Btn.BackgroundColor3 = Color3.fromRGB(200, 50, 50) 
            Btn.Text = player.Name
        end
    end)
    
    UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, UIListLayout.AbsoluteContentSize.Y + 10)
    end)
end

for _, p in ipairs(Players:GetPlayers()) do createPlayerButton(p) end
Players.PlayerAdded:Connect(createPlayerButton)
Players.PlayerRemoving:Connect(function(player)
    if ScrollFrame:FindFirstChild(player.Name) then
        ScrollFrame[player.Name]:Destroy()
    end
    ignoredPlayers[player.Name] = nil
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.F1 then
        flags.AIM_ENABLED = not flags.AIM_ENABLED
    elseif input.KeyCode == Enum.KeyCode.F2 then
        flags.AUTO_CLICK = not flags.AUTO_CLICK
    elseif input.KeyCode == Enum.KeyCode.F3 then
        flags.ESP_ENABLED = not flags.ESP_ENABLED
        for _, p in ipairs(Players:GetPlayers()) do
            local char = p.Character
            local esp = char and char:FindFirstChild("HumanoidRootPart") and char.HumanoidRootPart:FindFirstChild("GOD_ESP")
            if esp then esp.Enabled = (flags.ESP_ENABLED and not ignoredPlayers[p.Name]) end
        end
    end
end)

local function isVisible(part)
    local char = LocalPlayer.Character
    if not char then return false end
    local params = RaycastParams.new()
    params.FilterDescendantsInstances = {char, Camera}
    params.FilterType = Enum.RaycastFilterType.Exclude
    local result = Workspace:Raycast(Camera.CFrame.Position, part.Position - Camera.CFrame.Position, params)
    return not result or result.Instance:IsDescendantOf(part.Parent)
end

local function getBestTarget()
    if not flags.AIM_ENABLED then return nil end
    local target = nil
    local shortestDist = CFG.MAX_DIST 

    for _, p in ipairs(Players:GetPlayers()) do
        if p == LocalPlayer or ignoredPlayers[p.Name] then continue end -- BỎ QUA PLAYER TRONG DANH SÁCH
        
        local char = p.Character
        local head = char and char:FindFirstChild(CFG.AIM_PART)
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        
        if head and hum and hum.Health > 0 then
            local dist3D = (head.Position - Camera.CFrame.Position).Magnitude
            if dist3D < shortestDist and isVisible(head) then
                shortestDist = dist3D
                target = head
            end
        end
    end
    return target
end

UserInputService.InputBegan:Connect(function(i) if i.UserInputType == CFG.AIM_KEY then isAiming = true end end)
UserInputService.InputEnded:Connect(function(i) if i.UserInputType == CFG.AIM_KEY then isAiming = false end end)

RunService:BindToRenderStep("GOD_TRIGGER_LOCK", Enum.RenderPriority.Camera.Value + 1, function()
    if isAiming and flags.AIM_ENABLED then
        local target = getBestTarget()
        if target then
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, target.Position)
            if flags.AUTO_CLICK and (tick() - lastClick) >= CFG.TRIGGER_DELAY then
                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
                task.wait()
                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
                lastClick = tick()
            end
        end
    end
end)

local function createESP(p)
    local function apply(char)
        local root = char:WaitForChild("HumanoidRootPart", 10)
        if root then
            if root:FindFirstChild("GOD_ESP") then root.GOD_ESP:Destroy() end
            local bb = Instance.new("BillboardGui", root)
            bb.Name = "GOD_ESP"
            bb.AlwaysOnTop = true; bb.Size = UDim2.new(4,0,5,0)

            bb.Enabled = flags.ESP_ENABLED and not ignoredPlayers[p.Name]
            local f = Instance.new("Frame", bb)
            f.Size = UDim2.new(1,0,1,0); f.BackgroundTransparency = 0.7; f.BackgroundColor3 = Color3.new(1,0,0)
            Instance.new("UIStroke", f).Color = Color3.new(1,1,1)
            
            task.spawn(function()
                while root and root.Parent do
                    bb.Enabled = flags.ESP_ENABLED and not ignoredPlayers[p.Name]
                    task.wait(0.5)
                end
            end)
        end
    end
    if p.Character then apply(p.Character) end
    p.CharacterAdded:Connect(apply)
end

for _, p in ipairs(Players:GetPlayers()) do if p ~= LocalPlayer then createESP(p) end end
Players.PlayerAdded:Connect(createESP)

RunService:BindToRenderStep("GOD_TRACERS", Enum.RenderPriority.Camera.Value, function()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            if not Tracers[p] then
                local line = Drawing.new("Line")
                line.Thickness = 1.5
                line.Color = CFG.TRACER_COLOR
                line.Transparency = 1
                Tracers[p] = line
            end
            
            local tracer = Tracers[p]
            local char = p.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            
            if flags.ESP_ENABLED and not ignoredPlayers[p.Name] and root and hum and hum.Health > 0 then
                local pos, onScreen = Camera:WorldToViewportPoint(root.Position)
                if onScreen then
                    tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                    tracer.To = Vector2.new(pos.X, pos.Y)
                    tracer.Visible = true
                else
                    tracer.Visible = false
                end
            else
                tracer.Visible = false
            end
        end
    end
end)

Players.PlayerRemoving:Connect(function(p)
    if Tracers[p] then
        Tracers[p]:Remove()
        Tracers[p] = nil
    end
end)
