local bullets = {
  list = {},
  speed = 600,
  life = 1.6,
  radius = 20,
  cooldown = 0.5,
  nextTime = 0.5,
  image = nil,
  imageAngleOffset = 0
}

-- Crea una bala
function bullets.spawn(x, y, angle)
  local vx, vy = math.cos(angle)*bullets.speed, math.sin(angle)*bullets.speed
  bullets.list[#bullets.list+1] = { x=x, y=y, vx=vx, vy=vy, t=bullets.life, angle=angle }
end

-- Actualiza balas y limpia las que expiran
function bullets.update(dt)
  local w, h = love.graphics.getDimensions()
  for i = #bullets.list, 1, -1 do
    local b = bullets.list[i]
    b.x, b.y = b.x + b.vx*dt, b.y + b.vy*dt
    b.t = b.t - dt
    if b.t <= 0 or b.x < -20 or b.y < -20 or b.x > w + 20 or b.y > h + 20 then
      table.remove(bullets.list, i)
    end
  end
end

-- Dibuja todas las balas
function bullets.draw()
  if bullets.image then
    local iw, ih = bullets.image:getDimensions()
    local scale = (bullets.radius * 2) / ih
    for _, b in ipairs(bullets.list) do
      local ang = b.angle or math.atan2(b.vy, b.vx)
      love.graphics.draw(bullets.image, b.x, b.y, ang + bullets.imageAngleOffset, scale, scale, iw/2, ih/2)
    end
  else
    for _, b in ipairs(bullets.list) do love.graphics.circle("fill", b.x, b.y, bullets.radius) end
  end
end

return bullets
