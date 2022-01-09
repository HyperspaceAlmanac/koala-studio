local animations = {}

function Join(player)
    animations[player] = {}
    local animationTable = {animation1 = {}, animation2 = {}, someFancyAnimation = {}}
    animations[player] = animationTable
end

function Leave(player)
    --Storage update
    animations[player] = nil
end

Game.playerJoinedEvent:Connect(Join)
Game.playerLeftEvent:Connect(Leave)