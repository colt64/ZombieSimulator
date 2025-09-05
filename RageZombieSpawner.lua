local SpawnerBuilding = require("SpawnerBuilding")
local RageZombie = require("RageZombie")
local RageZombieSpawner = {}

local RageZombieSpawner = setmetatable({}, { __index = SpawnerBuilding })
RageZombieSpawner.__index = RageZombieSpawner



function RageZombieSpawner.new(x,y,width, height, spawnrate)
    local self = setmetatable(SpawnerBuilding.new(x, y,width, height, spawnrate), RageZombieSpawner)
    self.type = "zombie"
    self.color = {1,0,0}
    self.zombies = zombies
    self.spawnrate = spawnrate or 5
    self.buildingFrontX = self.x + self.width + 15
    self.buildingFrontY = self.y + self.height/2 -- put it 15 pixels above the center of the building
    self.type = "RageZombieSpawner"
    return self
end

function RageZombieSpawner:spawnNPC()
    table.insert(self.zombies, RageZombie.new(self.buildingFrontX, self.buildingFrontY))
end
return RageZombieSpawner
