# Implementation of a chaining strategy in Swarm Robotics

## Introduction

In real-world swarm robotics applications, exploration is an important behavior.
Often, the environment in which the robots are deployed is unknown
and potentially dangerous for humans, so the robots must be capable to
spread and discover its structure and the important locations.
In the course, we learned the simplest exploration strategy possible—
diffusion. Diffusion can be obtained with a simple obstacle avoidance strategy.
This strategy is very efficient in those cases in which the robots are in
large number (high density of robots per area unit), and the structure of the
environment is relatively simple.
When the environment is very large and its structure is complex, obstacle
avoidance is not sufficient anymore. The robots must engage in some sort of
exploration activity that retains memory of interesting locations and avoid
exploring multiple times the same places, potentially neglecting important
portions of the environment.
Several methods exist to obtain this goal. Since we are working with
robot swarms, we are going to consider a solution that imposes minimal
requirements on the robots—chaining.
In a nutshell, chaining consists in connecting two places (i.e., the nest
and an important location) with a set of robots positioned along the path
that leads from one place to the other. Once the path is formed, additional
robots can communicate with the robots along the path to move from a place
to the other without the need for exploration. In other words, chaining is a
form of collective memory.

## Design pattern : State machine

A state machine allows to decouple a complex problem into simpler instances, whose solution is easier to develop. I use the design of Shervin NOYAN, explained in his report (http://www.swarm-bots.org/dllink.php@id=448&type=documents).

## Technical information

**landmarks.argos** The XML configuration file

**src** A directory that contains the loop functions (i.e., the logic to gather the data) in source format.

**build** The loop functions compilated and ready to be used by the configuration file
