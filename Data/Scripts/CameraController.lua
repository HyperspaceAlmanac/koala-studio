-- Custom 
local CAMERA = script:GetCustomProperty("ThirdPersonCamera"):WaitForObject() ---@type Camera


local LOCAL_PLAYER = Game.GetLocalPlayer()
function Tick(deltaTime)
    if LOCAL_PLAYER:IsBindingPressed("ability_secondary") then
        CAMERA.rotationMode =  RotationMode.LOOK_ANGLE
        CAMERA:SetRotation(LOCAL_PLAYER:GetViewWorldRotation())
    else
        CAMERA.rotationMode = RotationMode.CAMERA
    end
end