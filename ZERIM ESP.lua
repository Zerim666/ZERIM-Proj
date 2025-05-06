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

-- CONFIGURATION --
local SETTINGS = {
    Enabled = true,
    Smoothing = 0.15,          -- 0 = instant lock, 1 = no movement
    MaxFOV = 60,              -- Degrees
    TeamCheck = true,         -- Ignore teammates
    VisibleCheck = true,      -- Only target visible players
    AimPart = "Head",         -- "Head" or "HumanoidRootPart"
    Prediction = 0.1,         -- Bullet lead (set to 0 to disable)
    DrawFOV = true            -- Show FOV circle
}

-- FOV Circle Visualization --
local FOVCircle
if SETTINGS.DrawFOV then
    FOVCircle = Instance.new("Frame")
    FOVCircle.Size = UDim2.new(0, SETTINGS.MaxFOV * 5, 0, SETTINGS.MaxFOV * 5)
    FOVCircle.Position = UDim2.new(0.5, -SETTINGS.MaxFOV * 2.5, 0.5, -SETTINGS.MaxFOV * 2.5)
    FOVCircle.BackgroundTransparency = 1
    FOVCircle.BorderColor3 = Color3.new(1, 0, 0)
    FOVCircle.BorderSizePixel = 1
    FOVCircle.AnchorPoint = Vector2.new(0.5, 0.5)
    FOVCircle.Parent = game.CoreGui
    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(1, 0)
    UICorner.Parent = FOVCircle
end

-- Find closest visible target in FOV --
local function getClosestTarget()
    if not LocalPlayer.Character then return nil end
    local myHead = LocalPlayer.Character:FindFirstChild("Head")
    if not myHead then return nil end

    local closestTarget = nil
    local closestDistance = SETTINGS.MaxFOV
    local myPosition = myHead.Position

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and (not SETTINGS.TeamCheck or player.Team ~= LocalPlayer.Team) then
            local character = player.Character
            if character then
                local targetPart = character:FindFirstChild(SETTINGS.AimPart)
                if targetPart then
                    -- Check visibility
                    if SETTINGS.VisibleCheck then
                        local raycastParams = RaycastParams.new()
                        raycastParams.FilterDescendantsInstances = {LocalPlayer.Character, character}
                        raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
                        local raycastResult = workspace:Raycast(myPosition, (targetPart.Position - myPosition).Unit * 1000, raycastParams)
                        if raycastResult and raycastResult.Instance:IsDescendantOf(character) == false then
                            continue
                        end
                    end

                    -- Calculate angle
                    local direction = (targetPart.Position - myPosition).Unit
                    local angle = math.deg(math.acos(direction:Dot(Camera.CFrame.LookVector)))
                    
                    -- Check if within FOV and closest
                    if angle < closestDistance then
                        closestDistance = angle
                        closestTarget = targetPart
                    end
                end
            end
        end
    end

    return closestTarget
end

-- Smooth aiming function --
local function aimAt(target)
    if not target then return end
    
    -- Add prediction if enabled
    local targetPosition = target.Position
    if SETTINGS.Prediction > 0 then
        local character = target.Parent
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            local velocity = target.AssemblyLinearVelocity
            targetPosition = targetPosition + (velocity * SETTINGS.Prediction)
        end
    end

    -- Smooth aiming
    local currentLook = Camera.CFrame.LookVector
    local desiredLook = (targetPosition - Camera.CFrame.Position).Unit
    local smoothedLook = currentLook:Lerp(desiredLook, 1 - SETTINGS.Smoothing)
    
    Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, Camera.CFrame.Position + smoothedLook)
end

-- Main loop --
RunService.RenderStepped:Connect(function()
    if not SETTINGS.Enabled then return end
    
    local target = getClosestTarget()
    if target then
        aimAt(target)
    end
end)

-- Toggle with RightShift --
UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.RightShift then
        SETTINGS.Enabled = not SETTINGS.Enabled
        if FOVCircle then
            FOVCircle.Visible = SETTINGS.Enabled
        end
    end
end)

local Camera = workspace.CurrentCamera
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local Holding = false

