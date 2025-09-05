local Building = require("building")
local NPC = require("npc")

local SpawnerBuilding = setmetatable({}, { __index = Building })
SpawnerBuilding.__index = SpawnerBuilding

function SpawnerBuilding.new(x, y, width, height, spawnRate)
    local self = setmetatable(Building.new(x, y, width, height, spawnRate), SpawnerBuilding)
    self.spawnRate = spawnRate or 1
    self.color = {1,1,1}
    self.spawnTimer = spawnRate - 1
    self.npcs = npcs
    self.x = x or 25
    self.y = y or 25
    self.width = width or 50
    self.type = "SpawnerBuilding"
    return self
end

function SpawnerBuilding:update(dt)
    self.spawnTimer = self.spawnTimer + dt
    if self.spawnTimer >= self.spawnRate then
        self:spawnNPC()
        self.spawnTimer = 0
    end
end
function SpawnerBuilding:spawnNPC()
    local buildingFrontX = self.x + self.width / 2
    local buildingFrontY = self.y + self.height + 15 -- put it 15 pixels below the center of the building

    table.insert(self.npcs, NPC.new(buildingFrontX, buildingFrontY, self.x, self.y))
end

function SpawnerBuilding:isInside(x, y)
    return x >= self.x and x <= self.x + self.width and y >= self.y and y <= self.y + self.height
end

function SpawnerBuilding:handleClick(x, y)
    if self:isInside(x, y) then
        self:spawnNPC()
        return true
    end
    return false
end
return SpawnerBuilding
