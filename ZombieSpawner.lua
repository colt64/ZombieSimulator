local SpawnerBuilding = require("SpawnerBuilding")
local Zombie = require("Zombie")
local ZombieSpawner = {}

local ZombieSpawner = setmetatable({}, { __index = SpawnerBuilding })
ZombieSpawner.__index = ZombieSpawner



function ZombieSpawner.new(x,y,width, height, spawnrate)
    local self = setmetatable(SpawnerBuilding.new(x, y,width, height, spawnrate), ZombieSpawner)
    self.type = "zombie"
    self.color = {0,1,0}
    self.zombies = zombies
    self.spawnrate = spawnrate or 5
    self.buildingFrontX = self.x + self.width / 2
    self.buildingFrontY = self.y -  15 -- put it 15 pixels above the center of the building
    self.type = "ZombieSpawner"
    return self
end

function ZombieSpawner:spawnNPC()
    table.insert(zombies, Zombie.new(self.buildingFrontX, self.buildingFrontY))
end
return ZombieSpawner
