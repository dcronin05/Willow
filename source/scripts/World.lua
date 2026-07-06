---@class World
--- The World class handles decoding the level data from the LDtk JSON map,
--- constructing the visual tilemaps, generating collision bounds for the physics engine,
--- and spawning all entities (Player, Signs, Items) into the Playdate environment.

local pd = playdate
local gfx = pd.graphics

class('World').extends()

--- Initializes a new room by parsing the LDtk JSON and building the Playdate graphics/physics objects.
---@param levelName string The exact identifier of the level defined in LDtk (e.g. "Room_1")
function World:init(levelName)
    -- ==========================================
    -- 1. JSON PARSING
    -- ==========================================
    -- Natively parse the entire LDtk JSON file into a Lua table using Playdate's built in decoder.
    local ldtkData = json.decodeFile("levels/world.ldtk")
    local levelData = nil
    
    -- Iterate through the array of levels in the JSON to find the one matching our levelName.
    for _, level in ipairs(ldtkData.levels) do
        if level.identifier == levelName then
            levelData = level
            -- Expose the width and height of the room so that the camera script in main.lua can clamp itself.
            self.width = level.pxWid
            self.height = level.pxHei
            break
        end
    end
    
    -- If the requested level name isn't found in the JSON, abort safely to prevent a crash.
    if not levelData then print("Error: Level not found") return end
    
    -- ==========================================
    -- 2. TILEMAP INITIALIZATION
    -- ==========================================
    -- Create a new empty tilemap object which will hold all the 16x16 visual map tiles.
    local tilemap = gfx.tilemap.new()
    -- Load the sprite sheet containing our tile graphics (wall, floor, empty space).
    local imageTable = gfx.imagetable.new("images/tileset")
    
    -- Attach the sprite sheet to the tilemap and specify its size in GRID units (not pixels).
    -- Calculate grid dimensions based on the level's pixel size divided by the 16x16 tile size.
    local gridWidth = self.width / 16
    local gridHeight = self.height / 16
    tilemap:setImageTable(imageTable)
    tilemap:setSize(gridWidth, gridHeight)

    -- ==========================================
    -- 3. LAYER PROCESSING
    -- ==========================================
    -- LDtk organizes maps into layers (e.g. Collisions, Background, Entities).
    -- We loop through the instances of these layers to parse their specific data.
    for _, layer in ipairs(levelData.layerInstances) do
        
        -- ------------------------------------------
        -- LAYER: COLLISIONS (IntGrid)
        -- ------------------------------------------
        if layer.__identifier == "Collisions" then
            -- IntGrid layers contain a 1D CSV array of integer values representing the tiles (e.g. 0=Empty, 1=Wall).
            local grid = layer.intGridCsv
            
            -- We iterate through every value in the 1D LDtk CSV and populate our 2D Playdate tilemap.
            for i = 1, #grid do
                -- Convert the 1D index `i` into 2D X and Y coordinates using the dynamic gridWidth.
                -- Note: Lua arrays are 1-indexed, so we subtract 1 before doing the modulo/division math.
                local x = ((i - 1) % gridWidth) + 1
                local y = math.floor((i - 1) / gridWidth) + 1
                
                -- In LDtk: IntGrid value `0` means empty space. `1` means Grass. `2` means Dirt.
                -- In our Playdate tileset.png: Tile 1 is Grass, Tile 2 is Dirt, Tile 3 is Air.
                local tileID = 3 -- Default to Air
                if grid[i] == 1 then tileID = 1 end
                if grid[i] == 2 then tileID = 2 end
                
                -- Place the correct tile graphic onto the tilemap at this grid coordinate.
                tilemap:setTileAtPosition(x, y, tileID)
            end
            
            -- In Playdate, tilemaps must be attached to a Sprite in order to be drawn to the screen automatically.
            local tilemapSprite = gfx.sprite.new()
            tilemapSprite:setTilemap(tilemap)
            
            -- Ensure the tilemap sprite's top-left corner perfectly aligns with the screen's top-left (0, 0).
            tilemapSprite:moveTo(0, 0)
            tilemapSprite:setCenter(0, 0)
            
            -- Draw the background layer behind everything else so entities render on top of it.
            tilemapSprite:setZIndex(-1)
            tilemapSprite:add()
            
            -- Finally, generate solid physics bounding boxes!
            -- We tell Playdate to generate solid walls for EVERY tile in the tilemap, EXCEPT for the tile IDs listed in the table.
            -- Since Tile 3 is "transparent air", we pass `{3}` to tell Playdate it has no collision.
            gfx.sprite.addWallSprites(tilemap, {3})
            
        -- ------------------------------------------
        -- LAYER: ENTITIES (Player, Signs)
        -- ------------------------------------------
        elseif layer.__identifier == "Entities" then
            -- Loop over every entity placed into this room via the LDtk editor.
            for _, entity in ipairs(layer.entityInstances) do
                -- Grab the raw pixel coordinates defining where the entity was placed.
                local pxX = entity.px[1]
                local pxY = entity.px[2]
                
                -- Check the string identifier of the entity to figure out which Lua class to instantiate.
                if entity.__identifier == "Player" then
                    local ldtkX, ldtkY = pxX, pxY
                    -- If we have saved coordinates, override the LDtk spawn point
                    if SaveManager.hasSavedPlayerPosition() then
                        pxX, pxY = SaveManager.getSavedPlayerPosition()
                        
                        -- Clamp the saved coordinates to the current level boundaries 
                        -- in case the map was shrunk in LDtk since the last save!
                        pxX = math.max(16, math.min(self.width - 16, pxX))
                        pxY = math.max(16, math.min(self.height - 16, pxY))
                    end
                    
                    -- Spawn the player and assign it to a global variable so the camera and UI can reference it.
                    -- We pass the LDtk coordinates so the player can use them for respawning!
                    _G.player = Player(pxX, pxY, ldtkX, ldtkY)
                    
                    -- Restore player health if it was saved
                    if SaveManager.state.player.health then
                        _G.player.health = SaveManager.state.player.health
                    end
                    
                elseif entity.__identifier == "Sign" then
                    -- Signs can have custom text attached to them in LDtk using "Custom Fields".
                    local text = "..."
                    -- Search the entity's fieldInstances for the field named "text".
                    for _, field in ipairs(entity.fieldInstances) do
                        if field.__identifier == "text" then
                            text = field.__value
                        end
                    end
                    -- Instantiate the sign! 
                    -- Note: LDtk gives us the top-left coordinates (pxX, pxY), but our Sign Lua class anchors to the bottom-center.
                    -- So we shift the spawn point by +8 (half width) and +16 (full height) to perfectly align it with LDtk's grid.
                    Sign(pxX + 8, pxY + 16, text)
                    
                elseif entity.__identifier == "Enemy" then
                    -- Only spawn the enemy if they aren't dead!
                    if not SaveManager.isEntityKilled(entity.iid) then
                        import "scripts/Enemy"
                        
                        -- If the enemy has a saved state (e.g. they were moved or damaged), override the LDtk values
                        local savedHealth = nil
                        if SaveManager.state.world.entities[entity.iid] then
                            local state = SaveManager.state.world.entities[entity.iid]
                            pxX = state.x
                            pxY = state.y
                            savedHealth = state.health
                        end
                        
                        Enemy(pxX, pxY, entity.iid, savedHealth)
                    end
                end
            end
        end
    end
end
