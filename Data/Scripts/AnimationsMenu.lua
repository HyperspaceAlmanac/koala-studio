-- Custom 
local API = require(script:GetCustomProperty("AnimatorClientAPI"))

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

local animations = {}
local currentAnimation = nil
for _, anim in ipairs(ANIMATION_LIST:GetChildren()) do
    if anim:IsA("UIButton") then
        table.insert(animations, anim)
        anim.clickedEvent:Connect(
            function(button)
                if currentAnimation then
                    currentAnimation:SetButtonColor(lightGray)
                end
                button:SetButtonColor(gray)
                currentAnimation = button
            end
        )
        anim.text = "Animation"..tostring(#animations)
    end
end
currentAnimation = animations[1]
currentAnimation:SetButtonColor(gray)

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
        end
    end
    for i, val in ipairs(t) do
        val.y = (i - 1) * 60
    end
end
DELETE.clickedEvent:Connect(
    function (button)
        if currentAnimation then
            ClickedDelete("Animation",
            function()
                if currentAnimation then
                    FindAndDelete(animations, currentAnimation)
                    currentAnimation:Destroy()
                    if #animations > 0 then
                        currentAnimation = animations[1]
                        currentAnimation:SetButtonColor(gray)
                    end
                end
            end)
        end
    end
)

function NameClicked(button)
    local lastPressed = LOCAL_PLAYER.clientUserData.lastPressed
    if lastPressed then
        lastPressed:SetButtonColor(gray)
        LOCAL_PLAYER.clientUserData.lastPressed = nil
    end
    local lastKF = LOCAL_PLAYER.clientUserData.currentKeyFrame
    if LOCAL_PLAYER.clientUserData.currentKeyFrame then
        lastKF:SetButtonColor(Color.BLACK)
        LOCAL_PLAYER.clientUserData.currentKeyFrame = nil
    end
    LOCAL_PLAYER.clientUserData.setAnimName = true
end

NAME.clickedEvent:Connect(NameClicked)
API.RegisterDeleteCallback(ClickedDelete)

