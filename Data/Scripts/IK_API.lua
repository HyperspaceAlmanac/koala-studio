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

function BinSearchKF(player, anchor, time, key)
end

function BinInsertKF(player, anchor, time, kf)
    
end

function API.CreateCurve(player, anchor, keyFrames)
    API.SortedKF[player][anchor] = {}
end

function API.UpdateKF(player, anchor, index, key, val)
end

function API.AddKF(player, anchor, keyFrame)
end

function API.DeleteKF(plyaer, anchor, index)
end

function API.GetValue(player, anchor, index, key)
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