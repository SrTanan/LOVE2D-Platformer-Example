local public = {}
public.type = "player"
public.handleSpriteCollision = true

local clock = 0
local direction = 0
local onFloor = false
local jumping = false
local jumpClock = 0
local standing = true
local gravity = 294
local velocity = 5

function public.onSpriteCollision(a,b)
end

function public.onTileCollision(sprite,pos)
	if (sprite.state.pos.y < pos.y) then
		onFloor = true
		standing = true
	end
end

function public.update(sprite, dt)
	sprite.state.acc.y = sprite.state.acc.y + gravity

	if (onFloor) then
		standing = true
	end

	if (love.keyboard.isDown("lshift")) then
		velocity = 15
	else
		velocity = 5
	end

	if (love.keyboard.isDown("d")) then
		direction = 0

		if (onFloor) then
			sprite.index[1] = 1

			clock = clock + (60*dt)
			if (clock >= 3) then
				sprite.index[2] = sprite.index[2] + 1
				clock = 0
			end

			if (sprite.index[2] > #sprite.sprite) then
				sprite.index[2] = 1
			end

			sprite.state.vel.x = velocity

			standing = false
		else
			sprite.state.vel.x = (velocity+2)
		end
	end

	if (love.keyboard.isDown("a")) then
		direction = 1

		if (onFloor) then
			sprite.index[1] = 2

			clock = clock + (60*dt)
			if (clock >= 3) then
				sprite.index[2] = sprite.index[2] + 1
				clock = 0
			end

			if (sprite.index[2] > #sprite.sprite) then
				sprite.index[2] = 1
			end

			sprite.state.vel.x = -velocity
			standing = false
		else
			sprite.state.vel.x = -(velocity+2)
		end
	end

	if (standing) then
		sprite.index[1] = 1+direction
		sprite.index[2] = 1
	end

	if (love.keyboard.isDown("space")) then
		standing = false

		if (onFloor == true) then
			jumping = true
			jumpClock = 0
			onFloor = false
		end

		if (jumping) then
			sprite.state.acc.y = sprite.state.acc.y - (gravity/4)
		end
	end

	if (jumping) then
		sprite.index[1] = 3+direction
		sprite.index[2] = 1

		jumpClock = jumpClock + (100*dt)

		if (jumpClock < 30) then
			sprite.state.acc.y = sprite.state.acc.y - (gravity+((gravity*10)/(jumpClock*3)))
		else
			jumping = false
		end
	end
end

return public