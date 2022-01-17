-- Custom 
local API = require(script:GetCustomProperty("AnimatorClientAPI"))

-- Templates 
local KEY_FRAME_BUTTON = script:GetCustomProperty("KeyFrameButton")
local SECOND_LABEL = script:GetCustomProperty("SecondLabel")

-- Custom
local TIME_LINE = script:GetCustomProperty("TimeLine"):WaitForObject() ---@type UIPanel
local SCROLLING_TIMELINE = script:GetCustomProperty("ScrollingTimeline"):WaitForObject() ---@type UIScrollPanel
local ANCHORS = script:GetCustomProperty("Anchors"):WaitForObject() ---@type UIPanel
local TICK_MARKS = script:GetCustomProperty("TickMarks"):WaitForObject() ---@type UIPanel

local TIME_BUTTON = script:GetCustomProperty("TimeButton"):WaitForObject() ---@type UIButton
local B_1 = script:GetCustomProperty("B1"):WaitForObject() ---@type UIButton
local B_2 = script:GetCustomProperty("B2"):WaitForObject() ---@type UIButton
local B_3 = script:GetCustomProperty("B3"):WaitForObject() ---@type UIButton
local B_4 = script:GetCustomProperty("B4"):WaitForObject() ---@type UIButton

local SCREEN_SIZE = UI.GetScreenSize()
local LOCAL_PLAYER = Game.GetLocalPlayer()

local tickMarkScale = {B_1, B_2, B_3, B_4}
local gray = Color.New(0.25, 0.25, 0.25)
local lightGray = Color.New(0.75, 0.75, 0.75)
local black = Color.New(0, 0, 0)
local white = Color.New(1, 1, 1)
LOCAL_PLAYER.clientUserData.loading = false
LOCAL_PLAYER.clientUserData.anchors = {}
LOCAL_PLAYER.clientUserData.currentKeyFrame = nil
LOCAL_PLAYER.clientUserData.draggingKeyFrame = false
LOCAL_PLAYER.clientUserData.changeMaxTime = nil
local tickMarks = {}

for i, child in ipairs(ANCHORS:GetChildren()) do
    if i == 6 then
        break
    end
    local tbl = LOCAL_PLAYER.clientUserData.anchors
    table.insert(tbl, {})
    child.clientUserData.anchorIndex = #tbl
end

LOCAL_PLAYER.clientUserData.tickMarkNum = 2
B_2:SetButtonColor(lightGray)
LOCAL_PLAYER.clientUserData.maxSeconds = 10

function UpdateTickMarks(oldSize)
    local tickMarkNum = LOCAL_PLAYER.clientUserData.tickMarkNum
    local maxSeconds = LOCAL_PLAYER.clientUserData.maxSeconds
    ANCHORS.width = maxSeconds * tickMarkNum * 100 + 10
    if #tickMarks > maxSeconds then
        for i = #tickMarks, maxSeconds + 1, -1 do
            tickMarks[i]:Destroy()
            table.remove(tickMarks, i)
        end
    elseif #tickMarks < maxSeconds then
        for i = #tickMarks + 1, maxSeconds do
            table.insert(tickMarks, World.SpawnAsset(SECOND_LABEL, {parent = TICK_MARKS}))
        end
    end
    for i = 1, maxSeconds do
        tickMarks[i].x = i * tickMarkNum * 100
    end
    --Update keyFrames
    if LOCAL_PLAYER.clientUserData.loading then
        return
    end
    if oldSize then
        for _, anchor in ipairs(LOCAL_PLAYER.clientUserData.anchors) do
            for _, kf in ipairs(anchor) do
                local time = (kf.x + 25) / (100 * oldSize) 
                kf.x = time * (100 * tickMarkNum) - 25
            end
        end
    else
        for _, anchor in ipairs(LOCAL_PLAYER.clientUserData.anchors) do
            for _, kf in ipairs(anchor) do
                kf.x = math.min(kf.x, maxSeconds * tickMarkNum * 100 - 25)
            end
        end
    end
end

API.RegisterUTD(UpdateTickMarks)
UpdateTickMarks(nil)

function PressKeyFrame(button)
    local prev = LOCAL_PLAYER.clientUserData.currentKeyFrame
    if prev then
        prev:SetButtonColor(black)
    end
    button:SetButtonColor(gray)
    LOCAL_PLAYER.clientUserData.currentKeyFrame = button
    LOCAL_PLAYER.clientUserData.draggingKeyFrame = true
    prev = LOCAL_PLAYER.clientUserData.lastPressed
    if prev and prev.clientUserData.index then
        prev:SetButtonColor(white)    
    end
    LOCAL_PLAYER.clientUserData.lastPressed = nil
    button.clientUserData.dragStartTime = time()
