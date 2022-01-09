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

function SendAnimations(player)
    local encodedTable = {}
    table.insert(encodedTable, ENCODER_API.EncodeByte(1))
    for _, tbl in ipairs(animations[player]) do
        table.insert(encodedTable, ENCODER_API.EncodeByte(#tbl.name))
        table.insert(encodedTable, tbl.name)
    end
    NETWORKED_OBJ:SetCustomProperty("Message",  table.concat(encodedTable, ""))
end

function SendAnimationInfo(animation)

end

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
    local animationTable = {{name="animation1"}, {name="animation TWO"}, {name="Much Longer Name"}}
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

