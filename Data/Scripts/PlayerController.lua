-- Custom 
local NETWORKED_OBJ = script:GetCustomProperty("Networked"):WaitForObject() ---@type Folder

-- API 
local IK_API = require(script:GetCustomProperty("IK_API"))
local ENCODER_API = require(script:GetCustomProperty("EncoderAPI"))

local animations = {}
local listeners = {}

function DecodeKeyFrame(message)
    local kf = {}
    local misc = ENCODER_API.DecodeMisc(message:sub(1, 1))
    kf.active = misc[1]
    kf.rxl = misc[2]
    kf.ryl = misc[3]
    kf.rzl = misc[4]
    local signTable = ENCODER_API.DecodePosAndOffsetSigns(message:sub(2, 2))
    local x = ENCODER_API.DecodeDecimal(message:sub(3, 5))
    local y = ENCODER_API.DecodeDecimal(message:sub(6, 8))
    local z = ENCODER_API.DecodeDecimal(message:sub(9, 11))
    kf.position = Vector3.New(signTable[1] and x or -x, signTable[2] and y or -y, signTable[3] and z or -z)
    x = ENCODER_API.DecodeDecimal(message:sub(12, 14))
    y = ENCODER_API.DecodeDecimal(message:sub(15, 17))
    z = ENCODER_API.DecodeDecimal(message:sub(18, 20))
    kf.offset = Vector3.New(signTable[4] and x or -x, signTable[5] and y or -y, signTable[6] and z or -z)
    x = ENCODER_API.DecodeDecimal(message:sub(21, 23))
    y = ENCODER_API.DecodeDecimal(message:sub(24, 26))
    z = ENCODER_API.DecodeDecimal(message:sub(27, 29))
    kf.rotation = Rotation.New(x > 180 and -(360 - x) or x, y > 180 and - (360 - y) or y, z > 180 and - (360 - z) or z )
    kf.time = ENCODER_API.DecodeDecimal(message:sub(30, 32))
    kf.weight = CoreMath.Round(ENCODER_API.DecodeNetwork(message:sub(33, 34)) / 1000, 3)
    kf.blendIn = ENCODER_API.DecodeDecimal(message:sub(35, 37))
    kf.blendOut = ENCODER_API.DecodeDecimal(message:sub(38, 40))
    return kf
end

