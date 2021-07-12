-- LÖVE LOAD FUNCTION
function love.load()
    anim8 = require 'libraries/anim8/anim8'
    sti = require 'libraries/Simple-Tiled-Implementation/sti'
    cameraFile = require 'libraries/hump/camera'

    cam = cameraFile()

    sprites = {}
    sprites.playerSheet = love.graphics.newImage("assets/sprites/animations/playerSheet.png")
    sprites.enemySheet = love.graphics.newImage("assets/sprites/animations/enemySheet.png")

    local grid = anim8.newGrid(614, 564, sprites.playerSheet:getWidth(), sprites.playerSheet:getHeight())
    local enemyGrid = anim8.newGrid(100, 79, sprites.enemySheet:getWidth(), sprites.enemySheet:getHeight())

    animations = {}
    animations.idle = anim8.newAnimation(grid('1-15', 1), 0.05)
    animations.jump = anim8.newAnimation(grid('1-7', 2), 0.05)
    animations.run = anim8.newAnimation(grid('1-15', 3), 0.05)
    animations.enemy = anim8.newAnimation(enemyGrid('1-2', 1), 0.03)

    wf = require 'libraries/windfield/windfield/windfield'
    world = wf.newWorld(0, 800, false)
    world:setQueryDebugDrawing(true)

    world:addCollisionClass("Platform")
    world:addCollisionClass("Player")
    world:addCollisionClass("Danger")

    require('src/player')
    require('src/enemy')

    platforms = {}

    flagX = 0
    flagY = 0

    currentLevel = "level1"

    loadMap(currentLevel)
end

-- LÖVE UPDATE FUNCTION
function love.update(dt)
    world:update(dt)
    gameMap:update(dt)
    updatePlayer(dt)
    updateEnemies(dt)

    local px, py = player:getPosition()
    cam:lookAt(px, love.graphics.getHeight()/2)

    local colliders = world:queryCircleArea(flagX, flagY, 10, {"Player"})
    if #colliders > 0 then
        if currentLevel == "level1" then
            loadMap("level2")
        elseif currentLevel == "level2" then
            loadMap("level1")
        end
    end
end

-- LÖVE DRAW FUNCTION
function love.draw()
    cam:attach()
        gameMap:drawLayer(gameMap.layers["Tile Layer 1"])
        world:draw()
        drawPlayer()
        drawEnemies()
    cam:detach()
end

function love.keypressed(key)
    if player.body then
        if key == "space" or key == "w" then
            if player.grounded then
                player:applyLinearImpulse(0, -4000)
            end
        end
    end
    if key == "r" then
        loadMap("level2")
    end
end

function spawnPlatform(x, y, width, height)
    local platform = world:newRectangleCollider(x, y, width, height, {collision_class = "Platform"})
    platform:setType("static")
    table.insert(platforms, platform)
end

function destroyLevel()
    local i = #platforms
    while i > -1 do
       if platforms[i] ~= nil then
          platforms[i]:destroy()
       end
       table.remove(platforms, i)
        i = i - 1
    end

    local i = #enemies
    while i > -1 do
        if enemies[i] ~= nil then
            enemies[i]:destroy()
        end
        table.remove(enemies, i)
        i = i - 1
    end
end

function loadMap(mapName)
    currentLevel = mapName
    destroyLevel()
    gameMap = sti('assets/maps/' .. mapName .. '.lua')

--  World
    for i, obj in pairs(gameMap.layers["Platforms"].objects) do
        spawnPlatform(obj.x, obj.y, obj.width, obj.height)
    end

--  Enemies
    for i, obj in pairs(gameMap.layers["Enemies"].objects) do
        spawnEnemy(obj.x, obj.y)
    end

-- Spawn
    for i, obj in pairs(gameMap.layers["Spawn"].objects) do
        player:setPosition(obj.x, obj.y)
    end
--  Flag
    for i, obj in pairs(gameMap.layers["Flag"].objects) do
        flagX = obj.x
        flagY = obj.y
    end
end