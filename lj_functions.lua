

local lj_functions = {}

local range_and_bearing = require("range_and_bearing")


--This function computes the necessary wheel speed to go in the direction of the desired angle
function lj_functions.compute_SpeedFromAngle(angle)
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

-- This function take the distance and compute the lennard-jones potential
function lj_functions.compute_LennardJones(distance,target_dist,eps)
   return -(4*eps/distance * (math.pow(target_dist/distance,4) - math.pow(target_dist/distance,2)))
end

---------------------------------------------------------------------------

-- Detect short range obstacles and return a vector to avoid them.
function short_range(factor)
    local vector = {0,0}
    local data_short = table.copy(robot.distance_scanner.short_range)
    
    for i=1, #data_short do
        
		if data_short[i].distance >= 0 then
			local lj_value = lj_functions.compute_LennardJones(data_short[i].distance, 15, 20)
			vector[1] = vector[1] + factor * math.cos(data_short[i].angle) * lj_value
			vector[2] = vector[2] + factor * math.sin(data_short[i].angle) * lj_value
		end
    end
    
    return vector
end

-- Detect free zones and return a vector to go to them.
-- We say that a scanner detects a free zone when the distance is -2 (means nothing is detected)
-- and we only use the frontal sensors ( -1 < angle < 1)
function attraction_free_zones(factor)
    local vector = {0,0}
	local data_long = table.copy(robot.distance_scanner.long_range)
                                       
	for i=1,#data_long do
                                       
		if math.abs(data_long[i].angle) < 1 and data_long[i].distance == -2 then
			local lj_value = lj_functions.compute_LennardJones(21,20,80)
			vector[1] = vector[1] + factor * math.cos(data_long[i].angle) * lj_value
			vector[2] = vector[2] + factor * math.sin(data_long[i].angle) * lj_value
		end
    end
                                       
    return vector
end
                                       
-- Detect long range obstacles and return a vector to avoid them.
function long_range(factor)
    local data_long = table.copy(robot.distance_scanner.long_range)
    local vector = {0,0}        
                                        
	for i=1,#data_long do
		if data_long[i].distance >= 0 then
			local lj_value = lj_functions.compute_LennardJones(data_long[i].distance, 50, 50)
			vector[1] = vector[1] + factor * math.cos(data_long[i].angle) * lj_value
			vector[2] = vector[2] + factor * math.sin(data_long[i].angle) * lj_value
		end
    end
    
    return vector
end
                                       
function center(factor)
    local data_long = table.copy(robot.distance_scanner.long_range)
    local vector = {0,0}  
    local mean_dist = 0
    local n = 0
                                       
	for i=1,#data_long do
		if data_long[i].distance >= 0 then
			mean_dist = mean_dist + data_long[i].distance
            n = n + 1
		end
    end  
                                       
    mean_dist = mean_dist / n
                                       
	for i=1,#data_long do
		if data_long[i].distance >= 0 then
			local lj_value = lj_functions.compute_LennardJones(data_long[i].distance, mean_dist, 50)
			vector[1] = vector[1] + factor * math.cos(data_long[i].angle) * lj_value
			vector[2] = vector[2] + factor * math.sin(data_long[i].angle) * lj_value
		end
    end
    
    return vector
end                                      
        
---------------------------------------------------------------------------


function lj_functions.process_exploration()
    -- Variables
    local vector = {0,0}
    
    vector[1] = short_range(10)[1] + attraction_free_zones(50)[1] + long_range(1)[1]
    vector[2] = short_range(10)[2] + attraction_free_zones(50)[2] + long_range(1)[2]
    return vector
end

function lj_functions.process_adjust()
    local vector = {0,0}
    previous = range_and_bearing.close_chain_member("previous")
    theta = 2
    
    if previous.distance >= d_chain - theta and previous.distance <= d_chain + theta then
        return -1
    end
                                       
    vector[1] = short_range(10)[1] + attraction_free_zones(50)[1] + long_range(1)[1]
    vector[2] = short_range(10)[2] + attraction_free_zones(50)[2] + long_range(1)[2]
    
    local lj_value = lj_functions.compute_LennardJones(previous.distance, d_chain, 50)
    vector[1] = vector[1] + math.cos(previous.angle) * lj_value
    vector[2] = vector[2] + math.sin(previous.angle) * lj_value

    return vector
end
                                       
function lj_functions.process_merge()
    
    local vector = {0,0}
    vector[1] = short_range(1)[1] 
    vector[2] = short_range(1)[2]
                                       
    same_member = range_and_bearing.same_chain_member()
    lj_value = lj_functions.compute_LennardJones(same_member.d, 20, 50) 
    vector[1] = vector[1] + math.cos(same_member.angle) * lj_value
    vector[2] = vector[2] + math.sin(same_member.angle) * lj_value
    
    -- Close enough
    if same_member.d <= 30 then
        transition(EXPLORER)
    end
    
    return vector
end

function lj_functions.process_goto(target_robot)
    
    local vector = {0,0}
    vector[1] = short_range(10)[1] + attraction_free_zones(50)[1] + long_range(1)[1]
    vector[2] = short_range(10)[2] + attraction_free_zones(50)[2] + long_range(1)[2]
                                       
    lj_value = lj_functions.compute_LennardJones(target_robot.d,d_expl, 50)
    vector[1] = vector[1] + math.cos(target_robot.angle) * lj_value
    vector[2] = vector[2] + math.sin(target_robot.angle) * lj_value

    
    return vector    
end

return lj_functions