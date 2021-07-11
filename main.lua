-- LÖVE LOAD FUNCTION
function love.load()
    anim8 = require 'libraries/anim8/anim8'

    sprites = {}
    sprites.playerSheet = love.graphics.newImage("assets/sprites/playerSheet.png")

    local grid = anim8.newGrid(614, 564, sprites.playerSheet:getWidth(), sprites.playerSheet:getHeight())

    animations = {}
    animations.idle = anim8.newAnimation(grid('1-15', 1), 0.05)
    animations.jump = anim8.newAnimation(grid('1-7', 2), 0.05)
    animations.run = anim8.newAnimation(grid('1-15', 3), 0.05)

    wf = require 'libraries/windfield/windfield/windfield'
    world = wf.newWorld(0, 800, false)
    world:setQueryDebugDrawing(true)

    world:addCollisionClass("Platform")
    world:addCollisionClass("Player")
    world:addCollisionClass("Danger")

    require('src/player')

    platform = world:newRectangleCollider(250, 400, 300 , 100, {collision_class = "Platform"})
    platform:setType("static")

    dangerZone = world:newRectangleCollider(0, 550, 800, 50, {collision_class = "Danger"})
    dangerZone:setType("static")
end

-- LÖVE UPDATE FUNCTION
function love.update(dt)
    world:update(dt)
    updatePlayer(dt)
end

-- LÖVE DRAW FUNCTION
function love.draw()
    world:draw()
    drawPlayer()
end

function love.keypressed(key)
    if player.body then
        if key == "space" or key == "w" then
            if player.grounded then
                player:applyLinearImpulse(0, -4000)
            end
        end
    end
end

function love.mousepressed(x, y, button)
    if button == 1 then
        local colliders = world:queryCircleArea(x, y, 200, {"Platform", "Danger"})
        for i,c in ipairs(colliders) do
           c:destroy()
        end
    end
end