function SendAnimations(player)
    local encodedTable = {}
    for _, tbl in ipairs(animations[player]) do
        table.insert(encodedTable, ENCODER_API.EncodeByte(#tbl.name))
        table.insert(encodedTable, tbl.name)
    end
    NETWORKED_OBJ:SetCustomProperty(player.serverUserData.nProp,  table.concat(encodedTable, ""))
end

function DecodeFromStorage(player, data)
    animations[player] = {}
    for _, animation in ipairs(data) do
        local entry = {}
        entry.name = animation.name
        entry.maxTime = animation.maxTime
        entry.timeScale = animation.timeScale
        entry.keyFrames = {}
        for _, anchor in ipairs(animation.keyFrames) do
            --[[
            if type(anchor) == "table" then
                local animationTable = {{name="animation1", maxTime = 10, timeScale = 1, keyFrames = {{}, {}, {}, {}, {}}},
                {name="animation 2", maxTime = 20, timeScale = 2, keyFrames = {{}, {}, {}, {}, {}}},
                {name="animation 3" , maxTime = 15, timeScale = 3, keyFrames = {{}, {}, {}, {}, {}}}}
                animations[player] = animationTable
                local persistent = Storage.GetPlayerData(player)
                persistent.animations = nil
                Storage.SetPlayerData(player, persistent)
                return
            end]]
            local keyFrames = {}
            local index = 1
            local size = ENCODER_API.DecodeNetwork(anchor:sub(1, 2))
            index = index + 2
            if size > 0 then
                for i= 1, size do
                    table.insert(keyFrames, DecodeKeyFrame(anchor:sub(index, index + 39)))
                    index = index + 40
                end
            end
            table.insert(entry.keyFrames, keyFrames)
        end
        table.insert(animations[player], entry)
    end
end

function LoadAnimation(player, index)
    if #animations[player] < index then
        return
    end
    local animInfo = animations[player][index]
    local kfTable = animInfo.keyFrames
    for i = 1, 5 do
        local keyFrames = kfTable[i]
        IK_API.CreateSortedKFs(player, i, keyFrames)
    end
    player.serverUserData.currentAnimation = index
    IK_API.Status[player].currentTime = 0
    IK_API.Status[player].isPlaying = true
    IK_API.MoveTo(player)
    player:SetPrivateNetworkedData("animNum", index)
    player:SetPrivateNetworkedData("maxTime", animInfo.maxTime)
    player:SetPrivateNetworkedData("currentTime", 0)
    player.movementControlMode = MovementControlMode.NONE
    player.isMovementEnabled = false
    player.maxJumpCount = 0
end

function StopAnimation(player)
    player:SetPrivateNetworkedData("animNum", 0)
    player:SetPrivateNetworkedData("currentTime", 0)
    IK_API.Status[player].currentTime = 0
    IK_API.Status[player].isPlaying = false
    player.serverUserData.currentAnimation = nil
    for _, anchor in ipairs(player:GetIKAnchors()) do
        anchor:Deactivate()
    end
    player.movementControlMode = player.serverUserData.originalMovement
    player.isMovementEnabled = true
    player.maxJumpCount = player.serverUserData.maxJumps
end

function GetCurrentAnimation(player)
    return animations[player][player.serverUserData.currentAnimation]
end

function GetNumber()
    local table = {}
    local val = nil
    for _, player in ipairs(Game.GetPlayers()) do
        val = player.serverUserData.pID
        if val ~= nil then
            table[val] = 1
        end
    end
    for i = 1, 8 do -- change if more players
        if table[i] == nil then
            return i
        end
    end
    return -1
end

local properties = {"P1", "P2", "P3", "P4", "P5", "P6", "P7", "P8"}
function NumberToPropertyName(number)
    if number > 0 and number < 9 then
        return properties[number]
    end
    return nil
end

local numKeys = {}
for i= 1, 9 do
    table.insert(numKeys, "ability_extra_"..tostring(i))
end
function KeyPressed(player, key)
    for i, val in ipairs(numKeys) do
        if val == key then
            if player:GetPrivateNetworkedData("animNum") == i then
                StopAnimation(player)
            else
                LoadAnimation(player, i)
            end
            return
        end
    end
end

function Join(player)
    player.serverUserData.originalMovement = player.movementControlMode
    player.serverUserData.maxJumps = player.maxJumpCount
    animations[player] = {}
    local persistent = Storage.GetPlayerData(player)
    local num = GetNumber()
    player.serverUserData.pID = num
    player.serverUserData.nProp = NumberToPropertyName(num)
    player:SetPrivateNetworkedData("pID", num)
    player:SetPrivateNetworkedData("propName", player.serverUserData.nProp)
    player:SetPrivateNetworkedData("animNum", 0)
    player:SetPrivateNetworkedData("maxTime", 0)
    player:SetPrivateNetworkedData("currentTime", 0)
    --DEBUG
    --persistent = {}
    if not persistent.animations then
        local animationTable = {{name="animation1", maxTime = 10, timeScale = 1, keyFrames = {{}, {}, {}, {}, {}}},
        {name="animation 2", maxTime = 20, timeScale = 2, keyFrames = {{}, {}, {}, {}, {}}},
        {name="animation 3" , maxTime = 15, timeScale = 3, keyFrames = {{}, {}, {}, {}, {}}}}
        animations[player] = animationTable
    else
        DecodeFromStorage(player, persistent.animations)
    end
    player.serverUserData.currentAnimation = nil
    listeners[player] = {}
    listeners[player].binding = player.bindingReleasedEvent:Connect(KeyPressed)
    SendAnimations(player)
end

function Leave(player)
    animations[player] = nil
    listeners[player].binding:Disconnect()
    listeners[player] = nil
    NETWORKED_OBJ:SetCustomProperty(player.serverUserData.nProp,  "")
end

function Tick(deltaTime)
    for _, player in ipairs(Game.GetPlayers()) do
        local status = IK_API.Status[player]
        if status.isPlaying and player.serverUserData.currentAnimation then
            local maxTime = GetCurrentAnimation(player).maxTime
            status.currentTime = status.currentTime + deltaTime
            if status.currentTime > maxTime then
                StopAnimation(player)
            else
                IK_API.UpdateAnchors(player, status.currentTime)
                player:SetPrivateNetworkedData("currentTime", status.currentTime)
            end
        end
    end
end

Game.playerJoinedEvent:Connect(Join)
Game.playerLeftEvent:Connect(Leave)



