local pd = playdate
local gfx = pd.graphics

class('MapUI').extends(gfx.sprite)

--- Initializes the Map UI, freezing the game and generating the map graphic.
function MapUI:init()
    MapUI.super.init(self)
    
    self.isFullScreen = true
    
    -- We want to draw this above everything!
    self:setZIndex(9999)
    -- Ignore the camera offset, draw directly to the screen UI layer
    self:setIgnoresDrawOffset(true)
    
    -- Map rendering properties
    self.cameraX = 0
    self.cameraY = 0
    self.panSpeed = 15
    self.zoom = MapUI.lastZoom or 1.0
    
    -- Generate the actual map image!
    self:generateMapImage()
    
    -- Center the camera on the player immediately, accounting for the current zoom level!
    if _G.player then
        -- The map is drawn at a 4:1 scale (each 16x16 tile is a 4x4 block)
        local scale = 4 / 16
        self.cameraX = (_G.player.x * scale * self.zoom) - (400 / 2)
        self.cameraY = (_G.player.y * scale * self.zoom) - (240 / 2)
    end
    
    self:clampCamera()
    
    -- Add this sprite to the active render loop!
    self:add()
end

--- Generates a massive off-screen image representing the entire world map.
function MapUI:generateMapImage()
    -- Instead of reading the JSON again, we could read the already-loaded LDtk JSON if we cached it.
    -- For simplicity, let's just parse the JSON for the current room to build the map image!
    local ldtkData = json.decodeFile("levels/world.ldtk")
    local levelData = nil
    
    for _, level in ipairs(ldtkData.levels) do
        if level.identifier == "Level_0" then
            levelData = level
            break
        end
    end
    
    if not levelData then return end
    
    local gridWidth = levelData.pxWid / 16
    local gridHeight = levelData.pxHei / 16
    
    -- We will draw each 16x16 tile as a 4x4 pixel square on the map!
    local scale = 4
    
    -- Create the massive off-screen image
    self.mapImage = gfx.image.new(gridWidth * scale, gridHeight * scale)
    
    -- Push context so all drawing commands target this off-screen image instead of the screen!
    gfx.pushContext(self.mapImage)
        
        -- Fill with a background color
        gfx.setColor(gfx.kColorWhite)
        gfx.fillRect(0, 0, gridWidth * scale, gridHeight * scale)
        
        for _, layer in ipairs(levelData.layerInstances) do
            if layer.__identifier == "Collisions" then
                local grid = layer.intGridCsv
                for i = 1, #grid do
                    local x = ((i - 1) % gridWidth)
                    local y = math.floor((i - 1) / gridWidth)
                    
                    local val = grid[i]
                    if val == 1 then
                        -- Grass
                        gfx.setColor(gfx.kColorBlack)
                        -- Draw a light dither pattern for grass
                        gfx.setPattern({ 0xAA, 0x55, 0xAA, 0x55, 0xAA, 0x55, 0xAA, 0x55 })
                        gfx.fillRect(x * scale, y * scale, scale, scale)
                    elseif val == 2 then
                        -- Dirt
                        gfx.setColor(gfx.kColorBlack)
                        -- Solid block for dirt/mountains
                        gfx.fillRect(x * scale, y * scale, scale, scale)
                    end
                end
            end
        end
        
        -- Draw a border around the map bounds
        gfx.setColor(gfx.kColorBlack)
        gfx.drawRect(0, 0, gridWidth * scale, gridHeight * scale)
        
    gfx.popContext()
    
    -- We set the size of our sprite to the whole screen so Playdate's redraw system doesn't clip it
    self:setSize(400, 240)
    self:setCenter(0, 0)
    self:moveTo(0, 0)
end

--- Restricts the camera from scrolling infinitely into the void, and auto-centers the map if it's smaller than the screen.
function MapUI:clampCamera()
    if not self.mapImage then return end
    
    local w, h = self.mapImage:getSize()
    local scaledW = w * self.zoom
    local scaledH = h * self.zoom
    
    if scaledW <= 400 then
        self.cameraX = -(400 - scaledW) / 2
    else
        self.cameraX = math.max(0, math.min(self.cameraX, scaledW - 400))
    end
    
    if scaledH <= 240 then
        self.cameraY = -(240 - scaledH) / 2
    else
        self.cameraY = math.max(0, math.min(self.cameraY, scaledH - 240))
    end
