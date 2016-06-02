local nest = {}
local range_and_bearing = require("range_and_bearing")

function nest.behavior()
    local p = range_and_bearing.robot_detected(NEST)* 2 / (60^2 + range_and_bearing.robot_detected(NEST) * 2)
    local r = robot.random.uniform()
    if r <= p  then
        transition(EXPLORER)
    end
end

return nest