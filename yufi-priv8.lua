-- YUFI PRIV8 - Advanced Camlock GUI with Extended Auto Prediction
local PredictionValues = {
    [10] = 0.012,
    [20] = 0.0672,
    [30] = 0.1184,
    [40] = 0.119811,
    [50] = 0.12477,
    [60] = 0.12667,
    [70] = 0.1337,
    [75] = 0.13382,
    [80] = 0.142269,
    [90] = 0.1696969,
    [100] = 0.183662,
    [110] = 0.1872,
    [120] = 0.18144,
    [130] = 0.18229,
    [140] = 0.18555,
    [150] = 0.18912,
    [160] = 0.19284,
    [170] = 0.19643,
    [180] = 0.20021,
    [190] = 0.20358,
    [200] = 0.20734 -- Extends up to 200ms or beyond
}

-- Services
local StarterGui = game:GetService("StarterGui")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")

-- ScreenGui and Main Frame
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "YUFI_PRIV8_GUI"
screenGui.Parent = PlayerGui

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 320, 0, 250)
mainFrame.Position = UDim2.new(0.5, -160, 0.5, -125)
mainFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
mainFrame.BorderSizePixel = 0
mainFrame.Visible = true
mainFrame.BackgroundTransparency = 0.1
mainFrame.Parent = screenGui

local titleLabel = Instance.new("TextLabel")
titleLabel.Text = "YUFI PRIV8 - Camlock"
titleLabel.Size = UDim2.new(1, 0, 0, 40)
titleLabel.BackgroundTransparency = 1
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 20
titleLabel.Parent = mainFrame

-- Status Label
local statusLabel = Instance.new("TextLabel")
statusLabel.Text = "Camlock Status: Unlocked"
statusLabel.Position = UDim2.new(0, 10, 0, 60)
statusLabel.Size = UDim2.new(1, -20, 0, 30)
statusLabel.BackgroundTransparency = 1
statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 16
statusLabel.Parent = mainFrame

-- Camlock Variables
local camlockEnabled = false
local targetPlayer = nil
local PredictionValue = 0.1477  -- Starting Prediction Value

-- Get prediction value based on ping
local function getPredictionBasedOnPing()
    local ping = tonumber(string.match(Stats.Network.ServerStatsItem["Data Ping"]:GetValueString(), "%d+"))
    if ping then
        for threshold, value in pairs(PredictionValues) do
            if ping <= threshold then
                return value
            end
        end
    end
    return PredictionValues[70]  -- Default to highest ping setting if no match
end

-- Toggle Camlock and Update Prediction
UIS.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.C then
        camlockEnabled = not camlockEnabled
        PredictionValue = getPredictionBasedOnPing()  -- Set prediction based on ping

        if camlockEnabled then
            targetPlayer = getClosestPlayer()
            if targetPlayer then
                statusLabel.Text = "Camlock Status: LOCKED to " .. targetPlayer.Name
                StarterGui:SetCore("SendNotification", {
                    Title = "YUFI PRIV8 - LOCKED",
                    Text = "Locked to: " .. targetPlayer.Name,
                    Duration = 2
                })
            end
        else
            targetPlayer = nil
            statusLabel.Text = "Camlock Status: Unlocked"
            StarterGui:SetCore("SendNotification", {
                Title = "YUFI PRIV8 - UNLOCKED",
                Text = "UNLOCKED",
                Duration = 2
            })
        end
    end
end)

-- Get Closest Player
local function getClosestPlayer()
    local closestPlayer = nil
    local shortestDistance = math.huge

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local playerPos = player.Character.HumanoidRootPart.Position
            local distance = (LocalPlayer.Character.HumanoidRootPart.Position - playerPos).Magnitude

            if distance < shortestDistance then
                closestPlayer = player
                shortestDistance = distance
            end
        end
    end
    return closestPlayer
end

-- Camlock Tracking with High Accuracy
RunService.RenderStepped:Connect(function()
    if camlockEnabled and targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local targetPos = targetPlayer.Character.HumanoidRootPart.Position + (targetPlayer.Character.HumanoidRootPart.Velocity * PredictionValue)
        LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(LocalPlayer.Character.HumanoidRootPart.Position, targetPos)
    end
end)

-- Toggle UI with Right Control
local function toggleUI()
    mainFrame.Visible = not mainFrame.Visible
    if mainFrame.Visible then
        for i = 0, 1, 0.1 do
            mainFrame.BackgroundTransparency = 1 - i
            wait(0.01)
        end
    else
        for i = 0, 1, 0.1 do
            mainFrame.BackgroundTransparency = i
            wait(0.01)
        end
    end
end

UIS.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.RightControl then
        toggleUI()
    end
end)

-- Drag Functionality
local dragging, dragInput, dragStart, startPos

mainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = mainFrame.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

mainFrame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        dragInput = input
    end
end)

UIS.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- High-Accuracy Camlock Configuration
getgenv().OldAimPart = "Head"
getgenv().AimPart = "HumanoidRootPart"
getgenv().AimlockKey = "c"
getgenv().AimRadius = 100
getgenv().ThirdPerson = true
getgenv().FirstPerson = true
getgenv().TeamCheck = false
getgenv().PredictMovement = true
getgenv().PredictionVelocity = PredictionValue
getgenv().CheckIfJumped = true
getgenv().Smoothness = true
getgenv().SmoothnessAmount = 0.4661

warn("YUFI PRIV8 - SUCCESS!")
