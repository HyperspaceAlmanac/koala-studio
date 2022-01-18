-- API
local API = require(script:GetCustomProperty("AnimatorClientAPI"))
local ENCODER_API = require(script:GetCustomProperty("EncoderAPI"))

-- Networking 
local NETWORKED = script:GetCustomProperty("NetworkedObj"):WaitForObject() ---@type Folder
local PLAYBACK_TIME = script:GetCustomProperty("PlaybackTime"):WaitForObject() ---@type Folder

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

--Preview
local PREVIEW = script:GetCustomProperty("Preview"):WaitForObject() ---@type UIButton
local PREVIEW_SCREEN = script:GetCustomProperty("PreviewScreen"):WaitForObject() ---@type UIButton
local TIME = script:GetCustomProperty("Time"):WaitForObject() ---@type UIText
local PLAY_BUTTON = script:GetCustomProperty("PlayButton"):WaitForObject() ---@type UIButton
local STOP = script:GetCustomProperty("Stop"):WaitForObject() ---@type UIButton
local BACK = script:GetCustomProperty("Back"):WaitForObject() ---@type UIButton
local TIME_LINE = script:GetCustomProperty("TimeLine"):WaitForObject() ---@type UIButton
local SECOND_LABEL = script:GetCustomProperty("SecondLabel")
local CURRENT_TIME = script:GetCustomProperty("CurrentTime")
local STATUS = script:GetCustomProperty("Status"):WaitForObject() ---@type UIText
local SAVE = script:GetCustomProperty("Save"):WaitForObject() ---@type UIButton
local HUB = script:GetCustomProperty("Hub"):WaitForObject() ---@type UIButton
local HELP_BUTTON = script:GetCustomProperty("HelpButton"):WaitForObject() ---@type UIButton
local HELP = script:GetCustomProperty("Help"):WaitForObject() ---@type UIButton


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

HELP_BUTTON.clickedEvent:Connect(
    function(button)
        HELP.visibility = Visibility.INHERIT
    end
)
HELP.clickedEvent:Connect(
    function(button)
        HELP.visibility = Visibility.FORCE_OFF
    end
)

function ExportEncoded(button)
    API.PushToQueue({"ExportEncoded"})
end
EXPORT_ENCODED.clickedEvent:Connect(ExportEncoded)

function ExportScript(button)
    API.PushToQueue({"ExportScript"})
end
EXPORT_SCRIPT.clickedEvent:Connect(ExportScript)


function ClickedDelete(message, callback)
    deleteMenu.callback = callback
    DELETE_MODAL.visibility = Visibility.INHERIT
    deleteMenu.display.text = "Delete "..message.."?"
end

function FindAndDelete(t, v)
    local found = 0
    for i, val in ipairs(t) do
        if val == v then
            found = i
        elseif found > 0 then
            val.clientUserData.id = val.clientUserData.id - 1
        end
    end
    if found == 0 then
        return
    end
    table.remove(t, found)
    API.PushToQueue({"DeleteAnimation", found})
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

SAVE.clickedEvent:Connect(
    function(button)
        API.PushToQueue({"Save"})
    end
)

HUB.clickedEvent:Connect(
    function(button)
        API.PushToQueue({"Hub"})
    end
)

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

function DeleteAllKeyFrames()
    for i = 1, 5 do
        local anchors = LOCAL_PLAYER.clientUserData.anchors[i]
        for _, button in ipairs(anchors) do
            button:Destroy()
        end
        LOCAL_PLAYER.clientUserData.anchors[i] = {}
    end
    local test = LOCAL_PLAYER.clientUserData.anchors
end

function ClickAnimation(button)
    API.CleanUp(LOCAL_PLAYER)
    local currentAnim = LOCAL_PLAYER.clientUserData.currentAnimation
    if currentAnim == button then
        return
    end
    DeleteAllKeyFrames()
    if currentAnim then
        currentAnim:SetButtonColor(lightGray)
    end
    button:SetButtonColor(Color.YELLOW)
    LOCAL_PLAYER.clientUserData.currentAnimation = button
    for j, btn in ipairs(animationButtons) do
        if btn == button then
            LOCAL_PLAYER.clientUserData.loading = true
		    API.PushToQueue({"SelectAnimation", j})
		    break
        end
    end
