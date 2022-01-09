-- API
local API = require(script:GetCustomProperty("AnimatorClientAPI"))
local ENCODER_API = require(script:GetCustomProperty("EncoderAPI"))

-- Networking 
local NETWORKED = script:GetCustomProperty("NetworkedObj"):WaitForObject() ---@type Folder

-- Custom 
local ANIMATION_BUTTON = script:GetCustomProperty("AnimationButton")
local ANIMATIONS = script:GetCustomProperty("Animations"):WaitForObject() ---@type UIPanel
local ANIMATION_LIST = script:GetCustomProperty("AnimationList"):WaitForObject() ---@type UIScrollPanel
local NEW = script:GetCustomProperty("New"):WaitForObject() ---@type UIButton
local NAME = script:GetCustomProperty("Name"):WaitForObject() ---@type UIButton
local DELETE = script:GetCustomProperty("Delete"):WaitForObject() ---@type UIButton
local EXPORT_ENCODED = script:GetCustomProperty("ExportEncoded"):WaitForObject() ---@type UIButton
local EXPORT_SCRIPT = script:GetCustomProperty("ExportScript"):WaitForObject() ---@type UIButton
local DELETE_MODAL = script:GetCustomProperty("DeleteModal"):WaitForObject() ---@type UIPanel

local LOCAL_PLAYER = Game.GetLocalPlayer()

local deleteMenu = {}
deleteMenu.display = DELETE_MODAL:FindChildByName("DeleteTitle")
deleteMenu.confirm = DELETE_MODAL:FindChildByName("Confirm")
deleteMenu.cancel = DELETE_MODAL:FindChildByName("Cancel")
deleteMenu.callback = nil

local lightGray = Color.New(0.75, 0.75, 0.75)
local gray = Color.New(1, 1, 1)

local animationNames = {}
local animationButtons = {}

deleteMenu.confirm.clickedEvent:Connect(
    function(button)
        if deleteMenu.callback then
            deleteMenu.callback()
            DELETE_MODAL.visibility = Visibility.FORCE_OFF
        end
    end
)

deleteMenu.cancel.clickedEvent:Connect(
    function(button)
        deleteMenu.target = nil
        DELETE_MODAL.visibility = Visibility.FORCE_OFF
    end
)

function ClickedDelete(message, callback)
    deleteMenu.callback = callback
    DELETE_MODAL.visibility = Visibility.INHERIT
    deleteMenu.display.text = "Delete "..message.."?"
end

function FindAndDelete(t, v)
    for i, val in ipairs(t) do
        if val == v then
            table.remove(t, i)
            API.PushToQueue({"DeleteAnimation", i})
        end
    end
    for i, val in ipairs(t) do
        val.y = (i - 1) * 60
    end
end
DELETE.clickedEvent:Connect(
    function (button)
        if LOCAL_PLAYER.clientUserData.currentAnimation then
            local currentAnimation = LOCAL_PLAYER.clientUserData.currentAnimation
            ClickedDelete("Animation",
            function()
                if currentAnimation then
                    FindAndDelete(animationButtons, currentAnimation)
                    currentAnimation:Destroy()
                    LOCAL_PLAYER.clientUserData.currentAnimation = nil
                end
            end)
        end
    end
)

function NewAnimation(button)
    local defaultName = "Animation"
    table.insert(animationNames, defaultName)
    local spawned = World.SpawnAsset(ANIMATION_BUTTON, {parent = ANIMATION_LIST})
    spawned.text = defaultName
    spawned.y = (#animationNames - 1) * 60
    table.insert(animationButtons, spawned)
    spawned.clickedEvent:Connect(
        function(b)
            if LOCAL_PLAYER.clientUserData.currentAnimation then
                LOCAL_PLAYER.clientUserData.currentAnimation:SetButtonColor(lightGray)
            end
            button:SetButtonColor(Color.WHITE)
            LOCAL_PLAYER.clientUserData.currentAnimation = spawned
        end
    )
    local tbl = {}
    API.PushToQueue({"NewAnimation", defaultName})
end

function RenameAnimation(name)
    local currentAnimation = LOCAL_PLAYER.clientUserData.currentAnimation
    if currentAnimation then
        currentAnimation.text = name
        for i, val in ipairs(animationButtons) do
            if val == currentAnimation then
                API.PushToQueue({"ChangeAnimationName", i, name})
                return
            end
        end
    end
end
API.RegisterUpdateNameCallback(RenameAnimation)

NEW.clickedEvent:Connect(NewAnimation)

function NameClicked(button)
    if LOCAL_PLAYER.clientUserData.currentAnimation then
        API.CleanUp(LOCAL_PLAYER)
        LOCAL_PLAYER.clientUserData.setAnimName = true
    end
end

NAME.clickedEvent:Connect(NameClicked)
API.RegisterDeleteCallback(ClickedDelete)

function Join(player)
    API.PlayerJoin(player)
    player.clientUserData.currentAnimation = nil
end

function UpdateAnimationNames(message)
    animationNames = {}
    animationButtons = {}
    LOCAL_PLAYER.clientUserData.currentAnimation = nil
    for _, btn in ipairs(ANIMATION_LIST:GetChildren()) do
        btn:Destroy()
    end
    local index = 2
    while index < #message do
        local size = ENCODER_API.DecodeByte(message:sub(index, index))
        index = index + 1
        local name = message:sub(index, index + size - 1)
        table.insert(animationNames, name)
        index = index + size
    end
    for i, name in ipairs(animationNames) do
        local button = World.SpawnAsset(ANIMATION_BUTTON, {parent = ANIMATION_LIST})
        button.text = name
        button.y = (i - 1) * 60
        table.insert(animationButtons, button)
        button.clickedEvent:Connect(
            function(b)
                if LOCAL_PLAYER.clientUserData.currentAnimation then
                    LOCAL_PLAYER.clientUserData.currentAnimation:SetButtonColor(lightGray)
                end
                button:SetButtonColor(Color.WHITE)
                LOCAL_PLAYER.clientUserData.currentAnimation = button
            end
        )
    end
end

function NetworkedMessage(obj, key)
    if key =="Message" then
        local message = obj:GetCustomProperty(key)
        if message then
            local opCode = ENCODER_API.DecodeByte(message:sub(1, 1))
            if opCode == 1 then
                UpdateAnimationNames(message)                
            end
        end
    end
end
Game.playerJoinedEvent:Connect(Join)
NETWORKED.customPropertyChangedEvent:Connect(NetworkedMessage)

--Send initial message to get animations
Task.Wait()
API.FullCleanUp(LOCAL_PLAYER)
API.PushToQueue({"GetAnimations"})

