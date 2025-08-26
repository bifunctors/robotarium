---@meta

---@class Robot
---@field id integer The unique ID of the robot
---@field x integer The robot's relative X position within its home
---@field y integer The robot's relative Y position within its home
---@field worldX integer The robot's absolute X position in the world
---@field worldY integer The robot's absolute Y position in the world
local Robot = {}

---Move the robot in the specified direction
---@param direction "north"|"south"|"east"|"west" The direction to move
---@return boolean success True if the move was successful, false if already moved this turn
function Robot:move(direction) end

---Check if the robot can move in the specified direction
---@param direction "north"|"south"|"east"|"west" The direction to check
---@return boolean canMove True if the robot can move in that direction
function Robot:canMove(direction) end

return Robot
