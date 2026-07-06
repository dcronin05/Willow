import "CoreLibs/object"
function playdate.update()
    playdate.graphics.setDitherPattern(0.5, playdate.graphics.image.kDitherTypeBayer8x8)
    print("Dither worked!")
    playdate.simulator.exit()
end
