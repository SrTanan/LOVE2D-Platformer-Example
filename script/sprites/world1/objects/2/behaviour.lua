local public = {}
public.type = "block"
public.handleSpriteCollision = true

function public.onSpriteCollision(a,b)
	a.stage.index[1] = a.stage.index[1] + 1

	if (a.stage.index[1] > #a.sprite) then
		a.stage.index[1] = 1
	end
end

function public.onTileCollision(sprite,pos)
end

function public.update(sprite, dt)
	
end

return public