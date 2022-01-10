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
    timelinePosition = 30.111,
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
    table.insert(tbl, ENCODER_API.EncodeDecimal(kf.timelinePosition))
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

function ProcessGetAnimationsRequest(player)
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

