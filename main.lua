local NPC = require("npc")
local utility = require("utility")
local SpawnerBuilding = require("SpawnerBuilding")
local Building = require("building")
local ZombieSpawner = require("ZombieSpawner")
local PoliceSpawner = require("PoliceSpawner")
local RageZombieSpawner = require("RageZombieSpawner")
local Zombie = require("Zombie")
local Police = require("Police")
local TownHall = require("TownHall")
local Supply = require("Supply")
buildings = {}
npcs = {}
zombies = {}
pendingSpawns = {}
police = {}
supplies = {}
suppliesCollected = 0
groups = {}

---globals for upgrade costs
spawnerCost = 5
policeCost = 1

local supplySpawnTimer = 0
local supplySpawnInterval = 4 -- spawn a supply every 10 seconds

-- Spatial grids for efficient queries
npcGrid = utility.SpatialGrid.new(32, 748, 748)
zombieGrid = utility.SpatialGrid.new(32, 748, 748)
buildingGrid = utility.SpatialGrid.new(64, 748, 748)

WINDOW_WIDTH, WINDOW_HEIGHT = love.graphics.getDimensions()

local function spawmNPC()
    npcX = love.math.random(WINDOW_WIDTH)
    npcyY = love.math.random(WINDOW_HEIGHT)
    table.insert(npcs,NPC.new(npcX,npcY))
end


