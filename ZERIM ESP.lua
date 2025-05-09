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

local Aimbot = loadstring(game:HttpGet("https://raw.githubusercontent.com/Exunys/Aimbot-V3/main/src/Aimbot.lua"))()
Aimbot.Load()
