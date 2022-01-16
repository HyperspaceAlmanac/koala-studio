-- Custom 
local NETWORKED_OBJ = script:GetCustomProperty("NetworkedObj"):WaitForObject() ---@type Folder
local PLAYBACK_TIME = script:GetCustomProperty("PlaybackTime"):WaitForObject() ---@type Folder

-- API 
local IK_API = require(script:GetCustomProperty("IK_API"))
local EDITOR_API = require(script:GetCustomProperty("EditorAPI"))
local ENCODER_API = require(script:GetCustomProperty("EncoderAPI"))

local animations = {}
local listeners = {}

--[[
    Properties of key frame
    {timelinePosition, active, position, rotation, weight, blendIn, blendout, offset}
]]
local sample = {
    timeline = 30.111,
    position = Vector3.New(10, 10, 10),
    rotation = Rotation.New(-30, 90, 20),
    offset = Vector3.New(0, 25, 0),
    weight = 0.95,
    blendIn = 0.35,
    blendOut = 0.201,
    active = true
}

function EncodeKeyFrame(kf)
    local tbl = {}
    table.insert(tbl, ENCODER_API.EncodeMisc(kf.active, kf.rxl, kf.ryl, kf.rzl))
    local pos = kf.position
    local offset = kf.offset
    table.insert(tbl, ENCODER_API.EncodePosAndOffsetSigns(pos, offset))
    table.insert(tbl, ENCODER_API.EncodeDecimal(math.abs(pos.x)))
    table.insert(tbl, ENCODER_API.EncodeDecimal(math.abs(pos.y)))
    table.insert(tbl, ENCODER_API.EncodeDecimal(math.abs(pos.z)))
    table.insert(tbl, ENCODER_API.EncodeDecimal(math.abs(offset.x)))
    table.insert(tbl, ENCODER_API.EncodeDecimal(math.abs(offset.y)))
    table.insert(tbl, ENCODER_API.EncodeDecimal(math.abs(offset.z)))
    local rot = kf.rotation
    table.insert(tbl, ENCODER_API.EncodeDecimal(rot.x % 360))
    table.insert(tbl, ENCODER_API.EncodeDecimal(rot.y % 360))
    table.insert(tbl, ENCODER_API.EncodeDecimal(rot.z % 360))
    table.insert(tbl, ENCODER_API.EncodeDecimal(kf.time))
    table.insert(tbl, ENCODER_API.EncodeNetwork(math.floor(kf.weight * 1000)))
    table.insert(tbl, ENCODER_API.EncodeDecimal(kf.blendIn))
    table.insert(tbl, ENCODER_API.EncodeDecimal(kf.blendOut))
    return table.concat(tbl, "")
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
    kf.offset = Vector3.New(signTable[1] and x or -x, signTable[2] and y or -y, signTable[3] and z or -z)
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

