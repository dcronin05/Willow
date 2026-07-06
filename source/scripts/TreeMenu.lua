---@class TreeMenu
--- A generic, nested vertical menu system (Skyrim-style) that draws on the left side of the screen.
--- Supports infinite nesting, fixed-cursor scrolling, and custom actions.

local pd = playdate
local gfx = pd.graphics

class('TreeMenu').extends(gfx.sprite)

--- Initializes the TreeMenu.
---@param rootData table The nested list of menu items.
function TreeMenu:init(rootData)
    TreeMenu.super.init(self)
    
    -- Stack to remember exactly where we were when drilling down or popping back up
    self.historyStack = {}
    
    -- Current list of items to display
    self.currentData = rootData
    
    -- The cursor is technically always on the selectedIndex, but visually it stays fixed on screen
    self.selectedIndex = 1
    
    -- Setup the sprite to draw on the left side of the screen
    self:setCenter(0, 0)
    self:moveTo(10, 40) -- Start below the top stats bar
    self:setIgnoresDrawOffset(true) -- Stay locked to the camera/screen
    self:setZIndex(100)
    self:add()
    
    self:drawUI()
end

--- Redraws the menu graphics to an image and assigns it to this sprite.
function TreeMenu:drawUI()
    local boxWidth = 140
    local boxHeight = 190
    local img = gfx.image.new(boxWidth, boxHeight)
    
    gfx.pushContext(img)
        -- Background (Solid black for readability)
        gfx.setColor(gfx.kColorBlack)
        gfx.fillRoundRect(0, 0, boxWidth, boxHeight, 4)
        
        -- Border
        gfx.setColor(gfx.kColorWhite)
        gfx.setLineWidth(2)
        gfx.drawRoundRect(1, 1, boxWidth-2, boxHeight-2, 4)
        
        -- Calculate how many items can fit and where the "fixed cursor" should be visually
        local maxVisibleItems = 7
        local itemHeight = 20
        -- We want the selected item to appear roughly in the middle of the list
        local visualCursorIndex = math.min(self.selectedIndex, 4) 
        -- If we are at the very bottom of a long list, the cursor might shift down
        if self.selectedIndex > #self.currentData - 3 and #self.currentData > maxVisibleItems then
            visualCursorIndex = maxVisibleItems - (#self.currentData - self.selectedIndex)
        end
        
        local startIndex = self.selectedIndex - visualCursorIndex + 1
        local endIndex = startIndex + maxVisibleItems - 1
        
        -- Draw Items
        gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
        
        local yOffset = 10
        if #self.currentData == 0 then
            gfx.drawText("*Empty*", 24, yOffset)
        else
            for i = startIndex, endIndex do
                if self.currentData[i] then
                    local item = self.currentData[i]
                    
                    -- Draw the fixed cursor if this is the selected item
                    if i == self.selectedIndex then
                        gfx.drawText(">", 8, yOffset)
                    end
                    
                    local text = item.title or "Unknown"
                    if item.qty and item.qty > 1 then
                        text = text .. " x" .. item.qty
                    end
                    
                    gfx.drawText(text, 24, yOffset)
                    
                    -- If it has children, draw a little indicator
                    if item.children then
                        gfx.drawText("+", boxWidth - 16, yOffset)
                    end
                end
                yOffset = yOffset + itemHeight
            end
        end
    gfx.popContext()
    
    self:setImage(img)
end

--- Called automatically by Playdate every frame.
function TreeMenu:update()
    if pd.buttonJustPressed(pd.kButtonDown) then
        if self.selectedIndex < #self.currentData then
            self.selectedIndex = self.selectedIndex + 1
            self:drawUI()
        end
    elseif pd.buttonJustPressed(pd.kButtonUp) then
        if self.selectedIndex > 1 then
            self.selectedIndex = self.selectedIndex - 1
            self:drawUI()
        end
    elseif pd.buttonJustPressed(pd.kButtonA) then
        if #self.currentData == 0 then return end
        
        local selectedItem = self.currentData[self.selectedIndex]
        
        if selectedItem.children then
            -- Drill down into the sub-menu!
            -- Save our current state to the stack
            table.insert(self.historyStack, {
                data = self.currentData,
                index = self.selectedIndex
            })
            -- Move to the new list
            self.currentData = selectedItem.children
            self.selectedIndex = 1
            self:drawUI()
            
        elseif selectedItem.onSelect then
            -- Execute the action!
            selectedItem.onSelect()
            -- Actions might consume an item, so they should tell UIManager to rebuild the tree if needed,
            -- or we just redraw what we have for now.
            self:drawUI()
        end
        
    elseif pd.buttonJustPressed(pd.kButtonB) then
        if #self.historyStack > 0 then
            -- Pop back up to the parent list!
            local previousState = table.remove(self.historyStack)
            self.currentData = previousState.data
            self.selectedIndex = previousState.index
            self:drawUI()
        else
            -- We are at the root! Close the UI entirely.
            UIManager.clearUI()
        end
    end
end
