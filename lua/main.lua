Game.createRobot("John")

DEBUG = true

function Update()
    for _, robot in ipairs(robots) do
        robot:move("west")
        if DEBUG then
            print("Able to move North " .. tostring(robot:canMove("north")))
            print("Able to move South " .. tostring(robot:canMove("south")))
            print("Able to move West " .. tostring(robot:canMove("west")))
            print("Able to move East " .. tostring(robot:canMove("east")))
            print("Robot Rel Position (" .. robot.x .. "," .. robot.y .. ")")
            print("Robot World Position (" .. robot.worldX .. "," .. robot.worldY .. ")")
        end
    end

end