function SendAnimations(player)
    local encodedTable = {}
    table.insert(encodedTable, ENCODER_API.EncodeByte(1))
    for _, tbl in ipairs(animations[player]) do
        table.insert(encodedTable, ENCODER_API.EncodeByte(#tbl.name))
        table.insert(encodedTable, tbl.name)
    end
    NETWORKED_OBJ:SetCustomProperty("Message",  table.concat(encodedTable, ""))
end

function LoadAnimation(player, index)
    local animInfo = animations[player][index]
    local encodedTable = {}
    table.insert(encodedTable, ENCODER_API.EncodeByte(2))
    --MaxTime
    table.insert(encodedTable, ENCODER_API.EncodeDecimal(animInfo.maxTime))
    table.insert(encodedTable, ENCODER_API.EncodeByte(animInfo.timeScale))
    local kfTable = animInfo.keyFrames
    for i = 1, 5 do
        local keyFrames = kfTable[i]
        IK_API.CreateSortedKFs(player, i, keyFrames)
        local size = #keyFrames
        table.insert(encodedTable, ENCODER_API.EncodeNetwork(size))
        if size > 0 then
            for j = 1, size do
                table.insert(encodedTable, EncodeKeyFrame(keyFrames[j]))
            end
        end
    end
    IK_API.Status[player].currentTime = 0
    NETWORKED_OBJ:SetCustomProperty("Message",  table.concat(encodedTable, ""))
end

function GetCurrentAnchorTable(player)
    return animations[player][player.serverUserData.currentAnimation].keyFrames
end

function GetCurrentAnimation(player)
    return animations[player][player.serverUserData.currentAnimation]
end
function HandleSelectAnimation(player, index)
    player.serverUserData.currentAnimation = index
    LoadAnimation(player, index)
end

function HandleGetAnimations(player)
    SendAnimations(player)
end

function HandleNewAnimation(player, animName)
    table.insert(animations[player], {name=animName, maxTime = 10, timeScale = 1, keyFrames = {{}, {}, {}, {}, {}}})
end

function HandleDeleteAnimation(player, index)
    table.remove(animations[player], index)
    player.serverUserData.currentAnimation = nil
end

function HandleChangeAnimationName(player, index, newName)
    local prop = animations[player][index]
    prop.name = newName
end

function HandleChangeTimeScale(player, index, scale)
    local animation = animations[player][index]
    animation.timeScale = scale
end

function HandleChangeMaxTime(player, index, maxTime)
    local animation = animations[player][index]
    animation.maxTime = maxTime
    for _, anchor in ipairs(animation.keyFrames) do
        for i, kf in ipairs(anchor) do
            kf.time = math.min(kf.time, maxTime)
        end
    end
    IK_API.Status[player].currentTime = 0
end

local DEFAULT_KF = {
    time = 0,
    position = Vector3.New(0, 0, 0),
    rotation = Rotation.New(0, 0, 0),
    offset = Vector3.New(0, 0, 0),
    weight = 1,
    blendIn = 0,
    blendOut = 0,
    active = true,
    rxl = false,
    ryl = false,
    rzl = false
}

function DuplicateKeyFrame(original)
    local kf = {}
    kf.time = original.time
    kf.position = Vector3.New(original.position)
    kf.rotation = Rotation.New(original.rotation)
    kf.offset = Vector3.New(original.offset)
    kf.weight = original.weight
    kf.blendIn = original.blendIn
    kf.blendOut = original.blendOut
    kf.active = original.active
    kf.rxl = original.rxl
    kf.ryl = original.ryl
    kf.rzl = original.rzl
    return kf
end

local sample = {
    time = 30.111,
    position = Vector3.New(10, 10, 10),
    rotation = Rotation.New(-30, 90, 20),
    offset = Vector3.New(0, 25, 0),
    weight = 0.95,
    blendIn = 0.35,
    blendOut = 0.201,
    active = true
}

function HandleKFTime(player, i, j, time)
    local kf = GetCurrentAnchorTable(player)[i][j]
    kf.time = time
    IK_API.UpdateKF(player, i, kf)
    IK_API.UpdateAnchors(player, time)
    IK_API.Status[player].currentTime = time
end

function HandleKFPosition(player, i, j, position)
    local kf = GetCurrentAnchorTable(player)[i][j]
    kf.position = position
    IK_API.UpdateAnchors(player, kf.time)
end

function HandleKFRotation(player, i, j, rotation)
    local kf = GetCurrentAnchorTable(player)[i][j]
    kf.rotation = rotation
    IK_API.UpdateAnchors(player, kf.time)
end

function HandleKFOffset(player, i, j, offset)
    local kf = GetCurrentAnchorTable(player)[i][j]
    kf.offset = offset
    IK_API.UpdateAnchors(player, kf.time)
end

function HandleKFWeight(player, i, j, weight)
    local kf = GetCurrentAnchorTable(player)[i][j]
    kf.weight = weight
    IK_API.UpdateAnchors(player, kf.time)
end

function HandleKFBlendIn(player, i, j, blendIn)
    local kf = GetCurrentAnchorTable(player)[i][j]
    kf.blendIn = blendIn
    IK_API.UpdateAnchors(player, kf.time)
end

function HandleKFBlendOut(player, i, j, blendOut)
    local kf = GetCurrentAnchorTable(player)[i][j]
    kf.blendOut = blendOut
    IK_API.UpdateAnchors(player, kf.time)
end

function HandleKFActive(player, i, j, active)
    local kf = GetCurrentAnchorTable(player)[i][j]
    kf.active = active
    IK_API.UpdateAnchors(player, kf.time)
end

function HandleKFrxl(player, i, j, active)
    local kf = GetCurrentAnchorTable(player)[i][j]
    kf.rxl = active
    IK_API.UpdateAnchors(player, kf.time)
end

function HandleKFryl(player, i, j, active)
    local kf = GetCurrentAnchorTable(player)[i][j]
    kf.ryl = active
    IK_API.UpdateAnchors(player, kf.time)
end

function HandleKFrzl(player, i, j, active)
    local kf = GetCurrentAnchorTable(player)[i][j]
    kf.rzl = active
    IK_API.UpdateAnchors(player, kf.time)
end

function HandleCreateKF(player, i, time)
    local kf = DuplicateKeyFrame(DEFAULT_KF)
    table.insert(GetCurrentAnchorTable(player)[i], kf)
    kf.time = CoreMath.Round(time, 3)
    IK_API.AddKF(player, i, kf)
    IK_API.UpdateAnchors(player, kf.time)
end

function HandleDuplicateKF(player, i, from)
    local anchor = GetCurrentAnchorTable(player)[i]
    local kf = DuplicateKeyFrame(anchor[from])
    table.insert(anchor, kf)
    IK_API.AddKF(player, i, kf)
end

function HandleDeleteKF(player, i, j)
    local anchor = GetCurrentAnchorTable(player)[i]
    IK_API.DeleteKF(player, i, anchor[j])
    table.remove(anchor, j)
end

function HandlePreviewPlay(player)
    local status = IK_API.Status[player]
    if not status.isPlaying then
        status.isPlaying = true
    end
end

function HandlePreviewSetTime(player, time)
    local status = IK_API.Status[player]
    status.currentTime = time
end

function HandlePreviewStop(player)
    local status = IK_API.Status[player]
    if status.isPlaying then
        status.isPlaying = false
    end
end

function EncodeForStorage(player)
    local compressed = {}
    for _, animation in ipairs(animations[player]) do
        local entry = {}
        entry.name = animation.name
        entry.maxTime = animation.maxTime
        entry.timeScale = animation.timeScale
        entry.keyFrames = {}
        for i, anchor in ipairs(animation.keyFrames) do
            local encoded = {}
            table.insert(encoded, ENCODER_API.EncodeNetwork(#anchor))
            if #anchor > 0 then
                for _, kf in ipairs(anchor) do
                    table.insert(encoded, EncodeKeyFrame(kf))
                end
            end
            table.insert(entry.keyFrames, table.concat(encoded, ""))
        end
        table.insert(compressed, entry)
    end
    return compressed
end

function DecodeFromStorage(player, data)
    animations[player] = {}
    for _, animation in ipairs(data) do
        local entry = {}
        entry.name = animation.name
        entry.maxTime = animation.maxTime
        entry.timeScale = animation.timeScale
        entry.keyFrames = {}
        for _, anchor in ipairs(animation.keyFrames) do
            local keyFrames = {}
            local index = 1
            local size = ENCODER_API.DecodeNetwork(anchor:sub(1, 2))
            index = index + 2
            if size > 0 then
                for i= 1, size do
                    table.insert(keyFrames, DecodeKeyFrame(anchor:sub(index, index + 39)))
                    index = index + 40
                end
            end
            table.insert(entry.keyFrames, keyFrames)
        end
        table.insert(animations[player], entry)
    end
end

function HandleExportEncoded(player)
    local encoded = EncodeForStorage(player)
    local formatted = {}
    table.insert(formatted, "{")
    for i, animation in ipairs(encoded) do
        table.insert(formatted, "{")
        table.insert(formatted, "name=\"")
        table.insert(formatted, animation.name)
        table.insert(formatted, "\",maxTime=")
        table.insert(formatted, tostring(animation.maxTime))
        table.insert(formatted, ",timeScale=")
        table.insert(formatted, tostring(animation.timeScale))
        table.insert(formatted, ",keyFrames={")
        for j, keyFrame in ipairs(animation.keyFrames) do
            table.insert(formatted, "\""..keyFrame.."\"")
            if j < #animation.keyFrames then
                table.insert(formatted, ",")
            end
        end
        table.insert(formatted, "}")
        table.insert(formatted, "}")
        if i < #encoded then
            table.insert(formatted, ",")
        end
    end
    table.insert(formatted, "}")
    print(table.concat(formatted, ""))
end

function FormatKeyFrame(kf)
    local kfTable = {}
    table.insert(kfTable, "{")
    table.insert(kfTable, "time="..tostring(kf.time)..",")
    table.insert(kfTable, string.format("position=Vector3.New(%.3f,%.3f,%.3f),", kf.position.x, kf.position.y, kf.position.z))
    table.insert(kfTable, string.format("rotation=Rotation.New(%.3f,%.3f,%.3f),", kf.rotation.x, kf.rotation.y, kf.rotation.z))
    table.insert(kfTable, string.format("offset=Vector3.New(%.3f,%.3f,%.3f),", kf.offset.x, kf.offset.y, kf.offset.z))
    table.insert(kfTable, string.format("weight=%.3f,blendIn=%.3f,blendOut=%.3f,", kf.weight, kf.blendIn, kf.blendOut))
    table.insert(kfTable, "active="..tostring(kf.active)..",rxl="..tostring(kf.rxl)..",ryl="..tostring(kf.ryl)..",rzl="..tostring(kf.rzl))
    table.insert(kfTable, "}")
    return table.concat(kfTable, "")
end

function HandleExportScript(player)
    local formatted = {}
    table.insert(formatted, "{")
    for i, animation in ipairs(animations[player]) do
        table.insert(formatted, "{name=\"")
        table.insert(formatted, animation.name)
        table.insert(formatted, "\",maxTime=")
        table.insert(formatted, tostring(animation.maxTime))
        table.insert(formatted, ",timeScale=")
        table.insert(formatted, tostring(animation.timeScale))
        table.insert(formatted, ",keyFrames={")
        for j, anchor in ipairs(animation.keyFrames) do
            table.insert(formatted, "{")
            for k, kf in ipairs(anchor) do
                table.insert(formatted, FormatKeyFrame(kf))
                if k < #anchor then
                    table.insert(formatted, ",")
                end
            end
            table.insert(formatted, "}")
            if j < #animation.keyFrames then
                table.insert(formatted, ",")
            end
        end
        table.insert(formatted, "}}")
        if i < #animations[player] then
            table.insert(formatted, ",")
        end
    end
    table.insert(formatted, "}")
    print(table.concat(formatted, ""))
end

--PASTE Encoded output here
--local encodedTable = <Encoded output>

--PASTE the table input here
--local luaTable = <Exported script output here>
function Join(player)
    animations[player] = {}
    local persistent = Storage.GetPlayerData(player)
    --DEBUG
    --persistent = {}
    if not persistent.animations then
        local animationTable = {{name="animation1", maxTime = 10, timeScale = 1, keyFrames = {{}, {}, {}, {}, {}}},
        {name="animation 2", maxTime = 20, timeScale = 2, keyFrames = {{}, {}, {}, {}, {}}},
        {name="animation 3" , maxTime = 15, timeScale = 3, keyFrames = {{}, {}, {}, {}, {}}}}
        animations[player] = animationTable
    else
        DecodeFromStorage(player, persistent.animations)
        
        -- To import encoded, do
        -- local encodedTable = <pasted output>
        --DecodeFromStorage(player, encodedTable)

        -- To import exported lua script do
        -- local luaTable = <pasted output>
        --animations[player] = luaTable 
    end
    player.serverUserData.currentAnimation = nil
end

function Leave(player)
    local persistent = Storage.GetPlayerData(player)
    if not persistent.animations then
        persistent.animations = {}
    end
    persistent.animations = EncodeForStorage(player)
    Storage.SetPlayerData(player, persistent)
    animations[player] = nil
end

function Tick(deltaTime)
    for _, player in ipairs(Game.GetPlayers()) do
        local status = IK_API.Status[player]
        if status.isPlaying then
            local maxTime = GetCurrentAnimation(player).maxTime
            status.currentTime = status.currentTime + deltaTime
            if status.currentTime > maxTime then
                status.currentTime = 0
            end
            IK_API.UpdateAnchors(player, status.currentTime)
            PLAYBACK_TIME:SetCustomProperty("Time", status.currentTime)
        end
    end
end

Game.playerJoinedEvent:Connect(Join)
Game.playerLeftEvent:Connect(Leave)

Events.ConnectForPlayer("GetAnimations", HandleGetAnimations)
Events.ConnectForPlayer("NewAnimation", HandleNewAnimation)
Events.ConnectForPlayer("DeleteAnimation", HandleDeleteAnimation)
Events.ConnectForPlayer("SelectAnimation", HandleSelectAnimation)
Events.ConnectForPlayer("ChangeAnimationName", HandleChangeAnimationName)
Events.ConnectForPlayer("ChangeAnimationTimeScale", HandleChangeTimeScale)
Events.ConnectForPlayer("ChangeAnimationMaxTime", HandleChangeMaxTime)
Events.ConnectForPlayer("UpdateKFTime", HandleKFTime)
Events.ConnectForPlayer("UpdateKFPosition", HandleKFPosition)
Events.ConnectForPlayer("UpdateKFTRotation", HandleKFRotation)
Events.ConnectForPlayer("UpdateKFOffset", HandleKFOffset)
Events.ConnectForPlayer("UpdateKFWeight", HandleKFWeight)
Events.ConnectForPlayer("UpdateKFBlendIn", HandleKFBlendIn)
Events.ConnectForPlayer("UpdateKFBlendOut", HandleKFBlendOut)
Events.ConnectForPlayer("UpdateKFActive", HandleKFActive)
Events.ConnectForPlayer("CreateKF", HandleCreateKF)
Events.ConnectForPlayer("DuplicateKF", HandleDuplicateKF)
Events.ConnectForPlayer("DeleteKF", HandleDeleteKF)
Events.ConnectForPlayer("UpdateKFrxl", HandleKFrxl)
Events.ConnectForPlayer("UpdateKFryl", HandleKFryl)
Events.ConnectForPlayer("UpdateKFrzl", HandleKFrzl)
Events.ConnectForPlayer("PreviewPlay", HandlePreviewPlay)
Events.ConnectForPlayer("PreviewSetTime", HandlePreviewSetTime)
Events.ConnectForPlayer("PreviewStop", HandlePreviewStop)
Events.ConnectForPlayer("ExportEncoded", HandleExportEncoded)
Events.ConnectForPlayer("ExportScript", HandleExportScript)



