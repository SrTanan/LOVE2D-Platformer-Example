function love.load()
	--load tilemaps
	local directories = getDirectories('tilemaps')
	tilemaps = {}
	obj = 1

	for i=1,#directories do
		table.insert(tilemaps, loadTilemap(directories[i]))
	end

	virtualScreen = newTilemapCanvas(tilemaps[1], 16, 16) --setup canvas
	camera = {x=1,y=1,width=16,height=16}

	local directories = getDirectories('sprites')
	spritemaps = {}

	for i=1,#directories do
		table.insert(spritemaps, loadSpriteMap(directories[i]))
	end
end
 

function getDirectories(folder)
	local directories = {}
	local files = love.filesystem.getDirectoryItems(folder)

	for k,v in ipairs(files) do
		local file = folder.."/"..v

		if (love.filesystem.getInfo(file).type ~= "file") then
			table.insert(directories, file)
		end
	end

	return directories
end

function processMaps(imgArray) --Given an image array, return a map array
	local maps = {}

	for i=1,#imgArray do
		local img = imgArray[i]
		local map = {{}}
		local pallete = {{0,0,0,1}}

		for x=1,img:getWidth()-1 do
			table.insert(map,{})

			for y=1,img:getHeight()-1 do

				local r,g,b,a = img:getPixel(x,y)
				local pixelColor = {r,g,b,a}

				local colorSet = false
				for color=1,#pallete do
					if (compareArrays(pixelColor, pallete[color])) then
						map[x][y] = color
						colorSet = true
					end
				end

				if (colorSet == false) then
					table.insert(pallete, pixelColor)
					map[x][y] = #pallete
				end
			end
		end

		table.insert(maps, map)
	end

	return maps
end

function loadImages(folder)
	local images = {}
	local files = love.filesystem.getDirectoryItems(folder)

	for k,v in ipairs(files) do
		local file = folder.."/"..v

		if (love.filesystem.getInfo(file).type == "file") and (checkExtension(file, {".png",".jpg",".jpeg"})) then
			table.insert(images, love.image.newImageData(file))
		end
	end

	return images
end

function loadTilemap(folder) --Tilemap type constructor
	local tileArray = loadImages(folder .. '/tiles')

	for i=1,#tileArray do
		tileArray[i] = love.graphics.newImage(tileArray[i])
	end

	return {map=processMaps(loadImages(folder))[1], tile={texture=tileArray,width=tileArray[1]:getWidth(),height=tileArray[1]:getHeight()}}
end

function loadSprite(folder, posx, posy) --Given a determined folder and a position, returns a Sprite object
	local directories = getDirectories(folder)
	local sprites = {{}}

	for i=1,#directories do
		sprites[i] = loadImages(directories[i])

		for j=1,#sprites[i] do
			sprites[i][j] = love.graphics.newImage(sprites[i][j])
			sprites[i][j]:setFilter("linear","nearest")
		end
	end

	--The sprite object cotains textures, along with information of the sprite's state,
	--as in, which texture is exactly being represented in the moment and additional information	
	return {state={pos={x=posx,y=posy},acc={x=0,y=0},vel={x=0,y=0}}, index={1,1},sprite=sprites,flags={gravity=false},behaviour=require(folder .. '/behaviour')}
end

function loadSpriteMap(folder)
	local map = processMaps(loadImages(folder))[1]
	local spriteDirectories = getDirectories(folder .. "/objects")
	local sprites = {}


	for x=1,#map do
		for y=1,#map[x] do
			if (map[x][y] ~= 1) and (map[x][y] ~= nil) then
				print(map[x][y])
				table.insert(sprites, loadSprite(spriteDirectories[map[x][y]-1],x,y))
			end
		end
	end

	return sprites
end

