-- Custom 
local NETWORKED_OBJ = script:GetCustomProperty("NetworkedObj"):WaitForObject() ---@type Folder

-- API 
local EDITOR_API = require(script:GetCustomProperty("EditorAPI"))
local ENCODER_API = require(script:GetCustomProperty("EncoderAPI"))

local animations = {}
local listeners = {}

--[[
    Properties of key frame
    {timelinePosition, active, position, rotation, weight, blendIn, blendout, offset}
]]
local sample = {
    timeline = 30.111,
    position = Vector3.New(10, 10, 10),
    rotation = Rotation.New(-30, 90, 20),
    offset = Vector3.New(0, 25, 0),
    weight = 0.95,
    blendIn = 0.35,
    blendOut = 0.201,
    active = true
}

function EncodeKeyFrame(kf)
    local tbl = {}
    table.insert(tbl, ENCODER_API.EncodeByte(kf.active and 1 or 0))
    local pos = kf.position
    local offset = kf.offset
    table.insert(tbl, ENCODER_API.EncodePosAndOffsetSigns(pos, offset))
    table.insert(tbl, ENCODER_API.EncodeDecimal(math.abs(pos.x)))
    table.insert(tbl, ENCODER_API.EncodeDecimal(math.abs(pos.y)))
    table.insert(tbl, ENCODER_API.EncodeDecimal(math.abs(pos.z)))
    table.insert(tbl, ENCODER_API.EncodeDecimal(math.abs(offset.x)))
    table.insert(tbl, ENCODER_API.EncodeDecimal(math.abs(offset.y)))
    table.insert(tbl, ENCODER_API.EncodeDecimal(math.abs(offset.z)))
    local rot = kf.rotation
    table.insert(tbl, ENCODER_API.EncodeDecimal(rot.x < 0 and rot.x + 360 or rot.x))
    table.insert(tbl, ENCODER_API.EncodeDecimal(rot.y < 0 and rot.y + 360 or rot.y))
    table.insert(tbl, ENCODER_API.EncodeDecimal(rot.z < 0 and rot.z + 360 or rot.z))
    table.insert(tbl, ENCODER_API.EncodeDecimal(kf.timeline))
    table.insert(tbl, ENCODER_API.EncodeNetwork(math.floor(kf.weight * 1000)))
    table.insert(tbl, ENCODER_API.EncodeDecimal(kf.blendIn))
    table.insert(tbl, ENCODER_API.EncodeDecimal(kf.blendOut))
    return table.concat(tbl, "")
end

