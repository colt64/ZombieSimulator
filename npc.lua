local utility = require("utility")
local NPC = {}
NPC.__index = NPC
local boid = true


--- states ---
local states = {}

states.idle = {
    enter = function(self)
        self.timer = 0
        self.dx = 0
        self.dy = 0
      --  self.color = {1,1,1}
    end,
    update = function(self,dt)
        self.timer = self.timer + dt
        if self.timer > 2 then
            self.state = self.states.wander
            self.state.enter(self)
        end
    end
}

states.newSpawn = {
    enter = function(self)
        --do not apply boids for a few seconds and others should ignore
        self.timer = 0
        self.dx = love.math.random(self.maxSpeed * -1,self.maxSpeed)
        self.dy = love.math.random(self.maxSpeed * -1,self.maxSpeed)
      --  self.color = {1,1,0}
    end,
    update = function(self,dt)
        self.timer = self.timer + dt
        if self.timer > 14 then
            self.state = self.states.wander
            self.state.enter(self)
        end
    end
}


states.wander = {
    enter = function(self)
        self.maxSpeed = 30
        self.dx = love.math.random(self.maxSpeed * -1,self.maxSpeed)
        self.dy = love.math.random(self.maxSpeed * -1,self.maxSpeed)
        self.timer = 0
       self.color = {1,1,1}
    end,
    update = function(self,dt)
        self.timer = self.timer + dt
        if self.timer >= 1 then
            if self.party then
                self:applyBoids(self.party)
            end
        end   
    end
}

states.flee = {
    enter = function(self, targets)
        self.maxSpeed = 50
        self.fleeTargets = targets or {}
        self.timer = 0 
     --   self.color = {1,0,0}
    end,
    update = function(self,dt)
        if #self.fleeTargets == 0 then
            self.timer = self.timer + dt
            if self.timer > 1 then
                if self.carryingSupply then
                    self.state = states.returnToBase
                    self.state.enter(self, {x = self.baseX, y = self.baseY}) 
                else
                    self.state = states.wander
                end
                self.state = self.states.wander
                self.state.enter(self)
            end
            return
        end
        local moveX, moveY = 0,0
        local count = 0
        for _,z in ipairs(self.fleeTargets) do
            local dx = self.x - z.x
            local dy = self.y - z.y
            local dist = math.sqrt(dx*dx + dy*dy)
            if dist > 0 then
                moveX = moveX + (dx / dist)
                moveY = moveY + (dy / dist)
                count = count + 1
            end
        end
        if count > 0 then
            self.dx = (moveX / count) * self.maxSpeed
            self.dy = (moveY / count) * self.maxSpeed
        end
    end
}

states.returnToBase = {
    enter = function(self, target)
        self.returnTarget = target 
        self.maxSpeed = 45
        self.timer = 0 
        self.color = {1,1,0}
    end,
    update = function(self,dt)
        if not self.returnTarget then
            self.timer = self.timer + dt
            if self.timer > 1 then
                self.state = states.wander
                self.color = {1,1,1}
                self.state.enter(self)
            end
            return
        else
            local dx = self.returnTarget.x - self.x
            local dy = self.returnTarget.y - self.y
            local dist = math.sqrt(dx*dx + dy*dy)
            if dist > 0 then
                self.dx = (dx / dist) * self.maxSpeed
                self.dy = (dy / dist) * self.maxSpeed
            end
        end
    end
}

states.gather = {
    enter = function(self, target)
    self.maxSpeed = 60
    self.gatherTarget = target 
    -- self.color = {1,0,1}
    end,
    update = function(self,dt)
        if self.gatherTarget then
            if utility.contains(supplies, self.gatherTarget) == false then
                self.gatherTarget = nil
            end
        end
        if not self.gatherTarget and self.state ~= self.states.returnToBase then
            self.state = self.states.wander
            self.state.enter(self)
            return
        else
            local dx = self.gatherTarget.x - self.x
            local dy = self.gatherTarget.y - self.y
            local dist = math.sqrt(dx*dx + dy*dy)
            if dist > 0 then
                self.dx = (dx / dist) * self.maxSpeed
                self.dy = (dy / dist) * self.maxSpeed
            end
        end
    end
}

function NPC.new(x,y, baseX, baseY)
    local self = setmetatable({}, NPC)
    self.type = "human"
    self.x = x or 100
    self.y = y or 100
    self.baseX = baseX or 200
    self.baseY = baseY or 200
    self.width = 3
    self.height = 3
    self.radius = self.width
    self.color = {1,1,1}
    self.maxSpeed = 55
    self.vision = 120
    self.npcs = npc
    self.zombies = zombies
    self.neighbors = {}
    self.separation = 10
    self.cohesion = 0.2
    self.alignment = 0.1
    self.Gatherer = true
    self.carryingSupply = false
    self.dead = false
    self.group = nil
    self.collidingWith = nil
    self.states = {
        wander = states.wander,
        chase = states.chase,
        idle = states.idle,
        flee = states.flee,
        returnToBase = states.returnToBase,
        gather = states.gather,
        newSpawn = states.newSpawn
    }
    self.dx = love.math.random(self.maxSpeed * -1,self.maxSpeed)
    self.dy = love.math.random(self.maxSpeed * -1,self.maxSpeed)  -- random y velocity
    self.state = self.states.wander
    self.state.enter(self)
    return self