end

function ReleaseKeyFrame(button)
    LOCAL_PLAYER.clientUserData.draggingKeyFrame = false
    local startTime =  button.clientUserData.dragStartTime
    if startTime and time() - startTime > 0.3 then
        local time = (button.x + 25) / (LOCAL_PLAYER.clientUserData.tickMarkNum * 100)
        API.PushToQueue({"UpdateKFTime", button.clientUserData.anchorIndex, button.clientUserData.timelineIndex, time})
    else
        API.PushToQueue({"UpdateKFCurrentTime", button.clientUserData.anchorIndex, button.clientUserData.timelineIndex})
    end
    button.clientUserData.dragStartTime = nil
    button:SetButtonColor(gray)
end

function InitializeKeyFrameProperties(button)
    button.clientUserData.prop = {}
    button.clientUserData.prop.position = Vector3.New(0, 0, 0)
    button.clientUserData.prop.offset = Vector3.New(0, 0, 0)
    button.clientUserData.prop.rotation = Rotation.New(0, 0, 0)
    button.clientUserData.prop.weight = 1
    button.clientUserData.prop.blendIn = 0
    button.clientUserData.prop.blendOut = 0
    button.clientUserData.prop.activated = true
    button.clientUserData.prop.rxl = false
    button.clientUserData.prop.ryl = false
    button.clientUserData.prop.rzl = false
end

local kfProps = {"id", "position", "offset", "rotation", "weight", "blendIn", "blendOut", "activated"}

function InitializeKeyFrame(offset, kfButton, duplicate, load)
    kfButton.clientUserData.pressed = kfButton.pressedEvent:Connect(PressKeyFrame)
    kfButton.clientUserData.released = kfButton.releasedEvent:Connect(ReleaseKeyFrame)
    InitializeKeyFrameProperties(kfButton)
    local prev = LOCAL_PLAYER.clientUserData.currentKeyFrame
    if prev then
        prev:SetButtonColor(black)
    end
    prev = LOCAL_PLAYER.clientUserData.lastPressed
    if prev and prev.clientUserData.index then
        prev:SetButtonColor(white)    
    end
    LOCAL_PLAYER.clientUserData.lastPressed = nil

    if not duplicate then
        if not load then
            LOCAL_PLAYER.clientUserData.currentKeyFrame = kfButton
            kfButton:SetButtonColor(gray)
        end
        local anchorIndex = kfButton.clientUserData.anchorIndex
        local anchors = LOCAL_PLAYER.clientUserData.anchors[anchorIndex]
        kfButton.clientUserData.timelineIndex = #anchors + 1
        table.insert(anchors, kfButton)
        if not load then
            API.PushToQueue({"CreateKeyFrame", anchorIndex, (offset + 25) / (LOCAL_PLAYER.clientUserData.tickMarkNum * 100)})
        end
    end

    kfButton.x = offset
    kfButton.y = 0
end

function DuplicateKeyFrame()
    local prevKF = LOCAL_PLAYER.clientUserData.currentKeyFrame
    if prevKF then
        local kfButton =  World.SpawnAsset(KEY_FRAME_BUTTON, {parent = prevKF.parent})
        InitializeKeyFrame(prevKF.x, kfButton, true, false)
        for _, val in ipairs(kfProps) do
            if val == "rotation" then
                kfButton.clientUserData.prop[val] = Rotation.New(prevKF.clientUserData.prop[val])
            elseif val == "position" then
                kfButton.clientUserData.prop[val] = Vector3.New(prevKF.clientUserData.prop[val])
            elseif val == "offest" then
                kfButton.clientUserData.prop[val] = Vector3.New(prevKF.clientUserData.prop[val])
            else
                kfButton.clientUserData.prop[val] = prevKF.clientUserData.prop[val]
            end
        end
        local anchorIndex = prevKF.clientUserData.anchorIndex
        kfButton.clientUserData.anchorIndex = anchorIndex
        local anchors = LOCAL_PLAYER.clientUserData.anchors[kfButton.clientUserData.anchorIndex]
        kfButton.clientUserData.timelineIndex = #anchors + 1
        table.insert(anchors, kfButton)
        API.PushToQueue({"DuplicateKeyFrame", anchorIndex, prevKF.clientUserData.timelineIndex})
    end
