-- API
local API = require(script:GetCustomProperty("AnimatorClientAPI"))

-- UI 

local R_XL = script:GetCustomProperty("rXL"):WaitForObject() ---@type UIButton
local R_YL = script:GetCustomProperty("rYL"):WaitForObject() ---@type UIButton
local R_ZL = script:GetCustomProperty("rZL"):WaitForObject() ---@type UIButton

local LINE = script:GetCustomProperty("Line2"):WaitForObject() ---@type UIText
local ANCHOR_EDITOR = script:GetCustomProperty("AnchorEditor"):WaitForObject() ---@type UIPanel
local EFFECTS_EDITOR = script:GetCustomProperty("EffectsEditor"):WaitForObject() ---@type UIPanel
local TRANSFORM = script:GetCustomProperty("Transform"):WaitForObject() ---@type UIPanel
local ANCHOR = script:GetCustomProperty("Anchor"):WaitForObject() ---@type UIPanel
local EDITMODE = script:GetCustomProperty("Editmode"):WaitForObject() ---@type UIPanel
local EDIT_MENU = script:GetCustomProperty("EditMenu"):WaitForObject() ---@type UIPanel
local P_X = script:GetCustomProperty("pX"):WaitForObject() ---@type UIButton
local P_Y = script:GetCustomProperty("pY"):WaitForObject() ---@type UIButton
local P_Z = script:GetCustomProperty("pZ"):WaitForObject() ---@type UIButton
local R_X = script:GetCustomProperty("rX"):WaitForObject() ---@type UIButton
local R_Y = script:GetCustomProperty("rY"):WaitForObject() ---@type UIButton
local R_Z = script:GetCustomProperty("rZ"):WaitForObject() ---@type UIButton
local WEIGHT_BUTTON = script:GetCustomProperty("weightButton"):WaitForObject() ---@type UIButton
local BLEND_IN_BUTTON = script:GetCustomProperty("blendInButton"):WaitForObject() ---@type UIButton
local BLEND_OUT_BUTTON = script:GetCustomProperty("blendOutButton"):WaitForObject() ---@type UIButton
local O_X = script:GetCustomProperty("oX"):WaitForObject() ---@type UIButton
local O_Y = script:GetCustomProperty("oY"):WaitForObject() ---@type UIButton
local O_Z = script:GetCustomProperty("oZ"):WaitForObject() ---@type UIButton
local ACTIVATED = script:GetCustomProperty("Activated"):WaitForObject() ---@type UIButton
local TIME_BUTTON = script:GetCustomProperty("TimeButton"):WaitForObject() ---@type UIButton
local TRANSFORM_BUTTON = script:GetCustomProperty("TransformButton"):WaitForObject() ---@type UIButton
local ANCHOR_BUTTON = script:GetCustomProperty("AnchorButton"):WaitForObject() ---@type UIButton
local DUPLICATE = script:GetCustomProperty("Duplicate"):WaitForObject() ---@type UIButton
local DELETE = script:GetCustomProperty("Delete"):WaitForObject() ---@type UIButton

local LOCAL_PLAYER = Game.GetLocalPlayer()
LOCAL_PLAYER.clientUserData.lastPressed = nil
local anchorTable = {}
local white = Color.New(1, 1, 1)
local gray = Color.New(0.5, 0.5, 0.5)


function ButtonReleased(button)
    local prevButton = LOCAL_PLAYER.clientUserData.lastPressed
    if prevButton then
        if prevButton.clientUserData.index then
            prevButton:SetButtonColor(white)
        end
    end
    LOCAL_PLAYER.clientUserData.lastPressed = button
    if button.clientUserData.index then
        button:SetButtonColor(gray)
    end
    if button.clientUserData.value == "transform" then
    	TRANSFORM.visibility = Visibility.INHERIT
    	ANCHOR.visibility = Visibility.FORCE_OFF
    elseif button.clientUserData.value == "anchor" then
        TRANSFORM.visibility = Visibility.FORCE_OFF
    	ANCHOR.visibility = Visibility.INHERIT
   	elseif button.clientUserData.value == "duplicate" then
   	elseif button.clientUserData.value == "delete" then
   	end
end

