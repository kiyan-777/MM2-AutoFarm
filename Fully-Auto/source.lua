--Made By Zynic btw dont use it, its in testing and its not like i get a log of your errors so dont

if not httpget then
    return print("You're executor [" .. identifyexecutor() .. "] cannot run this")
end

------------------------------------------------------------------------------------------------

-- State variables
local Octree = loadstring(httpget("https://raw.githubusercontent.com/Sleitnick/rbxts-octo-tree/main/src/init.lua", true))()
local library = loadstring(httpget("https://raw.githubusercontent.com/Zyn-ic/MM2-AutoFarm/refs/heads/main/UI-Library/XSX.lua", true))()
local Notif = library:InitNotifications()

local rt = {} -- Removable table
rt.__index = rt
rt.octree = Octree.new()

getgenv().RoundInProgress = false

rt.player = game.Players.LocalPlayer

rt.coinContainer = nil
rt.radius = 200 :: number -- Radius to search for coins
rt.walkspeed = 33 :: number -- speed at which you will go to a coin measured in walkspeed
rt.touchedCoins = {} -- Table to track touched coins
rt.positionChangeConnections = setmetatable({}, { __mode = "v" }) -- Weak table for connections
rt.Added = nil :: RBXScriptConnection
rt.Removing = nil :: RBXScriptConnection

rt.UserDied = nil :: RBXScriptConnection

local State = {
    Action = "Action",
    StandStillWait = "StandStillWait",
    WaitingForRound = "WaitingForRound",
    WaitingForRoundEnd = "WaitingForRoundEnd",
    RespawnState = "RespawnState"
}

local CurrentState = State.WaitingForRound
local LastPosition = nil
local RoundInProgress = function()
    return getgenv().RoundInProgress
end
local BagIsFull = false

-- Constants
rt.RoleTracker1 = nil :: RBXScriptConnection
rt.RoleTracker2 = nil :: RBXScriptConnection
rt.InvalidPos = nil :: RBXScriptConnection
local IsMurderer = false
local Working = false
local ROUND_TIMER = workspace:WaitForChild("RoundTimerPart").SurfaceGui.Timer
local PLAYER_GUI = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")

----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
function rt:Character () : (Model)
    return self.player.Character or self.player.CharacterAdded:Wait()
end

function rt:CheckIfPlayerIsInARound () : (boolean)
    --check if player is in a round
    --check by going to the players gui -> MainGui -> Game -> Timer.Visible
    if not PLAYER_GUI:WaitForChild("MainGUI") then return false end

    if PLAYER_GUI:WaitForChild("MainGUI").Game.Timer.Visible then
        return true
    end

    --check by going to the players gui -> MainGui -> Game -> EarnedXP.Visible
    if PLAYER_GUI:WaitForChild("MainGUI").Game.EarnedXP.Visible then
        return true
    end

    return false
end

function rt:MainGUI () : (ScreenGui)
    return self.player.PlayerGui.MainGUI or self.player.PlayerGui:WaitForChild("MainGUI")
end

function rt.Disconnect (connection:RBXScriptConnection)
    if connection and connection.Connected then
        connection:Disconnect()
    end
end

function rt:Map () : (Model | nil)
    for _, v in workspace:GetDescendants() do
        if v.Name == "Spawns" and v.Parent.Name ~= "Lobby"  then
            return v.Parent
        end
    end
    return nil
end

function rt:CheckIfPlayerWasInARound () : (boolean)
    if self.player:GetAttribute("Alive") then
        return true
    end

    return false
end

function rt:IsElite() : (boolean)
    if self.player:GetAttribute("Elite") then
        return true
    end

    return false
end

local function AutoFarmCleanUp()
    if next(rt.positionChangeConnections) == nil then
        return Notif:Notify("Nothing to Clean Up", 1.5, "information")
    end

    -- Clean up all connections and cached data
    for _, connection in pairs(rt.positionChangeConnections) do
        rt.Disconnect(connection)
    end
    rt.Disconnect(rt.Added)
    rt.Disconnect(rt.Removing)

    Notif:Notify("AutoFarm cleanup complete!", 1.5, "success")
    table.clear(rt.touchedCoins)
    table.clear(rt.positionChangeConnections)
    rt.octree:ClearAllNodes()
end

-- Function to check if a coin has been touched
local function isCoinTouched(coin)
    return rt.touchedCoins[coin]
end

-- Function to mark a coin as touched
local function markCoinAsTouched(coin)
    if not rt then return end
    rt.touchedCoins[coin] = true
    local node = rt.octree:FindFirstNode(coin)
    if node then
        rt.octree:RemoveNode(node)
    end
end

-- Function to track touch interactions
local function setupTouchTracking(coin)
    
    local touchInterest = coin:FindFirstChildWhichIsA("TouchTransmitter")
    if touchInterest then
        local connection
        connection = touchInterest.AncestryChanged:Connect(function(_, parent)
            if not rt then connection:Disconnect() return end
            if parent == nil then
                -- TouchInterest removed; mark the coin as touched
                markCoinAsTouched(coin)
                rt.Disconnect(connection)
            end
        end)
        rt.positionChangeConnections[coin] = connection
    end
