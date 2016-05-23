------------------------------------------------------------------------------------------------------
--										    CHAIN MEMBER FUNCTIONS
------------------------------------------------------------------------------------------------------

local chain_member = {}

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
	end

end

return chain_member

