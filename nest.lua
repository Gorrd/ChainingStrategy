------------------------------------------------------------------------------------------------------
--									    NEST FUNCTION
------------------------------------------------------------------------------------------------------

-- Initial state of all robots. 

local nest = {}
local range_and_bearing = require("range_and_bearing")

-- The robot begins his exploration based on a simple threshold model.
function nest.behavior()
    local p = range_and_bearing.robot_detected(NEST)* 2 / ((n_robots)*2^2 + range_and_bearing.robot_detected(NEST) * 2)
    local r = robot.random.uniform()
    if r <= p  then
        transition(EXPLORER)
    end
end

return nest