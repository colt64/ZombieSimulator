local utility = {}

function utility.clamp(val, min, max)
    if val < min then return min end
    if val > max then return max end
    return val
end

function utility.detectNPCBuildingCollision(circle, rect)
    -- find closest point on the rectangle to the circle center
    local closestX = math.max(rect.x, math.min(circle.x, rect.x + rect.width))
    local closestY = math.max(rect.y, math.min(circle.y, rect.y + rect.height))
    
    -- calculate distance from circle center to closest point
    local dx = circle.x - closestX
    local dy = circle.y - closestY
    
    return (dx*dx + dy*dy) < (circle.width * circle.width)
end

function utility.detectNPCCollision(circle1, circle2)
    local dx = circle1.x - circle2.x
    local dy = circle1.y - circle2.y
    local distanceSquared = dx * dx + dy * dy
    local radiusSum = circle1.width + circle2.width
    return distanceSquared < (radiusSum * radiusSum)
end

function utility.getDistance(x1, y1, x2, y2)
    local dx = x2 - x1
    local dy = y2 - y1
    return math.sqrt(dx * dx + dy * dy)
end

function utility.contains(tbl, value)
    for _, v in ipairs(tbl) do
        if v == value then
            return true
        end
    end
    return false
end


function utility.detectBulletCollision(b, npcs)
        if b.alive then
            for _, npc in ipairs(npcs) do
                if not npc.dead then
                    local dx = npc.x - b.x
                    local dy = npc.y - b.y
                    local dist2 = dx*dx + dy*dy
                    local hitRadius = 10 -- tweak per sprite size

                    if dist2 < hitRadius*hitRadius then
                        b.alive = false
                        npc.dead = true
                        break
                    end
                end
            end
        end
end

function utility.visionBlocked(x1, y1, x2, y2, rx, ry, rw, rh)
    -- rectangle edges
    local left   = rx
    local right  = rx + rw
    local top    = ry
    local bottom = ry + rh

    -- helper: check line intersection
    local function linesIntersect(x1,y1,x2,y2, x3,y3,x4,y4)
        local denom = (y4 - y3)*(x2 - x1) - (x4 - x3)*(y2 - y1)
        if denom == 0 then return false end -- parallel
        local ua = ((x4 - x3)*(y1 - y3) - (y4 - y3)*(x1 - x3)) / denom
        local ub = ((x2 - x1)*(y1 - y3) - (y2 - y1)*(x1 - x3)) / denom
        return ua >= 0 and ua <= 1 and ub >= 0 and ub <= 1
    end

    -- check against all 4 edges of rect
    if linesIntersect(x1,y1,x2,y2, left,top, right,top)   then return true end
    if linesIntersect(x1,y1,x2,y2, right,top, right,bottom) then return true end
    if linesIntersect(x1,y1,x2,y2, right,bottom, left,bottom) then return true end
    if linesIntersect(x1,y1,x2,y2, left,bottom, left,top) then return true end

    return false
end

-- Spatial Grid for efficient neighbor/building queries
utility.SpatialGrid = {}
utility.SpatialGrid.__index = utility.SpatialGrid

function utility.SpatialGrid.new(cellSize, width, height)
    local self = setmetatable({}, utility.SpatialGrid)
    self.cellSize = cellSize or 32
    self.width = width or 748
    self.height = height or 748
    self.cells = {}
    return self
end

function utility.SpatialGrid:clear()
    self.cells = {}
end

function utility.SpatialGrid:_cellCoords(x, y)
    -- Ignore dead region: (384,359)-(748,748)
    if x >= 384 and y >= 359 then
        return nil, nil
    end
    local cx = math.floor(x / self.cellSize)
    local cy = math.floor(y / self.cellSize)
    return cx, cy
end

function utility.SpatialGrid:_cellKey(cx, cy)
    return cx .. "," .. cy
end

function utility.SpatialGrid:insert(obj)
    local cx, cy = self:_cellCoords(obj.x, obj.y)
    if not cx or not cy then return end
    local key = self:_cellKey(cx, cy)
    if not self.cells[key] then self.cells[key] = {} end
    table.insert(self.cells[key], obj)
    obj._gridCell = key
end

function utility.SpatialGrid:remove(obj)
    if obj._gridCell and self.cells[obj._gridCell] then
        for i, o in ipairs(self.cells[obj._gridCell]) do
            if o == obj then
                table.remove(self.cells[obj._gridCell], i)
                break
            end
        end
        obj._gridCell = nil
    end
end

function utility.SpatialGrid:update(obj, oldX, oldY)
    local oldCx, oldCy = self:_cellCoords(oldX, oldY)
    local newCx, newCy = self:_cellCoords(obj.x, obj.y)
    if oldCx ~= newCx or oldCy ~= newCy then
        self:remove(obj)
        self:insert(obj)
    end
end

function utility.SpatialGrid:getNearby(x, y, radius)
    local cx, cy = self:_cellCoords(x, y)
    if not cx or not cy then return {} end
    local results = {}
    local r = math.ceil((radius or 0) / self.cellSize)
    for dx = -r, r do
        for dy = -r, r do
            local nx, ny = cx + dx, cy + dy
            local key = self:_cellKey(nx, ny)
            if self.cells[key] then
                for _, obj in ipairs(self.cells[key]) do
                    table.insert(results, obj)
                end
            end
        end
    end
    return results
end

function utility.sign(number)
    -- dont want it returning zero so returns -1 instead
    return number > 0 and 1 or -1
end

return utility
