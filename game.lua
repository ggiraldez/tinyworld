local game = {}

local input = require('input')

local ph = 32
local pw = 32
local atmosphere = 3 * ph
local radius = love.graphics.getWidth() / 2 - atmosphere
local centerX = love.graphics.getWidth() / 2
local centerY = radius + atmosphere + ph

local levels = 3
local dimensions = {}
local tiles = {}

local playerLevel = 0
local playerPos = 0
local playerSpeed = 2

local playerAlt = radius
local vy = 0
local gravity = -0.1
local inTheAir = false

function game.init()
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
            tiles[level][tile] = 0
        end
    end

    -- initial player position
    playerPos = 0
    playerAlt = dimensions[0].innerRadius
    inTheAir = false
    vy = 0
end

function game.tic()
    input.tic()

    function changeLevel(level)
        local oldLen = dimensions[playerLevel].length
        playerLevel = level
        playerPos = (playerPos / oldLen) * dimensions[playerLevel].length
    end
    
    if not inTheAir then
        if input.up then
            print("jumping")
            vy = vy + 3.8
        end
        if input.down and playerLevel < levels then
            print("falling")
            vy = vy - 2
        end
        if vy < 0 then
            changeLevel(playerLevel + 1)
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
                changeLevel(playerLevel - 1)
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

    if input.left then
        playerPos = playerPos + playerSpeed
    end
    if input.right then
        playerPos = playerPos - playerSpeed
    end

    playerPos = playerPos % (dimensions[playerLevel].length)
end

function renderPlayer()
    -- player
    local x = centerX
    local y = centerY - playerAlt 
    love.graphics.quad('fill', x - pw/2, y - ph, x + pw/2, y - ph,
                               x + pw/2, y,      x - pw/2, y)
    love.graphics.print(playerPos, centerX, 0)
end

function playerTile()
    local dims = dimensions[playerLevel]
    local p = playerPos
    local tw = dims.twi
    local count = dims.count
    p = p + tw/2
    return math.floor(p / tw) % count
end

function renderPlanet()
    love.graphics.push()
    love.graphics.translate(centerX, centerY)
    local worldAngle = 2*math.pi * playerPos / dimensions[playerLevel].length
    love.graphics.rotate(-math.pi/2 + worldAngle)

    function drawtiles(level)
        local sizes = dimensions[level]
        local count = sizes.count
        local r = sizes.outerRadius
        local tw = sizes.tw
        local th = sizes.th
        local angleStep = 2*math.pi / count

        local pt = playerTile()

        love.graphics.push()
        for i = 0, count-1 do
            local restore = false

            love.graphics.quad('line', r-th, -tw/2, r,    -tw/2,
                                       r,     tw/2, r-th,  tw/2)

            if restore then
                love.graphics.setColor(255,255,255)
            end

            love.graphics.rotate(-angleStep)
        end
        love.graphics.pop()
    end

    for level = 1,levels do
        drawtiles(level)
    end

    love.graphics.pop()
end

function game.render()
    renderPlanet()
    renderPlayer()
end

return game