_G.AimbotEnabled = true
_G.TeamCheck = false -- If set to true then the script would only lock your aim at enemy team members.
_G.AimPart = "Head" -- Where the aimbot script would lock at.
_G.Sensitivity = 0 -- How many seconds it takes for the aimbot script to officially lock onto the target's aimpart.

_G.CircleSides = 64 -- How many sides the FOV circle would have.
_G.CircleColor = Color3.fromRGB(255, 255, 255) -- (RGB) Color that the FOV circle would appear as.
_G.CircleTransparency = 0.7 -- Transparency of the circle.
_G.CircleRadius = 80 -- The radius of the circle / FOV.
_G.CircleFilled = false -- Determines whether or not the circle is filled.
_G.CircleVisible = true -- Determines whether or not the circle is visible.
_G.CircleThickness = 0 -- The thickness of the circle.

local FOVCircle = Drawing.new("Circle")
FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
FOVCircle.Radius = _G.CircleRadius
FOVCircle.Filled = _G.CircleFilled
FOVCircle.Color = _G.CircleColor
FOVCircle.Visible = _G.CircleVisible
FOVCircle.Radius = _G.CircleRadius
FOVCircle.Transparency = _G.CircleTransparency
FOVCircle.NumSides = _G.CircleSides
FOVCircle.Thickness = _G.CircleThickness

local function GetClosestPlayer()
	local MaximumDistance = _G.CircleRadius
	local Target = nil

	for _, v in next, Players:GetPlayers() do
		if v.Name ~= LocalPlayer.Name then
			if _G.TeamCheck == true then
				if v.Team ~= LocalPlayer.Team then
					if v.Character ~= nil then
						if v.Character:FindFirstChild("HumanoidRootPart") ~= nil then
							if v.Character:FindFirstChild("Humanoid") ~= nil and v.Character:FindFirstChild("Humanoid").Health ~= 0 then
								local ScreenPoint = Camera:WorldToScreenPoint(v.Character:WaitForChild("HumanoidRootPart", math.huge).Position)
								local VectorDistance = (Vector2.new(UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y) - Vector2.new(ScreenPoint.X, ScreenPoint.Y)).Magnitude
								
								if VectorDistance < MaximumDistance then
									Target = v
								end
							end
						end
					end
				end
			else
				if v.Character ~= nil then
					if v.Character:FindFirstChild("HumanoidRootPart") ~= nil then
						if v.Character:FindFirstChild("Humanoid") ~= nil and v.Character:FindFirstChild("Humanoid").Health ~= 0 then
							local ScreenPoint = Camera:WorldToScreenPoint(v.Character:WaitForChild("HumanoidRootPart", math.huge).Position)
							local VectorDistance = (Vector2.new(UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y) - Vector2.new(ScreenPoint.X, ScreenPoint.Y)).Magnitude
							
							if VectorDistance < MaximumDistance then
								Target = v
							end
						end
					end
				end
			end
		end
	end

	return Target
end

UserInputService.InputBegan:Connect(function(Input)
    if Input.UserInputType == Enum.UserInputType.MouseButton2 then
        Holding = true
    end
end)

UserInputService.InputEnded:Connect(function(Input)
    if Input.UserInputType == Enum.UserInputType.MouseButton2 then
        Holding = false
    end
end)

RunService.RenderStepped:Connect(function()
    FOVCircle.Position = Vector2.new(UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y)
    FOVCircle.Radius = _G.CircleRadius
    FOVCircle.Filled = _G.CircleFilled
    FOVCircle.Color = _G.CircleColor
    FOVCircle.Visible = _G.CircleVisible
    FOVCircle.Radius = _G.CircleRadius
    FOVCircle.Transparency = _G.CircleTransparency
    FOVCircle.NumSides = _G.CircleSides
    FOVCircle.Thickness = _G.CircleThickness

    if Holding == true and _G.AimbotEnabled == true then
        TweenService:Create(Camera, TweenInfo.new(_G.Sensitivity, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {CFrame = CFrame.new(Camera.CFrame.Position, GetClosestPlayer().Character[_G.AimPart].Position)}):Play()
    end
end)