end

--- The main update loop for the Map. Overrides the sprite update.
function MapUI:update()
    
    -- 1. ZOOMING INPUT (Using the Crank!)
    local crankChange = pd.getCrankChange()
    local oldZoom = self.zoom
    if crankChange ~= 0 then
        self.zoom = math.max(0.5, math.min(self.zoom + (crankChange / 100), 4.0))
        MapUI.lastZoom = self.zoom
    end
    
    -- Optional button alternative for zooming if crank isn't used
    if pd.buttonJustPressed(pd.kButtonA) then
        if self.zoom < 3.0 then
            self.zoom = self.zoom + 1.0
        else
            self.zoom = 1.0
        end
        MapUI.lastZoom = self.zoom
    end
    
    -- If zoom changed, shift the camera so we zoom in/out from the CENTER of the screen
    if oldZoom ~= self.zoom then
        local cx, cy = 200, 120
        -- Find what point on the map is currently at the center of the screen
        local mapX = (cx + self.cameraX) / oldZoom
        local mapY = (cy + self.cameraY) / oldZoom
        
        -- Adjust camera so that same map point remains at the center of the screen
        self.cameraX = (mapX * self.zoom) - cx
        self.cameraY = (mapY * self.zoom) - cy
    end
    
    -- 2. PANNING INPUT (D-Pad)
    if pd.buttonIsPressed(pd.kButtonLeft) then
        self.cameraX = self.cameraX - (self.panSpeed / self.zoom)
    elseif pd.buttonIsPressed(pd.kButtonRight) then
        self.cameraX = self.cameraX + (self.panSpeed / self.zoom)
    end
    
    if pd.buttonIsPressed(pd.kButtonUp) then
        self.cameraY = self.cameraY - (self.panSpeed / self.zoom)
    elseif pd.buttonIsPressed(pd.kButtonDown) then
        self.cameraY = self.cameraY + (self.panSpeed / self.zoom)
    end
    
    -- Clamp the camera every frame to ensure we never escape bounds
    self:clampCamera()
    
    -- We must redraw every frame so the player location marker can blink!
    self:markDirty()
    
    -- 3. EXIT INPUT
    if pd.buttonJustPressed(pd.kButtonB) then
        UIManager.clearUI()
        return
    end
end

--- Override the default sprite draw function.
function MapUI:draw(x, y, width, height)
    -- Draw a white background covering the whole screen
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRect(0, 0, 400, 240)
    
    if not self.mapImage then return end
    
    -- Draw the pre-rendered map image, offset by the camera position and scaled!
    self.mapImage:drawScaled(-self.cameraX, -self.cameraY, self.zoom)
    
    -- Draw the player "You are here" marker
    if _G.player then
        -- 4 is the base scale we drew the image at (4x4 pixels per tile)
        local baseScale = 4 / 16
        local px = (_G.player.x * baseScale * self.zoom) - self.cameraX
        local py = (_G.player.y * baseScale * self.zoom) - self.cameraY
        
        -- Make it blink!
        if pd.getCurrentTimeMilliseconds() % 1000 < 500 then
            gfx.setColor(gfx.kColorBlack)
            -- Draw an X or a little crosshair
            gfx.drawLine(px - 3, py - 3, px + 3, py + 3)
            gfx.drawLine(px - 3, py + 3, px + 3, py - 3)
            gfx.drawRect(px - 4, py - 4, 8, 8)
        end
    end
    
    -- Draw UI Overlays (Title, Instructions) AT THE BOTTOM
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRect(0, 220, 400, 20)
    gfx.setColor(gfx.kColorBlack)
    gfx.drawRect(0, 220, 400, 20)
    gfx.drawText("*WORLD MAP*", 10, 222)
    gfx.drawText("Crank/A: Zoom", 140, 222)
    gfx.drawText("Press B to exit", 270, 222)
end
