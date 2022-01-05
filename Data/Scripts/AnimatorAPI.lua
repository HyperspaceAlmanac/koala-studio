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


function API.Hello()
    print("Hello")
end

API.initializing = false
return API