------------------------------------------------------------------------------------------------------
-- 													EXPLORER FUNCTIONS
------------------------------------------------------------------------------------------------------

--[[
           
          o-> 

      o
     / 
    o 
     \   
      o 
     /  
    o 

Their goal is to find a chain and expend it. T
They can move along a chain to go quicker to the unexplored areas and search for black spot.
They are also able to create a new chain.
]]

local range_and_bearing = require("range_and_bearing")
local lj_functions = require("lj_functions")
local explorer = {}

---------------------------------------------------------------------------
-- Main function
function explorer.behavior()
    
    if wait_time > 0 then
        wait_time = wait_time - 1
    else

    -- Target check
    if range_and_bearing.isOnTarget() 
    and range_and_bearing.robot_detected(TARGET) == 0 then
        transition(TARGET)
    end
        
        -- We dont create chain on nest
        if not(range_and_bearing.isOnNest()) and range_and_bearing.robot_detected(NEST) == 0 then
                
            if range_and_bearing.robot_detected(CHAIN_MEMBER) <= 1 then
                local p = 1 - (range_and_bearing.robot_detected(CHAIN_MEMBER)^2 / (range_and_bearing.robot_detected(CHAIN_MEMBER)^2 + 1))
                local r = robot.random.uniform()
                if r <= p  then
                    transition(CHAIN_MEMBER)
                end   
            end
                
            if range_and_bearing.robot_detected(CHAIN_MEMBER) >= 2 then
                explorer.move_along_chain()
            end
                
        else
            explorer.explore()
        end
        
        
    end
end

-- The explorer search in his environment for the target spot. The process is explained
-- on the lj_functions file.
function explorer.explore()
    local vector = lj_functions.process_exploration()
    local desired_angle = math.atan2(vector[2],vector[1]) 
    speeds = lj_functions.compute_SpeedFromAngle(desired_angle)
    robot.wheels.set_velocity(speeds[1],speeds[2])
end

-- The explorer founds a chain and move along to the last element.
function explorer.move_along_chain()
    	
	-- Selection of the chain member to follow
	local info = range_and_bearing.two_closest_chain_members() -- Informations of the two closest chain members
	local member_chosen = { color=NONE, d=0, angle=0 }
    
    -- Same color of the two chain members : we chose the closest
	if info.color1 == info.color2 then
		member_chosen.color = info.color1
		member_chosen.d = info.d1
		member_chosen.angle = info.angle1
	end
	
	if info.color1 == BLUE and info.color2 == GREEN
	or info.color1 == GREEN and info.color2 == RED
	or info.color1 == RED and info.color2 == BLUE then

	    member_chosen.color = info.color2
		member_chosen.d = info.d2
		member_chosen.angle = info.angle2

	elseif info.color1 == GREEN and info.color2 == BLUE
	or info.color1 == RED and info.color2 == GREEN
	or info.color1 == BLUE and info.color2 == RED then

		member_chosen.color = info.color1
		member_chosen.d = info.d1
		member_chosen.angle = info.angle1

	end
    
    -- The explorer goes to the chain member
	local vector = lj_functions.process_goto(member_chosen) 
    
    local desired_angle = math.atan2(vector[2],vector[1]) 
    speeds = lj_functions.compute_SpeedFromAngle(desired_angle)
    robot.wheels.set_velocity(speeds[1],speeds[2]) 
end

return explorer