end

function NPC:update(dt)
    local colliding = false
    local nextX = self.x + self.dx * dt
    local nextY = self.y + self.dy * dt

    -- Only check buildings in nearby cells
    self:avoidBuildingColision(nextX,nextY,dt)

    -- Only check zombies in nearby cells
    local nearbyZombies = zombieGrid:getNearby(self.x, self.y, self.vision)
    for _,z in ipairs(nearbyZombies) do
        if utility.detectNPCCollision(self,z) then
            if z.type == "zombie" and self.type == "human" then
                --spawn a zombie in this spot and destroy this npc
                if not self.dead then
                    table.insert(pendingSpawns, {x = self.x, y = self.y, type = "zombie"})
                    self.dead = true
                end
                z.state = z.states.idle
                z.state.enter(z)
            end
            if z.type == "rageZombie" and self.type == "human" and not self.dead then
                if love.math.random(0,100) >= 50 then
                    self.dead = true -- half the time rage zombies just kill the person but don't create a new zombie
                else
                    table.insert(pendingSpawns, {x = self.x, y = self.y, type = "zombie"})
                    self.dead = true
                end
            end
        end
    end
    -- Check for supply collision (only for non-police humans)
    if self.type == "human" and self.Gatherer then
        for i = #supplies, 1, -1 do
            local supply = supplies[i]
            if utility.detectNPCCollision(self, {x = supply.x, y = supply.y, width = supply.height}) then
                -- Remove the supply
                table.remove(supplies, i)
                -- Enter returnToBase state
                self.state = states.returnToBase
                self.carryingSupply = true
                self.state.enter(self, {x = self.baseX, y = self.baseY}) 
                break
            end
        end
    end
    -- update position
    self.x = utility.clamp(self.x + (self.dx * dt),0,WINDOW_WIDTH)
    self.y = utility.clamp(self.y + (self.dy * dt),0,WINDOW_HEIGHT)
    self:look()
    --should always return to base if carrying supply
    if self.carryingSupply then
        self.state = self.states.returnToBase
        self.state.enter(self, {x = self.baseX, y = self.baseY})
    end
    self.state.update(self,dt)
end

function NPC:avoidBuildingColision(nextX,nextY,dt)
    local nearbyBuildings = buildingGrid:getNearby(nextX, nextY, self.vision)
    for _,b in ipairs(nearbyBuildings) do
        local horiz = utility.detectNPCBuildingCollision({x=nextX, y=self.y, width=self.width}, b)
        local vert = utility.detectNPCBuildingCollision({x=self.x, y=nextY, width=self.width}, b)
        if horiz or vert then
            self.collidingWith = b.type
            if self.carryingSupply and b.type == "SpawnerBuilding" then
                self.carryingSupply = false
                suppliesCollected = suppliesCollected + 1
                self.dead = true --despawn after delivering supply
            end
            -- if horizontal collision, zero vx
            if horiz then
                self.dx = self.dx * -1
                self.dy = self.maxSpeed * utility.sign(self.dy)
            end
            -- if vertical collision, zero vy
            if vert then
                self.dy = self.dy * -1
                self.dx = self.maxSpeed * utility.sign(self.dx)
            end
            -- If stuck on a corner (both horiz & vert), add a random nudge
            if horiz and vert then
                self.dx = self.dx + love.math.random(-10,10)
                self.dy = self.dy + love.math.random(-10,10)
                -- Clamp speed to maxSpeed after nudge
                local speed = math.sqrt(self.dx * self.dx + self.dy * self.dy)
                if speed > self.maxSpeed then
                    self.dx = (self.dx / speed) * self.maxSpeed
                    self.dy = (self.dy / speed) * self.maxSpeed
                end
            end
        end
    end
    if nextX <= 0 or nextX >= WINDOW_WIDTH - self.width then
        self.dx = self.dx * -1
    end
    if nextY <= 0 or nextY >= WINDOW_HEIGHT - self.width then
        self.dy = self.dy * -1
    end
end

function NPC:draw()
    love.graphics.setColor(self.color)
    love.graphics.circle("fill",self.x,self.y,self.width)
    local c = self.collidingWith or ""
    --love.graphics.print("collidingWith: " .. c,self.x,self.y + 11)
end

