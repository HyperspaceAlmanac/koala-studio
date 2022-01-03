-- Templates 
local KEY_FRAME_BUTTON = script:GetCustomProperty("KeyFrameButton")
local SECOND_LABEL = script:GetCustomProperty("SecondLabel")

-- Custom 
local SCROLLING_TIMELINE = script:GetCustomProperty("ScrollingTimeline"):WaitForObject() ---@type UIScrollPanel
local ANCHORS = script:GetCustomProperty("Anchors"):WaitForObject() ---@type UIPanel
local TICK_MARKS = script:GetCustomProperty("TickMarks"):WaitForObject() ---@type UIPanel

local SCREEN_SIZE = UI.GetScreenSize()

local lastHoveredAnchor = nil
local currentKeyFrame = nil
local keyFrameTable = {}
local tickMarks = {}

function UpdateTickMarks(seconds)
    ANCHORS.width = seconds * 200 + 10
    if #tickMarks > seconds then
        for i = #tickMarks, seconds + 1, -1 do
            tickMarks[i]:Destroy()
            table.remove(tickMarks, i)
        end
    elseif #tickMarks < seconds then
        for i = #tickMarks + 1, seconds do
            table.insert(tickMarks, World.SpawnAsset(SECOND_LABEL, {parent = TICK_MARKS}))
        end
    end
    for i = 1, seconds do
        tickMarks[i].x = i * 200
    end
end

UpdateTickMarks(15)
Task.Spawn(
    function()
        Task.Wait(5)
        UpdateTickMarks(10)
    end
)

function PressKeyFrame(button)
    currentKeyFrame = button
end

function ReleaseKeyFrame(button)
    currentKeyFrame = nil
end

function HoverAnchor(button)
    lastHoveredAnchor = button
end

function ClickAnchor(button)
    local offset = UI.GetCursorPosition().x - SCROLLING_TIMELINE.x + SCROLLING_TIMELINE.scrollPosition
    local kfButton = World.SpawnAsset(KEY_FRAME_BUTTON, {parent = button})
    kfButton.clientUserData.pressed = kfButton.pressedEvent:Connect(PressKeyFrame)
    kfButton.clientUserData.released = kfButton.releasedEvent:Connect(ReleaseKeyFrame)
    table.insert(keyFrameTable, kfButton)
    kfButton.x = offset - 25
    kfButton.y = 0
end

for _, button in ipairs(ANCHORS:GetChildren()) do
    keyFrameTable[button] = {}
    button.hoveredEvent:Connect(HoverAnchor)
    button.clickedEvent:Connect(ClickAnchor)
end

function Tick(deltaTime)
    if currentKeyFrame then
        local offset = UI.GetCursorPosition().x - SCROLLING_TIMELINE.x + SCROLLING_TIMELINE.scrollPosition - 25
        currentKeyFrame.x = CoreMath.Clamp(offset, -25, ANCHORS.width -25)
    end
end
SCROLLING_TIMELINE.width = math.floor(SCREEN_SIZE.x - 250)
UI.SetCursorVisible(true)



