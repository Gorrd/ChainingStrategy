--[[ Chaining Strategy
The robots are initially placed in an area that we call the nest. The goal is to form five chains that 
connect the nest with the target locations. The experiment is automatically spotted when there is a robot
in each location.
]]

------------------------------------------------------------------------------------------------------
--														GLOBAL VARIABLES
------------------------------------------------------------------------------------------------------
-- States
-- EXPLORER states
-- Move around the nest searching for chains, then navigates along a chain to explore the environment.
EXPLORER = 1
EXPLORER_FWD = 11 -- The robot moves along a chain the direction away from the nest
EXPLORER_BWD = 12  -- The robot moves along a chain the direction back toward the nest

-- CHAIN_MEMBER states
-- Activates when a robot is aggregated into a chain.
CHAIN_MEMBER = 2
CHAIN_MEMBER_LAST = 21 -- The robot is the last member of its chain
CHAIN_MEMBER_NOT_LAST = 22 -- The robot is not the last member of its chain

-- The robots are all initialized in this state to explore the nest
current_state = EXPLORER
current_substate = EXPLORER_FWD

-- Probabilities of some state's transition
p_expl_chain = 0.01 -- Exploration -> Chain member
p_chain_expl = 0.1 -- Chain member -> Exploration

-- Colors to give information about the robot's location in the chain
NONE = 0
BLUE = 1
GREEN = 2
RED = 3
current_color = 0

------------------------------------------------------------------------------------------------------
--														HELPFUL FUNCTIONS
------------------------------------------------------------------------------------------------------

-- function used to copy two tables
function table.copy(t)
  local t2 = {}
  for k,v in pairs(t) do
    t2[k] = v
  end
  return t2
end

-- Round numbers
function round(num, idp)
  local mult = 10^(idp or 0)
  return math.floor(num * mult + 0.5) / mult
end

------------------------------------------------------------------------------------------------------
--															MAIN PROGRAM
------------------------------------------------------------------------------------------------------

function init()
	current_state = EXPLORER
	current_substate = EXPLORER_FWD
	current_color = NONE
	emit_data()
	robot.in_chain = 0
end

function step()

	-- Emission of the several data
	emit_data()

	-- Writting in logs
	write_logs()

	-- Main loop
	if current_state == EXPLORER then
		explorer_behavior()
	
	elseif current_state == CHAIN_MEMBER then
		chain_member_behavior()
	end

end

-- Should be the same as init
function reset()
	current_state = EXPLORER
	current_substate = EXPLORER_FWD
	current_color = NONE
	emit_data()
	robot.in_chain = 0
end

function destroy()
end

------------------------------------------------------------------------------------------------------
-- 														LOGS FUNCTIONS
------------------------------------------------------------------------------------------------------

-- Writing in the logs
function write_logs()
	log("Robot ID : "..robot.id)
	log("State : "..number_state(current_substate))
	log("Explorers robots detected : "..robot_detected(EXPLORER))
	log("Chain members robots detected : "..robot_detected(CHAIN_MEMBER))
	log("Lost robots detected : "..robot_detected(LOST))
	robot_detected_logs()
	log("-------------------------------")
end

-- Write useful informations about detected robots
function robot_detected_logs()
	sort_data = table.copy(robot.range_and_bearing)
	table.sort(sort_data, function(a,b) return a.range<b.range end)
	for i = 1,#robot.range_and_bearing do
		log(
		sort_data[i].data[3]," - ", 
		number_state(sort_data[i].data[1])," - ",
		number_color(sort_data[i].data[2])," - ",
		sort_data[i].range
		)
	end
end

------------------------------------------------------------------------------------------------------
-- 													TRANSLATION FUNCTIONS
------------------------------------------------------------------------------------------------------

-- Translate the parameter state into word
function number_state(state)
	if state == EXPLORER_FWD then
		return "EXPLORER_FWD"
	elseif state == EXPLORER_BWD then
		return "EXPLORER_BWD"
	elseif state == CHAIN_MEMBER_LAST then
		return "CHAIN_MEMBER_LAST"
	elseif state == CHAIN_MEMBER_NOT_LAST then
		return "CHAIN_MEMBER_NOT_LAST"
	elseif state == EXPLORER then
		return "EXPLORER"
	elseif state == CHAIN_MEMBER then
		return "CHAIN_MEMBER"
	end
end

-- Translate the parameter color into word
function number_color(color)
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

------------------------------------------------------------------------------------------------------
-- 													BEHAVIOR FUNCTIONS
------------------------------------------------------------------------------------------------------

-- What the robot does when it is explorating his environment
function explorer_behavior()
	robot.leds.set_all_colors("white")

	-- Start condition : robot is on nest, no chain detected
	-- Time create a new chain !
	if current_substate == EXPLORER_FWD
	and isOnNest()
	and robot_detected(CHAIN_MEMBER) == 0
	and robot.random.bernoulli(p_expl_chain) == 1 then
		current_state = CHAIN_MEMBER
		current_substate = CHAIN_MEMBER_LAST
		set_color_chain()

	-- The explorer senses one chain member. A probabilistic event will trigger the aggregation
	-- of the robot to the chain.
	elseif current_substate == EXPLORER_FWD
	and robot_detected(CHAIN_MEMBER) == 1
	and robot.random.bernoulli(p_expl_chain) == 1 then
		current_state = CHAIN_MEMBER
		current_substate = CHAIN_MEMBER_LAST
		set_color_chain()

	-- The explorer senses two chain members or more. It will follow one chain member based on his substate.
	elseif robot_detected(CHAIN_MEMBER) >= 2 then
		move_along_chain()

	-- The backward explorer founds the nest and is ready to go on
	elseif current_substate == EXPLORER_BWD
	and isOnNest() then
		current_substate = EXPLORER_FWD
	
	else
		explore()
	end
