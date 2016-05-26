------------------------------------------------------------------------------------------------------
-- 												RANGE AND BEARING FUNCTIONS
------------------------------------------------------------------------------------------------------

--[[
Functions about the range and bearing sensor. Useful for sending informations, detect next or
previous chain members.
Description of the data sent :

STATE : 1
COLOR : 2
ID : 3
NEST : 4

Chain member color rotation :

 BLUE -> GREEN -> RED
  |                |
  --------<---------
]]

local range_and_bearing = {}

---------------------------------------------------------------------------
-- Emission of the data
function range_and_bearing.emit_data()
	robot.range_and_bearing.set_data(1,current_state)
	robot.range_and_bearing.set_data(2,current_color)
	robot.range_and_bearing.set_data(3,tonumber(string.match(robot.id, "[0-9]+"))) -- Regex for finding the ID number from robot.id (= rescuer20 for exemple)
	if range_and_bearing.isOnNest() then
	    robot.range_and_bearing.set_data(4,1)
	else
		robot.range_and_bearing.set_data(4,0) 
    end   
end
---------------------------------------------------------------------------

---------------------------------------------------------------------------
-- Set the color (position) of the robot in the chain. Called only when zero or one chain member are detected.
function range_and_bearing.set_color_chain()

	for i = 1,#robot.range_and_bearing do
		if robot.range_and_bearing[i].range < d_camera and robot.range_and_bearing[i].data[2] == BLUE then
			robot.leds.set_all_colors("green")
			current_color = GREEN
			break

		elseif robot.range_and_bearing[i].range < d_camera and robot.range_and_bearing[i].data[2] == GREEN then
			robot.leds.set_all_colors("red")
			current_color = RED
			break

		elseif robot.range_and_bearing[i].range < d_camera and robot.range_and_bearing[i].data[2] == RED then
			robot.leds.set_all_colors("blue")
			current_color = BLUE
			break
		else
			robot.leds.set_all_colors("blue")
			current_color = BLUE
		end
	end
end
---------------------------------------------------------------------------

---------------------------------------------------------------------------
-- Return how many robots with the state sent in parameter.
function range_and_bearing.robot_detected(state)
	local number_robot_sensed = 0

	for i = 1,#robot.range_and_bearing do
		if robot.range_and_bearing[i].range < d_camera and robot.range_and_bearing[i].data[1] == state then
			number_robot_sensed = number_robot_sensed + 1
		end
	end
	return number_robot_sensed
end
---------------------------------------------------------------------------

---------------------------------------------------------------------------
-- Detect if the next color of the chain is detected.
function range_and_bearing.next_chain_color_detected()
	for i = 1,#robot.range_and_bearing do

		if robot.range_and_bearing[i].range < d_camera
		and current_color == BLUE
		and robot.range_and_bearing[i].data[2] == GREEN then
			return true

		elseif robot.range_and_bearing[i].range < d_camera 
		and current_color == GREEN
		and robot.range_and_bearing[i].data[2] == RED then
			return true

		elseif robot.range_and_bearing[i].range < d_camera
		and current_color == RED
		and robot.range_and_bearing[i].data[2] == BLUE then
			return true
		end
	end
	return false
end
---------------------------------------------------------------------------

---------------------------------------------------------------------------
-- Detect if the previous color of the chain is detected.
function range_and_bearing.previous_chain_color_detected()
	for i = 1,#robot.range_and_bearing do

		if robot.range_and_bearing[i].range < d_camera
		and current_color == BLUE
		and robot.range_and_bearing[i].data[2] == RED then
			return true

		elseif robot.range_and_bearing[i].range < d_camera 
		and current_color == GREEN
		and robot.range_and_bearing[i].data[2] == BLUE then
			return true

		elseif robot.range_and_bearing[i].range < d_camera
		and current_color == RED
		and robot.range_and_bearing[i].data[2] == GREEN then
			return true
		end
	end
	return false
end
---------------------------------------------------------------------------

---------------------------------------------------------------------------
-- Find the previous chain member and return his informations.
function range_and_bearing.previous_chain_member()
	local sort_data = table.copy(robot.range_and_bearing)
	local info = { d = 0, angle = 0 }
	local previous_color = NONE
	table.sort(sort_data, function(a,b) return a.range<b.range end)
	
	    -- Find the color of the previous member based on the current color
	    if current_color == BLUE then
	        previous_color = RED
	    elseif current_color == GREEN then
	        previous_color = BLUE
	    elseif current_color == RED then
	        previous_color = GREEN
	    end
	
	for i = 1,#robot.range_and_bearing do
		if sort_data[i].data[1] == CHAIN_MEMBER and sort_data[i].data[2] == previous_color -- previous chain member found
		and sort_data[i].range < d_camera then
		    info.d = sort_data[i].range
		    info.angle = sort_data[i].horizontal_bearing
		end
	end
	
	return info
end
---------------------------------------------------------------------------

