-- API 
local API = require(script:GetCustomProperty("IK_API"))

-- Custom 
local PLAYER_POSITION_REFERENCE = script:GetCustomProperty("PlayerPositionReference")
local BODY_DEBUG = script:GetCustomProperty("BodyDebug")
local LEFT_HAND_DEBUG = script:GetCustomProperty("LeftHandDebug")
local LEFT_FOOT_DEBUG = script:GetCustomProperty("LeftFootDebug")
local RIGHT_HAND_DEBUG = script:GetCustomProperty("RightHandDebug")
local RIGHT_FOOT_DEBUG = script:GetCustomProperty("RightFootDebug")


local AnchorTable = {}
local References = {}
local listeners = {}

function Join(player)
    local anchors = {}
    local r1 = World.SpawnAsset(PLAYER_POSITION_REFERENCE, {rotation=player:GetWorldRotation()})
    r1:AttachToPlayer(player, "Pelvis")
    local reference = World.SpawnAsset(PLAYER_POSITION_REFERENCE, {position = r1:GetWorldPosition(), rotation=player:GetWorldRotation()})
    r1:Destroy()
    References[player] = reference
    local body = World.SpawnAsset(BODY_DEBUG, {parent = reference})
    player:SetPrivateNetworkedData("IKBody", body)
    player:SetPrivateNetworkedData("IKBodyActive", false)
    table.insert(anchors, body)
    table.insert(anchors, World.SpawnAsset(LEFT_HAND_DEBUG, {parent = body}))
    table.insert(anchors, World.SpawnAsset(RIGHT_HAND_DEBUG, {parent = body}))
    table.insert(anchors, World.SpawnAsset(LEFT_FOOT_DEBUG, {parent = body}))
    table.insert(anchors, World.SpawnAsset(RIGHT_FOOT_DEBUG, {parent = body}))
    AnchorTable[player] = anchors
    for _, anchor in ipairs(anchors) do
        listeners[anchor] = {}
        anchor.serverUserData.active = false
        listeners[anchor][1] = anchor.activatedEvent:Connect(
            function(ik, player)
                ik.serverUserData.active = true
                player:SetPrivateNetworkedData("IKBodyActive", true)
            end
        )
        listeners[anchor][2] = anchor.deactivatedEvent:Connect(
            function(ik)
                ik.serverUserData.active = false
                player:SetPrivateNetworkedData("IKBodyActive", false)
            end
        )
    end
    API.PlayerJoin(player, anchors)
end

function Leave(player)
    API.PlayerLeft(player)
    for _, anchor in ipairs(player:GetIKAnchors()) do
        anchor:Deactivate()
    end
    for _, anchor in ipairs(AnchorTable[player]) do
        listeners[anchor][1]:Disconnect()
        listeners[anchor][2]:Disconnect()
        listeners[anchor] = nil
        if Object.IsValid(anchor) then
            anchor:Destroy()
        end
    end
    References[player]:Destroy()
    References[player] = nil
    AnchorTable[player] = nil
end

Game.playerJoinedEvent:Connect(Join)
Game.playerLeftEvent:Connect(Leave)
