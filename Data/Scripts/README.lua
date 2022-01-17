--[[
    Koala Studios by KoalaEsper

    This is a within Core timeline based custom animation editor.
    Users can create key frames for IK Anchors at specific points on the timeline
    by specifying values such as position, rotation, offset, weight, and so on.
    There is a playback system that will activate the anchors and figure out where
    they should be at each point in time.

    The key frames and animations are saved to Storage, and can also be exported
    as either encoded (just for key frames) or as a lua table.

    0. Getting Started
    This tool is for manipulating IK Anchors at specific time during the animation.
    Select an Animation, and create key frames for it by clicking the timeline, and
    then adjust its settings.

    Use the Right mouse button to rotate.
    
    Sometimes it takes a click to put the UI into focus. It take a click at the beginning
    to then be able to interact with rest of the UI.
    For modifying the values, click the button for a value and then either left click and
    drag in the LMB Drag Area, or to hit enter and type in a value if the purple prompt
    shows up. For typing in the value, it always takes an extra left click to put UI
    back into focus.

    1. The Animations menu
    The animation names are displayed here. When an animation is clicked, its color will
    change and a timeline will show up. Users can create new animations by hitting
    the "New" button, delete the currently selected ones, and rename it.

    The Delete button will bring up a menu asking the user to confirm.
    
    For renaming, there will be a purple prompt box that shows up. Hit enter to then
    input a new name for the animation. There is a 25 characters limit.
    Please only use ASCII characters.

    To the left there are Save and Preview buttons.
    Save will save the current information to Storage. Otherwise, it is only saved when
    a player leaves. The preview button only works when an Animation is selected.
    It will take user to a animation preview screen. That will have its own section.

    2. The timeline
    For creating the key frames, click the timeline to create one at that specific
    point in time. The tick marks are for seconds, and the Max Time as well as the
    size of the Tick Marks can be adjusted (100 - 400 pixels).
    
    To change Max Time, click it and there should be a purple prompt box that appears.
    Hit Enter, and type in the new time from 0-60 seconds. For any key frames that take
    place after the max time, it will be set to the max time.

    After a key frame is created, the key frame editor menu will open up. The key frame's
    time can be adjusted by dragging it along the timeline.

    3. Key Frame Editor
    When a keyframe is clicked on the timeline, the key frames editor menu opens up.
    Dragging a Key Frame along the timeline will change its time (displayed in the menu).

    For the key frame options:
    a. Activated / Deactivated button.
    Last IK Anchor will alway deactivate. Otherwise, this is for whether to go from current
    key frame to the next one, or to just deactivate, and then activate on next key frame.

    b. Current Time
    Displays the selected time for the current Key Frame.
    To change it, drag the key frame on the timeline. It can also be changed by clicking it,
    pressing enter, and typing in a new time.

    c. Transform / Anchor buttons
    These switches the right menu between the Transform and Anchor menus.
    Transform has Position and Rotation settings. Anchor has Weight, blendIn, blendOut,
    and AimOffset values.

    d. Duplicate
    Create a copy of the current keyframe.

    e. Delete
    Opens up a modal asking the user if they really want to delete this key frame.

    f. Transform Screen
    For Position, this can be adjusted by clicking the LMB Drag area and dragging left or right.
    It can also be changed by clicking x, y, or z, hitting ENTER and typing in the value.
    For rotation. It has an additional box next to it for using the long rotation path.
    This is for from previous key frame to current one.
    For example, if previous x value is 30, and current is 120, instead of going from
    30 to 120, it will rotate for 270 degrees to get to 120.

    g. Anchor Screen
    Weight is from 0-1.
    blendIn and blendOut are self explanatory.
    Offset i for the AIM offset. User can see what it will look like by using LMB drag.

    4. Preview Menu
    Opened up by clicking Preview.
    It has Start, Stop, and back buttons along with a timeline.
    When it is not running, click on the timeline to set a time to play from.
    Clicking start will play the animation from current selected time. When it reache the
    end, it will loop back to beginning and continue playing.
    Hit stop or back button to go back to editor.

    5. Server to Client Communication
    Server uses dynamic Custom Property to send information to the client.
    Client uses event broadcasts to send requests to the server.
    Client has an API for some cross script communications, and a basic queuing system
    to cap network communication to one every 0.1 seconds.

    ServerSynchronization is the server side communication handler.
    On client side, different scripts call a queining function callback that is defind
    and handled in ClientSynchronization.

    6. IK system and implementation.
    The IK Anchors are moved around and changed. This tool is for specifying IK at
    specific point in time.

    A reference object (r1) is spawned and attached to the player's Pelvis, and then another
    reference object (r2) is created and set to this position. The IK Body Anchor cannot be
    attached to the player or it will create a loop of the player trying to move to
    that position or rotation which causes the body anchor to move and so on.

    The body anchor is attached to r2, and the other four anchor are attached to the body.

    7. IK API
    There is a basic IK and animation API.
    It keeps track of a sorted list of key frames that is used to figure out where an anchor
    should be at a poitn in time. It also keeps track of whether an animation is playing
    and the current time.

    8. Playback scene
    This is an 8 player scene for playing back the animations.
    Player can create animations and then play them here.
    This allows player to create animation and play it back.
    There is a button to go to the hub from editor, and a portal to editor in the hub.
]]