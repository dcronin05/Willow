---@class InventoryUI
--- Displays the player's inventory from the SaveManager spreadsheet.
--- Allows scrolling and consuming items (like Potions).
local pd = playdate
local gfx = pd.graphics

class('InventoryUI').extends(gfx.sprite)

function InventoryUI:init()
    InventoryUI.super.init(self)
    
    self.selectedIndex = 1
    self.scrollOffset = 0
    self.itemsList = {}
    self:refreshItems()
    
    self:setCenter(0.5, 0.5)
    self:moveTo(200, 120) -- Center of screen
    self.ignoresDrawOffset = true -- Sticky UI
    self:setZIndex(100)
    self:add()
    
    self:drawUI()
end

function InventoryUI:refreshItems()
    self.itemsList = {}
    local playerInv = SaveManager.state.inventories["player"]
    if playerInv and playerInv.items then
        for itemId, qty in pairs(playerInv.items) do
            table.insert(self.itemsList, { id = itemId, qty = qty })
        end
    end
    -- Sort alphabetically for consistency
    table.sort(self.itemsList, function(a, b) return a.id < b.id end)
end

function InventoryUI:drawUI()
    local boxWidth = 300
    local boxHeight = 200
    local img = gfx.image.new(boxWidth, boxHeight)
    
    gfx.pushContext(img)
        -- Background
        gfx.setColor(gfx.kColorBlack)
        gfx.fillRoundRect(0, 0, boxWidth, boxHeight, 8)
        
        -- Border
        gfx.setColor(gfx.kColorWhite)
        gfx.setLineWidth(4)
        gfx.drawRoundRect(2, 2, boxWidth-4, boxHeight-4, 8)
        
        -- Title
        gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
        gfx.drawText("Inventory", 10, 10)
        gfx.drawLine(10, 30, boxWidth-10, 30)
        
        -- Items
        local yOffset = 40
        if #self.itemsList == 0 then
            gfx.drawText("*Empty*", 20, yOffset)
        else
            for i = 1, #self.itemsList do
                if i >= self.selectedIndex - 3 and i <= self.selectedIndex + 4 then
                    local item = self.itemsList[i]
                    local itemData = ItemDatabase[item.id]
                    local name = itemData and itemData.name or item.id
                    
                    -- Draw cursor
                    if i == self.selectedIndex then
                        gfx.drawText(">", 10, yOffset)
                    end
                    
                    gfx.drawText(name .. " x" .. item.qty, 30, yOffset)
                    yOffset = yOffset + 20
                end
            end
        end
    gfx.popContext()
    
    self:setImage(img)
end

function InventoryUI:update()
    -- Input handling
    if pd.buttonJustPressed(pd.kButtonDown) then
        if self.selectedIndex < #self.itemsList then
            self.selectedIndex = self.selectedIndex + 1
            self:drawUI()
        end
    elseif pd.buttonJustPressed(pd.kButtonUp) then
        if self.selectedIndex > 1 then
            self.selectedIndex = self.selectedIndex - 1
            self:drawUI()
        end
    elseif pd.buttonJustPressed(pd.kButtonA) then
        -- Use item
        if #self.itemsList > 0 then
            local selectedItem = self.itemsList[self.selectedIndex]
            if selectedItem.id == "potion" then
                if _G.player then
                    _G.player.health = 5
                    print("Healed to max!")
                end
                SaveManager.consumeItem("player", "potion", 1)
                self:refreshItems()
                if self.selectedIndex > #self.itemsList then
                    self.selectedIndex = math.max(1, #self.itemsList)
                end
                self:drawUI()
            end
        end
    elseif pd.buttonJustPressed(pd.kButtonB) then
        -- Close UI
        UIManager.clearUI()
    end
end
