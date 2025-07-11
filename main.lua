local NOT_FOUND = love.graphics.newImage("404.png")

Object = {}
Object.__index = Object

function Object:new(o)
	o = o or {}
	setmetatable(o, self)
	return o
end

Rect = Object:new{
	x = 0,
	y = 0,
	w = 0,
	h = 0
}
Rect.__index = Rect

function Rect:intersectsWithRect(other)
	return 	self.x < other.x + other.w and
		self.x + self.w > other.x and
		self.y < other.y + other.h and
		self.y + self.h > other.y
end

function Rect:intersectsWithLine(x1,y1, x2,y2)
  local tmin, tmax = 0, 1
  local dx, dy    = x2 - x1, y2 - y1

  local function clip(p, q)
    if p == 0 then
      if q < 0 then
        return false
      end
      return true
    end
    local t = q / p
    if p < 0 then
      if t > tmax then return false end
      if t > tmin then tmin = t end
    else
      if t < tmin then return false end
      if t < tmax then tmax = t end
    end
    return true
  end

  if not clip(    dx, x1 -   self.x) then return false end
  if not clip(-   dx, self.x + self.w - x1) then return false end
  if not clip(    dy, y1 -   self.y) then return false end
  if not clip(-   dy, self.y + self.h - y1) then return false end

  return true
end

function Rect:centerTo(x, y)
	self.x = x - self.w / 2
	self.y = y - self.h / 2
end

function Rect:centerToRect(other)
	self.x = other.x + other.w / 2 - self.w / 2
	self.y = other.y + other.h / 2 - self.h / 2
end

function Rect:mul(scalar)
	self.w = self.w * scalar
	self.h = self.h * scalar
end

function Rect:getCenter()
	return Vector2:new{x = self.x + self.w / 2, y = self.y + self.h / 2}
end

function Rect:__tostring()
	return "Rect{x = "..self.x..", y = "..self.y..", w = "..self.w..", h = "..self.h.."}"
end

Color = Object:new{
	r = 1,
	g = 1,
	b = 1,
	a = 1
}
Color.__index = Color

TextureRect = Rect:new{
	l2dimage = NOT_FOUND,
	follow_camera = false,
	w = 100,
	h = 100,
	color = Color:new()
}
TextureRect.__index = TextureRect

function TextureRect:new(o)
	o = o or {}
	setmetatable(o, self)
	o.color = o.color or Color:new()
	return o
end

function TextureRect:fromImagePath(path)
	local l2dimage = love.graphics.newImage(path)
	local w, h = l2dimage:getDimensions()
	return self:new{
		l2dimage = l2dimage,
		w = w,
		h = h
	}
end

function TextureRect:render()
	-- iw * sw = rw
	-- sw = rw/iw
	local iw, ih = self.l2dimage:getDimensions()
	local x = self.x
	local y = self.y
	if not self.follow_camera then
		x = x - camera_x + screen_w / 2
		y = y - camera_y + screen_h / 2
	end

	love.graphics.setColor(self.color.r, self.color.g, self.color.b, self.color.a)
	love.graphics.draw(self.l2dimage, x, y, 0, self.w/iw, self.h/ih)
end

RotatedTextureRect = TextureRect:new{
	r = 0
}
RotatedTextureRect.__index = RotatedTextureRect

function RotatedTextureRect:render()
	local iw, ih = self.l2dimage:getDimensions()
	local x = self.x
	local y = self.y
	if not self.follow_camera then
		x = x - camera_x + screen_w / 2
		y = y - camera_y + screen_h / 2
	end

	love.graphics.setColor(self.color.r, self.color.g, self.color.b, self.color.a)
	love.graphics.draw(self.l2dimage, x, y, self.r, self.w/iw, self.h/ih, iw / 2, ih / 2)
end

Bullet = RotatedTextureRect:new{
	speed = 2000,
	distance_traveled = 0,
	max_distance_traveled = 20000
}
Bullet.__index = Bullet

Vector2 = Object:new{
	x = 0,
	y = 0
}
Vector2.__index = Vector2

