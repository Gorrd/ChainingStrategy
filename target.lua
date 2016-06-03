------------------------------------------------------------------------------------------------------
-- 													TARGET FUNCTIONS
------------------------------------------------------------------------------------------------------
        
local target = {}

-- When the robot is on the target spot, it doesnt move and thats all.
function target.behavior()
    robot.leds.set_all_colors("white")
    robot.wheels.set_velocity(0,0)
end

return target