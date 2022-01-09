local ENCODER = require(script:GetCustomProperty("EncoderAPI"))

Task.Wait(1)
local pos = Vector3.New(-1, -1, -1)
local offset = Vector3.New(-1, -1, 1)
Events.BroadcastToAllPlayers("Message", ENCODER.EncodePosAndOffsetSigns(pos, offset))