function Vector2.__add(a, b)
	return Vector2:new{x = a.x + b.x, y = a.y + b.y}
end

function Vector2.__sub(a, b)
	return Vector2:new{x = a.x - b.x, y = a.y - b.y}
end

function Vector2.__mul(a, b)
	if type(b) == "table" then
		return Vector2:new{x = a.x * b.x, y = a.y * b.y}
	end
	return Vector2:new{x = a.x * b, y = a.y * b}
end

function Vector2.__div(a, b)
	if type(b) == "table" then
		return Vector2:new{x = a.x / b.x, y = a.y / b.y}
	end
	return Vector2:new{x = a.x / b, y = a.y / b}
end

function Vector2.__unm(a)
	return Vector2:new{x = -a.x, y = -a.y}
end

function Vector2:getMagnitude()
	return math.sqrt(self.x^2 + self.y^2)
end

function Vector2:angleTo(other)
	return math.atan2(other.y - self.y, other.x - self.x)
end

function Vector2:directionTo(other)
	local d = (other - self)
	return d / d:getMagnitude()
end

function Vector2:distanceTo(other)
	return (other - self):getMagnitude()
end

Enemy = Object:new{
	collider = Rect:new{
		x = 0,
		y = 0,
		w = 200,
		h = 200
	},
	textures = {
		up = {
			love.graphics.newImage("uugeli/uugeliup1.png"),
			love.graphics.newImage("uugeli/uugeliup2.png")
		},
		down = {
			love.graphics.newImage("uugeli/uugelidown1.png"),
			love.graphics.newImage("uugeli/uugelidown2.png")
		},
		left = {
			love.graphics.newImage("uugeli/uugelileft1.png"),
			love.graphics.newImage("uugeli/uugelileft2.png")
		},
		right = {
			love.graphics.newImage("uugeli/uugeliright1.png"),
			love.graphics.newImage("uugeli/uugeliright2.png")
		}
	},
	textureRect = TextureRect:new(),
	velocity = Vector2:new(),
	acceleration = Vector2:new(),
	speed = 7000,
	mass = 16,
	drag = 0.4,
	current_frame = 1,
	animation_fps = 24,
	time_until_next_frame = 1/24,
	redness = 0,
	health = 3
}
Enemy.__index = Enemy

function Enemy:new(o)
	o = o or {}

	o.collider = o.collider or Rect:new{x = Enemy.collider.x, y = Enemy.collider.y, w = Enemy.collider.w, h = Enemy.collider.h}
	o.textureRect = o.textureRect or TextureRect:new{w = 200, h = 200}
	o.velocity = o.velocity or Vector2:new()
	o.acceleration = o.acceleration or Vector2:new()
	o.animation_fps = o.animation_fps or 24
	o.time_until_next_frame = 1 / o.animation_fps

	setmetatable(o, self)
	return o
end

function Enemy:getPosition()
	return Vector2:new{x = self.collider.x, y = self.collider.y}
end


function randomFloat(min, max)
	return min + math.random() * (max - min)
end

--[[function getOffsets(image, scale)
	scale = scale or 1
	local w, h = image:getDimensions()
	x = -w * scale / 2
	y = -h * scale / 2
	return x, y
end

function loadPImage(path, scale) 
	image = love.graphics.newImage(path)
	local w, h = image:getDimensions()
	return {
		image = image,
		scale = scale,
		offset_x = -w * scale / 2,
		offset_y = -h * scale / 2
	}
end]]

function love.resize(w, h)
	screen_w = w
	screen_h = h
end