function SendAnimations(player)
    local encodedTable = {}
    table.insert(encodedTable, ENCODER_API.EncodeByte(1))
    for _, tbl in ipairs(animations[player]) do
        table.insert(encodedTable, ENCODER_API.EncodeByte(#tbl.name))
        table.insert(encodedTable, tbl.name)
    end
    NETWORKED_OBJ:SetCustomProperty("Message",  table.concat(encodedTable, ""))
end

function SendAnimationInfo()
    local encodedTable = {}
    table.insert(encodedTable, ENCODER_API.EncodeByte(2))
    for i = 1, 6 do
        table.insert(encodedTable, ENCODER_API.EncodeNetwork(2))
        for j = 1, 2 do
            table.insert(encodedTable, EncodeKeyFrame(sample))
        end
    end
    NETWORKED_OBJ:SetCustomProperty("Message",  table.concat(encodedTable, ""))
end

Task.Spawn(
    function()
        Task.Wait(3)
        SendAnimationInfo()
    end
)

function HandleGetAnimations(player)
    SendAnimations(player)
end

function HandleNewAnimation(player, animName)
   table.insert(animations[player], {name=animName})
end

function HandleDeleteAnimation(player, index)
    table.remove(animations[player], index)
end

function HandleChangeAnimationName(player, index, newName)
    local prop = animations[player][index]
    prop.name = newName
    print("New name: "..prop.name)
end

function HandleChangeTimeScale(player, index, scale)
    local animation = animations[player][index]
    animation.timeScale = scale
end

function HandleChangeMaxTime(player, index, maxTime)
    local animation = animations[player][index]
    animation.maxtime = maxTime
    for _, anchor in animation do
        for i, kf in ipairs(anchor) do
            kf.time = math.min(kf.time, maxTime)
        end
    end
end

local DEFAULT_KF = {
    time = 0,
    position = Vector3.New(0, 0, 0),
    rotation = Rotation.New(0, 0, 0),
    offset = Vector3.New(0, 0, 0),
    weight = 1,
    blendIn = 0,
    blendOut = 0,
    active = true
}

function DuplicateKeyFrame(original)
    local kf = {}
    kf.time = original.time
    kf.position = original.position
    kf.rotation = original.rotation
    kf.offset = original.offset
    kf.weight = original.weight
    kf.blendIn = original.blendIn
    kf.blendOut = original.blendOut
    kf.active = original.active
    return kf
end

local sample = {
    time = 30.111,
    position = Vector3.New(10, 10, 10),
    rotation = Rotation.New(-30, 90, 20),
    offset = Vector3.New(0, 25, 0),
    weight = 0.95,
    blendIn = 0.35,
    blendOut = 0.201,
    active = true
}

function HandleKFTime(player, i, j, time)
    local kf = animations[player][i][j]
    kf.time = time
end

function HandleKFPosition(player, i, j, position)
    local kf = animations[player][i][j]
    kf.position = position
end

function HandleKFRotation(player, i, j, rotation)
    local kf = animations[player][i][j]
    kf.rotation = rotation
end

function HandleKFOffset(player, i, j, offset)
    local kf = animations[player][i][j]
    kf.offset = offset
end

function HandleKFWeight(player, i, j, weight)
    local kf = animations[player][i][j]
    kf.weight = weight
end

function HandleKFBlendIn(player, i, j, blendIn)
    local kf = animations[player][i][j]
    kf.blendIn = blendIn
end

function HandleKFBlendOut(player, i, j, blendOut)
    local kf = animations[player][i][j]
    kf.blendOut = blendOut
end

function HandleKFActive(player, i, j, active)
    local kf = animations[player][i][j]
    kf.active = active
end

function HandleCreateKF(player, i, time)
    local kf = DuplicateKeyFrame(DEFAULT_KF)
    table.insert(animations[player][i], kf)
    kf.time = CoreMath.Round(time, 3)
    print(time)
end

function HandleDuplicateKF(player, i, from)
    local anchor = animations[player][i]
    table.insert(anchor, DuplicateKeyFrame(anchor[from]))
end

function HandleDeleteKF(player, i, j)
    local anchor = animations[player][i]
    table.remove(anchor, j)
end

function Join(player)
    animations[player] = {}
    local animationTable = {{name="animation1", maxTime = 10, timeScale = 1, }, {name="animation TWO"}, {name="Much Longer Name"}}
    animations[player] = animationTable
end

function Leave(player)
    animations[player] = nil
end

Game.playerJoinedEvent:Connect(Join)
Game.playerLeftEvent:Connect(Leave)

Events.ConnectForPlayer("GetAnimations", HandleGetAnimations)
Events.ConnectForPlayer("NewAnimation", HandleNewAnimation)
Events.ConnectForPlayer("DeleteAnimation", HandleDeleteAnimation)
Events.ConnectForPlayer("ChangeAnimationName", HandleChangeAnimationName)
Events.ConnectForPlayer("ChangeAnimationTimeScale", HandleChangeTimeScale)
Events.ConnectForPlayer("ChangeAnimationMaxTime", HandleChangeMaxTime)
Events.ConnectForPlayer("UpdateKFTime", HandleKFTime)
Events.ConnectForPlayer("UpdateKFPosition", HandleKFPosition)
Events.ConnectForPlayer("UpdateKFTRotation", HandleKFRotation)
Events.ConnectForPlayer("UpdateKFOffset", HandleKFOffset)
Events.ConnectForPlayer("UpdateKFWeight", HandleKFWeight)
Events.ConnectForPlayer("UpdateKFBlendIn", HandleKFBlendIn)
Events.ConnectForPlayer("UpdateKFBlendOut", HandleKFBlendOut)
Events.ConnectForPlayer("UpdateKFActive", HandleKFActive)
Events.ConnectForPlayer("CreateKF", HandleCreateKF)
Events.ConnectForPlayer("DuplicateKF", HandleDuplicateKF)
Events.ConnectForPlayer("DeleteKF", HandleDeleteKF)


