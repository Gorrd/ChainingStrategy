------------------------------------------------------------------------------------------------------
-- 													EXPLORER FUNCTIONS
------------------------------------------------------------------------------------------------------

local range_and_bearing = require("range_and_bearing")

local explorer={}

-- What the robot does when it is explorating his environment
function explorer.behavior()
	robot.leds.set_all_colors("white")

	-- Start condition : robot is not on nest, no chain detected
	-- Time create a new chain !
	-- Delay is added to prevent the chain to start too close from the nest
	if current_substate == EXPLORER_FWD
	and not(explorer.isOnNest())
	and range_and_bearing.robot_detected(CHAIN_MEMBER) == 0 then
		if current_transition_steps == -1 then
			current_transition_steps = robot.random.uniform_int(10,30)
		end
		if current_transition_steps == 0 then
			current_state = CHAIN_MEMBER
			current_substate = CHAIN_MEMBER_LAST
			range_and_bearing.set_color_chain()
			current_transition_steps = -1
		else
			current_transition_steps = current_transition_steps - 1
		end

	-- The explorer senses one chain member and is not on the nest. 
	-- A probabilistic event will trigger the aggregation of the robot to the chain.
	elseif current_substate == EXPLORER_FWD
	and range_and_bearing.robot_detected(CHAIN_MEMBER) == 1
	and robot.random.bernoulli(p_expl_chain) == 1 
	and not(explorer.isOnNest()) then
		current_state = CHAIN_MEMBER
		current_substate = CHAIN_MEMBER_LAST
		range_and_bearing.set_color_chain()

	-- The explorer senses two chain members or more. It will follow one chain member based on his substate until
	-- it detects only one chain member.
	elseif range_and_bearing.robot_detected(CHAIN_MEMBER) >= 2 then
		explorer.move_along_chain()

	-- The backward explorer founds the nest and is ready to go on
	elseif current_substate == EXPLORER_BWD
	and explorer.isOnNest() then
		current_substate = EXPLORER_FWD

	-- The robot explores
	else
		explorer.explore()
	end
end

-- The explorer moves along the chain he found.
function explorer.move_along_chain()
	
	-- Selection of the chain member to follow
	info = range_and_bearing.two_closest_chain_members() -- Informations of the two closest chain members
	member_chosen = {color=NONE, distance=0, angle=0}

	if info.color1 == info.color2 then
		member_chosen.color = info.color1 
		member_chosen.distance = info.d1 
		member_chosen.angle = info.angle1
	end
	
	if info.color1 == BLUE and info.color2 == GREEN
	or info.color1 == GREEN and info.color2 == RED
	or info.color1 == RED and info.color2 == BLUE then

		if current_substate == EXPLORER_FWD then

		member_chosen.color = info.color1
		member_chosen.distance = info.d1
		member_chosen.angle = info.angle1

		elseif current_substate == EXPLORER_BWD then
		member_chosen.color = info.color2 
		member_chosen.distance = info.d2
		member_chosen.angle = info.angle2
		end

	elseif info.color1 == GREEN and info.color2 == BLUE
	or info.color1 == RED and info.color2 == GREEN
	or info.color1 == BLUE and info.color2 == RED then

		if current_substate == EXPLORER_FWD then
		member_chosen.color = info.color2
		member_chosen.distance = info.d2
		member_chosen.angle = info.angle2

		elseif current_substate == EXPLORER_BWD then
		member_chosen.color = info.color1
		member_chosen.distance = info.d1
		member_chosen.angle = info.angle1
		end

	end

    -- Adjust distance
	F_ad = { x=0, y=0 }
	F_ad.x = (d_expl-member_chosen.distance) / d_camera  * math.cos(member_chosen.angle)
	F_ad.y = (d_expl-member_chosen.distance) / d_camera  * math.sin(member_chosen.angle)
	
	-- Move perpendicular
	F_mp = { x=0, y=0 }
	F_mp.x = - math.sin(member_chosen.angle)
    F_mp.y = math.cos(member_chosen.angle)
    
    -- Avoid collisions
    F_ac = { x=0, y=0 }
    for i = 1, 24 do 
        vec = {
			x = robot.proximity[i].value * math.cos(robot.proximity[i].angle),
			y = robot.proximity[i].value * math.sin(robot.proximity[i].angle)
		}
		F_ac.x = F_ac.x + vec.x
		F_ac.y = F_ac.y + vec.y
	end
    
	F_expl = { x=0, y=0 }
	F_expl.x = 5*F_ad.x + F_mp.x + F_ac.x
	F_expl.y = 5*F_ad.y + F_mp.y + F_ac.y

	length = math.sqrt(F_expl.x * F_expl.x + F_expl.y * F_expl.y)
	angle = math.atan2(F_expl.y, F_expl.x)
	
	-- Low level motor control
	lSpeed = 0
	rSpeed = 0
	
	if angle >= 0 and angle < math.pi/2 then
	    lSpeed = math.cos(2*angle)
	    rSpeed = 10
	elseif angle >= math.pi/2 and angle < math.pi then
		lSpeed = math.cos(2*angle - math.pi)
	    rSpeed = -10
	elseif angle >= math.pi and angle < 3*math.pi/2 then
		lSpeed = -10
	    rSpeed = - math.cos(2*angle)
	elseif angle >= 3*math.pi/2 and angle < 2*math.pi then
		lSpeed = 10
	    rSpeed = - math.cos(2*angle - math.pi)
	else
	    lSpeed = 10
	    rSpeed = 10
	end
	
	robot.wheels.set_velocity(math.min(length,10)*lSpeed,math.min(length,10)*rSpeed)
