-- API

local API = require(script:GetCustomProperty("AnimatorClientAPI"))

-- Custom 
local CHAT_REMINDER = script:GetCustomProperty("ChatReminder"):WaitForObject() ---@type UIPanel
local TITLE = script:GetCustomProperty("Title"):WaitForObject() ---@type UIText
local FIELD = script:GetCustomProperty("Field"):WaitForObject() ---@type UIText
local TYPE = script:GetCustomProperty("Type"):WaitForObject() ---@type UIText

local LOCAL_PLAYER = Game.GetLocalPlayer()

local lpTable = {
    px = {"Position X", "number"},
    py = {"Position Y", "number"},
    pz = {"Position Z", "number"},
    rx = {"Rotation X", "degrees"},
    ry = {"Rotation Y", "degrees"},
    rz = {"Rotation Z", "degrees"},
    weight = {"Anchor Weight", "0 - 1.0"},
    blendIn = {"Blend In Time", "number"},
    blendOut = {"Blend out Time", "number"},
    ox = {"Offset X", "number"},
    oy = {"Offset Y", "number"},
    oz = {"Offset Z", "number"},
    time = {"Time", "number"}
}

function VisibilityCheck()
    local kf = LOCAL_PLAYER.clientUserData.currentKeyFrame
    local lp = LOCAL_PLAYER.clientUserData.lastPressed
    if kf or lp then
        LOCAL_PLAYER.clientUserData.setAnimName = false
        if LOCAL_PLAYER.clientUserData.changeMaxTime then
            LOCAL_PLAYER.clientUserData.changeMaxTime:SetButtonColor(Color.WHITE)
            LOCAL_PLAYER.clientUserData.changeMaxTime = nil
        end
    end
    if lp then
        if lpTable[lp.clientUserData.value] then
            CHAT_REMINDER.visibility = Visibility.INHERIT
        else
            CHAT_REMINDER.visibility = Visibility.FORCE_OFF
        end
    elseif LOCAL_PLAYER.clientUserData.changeMaxTime then
        LOCAL_PLAYER.clientUserData.setAnimName = false
        CHAT_REMINDER.visibility = Visibility.INHERIT
    elseif LOCAL_PLAYER.clientUserData.setAnimName then
        CHAT_REMINDER.visibility = Visibility.INHERIT
    else
        CHAT_REMINDER.visibility = Visibility.FORCE_OFF
    end
end

function Validator(value, expected)
    print("Validator")
    local num = tonumber(value)
    if not num then
        return {"Not a valid Number", nil}
    end
    num = CoreMath.Round(num, 3)
    if expected == "number" then
        return {"", num}
    elseif expected == "0 - 1.0" then
        if num > 0 and num <= 1 then
            return {"", num}
        else
            return {"Value not between 0 and 1", nil}
        end
    elseif expected == "degrees" then
        num = num % 360
        return {"", num}
    end
end

function UpdateLastPressed(name, value)
	print("Checking last pressed")
    local values = LOCAL_PLAYER.clientUserData.currentKeyFrame.clientUserData.prop
    if not values then
        return false
    end
    if name == "px" then
        values.position.x = value
    elseif name == "py" then
        values.position.y = value
    elseif name == "pz" then
        values.position.z = value
    elseif name == "rx" then
        values.rotation.x = value
    elseif name == "ry" then
        values.rotation.y = value
    elseif name == "rz" then
        values.rotation.z = value
    elseif name == "ox" then
        values.offset.x = value
    elseif name == "oy" then
        values.offset.y = value
    elseif name == "oz" then
        values.offset.z = value
    elseif name == "weight" then
        values.weight = value
    elseif name == "blendIn" then
        values.blendIn = value
    elseif name == "blendOut" then
        values.blendOut = value
    elseif name == "time" then
        local kf = LOCAL_PLAYER.clientUserData.currentKeyFrame
        if kf then
            kf.x = value * LOCAL_PLAYER.clientUserData.tickMarkNum * 100 - 25
        else
            return false
        end
    else
        return false
    end
    return true
end

function ChatHook(param)
    local lp = LOCAL_PLAYER.clientUserData.lastPressed
    local mt = LOCAL_PLAYER.clientUserData.changeMaxTime
    local name = LOCAL_PLAYER.clientUserData.setAnimName
    if lp then
        local key = lp.clientUserData.value
        if key and lpTable[key] then
            local result = Validator(param.message, lpTable[key][2])
            if result[1] == "" then
                param.message = ""
                local update = UpdateLastPressed(key, result[2])
            else
                param.message = result[1]
            end
        end
    elseif mt then
        local num = tonumber(param.message)
        if num then
            num = CoreMath.Round(num, 3)
            num = CoreMath.Clamp(num, 0, 60)
            LOCAL_PLAYER.clientUserData.maxSeconds = num
            API.UpdateMaxTime(num)
            API.UpdateTimeDisplayCallback()
            param.message = ""
        end
    elseif name then
        API.UpdateName(param.message)
        param.message = ""
    end
end

function Tick(deltaTime)
    VisibilityCheck()
    local lp = LOCAL_PLAYER.clientUserData.lastPressed
    local mt = LOCAL_PLAYER.clientUserData.changeMaxTime
    local name = LOCAL_PLAYER.clientUserData.setAnimName
    if lp then
    	local lpValue = lp.clientUserData.value
        if lpValue and lpTable[lpValue] then
            FIELD.text = lpTable[lpValue][1]
            TYPE.text = lpTable[lpValue][2]
        end
    elseif mt then
        FIELD.text = "Timeline Max"
        TYPE.text = "Seconds"
    elseif name then
        FIELD.text = "Aniation Name"
        TYPE.text = "String"
    end
end
Chat.sendMessageHook:Connect(ChatHook)
