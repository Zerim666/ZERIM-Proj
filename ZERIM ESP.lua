-- Script (ServerScriptService)
local Players = game:GetService("Players")

-- Function to highlight a character
local function highlightPlayer(character)
    local highlight = Instance.new("Highlight")
    highlight.Parent = character
    highlight.OutlineColor = Color3.new(1, 0, 0) -- Red (change per team?)
    highlight.FillColor = Color3.new(1, 0, 0, 0.2) -- Slight fill
    highlight.FillTransparency = 0.8 -- Mostly transparent
end

-- Apply to all players on spawn
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(highlightPlayer)
    if player.Character then
        highlightPlayer(player.Character)
    end
end)

-- Apply to existing players
for _, player in ipairs(Players:GetPlayers()) do
    if player.Character then
        highlightPlayer(player.Character)
    end
    player.CharacterAdded:Connect(highlightPlayer)
end
local Players = game:GetService("Players")

local function createNameTag(player)
    local character = player.Character or player.CharacterAdded:Wait()
    local humanoidRootPart = character:WaitForChild("Head") -- or "HumanoidRootPart"

    -- Create BillboardGui (floating text)
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "PlayerTag"
    billboard.Adornee = humanoidRootPart
    billboard.Size = UDim2.new(0, 100, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 3, 0) -- Height above head
    billboard.AlwaysOnTop = true
    billboard.LightInfluence = 1 -- Not affected by lighting
    billboard.Parent = humanoidRootPart

    -- TextLabel for the name
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Text = player.Name
    nameLabel.TextColor3 = Color3.new(1, 1, 1) -- White
    nameLabel.TextStrokeColor3 = Color3.new(0, 0, 0) -- Black outline
    nameLabel.TextStrokeTransparency = 0.3
    nameLabel.TextScaled = true
    nameLabel.BackgroundTransparency = 1 -- No background
    nameLabel.Size = UDim2.new(1, 0, 1, 0)
    nameLabel.Parent = billboard

    -- Optional: Add health display
    local humanoid = character:FindFirstChild("Humanoid")
    if humanoid then
        humanoid.HealthChanged:Connect(function()
            nameLabel.Text = player.Name .. "\nHP: " .. math.floor(humanoid.Health)
        end)
    end
end

-- Apply to all players
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(character)
        createNameTag(player)
    end)
    if player.Character then
        createNameTag(player)
    end
end)

-- Apply to existing players
for _, player in ipairs(Players:GetPlayers()) do
    if player.Character then
        createNameTag(player)
    end
    player.CharacterAdded:Connect(function(character)
        createNameTag(player)
    end)
end
-- Place in StarterPlayerScripts as a LocalScript
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- CONFIG --
local SETTINGS = {
    AimKey = Enum.KeyCode.RightControl,  -- Change to your preferred key
    Smoothing = 0.15,                   -- 0 = instant lock, 1 = no movement
    MaxFOV = 60,                        -- Degrees
    TeamCheck = true,                   -- Ignore teammates
    VisibleCheck = true,                -- Only target visible players
    AimPart = "Head",                   -- "Head" or "HumanoidRootPart"
    Prediction = 0.1,                   -- Bullet lead (set to 0 to disable)
    DrawFOV = true                      -- Show targeting circle
}

-- FOV Circle Visualization --
local FOVCircle
if SETTINGS.DrawFOV then
    FOVCircle = Instance.new("Frame")
    FOVCircle.Size = UDim2.new(0, SETTINGS.MaxFOV * 5, 0, SETTINGS.MaxFOV * 5)
    FOVCircle.Position = UDim2.new(0.5, -SETTINGS.MaxFOV * 2.5, 0.5, -SETTINGS.MaxFOV * 2.5)
    FOVCircle.BackgroundTransparency = 1
    FOVCircle.BorderColor3 = Color3.new(1, 0.5, 0.5)
    FOVCircle.BorderSizePixel = 1
    FOVCircle.AnchorPoint = Vector2.new(0.5, 0.5)
    FOVCircle.Parent = game.CoreGui
    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(1, 0)
    UICorner.Parent = FOVCircle
    FOVCircle.Visible = false
end

-- Find best target --
local function getBestTarget()
    if not LocalPlayer.Character then return nil end
    local myHead = LocalPlayer.Character:FindFirstChild("Head")
    if not myHead then return nil end

    local bestTarget = nil
    local closestAngle = math.rad(SETTINGS.MaxFOV)
    local myPosition = myHead.Position

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and (not SETTINGS.TeamCheck or player.Team ~= LocalPlayer.Team) then
            local character = player.Character
            if character then
                local targetPart = character:FindFirstChild(SETTINGS.AimPart)
                if targetPart then
                    -- Visibility check
                    if SETTINGS.VisibleCheck then
                        local ray = Ray.new(
                            myPosition,
                            (targetPart.Position - myPosition).Unit * 1000
                        )
                        local hit = workspace:FindPartOnRayWithIgnoreList(ray, {LocalPlayer.Character, character})
                        if hit and not hit:IsDescendantOf(character) then
                            continue
                        end
                    end

                    -- Calculate angle to target
                    local direction = (targetPart.Position - myPosition).Unit
                    local angle = math.acos(direction:Dot(Camera.CFrame.LookVector))
                    
                    -- Check if best target
                    if angle < closestAngle then
                        closestAngle = angle
                        bestTarget = targetPart
                    end
                end
            end
        end
    end

    return bestTarget
end

-- Smooth aiming --
local function aimAt(target)
    if not target then return end
    
    -- Add prediction
    local targetPosition = target.Position
    if SETTINGS.Prediction > 0 then
        local humanoid = target.Parent:FindFirstChildOfClass("Humanoid")
        if humanoid then
            targetPosition = targetPosition + (target.AssemblyLinearVelocity * SETTINGS.Prediction)
        end
    end

    -- Smooth camera movement
    local currentLook = Camera.CFrame.LookVector
    local desiredLook = (targetPosition - Camera.CFrame.Position).Unit
    local smoothedLook = currentLook:Lerp(desiredLook, 1 - SETTINGS.Smoothing)
    
    Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, Camera.CFrame.Position + smoothedLook)
end

-- Main loop --
RunService.RenderStepped:Connect(function()
    if FOVCircle then
        FOVCircle.Visible = UserInputService:IsKeyDown(SETTINGS.AimKey)
    end
    
    if UserInputService:IsKeyDown(SETTINGS.AimKey) then
        local target = getBestTarget()
        if target then
            aimAt(target)
        end
    end
end)

-- Instructions --
print("Aimbot loaded! Hold " .. tostring(SETTINGS.AimKey) .. " to activate")
