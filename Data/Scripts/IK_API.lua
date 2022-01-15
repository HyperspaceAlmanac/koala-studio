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
API.PropToIndex = {}

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

function API.UpdateAnchors(player, currentTime)
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
            if left then
                if left.active then
                
                else
                
                end
            else
                anchor.weight = right.weight
                anchor.blendInTime = right.blendIn
                
            end
        else
            if #sortedKF > 0 then
                local last = sortedKF[#sortedKF]
                anchor.blendOutTime = last.blendOut
                anchor.weight = last.weight
            end
            if anchor.target then
                anchor:Deactivate()
            end
        end
    end
end

function API.PlayerJoin(player, anchors)
    API.SortedKF[player] = {}
    API.Anchors[player] = {}
    for _, anchor in ipairs(anchors) do
        table.insert(API.Anchors[player], anchor)
    end
end

function API.PlayerLeft(player)
    API.SortedKF[player] = nil
    API.Anchors[player] = nil
end

function API.Hello()
    print("Hello")
end


API.initializing = false
return API