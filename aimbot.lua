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
    MAX_DIST       = 99999999,       
    TRIGGER_DELAY  = 0.00001,       
    AUTO_CLICK     = true,  
}

local isAiming = false
local lastClick = 0

local function isVisible(part)
    local char = LocalPlayer.Character
    if not char then return false end
    
    local params = RaycastParams.new()
    params.FilterDescendantsInstances = {char, Camera}
    params.FilterType = Enum.RaycastFilterType.Exclude
    
    local origin = Camera.CFrame.Position
    local direction = part.Position - origin
    local result = Workspace:Raycast(origin, direction, params)

    if not result or result.Instance:IsDescendantOf(part.Parent) then
        return true
    end
    return false
end

local function getBestTarget()
    local target = nil
    local shortestDist = math.huge
    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    for _, p in ipairs(Players:GetPlayers()) do
        if p == LocalPlayer then continue end
        
        local char = p.Character
        local head = char and char:FindFirstChild(CFG.AIM_PART)
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        
        if head and hum and hum.Health > 0 then
            local pos, onScreen = Camera:WorldToViewportPoint(head.Position)
            if onScreen then
                local screenDist = (Vector2.new(pos.X, pos.Y) - screenCenter).Magnitude
                if screenDist < shortestDist and isVisible(head) then
                    shortestDist = screenDist
                    target = head
                end
            end
        end
    end
    return target
end
UserInputService.InputBegan:Connect(function(i) if i.UserInputType == CFG.AIM_KEY then isAiming = true end end)
UserInputService.InputEnded:Connect(function(i) if i.UserInputType == CFG.AIM_KEY then isAiming = false end end)

RunService:BindToRenderStep("GOD_TRIGGER_LOCK", Enum.RenderPriority.Camera.Value + 1, function()
    if isAiming then
        local target = getBestTarget()
        if target then
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, target.Position)
            if CFG.AUTO_CLICK and (tick() - lastClick) >= CFG.TRIGGER_DELAY then
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
            local bb = Instance.new("BillboardGui", root)
            bb.AlwaysOnTop = true; bb.Size = UDim2.new(4,0,5,0)
            local f = Instance.new("Frame", bb)
            f.Size = UDim2.new(1,0,1,0); f.BackgroundTransparency = 0.7; f.BackgroundColor3 = Color3.new(1,0,0)
            Instance.new("UIStroke", f).Color = Color3.new(1,1,1)
        end
    end
    if p.Character then apply(p.Character) end
    p.CharacterAdded:Connect(apply)
end
for _, p in ipairs(Players:GetPlayers()) do if p ~= LocalPlayer then createESP(p) end end
Players.PlayerAdded:Connect(createESP)
