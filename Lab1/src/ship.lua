local utils = require("src.utils")

local ship = {
  size = 50, angle = 0,
  x = 0, y = 0, vx = 0, vy = 0,
  thrust = 600, strafe = 450, drag = 0.85, maxSpeed = 420,
  image = nil
}

-- Triángulo fallback (si no hay imagen)
local function drawShipAtOrigin(s)
  love.graphics.setLineWidth(2)
  love.graphics.polygon("line", s,0, -s*0.6,-s*0.5, -s*0.6,s*0.5)
end

-- Set posición
function ship.setPosition(x, y) ship.x, ship.y = x, y end

-- Reset velocidad
function ship.resetVelocity() ship.vx, ship.vy = 0, 0 end

-- Aleja un poco la nave tras colisión
function ship.bumpFrom(dx, dy)
  local len = math.sqrt(dx*dx + dy*dy)
  if len > 0 then local nx, ny = dx/len, dy/len; ship.vx = ship.vx + nx*200; ship.vy = ship.vy + ny*200 end
end

-- Actualiza ángulo hacia el mouse
function ship.updateAngleToMouse()
  local mx, my = love.mouse.getPosition()
  local dx, dy = mx - ship.x, my - ship.y
  if dx ~= 0 or dy ~= 0 then ship.angle = math.atan2(dy, dx) end
end

-- Movimiento WASD con inercia, drag y wrap
function ship.update(dt)
  local cosA, sinA = math.cos(ship.angle), math.sin(ship.angle)
  local fx, fy = cosA, sinA
  local rx, ry = -sinA, cosA
  local forward, strafe = 0, 0
  if love.keyboard.isDown("w") then forward = forward + 1 end
  if love.keyboard.isDown("s") then forward = forward - 1 end
  if love.keyboard.isDown("d") then strafe  = strafe + 1 end
  if love.keyboard.isDown("a") then strafe  = strafe - 1 end
  local ax = fx*(forward*ship.thrust) + rx*(strafe*ship.strafe)
  local ay = fy*(forward*ship.thrust) + ry*(strafe*ship.strafe)
  ship.vx, ship.vy = ship.vx + ax*dt, ship.vy + ay*dt
  ship.vx, ship.vy = ship.vx - ship.vx*ship.drag*dt, ship.vy - ship.vy*ship.drag*dt
  local speed2, max2 = ship.vx*ship.vx + ship.vy*ship.vy, ship.maxSpeed^2
  if speed2 > max2 then local s = ship.maxSpeed/math.sqrt(speed2); ship.vx, ship.vy = ship.vx*s, ship.vy*s end
  ship.x, ship.y = ship.x + ship.vx*dt, ship.y + ship.vy*dt
  ship.x, ship.y = utils.wrap(ship.x, ship.y, ship.size)
end

-- Punto de salida del disparo (punta)
function ship.getMuzzle(cx, cy)
  return cx + math.cos(ship.angle)*ship.size, cy + math.sin(ship.angle)*ship.size
end

-- Dibuja nave (imagen centrada y escalada, o triángulo)
function ship.draw(cx, cy)
  love.graphics.push()
  love.graphics.translate(cx, cy)
  love.graphics.rotate(ship.angle)
  if ship.image then
    local w, h = ship.image:getDimensions()
    local scale = ship.size * 2 / math.max(w, h)
    love.graphics.draw(ship.image, 0, 0, 0, scale, scale, w/2, h/2)
  else
    drawShipAtOrigin(ship.size)
  end
  love.graphics.pop()
end

return ship
