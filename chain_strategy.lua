--[[ Chaining Strategy
The robots are initially placed in an area that we call the nest. The goal is to form five chains that 
connect the nest with the target locations. The experiment is automatically spotted when there is a robot
in each location.
]]

------------------------------------------------------------------------------------------------------
--									    GLOBAL VARIABLES
------------------------------------------------------------------------------------------------------
-- States
-- EXPLORER state
-- Move around the nest searching for chains, then navigates along a chain to explore the environment.
EXPLORER = 1

-- CHAIN_MEMBER state
-- Activates when a robot is aggregated into a chain.
CHAIN_MEMBER = 2

-- TARGET state
-- The robot is on the black spot and doesnt move anymore.
TARGET = 3

-- The robots are all initialized in this state to explore the nest and try to leave it.
current_state = EXPLORER

-- Probabilities of some state's transition

p_expl_chain = 0.1 -- Exploration -> Chain member
p_chain_expl = 1-p_expl_chain -- Chain member -> Exploration

-- Count how many steps left for the robot's transition
current_transition_steps = -1
long_range_steps = 0

-- If the explorer found the last member of the chain
last_chain_member_found = false

-- Counter for merge behavior
merged_steps = 0

-- When a close obstacle is sensed, the collision behavior is executed prior to others
avoid_collision = false


-- Colors to give information about the robot's location in the chain
NONE = 0
BLUE = 1
GREEN = 2
RED = 3
current_color = 0

-- Variables for the experiment

d_expl = 50 -- desired distance between an explorer and his chosen chain-member
d_camera = 200 -- camera sensing range
d_merge = 30 -- distance threshold for two chain-members to merge into one
d_chain = 200 -- the target distance between robots, in cm
EPSILON = 50 -- a coefficient to increase the force of the repulsion/attraction function
WHEELS_SPEED = 40 -- Speed of the wheels

------------------------------------------------------------------------------------------------------
--										    HELPFUL FUNCTIONS
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

-- Load others lua files
local range_and_bearing = require("range_and_bearing")
local logs = require("logs")
local explorer = require("explorer")
local chain_member = require("chain_member")

------------------------------------------------------------------------------------------------------
--										    MAIN PROGRAM
------------------------------------------------------------------------------------------------------

function init()
	current_state = EXPLORER
	current_color = NONE
	range_and_bearing.emit_data()
	robot.in_chain = 0
	robot.distance_scanner.enable()
	current_transition_steps = -1
   long_range_steps = 0
	merge_steps = robot.random.uniform_int(1,20)
end

function step()

	-- Distance scanner rotation
	robot.distance_scanner.set_rpm(30/math.pi)

	-- Emission of the several data
	range_and_bearing.emit_data()

	-- Main loop
	if current_state == EXPLORER then
		explorer.behavior()
	   
	elseif current_state == CHAIN_MEMBER then
	   chain_member.behavior()

	elseif current_state == TARGET then
		-- Nothing to do.
	end
	
end

-- Should be the same as init
function reset()
	current_state = EXPLORER
	current_color = NONE
	range_and_bearing.emit_data()
	robot.in_chain = 0
	robot.distance_scanner.enable()
	current_transition_steps = -1
   long_range_steps = 0
	merge_steps = robot.random.uniform_int(1,20)
end

function destroy()
end


------------------------------------------------------------------------------------------------------


