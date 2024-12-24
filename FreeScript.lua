-- Script made by Zynic

local Octree = loadstring(game:HttpGet("https://raw.githubusercontent.com/Sleitnick/rbxts-octo-tree/main/src/init.lua", true))()
local rt = {} -- Removable table
rt.Players = game:GetService("Players")
rt.player = rt.Players.LocalPlayer

function rt.Character()
    return rt.player.Character or rt.player.CharacterAdded:Wait()
end

function rt.Map()
    for _, v in workspace:GetDescendants() do
        if v:IsA("Model") and v.Name == "Base" then
            return v.Parent
        end
    end
    return nil
end

rt.coinContainer = nil
rt.octree = Octree.new()
rt.radius = 200 -- Radius to search for coins
rt.walkspeed = 30 -- speed at which you will go to a coin measured in walkspeed
rt.positionChangeConnections = {}

-- Function to set the collision state of the character's parts
local function setCharacterCollision(character, state)
    for _, part in pairs(character:GetDescendants()) do
        if part:IsA("BasePart") or part:IsA("MeshPart") then
            part.CanCollide = state
        end
    end
end

-- Function to add BodyPosition to keep the character afloat
local function addBodyPosition(character)
    local bodyPosition = Instance.new("BodyPosition")
    bodyPosition.P = 0 -- Set the power to 0 to prevent the player from falling
    bodyPosition.D = 0 -- Set the dampening to 0 to prevent the player from moving in the Y or Z direction
    bodyPosition.MaxForce = Vector3.new(math.huge, math.huge, math.huge) -- Set the maximum force to prevent the player from moving in the Y or Z direction

    bodyPosition.Parent = character.HumanoidRootPart
    return bodyPosition
end

-- Function to populate the Octree with coins
local function populateOctree()
    rt.octree:ClearAllNodes() -- Clear previous nodes if necessary

    for _, descendant in pairs(rt.coinContainer:GetDescendants()) do
        if descendant:IsA("MeshPart") and descendant.Material == Enum.Material.Ice then
            rt.octree:CreateNode(descendant.Position, descendant)
        end
    end

    rt.coinContainer.DescendantAdded:Connect(function(descendant)
        if descendant:IsA("MeshPart") and descendant.Material == Enum.Material.Ice then
            rt.octree:CreateNode(descendant.Position, descendant)
        end
    end)

    rt.coinContainer.DescendantRemoving:Connect(function(descendant)
        if descendant:IsA("MeshPart") and descendant.Material == Enum.Material.Ice then
            local node = rt.octree:FindFirstNode(descendant)
            if node then
                rt.octree:RemoveNode(node)
            end
        end
    end)
end

-- Function to move the player slowly to a given position
local function moveToPositionSlowly(targetPosition, duration)
    rt.humanoidRootPart = rt.Character():WaitForChild("HumanoidRootPart")
    local startPosition = rt.humanoidRootPart.Position
    local startTime = tick()
    
    -- Set character parts to be non-collidable and add BodyPosition
    
    local bodyPosition = addBodyPosition(rt.Character())

    while true do
        local elapsedTime = tick() - startTime
        local alpha = math.min(elapsedTime / duration, 1)
        rt.humanoidRootPart.CFrame = CFrame.new(startPosition:Lerp(targetPosition, alpha))

        if alpha >= 1 then
            task.wait(0.2)
            break
        end

        task.wait() -- Small delay to make the movement smoother
    end
    bodyPosition:Destroy()
end

-- Function to handle coin collection
local function collectCoins()
    -- Step 1: Check if CoinContainer is loaded
    rt.coinContainer = rt.Map():FindFirstChild("CoinContainer")
    assert(rt.coinContainer, "CoinContainer not found in the map!")
    setCharacterCollision(rt.Character(), false)
    populateOctree() -- Ensure the octree is updated
    while true do
       
        -- Continuously find and move to the closest coin
        local nearestNode = rt.octree:GetNearest(rt.Character().HumanoidRootPart.Position, rt.radius, 1)[1]

        if nearestNode then
            local closestCoin = nearestNode.Object
            local closestCoinPosition = closestCoin.Position
            local distance = (rt.Character().HumanoidRootPart.Position - closestCoinPosition).Magnitude
            local duration = distance / 28 -- Default walk speed in Roblox is 26 studs/sec

            moveToPositionSlowly(closestCoinPosition, duration)

            -- Remove the collected coin from the octree and destroy it
            rt.octree:RemoveNode(nearestNode)
            closestCoin:Destroy()
        else
            -- If no coins found, wait and re-check
            task.wait(1)
        end
    end
end

-- Call the function to start collecting coins
local start = coroutine.create(collectCoins)
coroutine.resume(start)

-- Clean up when the player dies or leaves
local died = rt.player.CharacterRemoving:Connect(function()
    coroutine.close(start)
    rt = nil
    Octree = nil
end)

rt.Players.PlayerRemoving:Connect(function()
    died:Disconnect()
end)
