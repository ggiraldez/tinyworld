local map = {}

-- sample map
local mapgen = {}
mapgen[0] = " __ _  ____ _____ _  ____  ___ __ __  ___"
mapgen[1] = "J.C DNN.CZZ ZD...U.[]....LJ...U..LZZJL7.F"
mapgen[2] = "...U.UN....N....CZZ__D......O....A.C7.L^J"
mapgen[3] = "ZZZZZZJ...C_D...................C_ZZ_ZZ_Z"

-- tile connections (map values)
local mapvalues = {}
mapvalues['.'] = { c=false, u=false, d=false, l=false, r=false }   -- solid
mapvalues[' '] = { c=true,  u=true,  d=true,  l=true,  r=true  }   -- empty
mapvalues['O'] = { c=true,  u=false, d=false, l=false, r=false }   -- hole

mapvalues['_'] = { c=true,  u=true,  d=false, l=true,  r=true  }   -- floor only
mapvalues['^'] = { c=true,  u=false, d=true,  l=true,  r=true  }   -- roof only
mapvalues['['] = { c=true,  u=true,  d=true,  l=false, r=true  }   -- left only
mapvalues[']'] = { c=true,  u=true,  d=true,  l=true,  r=false }   -- right only

mapvalues['Z'] = { c=true,  u=false, d=false, l=true,  r=true  }   -- horizontal tunnel
mapvalues['N'] = { c=true,  u=true,  d=true,  l=false, r=false }   -- vertical tunnel

mapvalues['L'] = { c=true,  u=true,  d=false, l=false, r=true  }
mapvalues['J'] = { c=true,  u=true,  d=false, l=true,  r=false }
mapvalues['7'] = { c=true,  u=false, d=true,  l=true,  r=false }
mapvalues['F'] = { c=true,  u=false, d=true,  l=false, r=true  }

mapvalues['C'] = { c=true,  u=false, d=false, l=false, r=true  }
mapvalues['D'] = { c=true,  u=false, d=false, l=true,  r=false }
mapvalues['U'] = { c=true,  u=true,  d=false, l=false, r=false }
mapvalues['A'] = { c=true,  u=false, d=true,  l=false, r=false }

-- the map dimensions and data
-- Levels:
-- 0: surface
-- 1: outer cortex
-- 2: mid cortex
-- 3: inner cortex
local levels = 3
local tilesPerLevel = 41
local data = {}


function map.init()
    -- build map from strings
    for level = 0, levels do
        data[level] = {}
        if string.len(mapgen[level]) ~= tilesPerLevel then
            print("invalid map literal for level "..level)
        end
        for i = 0, tilesPerLevel - 1 do
            local c = string.sub(mapgen[level], i+1, i+1)
            local v = mapvalues[c]
            if v == nil then
                print("invalid map character, level "..level..", index "..i)
                v = mapvalues[' ']
            end
            data[level][i] = v
        end
    end
end

function map.validate()
    -- validate map
    local mapValid = true
    for level = 0, levels do
        local dl = data[level]
        for i = 0, tilesPerLevel - 1 do
            local v = dl[i]
            local valid = true

            if level == 0 then
                if not v.u then valid = false end
            else
                if v.u ~= data[level-1][i].d then valid = false end
                if level == levels then
                    if v.d then valid = false end
                end
            end

            if i == 0 then
                if v.l ~= dl[tilesPerLevel-1].r then valid = false end
            else
                if v.l ~= dl[i-1].r then valid = false end
            end

            if not valid then
                print("invalid map connections at level "..level.." index "..i)
                mapValid = false
            end
        end
    end
    if mapValid then
        print("Map validated.")
    end
    return mapValid
end

function map.calculateDimensions()
    local dimensions = {}

    -- base dimensions (outer cortex tiles are 64x64)
    -- r1: outer cortex outer radius is the planet radius
    -- c1: tile count at the outer cortex
    local th = 64
    local tw = 64
    local c1 = tilesPerLevel
    local r1 = (c1*tw) / (2*math.pi)

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

    return dimensions
end

-- generateTiles builds the tiles arrays, ie. the quad indices for each level
-- and the given map data. For each map tile 4 tiles are generated, one for
-- each corner of the map tile. So if the map tile is 64x64, each subtile is
-- 32x32 and so on. Tiles level array has 4 times the number of map tiles
-- because of this.
function map.generateTiles()
    local tiles = {}

    for level = 0, levels do
        tiles[level] = {}
        for i = 0, tilesPerLevel - 1 do
            local base = 4 * i
            local tl, tr, bl, br
            local m = data[level][i]

            if not m.c then
                tl = 8
                tr = 9
                bl = 8
                br = 9
            else
                if m.u then
                    if m.l then tl = 7 else tl = 3 end
                    if m.r then tr = 0 else tr = 4 end
                else
                    if m.l then tl = 6 else tl = 5 end
                    if m.r then tr = 1 else tr = 2 end
                end
                if m.d then
                    if m.l then bl = 7 else bl = 3 end
                    if m.r then br = 0 else br = 4 end
                else
                    if m.l then bl = 1 else bl = 5 end
                    if m.r then br = 6 else br = 2 end
                end
            end

            tiles[level][base + 0] = tl
            tiles[level][base + 1] = tr
            tiles[level][base + 2] = bl
            tiles[level][base + 3] = br
        end
    end

    return tiles
end

function map.generateLandscape()
    local tiles = {}

    for i = 0, tilesPerLevel - 1 do
        tiles[i] = math.random(0, 1)
    end

    local hills = { {2,3}, {4,5}, {6}, {7} }
    for j = 1, 8 do
        local h = hills[math.random(#hills)]
        local i
        repeat
            i = math.random(0, tilesPerLevel - 1)
            local valid = true
            for k = 1, #h do
                if tiles[(i+k-1) % (tilesPerLevel-1)] > 1 then
                    valid = false
                    break
                end
            end
        until valid

        for k = 1, #h do
            tiles[(i+k-1) % (tilesPerLevel-1)] = h[k]
        end
    end

    return tiles
end



-- export other variables
map.data = data
map.levels = levels
map.tilesPerLevel = tilesPerLevel

return map
