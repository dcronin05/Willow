-- SaveManager handles persisting game state to the Playdate flash storage.
local pd = playdate

SaveManager = {}

-- Internal state table to hold data we want to save
SaveManager.state = {
    playerX = nil,
    playerY = nil,
    currentLevel = nil
}

function SaveManager.loadGame()
    local savedData = pd.datastore.read("willow_save")
    if savedData then
        SaveManager.state = savedData
        print("Save loaded successfully!")
    else
        print("No save found, starting fresh.")
    end
end

function SaveManager.saveGame()
    if _G.player then
        SaveManager.state.playerX = _G.player.x
        SaveManager.state.playerY = _G.player.y
    end
    
    pd.datastore.write(SaveManager.state, "willow_save")
    print("Game saved!")
end

function SaveManager.hasSavedPlayerPosition()
    return SaveManager.state.playerX ~= nil and SaveManager.state.playerY ~= nil
end

function SaveManager.getSavedPlayerPosition()
    return SaveManager.state.playerX, SaveManager.state.playerY
end