function DeleteCurrentKeyFrame()
    if LOCAL_PLAYER.clientUserData.currentKeyFrame then
        local kf = LOCAL_PLAYER.clientUserData.currentKeyFrame
        local kfTable = LOCAL_PLAYER.clientUserData.anchors[kf.clientUserData.anchorIndex]
        local foundIndex = nil
        for i, b in ipairs(kfTable) do
            if b == kf then
                foundIndex = i
            else
                if foundIndex and i > foundIndex then
                    b.clientUserData.timelineIndex = b.clientUserData.timelineIndex - 1
                end
            end
        end
        if foundIndex then
            table.remove(kfTable, foundIndex)
            API.PushToQueue({"DeleteKeyFrame", kf.clientUserData.anchorIndex, foundIndex})
        end
        kf:Destroy()
        LOCAL_PLAYER.clientUserData.currentKeyFrame = nil
    end
end

function Initialize()
    P_X.clientUserData.value = "px"
    table.insert(anchorTable, P_X)
    P_X.clientUserData.index = #table

    P_Y.clientUserData.value = "py"
    table.insert(anchorTable, P_Y)
    P_Y.clientUserData.index = #table

    P_Z.clientUserData.value = "pz"
    table.insert(anchorTable, P_Z)
    P_Z.clientUserData.index = #table

    R_X.clientUserData.value = "rx"
    table.insert(anchorTable, R_X)
    R_X.clientUserData.index = #table

    R_Y.clientUserData.value = "ry"
    table.insert(anchorTable, R_Y)
    R_Y.clientUserData.index = #table

    R_Z.clientUserData.value = "rz"
    table.insert(anchorTable, R_Z)
    R_Z.clientUserData.index = #table

    WEIGHT_BUTTON.clientUserData.value = "weight"
    table.insert(anchorTable, WEIGHT_BUTTON)
    WEIGHT_BUTTON.clientUserData.index = #table

    BLEND_IN_BUTTON.clientUserData.value = "blendIn"
    table.insert(anchorTable, BLEND_IN_BUTTON)
    BLEND_IN_BUTTON.clientUserData.index = #table

    BLEND_OUT_BUTTON.clientUserData.value = "blendOut"
    table.insert(anchorTable, BLEND_OUT_BUTTON)
    BLEND_OUT_BUTTON.clientUserData.index = #table

    O_X.clientUserData.value = "ox"
    table.insert(anchorTable, O_X)
    O_X.clientUserData.index = #table

    O_Y.clientUserData.value = "oy"
    table.insert(anchorTable, O_Y)
    O_Y.clientUserData.index = #table

    O_Z.clientUserData.value = "oz"
    table.insert(anchorTable, O_Z)
    O_Z.clientUserData.index = #table

    TIME_BUTTON.clientUserData.value = "time"
    table.insert(anchorTable, TIME_BUTTON)
    TIME_BUTTON.clientUserData.index = #table

    for _, b in ipairs(anchorTable) do
        b.clientUserData.released = b.releasedEvent:Connect(ButtonReleased)
    end

    TRANSFORM_BUTTON.clientUserData.value = "transform"
    TRANSFORM_BUTTON.clientUserData.released = TRANSFORM_BUTTON.releasedEvent:Connect(ButtonReleased)
    ANCHOR_BUTTON.clientUserData.value = "anchor"
    ANCHOR_BUTTON.clientUserData.released = ANCHOR_BUTTON.releasedEvent:Connect(ButtonReleased)
    ACTIVATED.clickedEvent:Connect(
        function (button)
            local kf = LOCAL_PLAYER.clientUserData.currentKeyFrame
            if kf then
                local original = kf.clientUserData.prop.activated
                kf.clientUserData.prop.activated = not original
                API.PushToQueue({"UpdateKFActive", kf.clientUserData.anchorIndex, kf.clientUserData.timelineIndex, not original}) 
            end
        end
    )
    DUPLICATE.clientUserData.value = "duplicate"
    DUPLICATE.clientUserData.released = DUPLICATE.releasedEvent:Connect(ButtonReleased)
    DELETE.clientUserData.value = "delete"
    DELETE.clientUserData.released = DELETE.releasedEvent:Connect(ButtonReleased)

    DELETE.clickedEvent:Connect(
        function(button)
            if API.DeleteCallback and LOCAL_PLAYER.clientUserData.currentKeyFrame then
                API.DeleteCallback("KeyFrame", DeleteCurrentKeyFrame)
            end
        end
    )

    DUPLICATE.clickedEvent:Connect(
        function(button)
            local prevButton = LOCAL_PLAYER.clientUserData.lastPressed
            if prevButton then
                if prevButton.clientUserData.index then
                    prevButton:SetButtonColor(white)
                end
            end
            LOCAL_PLAYER.clientUserData.lastPressed = nil
            API.DuplicateKFCallback()
        end
    )
    R_XL.clickedEvent:Connect(
        function(button)
            local kf = LOCAL_PLAYER.clientUserData.currentKeyFrame
            if kf then
                local updated = not kf.clientUserData.prop.rxl
                kf.clientUserData.prop.rxl = updated
                API.PushToQueue({"UpdateKFrxl", kf.clientUserData.anchorIndex, kf.clientUserData.timelineIndex, updated})
            end
        end
    )
    R_YL.clickedEvent:Connect(
        function(button)
            local kf = LOCAL_PLAYER.clientUserData.currentKeyFrame
            if kf then
                local updated = not kf.clientUserData.prop.ryl
                kf.clientUserData.prop.ryl = updated
                API.PushToQueue({"UpdateKFryl", kf.clientUserData.anchorIndex, kf.clientUserData.timelineIndex, updated})
            end
        end
    )
    R_ZL.clickedEvent:Connect(
        function(button)
            local kf = LOCAL_PLAYER.clientUserData.currentKeyFrame
            if kf then
                local updated = not kf.clientUserData.prop.rzl
                kf.clientUserData.prop.rzl = updated
                API.PushToQueue({"UpdateKFrzl", kf.clientUserData.anchorIndex, kf.clientUserData.timelineIndex, updated})
            end
        end
    )
