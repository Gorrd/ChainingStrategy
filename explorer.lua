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

When the experiment begins, all robots are on explorer state on the nest. Their goal is to find a chain
and expend it. They can move along a chain to go quicker to the unexplored areas and search for black spot.
They are also able to create a new chain.
]]

local range_and_bearing = require("range_and_bearing")
local convert = require("convert")

local explorer={}

---------------------------------------------------------------------------
-- Main function
function explorer.behavior()
	robot.leds.set_all_colors("black")
	robot.in_chain = 0

	-- Start condition : robot is not on nest, no chain detected
	-- Time create a new chain !
	-- Delay is added to prevent the chain to begin too close from the nest
	if not(range_and_bearing.isOnNest())
	and range_and_bearing.robot_detected(CHAIN_MEMBER) == 0 then
		if current_transition_steps == -1 then
			current_transition_steps = 100
		end
		if current_transition_steps == 0 then
			current_state = CHAIN_MEMBER
			range_and_bearing.set_color_chain()
			current_transition_steps = -1
		else
			current_transition_steps = current_transition_steps - 1
		end
	end
	
	-- The explorer senses one chain member and is not on the nest. 
	-- A probabilistic event will trigger the aggregation of the robot to the chain.
	if range_and_bearing.robot_detected(CHAIN_MEMBER) == 1
	and robot.random.bernoulli(p_expl_chain)
	and not(range_and_bearing.isOnNest())
	and not(range_and_bearing.nest_detected()) then
		current_state = CHAIN_MEMBER
		range_and_bearing.set_color_chain()
    
    -- The explorer senses one chain member and is on the nest. The chain member attracts
    -- the explorer, allowing it to leave the nest.
	elseif range_and_bearing.robot_detected(CHAIN_MEMBER) == 1
	and range_and_bearing.isOnNest() then
        explorer.explore()
        
	-- The explorer senses two chain members or more. It will follow one chain member until
	-- it detects only one chain member.
	elseif range_and_bearing.robot_detected(CHAIN_MEMBER) >= 2 
	and not(range_and_bearing.isOnNest())
	and not(last_chain_member_found) then
	    explorer.move_along_chain()
	
	-- Target found    
	elseif range_and_bearing.isOnTarget() then
	    robot.wheels.set_velocity(0,0)
        current_state = TARGET
        current_color = NONE
        robot.leds.set_all_colors("black")
        
	-- The robot explores
	else
		explorer.explore()
	end
	
end
---------------------------------------------------------------------------

---------------------------------------------------------------------------
-- The explorer moves along the chain he found.
function explorer.move_along_chain()
	
	-- Selection of the chain member to follow
	info = range_and_bearing.two_closest_chain_members() -- Informations of the two closest chain members
	member_chosen = {color=NONE, d=0, angle=0}
    
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
	
	if member_chosen.d <= d_expl then
	    last_chain_member_found = true
	end
	
	if not(last_chain_member_found) then
	    target_angle = explorer.ProcessRAB_LJ(member_chosen) 
	    speeds = explorer.ComputeSpeedFromAngle(target_angle)
        robot.wheels.set_velocity(speeds[1],speeds[2]) 
    end
end

---------------------------------------------------------------------------
-- In this function, we take all distances of the other robots and apply the lennard-jones potential.
-- We then sum all these vectors to obtain the final angle to follow in order to go to the place with the minimal potential
function explorer.ProcessRAB_LJ(target_robot)

   sum_vector = {0,0}
   lj_value = explorer.ComputeLennardJones(target_robot.d,d_expl) -- compute the lennard-jones value
   sum_vector[1] = math.cos(target_robot.angle)*lj_value -- sum the x components of the vectors
   sum_vector[2] = math.sin(target_robot.angle)*lj_value -- sum the y components of the vectors

   desired_angle = math.atan2(sum_vector[2],sum_vector[1]) -- compute the angle from the vector
   return desired_angle
end
---------------------------------------------------------------------------

---------------------------------------------------------------------------
-- This function take the distance and compute the lennard-jones potential.
-- The parameters are defined at the top of the script
function explorer.ComputeLennardJones(distance,target_dist)
   return -(4*EPSILON/distance * (math.pow(target_dist/distance,4) - math.pow(target_dist/distance,2)));
end
---------------------------------------------------------------------------

--This function computes the necessary wheel speed to go in the direction of the desired angle.
function explorer.ComputeSpeedFromAngle(angle)
    dotProduct = 0.0;
    KProp = 20;
    wheelsDistance = 0.14;

    -- if the target angle is behind the robot, we just rotate, no forward motion
    if angle > math.pi/2 or angle < -math.pi/2 then
        dotProduct = 0.0;
    else
    -- else, we compute the projection of the forward motion vector with the desired angle
        forwardVector = {math.cos(0), math.sin(0)}
        targetVector = {math.cos(angle), math.sin(angle)}
        dotProduct = forwardVector[1]*targetVector[1]+forwardVector[2]*targetVector[2]
    end

	 -- the angular velocity component is the desired angle scaled linearly
    angularVelocity = KProp * angle;
    -- the final wheel speeds are compute combining the forward and angular velocities, with different signs for the left and right wheel.
    speeds = {dotProduct * WHEELS_SPEED - angularVelocity * wheelsDistance, dotProduct * WHEELS_SPEED + angularVelocity * wheelsDistance}

    return speeds
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
			robot.wheels.set_velocity(math.max(0.5,math.cos(angle)) * WHEELS_SPEED, 0)
		else
			robot.wheels.set_velocity(0, math.max(0.5,math.cos(angle)) * WHEELS_SPEED)	
		end
	else 
			-- No obstacle. We go straight
			robot.wheels.set_velocity(WHEELS_SPEED,WHEELS_SPEED)
	end
end

function emit_data()
	robot.range_and_bearing.set_data(1,current_state)
	robot.range_and_bearing.set_data(2,current_color)  
end


return explorer

