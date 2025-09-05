local NPC = require("npc")
local utility = require("utility")

local Police = setmetatable({}, { __index = NPC })
Police.__index = Police

local boid = true


---- states
local states = {}

states.wander = {
    enter = function(self)
        self.dx = love.math.random(self.maxSpeed * -1,self.maxSpeed)
        self.dy = love.math.random(self.maxSpeed * -1,self.maxSpeed)
        self.timer = 0
    end,
    update = function(self, dt)
        self.timer = self.timer + dt
        self.fireCooldown = math.max(0, self.fireCooldown - dt)
        if zombies then
            self:look(zombies)
        end 
        self:updateBullets(dt)
        self:applyBoids(self.neighbors)
    end
}

function Police.new(x, y)
    local self = setmetatable(NPC.new(x, y), Police)
    self.color = {0,0,1}
    self.bullets = {}
    self.maxSpeed = 35
    self.vision = 130
    self.type = "human"
    self.Gatherer = false
    self.radius = 5
    self.fireCooldown = 0
    self.fireRate = 2
    self.states = {
        wander = states.wander
    }
    self.state = self.states.wander
    self.width = self.radius
    self.state.enter(self)
    return self
end

function Police:draw()
    -- draw the police officer
    love.graphics.setColor(self.color) -- blue for police
    love.graphics.circle("fill", self.x, self.y, self.radius)


    -- draw bullets
    if self.bullets then
        love.graphics.setColor(1, 1, 0) -- yellow bullets
        for _, b in ipairs(self.bullets) do
            love.graphics.circle("fill", b.x, b.y, b.radius or 2)
        end
        love.graphics.setColor(1, 1, 1)
    end
end

function Police:shootAt(target)
    -- direction toward zombie
    local dx = target.x - self.x
    local dy = target.y - self.y
    local len = math.sqrt(dx*dx + dy*dy)
    if len == 0 then return end

    dx, dy = dx/len, dy/len

    -- spray = a few slightly randomized directions
    for i = -2, 2 do
        local spread = 0.1 * i
        local angle = math.atan2(dy, dx) + spread
        local vx, vy = math.cos(angle), math.sin(angle)
 
        table.insert(self.bullets, {
            x = self.x,
            y = self.y,
            dx = vx * 200, -- bullet speed
            dy = vy * 200,
            alive = true,
            ttl = 2.0,
            radius = 1,
            width = 1
        })
    end
    self.fireCooldown = self.fireRate -- 1 sec between sprays
end

function Police:look()
    self.neighbors = {}
    -- Use spatial grid for zombies
    local nearbyZombies = zombieGrid:getNearby(self.x, self.y, self.vision)
    for _, npc in ipairs(nearbyZombies) do
        if (npc.type == "zombie" or npc.type == "rageZombie") and not npc.dead then
            if self:canSee(npc) and self.fireCooldown <= 0 then
                if self.timer > 0.5  then
                    self:shootAt(npc)
                    self.timer = 0
                end
                break
            end
        end
    end
    -- Use spatial grid for NPC boids
    if #npcs > 2 and boid then
        local nearbyNpcs = npcGrid:getNearby(self.x, self.y, self.vision)
        for _,n in ipairs(nearbyNpcs) do
            if n ~= self and self:canSee(n) then
                table.insert(self.neighbors, n)
            end 
        end
    end
end

function Police:updateBullets(dt)
    
    -- update bullets
    for i = #self.bullets, 1, -1 do
        local b = self.bullets[i]
        if b.alive then
            b.x = b.x + b.dx * dt
            b.y = b.y + b.dy * dt
            b.ttl = b.ttl - dt
            if b.ttl <= 0 then
                b.alive = false 
            else      
                for _,building in ipairs(buildings) do
                  if utility.detectNPCBuildingCollision(b,building) then
                    b.alive = false
                  end
            end
            utility.detectBulletCollision(b, zombies)
        end
    end
    for i = #self.bullets, 1,-1 do
        if not self.bullets[i].alive then
            table.remove(self.bullets,i)
        end
    end
    end
    
end

return Police
