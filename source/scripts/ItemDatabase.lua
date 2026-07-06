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
        type = "equipment", slot = "weapon", attackType = "melee",
        damage = 35, range = 35, cooldown = 500, maxTargets = 2,
        maxStack = 1
    },
    rapier = {
        name = "Rapier",
        description = "Quick and deadly, but only pierces a single target.",
        imagePath = "images/items/sword",
        type = "equipment", slot = "weapon", attackType = "melee",
        damage = 50, range = 40, cooldown = 300, maxTargets = 1,
        maxStack = 1
    },
    greatsword = {
        name = "Greatsword",
        description = "Massive blade that cleaves everything in its path.",
        imagePath = "images/items/sword",
        type = "equipment", slot = "weapon", attackType = "melee",
        damage = 75, range = 50, cooldown = 800, maxTargets = 99,
        maxStack = 1
    },
    fireball = {
        name = "Fireball Wand",
        description = "Hurls a magical blast that deals splash damage.",
        imagePath = "images/items/potion", -- Placeholder image
        type = "equipment", slot = "weapon", attackType = "projectile",
        damage = 40, projectileSpeed = 6, splashRadius = 40, cooldown = 1000,
        maxStack = 1
    },
    silver_coin = {
        name = "Silver Coin",
        description = "Standard currency used across the kingdom.",
        imagePath = "images/items/coin",
        type = "currency",
        maxStack = 9999
    }
}
