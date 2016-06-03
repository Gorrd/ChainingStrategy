--[[ Chaining Strategy
The robots are initially placed in an area that we call the nest. The goal is to form five chains that 
connect the nest with the target locations. The experiment is automatically spotted when there is a robot
in each location.
]]

------------------------------------------------------------------------------------------------------
--									    GLOBAL VARIABLES
------------------------------------------------------------------------------------------------------
-- States
EXPLORER = 0
CHAIN_MEMBER = 1
TARGET = 2
NEST = 3

-- Colors to give information about the robot's location in the chain.
NONE = 0
BLUE = 1
GREEN = 2
RED = 3

-- The robots are all initialized in this state to explore the nest and try to leave it.
current_state = NEST
current_color = NONE

-- Variables for the experiment
WHEELS_SPEED = 40
d_camera = 300 -- To modify !!
d_chain = 150 
d_expl = 70
d_merge = 20
n_robots = 25 -- To modify !!

-- Variable for transition
wait_time = 0

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
local explorer = require("explorer")
local chain_member = require("chain_member")
local target = require("target")
local nest = require("nest")
------------------------------------------------------------------------------------------------------
--										    MAIN PROGRAM
------------------------------------------------------------------------------------------------------

function init()
	current_state = NEST
	robot.leds.set_all_colors("yellow")
	range_and_bearing.emit_data()
	robot.distance_scanner.enable()
   wait_time = 0
   robot.in_chain = 0
end

function step()

	-- Distance scanner rotation
	robot.distance_scanner.set_rpm(200)
	-- Emission of the several data
	range_and_bearing.emit_data()

	-- Main loop
	if current_state == EXPLORER then
		explorer.behavior()
	   
	elseif current_state == CHAIN_MEMBER then
        chain_member.behavior()

	elseif current_state == TARGET then
        target.behavior()

	elseif current_state == NEST then
		  nest.behavior()
	end
	
end

-- Should be the same as init
function reset()
	current_state = NEST
	robot.leds.set_all_colors("yellow")
	range_and_bearing.emit_data()
	robot.distance_scanner.enable()
   wait_time = 0
   robot.in_chain = 0
end

function destroy()
end

-- Transition function, wait time is added
function transition(state)
	 wait_time = robot.random.uniform_int(1,10)

	 if state == NEST then
		current_state = NEST
		robot.leds.set_all_colors("yellow")
	 end

    if state == CHAIN_MEMBER then
        current_state = CHAIN_MEMBER
		 robot.in_chain = 1
        range_and_bearing.set_color_chain()
    end

    if state == EXPLORER then
        current_state = EXPLORER
        current_color = NONE
		  robot.in_chain = 0
		  robot.leds.set_all_colors("black")
    end
    
    if state == TARGET then
        current_state = TARGET
        current_color = NONE
    end
end