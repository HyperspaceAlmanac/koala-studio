-- API 
local ENCODER_API = require(script:GetCustomProperty("EncoderAPI"))
local ANIMATOR_API = require(script:GetCustomProperty("AnimatorClientAPI"))
local eventQueue = {}

function CreateKeyFrame(params)
end

function MoveKeyFrame(params)
end

function UpdateKeyFrame(params)
end

function DeleteKeyFrame(params)
end

function CreateAnimation(params)
end

function LoadAnimation(params)

end

function SaveAnimation(params)
end

function ExportAnimation(params)

end

function DeleteAnimation(params)
end

function ClientEvent(type, params)
end

function ProcessRequest(params)
    if params[1] == "NewAnimation" then
        Events.BroadcastToServer("NewAnimation", params[2])
    elseif params[1] == "DeleteAnimation" then
        Events.BroadcastToServer("DeleteAnimation", params[2])
    elseif params[1] == "ChangeAnimationName" then
        Events.BroadcastToServer("ChangeAnimationName", params[2], params[3])
    elseif params[1] == "GetAnimations" then
        Events.BroadcastToServer("GetAnimations")
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
