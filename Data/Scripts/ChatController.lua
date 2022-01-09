-- API

local API = require(script:GetCustomProperty("AnimatorClientAPI"))

-- Custom 
local CHAT_REMINDER = script:GetCustomProperty("ChatReminder"):WaitForObject() ---@type UIPanel
local TITLE = script:GetCustomProperty("Title"):WaitForObject() ---@type UIText
local FIELD = script:GetCustomProperty("Field"):WaitForObject() ---@type UIText
local TYPE = script:GetCustomProperty("Type"):WaitForObject() ---@type UIText
local LMBDRAG_AREA = script:GetCustomProperty("LMBDragArea"):WaitForObject() ---@type UIButton

local START_ICON = script:GetCustomProperty("StartIcon"):WaitForObject() ---@type UIImage
local END_ICON = script:GetCustomProperty("EndIcon"):WaitForObject() ---@type UIImage

local LOCAL_PLAYER = Game.GetLocalPlayer()
LOCAL_PLAYER.clientUserData.dragStartValue = nil
LOCAL_PLAYER.clientUserData.mouseStartPos = nil

local lpTable = {
    px = {"Position X", "number"},
    py = {"Position Y", "number"},
    pz = {"Position Z", "number"},
    rx = {"Rotation X", "degrees"},
    ry = {"Rotation Y", "degrees"},
    rz = {"Rotation Z", "degrees"},
    weight = {"Anchor Weight", "0 - 1.0"},
    blendIn = {"Blend In Time", "blend"},
    blendOut = {"Blend out Time", "blend"},
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
    elseif expected == "blend" then
        if num > 0 then
            return {"", num}
        else
            return {"Time must be greater than 0", nil}
        end
    elseif expected == "degrees" then
        num = num % 360
        return {"", num}
    end
end

function UpdateLastPressed(name, value)
    local values = LOCAL_PLAYER.clientUserData.currentKeyFrame.clientUserData.prop
    if not values then
        return false
    end
    value = CoreMath.Round(value, 3)
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

function GetCurrentPropValue(name)
    local values = LOCAL_PLAYER.clientUserData.currentKeyFrame.clientUserData.prop
    if not values then
        return nil
    end
    local current = nil
    if name == "px" then
        current = values.position.x
    elseif name == "py" then
        current = values.position.y
    elseif name == "pz" then
        current = values.position.z
    elseif name == "rx" then
        current = values.rotation.x
    elseif name == "ry" then
        current = values.rotation.y
    elseif name == "rz" then
        current = values.rotation.z
    elseif name == "ox" then
        current = values.offset.x
    elseif name == "oy" then
        current = values.offset.y
    elseif name == "oz" then
        current = values.offset.z
    elseif name == "weight" then
        current = values.weight
    elseif name == "blendIn" then
        current = values.blendIn
    elseif name == "blendOut" then
        current = values.blendOut
    end
    return current
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

function UpdateDragStatus()
    if not LOCAL_PLAYER.clientUserData.dragStartValue then
        return
    end
    local lp = LOCAL_PLAYER.clientUserData.lastPressed
    local position = UI.GetCursorPosition()
    END_ICON.x = position.x - 45
    END_ICON.y = position.y - 10
    if lp then
        local key = lp.clientUserData.value
        if key and lpTable[key] then
            local inputType = lpTable[key][2]
            local val = LOCAL_PLAYER.clientUserData.dragStartValue
            if inputType == "number" then
                local diff = UI.GetCursorPosition().x - LOCAL_PLAYER.clientUserData.mouseStartPos.x
                val = val + diff / 10
            elseif inputType == "degrees" then
                local diff = UI.GetCursorPosition().x - LOCAL_PLAYER.clientUserData.mouseStartPos.x
                val = (val + diff) % 360
                if val > 180 then
                    val = - (360 - val)
                elseif val < -180 then
                    val = 360 + val
                end
            elseif inputType == "blend" then
                local diff = (UI.GetCursorPosition().x - LOCAL_PLAYER.clientUserData.mouseStartPos.x) / 50
                val = math.max(0, val + diff)
            elseif inputType == "0 - 1.0" then
                local diff = (UI.GetCursorPosition().x - LOCAL_PLAYER.clientUserData.mouseStartPos.x) / 200
                val = CoreMath.Clamp(val + diff, 0, 1)
            else
                error("Invalid input type")
                return
            end
            local update = UpdateLastPressed(key, CoreMath.Round(val, 3))
        end
    end
end

function StartDrag(button)
    local lp = LOCAL_PLAYER.clientUserData.lastPressed
    if lp then
        local key = lp.clientUserData.value
        if key and lpTable[key] then
            local currentVal = CoreMath.Round(GetCurrentPropValue(key), 3) 
            if currentVal then
                LOCAL_PLAYER.clientUserData.dragStartValue = currentVal
            end
        end
    end
    if LOCAL_PLAYER.clientUserData.dragStartValue then
        local position = UI.GetCursorPosition()
        LOCAL_PLAYER.clientUserData.mouseStartPos = position
        START_ICON.visibility = Visibility.FORCE_ON
        START_ICON.x = position.x - 25
        START_ICON.y = position.y - 25
        END_ICON.visibility = Visibility.FORCE_ON
        END_ICON.x = position.x - 45
        END_ICON.y = position.y - 10
    end
end
function EndDrag(button)
    local lp = LOCAL_PLAYER.clientUserData.lastPressed
    if lp then
        local key = lp.clientUserData.value
        if key and lpTable[key] then
            --Broadcast new value to server
        end
    end
    if LOCAL_PLAYER.clientUserData.dragStartValue then
        LOCAL_PLAYER.clientUserData.mouseStartPos = nil
        START_ICON.visibility = Visibility.FORCE_OFF
        END_ICON.visibility = Visibility.FORCE_OFF
    end
    LOCAL_PLAYER.clientUserData.dragStartValue = nil
end
LMBDRAG_AREA.pressedEvent:Connect(StartDrag)
LMBDRAG_AREA.releasedEvent:Connect(EndDrag)

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
    UpdateDragStatus()
end
Chat.sendMessageHook:Connect(ChatHook)
