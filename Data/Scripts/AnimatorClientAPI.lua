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

API.LOADING = false
API.SAVING = false
API.DELETE_CONFIRM = false

--Callbacks
API.LoadAnimationCallback = nil
API.LoadAnimationTimelineCallback = nil
API.PushToQueueCallback = nil
API.DeleteCallback = nil
API.CancelDeleteCallback = nil
API.ChatInputType = nil
API.WaitToDelete = false

function API.CreateKeyFrame(params)
end

function API.MoveKeyFrame(params)
end

function API.UpdateKeyFrame(params)
end

function API.DeleteKeyFrame(params)
end

function API.CreateAnimation(params)
end

function API.LoadAnimation(params)

end

function API.SaveAnimation(params)
end

function API.ExportAnimation(params)

end

function API.DeleteAnimation(params)
end

function API.RegisterLAC(callback)
    API.LoadAnimationCallbacl = callback
end

function API.RegisterLATC(callback)
    API.LoadAnimationTimelineCallback = callback
end

function API.RegisterP2QC(callback)
    API.PushToQueueCallback = callback
end

function API.RegisterDeleteCallback(callback)
    API.DeleteCallback = callback
end

function API.CancelDeleteCallback(callback)
    API.CancelDeleteCallback = callback
end

function API.Hello()
    print("Hello")
end

API.initializing = false
return API