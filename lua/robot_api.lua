---@meta

---@class Robot
---@field id integer The unique ID of the robot
---@field x number The X position of the robot
---@field y number The Y position of the robot
---@field forward fun(self: Robot) Move the robot forward
Robot = {}

function Robot.forward() end

return Robot