end

function NewAnimation(button)
    local defaultName = "Animation"
    table.insert(animationNames, defaultName)
    local spawned = World.SpawnAsset(ANIMATION_BUTTON, {parent = ANIMATION_LIST})
    spawned.text = defaultName
    spawned.clientUserData.id = #animationNames
    spawned.y = (#animationNames - 1) * 60
    table.insert(animationButtons, spawned)
    spawned.clickedEvent:Connect(ClickAnimation)
    API.PushToQueue({"NewAnimation", defaultName})
end
NEW.clickedEvent:Connect(NewAnimation)

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
        button.clientUserData.id = i
        button.text = name
        button.y = (i - 1) * 60
        table.insert(animationButtons, button)
        button.clickedEvent:Connect(ClickAnimation)
    end
end

function DecodeKeyFrame(message)
    local kf = {}
    local misc = ENCODER_API.DecodeMisc(message:sub(1, 1))
    kf.activated = misc[1]
    kf.rxl = misc[2]
    kf.ryl = misc[3]
    kf.rzl = misc[4]
    local signTable = ENCODER_API.DecodePosAndOffsetSigns(message:sub(2, 2))
    local x = ENCODER_API.DecodeDecimal(message:sub(3, 5))
    local y = ENCODER_API.DecodeDecimal(message:sub(6, 8))
    local z = ENCODER_API.DecodeDecimal(message:sub(9, 11))
    kf.position = Vector3.New(signTable[1] and x or -x, signTable[2] and y or -y, signTable[3] and z or -z)
    x = ENCODER_API.DecodeDecimal(message:sub(12, 14))
    y = ENCODER_API.DecodeDecimal(message:sub(15, 17))
    z = ENCODER_API.DecodeDecimal(message:sub(18, 20))
    kf.offset = Vector3.New(signTable[4] and x or -x, signTable[5] and y or -y, signTable[6] and z or -z)
    x = ENCODER_API.DecodeDecimal(message:sub(21, 23))
    y = ENCODER_API.DecodeDecimal(message:sub(24, 26))
    z = ENCODER_API.DecodeDecimal(message:sub(27, 29))
    kf.rotation = Rotation.New(x > 180 and -(360 - x) or x, y > 180 and - (360 - y) or y, z > 180 and - (360 - z) or z )
    kf.time = ENCODER_API.DecodeDecimal(message:sub(30, 32))
    kf.weight = CoreMath.Round(ENCODER_API.DecodeNetwork(message:sub(33, 34)) / 1000, 3)
    kf.blendIn = ENCODER_API.DecodeDecimal(message:sub(35, 37))
    kf.blendOut = ENCODER_API.DecodeDecimal(message:sub(38, 40))
    return kf
end

function ProcessAnimationData(message)
    local index = 2
    local maxSeconds = ENCODER_API.DecodeDecimal(message:sub(index,index + 2))
    if LOCAL_PLAYER.clientUserData.maxSeconds ~= maxSeconds then
        LOCAL_PLAYER.clientUserData.maxSeconds = maxSeconds
        API.UpdateTimeDisplayCallback(nil)
    end
    index = index + 3
    local scale = ENCODER_API.DecodeByte(message:sub(index,index))
    index = index + 1
    local oldTickMark = LOCAL_PLAYER.clientUserData.tickMarkNum
    if scale ~= oldTickMark then
        API.ChangeTLScale(scale)
    end

    for i = 1, 5 do
        local size = ENCODER_API.DecodeNetwork(message:sub(index, index + 1))
        index = index + 2
        if size > 0 then
            for j = 1, size do
                local keyFrame = DecodeKeyFrame(message:sub(index, index + 39)) --size of 40
                API.LoadKeyFrame(keyFrame, i, keyFrame.time)
                index = index + 40
            end
        end
    end
    LOCAL_PLAYER.clientUserData.loading = false
end
function NetworkedMessage(obj, key)
    if key =="Message" then
        local message = obj:GetCustomProperty(key)
        if message then
            local opCode = ENCODER_API.DecodeByte(message:sub(1, 1))
            if opCode == 1 then
                UpdateAnimationNames(message)
            end
            if opCode == 2 then
                --TODO: Timeline settings such as max and increment size
                ProcessAnimationData(message)
            end
        end
    end
end
-- PREVIEW

local isPlaying = false
local currentTime = 0
local tickMarkSize = 100

local SCREEN_SIZE = UI.GetScreenSize()
TIME_LINE.width = math.floor(SCREEN_SIZE.x - 100)
local currentTimeDisplay = World.SpawnAsset(CURRENT_TIME, {parent = TIME_LINE})

local tickMarks = {}

function UpdateTickMarks()
    local maxSeconds = LOCAL_PLAYER.clientUserData.maxSeconds
    tickMarkSize = TIME_LINE.width / maxSeconds
    local tickNum = math.floor(maxSeconds)
    if #tickMarks > tickNum then
        for i = #tickMarks, tickNum, -1 do
            tickMarks[i]:Destroy()
            table.remove(tickMarks, i)
        end
    elseif #tickMarks < tickNum then
        for i = #tickMarks + 1, tickNum do
            table.insert(tickMarks, World.SpawnAsset(SECOND_LABEL, {parent = TIME_LINE}))
        end
    end
    for i = 1, tickNum do
        tickMarks[i].x = i * tickMarkSize
    end
end

function OpenPreview(button)
    if LOCAL_PLAYER.clientUserData.currentAnimation then
        UpdateTickMarks()
        API.CleanUp(LOCAL_PLAYER)
        PREVIEW_SCREEN.visibility = Visibility.INHERIT
    end
end
PREVIEW.clickedEvent:Connect(OpenPreview)

function GoBack(button)
    PREVIEW_SCREEN.visibility = Visibility.FORCE_OFF
    isPlaying = false
    STATUS.text = "Idle"
    API.PushToQueue({"StopAnimation"})
end
BACK.clickedEvent:Connect(GoBack)

function PlayAnimation(button)
    if not isPlaying then
        isPlaying = true
        API.PushToQueue({"PlayAnimation"})
        STATUS.text = "Playing"
    end
end
PLAY_BUTTON.clickedEvent:Connect(PlayAnimation)

function StopAnimation(button)
    if isPlaying then
        API.PushToQueue({"StopAnimation"})
        isPlaying = false
        STATUS.text = "Idle"
    end
end
STOP.clickedEvent:Connect(StopAnimation)

local isDragging = false
function DragStart(button)
    if not isPlaying then
        isDragging = true
    end
end

function DragEnd(button)
    isDragging = false
    API.PushToQueue({"SetPreviewTime", currentTime})
end

function UpdateDrag()
    local offset = UI.GetCursorPosition().x - 50
    currentTime = CoreMath.Round(CoreMath.Clamp(offset / tickMarkSize, 0, LOCAL_PLAYER.clientUserData.maxSeconds), 3)
end

TIME_LINE.pressedEvent:Connect(DragStart)
TIME_LINE.releasedEvent:Connect(DragEnd)

function Tick(deltaTime)
    if isDragging then
        UpdateDrag()
    end
    TIME.text = tostring(CoreMath.Round(currentTime, 3))
    currentTimeDisplay.x = TIME_LINE.x + currentTime * tickMarkSize - 5
end

function UpdateTime(obj, key)
    if key == "Time" then
        currentTime = obj:GetCustomProperty("Time")
    end
end

UpdateTime(PLAYBACK_TIME, "Time")
local l1 = PLAYBACK_TIME.customPropertyChangedEvent:Connect(UpdateTime)

Game.playerJoinedEvent:Connect(Join)
local l2 = NETWORKED.customPropertyChangedEvent:Connect(NetworkedMessage)

script.destroyEvent:Connect(
    function(obj)
        l1:Disconnect()
        l2:Disconnect()
    end
)
--Send initial message to get animations
Task.Wait()
API.FullCleanUp(LOCAL_PLAYER)
API.PushToQueue({"GetAnimations"})


