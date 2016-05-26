------------------------------------------------------------------------------------------------------
-- 									TRANSLATION FUNCTIONS
------------------------------------------------------------------------------------------------------

-- Convert the global variables into string for display tasks.

local convert={}

-- Translate the parameter state into word
function convert.number_state(state)
	if state == EXPLORER then
		return "EXPLORER"
	elseif state == CHAIN_MEMBER then
		return "CHAIN_MEMBER"
	end
end

-- Translate the parameter color into word
function convert.number_color(color)
	if color == NONE then
		return "NONE"
	elseif color == BLUE then
		return "BLUE"
	elseif color == GREEN then
		return "GREEN"
	elseif color == RED then
		return "RED"
	end
end

return convert
