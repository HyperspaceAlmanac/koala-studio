local ENCODER = require(script:GetCustomProperty("EncoderAPI"))
function Decode(message)
    local result = ENCODER.DecodePosAndOffsetSigns(message)
    for i, val in ipairs(result) do
        print(tostring(i).." "..tostring(val))
    end
end
Events.Connect("Message", Decode)