local gfx = playdate.graphics

class('World').extends()

function World:init()
    -- 1. Create the tilemap object
    local tilemap = gfx.tilemap.new()
    
    -- 2. Load the image table we generated
    -- Notice we don't include the "-table-16-16" suffix or the ".png" extension. The engine figures it out!
    local imageTable = gfx.imagetable.new("images/tileset")
    tilemap:setImageTable(imageTable)
    
    -- 3. Define the width (columns) and height (rows) of our level
    local levelWidth = 30
    local levelHeight = 15
    
    -- 4. We define our map as a flat 1D array of tile IDs.
    -- 0 = Empty/Transparent
    -- 1 = Solid Ground (our black square with a white outline)
    -- 2 = Air (our white square with a few texture dots)
    local levelData = {
        2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,
        2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,
        2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,
        2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,
        2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,
        2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,
        2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,
        2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,
        2,2,2,2,2,2,2,2,2,2,1,1,1,1,1,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,
        2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,
        2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,
        1,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,1,1,2,2,2,2,2,2,2,1,
        1,1,1,1,1,1,1,2,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,2,1,1,1,1,1,
        1,1,1,1,1,1,1,2,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,2,1,1,1,1,1,
        1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
    }
    
    -- Load the array into the tilemap
    tilemap:setTiles(levelData, levelWidth)
    
    -- 5. Create a Sprite to actually draw the tilemap onto the screen
    local tilemapSprite = gfx.sprite.new()
    tilemapSprite:setTilemap(tilemap)
    tilemapSprite:moveTo(0, 0)
    tilemapSprite:setCenter(0, 0) -- Important: draw from top-left, not center!
    tilemapSprite:setZIndex(-1) -- Draw it behind the player
    tilemapSprite:add()
    
    -- 6. Add solid wall collisions magically!
    -- This tells the engine: "Look at the tilemap. Every time you see Tile ID 1, put a physical collision box there!"
    local emptyIDs = {1}
    gfx.sprite.addWallSprites(tilemap, emptyIDs)
end
