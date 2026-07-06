local pd = playdate
local gfx = pd.graphics

class('World').extends()

function World:init(levelName)
    -- Natively parse the LDtk JSON file!
    local ldtkData = json.decodeFile("levels/world.ldtk")
    local levelData = nil
    
    -- Find our specific room
    for _, level in ipairs(ldtkData.levels) do
        if level.identifier == levelName then
            levelData = level
            break
        end
    end
    
    if not levelData then print("Error: Level not found") return end
    
    local tilemap = gfx.tilemap.new()
    local imageTable = gfx.imagetable.new("images/tileset")
    tilemap:setImageTable(imageTable)
    tilemap:setSize(25, 15)

    -- Extract layers
    for _, layer in ipairs(levelData.layerInstances) do
        
        -- 1. BUILD COLLISIONS FROM INTGRID
        if layer.__identifier == "Collisions" then
            local grid = layer.intGridCsv
            
            -- LDtk IntGrid values map 1-to-1 with our array!
            -- We iterate through the LDtk CSV and populate our Playdate tilemap
            for i = 1, #grid do
                -- Playdate is 1-indexed, LDtk 1D arrays are 0-indexed math
                -- Wait, lua loops are 1-indexed. We calculate x,y:
                local x = ((i - 1) % 25) + 1
                local y = math.floor((i - 1) / 25) + 1
                
                -- LDtk IntGrid value 0 means empty. Value 1 means Wall.
                -- In our tileset.png, Tile 1 is the Wall, Tile 2 is Air.
                local tileID = grid[i] == 1 and 1 or 2
                tilemap:setTileAtPosition(x, y, tileID)
            end
            
            local tilemapSprite = gfx.sprite.new()
            tilemapSprite:setTilemap(tilemap)
            tilemapSprite:moveTo(0, 0)
            tilemapSprite:setCenter(0, 0)
            tilemapSprite:setZIndex(-1)
            tilemapSprite:add()
            
            -- Solid wall collisions: Tell Playdate that tile ID 2 is empty!
            gfx.sprite.addWallSprites(tilemap, {2})
            
        -- 2. SPAWN ENTITIES
        elseif layer.__identifier == "Entities" then
            for _, entity in ipairs(layer.entityInstances) do
                local pxX = entity.px[1]
                local pxY = entity.px[2]
                
                if entity.__identifier == "Player" then
                    _G.player = Player(pxX, pxY)
                    
                elseif entity.__identifier == "Sign" then
                    local text = "..."
                    for _, field in ipairs(entity.fieldInstances) do
                        if field.__identifier == "text" then
                            text = field.__value
                        end
                    end
                    -- Adjust for sign anchoring
                    Sign(pxX + 8, pxY + 16, text)
                end
            end
        end
    end
end
