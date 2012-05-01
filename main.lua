local game = require('game')
local input = require('input')
local ticsPerSec = 60
local showFPS = true

function love.load()
    math.randomseed(os.time())
    game.init()
end

do
    local lastTicTime = 0
    local currentTime = 0
    local lastReport = 0
    local reportInterval = 1
    local tics = 0

    function love.update(dt)
        currentTime = currentTime + dt
        while currentTime - lastTicTime > 1/ticsPerSec do
            game.tic()
            tics = tics + 1
            lastTicTime = lastTicTime + 1/ticsPerSec
        end
        if currentTime - lastReport > reportInterval then
            if showFPS then
                -- print(tics .. " tics, " .. love.timer.getFPS() .. " fps")
            end
            lastReport = currentTime
            tics = 0
        end
    end
end

function love.keypressed(key, unicode)
    if key == "escape" then
        love.event.push("quit")
    elseif key == "numlock" then
        debug.debug()
        love.timer.step()
    elseif key == "f11" then
        love.graphics.toggleFullscreen()
    elseif key == "f5" then
        game.reloadGfx()
    elseif key == "f2" then
        game.toggleDebug()
    elseif key == "f3" then
        game.restart()
    else
        input.keypressed(key, unicode)
    end
end

function love.draw()
    love.graphics.push()
    game.render()
    love.graphics.pop()

    if showFPS then
        love.graphics.print(love.timer.getFPS() .. " fps", 0, 0)
    end
end

