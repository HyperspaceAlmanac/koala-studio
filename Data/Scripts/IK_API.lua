local API = {}
if _G["IK_API"] == nil then
    _G["IK_API"] = API
    API.initializng = true
else
    while API.initializing do
        Task.Wait()
    end
    return _G["IK_API"]
end

API.SortedKF = {}-- {{}, {}, {}, {}, {}} -- 5 list of curves, one for each anchor
API.Anchors = {}
API.Status = {}
API.PropToIndex = {}
API.MoveTo = nil

local VALUES = {"px", "py", "pz", "rx", "ry", "rz", "ox", "oy", "oz", "weight", "blendIn", "blendOut", "active"}
for i, key in ipairs(VALUES) do
    API.PropToIndex[key] = i
end

function Compare(kf1, kf2)
    return kf1.time <= kf2.time
end

function SearchKF(player, anchor, left, right, KeyFrame)
end

function InsertKF(kftable, KeyFrame, left, right)

end

function API.CreateSortedKFs(player, anchor, keyFrames)
    API.SortedKF[player][anchor] = {}
    local sorted = API.SortedKF[player][anchor]
    for _, kf in ipairs(keyFrames) do
        table.insert(sorted, kf)
    end
    table.sort(sorted, Compare)
end

function API.UpdateKF(player, anchor, keyFrame)
    local sortedKF =  API.SortedKF[player][anchor]
    if #sortedKF == 1 then
        return
    end
    for i, val in ipairs(sortedKF) do
        if val == keyFrame then
            table.remove(sortedKF, i)
        end
    end
    API.AddKF(player, anchor, keyFrame)
end

function API.AddKF(player, anchor, keyFrame)
    local sortedKF =  API.SortedKF[player][anchor]
    if #sortedKF == 0 then
        table.insert(sortedKF, keyFrame)
    else
        for i, val in ipairs(sortedKF) do
            if val.time >= keyFrame.time then
                table.insert(sortedKF, i, keyFrame)
                return
            end
        end
    end
    table.insert(sortedKF, keyFrame)
end

function API.DeleteKF(player, anchor, keyFrame)
    local sortedKF =  API.SortedKF[player][anchor]
    for i, val in ipairs(sortedKF) do
        if val == keyFrame then
            table.remove(sortedKF, i)
            return
        end
    end
end

function RotationPathing(sr, er, progress, longRoute)
    sr = sr < 0 and sr + 360 or sr
    er = er < 0 and er + 360 or er
    local diff = er - sr
    if diff >= 0 then
        if diff >= 180 then
            if longRoute then
                return (sr + diff * progress) % 360
            else
                return (sr - (360 - diff) * progress) % 360
            end
        else
            if longRoute then
                return (sr - (360 - diff) * progress) % 360
            else
                return (sr + diff * progress) % 360
            end
        end
    else
        -- need to run tests and double check math
        local opposite = diff + 360
        if diff <= -180 then
            if longRoute then
                return (sr + diff * progress) % 360
            else
                return (sr + opposite * progress) % 360
            end
        else
            if longRoute then
                return (sr + opposite * progress) % 360                
            else
                return (sr + diff * progress) % 360
            end
        end
    end

end

function API.UpdateAnchors(player, currentTime)
    currentTime = CoreMath.Round(currentTime, 3)
    local editMode = API.Status[player].edit
    for i = 1, 5 do
        local sortedKF =  API.SortedKF[player][i]
        local anchor = API.Anchors[player][i]
        local left = nil
        local right = nil
        for j, kf in ipairs(sortedKF) do
            if kf.time >= currentTime then --found right side
                if j > 1 then
                    left = sortedKF[j - 1]
                    right = sortedKF[j]
                    break
                else
                    right = sortedKF[j]
                    break
                end
            end
        end
        if right then
            anchor.weight = right.weight
            anchor.blendInTime = right.blendIn
            if left then
                anchor.blendOutTime = left.blendOut
                local rightTime = CoreMath.Round(right.time, 3)
                if left.active then
                    if not anchor.serverUserData.active then
                        anchor:Activate(player)
                    end
                    local timeDiff = currentTime - left.time
                    local percentage = timeDiff / (right.time - left.time)
                    local positionDiff = right.position - left.position
                    anchor:SetPosition(left.position + positionDiff * percentage)
                    local rx = RotationPathing(left.rotation.x, right.rotation.x, percentage, right.rxl)
                    local ry = RotationPathing(left.rotation.y, right.rotation.y, percentage, right.ryl)
                    local rz = RotationPathing(left.rotation.z, right.rotation.z, percentage, right.rzl)
                    anchor:SetRotation(Rotation.New(rx, ry, rz))
                    local offsetDiff = right.offset - left.offset
                    anchor:SetAimOffset(left.offset + offsetDiff * percentage)
                else
                    if currentTime < rightTime then
                        if anchor.serverUserData.active then
                            anchor:Deactivate()
                        end
                    elseif currentTime == rightTime and editMode then
                        if not anchor.serverUserData.active then
                            anchor:Activate(player)
                        end
                    end
                    anchor:SetRotation(right.rotation)
                    anchor:SetPosition(right.position)
                    anchor:SetAimOffset(right.offset)
                end
            else
                local rightTime = CoreMath.Round(right.time, 3)
                if currentTime < rightTime then
                    if anchor.serverUserData.active then
                        anchor:Deactivate()
                    end
                    if i == 1 then
                        anchor:SetRotation(Rotation.New(0, 0, 0))
                        anchor:SetPosition(Vector3.New(0, 0, 0))
                        player:SetWorldRotation(anchor:GetWorldRotation())
                    end
                elseif currentTime == rightTime and editMode then
                    if not anchor.serverUserData.active then
                        anchor:Activate(player)
                    end
                end
                anchor:SetRotation(right.rotation)
                anchor:SetPosition(right.position)
                anchor:SetAimOffset(right.offset)
            end
        else
            if #sortedKF > 0 then
                local last = sortedKF[#sortedKF]
                anchor.blendOutTime = last.blendOut
                anchor.weight = last.weight
                anchor:SetRotation(last.rotation)
                anchor:SetPosition(last.position)
                anchor:SetAimOffset(last.offset)
            end
            if anchor.serverUserData.active then
                anchor:Deactivate()
                if i == 1 then
                    anchor:SetRotation(Rotation.New(0, 0, 0))
                    anchor:SetPosition(Vector3.New(0, 0, 0))
                    player:SetWorldRotation(anchor:GetWorldRotation())
                end
            end
        end
    end
end

function API.PlayerJoin(player, anchors, editorMode)
    API.SortedKF[player] = {}
    API.Anchors[player] = {}
    API.Status[player] = { isPlaying = false, currentTime = 0, edit = editorMode}
    for _, anchor in ipairs(anchors) do
        table.insert(API.Anchors[player], anchor)
    end
end

function API.PlayerLeft(player)
    API.SortedKF[player] = nil
    API.Anchors[player] = nil
    API.Status[player] = nil
end

function API.Hello()
    print("Hello")
end

function API.RegisterMoveTo(callback)
    API.MoveTo = callback
end


API.initializing = false
return API