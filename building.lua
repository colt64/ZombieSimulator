local utility = require("utility")
local Building = {}
Building.__index = Building


function Building.new(x,y,width,height)
    local self = setmetatable({}, Building)
    self.type = "building"
    self.x = x or 200
    self.y = y or 100
    self.initialx = x or 200
    self.initialy = y or 100
    self.width = width or 75
    self.height = height or 50
    self.color = {0.2,0.2,0.2}
    self.selected = false
    return self
end

function Building:update(dt)
    --No update on default buildings
end

function Building:draw()
    love.graphics.setColor(self.color)
    love.graphics.rectangle("fill",self.x,self.y,self.width,self.height)
end

function Building:resize(w,h)
  --  self.x = utility.clamp(initialx,0,w)
   -- self.y = utility.clamp(initialy,0,h)
--    self.x = utility.clamp(self.initialx,0,w - self.width)
--    self.y = utility.clamp(self.initialy,0,h - self.height)
end

function Building:handleClick(x, y)
    if self:isInside(x, y) then
        for _,b in ipairs(buildings) do
            b.selected = false
        end
        self.selected = not self.selected
        return true
    else
        self.selected = false
        return false
    end
end

function Building:isInside(x, y)
    return x >= self.x and x <= self.x + self.width and y >= self.y and y <= self.y + self.height
end


function Building:drawMenu()
    if not self.selected then 
        return
    end


    local menuX = self.x + self.width + 5
    local menuY = self.y
    local menuWidth = 160
    local menuHeight = 60

    -- clamp so it stays onscreen
    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()

    if menuX + menuWidth > screenW then
        menuX = self.x - menuWidth - 5  -- shift to left of building
    end
    if menuY + menuHeight > screenH then
        menuY = screenH - menuHeight - 5 -- shift up a bit
    end
    if menuY < 0 then
        menuY = 5
    end

    -- background
    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.rectangle("fill", menuX, menuY, menuWidth, menuHeight, 4, 4)

    -- outline
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("line", menuX, menuY, menuWidth, menuHeight, 4, 4)

    -- clear buttons for this frame
    self.menuButtons = {}

    -- option 1: human spawner
    love.graphics.print("Survivor", menuX + 8, menuY + 8)

    local spawnBtnX = menuX + 80
    local spawnBtnY = menuY + 5
    local spawnBtnW = 60
    local spawnBtnH = 20

    if suppliesCollected >= spawnerCost then   
        love.graphics.setColor(1, 1, 1)
    else
        love.graphics.setColor(0.5, 0.5, 0.5) -- gray if can’t afford
    end

    love.graphics.rectangle("line", spawnBtnX, spawnBtnY, spawnBtnW, spawnBtnH)
    love.graphics.print(spawnerCost, spawnBtnX + 5, spawnBtnY + 3)

    table.insert(self.menuButtons, {
        x = spawnBtnX, y = spawnBtnY,
        w = spawnBtnW, h = spawnBtnH,
        action = "buySpawner",
        enabled = (suppliesCollected >= spawnerCost)
    })

    -- option 2: police station
    love.graphics.print("Police", menuX + 8, menuY + 30)

    local policeBtnX = menuX + 80
    local policeBtnY = menuY + 27
    local policeBtnW = 60
    local policeBtnH = 20

    love.graphics.rectangle("line", policeBtnX, policeBtnY, policeBtnW, policeBtnH)
    love.graphics.print(policeCost, policeBtnX + 5, policeBtnY + 3)

    table.insert(self.menuButtons, {
        x = policeBtnX, y = policeBtnY,
        w = policeBtnW, h = policeBtnH,
        action = "buyPolice",
        enabled = (suppliesCollected >= policeCost)
    })
    if suppliesCollected >= policeCost then
        love.graphics.setColor(1, 1, 1)
    else
        love.graphics.setColor(0.5, 0.5, 0.5)
    end
    -- reset color
    love.graphics.setColor(1, 1, 1)
end

function Building:handleMenuClick(mx, my)
    if not self.menuButtons then return nil end
    for _, btn in ipairs(self.menuButtons) do
        if mx >= btn.x and mx <= btn.x + btn.w and
           my >= btn.y and my <= btn.y + btn.h and btn.enabled then
            self.selected = false
            return btn.action
        end
    end
    return nil
end
return Building