end

-- The robot is aggregated on a chain
function chain_member_behavior()
	robot.wheels.set_velocity(0,0)

	-- Chain member last -> Chain member not last
	if current_substate == CHAIN_MEMBER_LAST
	and next_chain_color_detected() then
		current_substate = CHAIN_MEMBER_NOT_LAST

	-- Chain member not last -> Chain member last
	elseif current_substate == CHAIN_MEMBER_NOT_LAST
	and not(next_chain_color_detected()) then
		current_substate = CHAIN_MEMBER_LAST

	-- Chain member last -> explorer backward
	elseif current_substate == CHAIN_MEMBER_LAST
	and robot_detected(EXPLORER) == 0
	and robot.random.bernoulli(p_chain_expl) == 1 then
		current_state = EXPLORER
		current_substate = EXPLORER_BWD
		current_color = NONE
	end

end

------------------------------------------------------------------------------------------------------
-- 												RANGE AND BEARING FUNCTIONS
------------------------------------------------------------------------------------------------------

-- The robot emits his state (= 1) and his color (= 2) and his ID (= 3)
function emit_data()
	robot.range_and_bearing.set_data(1,current_state)
	robot.range_and_bearing.set_data(2,current_color)
	robot.range_and_bearing.set_data(3,tonumber(string.match(robot.id, "[0-9]+")))
end

-- Set the color (position) of the robot in the chain. Called only when one robot is sensed !!
function set_color_chain()

	for i = 1,#robot.range_and_bearing do
		if robot.range_and_bearing[i].range < 150 and robot.range_and_bearing[i].data[2] == BLUE then
			robot.leds.set_all_colors("green")
			current_color = GREEN
			break

		elseif robot.range_and_bearing[i].range < 150 and robot.range_and_bearing[i].data[2] == GREEN then
			robot.leds.set_all_colors("red")
			current_color = RED
			break

		elseif robot.range_and_bearing[i].range < 150 and robot.range_and_bearing[i].data[2] == RED then
			robot.leds.set_all_colors("blue")
			current_color = BLUE
			break
		else
			robot.leds.set_all_colors("blue")
			current_color = BLUE
		end
	end
end

-- Return how many robots with the parameter state
function robot_detected(state)
	number_robot_sensed = 0

	for i = 1,#robot.range_and_bearing do
		if robot.range_and_bearing[i].range < 150 and robot.range_and_bearing[i].data[1] == state then
			number_robot_sensed = number_robot_sensed + 1
		end
	end
	return number_robot_sensed
end

-- Sense the nest
function isOnNest()
	sort_ground = table.copy(robot.motor_ground)
   table.sort(sort_ground, function(a,b) return a.value<b.value end)
	if round(sort_ground[1].value,2) == 0.9 then
		return true
	else
		return false
	end
end

-- Detect if the next color of the chain is detected
function next_chain_color_detected()
	for i = 1,#robot.range_and_bearing do

		if robot.range_and_bearing[i].range < 150 
		and current_color == BLUE
		and robot.range_and_bearing[i].data[2] == GREEN then
			return true

		elseif robot.range_and_bearing[i].range < 150 
		and current_color == GREEN
		and robot.range_and_bearing[i].data[2] == RED then
			return true

		elseif robot.range_and_bearing[i].range < 150 
		and current_color == RED
		and robot.range_and_bearing[i].data[2] == BLUE then
			return true
		end
	end
	return false
end

------------------------------------------------------------------------------------------------------

-- LOLILOL
function move_along_chain()
	-- First : find the two closest chain members. We need color
	explore()
end

function explore()
	-- We treat each proximity reading as a vector. The value represents the length
	-- and the angle gives the angle of corresponding to the reading, wrt the robot's coordinate system
	-- First, we sum all the vectors.
	accumul = { x=0, y=0 }
	for i = 1, 24 do 
		-- we calculate the x and y components given length and angle
		vec = {
			x = robot.proximity[i].value * math.cos(robot.proximity[i].angle),
			y = robot.proximity[i].value * math.sin(robot.proximity[i].angle)
		}
		-- we sum the vectors into a variable called accumul
		accumul.x = accumul.x + vec.x
		accumul.y = accumul.y + vec.y
	end
	-- we get length and angle of the final sum vector
	length = math.sqrt(accumul.x * accumul.x + accumul.y * accumul.y)
	angle = math.atan2(accumul.y, accumul.x)

	
	if length > 0.2 then
		-- If the angle is greater than 0 the resulting obstacle is on the left. Otherwise it is on the right
		-- We turn with a speed that depends on the angle. The closer the obstacle to the x axis
		-- of the robot, the quicker the turn
		if angle > 0 then
			robot.wheels.set_velocity(math.max(0.5,math.cos(angle)) * 5,0)
		else
			robot.wheels.set_velocity(0, math.max(0.5,math.cos(angle)) * 5)	
		end
	else 
			-- No obstacle. We go straight
			robot.wheels.set_velocity(5,5)
	end
end
