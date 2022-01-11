local API = {}
if _G["AnimationAPI"] == nil then
    _G["AnimationAPI"] = API
    API.initializng = true
else
    while API.initializing do
        Task.Wait()
    end
    return _G["AnimationAPI"]
end

API.loadingTable = {}
API.AnimationTable = {}

--Callbacks
API.LoadAnimationCallback = nil
API.LoadAnimationTimelineCallback = nil
API.PushToQueue = nil
API.DeleteCallback = nil
API.CancelDeleteCallback = nil
API.UpdateTimeDisplayCallback = nil
API.DuplicateKFCallback = nil
API.UpdateNameCallback = nil
API.ChangeTLScale = nil
API.LoadKeyFrame = nil
API.ChatInputType = nil
API.WaitToDelete = false

function API.PlayerJoin(player)
    API.AnimationTable[player] = {}
    API.loadingTable[player] = {}
end

function API.PlayerLeave(player)
    API.AnimationTable[player] = nil
    API.loadingTable[player] = nil
end

function API.UpdateName(name)
    print("Updated Animation name to: "..name)
end

function API.UpdateMaxTime(time)
    print("Updated max time to: "..tostring(time))
end

function API.UpdateTimeScale(index)
end



function API.RegisterLAC(callback)
    API.LoadAnimationCallbacl = callback
end

function API.RegisterLATC(callback)
    API.LoadAnimationTimelineCallback = callback
end

function API.RegisterP2QC(callback)
    API.PushToQueue = callback
end

function API.RegisterDeleteCallback(callback)
    API.DeleteCallback = callback
end

function API.CancelDeleteCallback(callback)
    API.CancelDeleteCallback = callback
end

function API.RegisterUTD(callback)
    API.UpdateTimeDisplayCallback = callback
end

function API.RegisterDuplicateKF(callback)
    API.DuplicateKFCallback = callback
end

function API.RegisterUpdateNameCallback(callback)
    API.UpdateNameCallback = callback
end

function API.RegisterLoadKeyFrame(callback)
    API.LoadKeyFrame = callback
end

function API.RegisterChangeTLScale(callback)
    API.ChangeTLScale = callback
end

function API.CleanUp(player)
    local lastPressed = player.clientUserData.lastPressed
    if lastPressed and lastPressed.clientUserData.index then
        lastPressed:SetButtonColor(Color.WHITE)
        player.clientUserData.lastPressed = nil
    end
    local lastKF = player.clientUserData.currentKeyFrame
    if player.clientUserData.currentKeyFrame then
        lastKF:SetButtonColor(Color.BLACK)
        player.clientUserData.currentKeyFrame = nil
    end
    if player.clientUserData.changeMaxTime then
        player.clientUserData.changeMaxTime:SetButtonColor(Color.WHITE)
        player.clientUserData.changeMaxTime = nil
    end
    player.clientUserData.setAnimName = false
end

function API.FullCleanUp(player)
    API.CleanUp(player)
    player.clientUserData.currentAnimation = nil
end

function API.Hello()
    print("Hello")
end

API.initializing = false
return API