end

function explorer.explore()

	-- Long range scanner. Because of the robot's movement, we need to correct direction
	-- only 5 steps otherwise the robot will adjust his direction each step.
	accumul = { x=0, y=0 }
	
	if long_range_steps == 0 then
	    local data = table.copy(robot.distance_scanner.long_range)
        for i=1,#robot.distance_scanner.long_range do
		    local vec = {
			    x = data[i].distance * math.cos(data[i].angle),
			    y = data[i].distance * math.sin(data[i].angle)
		    }
		    accumul.x = accumul.x + vec.x
		    accumul.y = accumul.y + vec.y
        end
    end
    
    long_range_steps = long_range_steps + 1
    if long_range_steps == 5 then
        long_range_steps = 0
    end
    
    -- Short range is about the proximity sensor
    for i = 1, 24 do 
		vec = {
			x = robot.proximity[i].value * math.cos(robot.proximity[i].angle),
			y = robot.proximity[i].value * math.sin(robot.proximity[i].angle)
		}

		accumul.x = accumul.x + vec.x
		accumul.y = accumul.y + vec.y
	end
    
    
    -- Length and angle of the final vector
	length = math.sqrt(accumul.x * accumul.x + accumul.y * accumul.y)
	angle = math.atan2(accumul.y, accumul.x)

	
	if length > 0.2 then
		-- If the angle is greater than 0 the resulting obstacle is on the left. Otherwise it is on the right
		-- We turn with a speed that depends on the angle. The closer the obstacle to the x axis
		-- of the robot, the quicker the turn
		if angle > 0 then
			robot.wheels.set_velocity(math.max(0.5,math.cos(angle)) * 10,0)
		else
			robot.wheels.set_velocity(0, math.max(0.5,math.cos(angle)) * 10)	
		end
	else 
			-- No obstacle. We go straight
			robot.wheels.set_velocity(10,10)
	end
end

-- Sense if the robot is on the nest based on the color's floor
function explorer.isOnNest()
	local sort_ground = table.copy(robot.motor_ground)
   table.sort(sort_ground, function(a,b) return a.value<b.value end)
	if round(sort_ground[1].value,2) == 0.9 then
		return true
	else
		return false
	end
end


return explorer

