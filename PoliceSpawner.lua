local SpawnerBuilding = require("SpawnerBuilding")
local Police = require("Police")
local PoliceSpawner = {}

local PoliceSpawner = setmetatable({}, { __index = SpawnerBuilding })
PoliceSpawner.__index = PoliceSpawner



function PoliceSpawner.new(x,y,width, height, spawnrate)
    local self = setmetatable(SpawnerBuilding.new(x, y,width, height, spawnrate), PoliceSpawner)
    self.type = "human"
    self.color = {0,0,1}
    self.police = police
    self.spawnrate = spawnrate or 8
    self.width = width or 50
    self.height = height or 75
    self.buildingFrontX = self.x - 15
    self.buildingFrontY = self.y + self.height/2 -- put it 15 pixels above the center of the building
    self.type = "PoliceSpawner"
    return self
end

function PoliceSpawner:spawnNPC()
    table.insert(police, Police.new(self.buildingFrontX, self.buildingFrontY))
end
return PoliceSpawner
