------------------------------------------------------------------------------------------------------
--										    CHAIN MEMBER FUNCTIONS
------------------------------------------------------------------------------------------------------

--[[

      o
     / 
    o 
     \   
      o 
     /  
    o 
    
This state is triggered when the explorer found a perfect spot to create/aggregate a chain.  Conditions
about the transition to this state are explained in the initial states code. 

The behavior is to align the differents chain members, ie each chain member respect a certain threshold 
for his chain members neighbors. To form this pattern, we use the Lennard-Jones potential.
]]

local chain_member = {}
local range_and_bearing = require("range_and_bearing")

---------------------------------------------------------------------------
-- Main function called each step 
function chain_member.behavior()

    robot.wheels.set_velocity(0,0)

    -- Count how many robots are in a chain at a current step
	robot.in_chain = 1
	
	-- First, we check the ground and detect if the robot is on the nest or found the target.
	
	-- Chain member on the nest -> get back to explorer
	if range_and_bearing.isOnNest() then
	    current_state = EXPLORER
	    current_color = NONE
	end
	
	-- Target found
	if range_and_bearing.isOnTarget() then
	    robot.wheels.set_velocity(0,0)
	    current_state = TARGET
	    current_color = NONE
	    robot.leds.set_all_colors("white")
	end
	
	-- Robot lost
	if range_and_bearing.robot_detected(EXPLORER) == 0
	and range_and_bearing.robot_detected(CHAIN_MEMBER) == 0 then
	    current_state = EXPLORER
	    current_color = NONE
	end
	
	if range_and_bearing.previous_chain_color_detected()
	and not(range_and_bearing.next_chain_color_detected()) 
	and range_and_bearing.robot_detected(CHAIN_MEMBER) == 1 then
	    current_state = EXPLORER
	    current_color = NONE
	end
	
    -- Avoid collision
	accumul = { x=0, y=0 }
	avoid_collision = false
    for i = 1, 24 do 
		vec = {
			x = robot.proximity[i].value * math.cos(robot.proximity[i].angle),
			y = robot.proximity[i].value * math.sin(robot.proximity[i].angle)
		}

		accumul.x = accumul.x + vec.x
		accumul.y = accumul.y + vec.y
	end
	
	if accumul.x ~= 0 and accumul.y ~= 0 then
	    avoid_collision = true
	    length = math.sqrt(accumul.x * accumul.x + accumul.y * accumul.y)
	    angle = math.atan2(accumul.y, accumul.x)

	    if length > 0.2 then
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

	    -- Merge behavior : When two chain members of the same colors detect each other, they merge
    if range_and_bearing.same_chain_member_detected() then
  --  and not(avoid_collision) then
        
        same_member = range_and_bearing.same_chain_member()
        target_angle = chain_member.ProcessRAB_LJ(same_member,d_merge) 
	    speeds = chain_member.ComputeSpeedFromAngle(target_angle)
	    robot.wheels.set_velocity(speeds[1],speeds[2])
	    
	    if same_member.d <= d_merge then
	        if merge_steps == 0 then
	            current_state = EXPLORER
	            current_color = NONE
	            robot.range_and_bearing.clear_data()
	            merge_steps = robot.random.uniform_int(1,20)
	        else
	            merge_steps = merge_steps - 1
	        end
        end  
    end 

	-- Distance between chain members adjusted. We check if the robot will not change state next step,
	-- If the chain member is the last of his chain
	if range_and_bearing.previous_chain_color_detected()
	and not(range_and_bearing.next_chain_color_detected())
	and not(range_and_bearing.same_chain_member_detected()) 
	and not(avoid_collision) then
	
	    previous = range_and_bearing.previous_chain_member()
	    target_angle = chain_member.ProcessRAB_LJ(previous,d_chain) 
	    speeds = chain_member.ComputeSpeedFromAngle(target_angle)
        robot.wheels.set_velocity(speeds[1],speeds[2])   
    end


end
---------------------------------------------------------------------------

---------------------------------------------------------------------------
-- In this function, we take all distances of the other robots and apply the lennard-jones potential.
-- We then sum all these vectors to obtain the final angle to follow in order to go to the place with the minimal potential
function chain_member.ProcessRAB_LJ(target_robot,target_distance)
   sum_vector = {0,0}
   lj_value = chain_member.ComputeLennardJones(target_robot.d,target_distance) -- compute the lennard-jones value
   sum_vector[1] = math.cos(target_robot.angle)*lj_value -- sum the x components of the vectors
   sum_vector[2] = math.sin(target_robot.angle)*lj_value -- sum the y components of the vectors
   desired_angle = math.atan2(sum_vector[2],sum_vector[1]) -- compute the angle from the vector
   return desired_angle
end
---------------------------------------------------------------------------

---------------------------------------------------------------------------
-- This function take the distance and compute the lennard-jones potential.
-- The parameters are defined at the top of the script
function chain_member.ComputeLennardJones(distance,target_dist)
   return -(4*EPSILON/distance * (math.pow(target_dist/distance,4) - math.pow(target_dist/distance,2)));
end
---------------------------------------------------------------------------

--This function computes the necessary wheel speed to go in the direction of the desired angle.
function chain_member.ComputeSpeedFromAngle(angle)
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

return chain_member

