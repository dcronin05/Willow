local pd = playdate
local gfx = pd.graphics

class('World').extends()

function World:init(levelName)
    -- Tell the LDtk library to load this specific room into memory
    LDtk.load_level(levelName)
    
    -- 1. BUILD THE TILEMAPS & COLLISIONS
    for layer_name, layer in pairs(LDtk.get_layers(levelName)) do
        if layer.tiles then
            local tilemap = LDtk.create_tilemap(levelName, layer_name)
            
            local layerSprite = gfx.sprite.new()
            layerSprite:setTilemap(tilemap)
            layerSprite:moveTo(0, 0)
            layerSprite:setCenter(0, 0)
            layerSprite:setZIndex(layer.zIndex)
            layerSprite:add()
            
            -- We assume any tile with the ID '1' is a solid wall
            -- Playdate requires us to provide the IDs of the EMPTY tiles (everything else)
            local emptyIDs = {}
            for i=0, 255 do
                if i ~= 1 then
                    table.insert(emptyIDs, i)
                end
            end
            
            -- Generate the physics colliders for all the '1' tiles!
            gfx.sprite.addWallSprites(tilemap, emptyIDs)
        end
    end
    
    -- 2. SPAWN THE ENTITIES
    for index, entity in ipairs(LDtk.get_entities(levelName)) do
        if entity.name == "Player" then
            _G.player = Player(entity.position.x, entity.position.y)
        elseif entity.name == "Sign" then
            local text = entity.fields.text or "..."
            -- LDtk anchors are typically (0, 0) top-left, but we set our Sign to anchor (0.5, 1) bottom-center
            -- LDtk outputs entity.position based on the entity's pivot in the editor.
            -- In our generated LDtk, pivot is [0, 0] so it's the top-left.
            -- We need to pass x + width/2, y + height to match our Sign's anchor
            Sign(entity.position.x + 8, entity.position.y + 16, text)
        end
    end
end
