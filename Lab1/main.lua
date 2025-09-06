local utils     = require("src.utils")
local ship      = require("src.ship")
local bullets   = require("src.bullets")
local asteroids = require("src.asteroids")

-- Texto para la pantalla de pausa
local INSTRUCTIONS = [[
CONTROLES
  Mouse  : apuntas
  Click  : disparas
  W/A/S/D: moverte con inercia
  P      : pausar / reanudar
  R      : reiniciar
]]

local time = 0

-- Estado de juego
local game = {
  score = 0, lives = 3, paused = false, over = false,
  showInstructions = true, showCredits = false
}

-- Recursos
local sounds, images = {}, {}

-- Constantes de daño/seguridad
local INV_TIME = 2.0
ship.invuln = 0
ship.radius = ship.size * 0.6

-- Reinicia todo
local function resetGame()
  game.score, game.lives, game.over, game.paused = 0, 3, false, false
  game.showInstructions = false
  bullets.list, asteroids.list = {}, {}
  ship.invuln = 0
  local cx, cy = utils.center()
  ship.setPosition(cx, cy)
  ship.resetVelocity()
end

-- Carga inicial
function love.load()
  love.window.setTitle("Asteroids — Modular")
  love.window.setMode(1000, 600, { resizable = true, vsync = true, minwidth = 640, minheight = 360 })
  love.graphics.setBackgroundColor(0, 0, 0)
  love.math.setRandomSeed(os.time())

  sounds.music     = love.audio.newSource("StarWars8Bits.mp3", "stream")
  sounds.blaster   = love.audio.newSource("blaster.wav", "static")
  sounds.explosion = love.audio.newSource("asteroidExplosion.wav", "static")
  sounds.music:setLooping(true); sounds.music:setVolume(0.6)
  sounds.blaster:setVolume(0.8); sounds.explosion:setVolume(0.9)

  images.ship    = love.graphics.newImage("shipStarWars.png")
  images.blaster = love.graphics.newImage("blaster.png")

  ship.image = images.ship
  bullets.image = images.blaster
  bullets.imageAngleOffset = math.pi / 2   -- rota el sprite del láser 90°

  love.audio.play(sounds.music)

  local cx, cy = utils.center()
  ship.setPosition(cx, cy)
  ship.resetVelocity()
end

-- Centro de pantalla para overlays
local function screenCenter() return utils.center() end

-- Dispara una bala desde la punta de la nave
local function fireNow()
  if game.paused or game.over then return end
  local mx, my = ship.getMuzzle(ship.x, ship.y)
  bullets.spawn(mx, my, ship.angle)
  sounds.blaster:stop(); love.audio.play(sounds.blaster)
end

-- Entrada de teclado
function love.keypressed(key)
  if key == "space" or key == "return" then
    if game.showInstructions then game.showInstructions = false; return end
    if game.showCredits then game.showCredits = false; return end
  end
  if key == "c" and not game.over and not game.showInstructions then
    game.showCredits = not game.showCredits
    game.paused = game.showCredits
  elseif key == "p" and not game.over and not game.showInstructions and not game.showCredits then
    game.paused = not game.paused
  elseif key == "r" then
    resetGame()
  end
end

-- Entrada de mouse
function love.mousepressed(_, _, button)
  if button ~= 1 then return end
  if game.showInstructions then game.showInstructions = false; return end
  if game.showCredits then game.showCredits = false; game.paused = false; return end
  if not game.paused and not game.over then
    fireNow()
    bullets.nextTime = time + bullets.cooldown
  end
end