function NPC:look()
    self.party = {}
    self.neighbors = {}
    local visibleZombies = {}
    --check for supplies before checking for zombies
    if supplies and #supplies > 0 and self.type == "human" and self.state ~= self.states.gather then
        local closestSupply = nil
        local closestDist = math.huge
        for _,s in ipairs(supplies) do
            local dx = s.x - self.x
            local dy = s.y - self.y
            local dist = math.sqrt(dx*dx + dy*dy)
            if dist < closestDist and self:canSee(s) then
                closestDist = dist
                closestSupply = s
            end
        end
        if closestSupply and self.state ~= self.states.returnToBase then
            self.state = self.states.gather
            self.state.enter(self, closestSupply)
            return
        end
    end 


    -- Only check zombies in nearby cells
    local nearbyZombies = zombieGrid:getNearby(self.x, self.y, self.vision)
    for _,v in ipairs(nearbyZombies) do
        if self:canSee(v) then
            if v.type == "zombie" and self.type == "human" then
                table.insert(visibleZombies,v)
            end
        end
    end
    self.fleeTargets = visibleZombies
    if #visibleZombies > 0 and self.type == "human" and self.state ~= self.states.flee then
        self.state = self.states.flee
        self.state.enter(self, visibleZombies)
    end
    -- Only check NPCs in nearby cells
    if #npcs > 2 and boid then
        local nearbyNpcs = npcGrid:getNearby(self.x, self.y, self.vision)
        for _,n in ipairs(nearbyNpcs) do
            if n ~= self and self:canSee(n) and n.state ~= n.states.newSpawn then
                table.insert(self.neighbors, n)
                
                --group logic--
                if not self.group and not n.group then
                    self.group = love.math.random(0,100000)
                    groups[self.group] = {size = 2, maxsize = love.math.random(2,6)}
                    n.group = self.group
                    table.insert(self.party,n)
                    return
                end
                if not self.group and n.group and groups[n.group].size <= groups[n.group].maxsize then
                    self.group = n.group
                    groups[n.group].size = groups[n.group].size + 1
                    table.insert(self.party,n)
                end
                if self.group and n.group then
                    if self.group == n.group then
                        table.insert(self.party,n)
                    end
                end
            end
        end
    end
    --if youre alone look for a new group
    if #self.party < 1 and self.group then
        groups[self.group].size = groups[self.group].size - 1
        if groups[self.group].size <= 0 then
            groups[self.group] = nil
        end
        self.group = nil
    end
        
end

-- Helper: Boids logic
function NPC:applyBoids(neighbors)
    local separationX, separationY = 0,0
    local alignmentX, alignmentY = 0,0
    local cohesionX, cohesionY = 0,0
    local neighborCount = 0

    for _, other in ipairs(neighbors) do
        if other ~= self and not other.dead and self:canSee(other) then
            local dx = self.x - other.x
            local dy = self.y - other.y
            local dist = math.sqrt(dx*dx + dy*dy)
            if dist > 0 then
                separationX = separationX + (dx / (dist*dist))
                separationY = separationY + (dy / (dist*dist))
                alignmentX = alignmentX + other.dx
                alignmentY = alignmentY + other.dy
                cohesionX = cohesionX + other.x
                cohesionY = cohesionY + other.y
                neighborCount = neighborCount + 1
            end
        end
    end

    if neighborCount > 0  then
        alignmentX = alignmentX / neighborCount
        alignmentY = alignmentY / neighborCount
        cohesionX = (cohesionX / neighborCount - self.x)
        cohesionY = (cohesionY / neighborCount - self.y)

        local separationWeight, alignmentWeight, cohesionWeight = self.separation, self.alignment, self.cohesion

        local moveX = self.dx + separationX * separationWeight + alignmentX * alignmentWeight + cohesionX * cohesionWeight
        local moveY = self.dy + separationY * separationWeight + alignmentY * alignmentWeight + cohesionY * cohesionWeight

        -- apply forces
        self.dx = self.dx + separationX * separationWeight + alignmentX * alignmentWeight + cohesionX * cohesionWeight
        self.dy = self.dy + separationY * separationWeight + alignmentY * alignmentWeight + cohesionY * cohesionWeight

        -- clamp speed
        local speed = math.sqrt(self.dx*self.dx + self.dy*self.dy)
        if speed > self.maxSpeed then
            self.dx = ((self.dx / speed) * self.maxSpeed) 
            self.dy = ((self.dy / speed) * self.maxSpeed) 
        end
    end    
end

function NPC:canSee(target)
    local distx = target.x - self.x
    local disty = target.y - self.y
    local distanceSquared = distx * distx + disty * disty
    if distanceSquared > self.vision * self.vision then
        return false
    end
    -- Only check buildings in nearby cells
    local nearbyBuildings = buildingGrid:getNearby(self.x, self.y, self.vision)
    for _,b in ipairs(nearbyBuildings) do
        if utility.visionBlocked(self.x, self.y, target.x, target.y, b.x, b.y, b.width, b.height) then
            return false
        end
    end
    return true
end

return NPC