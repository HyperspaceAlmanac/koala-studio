-- Custom 
local API = require(script:GetCustomProperty("AnimatorClientAPI"))

-- Templates 
local KEY_FRAME_BUTTON = script:GetCustomProperty("KeyFrameButton")
local SECOND_LABEL = script:GetCustomProperty("SecondLabel")

-- Custom 
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

local lastHoveredAnchor = nil
local tickMarkScale = {B_1, B_2, B_3, B_4}
local gray = Color.New(0.25, 0.25, 0.25)
local lightGray = Color.New(0.75, 0.75, 0.75)
local black = Color.New(0, 0, 0)
local white = Color.New(1, 1, 1)
LOCAL_PLAYER.clientUserData.currentKeyFrame = nil
LOCAL_PLAYER.clientUserData.draggingKeyFrame = false
LOCAL_PLAYER.clientUserData.changeMaxTime = nil
local keyFrameTable = {}
local tickMarks = {}

LOCAL_PLAYER.clientUserData.tickMarkNum = 2
B_2:SetButtonColor(lightGray)
LOCAL_PLAYER.clientUserData.maxSeconds = 10

function UpdateTickMarks()
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
end

API.RegisterUTD(UpdateTickMarks)
UpdateTickMarks()

function PressKeyFrame(button)
    local prev = LOCAL_PLAYER.clientUserData.currentKeyFrame
    if prev then
        prev:SetButtonColor(black)
    end
    button:SetButtonColor(gray)
    LOCAL_PLAYER.clientUserData.currentKeyFrame = button
    LOCAL_PLAYER.clientUserData.draggingKeyFrame = true
    prev = LOCAL_PLAYER.clientUserData.lastPressed
    if prev then
        prev:SetButtonColor(white)    
    end
    LOCAL_PLAYER.clientUserData.lastPressed = nil
end

function ReleaseKeyFrame(button)
    LOCAL_PLAYER.clientUserData.draggingKeyFrame = false
    button:SetButtonColor(gray)
end

function HoverAnchor(button)
    lastHoveredAnchor = button
end

function InitializeKeyFrameProperties(button, offset)
    button.clientUserData.prop = {}
    button.clientUserData.prop.id = 1
    button.clientUserData.prop.position = Vector3.New(0, 0, 0)
    button.clientUserData.prop.offset = Vector3.New(0, 0, 0)
    button.clientUserData.prop.rotation = Rotation.New(0, 0, 0)
    button.clientUserData.prop.weight = 1
    button.clientUserData.prop.blendIn = 0
    button.clientUserData.prop.blendOut = 0
    button.clientUserData.prop.activated = true
end

function ClickAnchor(button)
    local offset = UI.GetCursorPosition().x - SCROLLING_TIMELINE.x + SCROLLING_TIMELINE.scrollPosition
    local kfButton = World.SpawnAsset(KEY_FRAME_BUTTON, {parent = button})
    kfButton.clientUserData.pressed = kfButton.pressedEvent:Connect(PressKeyFrame)
    kfButton.clientUserData.released = kfButton.releasedEvent:Connect(ReleaseKeyFrame)
    InitializeKeyFrameProperties(kfButton, offset - 25)
    table.insert(keyFrameTable, kfButton)
    local prev = LOCAL_PLAYER.clientUserData.currentKeyFrame
    if prev then
        prev:SetButtonColor(black)
    end
    LOCAL_PLAYER.clientUserData.currentKeyFrame = kfButton
    kfButton:SetButtonColor(gray)
    kfButton.x = offset - 25
    kfButton.y = 0
end

for _, button in ipairs(ANCHORS:GetChildren()) do
    keyFrameTable[button] = {}
    button.hoveredEvent:Connect(HoverAnchor)
    button.clickedEvent:Connect(ClickAnchor)
end

function SetScale(button, index)
    tickMarkScale[LOCAL_PLAYER.clientUserData.tickMarkNum]:SetButtonColor(white)
    tickMarkScale[index]:SetButtonColor(lightGray)
    LOCAL_PLAYER.clientUserData.tickMarkNum = index
    UpdateTickMarks()
end

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
    if prev then
        prev:SetButtonColor(white)    
    end
    LOCAL_PLAYER.clientUserData.lastPressed = nil
end
TIME_BUTTON.clickedEvent:Connect(SetMaxTime)

function Tick(deltaTime)
    if LOCAL_PLAYER.clientUserData.currentKeyFrame and LOCAL_PLAYER.clientUserData.draggingKeyFrame then
        local offset = UI.GetCursorPosition().x - SCROLLING_TIMELINE.x + SCROLLING_TIMELINE.scrollPosition - 25
        LOCAL_PLAYER.clientUserData.currentKeyFrame.x = CoreMath.Clamp(offset, -25, ANCHORS.width -25)
    end
    TIME_BUTTON.text = tostring(CoreMath.Round(LOCAL_PLAYER.clientUserData.maxSeconds, 3))
end
SCROLLING_TIMELINE.width = math.floor(SCREEN_SIZE.x - 250)
UI.SetCursorVisible(true)



