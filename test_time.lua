import "CoreLibs/object"
function playdate.update()
    print("Time: " .. playdate.getSecondsSinceEpoch())
    playdate.simulator.exit()
end
