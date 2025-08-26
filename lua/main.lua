Game.createRobot("John")

DEBUG = false

function Update()
    for _, robot in ipairs(robots) do
        robot:move("north")
    end

end
