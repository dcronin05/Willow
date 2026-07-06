---@class NPC
--- The NPC class represents AI-driven characters in the world.
--- It extends Character to inherit physics, and adds a state machine for movement.

local pd = playdate
local gfx = pd.graphics

import "scripts/Character"

class('NPC').extends(Character)

function NPC:init(x, y, faction, iid, health)
    NPC.super.init(self, x, y, faction, iid, health)
    
    -- AI State Machine
    self.state = "patrol"
    self.patrolTimer = pd.timer.new(1000, function() self:pickPatrolDirection() end)
    self.patrolTimer.repeats = true
    
    -- Override max speed to be slower than player
    self.maxSpeed = 1.0
end

function NPC:pickPatrolDirection()
    -- Randomly pick left, right, or stop
    local dir = math.random(1, 3)
    if dir == 1 then
        self.xVelocity = -self.maxSpeed
        self.facingRight = false
    elseif dir == 2 then
        self.xVelocity = self.maxSpeed
        self.facingRight = true
    else
        self.xVelocity = 0
    end
end

function NPC:update()
    -- Apply friction if we're not actively commanded to move (or if we hit a wall)
    if self.xVelocity == 0 then
        self.xVelocity = self.xVelocity * self.friction
    end
    
    -- Apply base Character physics (gravity, collisions)
    self:applyPhysics()
    
    -- Flip the sprite and handle any animations defined by subclasses
    self:updateAnimation()
end
