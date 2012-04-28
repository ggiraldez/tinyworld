local game = {}

local input = require('input')
local gfx = require('gfx')
local map = require('map')

-- player state
local ph = 32
local pw = 32
local playerAlt
local inTheAir
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

function game.init()
    gfx.init()
    
    map.init()
    map.validate()

    dimensions = map.calculateDimensions()
    tiles = map.generateTiles()

    starfieldInit()

    -- initial player position
    playerAngle = 0
    playerAlt = dimensions[0].innerRadius + ph
    playerFrame = 0
    inTheAir = true
    vy = 0
end

function game.reloadGfx()
    gfx.reload()
end

----------------------------------------------------------------------------------
-- Auxiliary functions
----------------------------------------------------------------------------------

local function playerTile(angle)
    local count = dimensions[0].count
    local tileArc = 2*math.pi / count

    if not angle then angle = playerAngle end
    angle = -angle + tileArc/2

    local index = math.floor(angle / tileArc) % count
    local fraction = (angle % tileArc) / tileArc
    
    -- index is [0,count)
    -- fraction is [0,1]
    return index, fraction
end

local function calculateHeights(angle)
    local i, f = playerTile(angle)
    local hs = { }

    for level = 0, levels do
        local et, eb
        if f < .5 then
            -- pick tiles on the left
            local ttl = tiles[level][4*i+0]
            local btl = tiles[level][4*i+2]
            local si = math.floor(#(quads[level].ht[ttl]) * 2*f)
            et = quads[level].ht[ttl][si]
            eb = quads[level].hb[btl][si]
        else
            -- pick tiles on the right
            local ttr = tiles[level][4*i+1]
            local btr = tiles[level][4*i+3]
            local si = math.floor(#(quads[level].ht[ttr]) * 2*(f-0.5))
            et = quads[level].ht[ttr][si]
            eb = quads[level].hb[btr][si]
        end

        -- radiuses
        local ri = dimensions[level].innerRadius
        local ro = dimensions[level].outerRadius
        local rm = (ri+ro)/2

        -- heights for this level
        local ht, hb
        ht = rm + 2*et
        hb = ri + 2*eb
        if level == 0 then ht = 2*ro end

        if math.abs(ht - hb) > 1 then
            if level > 0 and math.abs(hs[#hs] - ht) < 2 then
                hs[#hs] = math.floor(hb)
            else
                table.insert(hs, math.ceil(ht))
                table.insert(hs, math.floor(hb))
            end
        end
    end

    return hs
end


----------------------------------------------------------------------------------
-- Game logic
----------------------------------------------------------------------------------

local function findFloorCeil(angle)
    local hs = calculateHeights(angle)
    for i = 1, #hs, 2 do
        if playerAlt + ph - 8 <= hs[i] and playerAlt + 4 >= hs[i+1] then
            return hs[i+1], hs[i]
        end
    end
    return playerAlt, playerAlt
end

function game.tic()
    local floor, ceiling

    input.tic()

    -- vertical controls
    if not inTheAir then
        if input.up then
            vy = vy + 5.5
        end
        if vy ~= 0 then
            inTheAir = true
        end
    end

    -- update player altitude
    if inTheAir then
        floor, ceil = findFloorCeil(playerAngle)
        if ceil == floor then ceil = floor + ph end

        vy = vy + gravity
        playerAlt = playerAlt + vy

        if vy > 0 then
            if playerAlt + ph > ceil then
                -- we hit the ceiling
                playerAlt = ceil - ph
                vy = 0
            end
        else
            if playerAlt < floor then
                -- we reached the floor
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

    local saveAngle = playerAngle
    playerAngle = playerAngle + vx / playerAlt
    playerAngle = playerAngle % (2*math.pi)

    if vx == 0 then
        playerFrame = 0
    else
        playerFrame = playerFrame + vx
    end

    if vx ~= 0 then
        if vx > 0 then
            floor, ceil = findFloorCeil(playerAngle + (pw-16)/playerAlt/2)
        elseif vx < 0 then
            floor, ceil = findFloorCeil(playerAngle - (pw-16)/playerAlt/2)
        end
        if math.abs(playerAlt - floor) < 4 and not inTheAir then
            playerAlt = floor
        elseif playerAlt > floor then
            inTheAir = true
        end
        if floor == ceil then
            -- means we hit a wall
            vx = 0
            playerAngle = saveAngle
        end
    end
end


---------------------------------------------------------------------------------
-- Render code
---------------------------------------------------------------------------------

local function renderPlayer()
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

end

local function renderPlanet()
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
            local base = i * 4
            if t[base+0] then
                love.graphics.drawq(textures.tiles, q.t[t[base + 0]], math.ceil(-tw/2), -r, 0, 2, 2)
            end
            if t[base+1] then
                love.graphics.drawq(textures.tiles, q.t[t[base + 1]], 0, -r, 0, 2, 2)
            end
            if t[base+2] then
                love.graphics.drawq(textures.tiles, q.b[t[base + 2]], math.ceil(-tw/2), -r+th/2, 0, 2, 2)
            end
            if t[base+3] then
                love.graphics.drawq(textures.tiles, q.b[t[base + 3]], 0, -r+th/2, 0, 2, 2)
            end

            love.graphics.rotate(angleStep)
        end
        love.graphics.pop()
    end

    for level = 0,levels do
        drawtiles(level)
    end
end

local function renderStarfield()
    for i = 1, #starField do
        local s = starField[i]
        love.graphics.drawq(textures.stars, quads.stars[s.t], s.x, s.y, s.r, .5, .5)
    end
end

local function renderDebug()
    local s = string.format("alt=%d, angle=%.4f, x=%.1f", playerAlt, playerAngle, (playerAngle*playerAlt))
    love.graphics.print(s, 100, 0)
    local hs = calculateHeights(playerAngle)
    love.graphics.print(table.concat(hs, ", "), 500, 0)

    local function drawHeights(angle)
        local hs = calculateHeights(angle)
        for i = 1, #hs, 2 do
            love.graphics.line(0, -hs[i], 0, -hs[i+1])
        end
    end

    local r,g,b,a
    r,g,b,a = love.graphics.getColor()
    love.graphics.setColor(0,255,255)

    local arc = (pw-8) / playerAlt
    love.graphics.push()
    love.graphics.translate(centerX, centerY)
    love.graphics.rotate(arc/2)
    drawHeights(playerAngle - arc/2)
    love.graphics.rotate(-arc)
    drawHeights(playerAngle + arc/2)
    love.graphics.pop()

    love.graphics.setColor(r,g,b,a)
end

function game.render()
    love.graphics.push()
    love.graphics.translate(centerX, centerY)
    love.graphics.rotate(playerAngle)
        renderStarfield()
        renderPlanet()
    love.graphics.pop()

    renderPlayer()
    -- renderDebug()
end


return game

