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
local lj_functions = require("lj_functions")
local explorer = require("explorer")

---------------------------------------------------------------------------
-- Main function called each step 
function chain_member.behavior()
    
    if wait_time > 0 then
        wait_time = wait_time - 1
    else
        robot.wheels.set_velocity(0,0)
        
        -- When the chain member detects nothing, it goes on exploration. If 
        -- this condition is triggered it means the robot is close to a target spot.
        if range_and_bearing.robot_detected(CHAIN_MEMBER) == 0 
        and range_and_bearing.robot_detected(EXPLORER) == 0 then 
            explorer.explore()
        end
        
        -- Ground check
        if range_and_bearing.isOnNest() then
            transition(EXPLORER)
        end
        
        -- Target check
        if range_and_bearing.isOnTarget() 
        and range_and_bearing.robot_detected(TARGET) == 0 then
            transition(TARGET)
        end
        
        -- Adjust distance with the previous member of the chain
        if range_and_bearing.close_chain_member_detected("previous") then
            adjust_distance()
        end
        
        -- Merge with the same chain member
        if range_and_bearing.same_chain_member_detected() then
            merge()
        end
    end
end

function adjust_distance()
    local vector = lj_functions.process_adjust()
    
    if vector == -1 then
        robot.wheels.set_velocity(0,0)
    else
        local desired_angle = math.atan2(vector[2],vector[1]) 
        speeds = lj_functions.compute_SpeedFromAngle(desired_angle)
        robot.wheels.set_velocity(speeds[1],speeds[2])
    end
end

function merge()
    local vector = lj_functions.process_merge()
    
    if vector ~= -1 then
        local desired_angle = math.atan2(vector[2],vector[1]) 
        speeds = lj_functions.compute_SpeedFromAngle(desired_angle)
        robot.wheels.set_velocity(speeds[1],speeds[2])    
    end
end

return chain_member

