
local target = {}

function target.behavior()
    robot.leds.set_all_colors("white")
    robot.wheels.set_velocity(0,0)
end

return target