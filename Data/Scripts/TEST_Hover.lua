button = script.parent

button.hoveredEvent:Connect(
    function(button)
        print(button.name)
    end
)