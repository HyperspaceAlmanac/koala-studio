local ENCODER_API = require(script:GetCustomProperty("EncoderAPI"))

--Template
local ANIMATION_DISPLAY = script:GetCustomProperty("AnimationDisplay")

-- Custom 
local ANIMATION_LIST = script:GetCustomProperty("AnimationList"):WaitForObject() ---@type UIPanel

local PLAYBACK = script:GetCustomProperty("Playback"):WaitForObject() ---@type UIPanel
local NAME = script:GetCustomProperty("Name"):WaitForObject() ---@type UIText
local UIBUTTON = script:GetCustomProperty("UIButton"):WaitForObject() ---@type UIButton
local PROGRESS = script:GetCustomProperty("Progress"):WaitForObject() ---@type UIProgressBar
local CURRENT_TIME = script:GetCustomProperty("CurrentTime"):WaitForObject() ---@type UIText
local MAX_TIME = script:GetCustomProperty("MaxTime"):WaitForObject() ---@type UIText

--Networking
local NETWORKED = script:GetCustomProperty("Networked"):WaitForObject() ---@type Folder
local LOCAL_PLAYER = Game.GetLocalPlayer()

local networkedPropName = nil
local currentTime = 0
local maxTime = 0
local animNum = 0
local animationNames = {}
PLAYBACK.visibility = Visibility.FORCE_OFF


function UpdateAnimationNames(message)
    animationNames = {}
    local index = 1
    while index < #message do
        local size = ENCODER_API.DecodeByte(message:sub(index, index))
        index = index + 1
        local name = message:sub(index, index + size - 1)
        table.insert(animationNames, name)
        index = index + size
        if #animationNames == 9 then
            break
        end
    end
    for i, name in ipairs(animationNames) do
        local button = World.SpawnAsset(ANIMATION_DISPLAY, {parent = ANIMATION_LIST})
        button.text = name
        button.y = (i - 1) * 60
    end
end

function NamesUpdate(obj, key)
    if networkedPropName then
        if key == networkedPropName then
            UpdateAnimationNames(obj:GetCustomProperty(key))
        end
    end
end

function PrivateNetwork(player, key)
    if key == "propName" then
        networkedPropName = player:GetPrivateNetworkedData(key)
        NamesUpdate(NETWORKED, networkedPropName)
    elseif key == "animNum" then
        animNum = player:GetPrivateNetworkedData(key)
        UIBUTTON.text = tostring(animNum)
    elseif key == "maxTime" then
        maxTime = CoreMath.Round(player:GetPrivateNetworkedData(key), 3)
        MAX_TIME.text = tostring(maxTime)
    elseif key == "currentTime" then
        currentTime = CoreMath.Round(player:GetPrivateNetworkedData(key), 3)
        CURRENT_TIME.text = tostring(currentTime)
    end
end

Task.Spawn(
    function()
        while not networkedPropName do
            Task.Wait(0.5)
            if not networkedPropName then
                networkedPropName = LOCAL_PLAYER:GetPrivateNetworkedData("propName")
                if networkedPropName then
                    NamesUpdate(NETWORKED, networkedPropName)
                end
            end
        end
    end
)

function Tick()
    if animNum > 0 and #animationNames > 0 then
        NAME.text = animationNames[animNum]
        PLAYBACK.visibility = Visibility.INHERIT
        if maxTime > 0 and currentTime <= maxTime then
            PROGRESS.progress = currentTime / maxTime
        end
    else
        PLAYBACK.visibility = Visibility.FORCE_OFF
    end

end

local l1 = NETWORKED.customPropertyChangedEvent:Connect(NamesUpdate)
LOCAL_PLAYER.privateNetworkedDataChangedEvent:Connect(PrivateNetwork)

script.destroyEvent:Connect(function(obj)
    l1:Disconnect()
end)