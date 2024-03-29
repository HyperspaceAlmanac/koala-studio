-- API

local API = require(script:GetCustomProperty("AnimatorClientAPI"))

-- Custom 
local CHAT_REMINDER = script:GetCustomProperty("ChatReminder"):WaitForObject() ---@type UIPanel
local FIELD = script:GetCustomProperty("Field"):WaitForObject() ---@type UIText
local TYPE = script:GetCustomProperty("Type"):WaitForObject() ---@type UIText
local LMBDRAG_AREA = script:GetCustomProperty("LMBDragArea"):WaitForObject() ---@type UIButton

local START_ICON = script:GetCustomProperty("StartIcon"):WaitForObject() ---@type UIImage
local END_ICON = script:GetCustomProperty("EndIcon"):WaitForObject() ---@type UIImage

-- IK
local REFERENCE_CLIENT = script:GetCustomProperty("ReferenceClient")
local BODY_IK = script:GetCustomProperty("BodyIKClient")
local LEFT_FOOT_IK = script:GetCustomProperty("LeftFootIKClient")
local LEFT_HAND_IK = script:GetCustomProperty("LeftHandIKClient")
local RIGHT_FOOT_IK = script:GetCustomProperty("RightFootIKClient")
local RIGHT_HAND_IK = script:GetCustomProperty("RightHandIKClient")

local LOCAL_PLAYER = Game.GetLocalPlayer()
LOCAL_PLAYER.clientUserData.dragStartValue = nil
LOCAL_PLAYER.clientUserData.mouseStartPos = nil

local ikBody = nil
local ikBodyActive = false

local clientIK = {}
local r1 = World.SpawnAsset(REFERENCE_CLIENT)
r1:AttachToPlayer(LOCAL_PLAYER, "Pelvis")
local reference = World.SpawnAsset(REFERENCE_CLIENT, {position = r1:GetWorldPosition(), rotation = r1:GetWorldRotation()})
r1:Destroy()
local bodyObj = World.SpawnAsset(BODY_IK, {parent = reference})
table.insert(clientIK, bodyObj)
table.insert(clientIK, World.SpawnAsset(LEFT_HAND_IK, {parent = bodyObj}))
table.insert(clientIK, World.SpawnAsset(RIGHT_HAND_IK, {parent = bodyObj}))
table.insert(clientIK, World.SpawnAsset(LEFT_FOOT_IK, {parent = bodyObj}))
table.insert(clientIK, World.SpawnAsset(RIGHT_FOOT_IK, {parent = bodyObj}))
for _, anchor in ipairs(clientIK) do
    anchor.visibility = Visibility.FORCE_OFF
end

