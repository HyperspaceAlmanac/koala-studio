   
--Byte Encoder
-- Module for encoding and decoding messages
-- Modified version of Symphony of Mayhem Byte Encoder (only older version made public)

-- To import, drag from project content into Custom Property of script that import this.
-- Add in the line, and then access the functions as properties of the variable
-- local encoder = require(script:GetCustomProperty("Encoder"))
local Encoder = {}

-- More specialized with limitation that it has to be 0-126
function Encoder.EncodeTwoBytes(num)
    local negative = num < 0
    if negative then
        num = -num
    end
    local right = num & 255
    local left = 0
    if num > 255 then
        left = (num & 32512) >> 8
    end
    if negative then
        left = left + 128
    end
    return string.char(left)..string.char(right)
end

function Encoder.DecodeTwoBytes(encoded)
    local left = tonumber(string.byte(encoded:sub(1, 1)))
    local right = tonumber(string.byte(encoded:sub(2, 2)))
    local negative = (left & 128) > 0
    if negative then
        left = left - 128
    end
    if negative then
        return -((left << 8) + right)
    else
        return (left << 8) + right        
    end

end

--For two bytes server to client or client to server communication
-- EX: Events.BroadcastToAllPlayers()
-- Two byte encoding for 0-9999
function Encoder.EncodeNetwork(num)
    local right = num % 100 + 1
    local left = math.floor(num / 100) + 1
    return string.char(left)..string.char(right)
end

function Encoder.DecodeNetwork(encoded)
    local left = tonumber(string.byte(encoded:sub(1, 1))) - 1
    local right = tonumber(string.byte(encoded:sub(2, 2))) - 1
    return left * 100 + right
end

-- 0 to 255
function Encoder.EncodeByte(num)
    return string.char(num)
end

function Encoder.DecodeByte(encoded)
    return tonumber(string.byte(encoded))
end

-- 0 to 15, 0-3, 0-3 
function Encoder.EncodeFourTwoTwo(type, left, right)
    return string.char((type << 4) + (left << 2) + right)
end

function Encoder.DecodeFourTwoTwo(encoded)
    local values = {}
    encoded = tonumber(string.byte(encoded))
    values[1] = (encoded & 240) >> 4
    values[2] = (encoded & 12) >> 2
    values[3] = (encoded & 3)
    return values
end

function Encoder.EncodePlayerInfo(num, left, right)
    local leftVal = 0
    local rightVal = 0
    if left then
        leftVal = 1
    end
    if right then
        rightVal = 1
    end
    return string.char((num << 2) + (leftVal << 1) + rightVal)
end

function Encoder.DecodePlayerInfo(encoded)
    local values = {}
    encoded = tonumber(string.byte(encoded))
    values[1] = (encoded & 28) >> 2
    values[2] = (encoded >> 1) & 1
    values[3] = encoded & 1
    return values
end

function Encoder.EncodeWeapon(weapon, mode)
    return string.char((weapon << 3) + mode)
end

function Encoder.DecodeWeapon(encoded)
    local values = {}
    encoded = tonumber(string.byte(encoded))
    values[1] = (encoded & 120) >> 3
    values[2] = encoded & 7
    return values
end

function Encoder.EncodeWeaponInfo(player, mode)
    return string.char((player << 3) + mode + 1)
end

function Encoder.DecodeWeaponInfo(encoded)
    local values = {}
    encoded = tonumber(string.byte(encoded)) - 1
    values[1] = (encoded) >> 3
    values[2] = encoded & 7
    return values
end

function Encoder.EncodeHitMode(position, left, right, type)
    local x = position.x >= 0 and 1 or 0 
    local y = position.y >= 0 and 1 or 0
    local z = position.z >= 0 and 1 or 0
    return string.char((x << 5) + (y << 4) + (z << 3) + (left << 2) + (right * 2) + type)
end

function Encoder.DecodeHitMode(encoded)
    local values = {}
    encoded = tonumber(string.byte(encoded))
    values[1] = (encoded & 32) > 0
    values[2] = (encoded & 16) > 0
    values[3] = (encoded & 8) > 0
    values[4] = (encoded & 4) >> 2
    values[5] = (encoded & 2) >> 1
    values[6] = encoded & 1
    return values
end

function Encoder.EncodeSpawn(l1, r1, l2, r2, drum)
    return 32 + (l1 and 16 or 0) + (r1 and 8 or 0) + (l2 and 4 or 0) + (r2 and 2 or 0)
           + (drum and 1 or 0)
end
function Encoder.DecodeSpawn(encoded)
    local values = {}
    encoded = encoded - 32
    values[1] = encoded & 16 > 0
    values[2] = encoded & 8 > 0
    values[3] = encoded & 4 > 0
    values[4] = encoded & 2 > 0
    values[5] = encoded & 1 > 0
    return values
end

function Encoder.EncodeKeyFrame()
    return ""
end

function Encoder.DecodeKeyFrame()

end

return Encoder