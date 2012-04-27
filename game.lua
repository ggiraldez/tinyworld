local game = {}

local input = require('input')
local gfx = require('gfx')
local map = require('map')

-- player state
local ph = 32
local pw = 32
local playerAlt
local inTheAir
local playerLevel
local playerAngle = 0
local maxSpeed = 2
local accel = .2
local vy = 0
local vx = 0
local playerFrame = 0
local playerDir = 1

-- geometry vars
local atmosphere = 3 * ph
local radius = love.graphics.getWidth() / 2 - atmosphere
local centerX = love.graphics.getWidth() / 2
local centerY = radius + atmosphere + ph
local gravity = -0.2

-- planet tiles
local dimensions = {}
local tiles = {}
local levels = map.levels

local textures = gfx.textures
local quads = gfx.quads

local starField = {}


---------------------------------------------------------------------------------
-- Initialization code
---------------------------------------------------------------------------------

local function starfieldInit()
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
end

local function tilesInit()
    -- level 0: atmosphere
    -- level 1: outer cortex
    -- level 2: mid cortex
    -- level 3: inner cortex
    -- base dimensions (outer cortex tiles are 64x64)
    -- r1: outer cortex outer radius is the planet radius
    -- c1: tile count at the outer cortex
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

    for level = 0, levels do
        tiles[level] = {}
        local count = dimensions[level].count
        for tile = 0, count - 1 do
            local t
            if level == 1 then 
                t = math.random(0,3) 
            else 
                t = math.random(0,2)
            end
            tiles[level][tile] = t
        end
    end

end


function game.init()
    gfx.init()
    map.init()
    map.validate()

    starfieldInit()
    tilesInit()

    -- initial player position
    playerAngle = 0
    playerAlt = dimensions[0].innerRadius
    playerLevel = 0
    playerFrame = 0
    inTheAir = false
    vy = 0
end


----------------------------------------------------------------------------------
-- Auxiliary functions
----------------------------------------------------------------------------------

function playerTile()
    local dims = dimensions[playerLevel]
    local tileArc = 2*math.pi / dims.count
    return math.floor((playerAngle + tileArc/2) / tileArc) % dims.count
end


----------------------------------------------------------------------------------
-- Game logic
----------------------------------------------------------------------------------

function game.tic()
    input.tic()

    -- vertical controls
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

    -- update player altitude
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

    -- horizontal controls
    local a = accel
    if inTheAir then
        a = a / 4
    end
    if input.left or input.right then
        if input.left then
            vx = vx + 2*a
            playerDir = -1
        else
            vx = vx - 2*a
            playerDir = 1
        end
    else
        if vx > 0 then
            vx = math.max(vx - a, 0)
        elseif vx < 0 then
            vx = math.min(vx + a, 0)
        end
    end
    if vx > maxSpeed then
        vx = maxSpeed
    elseif vx < -maxSpeed then
        vx = -maxSpeed
    end

    playerAngle = playerAngle + vx / playerAlt
    playerAngle = playerAngle % (2*math.pi)

    if vx == 0 then
        playerFrame = 0
    else
        playerFrame = playerFrame + vx
    end
end


---------------------------------------------------------------------------------
-- Render code
---------------------------------------------------------------------------------

function renderPlayer()
    local q = 0
    if inTheAir then
        if vy < -2 then
            q = 'falling'
        else
            q = 'jumping'
        end
    else
        if vx == 0 then
            q = 0
        else
            q = math.floor(playerFrame / 4) % 10
        end
    end

    local sx = 2
    local sy = 2
    if playerDir < 0 then
        sx = -sx
    end

    local x = centerX
    local y = centerY - playerAlt 
    love.graphics.drawq(textures.player, quads.player[q],
                        x - sx/math.abs(sx) * pw/2, y - ph, 0, sx, sy)
    --love.graphics.quad('line', x - pw/2, y - ph, x + pw/2, y - ph,
    --                           x + pw/2, y,      x - pw/2, y)
end

function renderPlanet()
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
        local q = quads[level]
        local t = tiles[level]

        love.graphics.push()
        for i = 0, count-1 do
            love.graphics.drawq(textures.tiles, q[t[i]],
                                math.ceil(-tw/2), -r, 0, 2, 2)
            love.graphics.rotate(-angleStep)
        end
        love.graphics.pop()
    end

    for level = 1,levels do
        drawtiles(level)
    end
end

function renderStarfield()
    for i = 1, #starField do
        local s = starField[i]
        love.graphics.drawq(textures.stars, quads.stars[s.t], s.x, s.y, s.r, .5, .5)
    end
end

function game.render()
    love.graphics.push()
    love.graphics.translate(centerX, centerY)
    love.graphics.rotate(playerAngle)
        renderStarfield()
        renderPlanet()
    love.graphics.pop()

    renderPlayer()
end


return game

