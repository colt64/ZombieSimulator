local utility = require("utility")
local Building = require("building")

local TownHall  = setmetatable({}, { __index = Building })
TownHall.__index = TownHall



function TownHall.new(x,y,width,height)
    local self = setmetatable(Building.new(x, y,width, height), TownHall)
    
    self.x = x or 200
    self.y = y or 100
    self.initialx = x or 200
    self.initialy = y or 100
    self.width = width or 75
    self.height = height or 50
    self.color = {0.2,0.2,0.2}
    return self
end

function TownHall:update(dt)
    --No update on default buildings
end

function TownHall:draw()
    --draw the steps part
    love.graphics.setColor(self.color)
    love.graphics.rectangle("fill",self.x + 10,self.y,self.width - 20 ,self.height,20,20)
    love.graphics.setColor({0,0,0})
    love.graphics.rectangle("line",self.x + 10,self.y,self.width - 20 ,self.height,20,20)
        
        --draw the main building part
    love.graphics.setColor(self.color)
    love.graphics.rectangle("fill",self.x,self.y + 30,self.width ,self.height - 30,20,20)
    love.graphics.setColor({0,0,0})
    love.graphics.rectangle("line",self.x,self.y + 30,self.width ,self.height - 30,20,20)
    
    
    --draw the dome part
    love.graphics.setColor(self.color)
    love.graphics.circle("fill",self.x + self.width/2, self.y + self.height/2,self.height/4)
    love.graphics.setColor({0,0,0})
    love.graphics.circle("line",self.x + self.width/2, self.y + 10 + self.height/2,self.height/4)
    love.graphics.circle("line",self.x + self.width/2, self.y + 10 + self.height/2,self.height/8)
    
    --draw the stairs

    love.graphics.setColor({0,0,0})
    love.graphics.line(self.x + 15, self.y + 10, self.x + self.width - 15, self.y + 10)
    love.graphics.line(self.x + 15, self.y + 17, self.x + self.width - 15, self.y + 17)
    love.graphics.line(self.x + 15, self.y + 23, self.x + self.width - 15, self.y + 23)
    -- love.graphics.line(self.x + 15, self.y + 25, self.x + self.width - 15, self.y + 25)
end

function TownHall:resize(w,h)
  --  self.x = utility.clamp(initialx,0,w)
   -- self.y = utility.clamp(initialy,0,h)
   self.x = utility.clamp(self.initialx,0,w - self.width)
   self.y = utility.clamp(self.initialy,0,h - self.height)
end

return TownHall