end

local function setupPositionTracking(coin: MeshPart, LastPositonY: number)
    local connection
    connection = coin:GetPropertyChangedSignal("Position"):Connect(function()
        -- Check if the Y position has changed
        local currentY = coin.Position.Y
        if LastPositonY and LastPositonY ~= currentY then

            -- Remove the coin from the octree as it has been moved
            markCoinAsTouched(coin)

            rt.Disconnect(connection)
            coin:Destroy()
            return
        end
    end)
    rt.positionChangeConnections[coin] = connection
end

local function moveToPositionSlowly(targetPosition: Vector3, duration: number)
    local startPosition = rt:Character().PrimaryPart.Position
    local startTime = tick()
    
    while true do
        local elapsedTime = tick() - startTime
        local alpha = math.min(elapsedTime / duration, 1)
        rt:Character():PivotTo(CFrame.new(startPosition:Lerp(targetPosition, alpha)))

        if alpha >= 1 then
            task.wait(0.2)
            break
        end

        task.wait(0.02) -- Small delay to make the movement smoother
    end
end
-- Function to populate the Octree with coins
local function populateOctree()
    rt.octree:ClearAllNodes() -- Clear previous nodes

    for _, descendant in pairs(rt.coinContainer:GetDescendants()) do
        if descendant:IsA("TouchTransmitter") then --and descendant.Material == rt.Material then
            local parentCoin = descendant.Parent
            if not isCoinTouched(parentCoin) then
                rt.octree:CreateNode(parentCoin.Position, parentCoin)
                setupTouchTracking(parentCoin)
            end
            setupPositionTracking(parentCoin, parentCoin.Position.Y)
        end
    end

    rt.Added = rt.coinContainer.DescendantAdded:Connect(function(descendant)
        if descendant:IsA("TouchTransmitter") then --and descendant.Material == rt.Material then
            local parentCoin = descendant.Parent
            if not isCoinTouched(parentCoin) then
                rt.octree:CreateNode(parentCoin.Position, parentCoin)
                setupTouchTracking(parentCoin)
                setupPositionTracking(parentCoin, parentCoin.Position.Y)
            end
        end
    end)

    rt.Removing = rt.coinContainer.DescendantRemoving:Connect(function(descendant)
        if descendant:IsA("TouchTransmitter") and descendant.Parent.Name == "Coin_Server" then
            local parentCoin = descendant.Parent
            if isCoinTouched(parentCoin) then
                markCoinAsTouched(parentCoin)
            end
        end
    end)
end

local function ChangeState(State)
    CurrentState = State
end
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------

-- Helper Functions

local function CheckMurderer()
    return IsMurderer
end

local function IsBagFull()
    local playerGui = PLAYER_GUI:WaitForChild("MainGUI")
    local coinText = playerGui.Game.CoinBags.Container.SnowToken.CurrencyFrame.Icon.Coins.Text
    return tonumber(coinText) >= (rt:IsElite() and 50 or 40)
end

local function RespawnAndTeleportBack()
    LastPosition = LastPosition ~= nil and LastPosition or rt:Character():GetPivot()
    rt:Character():FindFirstChildWhichIsA("Humanoid"):ChangeState(Enum.HumanoidStateType.Dead)
    repeat task.wait() until rt.player.CharacterAdded:Wait()
    task.wait(1)
    rt:Character():PivotTo(LastPosition)
end

local function CollectCoins()
    Working = true
    rt.coinContainer = rt:Map():FindFirstChild("CoinContainer")
    populateOctree()
    while CurrentState == State.Action do
        if IsBagFull() then
            Notif:Notify("Bag is full!", 2, "success")
            BagIsFull = true
            break
        end

        -- Find nearest coin
        local nearestNode = rt.octree:GetNearest(rt:Character().PrimaryPart.Position, rt.radius, 1)[1]
        if nearestNode then
            local closestCoin = nearestNode.Object
            if not isCoinTouched(closestCoin) then
                local targetPosition = closestCoin.Position
                local duration = (rt:Character().PrimaryPart.Position - targetPosition).Magnitude / rt.walkspeed
                moveToPositionSlowly(targetPosition, duration)
                markCoinAsTouched(closestCoin)
                task.wait(0.2)
            end
        else
            task.wait(1)
        end
    end
    AutoFarmCleanUp()
end

local function RespawnState()
    Notif:Notify("Respawning...", 2, "info")
    repeat task.wait() until rt.player.CharacterAdded:Wait()
    task.wait(1)
    rt.player.Character:PivotTo(LastPosition)
    Notif:Notify("Respawned!", 2, "success")

    if not RoundInProgress() then
        Notif:Notify("Round ended during respawn!", 2, "info")
        ChangeState(State.WaitingForRound)
        return
    end

    ChangeState(State.Action)
