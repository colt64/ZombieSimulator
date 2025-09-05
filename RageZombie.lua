local NPC = require("npc")
local Zombie = require("Zombie")
local utility = require("utility")

local RageZombie = setmetatable({},{__index = Zombie})
RageZombie.__index = RageZombie
local boid = true

---states ---
local states = {}


states.ragewander = {
    enter = function(self)
        self.maxSpeed = 30
        self.dx = love.math.random(-self.maxSpeed,self.maxSpeed)
        self.dy = love.math.random(-self.maxSpeed,self.maxSpeed)
        self.timer = 0
        --self.color = {0,1,0}
    end,
    update = function(self,dt)
        self.timer = self.timer + dt
        self:decay(dt)
         if self.timer >= 1 then
            if self.neighbors then
                self:applyBoids(self.neighbors)
            end
        end
    end
}


states.ragechase = {
    enter = function(self, target)
        self.chaseTarget = target 
        self.maxSpeed = 100
        self.timer = 0 
        self.cohesion = 0.04
        --self.color = {1,0,1}
    end,
    update = function(self,dt)
        self:decay(dt)
        if not self.chaseTarget then
            self.timer = self.timer + dt
            if self.timer > 1 then
                self.state = states.ragewander
                self.state.enter(self)
            end
            return
        else
            local dx = self.chaseTarget.x - self.x
            local dy = self.chaseTarget.y - self.y
            local dist = math.sqrt(dx*dx + dy*dy)
            if dist > 0 then
                self.dx = (dx / dist) * self.maxSpeed
                self.dy = (dy / dist) * self.maxSpeed
            end
        end
    end
}



function RageZombie.new(x,y)
    local self = Zombie.new(x,y)
    setmetatable(self, RageZombie)
    self.lifespan = 600
    self.maxSpeed = 5
    self.color = {1,0,0}
    self.vision = 100
    self.type = "rageZombie"
    self.states = {
        ragewander = states.ragewander,
        ragechase = states.ragechase
    }
    self.state = states.ragewander
    self.state.enter(self)
    return self
end

function RageZombie:decay(dt)
    self.decayTimer = self.decayTimer + dt
    if self.decayTimer > self.lifespan then
        self.dead = true
    end
    self.percentDecayed = utility.clamp(1 - (self.decayTimer/self.lifeSpan),0.2,1)
    self.color = {self.percentDecayed,0,0}
end

function RageZombie:look()
        self.chaseTarget = nil
        self.neighbors = {}
        ---Vision and states ---
        local closest = nil
        local closestDist = math.huge
        local visibleHumans = {}
        for _,n in ipairs(npcs) do
            table.insert(visibleHumans,n)
        end
        for _,p in ipairs(police) do
            table.insert(visibleHumans,p)
        end
        
        for _,v in ipairs(visibleHumans) do
            if self:canSee(v) then
                local dist = utility.getDistance(self.x, self.y, v.x, v.y)
                if dist < closestDist then
                    closestDist = dist
                    closest = v
                end
            end
        end
        self.chaseTarget = closest

        if self.chaseTarget and self.state ~= states.ragechase then
            self.state = states.ragechase
            self.state.enter(self, self.chaseTarget)
        end
        if #zombies > 2 and boid then
            for _,z in ipairs(zombies) do
                if z ~= self and self: canSee(z) then
                    table.insert(self.neighbors, z)
                end 
            end
        end
end

return RageZombie