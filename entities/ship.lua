--[[
 * Copyright (C) 2016 Ricky K. Thomson
 * 
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 * u should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 --]]
 
ship = {}
ship.sounds = {}

ship.cannon = {}
ship.cannon.switch = false -- alternating sides


function ship:init(shipsel)
	ship.type = shipsel
	ship.gfx = love.graphics.newImage("gfx/starship/"..ship.type.."_small.png") -- default

	ship.x = love.graphics.getWidth()/3
	ship.y = love.graphics.getHeight()/2-ship.gfx:getHeight()/2
	ship.w = ship.gfx:getWidth()
	ship.h = ship.gfx:getHeight()
	ship.shield = 100
	ship.shieldmax = 100
	ship.energy = 100
	ship.energymax = 100
	ship.speed = 1500
	ship.speedmax = 3000
	
	ship.lives = 3
	ship.projectileCycle = 0
	ship.projectileDelay = 0.14
	ship.secondaryCycle = 0
	ship.secondaryDelay = 0.05
	
	ship.respawnCycle = 3
	ship.respawnDelay = 3
	ship.alive = true
	ship.float = 2
	ship.maxvel = 400
	ship.xvel = 0
	ship.yvel = 0
	ship.idle = true
	ship.invincible = false
	
	if cheats.invincible then ship.invincible = true end
end



function ship:update(dt)
	if paused then return end
	self.idle = true
	
	
	if not ship.alive then 
			self.respawnCycle = math.max(0, self.respawnCycle - dt)
			if self.respawnCycle <= 0 then
				self.respawnCycle = self.respawnDelay
				
				if ship.lives < 0 then
					title:init()
				else
					self.alive = true
					ship.shield = ship.shieldmax
				end
			end
		return
	end
	
	if love.keyboard.isDown(binds.up, binds.altup) then 
		self.yvel = self.yvel - self.speed * dt
		self.idle = false
	end
	if love.keyboard.isDown(binds.down, binds.altdown) then 
		self.yvel = self.yvel + self.speed * dt
		self.idle = false
	end
	if love.keyboard.isDown(binds.left, binds.altleft) then 
		self.xvel = self.xvel - self.speed * dt
		self.idle = false
	end
	if love.keyboard.isDown(binds.right, binds.altright) then 
		self.xvel = self.xvel + self.speed * dt
		self.idle = false
	end



	
	if self.idle then
		if self.yvel ~= 0 then
			if self.yvel > 0 then
				self.yvel = self.yvel - (self.speed/self.float) *dt
				if self.yvel < 0 then self.yvel = 0 end
				
			elseif ship.yvel < 0 then
				self.yvel = self.yvel + (self.speed/self.float) *dt
				if self.yvel > 0 then self.yvel = 0 end
			end
		end

		if self.xvel ~= 0 then
			if self.xvel > 0 then
				self.xvel = self.xvel - (self.speed/self.float) *dt
				if self.xvel < 0 then self.xvel = 0 end
				
			elseif self.xvel < 0 then
				self.xvel = self.xvel + (self.speed/self.float) *dt
				if self.xvel > 0 then self.xvel = 0 end
			end
		end
	end
	
	
	
	if self.yvel > self.maxvel then self.yvel = self.maxvel	end
	if self.xvel > self.maxvel then self.xvel = self.maxvel end
	if self.yvel < -self.maxvel then self.yvel = -self.maxvel end
	if self.xvel < -self.maxvel then self.xvel = -self.maxvel end


	self.y = self.y + self.yvel * dt
	self.x = self.x + self.xvel * dt

	if self.x < 0   then 
		self.x = 0
		self.xvel = 0
	end
	if self.x > starfield.w-self.w  then 
		self.x = starfield.w-self.w
		self.xvel = 0
	end
	
	if self.y < 0  then 
		self.y = 0
		self.yvel = 0
	end
	if self.y > starfield.h-self.h  then 
		self.y = starfield.h-self.h
		self.yvel = 0
	end
	

	for i,p in ipairs(pickups.items) do
		if ship.alive and collision:check(p.x,p.y,p.w,p.h,ship.x,ship.y,ship.w,ship.h) then
			if pickups.sound:isPlaying() then
				pickups.sound:stop()
			end
			pickups.sound:play()
			
			if 		   p.type == 1 then ship.shield = ship.shield + 20
				elseif p.type == 2 then ship.energy = ship.energy + 20
				elseif p.type == 3 then ship.speed = ship.speed + 200
				elseif p.type == 4 then --
			end
			
			if ship.shield > ship.shieldmax then ship.shield = ship.shieldmax	end
			if ship.energy > ship.energymax then ship.energy = ship.energymax	end
			if ship.speed > ship.speedmax then ship.speed = ship.speedmax	end

			
			table.remove(pickups.items, i)
		end
	end


	if love.keyboard.isDown(binds.shoot) 
	or love.mouse.isDown("l") then
		self:shootPrimary(dt)
	end

	if love.keyboard.isDown(binds.special) 
	or love.mouse.isDown("r") then
		self:shootSecondary(dt)
	end	
	
	
	if ship.shield <= 0 then
		ship.shield = 0
		self.alive = false
		ship.lives = ship.lives -1
		if ship.lives < 0 then sound:playbgm(2) end
	end
	if self.energy < 0 then self.energy = 0 end