end

-- Waiting State Logic
local function WaitingForRound()
    Notif:Notify("Waiting for round to start...", 2, "info")
    Working = false
    --rt:Character():FindFirstChildWhichIsA("Humanoid"):ChangeState(Enum.HumanoidStateType.Seated)
   -- Monitor round start
    repeat
        task.wait(0.5)
    until RoundInProgress() and rt:CheckIfPlayerWasInARound()

    Notif:Notify("Round started!", 2, "success")
    ChangeState(State.Action)
end

local function waitForRoundEnd()
    Notif:Notify("Waiting for round to end...", 2, "info")
    Working = false
    --rt:Character():FindFirstChildWhichIsA("Humanoid"):ChangeState(Enum.HumanoidStateType.Seated)
    -- Monitor round end
    repeat
        task.wait(1)
    until not RoundInProgress()

    Notif:Notify("Round ended!", 2, "success")
    ChangeState(State.WaitingForRound)
end

local function StandStillWait()
    Notif:Notify("Waiting for murderer to respawn", 2, "info")
    ChangeState("Nothing")
    repeat
        task.wait(1)
    until rt.player.CharacterAdded:Wait()
    task.wait(1)
    ChangeState(State.WaitingForRound)
end

-- Action State Logic
local function ActionState()
    LastPosition = nil
    if CheckMurderer() then
        Notif:Notify("You are the Murderer! Collecting coins...", 2, "success")
        CollectCoins()
    else
        Notif:Notify(". Logging position and respawning...", 2, "information")
        if #game.Players:GetChildren() > 2 then RespawnAndTeleportBack(); CollectCoins() else CollectCoins() end
    end

    -- After collecting coins or if the round ends, return to waiting state
    if BagIsFull or not RoundInProgress() then
        if CheckMurderer() then
            Notif:Notify("Returning to Waiting State...", 2, "info")
            BagIsFull, Working, getgenv().RoundInProgress = false, false, false
            rt:Character():FindFirstChildWhichIsA("Humanoid"):ChangeState(Enum.HumanoidStateType.Dead)
        else
            Notif:Notify("Returning to Waiting State...", 2, "info")
            BagIsFull, Working = false, false
            rt:Character():FindFirstChildWhichIsA("Humanoid"):ChangeState(Enum.HumanoidStateType.Dead)
            ChangeState(State.WaitingForRoundEnd)
        end
    end
    
end

----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
rt.RoleTracker1 = rt.player.DescendantAdded:Connect(function(descendant)
    if descendant:IsA("Tool") then
        if descendant.Name == "Knife" then
            IsMurderer = true
        end
    end
end)

rt.InvalidPos = workspace.DescendantAdded:Connect(function(descendant)
    if descendant:IsA("Model") then
        if string.match(descendant.Name, "Glitch") and descendant.Parent.Name ~= "Lobby" then
            descendant:Destroy()
        end

        if string.match(descendant.Name, "Invis") and descendant.Parent.Name ~= "Lobby" then
            descendant:Destroy()
        end
    end
end)

 -- Monitor round start
local LastText
ROUND_TIMER:GetPropertyChangedSignal("Text"):Connect(function()
    getgenv().RoundInProgress = true
end)

PLAYER_GUI.ChildAdded:Connect(function(child)
    if child:IsA("Sound") then
        getgenv().RoundInProgress = false
        Working = false
        ChangeState(State.WaitingForRound)
    end
end)

rt.UserDied = rt.player.CharacterRemoving:Connect(function(character)
    AutoFarmCleanUp()
    LastText = ROUND_TIMER.Text
    if CheckMurderer() then IsMurderer = false; LastPosition = nil; Working = false; getgenv().RoundInProgress = false return ChangeState(State.StandStillWait) end
    
    if not RoundInProgress() then IsMurderer = false; LastPosition = nil; Working = false; return ChangeState(State.WaitingForRound) end

    task.wait(2)
    if LastText == ROUND_TIMER.Text then LastPosition = nil; IsMurderer = false; getgenv().RoundInProgress = false; Working = false return ChangeState(State.WaitingForRound) end

    if Working then
        Working = false
        ChangeState(State.RespawnState)
    end
end)

----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------

IsMurderer = rt.player.Backpack:FindFirstChild("Knife") and true or false   


-- Main Loop
while true do
    if CurrentState == State.WaitingForRound then
        WaitingForRound()
    elseif CurrentState == State.Action then
        ActionState()
    elseif CurrentState == State.WaitingForRoundEnd then
        waitForRoundEnd()
    elseif CurrentState == State.RespawnState then
        RespawnState()
    elseif CurrentState == State.StandStillWait then
        StandStillWait()
    end
    task.wait()
end


---------------------------------------------------------------------------------------------------------
--if the sound doesnt play when the murderer dies run getgenv().RoundInProgress = false
