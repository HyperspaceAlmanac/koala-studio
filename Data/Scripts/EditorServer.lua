local animations = {}

function Join(player)
    animations[player] = {}
    
end

function Leave(player)
    --Storage update
    animations[player] = nil
end

Game.playerJoinedEvent:Connect(Join)
Game.playerLeftEvent:Connect(Leave)