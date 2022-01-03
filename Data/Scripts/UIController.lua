
-- Templates 
local KEY_FRAME_BUTTON = script:GetCustomProperty("KeyFrameButton")

-- Custom 
local SCROLLING_TIMELINE = script:GetCustomProperty("ScrollingTimeline"):WaitForObject() ---@type UIScrollPanel

local SCREEN_SIZE = UI.GetScreenSize()

local lastHoveredAnchor = nil
local keyFrameTable = {}
function HoverAnchor(button)
    lastHoveredAnchor = button
end

function ClickAnchor(button)
    local offset = UI.GetCursorPosition().x - SCROLLING_TIMELINE.x + SCROLLING_TIMELINE.scrollPosition
    local kfButton = World.SpawnAsset(KEY_FRAME_BUTTON, {parent = button})
    table.insert(keyFrameTable, kfButton)
    kfButton.x = offset - 25
    kfButton.y = 0
end
for _, button in ipairs(SCROLLING_TIMELINE:GetChildren()) do
    keyFrameTable[button] = {}
    button.hoveredEvent:Connect(HoverAnchor)
    button.clickedEvent:Connect(ClickAnchor)
end
SCROLLING_TIMELINE.width = math.floor(SCREEN_SIZE.x - 250)
UI.SetCursorVisible(true)