end

function ship:draw()


	if not ship.alive then return end
	love.graphics.push()

	love.graphics.setColor(255,255,255,255)
	
	love.graphics.draw(
		self.gfx, self.x, 
		self.y, 0, 1, 1
	)
	

	if debug then
		love.graphics.setColor(255,255,0,100)
		love.graphics.rectangle("line", self.x,self.y, self.gfx:getWidth(),self.gfx:getHeight())
	end
	
	love.graphics.pop()

end



function ship:shootPrimary(dt)
	self.projectileCycle = math.max(0, self.projectileCycle - dt)
		
	if self.projectileCycle <= 0 then
		sound:play(projectiles.cannon.sound.shoot)
		
		ship.cannon.switch = not ship.cannon.switch
		
		local yswitch
		if ship.cannon.switch then
			yswitch = self.y + self.gfx:getHeight()/2-projectiles.cannon.gfx:getHeight()/2 -28
		else
			yswitch = self.y + self.gfx:getHeight()/2-projectiles.cannon.gfx:getHeight()/2 +28
		end
			
		table.insert(projectiles.missiles, {
			player = true,
			type = "cannon",
			gfx = projectiles.cannon.gfx,
			w = projectiles.cannon.gfx:getWidth(),
			h = projectiles.cannon.gfx:getHeight(),
			x = self.x + self.gfx:getWidth()/2,
			y = yswitch,
			xvel = 1000,
			yvel = 0,
			damage = projectiles.cannon.damage,
			r = math.random(150,255),
			g = math.random(150,255),
			b = math.random(150,255),
		})
		
		self.projectileCycle = self.projectileDelay
	end
end


function ship:shootSecondary(dt)
	if self.energy > 0 then 
		self.secondaryCycle = math.max(0, self.secondaryCycle - dt)
		
		if self.secondaryCycle <= 0 then
			sound:play(projectiles.beam.sound.shoot)
		
			self.energy = self.energy -200*dt
			
			table.insert(projectiles.missiles, {
				player = true,
				type = "beam",
				gfx = projectiles.beam.gfx,
				w = projectiles.beam.gfx:getWidth(),
				h = projectiles.beam.gfx:getHeight(),
				x = self.x + self.gfx:getWidth(),
				y = self.y + self.gfx:getHeight()/2-(projectiles.beam.gfx:getHeight()/2),
				xvel = 900,
				yvel = 0,
				damage = projectiles.beam.damage,
				r = 255,
				g = 100,
				b = 255,
			})
			self.secondaryCycle = self.secondaryDelay
		end
	end		
end