end

function ToRoundedString(number)
    return tostring(CoreMath.Round(number, 3))
end

function UpdateStatus()
    if not LOCAL_PLAYER.clientUserData.currentKeyFrame then
        ANCHOR_EDITOR.visibility = Visibility.FORCE_OFF
    else
        ANCHOR_EDITOR.visibility = Visibility.INHERIT
        local values = LOCAL_PLAYER.clientUserData.currentKeyFrame.clientUserData.prop
        P_X.text = ToRoundedString(values.position.x)

        P_Y.text = ToRoundedString(values.position.y)
    
        P_Z.text = ToRoundedString(values.position.z)

        R_X.text = ToRoundedString(values.rotation.x)

        R_Y.text = ToRoundedString(values.rotation.y)

        R_Z.text = ToRoundedString(values.rotation.z)

        WEIGHT_BUTTON.text = ToRoundedString(values.weight)

        BLEND_IN_BUTTON.text = ToRoundedString(values.blendIn)

        BLEND_OUT_BUTTON.text = ToRoundedString(values.blendOut)

        O_X.text = ToRoundedString(values.offset.x)
        O_Y.text = ToRoundedString(values.offset.y)
        O_Z.text = ToRoundedString(values.offset.z)
        ACTIVATED.text = values.activated and "Activated" or "Deactivated"
        local kf = LOCAL_PLAYER.clientUserData.currentKeyFrame
        TIME_BUTTON.text = "Time: "..ToRoundedString((kf.x + 25) / (LOCAL_PLAYER.clientUserData.tickMarkNum * 100))
        
        local lp = LOCAL_PLAYER.clientUserData.lastPressed
        if lp and (lp.clientUserData.value == "time" or lp.clientUserData.index) then
            local value = lp.clientUserData.value
            if value == "time" then
                LINE.text = "Current key frame time"
            elseif value == "px" then
                LINE.text = "Position.x"
            elseif value == "py" then
                LINE.text = "Position.y"
            elseif value == "pz" then
                LINE.text = "Position.z"
            elseif value == "rx" then
                LINE.text = "Rotation.x, Checkbox\nfor longer path"
            elseif value == "ry" then
                LINE.text = "Rotation.y, Checkbox\nfor longer path"
            elseif value == "rz" then
                LINE.text = "Rotation.z, Checkbox\nfor longer path"
            elseif value == "ox" then
                LINE.text = "IK Anchor Offset.x"
            elseif value == "oy" then
                LINE.text = "IK Anchor Offset.y"
            elseif value == "oz" then
                LINE.text = "IK Anchor Offset.z"
            elseif value == "weight" then
                LINE.text = "IK Anchor Weight"
            elseif value == "blendIn" then
                LINE.text = "IK Anchor BlendIn Time"
            elseif value == "blendOut" then
                LINE.text = "IK Anchor BlendOut Time"
            else
                LINE.text = ""
            end
        else
            LINE.text = ""
        end
        if kf.clientUserData.prop.rxl then
            R_XL.text = "X"
        else
            R_XL.text = ""
        end
        if kf.clientUserData.prop.ryl then
            R_YL.text = "X"
        else
            R_YL.text = ""
        end
        if kf.clientUserData.prop.rzl then
            R_ZL.text = "X"
        else
            R_ZL.text = ""
        end
    end
end

Initialize()
function Tick(deltaTime)
    UpdateStatus()
end