local utils = require("src.utils")

local asteroids = {
  list = {},
  spawnNext = 0,
  spawnMin = 1,
  spawnMax = 1.4,
  maxCount = 8      -- límite de asteroides vivos para spawns nuevos
}

-- Config por tamaño
local CFG = {
  L = { rmin=50, rmax=65, speedMin=40,  speedMax=80,  segMin=10, segMax=14 },
  M = { rmin=30, rmax=45, speedMin=60,  speedMax=120, segMin=8,  segMax=12 },
  S = { rmin=22, rmax=27, speedMin=90,  speedMax=160, segMin=7,  segMax=10 }
}

local NEXT  = { L="M", M="S" }
local SCORE = { L=20, M=50, S=100 }

-- Polígono irregular de roca (pares x,y)
local function makeRockShape(r, n)
  local pts = {}
  for i = 1, n do
    local ang = (i / n) * (2 * math.pi)
    local rr  = r * utils.randf(0.85, 1.15)
    pts[#pts+1] = math.cos(ang) * rr
    pts[#pts+1] = math.sin(ang) * rr
  end
  return pts
end


-- Crea un asteroide
local function newAsteroid(size, x, y, vx, vy, rOverride)
  local c = CFG[size]
  local r = rOverride or utils.randf(c.rmin, c.rmax)
  local seg = love.math.random(c.segMin, c.segMax)
  return { size=size, x=x, y=y, vx=vx, vy=vy, r=r, ang=utils.randf(0, 2*math.pi),
           spin=utils.randf(-1.2,1.2), shape=makeRockShape(r, seg) }
end

-- Spawnea desde un borde hacia el centro
local function spawnFromEdge(size)
  local w, h = love.graphics.getDimensions()
  local cx, cy = utils.center()
  local c = CFG[size]
  local x, y
  local edge = love.math.random(4)
  if edge == 1 then x, y = -60, utils.randf(0,h)
  elseif edge == 2 then x, y = w+60, utils.randf(0,h)
  elseif edge == 3 then x, y = utils.randf(0,w), -60
  else x, y = utils.randf(0,w), h+60 end
  local baseAng = math.atan2(cy - y, cx - x) + utils.randf(-0.35, 0.35)
  local speed = utils.randf(c.speedMin, c.speedMax)
  local vx, vy = math.cos(baseAng)*speed, math.sin(baseAng)*speed
  asteroids.list[#asteroids.list+1] = newAsteroid(size, x, y, vx, vy)
end

-- Actualiza todos los asteroides
function asteroids.update(dt)
  asteroids.spawnNext = asteroids.spawnNext - dt
  if asteroids.spawnNext <= 0 then
    if #asteroids.list >= asteroids.maxCount then
      asteroids.spawnNext = 0.25
    else
      spawnFromEdge("L")
      asteroids.spawnNext = utils.randf(asteroids.spawnMin, asteroids.spawnMax)
    end
  end
  for i = #asteroids.list, 1, -1 do
    local a = asteroids.list[i]
    a.x, a.y = a.x + a.vx*dt, a.y + a.vy*dt
    a.ang = a.ang + a.spin*dt
    a.x, a.y = utils.wrap(a.x, a.y, a.r)
  end
end

-- Golpe: divide si aplica y devuelve puntos
function asteroids.hit(index)
  local a = asteroids.list[index]; if not a then return 0 end
  local pts = SCORE[a.size] or 0
  local nextSize = NEXT[a.size]
  if nextSize then
    local count = (a.size=="L") and love.math.random(2,3)
               or (a.size=="M") and love.math.random(1,2) or 0
    for _=1,count do
      local c = CFG[nextSize]
      local base = math.atan2(a.vy, a.vx)
      if (a.vx*a.vx + a.vy*a.vy) < 1 then base = utils.randf(0, 2*math.pi) end
      local ang = base + utils.randf(-0.8, 0.8)
      local speed = utils.randf(c.speedMin, c.speedMax)
      local vx, vy = math.cos(ang)*speed, math.sin(ang)*speed
      asteroids.list[#asteroids.list+1] = newAsteroid(nextSize, a.x, a.y, vx, vy)
    end
  end
  table.remove(asteroids.list, index)
  return pts
end

-- Dibuja todos los asteroides
function asteroids.draw()
  love.graphics.setLineWidth(2)
  for _, a in ipairs(asteroids.list) do
    love.graphics.push()
    love.graphics.translate(a.x, a.y)
    love.graphics.rotate(a.ang)
    if (#a.shape % 2) ~= 0 then a.shape[#a.shape] = nil end
    love.graphics.polygon("line", a.shape)
    love.graphics.pop()
  end
end

return asteroids
