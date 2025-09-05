local NPC = require("npc")
local utility = require("utility")

local Zombie = {}
local Zombie = setmetatable({},{__index = NPC})
Zombie.__index = Zombie
local boid = false

--lookup for zombie types
local zombieTypes = {
    ["zombie"] = true,
    ["rageZombie"] = true
}
--- states ---
local states = {}

states.idle = {
    enter = function(self)
        self.timer = 0
        self.dx = 0
        self.dy = 0
        --self.color = {0,0.5,0}

    end,
    update = function(self,dt)
        self:decay(dt)
        self.timer = self.timer + dt
        if self.timer > 1 then
            self.state = states.wander
            self.state.enter(self)
        end
    end
}


states.wander = {
    enter = function(self)
        self.maxSpeed = 30
        self.dx = love.math.random(-self.maxSpeed,self.maxSpeed)
        self.dy = love.math.random(-self.maxSpeed,self.maxSpeed)
        self.timer = 0
        self.wanderoffRand = love.math.random(1,500)
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
        if love.math.random(1,1000) == wanderoffRand then
            self.state = states.wanderoff
            self.state.enter(self)
        end 
    end
}


states.wanderoff = {
    enter = function(self,dt)
        self.maxSpeed = 35
        self.dx = love.math.random(-self.maxSpeed,self.maxSpeed) 
        self.dy = love.math.random(-self.maxSpeed,self.maxSpeed) 
      --  self.color = {0,1,1}
    end,
    update = function(self,dt)
        self:decay(dt)
        self.timer = self.timer + dt
        if self.timer > 12 then
            self.color = {0,1,0}
            self.state = states.wander
            self.state.enter(self)
        end
    end
}


states.chase = {
        enter = function(self, target)
        self.maxSpeed = 45
        self.chaseTarget = target 
        self.timer = 0 
        --self.color = {1,0,1}
    end,
    update = function(self,dt)
        self:decay(dt)
        if not self.chaseTarget then
            self.timer = self.timer + dt
            if self.timer > 1 then
                self.state = states.wander
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


function Zombie.new(x,y)
    local self = setmetatable(NPC.new(x,y),Zombie)
    self.maxSpeed = 40
    self.color = {0,1,0}
    self.type = "zombie"
    self.percentDecayed = 0
    self.state = states.wander
    self.decayTimer = 0
    self.lifeSpan = 20
    self.separation = 20
    self.alignment = 0.1
    self.cohesion = 0.2
    self.zombies = zombies
    self.vision = 160
    self.states = {
        wander = states.wander,
        chase = states.chase,
        idle = states.idle,
        wanderoff = states.wanderoff
    }
    self.state = self.states.wanderoff
    self.state.enter(self)
    self.npcs =  npcs
    self.neighbors = {}
    return self
end



function Zombie:look()
    self.neighbors = {}
    local closest = nil
    local closestDist = math.huge
    local visibleHumans = {}
    -- Only check humans in nearby cells
    local nearbyNpcs = npcGrid:getNearby(self.x, self.y, self.vision or 80)
    local nearbyPolice = police or {}
    for _,n in ipairs(nearbyNpcs) do
        table.insert(visibleHumans, n)
    end
    for _,p in ipairs(nearbyPolice) do
        table.insert(visibleHumans, p)
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
    if self.chaseTarget and self.state ~= self.states.chase and self.state ~= self.states.idle then
        self.state = self.states.chase
        self.state.enter(self, self.chaseTarget)
    end
    -- Only check zombies in nearby cells
    if #zombies > 2 and boid then
        local nearbyZombies = zombieGrid:getNearby(self.x, self.y, self.vision or 80)
        for _,z in ipairs(nearbyZombies) do
            if z ~= self and self:canSee(z) and z.state ~= self.states.wanderoff then
                table.insert(self.neighbors, z)
            end
        end
    end
end

function Zombie:canSee(target)
    local distx = target.x - self.x
    local disty = target.y - self.y
    local distanceSquared = distx * distx + disty * disty
    if distanceSquared > (self.vision or 80) * (self.vision or 80) then
        return false
    end
    -- Only check buildings in nearby cells
    local nearbyBuildings = buildingGrid:getNearby(self.x, self.y, self.vision or 80)
    for _,b in ipairs(nearbyBuildings) do
        if utility.visionBlocked(self.x, self.y, target.x, target.y, b.x, b.y, b.width, b.height) then
            return false
        end
    end
    return true
end

function Zombie:decay(dt)
    self.decayTimer = self.decayTimer + dt
    if self.decayTimer > self.lifeSpan then
        self.dead = true
    end
    self.percentDecayed = utility.clamp(1 - (self.decayTimer/self.lifeSpan),0.2,1)
    self.color = {0,self.percentDecayed,0}
end

return Zombie