---------------------------------------------------------------------------
-- Find the next chain member and return his informations.
function range_and_bearing.next_chain_member()
	local sort_data = table.copy(robot.range_and_bearing)
	local info = { d = 0, angle = 0 }
	local next_color = NONE
	table.sort(sort_data, function(a,b) return a.range<b.range end)
	
	-- Find the color of the next member based on the current color
	if current_color == BLUE then
	    next_color = GREEN
	elseif current_color == GREEN then
	    next_color = RED
	elseif current_color == RED then
	    next_color = BLUE
	end
	
	for i = 1,#robot.range_and_bearing do
		if sort_data[i].data[1] == CHAIN_MEMBER and sort_data[i].data[2] == next_color 
		and sort_data[i].range < d_camera then -- next chain member found
		    info.d = sort_data[i].range
		    info.angle = sort_data[i].horizontal_bearing
		end
	end
	
	return info
end
---------------------------------------------------------------------------

---------------------------------------------------------------------------
-- Find the two closest chain members and return their informations. Doesnt need to check if there is at least 
-- two chain members detected.
function range_and_bearing.two_closest_chain_members()
	local sort_data = table.copy(robot.range_and_bearing)
	local info = {color1 = NONE, color2 = NONE, d1 = 0, d2 = 0, angle1 = 0, angle2 = 0}
	table.sort(sort_data, function(a,b) return a.range<b.range end)
	local count = 0
	
	for i = 1,#robot.range_and_bearing do
		if sort_data[i].data[1] == CHAIN_MEMBER and sort_data[i].range < d_camera then -- Chain member found
			if count == 0 then
				info.color1 = sort_data[i].data[2]
				info.d1 = sort_data[i].range
				info.angle1 = sort_data[i].horizontal_bearing
				count = count + 1
			elseif count == 1 then
				info.color2 = sort_data[i].data[2]
				info.d2 = sort_data[i].range
				info.angle2 = sort_data[i].horizontal_bearing
				count = count + 1
				break
			end
		end
	end
	
	return info
end
---------------------------------------------------------------------------

---------------------------------------------------------------------------
function range_and_bearing.same_chain_member_detected()
    local sort_data = table.copy(robot.range_and_bearing)
	table.sort(sort_data, function(a,b) return a.range<b.range end)
	for i = 1,#robot.range_and_bearing do
	    if sort_data[i].data[2] == current_color and sort_data[i].data[1] == CHAIN_MEMBER 
	    and sort_data[i].range < d_camera then
	        return true
	    end
	end
	return false
end
---------------------------------------------------------------------------

---------------------------------------------------------------------------
function range_and_bearing.same_chain_member()
    local sort_data = table.copy(robot.range_and_bearing)
	table.sort(sort_data, function(a,b) return a.range<b.range end)
	local info = {d = 0, angle = 0 }
	
	for i = 1,#robot.range_and_bearing do
	    if sort_data[i].data[2] == current_color and sort_data[i].data[1] == CHAIN_MEMBER 
	    and sort_data[i].range < d_camera then
			info.d = sort_data[i].range
			info.angle = sort_data[i].horizontal_bearing
		end
	end
	return info
end
---------------------------------------------------------------------------

---------------------------------------------------------------------------
-- Find the closest chain members and return its informations.
function range_and_bearing.closest_chain_member()
	local sort_data = table.copy(robot.range_and_bearing)
	local info = {color = NONE, d = 0, angle = 0 }
	table.sort(sort_data, function(a,b) return a.range<b.range end)
	local count = 0
	
	for i = 1,#robot.range_and_bearing do
		if sort_data[i].data[1] == CHAIN_MEMBER and sort_data[i].range < d_camera then -- Chain member found
				info.color = sort_data[i].data[2]
				info.d = sort_data[i].range
				info.angle = sort_data[i].horizontal_bearing
		end
	end
	
	return info
end
---------------------------------------------------------------------------

-- Sense if the robot is on the nest based on the color's floor
function range_and_bearing.isOnNest()
	local sort_ground = table.copy(robot.motor_ground)
   table.sort(sort_ground, function(a,b) return a.value<b.value end)
	if round(sort_ground[1].value,2) == 0.9 then
		return true
	else
		return false
	end
end

-- Sense if explorers that are on the nest are detected
function range_and_bearing.nest_detected()
	local sort_data = table.copy(robot.range_and_bearing)
	table.sort(sort_data, function(a,b) return a.range<b.range end)
	
	for i = 1,#robot.range_and_bearing do
		if sort_data[i].data[1] == EXPLORER and sort_data[i].range < d_camera 
		and sort_data[i].data[4] == 1 then -- Explorer on the nest found
		    return true
		end
	end
	return false
end

function range_and_bearing.isOnTarget()
	local sort_ground = table.copy(robot.motor_ground)
   table.sort(sort_ground, function(a,b) return a.value<b.value end)
   for i=1,#sort_ground do
	    if sort_ground[i].value ~= 0 then
		    return false
	    end
   end
   return true
end

return range_and_bearing
