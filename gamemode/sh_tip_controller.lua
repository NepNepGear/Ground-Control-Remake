AddCSLuaFile()

GM.tipController = {}
GM.tipController.shownEvents = {}
GM.tipController.events = { -- key is event name
	BEGIN_BLEEDING = {times = 3, text = "Being shot in an unprotected area will cause bleeding. Press Q_MENU_KEY to bandage yourself.", formatFunc = function(text) return string.gsub(text, "Q_MENU_KEY", GAMEMODE:getKeyBind("+menu")) end},
	STOPPED_BLEEDING = {times = 3, text = "Applying a bandage will not restore health, be careful around gunfire."},
	PICKUP_WEAPON = {times = 3, text = "Picking up weapons will not transmit the owner's ammo, and you can not carry more than 2 weapons at a time."},
	DROPPED_WEAPON = {times = 3, text = "Taking too much damage to the arms will make you drop your primary and be unable to use them."}, -- for when we lose a lot of health via hits to the arm(s) and we lose our primary
	RADIO_USED = {times = 3, text = "Radios can be used for quick communication and marking enemy positions. Press C_MENU_KEY to open the radio menu.", formatFunc = function(text) return string.gsub(text, "C_MENU_KEY", GAMEMODE:getKeyBind("+menu_context")) end},
	KILLED_ENEMY = {times = 3, text = "Make sure to report enemy deaths using the radio, it marks the death area and gives you a cash and experience bonus."},
	MARK_ENEMIES = {times = 3, text = "Make sure to spot enemies using the radio, it'll give you a spot bonus for enemies killed within the marked area."},
	HEAL_TEAMMATES = {times = 3, text = "You can bandage your team-mates the same way you can bandage yourself."},
	RESUPPLY_TEAMMATES = {times = 3, text = "If you have any spare ammo, give it to team-mates that need some."},
	HELP_TEAMMATES = {times = 3, text = "Make sure to help your team-mates, alone you're rarely a threat to the enemy."},
	HIGH_WEIGHT = {times = 3, text = "Carrying a lot of equipment will cause your stamina to drain faster from sprinting."},
	SPEND_CASH = {times = 3, text = "Spend your earned Cash on weapon attachments and Traits."},
	UNLOCK_ATTACHMENT_SLOTS = {times = 3, text = "Earning Experience will unlock more attachment slots for your guns."},
	HIGH_ADRENALINE = {times = 3, text = "Being suppressed increases your run speed and hip-fire accuracy, but makes aimed fire difficult."},
	FASTER_MOVEMENT = {times = 3, text = "Switching to a lighter weapon allows for faster movement."},
	HEALTH_REGEN = {times = 3, text = "Damage negated by an armor vest without penetration is equal to the amount of health you can regenerate idly."},
	BACKUP_SIGHTS = {times = 3, text = "The sight you have attached has back-up sights. Double-tap USE_KEY while aiming to switch to them and back.", formatFunc = function(text) return string.gsub(text, "USE_KEY", GAMEMODE:getKeyBind("+use")) end},
	THROW_FRAGS = {times = 3, text = "Hold USE_KEY and press PRIMARY_ATTACK_KEY to throw frag grenades.", formatFunc = function(text) return string.easyformatbykeys(text, "USE_KEY", GAMEMODE:getKeyBind("+use"), "PRIMARY_ATTACK_KEY", GAMEMODE:getKeyBind("+attack")) end},
	LOUD_LANDING = {times = 3, text = "The higher your loadout weight, the lesser the distance required to make a noisy landing."},
	WEAPON_CUSTOMIZATION = {times = 4, text = "Press C_MENU_KEY to open the weapon interaction menu at the start of a round.", formatFunc = function(text) return string.gsub(text, "C_MENU_KEY", GAMEMODE:getKeyBind("+menu_context")) end}
}