function love.load()
    love.window.setMode(0,0,{resizable = true})  
   table.insert(buildings, SpawnerBuilding.new(25, 25, 25, 25, 4))
   table.insert(buildings, Building.new(300,25, 50, 75, 20))
   table.insert(buildings, ZombieSpawner.new(250, 300, 75, 50, 10))
   table.insert(buildings, Building.new(50,275, 50, 75, 20))
   table.insert(buildings, TownHall.new(125,275,100,75))

   -- table.insert(buildings, Building.new(0,0,10,340))
   -- Create empty buildings --
   --row 1
   table.insert(buildings, Building.new(125,25, 50,50))
   table.insert(buildings, Building.new(200,25, 75,50))
   table.insert(buildings, Building.new(50,100, 75,50))
   table.insert(buildings, Building.new(150,100, 50,50))
   table.insert(buildings, Building.new(225,125, 50,25))
   table.insert(buildings, Building.new(300,125, 25,25))
    --row2
   table.insert(buildings, Building.new(25,175, 75,75))
   table.insert(buildings, Building.new(250,175, 50,75))
   table.insert(buildings, Building.new(325,175, 50,50))
   table.insert(buildings, Building.new(325,250, 50,25))
   --row4
   table.insert(buildings, Building.new(25,375, 50,50))
   table.insert(buildings, Building.new(100,375, 50,50))
   table.insert(buildings, Building.new(175,375, 75,50))
   table.insert(buildings, Building.new(300,375, 50,50))
   

   --row5
    table.insert(buildings, Building.new(25,450, 25,25))
    table.insert(buildings, Building.new(75,450, 25,25))

    table.insert(buildings, Building.new(325,450, 50,50))
    
    table.insert(buildings, Building.new(200,450, 50,50))
    table.insert(buildings, Building.new(125,450, 75,100))

    --row 6
    table.insert(buildings, Building.new(25,500, 25,25))
    table.insert(buildings, Building.new(75,500, 25,25))
    table.insert(buildings, Building.new(25,550, 75,50))

   table.insert(buildings, Building.new(300,525, 50,50))   

   table.insert(buildings, Building.new(125,575, 25,25))
   table.insert(buildings, Building.new(175,575, 25,25))


    -- row 7
    table.insert(buildings, Building.new(25,625, 50,110))
    table.insert(buildings, Building.new(100,625, 50,110))
    -- table.insert(buildings, Building.new(325,600, 50,50))

    table.insert(buildings, Building.new(175,625, 125,40))
    table.insert(buildings, Building.new(175,690, 125,40))

    table.insert(buildings, Building.new(325,625,25,25))
    table.insert(buildings, Building.new(350,650, 25,25))
    table.insert(buildings, Building.new(325,675, 25,25))
    table.insert(buildings, Building.new(350,700, 25,25))


    ---map-east --
    table.insert(buildings, Building.new(400,25, 50,50))
    table.insert(buildings, Building.new(475,25, 50,50))
    table.insert(buildings, Building.new(550,25, 50,50))
    table.insert(buildings, Building.new(625,25, 50,50))
    table.insert(buildings, Building.new(700,25, 50,50))
    
    table.insert(buildings, Building.new(400,100, 50,50))
    table.insert(buildings, Building.new(475,100, 50,50))
    table.insert(buildings, Building.new(550,100, 50,50))
    table.insert(buildings, Building.new(625,100, 50,50))
    table.insert(buildings, Building.new(700,100, 50,50))

    table.insert(buildings, Building.new(400,175, 50,50))
    table.insert(buildings, Building.new(475,175, 50,50))
    table.insert(buildings, Building.new(550,175, 50,50))
    table.insert(buildings, Building.new(625,175, 50,50))
    table.insert(buildings, Building.new(700,175, 50,50))

    table.insert(buildings, Building.new(400,250, 50,50))
    table.insert(buildings, Building.new(475,250, 50,50))
    table.insert(buildings, Building.new(550,250, 50,50))
    table.insert(buildings, Building.new(625,250, 50,50))
    table.insert(buildings, Building.new(700,250, 50,50))

    table.insert(buildings, Building.new(400,325, 50,50))
    table.insert(buildings, Building.new(475,325, 50,50))
    table.insert(buildings, Building.new(550,325, 50,50))
    table.insert(buildings, Building.new(625,325, 50,50))
    table.insert(buildings, Building.new(700,325, 50,50))

    --walls around the edge of the screen for now
    --  table.insert(buildings, Building.new(390,0,10,740))        
    -- -- table.insert(buildings, Building.new(375,400,400,10))
    -- -- table.insert(buildings, Building.new(0,700,400,10))
    --  table.insert(buildings, Building.new(0,0,50,10))
    --  table.insert(buildings, Building.new(75,0,50,10))
    --  table.insert(buildings, Building.new(150,0,50,10))
    --  table.insert(buildings, Building.new(225,0,50,10))
    --  table.insert(buildings, Building.new(300,0,50,10))
    --  table.insert(buildings, Building.new(375,0,50,10))
    --  table.insert(buildings, Building.new(42,0,50,10))

    -- Insert buildings into buildingGrid
    for _, b in ipairs(buildings) do
        buildingGrid:insert(b)
    end
end

function love.resize(w,h)
    WINDOW_WIDTH = w
    WINDOW_HEIGHT = h
    for _,b in ipairs(buildings) do
        b:resize(w,h)
    end
end