function love.load()
	math.randomseed(os.time())

	crosshair = TextureRect:fromImagePath("crossgair.png")
	crosshair.follow_camera = true
	crosshair.w = 25
	crosshair.h = 25
	crosshair.color = Color:new{r = 0, g = 0, b = 0}

	player_texture = TextureRect:fromImagePath("kitty.png")
	player_texture:mul(0.25)

	player_original_w = player_texture.w
	player_original_h = player_texture.h

	player_x = 200
	player_y = 200
	player_speed = 200

	player_dead = false

	camera_x = player_x
	camera_y = player_y

	screen_w, screen_h = love.graphics.getDimensions()

	font = love.graphics.newFont(100, "normal", love.graphics.getDPIScale())

	melons = {}
	static_objects = {}
	bullets = {}
	enemies = {}

	seeds = 0

	begin()

	shoot_sound = love.audio.newSource("blowgun.mp3", "stream")
	shoot_sound:setVolume(1.2)

	player_death_sound = love.audio.newSource("player_death.wav", "static")

	chomp_sounds = {}
	for i, v in pairs(love.filesystem.getDirectoryItems("chomps")) do
		chomp_sounds[i] = love.audio.newSource("chomps/"..v, "static")
	end

	enemy_death_sounds = {}
	for i, v in pairs(love.filesystem.getDirectoryItems("vihollinenkuolee")) do
		enemy_death_sounds[i] = love.audio.newSource("vihollinenkuolee/"..v, "static")
	end

	deadpeople = {}
	for i, v in pairs(love.filesystem.getDirectoryItems("deadpeople")) do
		deadpeople[i] = love.graphics.newImage("deadpeople/"..v)
	end

	rpm = 60 * 8
	time_since_last_shot = 0

	love.mouse.setVisible(false)
	love.graphics.setBackgroundColor(1, 1, 1)

	epics = {}
	current_epic = 1
	loadEpics()
end

function loadEpics()
	for line in love.filesystem.lines("epics.txt") do
		table.insert(epics, line)
	end
end

function begin()
	melons = {}
	newMelon()
	static_objects = {}
	bullets = {}
	enemies = {}

	for _=1,10 do
		newEnemy()
	end

	player_x = 200
	player_y = 200
	player_speed = 200

	player_max_stamina = 5
	player_stamina = player_max_stamina

	player_dead = false
	seeds = 0

	victory_animation_t = 0
	victory_sound = love.audio.newSource("VICTORY.wav", "static")
end

local just_pressed = {}

function justPressed(key)
	return just_pressed[key] ~= nil
end

function love.keypressed(key, scancode, isrepeat)
	if not isrepeat then
		just_pressed[key] = true
	end
end

function newMelon()
	local melon = TextureRect:fromImagePath("melone.png")
	melon:mul(0.1)
	local dist = 500
	melon:centerTo(math.random(-dist, dist), math.random(-dist, dist))
	table.insert(melons, melon)
end

function newEnemy()
	local enemy = Enemy:new{}
	local dist = 7500
	enemy.collider.x = math.random(-dist, dist)
	enemy.collider.y = math.random(-dist, dist)
	enemy.speed = enemy.speed + math.random(-3000, 3000)
	enemy.mass = enemy.mass + randomFloat(-4, 4)
	enemy.drag = enemy.drag + randomFloat(-0.3, 0.3)
	table.insert(enemies, enemy)
end

