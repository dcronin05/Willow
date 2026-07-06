---@class MessageBox
--- The MessageBox class is a custom UI component that renders a stylized, 
--- rounded rectangle box with wrapped text at the bottom of the screen.
--- It is typically used for displaying dialogue or sign text, and automatically
--- takes over the screen until dismissed by the user or by walking away.

local pd = playdate
local gfx = pd.graphics

-- Define the class and inherit from playdate.graphics.sprite so it can be added to the display list.
class('MessageBox').extends(gfx.sprite)

--- Initializes a new MessageBox popup.
---@param text string The string of text to render inside the box.
---@param sourceInteractable sprite (Optional) The interactable object (like a Sign) that triggered this popup.
function MessageBox:init(text, sourceInteractable)
    -- Initialize the base sprite class
    MessageBox.super.init(self)
    
    -- Save the string so we can draw it later
    self.text = text
    -- Keep a reference to the physical object that spawned this dialog.
    -- We use this reference in update() to auto-close the box if the player walks away.
    self.sourceInteractable = sourceInteractable
    
    -- ==========================================
    -- DYNAMIC IMAGE GENERATION
    -- ==========================================
    -- Instead of loading a static PNG for the UI box, we draw it dynamically!
    local boxWidth = 360
    local boxHeight = 60
    local image = gfx.image.new(boxWidth, boxHeight)
    
    -- pushContext redirects all graphics drawing commands to draw onto our custom `image` 
    -- instead of directly onto the screen.
    gfx.pushContext(image)
        -- 1. Draw a solid black rounded rectangle for the background
        gfx.setColor(gfx.kColorBlack)
        gfx.fillRoundRect(0, 0, boxWidth, boxHeight, 4)
        
        -- 2. Draw a thick white outline slightly inset from the edge
        gfx.setColor(gfx.kColorWhite)
        gfx.setLineWidth(2)
        gfx.drawRoundRect(2, 2, boxWidth-4, boxHeight-4, 4)
        
        -- 3. Draw the actual text using a white fill mode so the text is visible against the black background
        gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
        -- drawTextInRect automatically handles word-wrapping to fit inside the given bounding box!
        gfx.drawTextInRect(self.text, 10, 10, boxWidth-20, boxHeight-20)
    gfx.popContext()
    
    -- Apply our dynamically generated image to the sprite
    self:setImage(image)
    
    -- Anchor it to the bottom-center so we can easily position it at the bottom of the screen
    self:setCenter(0.5, 1)
    self:moveTo(200, 230) -- Center X (200), Bottom Y with a 10px margin (230)
    
    -- CRITICAL: We tell the sprite to ignore camera draw offsets!
    -- This ensures the UI box is permanently stuck to the camera screen, rather than scrolling away with the level.
    self:setIgnoresDrawOffset(true)
    
    -- Assign a massive Z-Index so this UI component is guaranteed to render on top of all players and level tiles.
    self:setZIndex(1000)
    
    -- Add the sprite to the rendering loop
    self:add()
end

--- Called automatically every frame while the MessageBox is active on screen.
function MessageBox:update()
    -- Manual dismiss: If the user presses the 'B' button, instantly close the dialog.
    if pd.buttonJustPressed(pd.kButtonB) then
        self:close()
        return
    end
    
    -- Auto dismiss: If we have a reference to the sign that spawned us, check the player's distance.
    if self.sourceInteractable and _G.player then
        -- Calculate the absolute horizontal pixel distance between the Player and the Sign
        local dist = math.abs(_G.player.x - self.sourceInteractable.x)
        -- If the player slides away more than 48 pixels (perhaps due to momentum), close the dialog automatically!
        if dist > 48 then
            self:close()
        end
    end
end

--- Safely removes the dialog box from the screen and frees up the UI manager.
function MessageBox:close()
    -- Remove this sprite from the Playdate rendering loop
    self:remove()
    -- Tell the global UIManager singleton that we are done, freeing up the engine to allow player movement again!
    UIManager.activeUI = nil
end
