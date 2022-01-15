-- Custom 
local BODY_DEBUG = script:GetCustomProperty("BodyDebug")
local LEFT_FOOT_DEBUG = script:GetCustomProperty("LeftFootDebug")
local LEFT_HAND_DEBUG = script:GetCustomProperty("LeftHandDebug")
local RIGHT_FOOT_DEBUG = script:GetCustomProperty("RightFootDebug")
local RIGHT_HAND_DEBUG = script:GetCustomProperty("RightHandDebug")

local playerIK = {}
function Join(player)
    playerIK[player] = {}
    playerIK[player]["body"] = World.SpawnAsset(BODY_DEBUG, {position = player:GetWorldPosition()})
    playerIK[player]["leftHand"] = World.SpawnAsset(LEFT_HAND_DEBUG, {position = player:GetWorldPosition()})
    playerIK[player]["rightHand"] = World.SpawnAsset(RIGHT_HAND_DEBUG, {position = player:GetWorldPosition()})
    playerIK[player]["leftFoot"] = World.SpawnAsset(LEFT_FOOT_DEBUG, {position = player:GetWorldPosition()})
    playerIK[player]["rightFoot"] = World.SpawnAsset(RIGHT_FOOT_DEBUG, {position = player:GetWorldPosition()})
end

local data = {}

function GenerateCurve()

end

function Play()

end
--Game.playerJoinedEvent:Connect(Join)