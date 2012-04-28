local gfx = {}

local textures = {}
local quads = {}


local function loadTextures()
    local w, h

    -- load tiles
    textures.tiles = love.graphics.newImage('images/tiles.png')
    textures.tiles:setFilter('linear', 'nearest')

    -- stars
    textures.stars = love.graphics.newImage('images/stars.png')

    -- planet core
    textures.core = love.graphics.newImage('images/core.png')
    textures.core:setFilter('linear', 'nearest')

    -- player texture
    textures.player = love.graphics.newImage('images/player.png')
    textures.player:setFilter('linear', 'nearest')
end

local function createQuads()
    local w, h

    -- load tiles
    w = textures.tiles:getWidth()
    h = textures.tiles:getHeight()

    -- quads for the tiles
    local widths =  { 38, 32, 28, 24 }
    local heights = { 32, 32, 32, 32 }
    local y = 0
    for level = 0, 3 do
        local tw = widths[level+1]
        local th = heights[level+1]
        quads[level] = { t={}, b={} }
        for i = 0, 9 do
            quads[level].t[i] = love.graphics.newQuad(i * tw/2, y,        tw/2, th/2, w, h)
            quads[level].b[i] = love.graphics.newQuad(i * tw/2, y + th/2, tw/2, th/2, w, h)
        end
        y = y + th
    end

    -- stars
    w = textures.stars:getWidth()
    h = textures.stars:getHeight()

    -- stars' quads
    quads.stars = {}
    quads.stars[0] = love.graphics.newQuad(0,  0, 16, 16, w, h)
    quads.stars[1] = love.graphics.newQuad(16, 0, 16, 16, w, h)
    quads.stars[2] = love.graphics.newQuad(32, 0, 16, 16, w, h)
    quads.stars[3] = love.graphics.newQuad(48, 0, 16, 16, w, h)

    -- player texture
    w = textures.player:getWidth()
    h = textures.player:getHeight()

    quads.player = {}
    quads.player[0] = love.graphics.newQuad(0,  0,  16, 16, w, h)
    quads.player[1] = love.graphics.newQuad(16, 0,  16, 16, w, h)
    quads.player[2] = love.graphics.newQuad(32, 0,  16, 16, w, h)
    quads.player[3] = love.graphics.newQuad(48, 0,  16, 16, w, h)
    quads.player[4] = love.graphics.newQuad(64, 0,  16, 16, w, h)
    quads.player[5] = love.graphics.newQuad(0,  16, 16, 16, w, h)
    quads.player[6] = love.graphics.newQuad(16, 16, 16, 16, w, h)
    quads.player[7] = love.graphics.newQuad(32, 16, 16, 16, w, h)
    quads.player[8] = love.graphics.newQuad(48, 16, 16, 16, w, h)
    quads.player[9] = love.graphics.newQuad(64, 16, 16, 16, w, h)
    quads.player.falling = love.graphics.newQuad(0,  32, 16, 16, w, h)
    quads.player.jumping = love.graphics.newQuad(16, 32, 16, 16, w, h)
end

function gfx.init()
    loadTextures()
    createQuads()
end

function gfx.reload()
    loadTextures()
end

gfx.textures = textures
gfx.quads = quads

return gfx

