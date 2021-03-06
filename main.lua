-- LÖVE LOAD FUNCTION
function love.load()
    anim8 = require 'libraries/anim8/anim8'
    sti = require 'libraries/Simple-Tiled-Implementation/sti'
    cameraFile = require 'libraries/hump/camera'
    require('libraries/show')

    cam = cameraFile()

    sounds = {}
    sounds.jump = love.audio.newSource("assets/audio/jump.wav", "static")
    sounds.music = love.audio.newSource("assets/audio/music.mp3", "stream")
    sounds.music:setLooping(true)
    sounds.music:setVolume(0.25)

    sounds.music:play()

    sprites = {}
    sprites.playerSheet = love.graphics.newImage("assets/sprites/animations/playerSheet.png")
    sprites.enemySheet = love.graphics.newImage("assets/sprites/animations/enemySheet.png")
    sprites.background = love.graphics.newImage("assets/sprites/background.png")

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

    dangerZone = world:newRectangleCollider(-500, 800, 5000, 50, {collision_class = "Danger"})
    dangerZone:setType("static")

    platforms = {}

    flagX = 0
    flagY = 0

    saveData = {}
    saveData.currentLevel = "level1"

    if love.filesystem.getInfo("data.lua") then
        local data = love.filesystem.load("data.lua")
        data()
    end

    loadMap(saveData.currentLevel)
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
        if saveData.currentLevel == "level1" then
            loadMap("level2")
        elseif saveData.currentLevel == "level2" then
            loadMap("level1")
        end
    end

    if player:enter("Danger") then
        loadMap(saveData.currentLevel)
    end
end

-- LÖVE DRAW FUNCTION
function love.draw()
    love.graphics.draw(sprites.background, 0, 0)
    cam:attach()
        gameMap:drawLayer(gameMap.layers["Tile Layer 1"])
        drawPlayer()
        drawEnemies()
    cam:detach()
end

function love.keypressed(key)
    if player.body then
        if key == "space" or key == "w" then
            if player.grounded then
                player:applyLinearImpulse(0, -4000)
                sounds.jump:play()
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
    saveData.currentLevel = mapName
    love.filesystem.write("data.lua", table.show(saveData, "saveData"))
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