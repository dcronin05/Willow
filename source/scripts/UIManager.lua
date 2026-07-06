_G.UIManager = {}

UIManager.activeUI = nil

function UIManager.showDialog(text, sourceInteractable)
    -- Prevent opening a new dialog if one is already open
    if UIManager.activeUI then return end
    
    -- Instantiate the MessageBox and track it
    UIManager.activeUI = MessageBox(text, sourceInteractable)
end

function UIManager.isUIActive()
    return UIManager.activeUI ~= nil
end