function love.draw()
    --draw the UI
    love.graphics.setColor({1,1,1})
    love.graphics.print("Humans " .. #npcs + #police, 5,5)
    love.graphics.print("Zombies: " .. #zombies, 100, 5)
    love.graphics.print("Supplies: " .. suppliesCollected, 275,5)

    --width and height for debugging
    -- love.graphics.print("Width: " .. WINDOW_WIDTH, 200,5)
    -- love.graphics.print("Height: " .. WINDOW_HEIGHT, 275,5)


            --draw buildings and mobs
    for _,building in ipairs(buildings) do
        building:draw()
    end
    --draw the park
    love.graphics.setColor({0.3,0.3,0})
    love.graphics.rectangle("fill",105,175,140,100,20,20)
    love.graphics.setColor({0.2,0.5,1})
    love.graphics.ellipse("fill",175,215,45,15)
    --draw mobs
    for _,p in ipairs(police) do
        p:draw()
    end
    for _,npc in ipairs(npcs) do
        npc:draw()
    end
    for _,zombie in ipairs(zombies) do
        zombie:draw()
    end
    for _,s in ipairs(supplies) do
        s:draw()
    end
    
        --draw UI
    for _,building in ipairs(buildings) do
        building:drawMenu()
    end
end    

function love.update(dt)
    npcGrid:clear()
    zombieGrid:clear()
    -- Insert all npcs/zombies into their grids
    for _,npc in ipairs(npcs) do
        npcGrid:insert(npc)
    end
    for _,zombie in ipairs(zombies) do
        zombieGrid:insert(zombie)
    end
    for _,building in ipairs(buildings) do
        building:update(dt)
    end
    for _,npc in ipairs(npcs) do
        npc:update(dt)
    end
    for _,zombie in ipairs(zombies) do
        zombie:update(dt, buildingGrid)
    end
    for _,p in ipairs(police) do
        p:update(dt, buildings)
    end
    --cleanup dead things and spawn new ones
    for i = #npcs, 1, -1 do
        if npcs[i].dead then
            npcGrid:remove(npcs[i])
            table.remove(npcs, i)
        end
    end
    for i = #zombies, 1, -1 do
        if zombies[i].dead then
            zombieGrid:remove(zombies[i])
            table.remove(zombies, i)
        end
    end


    for i = #police,1,-1 do
        if police[i].dead then
            table.remove(police, i)
        end
    end


    for _,spawn in ipairs(pendingSpawns) do
        local z = Zombie.new(spawn.x, spawn.y)

        table.insert(zombies, z)
        z.state = z.states.idle
        z.state.enter(z)
        zombieGrid:insert(z)
    end
    pendingSpawns = {} -- clear pending spawns

    if supplies then
        if #supplies < 15 then
            supplySpawnTimer = supplySpawnTimer + dt
            if supplySpawnTimer >= supplySpawnInterval then
                spawnSupply()
                supplySpawnTimer = 0
            end
        end
    end
end

function spawnSupply()
    local maxAttempts = 20
    local w, h = WINDOW_WIDTH, WINDOW_HEIGHT
    for attempt = 1, maxAttempts do
        local x = utility.clamp(love.math.random(0, w),0,WINDOW_WIDTH - 10)
        local y = utility.clamp(love.math.random(0, h),0,WINDOW_HEIGHT - 10)
        local collides = false
        local nearbyBuildings = buildingGrid:getNearby(x, y, 12) -- 12 is a little bigger than supply size
        for _, b in ipairs(nearbyBuildings) do
            if utility.detectNPCBuildingCollision({x = x, y = y, width = 5}, b) then
                collides = true
                break
            end
        end
        if not collides then
            table.insert(supplies, Supply.new(x, y))
            return
        end
    end
    -- If we get here, we failed to find a spot after maxAttempts
end

function love.mousepressed(x, y, button)
    if button == 1 then -- left mouse button
        for i, building in ipairs(buildings) do
            if building.handleClick then
                -- check if clicked the building itself
                building:handleClick(x, y)

                -- check if clicked menu option
                local action = building:handleMenuClick(x, y)
                if action == "buyPolice" then
                    local newBuilding = PoliceSpawner.new(building.x,building.y,building.width,building.height,20)
                    table.insert(buildings,newBuilding)
                    building.selected = false
                    table.remove(buildings,i)-- hide menu after replacement
                    buildingGrid:remove(building)
                    buildingGrid:insert(newBuilding)
                    suppliesCollected = suppliesCollected - policeCost
                    policeCost = policeCost * 10 -- increase cost for next police
                elseif action == "buySpawner" then
                    local newBuilding = SpawnerBuilding.new(building.x,building.y,building.width,building.height,20)
                    table.insert(buildings,newBuilding)
                    building.selected = false
                    table.remove(buildings,i)-- hide menu after replacement
                    buildingGrid:remove(building)
                    buildingGrid:insert(newBuilding)
                    suppliesCollected = suppliesCollected - spawnerCost
                    spawnerCost = spawnerCost  + 5 -- increase cost for next spawner
                end
            end
        end
    end
end

