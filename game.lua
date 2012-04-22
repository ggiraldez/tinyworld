local game = {}

local input = require('input')

-- player state
local ph = 32
local pw = 32
local playerAlt
local inTheAir
local playerLevel
local playerAngle = 0
local playerSpeed = 2
local vy = 0

-- geometry vars
local atmosphere = 3 * ph
local radius = love.graphics.getWidth() / 2 - atmosphere
local centerX = love.graphics.getWidth() / 2
local centerY = radius + atmosphere + ph
local gravity = -0.2

-- planet tiles
local levels = 3
local dimensions = {}
local tiles = {}

local textures = {}
local quads = {}

local starField = {}

function loadTextures()
    local w, h

    -- load tiles
    textures.tiles = love.graphics.newImage('images/tiles.png')
    w = textures.tiles:getWidth()
    h = textures.tiles:getHeight()

    -- quads for the tiles
    quads[1] = {}
    quads[2] = {}
    quads[3] = {}
    quads[1][0] = love.graphics.newQuad(0,  0, 32, 32,   w, h)
    quads[1][1] = love.graphics.newQuad(32, 0, 32, 32,   w, h)
    quads[1][2] = love.graphics.newQuad(64, 0, 32, 32,   w, h)
    quads[2][0] = love.graphics.newQuad(0,  64, 27, 32,  w, h)
    quads[2][1] = love.graphics.newQuad(27, 64, 27, 32,  w, h)
    quads[2][2] = love.graphics.newQuad(54, 64, 27, 32,  w, h)
    quads[3][0] = love.graphics.newQuad(0,  128, 22, 32, w, h)
    quads[3][1] = love.graphics.newQuad(22, 128, 22, 32, w, h)
    quads[3][2] = love.graphics.newQuad(44, 128, 22, 32, w, h)

    -- stars
    textures.stars = love.graphics.newImage('images/stars.png')
    w = textures.tiles:getWidth()
    h = textures.tiles:getHeight()

    -- stars' quads
    quads.stars = {}
    quads.stars[0] = love.graphics.newQuad(0,  0, 16, 16, w, h)
    quads.stars[1] = love.graphics.newQuad(16, 0, 16, 16, w, h)
    quads.stars[2] = love.graphics.newQuad(32, 0, 16, 16, w, h)
    quads.stars[3] = love.graphics.newQuad(48, 0, 16, 16, w, h)

    -- planet core
    textures.core = love.graphics.newImage('images/core.png')
end



function game.init()
    loadTextures()

    -- initialize starfield
    local span = math.max(centerX, centerY) * 1.3
    for i = 1, 300 do
        local x = 0
        local y = 0
        while x*x + y*y < radius*radius do
            x = math.random(-span, span)
            y = math.random(-span, span)
        end
        starField[i] = { x = x, y = y, r = math.random() * 2*math.pi, t = math.random(0,3) }
    end

    -- level 0: atmosphere
    -- level 1: cortex
    -- level 2+: deeper levels
    -- base dimensions (cortex tiles are 64x64)
    -- r1: cortex outer radius is the planet radius
    -- c1: tile count at the cortex
    local th = 64
    local tw = 64
    local r1 = radius
    local c1 = math.ceil(2*math.pi*r1 / tw)

    -- calculate dimensions
    for level = 0, levels do
        local count = c1
        local r = r1 - th * (level - 1)
        local ir = r - th
        local len = (2*math.pi*ir)
        local tw = (2*math.pi*r / count)
        local twi = (2*math.pi*ir / count)
        dimensions[level] = { tw = tw,
                              twi = twi,
                              th = th, 
                              count = count, 
                              outerRadius = r,
                              innerRadius = ir,
                              length = len
                            }
        print("Level #" .. level .. 
              ": count=" .. count .. 
              ", outerRadius=" .. r .. ", innerRadius=" .. ir .. 
              ", th=" .. th .. ", tw=" .. tw .. ", twi=" .. twi .. 
              ", length=" .. len)
    end

    -- generate tiles
    for level = 0, levels do
        tiles[level] = {}
        local count = dimensions[level].count
        for tile = 0, count - 1 do
            tiles[level][tile] = math.random(0, 2)
        end
    end

    -- initial player position
    playerAngle = 0
    playerAlt = dimensions[0].innerRadius
    inTheAir = false
    vy = 0
end

function game.tic()
    input.tic()

    if not inTheAir then
        if input.up then
            vy = vy + 5.5
        end
        if input.down and playerLevel < levels then
            vy = vy - 2
        end
        if vy < 0 then
            playerLevel = playerLevel + 1
        end
        if vy ~= 0 then
            inTheAir = true
        end
    end

    if inTheAir then
        local floor = dimensions[playerLevel].innerRadius
        local ceiling = dimensions[playerLevel].outerRadius
        vy = vy + gravity
        playerAlt = playerAlt + vy
        if vy > 0 then
            -- jumping
            if playerAlt > ceiling and playerLevel > 0 then
                playerLevel = playerLevel - 1
            end
        else
            -- falling
            if playerAlt < floor then
                playerAlt = floor
                vy = 0
                inTheAir = false
            end
        end
    end

    local vx = 0
    if input.left then
        vx = vx + playerSpeed
    end
    if input.right then
        vx = vx - playerSpeed
    end

    if vx ~= 0 then
        playerAngle = playerAngle + vx / playerAlt
        playerAngle = playerAngle % (2*math.pi)
    end
end

function renderPlayer()
    -- player
    local x = centerX
    local y = centerY - playerAlt 
    love.graphics.quad('fill', x - pw/2, y - ph, x + pw/2, y - ph,
                               x + pw/2, y,      x - pw/2, y)
end

function playerTile()
    local dims = dimensions[playerLevel]
    local tileArc = 2*math.pi / dims.count
    return math.floor((playerAngle + tileArc/2) / tileArc) % dims.count
end

function renderPlanet()
    love.graphics.push()
    love.graphics.translate(centerX, centerY)
    love.graphics.rotate(playerAngle)

    -- render core
    local w = textures.core:getWidth()
    local h = textures.core:getHeight()
    love.graphics.draw(textures.core, -w, -h, 0, 2, 2)   

    -- render cortex levels
    function drawtiles(level)
        local sizes = dimensions[level]
        local count = sizes.count
        local r = sizes.outerRadius
        local tw = sizes.tw
        local th = sizes.th
        local angleStep = 2*math.pi / count

        love.graphics.push()
        for i = 0, count-1 do
            love.graphics.drawq(textures.tiles, quads[level][tiles[level][i]],
                                math.ceil(-tw/2), -r, 0, 2, 2)
            love.graphics.rotate(-angleStep)
        end
        love.graphics.pop()
    end

    for level = 1,levels do
        drawtiles(level)
    end

    love.graphics.pop()
end

function renderStarfield()
    love.graphics.push()
    love.graphics.translate(centerX, centerY)
    love.graphics.rotate(playerAngle)
    for i = 1, #starField do
        local s = starField[i]
        love.graphics.drawq(textures.stars, quads.stars[s.t], s.x, s.y, s.r, .5, .5)
    end
    love.graphics.pop()
end

function game.render()
    renderStarfield()
    renderPlanet()
    renderPlayer()
end

return game

