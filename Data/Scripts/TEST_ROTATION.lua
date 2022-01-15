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

local cases = {
    {45, 135},
    {135, 45},
    {45, 315},
    {315, 45}
}

for _, case in ipairs(cases) do
    print("start: "..tostring(case[1])..", end:"..tostring(case[2]))
    print("Long path:")
    for i = 1, 10 do
        print(RotationPathing(case[1], case[2], i / 10, true))        
    end
    print("Short Path:")
    for i = 1, 10 do
        print(RotationPathing(case[1], case[2], i / 10, false))        
    end
    print("---")
end