function playChompSound()
	local sound = chomp_sounds[math.random(1, #chomp_sounds)]
	sound:setPitch(randomFloat(0.9, 1.1))
	sound:stop()
	sound:play()
end

function isAnyDown(keys)
	for _, v in pairs(keys) do
		if love.keyboard.isDown(v) then return true end
	end
	return false
end

function love.update(dt)
	time_since_last_shot = time_since_last_shot + dt

	if #enemies == 0 then
		victory_animation_t = victory_animation_t + dt / 24
		victory_animation_t = math.min(1, victory_animation_t)

		if not victory_sound:isPlaying() then
			victory_sound:play()
		end

		for _, sound in pairs(enemy_death_sounds) do
			sound:stop()
		end
		return
	end
	if player_dead then
		if justPressed("r") then
			player_death_sound:setPitch(randomFloat(0.5, 1.5))
			player_death_sound:stop()
			begin()
		else
			goto continue
		end
	end
	if not player_exhausted and love.keyboard.isDown("lshift") and isAnyDown({"w","a","s","d"}) then
		player_speed = 800
		player_stamina = player_stamina - dt
		if player_stamina <= 0 then
			player_exhausted = true
		end
	else
		player_stamina = player_stamina + dt / 2
		player_speed = 400
	end

	if player_exhausted then
		player_stamina = player_stamina + dt
		if player_stamina >= player_max_stamina then
			player_exhausted = false
		end
	end

	player_stamina = math.min(player_max_stamina, math.max(0, player_stamina))

	if (love.keyboard.isDown("w")) then
		player_y = player_y - player_speed * dt
	end
	if (love.keyboard.isDown("s")) then
		player_y = player_y + player_speed * dt
	end
	if (love.keyboard.isDown("a")) then
		player_x = player_x - player_speed * dt
	end
	if (love.keyboard.isDown("d")) then
		player_x = player_x + player_speed * dt
	end

	if love.mouse.isDown(1) and seeds > 0 and time_since_last_shot >= 60 / rpm then
		time_since_last_shot = 0
		shoot_sound:setPitch(randomFloat(1, 1.2))
		shoot_sound:stop()
		shoot_sound:play()

		seeds = seeds - 1

		local mouse_x, mouse_y = love.mouse.getPosition()
		local bullet = Bullet:fromImagePath("sedward.png")
		bullet:mul(0.1)
		bullet:centerToRect(player_texture)
		bullet.r = math.atan2((bullet.y - (mouse_y - screen_h / 2 + camera_y)), (bullet.x - (mouse_x - screen_w / 2 + camera_x))) + math.pi

		table.insert(bullets, bullet)
	end

	camera_x = player_x
	camera_y = player_y

	for i,melon in pairs(melons) do
		if player_texture:intersectsWithRect(melon) and justPressed("space") then
			local splat = RotatedTextureRect:fromImagePath("splat.png")
			splat:mul(0.25)
			splat:centerToRect(melon)
			splat.r = randomFloat(0, math.pi * 2)
			table.insert(static_objects, splat)
			table.remove(melons, i)
			newMelon()

			playChompSound()

			seeds = seeds + math.random(2, 5)
		end
	end

	for _, enemy in pairs(enemies) do
		local player_pos = Vector2:new{x = player_x, y = player_y}
		local force = enemy.collider:getCenter():directionTo(player_pos) * enemy.speed
		enemy.acceleration = force / enemy.mass
		enemy.velocity = enemy.velocity + enemy.acceleration * dt
		enemy.velocity = enemy.velocity * (1 - enemy.drag * dt)
		enemy.collider.x = enemy.collider.x + enemy.velocity.x * dt
		enemy.collider.y = enemy.collider.y + enemy.velocity.y * dt


		enemy.textureRect.x = enemy.collider.x -- - enemy.textureRect.w / 2 + enemy.collider.w / 2
		enemy.textureRect.y = enemy.collider.y -- - enemy.textureRect.h  + enemy.collider.h

		local angle = enemy.collider:getCenter():angleTo(player_pos)
		if angle < 0 then angle = angle + 2 * math.pi end

		local dir
		if angle < math.pi / 4 then dir = "right"
		elseif angle < 3 * math.pi / 4 then dir = "down"
		elseif angle < 5 * math.pi / 4 then dir = "left"
		elseif angle < 7 * math.pi / 4 then dir = "up"
		else dir = "right"
		end

		if enemy.time_until_next_frame <= 0 then
			enemy.current_frame = enemy.current_frame + 1
			enemy.current_frame = enemy.current_frame % #Enemy.textures[dir]
			enemy.time_until_next_frame = 1 / enemy.animation_fps
		end
		enemy.time_until_next_frame = enemy.time_until_next_frame - dt
		enemy.textureRect.l2dimage = Enemy.textures[dir][enemy.current_frame + 1]

		enemy.redness = enemy.redness - dt * 3
		enemy.redness = math.max(0, math.min(enemy.redness, 1))
		enemy.textureRect.color = Color:new{r = 1, g = 1 - enemy.redness, b = 1 - enemy.redness}

		if enemy.collider:intersectsWithRect(player_texture) then
			player_dead = true
			player_death_sound:play()
			current_epic = math.random(1, #epics)
		end
	end

	for i, bullet in pairs(bullets) do
		local old_x = bullet.x
		local old_y = bullet.y
		bullet.x = bullet.x + math.cos(bullet.r) * dt * bullet.speed
		bullet.y = bullet.y + math.sin(bullet.r) * dt * bullet.speed

		for j, enemy in pairs(enemies) do
			if enemy.collider:intersectsWithLine(old_x, old_y, bullet.x, bullet.y) then
				enemy.health = enemy.health - 1
				enemy.redness = enemy.redness + 0.5
				if enemy.health <= 0 then
					local sound = enemy_death_sounds[math.random(1, #enemy_death_sounds)]
					sound:setPitch(randomFloat(0.25, 1.75))
					sound:play()

					local deadperson = RotatedTextureRect:new{
						l2dimage = deadpeople[math.random(1, #deadpeople)],
						w = 200,
						h = 200,
						r = randomFloat(0, math.pi*2)
					}
					deadperson:centerToRect(enemy.textureRect)
					table.insert(static_objects, deadperson)
					table.remove(enemies, j)
				end
				table.remove(bullets, i)
				goto continue
			end
		end

		local dist = math.sqrt((bullet.x - old_x)^2 + (bullet.y - old_y)^2)
		bullet.distance_traveled = bullet.distance_traveled + dist
		if bullet.distance_traveled > bullet.max_distance_traveled then
			table.remove(bullets, i)
		end
		::continue::
	end

	just_pressed = {}

	::continue::
end

--[[
	RENDERING
]]

function renderText(str, x, y, scale, r)
	scale = scale or 1
	r = r or 0
	local text = love.graphics.newText(font, str)
	love.graphics.draw(text, x, y, r, scale)
end

function renderTextCentered(str, x, y, scale, r)
	scale = scale or 1
	r = r or 0
	local text = love.graphics.newText(font, str)
	local w, h = text:getDimensions()
	w = w * scale
	h = h * scale
	love.graphics.draw(text, x - w / 2, y - h / 2, r, scale)
end

function love.draw()
	for _, object in pairs(static_objects) do
		object:render()
	end

	for _, melon in pairs(melons) do
		melon:render()
	end

	for _, enemy in pairs(enemies) do
		enemy.textureRect:render()
	end

	love.graphics.setColor(1, 1, 1)

	if #enemies == 0 then
		player_texture.w = player_original_w + (screen_w - player_original_w) * victory_animation_t
		player_texture.h = player_original_h + (screen_h - player_original_h) * victory_animation_t
		player_texture:centerTo(player_x, player_y)
		player_texture:render()
		return
	end
	player_texture:centerTo(player_x, player_y)
	player_texture:render()

	love.graphics.setColor(0, 0, 1)
	for _, melon in pairs(melons) do
		if melon:intersectsWithRect(player_texture) and not player_dead then
			renderTextCentered("syö", screen_w / 2, screen_h / 2)
		end
	end

	for _, bullet in pairs(bullets) do
		bullet:render()
	end

	local mouse_x, mouse_y = love.mouse.getPosition()
	crosshair:centerTo(mouse_x, mouse_y)
	crosshair:render()

	if player_dead then
		love.graphics.setColor(1, 0, 0)
		local death_text = love.graphics.newText(font, epics[current_epic])
		local w, h = death_text:getDimensions()
		local scale = 1
		if w > screen_w * 0.8 then
			scale = screen_w * 0.8 / w
		end
		w = w * scale
		love.graphics.draw(death_text, screen_w / 2 - w / 2, screen_h / 2 - h / 2, 0, scale)

		love.graphics.setColor(0, 0, 1)
		renderTextCentered("pressings the r to restarting", screen_w / 2, screen_h / 3 * 2, 0.25)
	end

	love.graphics.setColor(0, 0, 0)
	renderText("Seeds: "..seeds, screen_w / 20, screen_w / 20, 0.5)

	if not player_exhausted then
		love.graphics.setColor((player_max_stamina - player_stamina) / player_max_stamina, player_stamina / player_max_stamina, 0)
	else
		love.graphics.setColor(0, 0, 0)
	end
	love.graphics.rectangle("fill", screen_w - 50 - 300, 50, 300 * (player_stamina / player_max_stamina), 35)
end
