-- API 
local ENCODER_API = require(script:GetCustomProperty("EncoderAPI"))

local eventQueue = {}
function SendMessages()
    for i = 1, 2 do
        if #eventQueue > 0 then
            Events.BroadcastToServer("ClientEvent", eventQueue[0])
            table.remove(eventQueue, 1)
        else
            return
        end
    end
end

function Initialize()
    Task.Spawn(
        function()
            Task.Wait(0.2)
            SendMessages()
        end
    )
end

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

function ReadServerData()
end

Events.Connect("ClientEvent", ClientEvent)