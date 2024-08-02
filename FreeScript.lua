-- StarterPlayerScripts/CoinCollectorScript.lua

local Octree = loadstring(game:HttpGet("https://raw.githubusercontent.com/Sleitnick/rbxts-octo-tree/main/src/init.lua", true))()
local rt = {} -- removeable table
rt.Players = game:GetService("Players")
rt.player = rt.Players.LocalPlayer

function rt.Character()
    return rt.player.Character or rt.player.CharacterAdded:Wait()
end

rt.coinContainer = nil
rt.octree = Octree.new()
rt.radius = 80 -- Radius to search for coins

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

-- Function to move the player slowly to a given position
local function moveToPositionSlowly(targetPosition, duration)
        rt.humanoidRootPart = rt.Character():WaitForChild("HumanoidRootPart")
        local startPosition = rt.humanoidRootPart.Position
        local startTime = tick()

        -- Set character parts to be non-collidable and add BodyPosition
        setCharacterCollision(rt.Character(), false)
        local bodyPosition = addBodyPosition(rt.Character())

        while true do
            local elapsedTime = tick() - startTime
            local alpha = math.min(elapsedTime / duration, 1)
            rt.humanoidRootPart.CFrame = CFrame.new(startPosition:Lerp(targetPosition, alpha))

            -- Check if we have reached the target position or time is up
            if alpha >= 1 then
                task.wait(0.9)
                break
            end

            task.wait() -- Small delay to make the movement smoother
        end

        -- Restore character parts to be collidable and remove BodyPosition
        bodyPosition:Destroy()
        setCharacterCollision(rt.Character(), true)
end

-- Function to collect coins
local function collectCoins()
    -- Step 1: Check if CoinContainer is loaded
    rt.coinContainer = game.Workspace:FindFirstChild("Normal"):FindFirstChild("CoinContainer")

    -- Populate the Octree with coins
    local function populateOctree()
        rt.octree:ClearAllNodes() -- Clear previous nodes if necessary
        for _, descendant in pairs(rt.coinContainer:GetDescendants()) do
            if descendant:IsA("MeshPart") and descendant.Material == Enum.Material.Glass then
                rt.octree:CreateNode(descendant.Position, descendant)
            end
        end
    end

    -- Function to handle coin collection
    local function handleCoinCollection()
        -- Update the octree with the current coins
        populateOctree()

        -- Continuously find and move to the closest coin
        while true do
            rt.humanoidRootPart = rt.Character().HumanoidRootPart
            
            -- Coroutine to find the nearest coin
            local nearestCoinCoroutine = coroutine.create(function()
                local nearestNode = rt.octree:GetNearest(rt.humanoidRootPart.Position, rt.radius, 1)[1]
                return nearestNode
            end)

            -- Start the coroutine and get the result
            local success, nearestNode = coroutine.resume(nearestCoinCoroutine)

            if success and nearestNode then
                local closestCoin = nearestNode.Object
                local closestCoinPosition = closestCoin.Position

                -- Coroutine to calculate the distance
                local distanceCoroutine = coroutine.create(function()
                    local distance = (rt.humanoidRootPart.Position - closestCoinPosition).Magnitude
                    return distance
                end)

                -- Start the coroutine and get the result
                local success, distance = coroutine.resume(distanceCoroutine)

                if success then
                    local duration = distance / 26 -- Default walk speed in Roblox is 26 studs/sec
                    moveToPositionSlowly(closestCoinPosition, duration)

                    -- Remove the collected coin from the octree
                    rt.octree:RemoveNode(nearestNode)

                    -- Re-populate the octree if it's empty
                    if #rt.octree:GetAllNodes() == 0 then
                        populateOctree()
                    end
                end
            else
                -- If no coins found, check again after a short delay
                task.wait(1)
                populateOctree()
            end

            task.wait(0.1) -- Short delay before the next iteration
        end
    end

    -- Start the coin collection process
    handleCoinCollection()
end

-- Call the function to start collecting coins
local start = coroutine.create(collectCoins)
coroutine.resume(start)

local died = rt.player.CharacterRemoving:Connect(function()
    -- Clean up memory
    coroutine.close(start)
    rt = nil
    Octree = nil
end)

rt.Players.PlayerRemoving:Connect(function()
    died:Disconnect()
end)
