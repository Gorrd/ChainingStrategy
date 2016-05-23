------------------------------------------------------------------------------------------------------
-- 										LOGS FUNCTIONS
------------------------------------------------------------------------------------------------------

-- Write informations on the log window. Useful for debug and see if the behaviors implemented work well.

local convert = require("convert")
local range_and_bearing = require("range_and_bearing")

local logs={}

-- Writing in the logs
function logs.write()
	log("Robot ID : "..robot.id)
	log("State : "..convert.number_state(current_substate))
	log("Explorers robots detected : "..range_and_bearing.robot_detected(EXPLORER))
	log("Chain members robots detected : "..range_and_bearing.robot_detected(CHAIN_MEMBER))
	log("Lost robots detected : "..range_and_bearing.robot_detected(LOST))
	logs.robot_detected()
	log("-------------------------------")
end

-- Write useful informations about detected robots
function logs.robot_detected()
	local sort_data = table.copy(robot.range_and_bearing)
	table.sort(sort_data, function(a,b) return a.range<b.range end)
	for i = 1,#robot.range_and_bearing do
		log(
		sort_data[i].data[3]," - ", 
		convert.number_state(sort_data[i].data[1])," - ",
		convert.number_color(sort_data[i].data[2])," - ",
		sort_data[i].range
		)
	end
end

return logs
