-- Script made by Zynic

local Octree = loadstring(game:HttpGet("https://raw.githubusercontent.com/Sleitnick/rbxts-octo-tree/main/src/init.lua", true))()
local rt = {} -- Removable table
rt.Players = game:GetService("Players")
rt.player = rt.Players.LocalPlayer

rt.coinContainer = nil
rt.octree = Octree.new()
rt.Material = Enum.Material.Ice
rt.TpBackToStart = true
rt.radius = 200 -- Radius to search for coins
rt.walkspeed = 30 -- speed at which you will go to a coin measured in walkspeed
rt.positionChangeConnections = setmetatable({}, {__mode = "v"}) -- Weak table to store position change connectionsS
rt.Added = nil :: RBXScriptConnection
rt.Removing = nil :: RBXScriptConnection
rt.MainGUI = rt.player.PlayerGui.MainGUI or rt.player.PlayerGui:WaitForChild("MainGUI")

function rt:Character() : (Model)
    return self.player.Character or self.player.CharacterAdded:Wait()
end

function rt:Map() : (Model | nil)
    for _, v in workspace:GetDescendants() do
        if v:IsA("Model") and v.Name == "Base" then
            return v.Parent
        end
    end
    return nil
end

function rt.Disconnect(connection:RBXScriptConnection)
    if connection.Connected then
        connection:Disconnect()
    end
end

-- Function to set the collision state of the character's parts
local function setCharacterCollision(character: Model, state:boolean)
    for _, part in pairs(character:GetDescendants()) do
        if part:IsA("BasePart") or part:IsA("MeshPart") then
            part.CanCollide = state
        end
    end
end

-- Function to add BodyPosition to keep the character afloat
local function addBodyPosition(character: Model) : (BodyPosition)
    local bodyPosition = Instance.new("BodyPosition")
    bodyPosition.P = 0 -- Set the power to 0 to prevent the player from falling
    bodyPosition.D = 0 -- Set the dampening to 0 to prevent the player from moving in the Y or Z direction
    bodyPosition.MaxForce = Vector3.new(math.huge, math.huge, math.huge) -- Set the maximum force to prevent the player from moving in the Y or Z direction

    bodyPosition.Parent = character.HumanoidRootPart
    return bodyPosition
end

local function setupPositionTracking(coin: MeshPart, LastPositonY: number)
    local connection
    connection = coin:GetPropertyChangedSignal("Position"):Connect(function()
        -- Check if the Y position has changed
        local currentY = coin.Position.Y
        if LastPositonY and LastPositonY ~= currentY then

            -- Remove the coin from the octree as it has been moved
            local node = rt.octree:FindFirstNode(coin)
            if node then
                rt.octree:RemoveNode(node)
            end

            rt.Disconnect(connection)
            coin:Destroy()
            return
        end
    end)
    rt.positionChangeConnections[coin] = connection
end


local function cleanupPositionTracking()
    for _, connection in pairs(rt.positionChangeConnections) do
        rt.Disconnect(connection)
    end
    rt.positionChangeConnections = nil
end

-- Function to populate the Octree with coins
local function populateOctree()
    rt.octree:ClearAllNodes() -- Clear previous nodes if necessary

    for _, descendant in pairs(rt.coinContainer:GetDescendants()) do
        if descendant:IsA("MeshPart") and descendant.Material == rt.Material then
            rt.octree:CreateNode(descendant.Parent.Position, descendant.Parent)
            setupPositionTracking(descendant.Parent, descendant.Position.Y)
        end
    end

    rt.Added = rt.coinContainer.DescendantAdded:Connect(function(descendant)
        if descendant:IsA("MeshPart") and descendant.Material == rt.Material then
            rt.octree:CreateNode(descendant.Parent.Position, descendant.Parent)
            --setupPositionTracking(descendant, descendant.Position.Y)
        end
    end)

    rt.Removing = rt.coinContainer.DescendantRemoving:Connect(function(descendant)
        if descendant:IsA("MeshPart") then
            local node = rt.octree:FindFirstNode(descendant.Parent)
            if node then
                rt.octree:RemoveNode(node)
            end
        end
    end)
end

-- Function to move the player slowly to a given position
local function moveToPositionSlowly(targetPosition: Vector3, duration: number)
    rt.humanoidRootPart = rt:Character():WaitForChild("HumanoidRootPart")
    local startPosition = rt.humanoidRootPart.Position
    local startTime = tick()
    
    -- Set character parts to be non-collidable and add BodyPosition
    
    local bodyPosition = addBodyPosition(rt:Character())

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
    rt.coinContainer = rt:Map():FindFirstChild("CoinContainer")
    assert(rt.coinContainer, "CoinContainer not found in the map!")
    rt.waypoint = rt:Character().HumanoidRootPart.CFrame
    setCharacterCollision(rt:Character(), false)
    populateOctree() -- Ensure the octree is updated
    while true do
        if rt.MainGUI.Game.CoinBags.Container.SnowToken.FullBagIcon.Visible then
            break
        end
        -- Continuously find and move to the closest coin
        local nearestNode = rt.octree:GetNearest(rt:Character().HumanoidRootPart.Position, rt.radius, 1)[1]

        if nearestNode then
            local closestCoin = nearestNode.Object
            local closestCoinPosition = closestCoin.Position
            local distance = (rt:Character().HumanoidRootPart.Position - closestCoinPosition).Magnitude
            local duration = distance / rt.walkspeed -- Default walk speed in Roblox is 26 studs/sec

            moveToPositionSlowly(closestCoinPosition, duration)

            -- Remove the collected coin from the octree and destroy it
            rt.octree:RemoveNode(nearestNode)
            closestCoin:Destroy() -- safety net just incase the coin isn't destroyed before we get to it here
        else
            -- If no coins found, wait and re-check
            task.wait(1)
        end
    end

    if rt.TpBackToStart then
        rt:Character().HumanoidRootPart.CFrame = rt.waypoint
    end
end

-- Call the function to start collecting coins
local start = coroutine.create(collectCoins)
coroutine.resume(start)

-- Clean up when the player dies or leaves
local died = rt.player.CharacterRemoving:Connect(function()
    coroutine.close(start)
    cleanupPositionTracking()
    rt.Disconnect(rt.Added)
    rt.Disconnect(rt.Removing)
    rt = nil
    Octree = nil
end)

rt.Players.PlayerRemoving:Connect(function()
    died:Disconnect()
end)
