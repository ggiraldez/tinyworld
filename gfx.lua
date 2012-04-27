local gfx = {}

local textures = {}
local quads = {}


local function loadTextures()
    local w, h

    -- load tiles
    textures.tiles = love.graphics.newImage('images/tiles.png')
    textures.tiles:setFilter('linear', 'nearest')
    w = textures.tiles:getWidth()
    h = textures.tiles:getHeight()

    -- quads for the tiles
    quads[1] = {}
    quads[1][0] = love.graphics.newQuad(0,  0, 32, 32,   w, h)
    quads[1][1] = love.graphics.newQuad(32, 0, 32, 32,   w, h)
    quads[1][2] = love.graphics.newQuad(64, 0, 32, 32,   w, h)
    quads[1][3] = love.graphics.newQuad(96, 0, 32, 32,   w, h)

    quads[2] = {}
    quads[2][0] = love.graphics.newQuad(0,  64, 27, 32,  w, h)
    quads[2][1] = love.graphics.newQuad(27, 64, 27, 32,  w, h)
    quads[2][2] = love.graphics.newQuad(54, 64, 27, 32,  w, h)

    quads[3] = {}
    quads[3][0] = love.graphics.newQuad(0,  128, 22, 32, w, h)
    quads[3][1] = love.graphics.newQuad(22, 128, 22, 32, w, h)
    quads[3][2] = love.graphics.newQuad(44, 128, 22, 32, w, h)

    -- stars
    textures.stars = love.graphics.newImage('images/stars.png')
    w = textures.stars:getWidth()
    h = textures.stars:getHeight()

    -- stars' quads
    quads.stars = {}
    quads.stars[0] = love.graphics.newQuad(0,  0, 16, 16, w, h)
    quads.stars[1] = love.graphics.newQuad(16, 0, 16, 16, w, h)
    quads.stars[2] = love.graphics.newQuad(32, 0, 16, 16, w, h)
    quads.stars[3] = love.graphics.newQuad(48, 0, 16, 16, w, h)

    -- planet core
    textures.core = love.graphics.newImage('images/core.png')
    textures.core:setFilter('linear', 'nearest')

    -- player texture
    textures.player = love.graphics.newImage('images/player.png')
    textures.player:setFilter('linear', 'nearest')
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
end

gfx.textures = textures
gfx.quads = quads

return gfx