local lpTable = {
    px = {"Position X", "number", "UpdateKFPosition"},
    py = {"Position Y", "number", "UpdateKFPosition"},
    pz = {"Position Z", "number", "UpdateKFPosition"},
    rx = {"Rotation X", "degrees", "UpdateKFRotation"},
    ry = {"Rotation Y", "degrees", "UpdateKFRotation"},
    rz = {"Rotation Z", "degrees", "UpdateKFRotation"},
    weight = {"Anchor Weight", "0 - 1.0", "UpdateKFWeight"},
    blendIn = {"Blend In Time", "blend", "UpdateKFBlendIn"},
    blendOut = {"Blend out Time", "blend", "UpdateKFBlendOut"},
    ox = {"Offset X", "number", "UpdateKFOffset"},
    oy = {"Offset Y", "number", "UpdateKFOffset"},
    oz = {"Offset Z", "number", "UpdateKFOffset"},
    time = {"Time", "number", "UpdateKFTime"}
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
                local kf = LOCAL_PLAYER.clientUserData.currentKeyFrame
                local i = kf.clientUserData.anchorIndex
                local j = kf.clientUserData.timelineIndex
                local prop = kf.clientUserData.prop
                local eventName = lpTable[key][3]
                if eventName == "UpdateKFPosition" then
                    API.PushToQueue({eventName, i, j, prop.position})
                elseif eventName == "UpdateKFRotation" then
                    API.PushToQueue({eventName, i, j, prop.rotation})
                elseif eventName == "UpdateKFOffset" then
                    API.PushToQueue({eventName, i, j, prop.offset})
                elseif eventName == "UpdateKFWeight" then
                    API.PushToQueue({eventName, i, j, prop.weight})
                elseif eventName == "UpdateKFBlendIn" then
                    API.PushToQueue({eventName, i, j, prop.blendIn})
                elseif eventName == "UpdateKFBlendOut" then
                    API.PushToQueue({eventName, i, j, prop.blendOut})
                else
                    print("ERROR! Unable to find event type")
                end
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
            API.UpdateTimeDisplayCallback(nil)
            param.message = ""
        end
    elseif name then
        local newName = param.message
        if #newName == 0 or #newName > 25 then
            param.message = "Name must be between 1 and 25 characters"
        else
            API.UpdateNameCallback(param.message)
            param.message = ""
        end
    end
end

function UpdateIK()
    local kf = LOCAL_PLAYER.clientUserData.currentKeyFrame
    if ikBody and ikBodyActive then
        if kf and kf.clientUserData.anchorIndex ~= 1 then
            bodyObj:SetWorldPosition(ikBody:GetWorldPosition())
            bodyObj:SetRotation(ikBody:GetRotation())
        end
    else
        bodyObj:SetWorldRotation(LOCAL_PLAYER:GetWorldRotation())
    end
    ---bodyObj:SetWorldRotation(LOCAL_PLAYER:GetWorldRotation())
    if LOCAL_PLAYER.clientUserData.dragStartValue then
        if kf then
            local anchorIndex = kf.clientUserData.anchorIndex
            local prop = kf.clientUserData.prop
            for i, anchor in ipairs(clientIK) do
                anchor.visibility = i == anchorIndex and Visibility.FORCE_ON or Visibility.FORCE_OFF
            end
            clientIK[anchorIndex]:SetPosition(prop.position)
            clientIK[anchorIndex]:SetRotation(prop.rotation)
            clientIK[anchorIndex]:SetAimOffset(prop.offset)
        end
    else
        for _, anchor in ipairs(clientIK) do
            anchor.visibility = Visibility.FORCE_OFF
        end
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
                local diff = (UI.GetCursorPosition().x - LOCAL_PLAYER.clientUserData.mouseStartPos.x) / 5
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
            local kf = LOCAL_PLAYER.clientUserData.currentKeyFrame
            local i = kf.clientUserData.anchorIndex
            local j = kf.clientUserData.timelineIndex
            local prop = kf.clientUserData.prop
            local eventName = lpTable[key][3]
            if eventName == "UpdateKFPosition" then
                API.PushToQueue({eventName, i, j, prop.position})
            elseif eventName == "UpdateKFRotation" then
                API.PushToQueue({eventName, i, j, prop.rotation})
            elseif eventName == "UpdateKFOffset" then
                API.PushToQueue({eventName, i, j, prop.offset})
            elseif eventName == "UpdateKFWeight" then
                API.PushToQueue({eventName, i, j, prop.weight})
            elseif eventName == "UpdateKFBlendIn" then
                API.PushToQueue({eventName, i, j, prop.blendIn})
            elseif eventName == "UpdateKFBlendOut" then
                API.PushToQueue({eventName, i, j, prop.blendOut})
            else
                print("ERROR! Unable to find event type")
            end
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

function HandleIKStatus(player, key)
    if key == "IKBody" then
        ikBody = player:GetPrivateNetworkedData("IKBody")
    elseif key == "IKBodyActive" then
        ikBodyActive = player:GetPrivateNetworkedData("IKBodyActive")
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
        FIELD.text = "Animation Name"
        TYPE.text = "String"
    end
    UpdateDragStatus()
    UpdateIK()
end
Chat.sendMessageHook:Connect(ChatHook)
ikBody = LOCAL_PLAYER:GetPrivateNetworkedData("IKBody")
ikBodyActive = LOCAL_PLAYER:GetPrivateNetworkedData("IKBodyActive")
LOCAL_PLAYER.privateNetworkedDataChangedEvent:Connect(HandleIKStatus)
