local map = {}

-- sample map
local mapgen = {}
mapgen[0] = "___ _______ _____ _  ____  ___ __ __ ____"
mapgen[1] = "..C D...CZZ ZD...U.[]....LJ...U..LZZJ...."
mapgen[2] = "...U.......N....CZZ__D......O....A......."
mapgen[3] = "..........C_D...................C_ZD....."

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


-- export other variables
map.data = data
map.levels = levels
map.tilesPerLevel = tilesPerLevel

return map

