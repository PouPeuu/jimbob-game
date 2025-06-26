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

function Rect:intersectsWithLine(x1, y1, x2, y2)
	
end

function Rect:centerTo(x, y)
	self.x = x - self.w / 2
	self.y = y - self.h / 2
end

function Rect:centerToRect(other)
	self.x = other.x + other.w / 2
	self.y = other.y + other.h / 2
end

function Rect:mul(scalar)
	self.w = self.w * scalar
	self.h = self.h * scalar
end

TextureRect = Rect:new{
	l2dimage = NOT_FOUND,
	follow_camera = true
}
TextureRect.__index = TextureRect

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
	love.graphics.draw(self.l2dimage, x, y, self.r, self.w/iw, self.h/ih, iw / 2, ih / 2)
end

Bullet = RotatedTextureRect:new{
	speed = 2000,
	distance_traveled = 0,
	max_distance_traveled = 3000
}
Bullet.__index = Bullet


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
	crosshair = TextureRect:fromImagePath("crossgair.png")
	crosshair.w = 25
	crosshair.h = 25

	player_texture = TextureRect:fromImagePath("kitty.png")
	player_texture.follow_camera = false
	player_texture:mul(0.25)

	player_x = 200
	player_y = 200
	player_speed = 200

	camera_x = player_x
	camera_y = player_y

	screen_w, screen_h = love.graphics.getDimensions()

	font = love.graphics.newFont(100, "normal", love.graphics.getDPIScale())

	melons = {}
	newMelon()

	static_objects = {}

	bullets = {}

	seeds = 0

	shoot_sound = love.audio.newSource("blowgun.mp3", "stream")
	shoot_sound:setVolume(1.2)

	chomp_sounds = {
		 "1.mp3",
		 "2.mp3"
	}

	for i, v in pairs(chomp_sounds) do
		chomp_sounds[i] = love.audio.newSource("chomps/"..v, "stream")
	end

	rpm = 60 * 4
	time_since_last_shot = 0

	love.mouse.setVisible(false)
	love.graphics.setBackgroundColor(1, 1, 1)
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
	melon = TextureRect:fromImagePath("melone.png")
	melon.follow_camera = false
	melon:mul(0.1)
	local dist = 500
	melon:centerTo(math.random(-dist, dist), math.random(-dist, dist))
	table.insert(melons, melon)
end

function playChompSound()
	local sound = chomp_sounds[math.random(1, #chomp_sounds)]
	sound:setPitch(randomFloat(0.9, 1.1))
	sound:play()
end

function love.update(dt)
	time_since_last_shot = time_since_last_shot + dt

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
		shoot_sound:setPitch(randomFloat(0.9, 1.1))
		shoot_sound:play()

		seeds = seeds - 1

		local mouse_x, mouse_y = love.mouse.getPosition()
		local bullet = Bullet:fromImagePath("sedward.png")
		bullet:centerToRect(player_texture)
		bullet.follow_camera = false
		bullet:mul(0.1)
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
			splat.follow_camera = false
			table.insert(static_objects, splat)
			table.remove(melons, i)
			newMelon()

			playChompSound()

			seeds = seeds + math.random(2, 5)
		end
	end

	for i, bullet in pairs(bullets) do
		local old_x = bullet.x
		local old_y = bullet.y
		bullet.x = bullet.x + math.cos(bullet.r) * dt * bullet.speed
		bullet.y = bullet.y + math.sin(bullet.r) * dt * bullet.speed

		local dist = math.sqrt((bullet.x - old_x)^2 + (bullet.y - old_y)^2)
		bullet.distance_traveled = bullet.distance_traveled + dist
		if bullet.distance_traveled > bullet.max_distance_traveled then
			table.remove(bullets, i)
		end
	end

	just_pressed = {}
end

--[[
	RENDERING
]]

function renderTextCentered(str, x, y, scale)
	scale = scale or 1
	local text = love.graphics.newText(font, str)
	local w, h = text:getDimensions()
	w = w * scale
	h = h * scale
	love.graphics.draw(text, x - w / 2, y - h / 2, 0, scale)
end

function love.draw()
	love.graphics.setColor(1, 1, 1)
	
	for _, object in pairs(static_objects) do
		object:render()
	end

	for _, melon in pairs(melons) do
		melon:render()
	end

	player_texture:centerTo(player_x, player_y)
	player_texture:render()

	love.graphics.setColor(1, 0, 0)
	for _, melon in pairs(melons) do
		if melon:intersectsWithRect(player_texture) then
			renderTextCentered("syö", screen_w / 2, screen_h / 2)
		end
	end

	love.graphics.setColor(1, 1, 1)
	for _, bullet in pairs(bullets) do
		bullet:render()
	end

	love.graphics.setColor(0, 0, 0)
	local mouse_x, mouse_y = love.mouse.getPosition()
	crosshair:centerTo(mouse_x, mouse_y)
	crosshair:render()
	love.graphics.print("Seeds: "..seeds, 0, 0)

	love.graphics.setColor(1, 0, 0)
end
