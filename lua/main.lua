Game.createRobot("r1")

local stopped = false

function Update()
    for _, robot in ipairs(robots) do
        if stopped then
            goto continue
        end
        if robot:canMove("west") then
            robot:move("west")
        else
            stopped = true
            Game.notify("Hit Bounds Of Home")
        end
        ::continue::
    end
end
