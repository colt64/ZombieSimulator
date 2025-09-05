local Supply = {}
Supply.__index = Supply

function Supply.new(x,y)
    local self = setmetatable({}, Supply)
    self.x = x or 0
    self.y = y or 0
    self.width = 10
    self.height = 10
    self.color = {1,1,0}
    self.type = "supply"
    return self
end

function Supply:draw()
    love.graphics.setColor(self.color)
    local h = self.width * math.sqrt(3) / 2
    love.graphics.polygon("fill",
        self.x, self.y,                  -- top
        self.x - self.width/2, self.y + h,  -- bottom left
        self.x + self.width/2, self.y + h   -- bottom right
    )
    love.graphics.setColor(1,1,1)
end

return Supply