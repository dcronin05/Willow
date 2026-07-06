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
    -- We'll make the image cover the entire left half of the screen
    local boxWidth = 200
    local boxHeight = 240
    local img = gfx.image.new(boxWidth, boxHeight)
    
    gfx.pushContext(img)
        -- =========================================================================
        -- TRUE FIXED-CURSOR SCROLLING
        -- =========================================================================
        local itemHeight = 22
        local fixedCursorY = 100 -- The cursor is permanently locked to this Y coordinate
        
        if #self.currentData == 0 then
            drawThickOutlinedText("*Empty*", 25, fixedCursorY)
        else
            -- We iterate through every item, but only draw the ones that fit on screen!
            for i = 1, #self.currentData do
                local item = self.currentData[i]
                
                -- Calculate this item's Y position relative to the currently selected item
                -- If i == selectedIndex, distance is 0, so yPos == fixedCursorY
                local distance = i - self.selectedIndex
                local yPos = fixedCursorY + (distance * itemHeight)
                
                -- Culling: Only draw items that are actually within the screen bounds
                if yPos > -itemHeight and yPos < boxHeight then
                    
                    -- Draw the permanently fixed cursor caret
                    if i == self.selectedIndex then
                        UIManager.drawThickOutlinedText(">", 9, yPos)
                    end
                    
                    local text = item.title or "Unknown"
                    if item.qty and item.qty > 1 then
                        text = text .. " x" .. item.qty
                    end
                    
                    UIManager.drawThickOutlinedText(text, 24, yPos)
                end
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
