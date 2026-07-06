---@class ItemDatabase
--- A static table defining the properties of every item in the game.
--- This prevents us from having to store display names, descriptions, and sprite paths 
--- in the save file. We just save the ID (e.g., "potion") and look it up here!

ItemDatabase = {
    potion = {
        name = "Health Potion",
        description = "Restores 25 health. Tastes like cherries.",
        imagePath = "images/items/potion", -- We will draw a tiny bottle for this later
        type = "consumable",
        healAmount = 25,
        maxStack = 99
    },
    iron_sword = {
        name = "Iron Sword",
        description = "A basic blade. Pointy end goes into the slime.",
        imagePath = "images/items/sword",
        type = "equipment",
        maxStack = 1
    }
}
