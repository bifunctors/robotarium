pub const GAME_API_LUA_FILE =
    \\---@meta
    \\---@class Game
    \\Game = {}
    \\---@param name string
    \\function Game.createRobot(name) end
    \\---@param msg string
    \\function Game.console(msg) end
    \\---@param msg string
    \\function Game.notify(msg) end
    \\return Game
;

pub const GLOBALS_API_LUA_FILE =
    \\---@meta
    \\---@type Robot[] Array of all robots available to the user
    \\robots = {}
;

pub const ROBOT_API_LUA_FILE =
    \\---@meta
    \\---@class Robot
    \\---@field id integer The unique ID of the robot
    \\---@field x integer The robot's relative X position within its home
    \\---@field y integer The robot's relative Y position within its home
    \\---@field worldX integer The robot's absolute X position in the world
    \\---@field worldY integer The robot's absolute Y position in the world
    \\local Robot = {}
    \\---Move the robot in the specified direction
    \\---@param direction "north"|"south"|"east"|"west" The direction to move
    \\---@return boolean success True if the move was successful, false if already moved this turn
    \\function Robot:move(direction) end
    \\---Check if the robot can move in the specified direction
    \\---@param direction "north"|"south"|"east"|"west" The direction to check
    \\---@return boolean canMove True if the robot can move in that direction
    \\function Robot:canMove(direction) end
    \\return Robot
;

pub const MAIN_API_LUA_FILE =
    \\-- Get Started:
    \\-- First, Create Your Robot
    \\Game.createRobot("biff")
    \\
    \\-- Then put your looping logic inside here
    \\function Update()
    \\    -- This loops every tick
    \\end
;
