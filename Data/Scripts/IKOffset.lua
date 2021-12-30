local ANCHOR = script:GetCustomProperty("Anchor"):WaitForObject() ---@type IKAnchor
local OFFSET = script:GetCustomProperty("Offset"):WaitForObject() ---@type StaticMesh

function Tick(deltaTime)
    OFFSET:SetPosition(ANCHOR:GetAimOffset())
end