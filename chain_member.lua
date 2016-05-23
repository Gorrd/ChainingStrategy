------------------------------------------------------------------------------------------------------
--										    CHAIN MEMBER FUNCTIONS
------------------------------------------------------------------------------------------------------

local chain_member = {}
local range_and_bearing = require("range_and_bearing")

-- The robot is aggregated on a chain
function chain_member.behavior()
	robot.wheels.set_velocity(0,0)


	-- Chain member last -> Chain member not last
	if current_substate == CHAIN_MEMBER_LAST
	and range_and_bearing.next_chain_color_detected() then
		current_substate = CHAIN_MEMBER_NOT_LAST

	-- Chain member not last -> Chain member last
	elseif current_substate == CHAIN_MEMBER_NOT_LAST
	and not(range_and_bearing.next_chain_color_detected()) then
		current_substate = CHAIN_MEMBER_LAST

	-- Chain member last -> explorer backward
	elseif current_substate == CHAIN_MEMBER_LAST
	and range_and_bearing.robot_detected(EXPLORER) == 0
	and robot.random.bernoulli(p_chain_expl) == 1 then
		current_state = EXPLORER
		current_substate = EXPLORER_BWD
		current_color = NONE
		
    elseif range_and_bearing.previous_chain_color_detected() then
        chain_member.align_strategy()

	end

end

function chain_member.align_strategy()
    target_angle = chain_member.processRAB_LJ() -- we compute the angle to follow, using the other robots as input, see function code for details
    speeds = chain_member.compute_speed_from_angle(target_angle) -- we now compute the wheel speed necessary to go in the direction of the target angle
    robot.wheels.set_velocity(speeds[1],speeds[2]) -- actuate wheels to move
end

--This function computes the necessary wheel speed to go in the direction of the desired angle.
function chain_member.compute_speed_from_angle(angle)
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
    speeds = {dotProduct * 10 - angularVelocity * wheelsDistance, dotProduct * 10 + angularVelocity * wheelsDistance}

    return speeds
end
---------------------------------------------------------------------------

---------------------------------------------------------------------------
-- In this function, we take all distances of the other robots and apply the lennard-jones potential.
-- We then sum all these vectors to obtain the final angle to follow in order to go to the place with the minimal potential
function chain_member.processRAB_LJ()

   sum_vector = {0,0}
   for i = 1,#robot.range_and_bearing do -- for each chain memeber robot seen
      if robot.range_and_bearing[i].data[1] == CHAIN_MEMBER then
        lj_value = chain_member.compute_LennardJones(robot.range_and_bearing[i].range) -- compute the lennard-jones value
        sum_vector[1] = sum_vector[1] + math.cos(robot.range_and_bearing[i].horizontal_bearing)*lj_value -- sum the x components of the vectors
        sum_vector[2] = sum_vector[2] + math.sin(robot.range_and_bearing[i].horizontal_bearing)*lj_value -- sum the y components of the vectors
      end
   end
   desired_angle = math.atan2(sum_vector[2],sum_vector[1]) -- compute the angle from the vector

   return desired_angle
end
---------------------------------------------------------------------------

---------------------------------------------------------------------------
-- This function take the distance and compute the lennard-jones potential.
-- The parameters are defined at the top of the script
function chain_member.compute_LennardJones(distance)
   return -(4*EPSILON/distance * (math.pow(d_chain/distance,4) - math.pow(d_chain/distance,2)));
end
---------------------------------------------------------------------------


return chain_member

