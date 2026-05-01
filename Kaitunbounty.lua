-- =========================
-- LOAD & INIT
-- =========================
loadstring(game:HttpGet("https://raw.githubusercontent.com/Drax2k10/DRGX/refs/heads/main/deleteoldgui.lua"))()

repeat task.wait() until game:IsLoaded()
local player = game.Players.LocalPlayer
local UIS = game:GetService("UserInputService")
local TP  = game:GetService("TeleportService")

-- =========================
-- FILES
-- =========================
local teamFile   = "team.txt"
local targetFile = "target.txt"
local startFile  = "started.txt"

-- TEAM
local function saveTeam(t) if writefile then writefile(teamFile, t) end end
local function loadTeam()
    if readfile and isfile and isfile(teamFile) then
        return readfile(teamFile)
    end
    return "Pirates"
end

-- TARGET
local function saveTarget(b, h)
    if writefile then writefile(targetFile, tostring(b)..","..tostring(h)) end
end
local function loadTarget()
    if readfile and isfile and isfile(targetFile) then
        local d = readfile(targetFile)
        local b,h = d:match("([^,]+),([^,]+)")
        return tonumber(b), tonumber(h)
    end
end

-- START STATE
local function saveStart(v)
    if writefile then writefile(startFile, tostring(v)) end
end
local function loadStart()
    if readfile and isfile and isfile(startFile) then
        return readfile(startFile) == "true"
    end
    return false
end

-- =========================
-- CONFIG
-- =========================
_G.SeleneCFG = {
    Team = loadTeam(),
    Region = "Singapore",
    WebhookURL = "",
    DiscordID = "",
    SuperBoostFps = false,
}

-- =========================
-- LOAD SCRIPT CHÍNH
-- =========================
loadstring(game:HttpGet("https://gist.githubusercontent.com/LeMinh2k12/7341d1a7e1208b959ba70511a6448c63/raw/00d03157131efe06ca10a340e43b9bf9f5e6698b/gistfile1.txt"))()
loadstring(game:HttpGet("https://raw.githubusercontent.com/Drax2k10/DRGX/refs/heads/main/Gui.lua"))()
loadstring(game:HttpGet("https://raw.githubusercontent.com/Drax2k10/DRGX/refs/heads/main/stat.lua"))()

repeat task.wait() until player:FindFirstChild("leaderstats")

-- =========================
-- GET STAT
-- =========================
local function getStat()
    local ls = player:FindFirstChild("leaderstats")
    if not ls then return 0 end
    local v = ls:FindFirstChild("Bounty/Honor")
    return v and v.Value or 0
end

-- =========================
-- GUI 🇻🇳
-- =========================
local gui = Instance.new("ScreenGui", player.PlayerGui)

local button = Instance.new("ImageButton", gui)
button.Size = UDim2.new(0,60,0,60)
button.Position = UDim2.new(0,20,0.5,-30)
button.BackgroundColor3 = Color3.fromRGB(255,0,0)
button.Image = "rbxassetid://119179036371497"
Instance.new("UICorner", button).CornerRadius = UDim.new(1,0)

-- drag
local dragging, startPos, startMouse
button.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        startMouse = i.Position
        startPos = button.Position
    end
end)
UIS.InputChanged:Connect(function(i)
    if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
        local d = i.Position - startMouse
        button.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X,
                                   startPos.Y.Scale, startPos.Y.Offset + d.Y)
    end
end)
button.InputEnded:Connect(function() dragging = false end)

-- frame
local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0,280,0,200)
frame.Position = UDim2.new(0.5,-140,0.5,-100)
frame.BackgroundColor3 = Color3.fromRGB(20,20,20)
frame.Visible = false
Instance.new("UICorner", frame)

local bountyBox = Instance.new("TextBox", frame)
bountyBox.PlaceholderText = "Target Bounty"
bountyBox.Size = UDim2.new(0.8,0,0,30)
bountyBox.Position = UDim2.new(0.1,0,0.25,0)

local honorBox = Instance.new("TextBox", frame)
honorBox.PlaceholderText = "Target Honor"
honorBox.Size = UDim2.new(0.8,0,0,30)
honorBox.Position = UDim2.new(0.1,0,0.5,0)

local startBtn = Instance.new("TextButton", frame)
startBtn.Size = UDim2.new(0.8,0,0,35)
startBtn.Position = UDim2.new(0.1,0,0.75,0)
startBtn.Text = "START"

button.MouseButton1Click:Connect(function()
    frame.Visible = not frame.Visible
end)

-- =========================
-- LOAD DATA
-- =========================
local sb, sh = loadTarget()
if sb then bountyBox.Text = tostring(sb) end
if sh then honorBox.Text = tostring(sh) end

bountyBox.FocusLost:Connect(function()
    saveTarget(bountyBox.Text, honorBox.Text)
end)
honorBox.FocusLost:Connect(function()
    saveTarget(bountyBox.Text, honorBox.Text)
end)

-- =========================
-- CONTROL
-- =========================
local started = loadStart()
local switched = false

if started then
    startBtn.Text = "RUNNING"
end

startBtn.MouseButton1Click:Connect(function()
    started = true
    saveStart(true)
    startBtn.Text = "RUNNING"
end)

-- =========================
-- LOOP
-- =========================
task.spawn(function()
    while true do
        task.wait(2)

        if not started then continue end
        if not player.Team then continue end

        local current = getStat()
        local bTarget = tonumber(bountyBox.Text)
        local hTarget = tonumber(honorBox.Text)

        print("Stat:", current, "| Team:", player.Team.Name)

        -- PIRATES → MARINES
        if player.Team.Name == "Pirates" and bTarget and current >= bTarget and not switched then
            switched = true
            saveTeam("Marines")
            saveStart(true)

            task.wait(1)
            TP:Teleport(game.PlaceId, player)
        end

        -- MARINES → DONE
        if player.Team.Name == "Marines" and hTarget and current >= hTarget then
            saveTeam("Pirates")
            saveStart(false)

            task.wait(1)
            game:Shutdown()
            break
        end
    end
end)
