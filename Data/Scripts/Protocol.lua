--[[
    Page just for the networking protocols

    Server Side
    1. SendAnimationNames
        1. OP CODE = 1
        2. PlayerID
        3. Size: n (1-25)
        4 - n: String
    2.


    Client Side
    1. GetAnimationNames
    Input: player
    Response: SendAnimationName

    2. Get AnimationInfo
    Input: 



    Key Frame Properties
    index = 2 bytes
    timelinePosition = 60.000, 3 bytes

    position = 3 x 3 bytes + 3 bit
    offset = 3 x 3 bytes + 3 bit

    rotation = 3 x 3 bytes
    weight = 2 bytes
    0.000 - 1.000
    blendIn = 3 bytes
    blendOut = 3 bytes
    
    active = combine, 1 bit
]]