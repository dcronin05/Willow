local pd = playdate
local gfx = pd.graphics

class('MessageBox').extends(gfx.sprite)

function MessageBox:init(text, sourceInteractable)
    MessageBox.super.init(self)
    
    self.text = text
    -- Keep a reference to the object that spawned this dialog
    self.sourceInteractable = sourceInteractable
    
    -- Draw the message box dynamically
    local boxWidth = 360
    local boxHeight = 60
    local image = gfx.image.new(boxWidth, boxHeight)
    
    gfx.pushContext(image)
        gfx.setColor(gfx.kColorBlack)
        gfx.fillRoundRect(0, 0, boxWidth, boxHeight, 4)
        
        gfx.setColor(gfx.kColorWhite)
        gfx.setLineWidth(2)
        gfx.drawRoundRect(2, 2, boxWidth-4, boxHeight-4, 4)
        
        gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
        gfx.drawTextInRect(self.text, 10, 10, boxWidth-20, boxHeight-20)
    gfx.popContext()
    
    self:setImage(image)
    self:setCenter(0.5, 1)
    self:moveTo(200, 230)
    
    self:setIgnoresDrawOffset(true)
    self:setZIndex(1000)
    self:add()
end

function MessageBox:update()
    -- Manual dismiss
    if pd.buttonJustPressed(pd.kButtonB) then
        self:close()
        return
    end
    
    -- Auto dismiss if we walk away (distance > 48 pixels)
    if self.sourceInteractable and _G.player then
        local dist = math.abs(_G.player.x - self.sourceInteractable.x)
        if dist > 48 then
            self:close()
        end
    end
end

function MessageBox:close()
    self:remove()
    -- Tell the UIManager that we are done!
    UIManager.activeUI = nil
end