-- Lógica de juego por frame
function love.update(dt)
  time = time + dt
  ship.updateAngleToMouse()
  if game.showInstructions or game.showCredits or game.paused or game.over then return end

  ship.update(dt)
  if ship.invuln > 0 then ship.invuln = math.max(0, ship.invuln - dt) end

  if love.mouse.isDown(1) and time >= bullets.nextTime then
    fireNow(); bullets.nextTime = time + bullets.cooldown
  end

  bullets.update(dt)
  asteroids.update(dt)

  -- Colisiones bala-asteroide
  for i = #asteroids.list, 1, -1 do
    local a = asteroids.list[i]
    local ar2 = (a.r + bullets.radius)^2
    for j = #bullets.list, 1, -1 do
      local b = bullets.list[j]
      local dx, dy = a.x - b.x, a.y - b.y
      if dx*dx + dy*dy <= ar2 then
        local pts = asteroids.hit(i); game.score = game.score + (pts or 0)
        table.remove(bullets.list, j)
        sounds.explosion:stop(); love.audio.play(sounds.explosion)
        break
      end
    end
  end

  -- Colisión nave-asteroide
  if ship.invuln <= 0 then
    for i = 1, #asteroids.list do
      local a = asteroids.list[i]
      local dx, dy = a.x - ship.x, a.y - ship.y
      local rr = a.r + ship.radius
      if dx*dx + dy*dy <= rr*rr then
        game.lives = game.lives - 1; ship.invuln = INV_TIME; ship.bumpFrom(dx, dy)
        if game.lives <= 0 then game.over = true; game.paused = true end
        break
      end
    end
  end
end

-- Dibujo por frame
function love.draw()
  local w = love.graphics.getWidth()
  local scx, scy = screenCenter()

  love.graphics.setColor(1,1,1)
  love.graphics.print(("Puntos: %d"):format(game.score), 16, 12)
  love.graphics.printf(("Vidas: %d"):format(game.lives), 0, 12, w - 16, "right")

  if ship.invuln > 0 then
    local blink = (math.floor(time * 10) % 2 == 0)
    love.graphics.setColor(1,1,1, blink and 1 or 0.25)
  else
    love.graphics.setColor(1,1,1,1)
  end
  ship.draw(ship.x, ship.y)
  love.graphics.setColor(1,1,1,1)

  bullets.draw()
  asteroids.draw()

  if game.showInstructions then
    love.graphics.setColor(0,0,0,0.8); love.graphics.rectangle("fill", 0,0, w, love.graphics.getHeight())
    love.graphics.setColor(1,1,1)
    local txt = [[
ASTEROIDS - INSTRUCCIONES

OBJETIVO: Destruye asteroides para ganar puntos

CONTROLES:
• Mouse: Apuntar
• Clic: Disparar
• WASD: Mover
• P: Pausar
• R: Reiniciar

PUNTOS:
• Grande 20 • Mediano 50 • Pequeño 100

PRESIONA ESPACIO O CLICK PARA COMENZAR
(C para ver créditos)]]
    love.graphics.printf(txt, 0, scy - 200, w, "center")
  elseif game.showCredits then
    love.graphics.setColor(0,0,0,0.8); love.graphics.rectangle("fill", 0,0, w, love.graphics.getHeight())
    love.graphics.setColor(1,1,1)
    local credits = [[
ASTEROIDS - CRÉDITOS

DESARROLLO:
• Programado en LÖVE 2D (Love2D)
• Arquitectura modular en Lua

RECURSOS DE AUDIO:
• Explosión de asteroide:
  https://freesound.org/people/runningmind/sounds/387858/

• Sonido de blaster:
  https://freesound.org/people/jradcoolness/sounds/334224/

• Tema musical 8-bits:
  https://www.youtube.com/watch?v=bOYdk1UY5o8

GRÁFICOS:
• Nave Star Wars
• Sprites de blaster

¡Gracias por jugar!

PRESIONA ESPACIO O CLICK PARA VOLVER]]
    love.graphics.printf(credits, 0, scy - 180, w, "center")
  elseif game.paused and not game.over then
    love.graphics.setColor(0,0,0,0.5); love.graphics.rectangle("fill", 0,0, w, love.graphics.getHeight())
    love.graphics.setColor(1,1,1)
    love.graphics.printf("PAUSA", 0, scy - 80, w, "center")
    love.graphics.printf(INSTRUCTIONS, 0, scy - 40, w, "center")
  elseif game.over then
    love.graphics.setColor(0,0,0,0.6); love.graphics.rectangle("fill", 0,0, w, love.graphics.getHeight())
    love.graphics.setColor(1,1,1)
    love.graphics.printf(("GAME OVER\nPuntos: %d\n(R para reiniciar)"):format(game.score), 0, scy - 40, w, "center")
  end
end
