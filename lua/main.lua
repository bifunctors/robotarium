Game.createRobot("r1")
Game.createRobot("r2")

function Update()
    for _, robot in ipairs(robots) do
        if robot:canMove("west") then
            robot:move("west")
            Game.console("Moving West")
        end
    end
end
