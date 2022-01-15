
-- API 
local API = require(script:GetCustomProperty("IK_API"))

-- Custom 
local BODY_DEBUG = script:GetCustomProperty("BodyDebug")
local LEFT_HAND_DEBUG = script:GetCustomProperty("LeftHandDebug")
local LEFT_FOOT_DEBUG = script:GetCustomProperty("LeftFootDebug")
local RIGHT_HAND_DEBUG = script:GetCustomProperty("RightHandDebug")
local RIGHT_FOOT_DEBUG = script:GetCustomProperty("RightFootDebug")


local AnchorTable = {}

function Join(player)
    local anchors = {}
    table.insert(anchors, World.SpawnAsset(BODY_DEBUG, {position = player:GetWorldPosition()}))
    table.insert(anchors, World.SpawnAsset(LEFT_HAND_DEBUG, {position = player:GetWorldPosition()}))
    table.insert(anchors, World.SpawnAsset(RIGHT_HAND_DEBUG, {position = player:GetWorldPosition()}))
    table.insert(anchors, World.SpawnAsset(LEFT_FOOT_DEBUG, {position = player:GetWorldPosition()}))
    table.insert(anchors, World.SpawnAsset(RIGHT_FOOT_DEBUG, {position = player:GetWorldPosition()}))
    AnchorTable[player] = anchors
    API.PlayerJoin(player, anchors)
end

function Leave(player)
    API.PlayerLeft(player)
    for _, anchor in ipairs(player:GetIKAnchors()) do
        anchor:Deactivate()
    end
    for _, anchor in ipairs(AnchorTable[player]) do
        anchor:Destroy()
    end
    AnchorTable[player] = nil
end

Game.playerJoinedEvent:Connect(Join)
Game.playerLeftEvent:Connect(Leave)
