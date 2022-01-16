local BODY_DEBUG = script:GetCustomProperty("BodyDebug"):WaitForObject() ---@type IKAnchor

local l1 = BODY_DEBUG.activatedEvent:Connect(
    function(ik, player)
        player.clientUserData.bodyIKEnabled = true
        player.clinetUerData.bodyIK = BODY_DEBUG
    end
)

local l2 = BODY_DEBUG.deactivatedEvent:Connect(
    function(ik, player)
        player.clientUserData.bodyIKEnabled = false
        player.clinetUerData.bodyIK = nil
    end
)