GM.tipController.nextTip = 0
GM.tipController.delayBetweenTips = 30
GM.tipController.alpha = 0
GM.tipController.displayTime = 0
GM.tipController.displayText = ""
GM.tipController.displayFont = "CW_HUD16"

GM.tipController.SAVE_DIRECTORY = "ground_control/shown_hints.txt"

GM.tipController.genericTips = {
	"SPEND_CASH",
	"UNLOCK_ATTACHMENT_SLOTS"
}

if SERVER then
	local PLAYER = FindMetaTable("Player")
	
	function PLAYER:sendTip(tipId)
		umsg.Start("GC_TIP_EVENT", self)
			umsg.String(tipId)
		umsg.End()
	end
end

if CLIENT then
	file.verifyDataFolder("ground_control")
	
	function GM.tipController:handleEvent(event)
		if CurTime() < self.nextTip then
			return false -- not ready to show next tip yet
		end
		
		local eventData = self.events[event] 
				
		if eventData then
			if not self.shownEvents[event] or self.shownEvents[event] < eventData.times then
				self:displayEvent(event)
				self:saveShownEvents()
				return true -- tip was shown
			end
		end
		
		return nil -- no tip was shown
	end
	
	local questionMark = surface.GetTextureID("ground_control/hud/help")
	
	function GM.tipController:displayEvent(event)
		self.shownEvents[event] = (self.shownEvents[event] or 0) + 1
		local eventData = self.events[event]
		local text = eventData.text
		
		if eventData.formatFunc then
			text = eventData.formatFunc(text)
		end
		
		self.nextTip = CurTime() + self.delayBetweenTips
		self.displayText = text
		self.flashTime = CurTime() + 2
		self.displayTime = CurTime() + (math.Clamp(2 + #text * 0.05, 2, 8)) + 2
		
		surface.SetFont(self.displayFont)
		local width, height = surface.GetTextSize(text)
		self.displayWidth = width
		self.displayHeight = height
	end
	
	function GM.tipController:draw(w, h)
		if CurTime() < self.displayTime then
			self.alpha = math.Approach(self.alpha, 1, FrameTime() * 3)
		else
			self.alpha = math.Approach(self.alpha, 0, FrameTime() * 5)
		end
		
		if self.alpha > 0 then
			if CurTime() < self.flashTime then
				self.alpha = self.alpha * (0.6 + 0.4 * math.flash(CurTime(), 2))
			end
		
			surface.SetDrawColor(0, 0, 0, 100 * self.alpha)
			surface.DrawRect(w * 0.5 - self.displayWidth * 0.5 - 4, h * 0.5 + 80 - self.displayHeight * 0.5 - 2, self.displayWidth + 28, self.displayHeight + 4)
		
			surface.SetDrawColor(255, 255, 255, 255 * self.alpha)
			surface.SetTexture(questionMark)
			surface.DrawTexturedRect(w * 0.5 - self.displayWidth * 0.5, h * 0.5 + 72, 16, 16)
			
			local hudColors = GAMEMODE.HUDColors
			
			hudColors.white.a = 255 * self.alpha
			hudColors.black.a = 255 * self.alpha
				draw.ShadowText(self.displayText, self.displayFont, w * 0.5 + 20, h * 0.5 + 80, hudColors.white, hudColors.black, 1, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			hudColors.white.a = 255
			hudColors.black.a = 255
		end
	end
	
	function GM.tipController:saveShownEvents()
		local data = util.TableToJSON(self.shownEvents)
		
		file.Write(self.SAVE_DIRECTORY, data)
	end
	
	function GM.tipController:loadShownEvents()
		local readData = file.Read(self.SAVE_DIRECTORY, "DATA")
		
		if readData then
			local data = util.JSONToTable(readData)
			
			if data then
				self.shownEvents = data
			end
		end
	end
	
	local function GC_TIP_EVENT(um)
		GAMEMODE.tipController:handleEvent(um:ReadString())
	end
	
	usermessage.Hook("GC_TIP_EVENT", GC_TIP_EVENT)
end