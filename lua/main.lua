Game.createRobot("r1")

function Update()
    for _, robot in ipairs(robots) do
        if robot:canMove("west") then
            robot:move("west")
        end
    end
end
