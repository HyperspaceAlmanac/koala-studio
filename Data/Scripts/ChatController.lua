-- API

local API = require(script:GetCustomProperty("AnimatorClientAPI"))

-- Custom 
local ANIMATOR_CLIENT_API = script:GetCustomProperty("AnimatorClientAPI")
local CHAT_REMINDER = script:GetCustomProperty("ChatReminder"):WaitForObject() ---@type UIPanel
local TITLE = script:GetCustomProperty("Title"):WaitForObject() ---@type UIText
local FIELD = script:GetCustomProperty("Field"):WaitForObject() ---@type UIText
local TYPE = script:GetCustomProperty("Type"):WaitForObject() ---@type UIText

local LOCAL_PLAYER = Game.GetLocalPlayer()

function VisibilityCheck()
    
end

function Tick(deltaTime)

end