function newTilemapCanvas(tilemap, width, height) --Returns a canvas with a tilemap drawn on it
	local c = 0
	if (width ~= nil) and (height ~= nil) then
		c = love.graphics.newCanvas(width*(tilemap.tile.width-1), height*tilemap.tile.height)
	else
		c = love.graphics.newCanvas(#tilemap.map*(tilemap.tile.width-1), #tilemap.map[1]*tilemap.tile.height)
	end
	
	c:setFilter("linear", "nearest")
	love.graphics.setCanvas(c)
	drawTilemap(tilemap)
	love.graphics.setCanvas()
	return c
end

function drawTilemap(tilemap, cam) --Draws tilemap into the selected canvas, within the boundaries of a camera
	if (cam ~= nil) then
		if (cam.x < 1) then
			cam.x = 1
		end

		if (cam.x+cam.width >= #tilemap.map) then
			cam.x = (#tilemap.map-cam.width)-2
		end

		if (cam.y < 1) then
			cam.y = 1
		end

		if (cam.y+cam.height > #tilemap.map[1]) then
			cam.y = (#tilemap.map[1]-cam.height)-2
		end

		for x=cam.x,cam.x+cam.width do
			for y=cam.y,cam.y+cam.height do
				love.graphics.draw(tilemap.tile.texture[tilemap.map[math.floor(x)][math.floor(y)]], (x-cam.x)*tilemap.tile.width, (y-cam.y)*tilemap.tile.height)
			end
		end
	else
		for x=1,#tilemap.map do
			for y=1,#tilemap.map[x] do
				love.graphics.draw(tilemap.tile.texture[tilemap.map[x][y]], (x-1)*tilemap.tile.width, (y-1)*tilemap.tile.height)
			end
		end
	end
end

function drawSprites(sprites, cam) --Draws sprites in a given array, within the boundaries of tilespace and relative to a camera
	for i=1,#sprites do
		local texture = sprites[i].sprite[sprites[i].index[1]][sprites[i].index[2]]
		love.graphics.draw(texture, (sprites[i].state.pos.x-math.floor(cam.x))*texture:getWidth(), (sprites[i].state.pos.y-math.floor(cam.y))*texture:getHeight())
	end
end

function updatePhysics(sprite, map, deltatime)
	local newState = {pos={x=sprite.state.pos.x, y=sprite.state.pos.y},vel={x=sprite.state.vel.x,y=sprite.state.vel.y},acc={x=sprite.state.acc.x,y=sprite.state.acc.y}}
	local collisions = {}

	if (sprite.flags.gravity == true) then
		newState.acc.y = newState.acc.y + 20
	end

	newState.vel.x = (newState.vel.x + (newState.acc.x*deltatime)) * 0.8 --apply acceleration and friction
	newState.vel.y = (newState.vel.y + (newState.acc.y*deltatime)) * 0.8 --apply acceleration and friction
	newState.acc = {x=0,y=0}

	local newPos = {x=newState.pos.x,y=newState.pos.y}
	newPos.x = newPos.x + (newState.vel.x*deltatime)
	newPos.y = newPos.y + (newState.vel.y*deltatime)

	--Clamp sprite
	if (newPos.x < 1) then
		newPos.x = 1
	elseif (newPos.x+1 > #map) then
		newPos.x = newPos.x - 1
	end

	if (newPos.y < 1) then
		newPos.y = 1
	elseif (newPos.y+1 > #map[1]) then
		newPos.y = newPos.y - 1
	end

	--Collision detection and handling
	--Algortithm sneakely stolen from One Lone Coder's video, so check it out! https://www.youtube.com/watch?v=oJvJZNyW_rw
	if (newState.vel.x <= 0) then --x-axis collision detection
		if (map[math.floor(newPos.x)][math.floor(newState.pos.y)] ~= 1) then
			newPos.x = math.floor(newPos.x) + 1
			newState.vel.x = 0

			table.insert(collisions, {x=math.floor(newPos.x),y=math.floor(newState.pos.y)})
		end

		if (map[math.floor(newPos.x)][math.floor(newState.pos.y+0.9)] ~= 1) then
			newPos.x = math.floor(newPos.x) + 1
			newState.vel.x = 0

			table.insert(collisions, {x=math.floor(newPos.x),y=math.floor(newState.pos.y+0.9)})
		end
	else
		if (map[math.floor(newPos.x+1)][math.floor(newState.pos.y)] ~= 1) then
			newPos.x = math.floor(newPos.x)
			newState.vel.x = 0

			table.insert(collisions, {x=math.floor(newPos.x+1),y=math.floor(newState.pos.y)})
		end

		if (map[math.floor(newPos.x+1)][math.floor(newState.pos.y+0.9)] ~= 1) then
			newPos.x = math.floor(newPos.x)
			newState.vel.x = 0

			table.insert(collisions, {x=math.floor(newPos.x+1),y=math.floor(newState.pos.y+0.9)})
		end
	end

	if (newState.vel.y <= 0) then --y-axis collision detection
		if (map[math.floor(newPos.x)][math.floor(newPos.y)] ~= 1) then
			newPos.y = math.floor(newPos.y) + 1
			newState.vel.y = 0

			table.insert(collisions, {x=math.floor(newPos.x),y=math.floor(newPos.y)})
		end

		if (map[math.floor(newPos.x+0.9)][math.floor(newPos.y)] ~= 1) then
			newPos.y = math.floor(newPos.y) + 1
			newState.vel.y = 0

			table.insert(collisions, {x=math.floor(newPos.x),y=math.floor(newPos.y)})
		end
	else
		if (map[math.floor(newPos.x)][math.floor(newPos.y+1)] ~= 1) then
			newPos.y = math.floor(newPos.y)
			newState.vel.y = 0

			table.insert(collisions,{x=math.floor(newPos.x),y=math.floor(newPos.y+1)})
		end

		if (map[math.floor(newPos.x+0.9)][math.floor(newPos.y+1)] ~= 1) then
			newPos.y = math.floor(newPos.y)
			newState.vel.y = 0

			table.insert(collisions,{x=math.floor(newPos.x),y=math.floor(newPos.y+1)})
		end
	end

	newState.pos = newPos

	return newState, collisions
end

function love.update(dt)

	for i=1,#spritemaps[1] do
		local collisions = {} --updatePhysics gives additional information on tilemap colisions
		spritemaps[1][i].state,collisions = updatePhysics(spritemaps[1][i], tilemaps[1].map, dt)

		for j=1,#collisions do
			spritemaps[1][i].behaviour.onTileCollision(spritemaps[1][i],collisions[j])
		end

		--Sprite-to-sprite collision detection and callback
		for j=1,#spritemaps[1] do
			if (spritemaps[1][j] ~= spritemaps[1][i]) then --No self-collision
				if (spriteToSpriteCollision(spritemaps[1][j],spritemaps[1][i]) == true) then
					spritemaps[1][i].behaviour.onSpriteCollision(spritemaps[1][i],spritemaps[1][j])

					if (spritemaps[1][i].behaviour.handleSpriteCollision ~= nil) then
						if (spritemaps[1][i].behaviour.handleSpriteCollision == true) then

							spritemaps[1][i].state.pos.x = spritemaps[1][i].state.pos.x + (spritemaps[1][i].state.pos.x-spritemaps[1][j].state.pos.x)
							spritemaps[1][i].state.pos.y = spritemaps[1][i].state.pos.y + (spritemaps[1][i].state.pos.y-spritemaps[1][j].state.pos.y)
							spritemaps[1][i].state.vel = {x=0,y=0}
						end
					end
				end 
			end
		end

		spritemaps[1][i].behaviour.update(spritemaps[1][i],dt)
	end	

end

function spriteToSpriteCollision(a,b)
	--Use screenspace for practicity and precision
	local aSize = {x=a.sprite[a.index[1]][a.index[2]]:getWidth(),y=a.sprite[a.index[1]][a.index[2]]:getHeight()}
	local bSize = {x=b.sprite[b.index[1]][b.index[2]]:getWidth(),y=b.sprite[b.index[1]][b.index[2]]:getHeight()}


	--Perform AABB collision detection
	if (a.state.pos.x*aSize.x < (b.state.pos.x*bSize.x)+bSize.x) then
		if ((a.state.pos.x*aSize.x)+aSize.x > b.state.pos.x*bSize.x) then
			if (a.state.pos.y*aSize.y < (b.state.pos.y*bSize.y)+bSize.y) then
				if ((a.state.pos.y*aSize.y)+aSize.y > b.state.pos.y*bSize.y) then
					return true
				end
			end
		end
	end

	return false
end

function love.draw()
	love.graphics.setColor(255,255,255,255)
	love.graphics.setCanvas(virtualScreen)
	love.graphics.setBackgroundColor(0,0,0)
	drawTilemap(tilemaps[1], camera)
	drawSprites(spritemaps[1], camera)
	love.graphics.setCanvas()

	love.graphics.draw(virtualScreen, 0, 0, 0, love.graphics.getWidth()/virtualScreen:getWidth(), love.graphics.getHeight()/virtualScreen:getHeight())

	
	for x=1,#tilemaps[1].map do
		for y=1,#tilemaps[1].map[x] do
			if (tilemaps[1].map[x][y] ~= 1) then
				love.graphics.rectangle("fill",x*5,y*5,5,5)
			end
		end
	end

	love.graphics.setColor(255,0,0,255)
	love.graphics.rectangle("fill",spritemaps[1][obj].state.pos.x*5, spritemaps[1][obj].state.pos.y*5,5,5)
end

function checkExtension(file, extensionTable) --Check if a file fits an extension, given a list of extensions
	for i=1,#extensionTable do
		if (file:sub(file:len()-extensionTable[i]:len()+1) == extensionTable[i]) then
			return true
		end
	end
	return false
end

function round(num) 
    if num >= 0 then return math.floor(num+.5) else return math.ceil(num-.5) end
end

function compareArrays(a,b)
	if (#a == #b) then
		for i=1,#a do
			if not (a[i] == b[i]) then
				return false
			end
		end
	else
		return false
	end
	return true
end