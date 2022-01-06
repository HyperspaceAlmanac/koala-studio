-- API

local API = require(script:GetCustomProperty("AnimatorClientAPI"))

-- Custom 
local CHAT_REMINDER = script:GetCustomProperty("ChatReminder"):WaitForObject() ---@type UIPanel
local TITLE = script:GetCustomProperty("Title"):WaitForObject() ---@type UIText
local FIELD = script:GetCustomProperty("Field"):WaitForObject() ---@type UIText
local TYPE = script:GetCustomProperty("Type"):WaitForObject() ---@type UIText

local LOCAL_PLAYER = Game.GetLocalPlayer()

local lpTable = {}

function VisibilityCheck()
    local kf = LOCAL_PLAYER.clientUserData.currentKeyFrame
    local lp = LOCAL_PLAYER.clientUserData.lastPressed
    if kf or lp then
        LOCAL_PLAYER.clientUserData.setAnimName = false
        if lp then
            CHAT_REMINDER.visibility = Visibility.INHERIT
        else
            CHAT_REMINDER.visibility = Visibility.FORCE_OFF
        end
        if LOCAL_PLAYER.clientUserData.changeMaxTime then
            LOCAL_PLAYER.clientUserData.changeMaxTime:SetButtonColor(Color.WHITE)
            LOCAL_PLAYER.clientUserData.changeMaxTime = nil
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

function Tick(deltaTime)
    VisibilityCheck()
    local lp = LOCAL_PLAYER.clientUserData.lastPressed
    local mt = LOCAL_PLAYER.clientUserData.changeMaxTime
    local name = LOCAL_PLAYER.clientUserData.setAnimName
    if lp then
        FIELD.text = "Key Frame"
        TYPE.text = "0-1"
    elseif mt then
        FIELD.text = "Timeline Max"
        TYPE.text = "Seconds"
    elseif name then
        FIELD.text = "Aniation Name"
        TYPE.text = "String"
    end
end

function ChatHook(param)
    local lp = LOCAL_PLAYER.clientUserData.lastPressed
    local mt = LOCAL_PLAYER.clientUserData.changeMaxTime
    local name = LOCAL_PLAYER.clientUserData.setAnimName
    if lp then
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
Chat.sendMessageHook:Connect(ChatHook)
