local utils = {}

-- Centro de pantalla
function utils.center() local w,h = love.graphics.getDimensions(); return w/2, h/2 end

-- Random float en [a,b]
function utils.randf(a,b) return a + (b - a) * love.math.random() end

-- Wrap (aparece al lado opuesto)
function utils.wrap(x,y,r)
  local w,h = love.graphics.getDimensions()
  if x < -r then x = w + r elseif x > w + r then x = -r end
  if y < -r then y = h + r elseif y > h + r then y = -r end
  return x,y
end

return utils
