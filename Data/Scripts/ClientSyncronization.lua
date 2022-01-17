-- API 
local ENCODER_API = require(script:GetCustomProperty("EncoderAPI"))
local ANIMATOR_API = require(script:GetCustomProperty("AnimatorClientAPI"))
local eventQueue = {}

function ProcessRequest(params)
    if params[1] == "NewAnimation" then
        Events.BroadcastToServer("NewAnimation", params[2])
    elseif params[1] == "DeleteAnimation" then
        Events.BroadcastToServer("DeleteAnimation", params[2])
    elseif params[1] == "ChangeAnimationName" then
        Events.BroadcastToServer("ChangeAnimationName", params[2], params[3])
    elseif params[1] == "SelectAnimation" then
        Events.BroadcastToServer("SelectAnimation", params[2])
    elseif params[1] == "GetAnimations" then
        Events.BroadcastToServer("GetAnimations")
    elseif params[1] == "DeleteKeyFrame" then
        Events.BroadcastToServer("DeleteKF", params[2], params[3])
    elseif params[1] == "CreateKeyFrame" then
        Events.BroadcastToServer("CreateKF", params[2], params[3])
    elseif params[1] == "DuplicateKeyFrame" then
        Events.BroadcastToServer("DuplicateKF", params[2], params[3])
    elseif params[1] == "SetTimeScale" then
        Events.BroadcastToServer("ChangeAnimationTimeScale", params[2], params[3])
    elseif params[1] == "SetMaxTime" then
        Events.BroadcastToServer("ChangeAnimationMaxTime", params[2], params[3])
    elseif params[1] == "UpdateKFTime" then
        Events.BroadcastToServer("UpdateKFTime", params[2], params[3], params[4])
    elseif params[1] == "UpdateKFPosition" then
        Events.BroadcastToServer("UpdateKFPosition", params[2], params[3], params[4])
    elseif params[1] == "UpdateKFRotation" then
        Events.BroadcastToServer("UpdateKFTRotation", params[2], params[3], params[4])
    elseif params[1] == "UpdateKFOffset" then
        Events.BroadcastToServer("UpdateKFOffset", params[2], params[3], params[4])
    elseif params[1] == "UpdateKFWeight" then
        Events.BroadcastToServer("UpdateKFWeight", params[2], params[3], params[4])
    elseif params[1] == "UpdateKFBlendIn" then
        Events.BroadcastToServer("UpdateKFBlendIn", params[2], params[3], params[4])
    elseif params[1] == "UpdateKFBlendOut" then
        Events.BroadcastToServer("UpdateKFBlendOut", params[2], params[3], params[4])
    elseif params[1] == "UpdateKFActive" then
        Events.BroadcastToServer("UpdateKFActive", params[2], params[3], params[4])
    elseif params[1] == "UpdateKFrxl" then
        Events.BroadcastToServer("UpdateKFrxl", params[2], params[3], params[4])
    elseif params[1] == "UpdateKFryl" then
        Events.BroadcastToServer("UpdateKFryl", params[2], params[3], params[4])
    elseif params[1] == "UpdateKFrzl" then
        Events.BroadcastToServer("UpdateKFrzl", params[2], params[3], params[4])
    elseif params[1] == "UpdateKFCurrentTime" then
        Events.BroadcastToServer("UpdateKFCurrentTime", params[2], params[3])
    elseif params[1] == "PlayAnimation" then
        Events.BroadcastToServer("PreviewPlay")
    elseif params[1] == "StopAnimation" then
        Events.BroadcastToServer("PreviewStop")
    elseif params[1] == "SetPreviewTime" then
        Events.BroadcastToServer("PreviewSetTime", params[2])
    elseif params[1] == "ExportEncoded" then
        Events.BroadcastToServer("ExportEncoded")
    elseif params[1] == "ExportScript" then
        Events.BroadcastToServer("ExportScript")
    elseif params[1] == "Save" then
        Events.BroadcastToServer("SaveProgress")
    elseif params[1] == "Hub" then
        Events.BroadcastToServer("GotoHub")
    else
        print("Unknown request header, no action taken")
    end
end

function AddToQueue(params)
    table.insert(eventQueue, params)
end
ANIMATOR_API.RegisterP2QC(AddToQueue)

function SendMessages()
    if #eventQueue > 0 then
        ProcessRequest(eventQueue[1])
        table.remove(eventQueue, 1)
    end
end

function Initialize()
    Task.Spawn(
        function()
            while true do
                Task.Wait(0.1)
                SendMessages()
            end
        end
    )
end

Initialize()