end

API.RegisterDuplicateKF(DuplicateKeyFrame)

function LoadKeyFrame(keyFrameData, anchorIndex, time)
    local kfButton =  World.SpawnAsset(KEY_FRAME_BUTTON, {parent = ANCHORS:GetChildren()[anchorIndex]})
    kfButton.clientUserData.anchorIndex = anchorIndex

    InitializeKeyFrame(time * LOCAL_PLAYER.clientUserData.tickMarkNum * 100 - 25, kfButton, false, true)
    for key, val in pairs(keyFrameData) do
        if key ~= "time" then
            kfButton.clientUserData.prop[key] = val
        end
    end
end
API.RegisterLoadKeyFrame(LoadKeyFrame)

function ClickAnchor(button)
    local offset = UI.GetCursorPosition().x - SCROLLING_TIMELINE.x + SCROLLING_TIMELINE.scrollPosition
    local kfButton = World.SpawnAsset(KEY_FRAME_BUTTON, {parent = button})
    kfButton.clientUserData.anchorIndex = button.clientUserData.anchorIndex
    InitializeKeyFrame(offset - 25, kfButton, false, false)
end

for i, button in ipairs(ANCHORS:GetChildren()) do
    if i == 6 then
        break
    end
    button.clickedEvent:Connect(ClickAnchor)
end

function SetScale(button, index)
    tickMarkScale[LOCAL_PLAYER.clientUserData.tickMarkNum]:SetButtonColor(white)
    tickMarkScale[index]:SetButtonColor(lightGray)
    local oldSize = LOCAL_PLAYER.clientUserData.tickMarkNum
    if oldSize ~= index then
        LOCAL_PLAYER.clientUserData.tickMarkNum = index
        local anim = LOCAL_PLAYER.clientUserData.currentAnimation
        API.PushToQueue({"SetTimeScale", anim.clientUserData.id , index})
        UpdateTickMarks(oldSize)
    end
end

function SetTLScale(index)
    if index == 1 or index == 2 or index == 3 or index == 4 then
        SetScale(tickMarkScale[index], index)
    end
end

API.RegisterChangeTLScale(SetTLScale)

B_1.clickedEvent:Connect(SetScale, 1)
B_2.clickedEvent:Connect(SetScale, 2)
B_3.clickedEvent:Connect(SetScale, 3)
B_4.clickedEvent:Connect(SetScale, 4)

function SetMaxTime(button)
    button:SetButtonColor(lightGray)
    LOCAL_PLAYER.clientUserData.changeMaxTime = button
    local prev = LOCAL_PLAYER.clientUserData.currentKeyFrame
    if prev then
        prev:SetButtonColor(black)
    end
    LOCAL_PLAYER.clientUserData.currentKeyFrame = nil
    prev = LOCAL_PLAYER.clientUserData.lastPressed
    if prev and prev.clientUserData.index then
        prev:SetButtonColor(white)    
    end
    LOCAL_PLAYER.clientUserData.lastPressed = nil
end
TIME_BUTTON.clickedEvent:Connect(SetMaxTime)

function MaxTimeUpdate(num)
    local anim = LOCAL_PLAYER.clientUserData.currentAnimation
    API.PushToQueue({"SetMaxTime", anim.clientUserData.id , num})
end
API.RegisterUpdateMaxTime(MaxTimeUpdate)

function Tick(deltaTime)
    if not LOCAL_PLAYER.clientUserData.currentAnimation then
        TIME_LINE.visibility = Visibility.FORCE_OFF
        return
    end
    TIME_LINE.visibility = Visibility.INHERIT
    if LOCAL_PLAYER.clientUserData.currentKeyFrame and LOCAL_PLAYER.clientUserData.draggingKeyFrame then
        local startTime =  LOCAL_PLAYER.clientUserData.currentKeyFrame.clientUserData.dragStartTime
        if startTime and time() - startTime > 0.3 then
            local offset = UI.GetCursorPosition().x - SCROLLING_TIMELINE.x + SCROLLING_TIMELINE.scrollPosition - 25
            LOCAL_PLAYER.clientUserData.currentKeyFrame.x = CoreMath.Clamp(offset, -25, ANCHORS.width -25)
        end
    end
    TIME_BUTTON.text = tostring(CoreMath.Round(LOCAL_PLAYER.clientUserData.maxSeconds, 3))
end
SCROLLING_TIMELINE.width = math.floor(SCREEN_SIZE.x - 250)
UI.SetCursorVisible(true)



