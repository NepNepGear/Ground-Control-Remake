AddCSLuaFile()
AddCSLuaFile("cl_radio.lua")

if CLIENT then
	include("cl_radio.lua")
end

if SERVER then
	GM.HUDColors = {} -- just a dummy table
end

GM.RadioCommands = {}
GM.VisibleRadioCommands = {}
GM.VoiceVariants = {}
GM.RadioCategories = {}
GM.VoiceVariantsById = {}

GM.VisibleVoiceVariants = {}
GM.VisibleVoiceVariantsById = {}

if SERVER then
	GM.MarkedSpots = {}
	
	function GM:markSpot(pos, marker, radioData)
		local markTeam = marker:Team()
		
		self.MarkedSpots[markTeam] = self.MarkedSpots[markTeam] or {}
		self:sanitiseMarkedSpots(markTeam)
		
		table.insert(self.MarkedSpots[markTeam], {position = pos, marker = marker, displayTime = CurTime() + radioData.displayTime, radioData = radioData})
	end
	
	function GM:sanitiseMarkedSpots(desiredTeam)
		local data = self.MarkedSpots[desiredTeam]
		local removeIndex = 1
		
		for i = 1, #data do
			local current = data[removeIndex]
			
			if CurTime() > current.displayTime or not IsValid(current.marker) then
				table.remove(data, removeIndex)
			else
				removeIndex = removeIndex + 1
			end
		end
	end
end

function GM:registerRadioVoiceVariant(voiceID, display, texture, redPlayerModel, bluePlayerModel, invisible, requiresSubtitles)
	local voiceData = {}
	voiceData.id = voiceID
	voiceData.display = display
	voiceData.numId = #self.VoiceVariants + 1
	voiceData.redPlayerModel = redPlayerModel
	voiceData.bluePlayerModel = bluePlayerModel
	voiceData.invisible = invisible
	voiceData.requiresSubtitles = requiresSubtitles
	
	if CLIENT and voiceData.texture then
		voiceData.texture = surface.GetTextureID(texture)
	end
	
	self.VoiceVariants[#self.VoiceVariants + 1] = voiceData
	self.VoiceVariantsById[voiceID] = voiceData
	
	if not invisible then
		self.VisibleVoiceVariants[#self.VisibleVoiceVariants + 1] = voiceData
		self.VisibleVoiceVariantsById[voiceID] = voiceData
	end
end

function GM:getVoiceModel(ply)
	local voiceData = self.VoiceVariants[ply.voiceVariant]
	local teamID = ply:Team()
	local model = nil
	
	if teamID == TEAM_RED then
		model = voiceData.redPlayerModel
	else
		model = voiceData.bluePlayerModel
	end
	
	if type(model) == "table" then
		model = model[math.random(1, #model)]
	end
	
	return model
end

GM:registerRadioVoiceVariant("us", "US", nil, "models/player/swat.mdl", "models/player/leet.mdl")
GM:registerRadioVoiceVariant("aus", "AUS", nil, "models/player/urban.mdl", "models/player/guerilla.mdl")
GM:registerRadioVoiceVariant("rus", "RUS", nil, "models/player/riot.mdl", "models/player/phoenix.mdl", false, true)
GM:registerRadioVoiceVariant("bandlet", "bandlet", nil, "models/player/bandit_backpack.mdl", "models/custom/stalker_bandit_veteran.mdl", true, true)
GM:registerRadioVoiceVariant("ghetto", "ghetto", nil, 
	{"models/player/group01/male_03.mdl", "models/player/group01/male_01.mdl"}, {"models/player/group01/male_03.mdl", "models/player/group01/male_01.mdl"}, true)

function GM:registerRadioCommand(data)
	--table.insert(self.RadioCommands, data)
	table.insert(self.RadioCommands[data.category].commands, data)
end

function GM:registerRadioCommandCategory(category, display, invisible)
	local structure = {commands = {}, display = display, invisible = invisible}
	self.RadioCommands[category] = structure
	self.RadioCategories[display] = category
	
	if not invisible then
		self.VisibleRadioCommands[category] = structure
	end
end

GM:registerRadioCommandCategory(1, "Combat")
GM:registerRadioCommandCategory(2, "Reply")
GM:registerRadioCommandCategory(3, "Orders")
GM:registerRadioCommandCategory(4, "Status")
GM:registerRadioCommandCategory(9, "special", true)

-- {sound = "ground_control/radio/aus/.mp3", text = ""}

local command = {}
command.tipId = "MARK_ENEMIES"
command.variations = {us = {{sound = "ground_control/radio/us/contact.mp3", text = "Contact!"}, 
	{sound = "ground_control/radio/us/contacts.mp3", text = "Contacts!"}, 
	{sound = "ground_control/radio/us/enemyinfantryspotted.mp3", text = "Enemy infantry spotted!"}, 
	{sound = "ground_control/radio/us/enemymovementspotted.mp3", text = "Enemy movement spotted!"}, 
	{sound = "ground_control/radio/us/enemymovementspotted2.mp3", text = "Enemy movement spotted!"}, 
	{sound = "ground_control/radio/us/enemyoverthere.mp3", text = "Enemy over there!"}, 
	{sound = "ground_control/radio/us/enemyrightthere.mp3", text = "Enemy right there!"}, 
	{sound = "ground_control/radio/us/enemyspotted.mp3", text = "Enemy spotted!"}, 
	{sound = "ground_control/radio/us/enemyspotted2.mp3", text = "Enemy spotted!"}, 
	{sound = "ground_control/radio/us/tangospotted.mp3", text = "Tango spotted!"}, 
	{sound = "ground_control/radio/us/tangospotted2.mp3", text = "Tango spotted!"}, 
	{sound = "ground_control/radio/us/ihaveeyesonenemytroops.mp3", text = "I have eyes on enemy troops!"}},
	
	aus = {{sound = "ground_control/radio/aus/contact.mp3", text = "Contact!"},
		{sound = "ground_control/radio/aus/enemymovement.mp3", text = "Enemy movement spotted!"},
		{sound = "ground_control/radio/aus/enemysighted.mp3", text = "Oi, enemy sighted!"},
		{sound = "ground_control/radio/aus/enemyspotted.mp3", text = "Enemy spotted!"},
		{sound = "ground_control/radio/aus/iseethem.mp3", text = "I see them!"},
		{sound = "ground_control/radio/aus/hostiles.mp3", text = "Hostiles!"},
		{sound = "ground_control/radio/aus/theresenemiesoverthere.mp3", text = "There's enemies over there!"},
		{sound = "ground_control/radio/aus/watchoutmate.mp3", text = "Watch out, mate, enemies spotted!"},
	},
	
	bandlet = {
		{sound = "ground_control/radio/bandlet/atanda.mp3", text = "Атанда!"},
		{sound = "ground_control/radio/bandlet/gondurasi.mp3", text = "Гондурасы!"},
		{sound = "ground_control/radio/bandlet/pacani_atas.mp3", text = "Пацаны, атас!"},
		{sound = "ground_control/radio/bandlet/stvoly_dostavaite_pocani.mp3", text = "Стволы доставайте, пацаны!"},
		{sound = "ground_control/radio/bandlet/volyni_k_boju.mp3", text = "Волыны к бою!"}
	},
	
	rus = {
		{sound = "ground_control/radio/rus/enemyspotted1.mp3", text = "Враг."},
		{sound = "ground_control/radio/rus/enemyspotted2.mp3", text = "Враг!"},
		{sound = "ground_control/radio/rus/enemyspotted3.mp3", text = "Враг."},
		{sound = "ground_control/radio/rus/enemyspotted4.mp3", text = "Пиндос!"},
		{sound = "ground_control/radio/rus/enemyspotted5.mp3", text = "Фраер."},
		{sound = "ground_control/radio/rus/enemyspotted6.mp3", text = "Фраер!"},
		{sound = "ground_control/radio/rus/enemyspotted7.mp3", text = "Враг прямо."},
		{sound = "ground_control/radio/rus/enemyspotted8.mp3", text = "Враг прямо!"},
		{sound = "ground_control/radio/rus/enemyspotted9.mp3", text = "Вижу врага."},
		{sound = "ground_control/radio/rus/enemyspotted10.mp3", text = "Вижу врага!"},
		{sound = "ground_control/radio/rus/enemyspotted11.mp3", text = "Пасу пиндоса!"},
		{sound = "ground_control/radio/rus/enemyspotted12.mp3", text = "Контакт."},
		{sound = "ground_control/radio/rus/enemyspotted13.mp3", text = "Контакт."},
		{sound = "ground_control/radio/rus/enemyspotted14.mp3", text = "Контакт!"},
	},
	
	ghetto = {
		{sound = "ground_control/radio/ghetto/enemy_spotted1.mp3", text = "Shit, I used to know that nigga from school!"},
		{sound = "ground_control/radio/ghetto/enemy_spotted2.mp3", text = "Shit, I know that nigga from down the block!"},
		{sound = "ground_control/radio/ghetto/enemy_spotted3.mp3", text = "I see the popos!"},
		{sound = "ground_control/radio/ghetto/enemy_spotted4.mp3", text = "It's the Five-O!"},
		{sound = "ground_control/radio/ghetto/enemy_spotted5.mp3", text = "I see them whiteboys!"},
		{sound = "ground_control/radio/ghetto/enemy_spotted6.mp3", text = "Ey yo, them crackers be there!"},
		{sound = "ground_control/radio/ghetto/enemy_spotted7.mp3", text = "Look at them pigs over there!"}
	}
}
	
command.onScreenText = "Enemy spotted"
command.onScreenColor = GM.HUDColors.lightRed
command.menuText = "Enemy spotted"
command.displayTime = 5
command.category = GM.RadioCategories.Combat
command.killRangeReward = 256 -- how close enemies have to be to the marked spot for the marker to receive points for marking the spot
command.cashReward = 10
command.expReward = 20	

local traceData = {}
traceData.mask = bit.bor(CONTENTS_SOLID, CONTENTS_MOVEABLE, CONTENTS_DEBRIS, CONTENTS_MONSTER, CONTENTS_HITBOX, CONTENTS_WATER)

function command:onPlayerDeath(victim, attacker, data)
	local victimTeam = victim:Team()
	local attackerTeam = attacker:Team()
	local marker = data.marker
	local markerTeam = marker:Team()
	
	if markerTeam == attackerTeam then
		if victimTeam ~= markerTeam and attacker ~= marker then
			local dist = victim:GetPos():Distance(data.position)
			
			if dist <= self.killRangeReward then
				marker:addCurrency(self.cashReward, self.expReward, "SPOT_KILL")
				GAMEMODE:trackRoundMVP(marker, "spotting", 1)
			end
		end
	end
end
	
function command:send(ply, commandId, category)
	traceData.start = ply:GetShootPos()
	traceData.endpos = traceData.start + ply:GetAimVector() * 4096
	traceData.filter = ply
	
	local trace = util.TraceLine(traceData)
	
	if not trace.HitSky then
		GAMEMODE:markSpot(trace.HitPos, ply, self)
		
		for key, obj in pairs(team.GetPlayers(ply:Team())) do
			GAMEMODE:sendMarkedSpot(category, commandId, ply, obj, trace.HitPos)
		end
	end
end

function command:receive(sender, commandId, category, data)
	local markPos = data:ReadVector()
	GAMEMODE:AddMarker(markPos, self.onScreenText, self.onScreenColor, self.displayTime)
end

GM:registerRadioCommand(command)

local command = {}
command.variations = {us = {{sound = "ground_control/radio/us/enemydown.mp3", text = "Enemy down."}, 
	{sound = "ground_control/radio/us/tangodown.mp3", text = "Tango down."},  
	{sound = "ground_control/radio/us/killconfirmed.mp3", text = "Kill confirmed."}},
	
	aus = {{sound = "ground_control/radio/aus/contactdown.mp3", text = "Contact down!"},
		{sound = "ground_control/radio/aus/contactsdead.mp3", text = "Contact's dead!"},
		{sound = "ground_control/radio/aus/enemydown.mp3", text = "Enemy down."}
	},
	
	bandlet = {
		{sound = "ground_control/radio/bandlet/na_havaj_suka.mp3", text = "На, хавай, сука!"},
		{sound = "ground_control/radio/bandlet/na_tebe.mp3", text = "На тебе!"},
		{sound = "ground_control/radio/bandlet/poluchi_suka.mp3", text = "Получи, сука!"}
	},
	
	rus = {
		{sound = "ground_control/radio/rus/enemydown1.mp3", text = "Враг убит."},
		{sound = "ground_control/radio/rus/enemydown2.mp3", text = "Враг уничтожен."},
		{sound = "ground_control/radio/rus/enemydown3.mp3", text = "Враг нейтрализован."},
		{sound = "ground_control/radio/rus/enemydown4.mp3", text = "Прихлопнул."},
		{sound = "ground_control/radio/rus/enemydown5.mp3", text = "Прищучил падлу."},
		{sound = "ground_control/radio/rus/enemydown6.mp3", text = "Готов."},
		{sound = "ground_control/radio/rus/enemydown7.mp3", text = "Готов!"},
		{sound = "ground_control/radio/rus/enemydown8.mp3", text = "Хэ, мамку ебал."},
		{sound = "ground_control/radio/rus/enemydown9.mp3", text = "На, хавай, сука!"},
		{sound = "ground_control/radio/rus/enemydown10.mp3", text = "Хээ, трубу вертел"},
		{sound = "ground_control/radio/rus/enemydown11.mp3", text = "А, скопытился, падла?!"},
	},
	
	ghetto = {
		{sound = "ground_control/radio/ghetto/enemy_down1.mp3", text = "I shot that nigga!"},
		{sound = "ground_control/radio/ghetto/enemy_down2.mp3", text = "Popped a cap in his ass!"},
		{sound = "ground_control/radio/ghetto/enemy_down3.mp3", text = "Got one of them whiteboys!"},
		{sound = "ground_control/radio/ghetto/enemy_down4.mp3", text = "I fucked that nigga up!"},
		{sound = "ground_control/radio/ghetto/enemy_down5.mp3", text = "Lit that cracker up!"},
		{sound = "ground_control/radio/ghetto/enemy_down6.mp3", text = "Black lives matter, nigga!"}
	}
}

command.menuText = "Enemy down"
command.category = GM.RadioCategories.Combat
command.onScreenText = "Enemy down"
command.onScreenColor = GM.HUDColors.green
command.displayTime = 6
command.cashReward = 5
command.expReward = 5


function command:send(ply, commandId, category)
	if ply.lastKillData.position and CurTime() < ply.lastKillData.time then
		for key, obj in pairs(team.GetPlayers(ply:Team())) do
			GAMEMODE:sendMarkedSpot(category, commandId, ply, obj, ply.lastKillData.position)
		end
		
		if team.GetAlivePlayers(ply:Team()) > 1 and not GAMEMODE.RoundOver then -- only give the reward if there's at least one player alive or the round hasn't ended yet
			ply:addCurrency(self.cashReward, self.expReward, "REPORT_ENEMY_DEATH")
		end
		
		ply:resetLastKillData()
	else
		for key, obj in pairs(team.GetPlayers(ply:Team())) do
			GAMEMODE:sendRadio(ply, obj, category, commandId)
		end
	end
end

local worldSpawn = Vector(0, 0, 0)

function command:receive(sender, commandId, category, data)
	local markPos = data:ReadVector()
	
	if markPos ~= worldSpawn then
		GAMEMODE:AddMarker(markPos, self.onScreenText, self.onScreenColor, self.displayTime)
	end
end

GM:registerRadioCommand(command)

local command = {}
command.variations = {us = {{sound = "ground_control/radio/us/affirmative.mp3", text = "Affirmative."}, 
	{sound = "ground_control/radio/us/copythat.mp3", text = "Copy that."}, 
	{sound = "ground_control/radio/us/icopy.mp3", text = "I copy."}},
	
	aus = {
		{sound = "ground_control/radio/aus/affirmative.mp3", text = "Affirmative."},
		{sound = "ground_control/radio/aus/copythat.mp3", text = "Copy that."},
		{sound = "ground_control/radio/aus/righto.mp3", text = "Right-o."},
		{sound = "ground_control/radio/aus/soundsgood.mp3", text = "Sounds good."},
		{sound = "ground_control/radio/aus/gotcha.mp3", text = "Gotcha."}
	},
	
	bandlet = {
		{sound = "ground_control/radio/bandlet/a_nu_chiki_briki_i_v_damki.mp3", text = "А ну чики-брики, и в дамки!"},
		{sound = "ground_control/radio/bandlet/a_nu_davaj_davaj.mp3", text = "А ну давай, давай!"}
	},
	
	rus = {
		{sound = "ground_control/radio/rus/affirmative1.mp3", text = "Понял."},
		{sound = "ground_control/radio/rus/affirmative2.mp3", text = "Принято."},
		{sound = "ground_control/radio/rus/affirmative3.mp3", text = "Так-точно."},
		{sound = "ground_control/radio/rus/affirmative4.mp3", text = "Окей."},
		{sound = "ground_control/radio/rus/affirmative5.mp3", text = "Выполняю."}
	},
	
	ghetto = {
		{sound = "ground_control/radio/ghetto/affirmative1.mp3", text = "Aight."},
		{sound = "ground_control/radio/ghetto/affirmative2.mp3", text = "Whatever you say, nigga."},
		{sound = "ground_control/radio/ghetto/affirmative3.mp3", text = "I got you, cus'"},
		{sound = "ground_control/radio/ghetto/affirmative4.mp3", text = "Yeah, what he said."},
		{sound = "ground_control/radio/ghetto/affirmative5.mp3", text = "You right, nigga."},
		{sound = "ground_control/radio/ghetto/affirmative6.mp3", text = "True that, mayne."}
	}
}

command.menuText = "Affirmative"
command.category = GM.RadioCategories.Reply

GM:registerRadioCommand(command)

local command = {}
command.variations = {us = {{sound = "ground_control/radio/us/nocando.mp3", text = "No can do."}, 
	{sound = "ground_control/radio/us/negative.mp3", text = "Negative."}, 
	{sound = "ground_control/radio/us/negative2.mp3", text = "Negative."}, 
	{sound = "ground_control/radio/us/nope.mp3", text = "Nope."}},
	
	aus = {
		{sound = "ground_control/radio/aus/nah.mp3", text = "Nah."},
		{sound = "ground_control/radio/aus/nahmate.mp3", text = "Nah, mate."},
		{sound = "ground_control/radio/aus/no.mp3", text = "No."},
		{sound = "ground_control/radio/aus/nocando.mp3", text = "No can do."}
	},
	
	bandlet = {
		{sound = "ground_control/radio/bandlet/ty_che_baklan.mp3", text = "Ты чё, баклан?"},
		{sound = "ground_control/radio/bandlet/ne_nu_ja_ne_ponial_mlia.mp3", text = "Не ну, я не понял, мля!"},
		{sound = "ground_control/radio/bandlet/sovsem_ohirel.mp3", text = "Совсем охерел?"},
		{sound = "ground_control/radio/bandlet/suka.mp3", text = "Сука!"}
	},
	
	rus = {
		{sound = "ground_control/radio/rus/negative1.mp3", text = "Нет."},
		{sound = "ground_control/radio/rus/negative2.mp3", text = "Никак нет."},
		{sound = "ground_control/radio/rus/negative3.mp3", text = "Отставить."},
		{sound = "ground_control/radio/rus/negative4.mp3", text = "Пошёл ты."}
	},
	
	ghetto = {
		{sound = "ground_control/radio/ghetto/negative1.mp3", text = "Fuck that shit."},
		{sound = "ground_control/radio/ghetto/negative2.mp3", text = "Hell no, man."},
		{sound = "ground_control/radio/ghetto/negative3.mp3", text = "Nah, nigga, you crazy."},
		{sound = "ground_control/radio/ghetto/negative4.mp3", text = "Nigga you trippin!"},
		{sound = "ground_control/radio/ghetto/negative5.mp3", text = "My nigga, you's is stupid."},
		{sound = "ground_control/radio/ghetto/negative6.mp3", text = "Fuck you, nigga."},
	}
}

command.menuText = "Negative"
command.category = GM.RadioCategories.Reply

GM:registerRadioCommand(command)

local command = {}
command.variations = {us = {{sound = "ground_control/radio/us/muchappreciated.mp3", text = "Much appreciated."}, 
	{sound = "ground_control/radio/us/thanks.mp3", text = "Thanks."},
	{sound = "ground_control/radio/us/thankyou.mp3", text = "Thank you."},
	{sound = "ground_control/radio/us/appreciated.mp3", text = "Appreciated."}},
	
	aus = {
		{sound = "ground_control/radio/aus/cheersmate.mp3", text = "Cheers, mate."},
		{sound = "ground_control/radio/aus/cheersmatey.mp3", text = "Cheers, matey."},
		{sound = "ground_control/radio/aus/thanksman.mp3", text = "Thanks, man."},
		{sound = "ground_control/radio/aus/thanksmate.mp3", text = "Thanks, mate."},
		{sound = "ground_control/radio/aus/thankyou.mp3", text = "Thank you."}
	},
	
	bandlet = {
		{sound = "ground_control/radio/bandlet/a_nu_chiki_briki_i_v_damki.mp3", text = "А ну чики-брики, и в дамки!"}
	},
	
	rus = {
		{sound = "ground_control/radio/rus/thanks1.mp3", text = "Спасибо."},
		{sound = "ground_control/radio/rus/thanks2.mp3", text = "Спасибо."},
		{sound = "ground_control/radio/rus/thanks3.mp3", text = "Благодарю."},
		{sound = "ground_control/radio/rus/thanks4.mp3", text = "Спасибо, братан."},
		{sound = "ground_control/radio/rus/thanks5.mp3", text = "Спасибо, братан."}
	},
	
	ghetto = {
		{sound = "ground_control/radio/ghetto/thanks1.mp3", text = "You my nigga."},
		{sound = "ground_control/radio/ghetto/thanks2.mp3", text = "Thanks, nigga."},
		{sound = "ground_control/radio/ghetto/thanks3.mp3", text = "You's a real nigga."},
		{sound = "ground_control/radio/ghetto/thanks4.mp3", text = "You a dope ass nigga."},
		{sound = "ground_control/radio/ghetto/thanks5.mp3", text = "Thanks, bruh."}
	}
}

command.menuText = "Thanks"
command.category = GM.RadioCategories.Reply

GM:registerRadioCommand(command)

local command = {}
command.variations = {us = {
		{sound = "ground_control/radio/us/waitforme.mp3", text = "Wait for me!"}, 
		{sound = "ground_control/radio/us/holdup.mp3", text = "Hold up!"},
		{sound = "ground_control/radio/us/holdit.mp3", text = "Hold it!"},
		{sound = "ground_control/radio/us/heywaitforme.mp3", text = "Hey, wait for me!"},
	},
	
	aus = {
		{sound = "ground_control/radio/aus/oiholdup.mp3", text = "Oi, hold up!"},
		{sound = "ground_control/radio/aus/wait.mp3", text = "Wait!"},
		{sound = "ground_control/radio/aus/waitforme.mp3", text = "Wait for me, mate!"},
		{sound = "ground_control/radio/aus/waitup.mp3", text = "Wait up!"}
	},
	
	bandlet = {
		{sound = "ground_control/radio/bandlet/aa_suki.mp3", text = "Аа, суки!"},
		{sound = "ground_control/radio/bandlet/tvoju_matj.mp3", text = "Твою мать!"}
	},
	
	rus = {
		{sound = "ground_control/radio/rus/wait1.mp3", text = "Э, погоди!"},
		{sound = "ground_control/radio/rus/wait2.mp3", text = "Постой!"},
		{sound = "ground_control/radio/rus/wait3.mp3", text = "Подожди!"},
		{sound = "ground_control/radio/rus/wait4.mp3", text = "Эй, тормозни!"}
	},
	
	ghetto = {
		{sound = "ground_control/radio/ghetto/wait1.mp3", text = "Ey, wait for me man!"},
		{sound = "ground_control/radio/ghetto/wait2.mp3", text = "Ayo, wait up niggas!"},
		{sound = "ground_control/radio/ghetto/wait3.mp3", text = "Hol' up, niggas!"},
		{sound = "ground_control/radio/ghetto/wait4.mp3", text = "Slow down, cus'!"}
	}
}

command.menuText = "Wait for me"
command.category = GM.RadioCategories.Reply

GM:registerRadioCommand(command)

local command = {}
command.variations = {us = {{sound = "ground_control/radio/us/moving.mp3", text = "Moving!"}, 
	{sound = "ground_control/radio/us/onmyway.mp3", text = "On my way!"},
	{sound = "ground_control/radio/us/onmyway2.mp3", text = "On my way!"}},
	
	aus = {
		{sound = "ground_control/radio/aus/immoving.mp3", text = "I'm moving."},
		{sound = "ground_control/radio/aus/imonmyway.mp3", text = "I'm on my way."},
		{sound = "ground_control/radio/aus/onmyway.mp3", text = "On my way."}
	},
	
	bandlet = {
		{sound = "ground_control/radio/bandlet/ne_tremsia_kodla_ne_tremsia.mp3", text = "Не трёмся кодла, не трёмся!"},
		{sound = "ground_control/radio/bandlet/nu_podorvali_pocani.mp3", text = "Ну, подорвали, пацаны!"}
	},
	
	rus = {
		{sound = "ground_control/radio/rus/moving1.mp3", text = "Иду."},
		{sound = "ground_control/radio/rus/moving2.mp3", text = "В пути."},
		{sound = "ground_control/radio/rus/moving3.mp3", text = "Иду, иду."},
		{sound = "ground_control/radio/rus/moving4.mp3", text = "Я уже иду."},
		{sound = "ground_control/radio/rus/moving5.mp3", text = "Я уже в пути."},
		{sound = "ground_control/radio/rus/moving6.mp3", text = "Топаю."}
	},
	
	ghetto = {
		{sound = "ground_control/radio/ghetto/moving1.mp3", text = "My black ass is movin!"},
		{sound = "ground_control/radio/ghetto/moving2.mp3", text = "Ey man, I'm movin!"},
		{sound = "ground_control/radio/ghetto/moving3.mp3", text = "Ey man, I'm goin!"},
		{sound = "ground_control/radio/ghetto/moving4.mp3", text = "I'm movin up, niggas!"}
	}
}

command.menuText = "Moving"
command.category = GM.RadioCategories.Reply

GM:registerRadioCommand(command)

local command = {}
command.variations = {us = {{sound = "ground_control/radio/us/suppressthisposition.mp3", text = "Suppress this position!"}, 
	{sound = "ground_control/radio/us/weneedtosuppressthisposition.mp3", text = "We need to suppress this position!"}},
	
	aus = {
		{sound = "ground_control/radio/aus/ineedfireonthatposition.mp3", text = "I need fire on that position!"},
		{sound = "ground_control/radio/aus/suppressthatposition.mp3", text = "Suppress that position!"},
	},
	
	bandlet = {
		{sound = "ground_control/radio/bandlet/nachinaem_heriachitj_kogda_sam_skazhu.mp3", text = "Начинаем херячить когда сам скажу!"},
		{sound = "ground_control/radio/bandlet/kak_majaknu_valim_kozlov_nafig_vse_vsosali.mp3", text = "Как маякну валим козлов нафиг, все всосали?"}
	},
	
	rus = {
		{sound = "ground_control/radio/rus/suppress1.mp3", text = "Дави, дави уродов!"},
		{sound = "ground_control/radio/rus/suppress2.mp3", text = "Подавить огневую точку!"},
		{sound = "ground_control/radio/rus/suppress3.mp3", text = "Открыть шквальный огонь!"}
	},
	
	ghetto = {
		{sound = "ground_control/radio/ghetto/suppress1.mp3", text = "Shoot them po-pos!"},
		{sound = "ground_control/radio/ghetto/suppress2.mp3", text = "Fuck 'em up!"},
		{sound = "ground_control/radio/ghetto/suppress3.mp3", text = "Shoot them whiteboys!"},
		{sound = "ground_control/radio/ghetto/suppress4.mp3", text = "Roll the window down on 'em!"}
	}
}
	
command.onScreenText = "Suppress"
command.onScreenColor = GM.HUDColors.blue
command.menuText = "Suppress this position"
command.displayTime = 5
command.category = GM.RadioCategories.Orders
	
function command:send(ply, commandId, category)
	traceData.start = ply:GetShootPos()
	traceData.endpos = traceData.start + ply:GetAimVector() * 4096
	traceData.filter = ply
	
	local trace = util.TraceLine(traceData)
	
	if not trace.HitSky then
		for key, obj in pairs(team.GetPlayers(ply:Team())) do
			GAMEMODE:sendMarkedSpot(category, commandId, ply, obj, trace.HitPos)
		end
	end
end

function command:receive(sender, commandId, category, data)
	local markPos = data:ReadVector()
	GAMEMODE:AddMarker(markPos, self.onScreenText, self.onScreenColor, self.displayTime)
end

GM:registerRadioCommand(command)

local command = {}
command.variations = {us = {{sound = "ground_control/radio/us/defendthisposition.mp3", text = "Defend this position."}, 
	{sound = "ground_control/radio/us/weneedtodefendthisposition.mp3", text = "We need to defend this position."}},

	aus = {
		{sound = "ground_control/radio/aus/holdhere.mp3", text = "Alright, hold here."},
		{sound = "ground_control/radio/aus/letslookafterthispoint.mp3", text = "Let's look after this point."},
		{sound = "ground_control/radio/aus/setupcamp.mp3", text = "Set up camp right here."},
		{sound = "ground_control/radio/aus/weneedtodefendthisposition.mp3", text = "We need to defend this position."},
		{sound = "ground_control/radio/aus/weneedtoprotectthispoint.mp3", text = "We need to protect this point."}
	},
	
	bandlet = {
		{sound = "ground_control/radio/bandlet/burkalo_na_temechko_zyrytj_v_oba_scha_nabegut.mp3", text = "Буркало на темечко, зырить в обя - ща набегут!"},
		{sound = "ground_control/radio/bandlet/vse_na_streme_i_neher_lybu_davitj_rano.mp3", text = "Все на стремё, и нехер лыбу давить - рано!"}
	},

	rus = {
		{sound = "ground_control/radio/rus/defend1.mp3", text = "Защищаем позицию."},
		{sound = "ground_control/radio/rus/defend2.mp3", text = "Занять оборону!"},
		{sound = "ground_control/radio/rus/defend3.mp3", text = "Занять огневые точки."},
		{sound = "ground_control/radio/rus/defend4.mp3", text = "Круговая оборона!"}
	},
	
	ghetto = {
		{sound = "ground_control/radio/ghetto/defend1.mp3", text = "Don't let them whiteboys come through here!"},
		{sound = "ground_control/radio/ghetto/defend2.mp3", text = "Don't let the fuzz come through here!"},
		{sound = "ground_control/radio/ghetto/defend3.mp3", text = "Defend this place from them pigs!"}
	}
}
	
command.onScreenText = "Defend"
command.onScreenColor = GM.HUDColors.blue
command.menuText = "Defend this position"
command.displayTime = 5
command.category = GM.RadioCategories.Orders
	
function command:send(ply, commandId, category)
	traceData.start = ply:GetShootPos()
	traceData.endpos = traceData.start + ply:GetAimVector() * 4096
	traceData.filter = ply
	
	local trace = util.TraceLine(traceData)
	
	if not trace.HitSky then
		for key, obj in pairs(team.GetPlayers(ply:Team())) do
			GAMEMODE:sendMarkedSpot(category, commandId, ply, obj, trace.HitPos)
		end
	end
end

function command:receive(sender, commandId, category, data)
	local markPos = data:ReadVector()
	GAMEMODE:AddMarker(markPos, self.onScreenText, self.onScreenColor, self.displayTime)
end

GM:registerRadioCommand(command)

local command = {}
command.variations = {us = {{sound = "ground_control/radio/us/followme.mp3", text = "Follow me."},
	{sound = "ground_control/radio/us/onme.mp3", text = "On me."}},

	aus = {
		{sound = "ground_control/radio/aus/comewithme.mp3", text = "Come with me, mate."},
		{sound = "ground_control/radio/aus/matefollowme.mp3", text = "Mate, follow me."},
		{sound = "ground_control/radio/aus/oicomewithme.mp3", text = "Oi, come with me."}
	},
	
	bandlet = {
		{sound = "ground_control/radio/bandlet/podorvalis_i_za_mnoi.mp3", text = "Подорвались, и за мной!"},
		{sound = "ground_control/radio/bandlet/kandehaem_veselee.mp3", text = "Кандёхаем веселее!"}
	},
	
	rus = {
		{sound = "ground_control/radio/rus/follow1.mp3", text = "За мной."},
		{sound = "ground_control/radio/rus/follow2.mp3", text = "Пошли за мной."},
		{sound = "ground_control/radio/rus/follow3.mp3", text = "Все за мной!"},
		{sound = "ground_control/radio/rus/follow4.mp3", text = "Давай, давай, за мной!"}
	},
	
	ghetto = {
		{sound = "ground_control/radio/ghetto/followme1.mp3", text = "Come with me, nigga!"},
		{sound = "ground_control/radio/ghetto/followme2.mp3", text = "Ayo cus', follow me!"},
		{sound = "ground_control/radio/ghetto/followme3.mp3", text = "Follow my black ass!"},
		{sound = "ground_control/radio/ghetto/followme4.mp3", text = "Follow me, bruh!"},
		{sound = "ground_control/radio/ghetto/followme5.mp3", text = "Follow me, bruh!"}
	}
}
	
command.menuText = "Follow me"
command.category = GM.RadioCategories.Orders

GM:registerRadioCommand(command)

local command = {}
command.tipId = "HEAL_TEAMMATES"
command.variations = {us = {{sound = "ground_control/radio/us/ineedamedic.mp3", text = "I need a medic!"},
		{sound = "ground_control/radio/us/ineedamedic2.mp3", text = "I need a medic!"}
	},

	aus = {
		{sound = "ground_control/radio/aus/fuckineedadoctor.mp3", text = "Fuck, I need a doctor!"},
		{sound = "ground_control/radio/aus/ineedamedic.mp3", text = "I need a medic!"},
		{sound = "ground_control/radio/aus/medic.mp3", text = "Medic!"},
		{sound = "ground_control/radio/aus/medicoverhere.mp3", text = "Medic, over here!"}
	},
	
	bandlet = {
		{sound = "ground_control/radio/bandlet/a_eb.mp3", text = "А, ёб!"},
		{sound = "ground_control/radio/bandlet/tvoju_matj.mp3", text = "Твою мать!"}
	},
	
	rus = {
		{sound = "ground_control/radio/rus/medic1.mp3", text = "Врач, мне нужен врач!"},
		{sound = "ground_control/radio/rus/medic2.mp3", text = "Врача сюда!"},
		{sound = "ground_control/radio/rus/medic3.mp3", text = "Врача мне, быстро!"},
		{sound = "ground_control/radio/rus/medic4.mp3", text = "Меня зацепили!"}
	},
	
	ghetto = {
		{sound = "ground_control/radio/ghetto/needmedic1.mp3", text = "Shit, nigga, I need some peace herb!"},
		{sound = "ground_control/radio/ghetto/needmedic2.mp3", text = "Shit, cus', I'm hit!"},
		{sound = "ground_control/radio/ghetto/needmedic3.mp3", text = "Aw fuck, that hurt, nigga!"},
		{sound = "ground_control/radio/ghetto/needmedic4.mp3", text = "Shit, they shot my black ass!"}
	}
}

command.menuText = "Need medic"
command.category = GM.RadioCategories.Combat
command.onScreenText = "Need medic"
command.onScreenColor = GM.HUDColors.blue
command.displayTime = 5

function command:send(ply, commandId, category)
	local ourPos = ply:GetPos()
	ourPos.z = ourPos.z + 32
	
	for key, obj in pairs(team.GetPlayers(ply:Team())) do
		GAMEMODE:sendMarkedSpot(category, commandId, ply, obj, ourPos)
	end
end

function command:receive(sender, commandId, category, data)
	local markPos = data:ReadVector()
	GAMEMODE:AddMarker(markPos, self.onScreenText, self.onScreenColor, self.displayTime)
end

GM:registerRadioCommand(command)

local command = {}
command.tipId = "RESUPPLY_TEAMMATES"
command.variations = {us = {{sound = "ground_control/radio/us/ineedammo.mp3", text = "I need ammo!"}, 
		{sound = "ground_control/radio/us/ineedsomeammo.mp3", text = "I need some ammo!"},
		{sound = "ground_control/radio/us/imrunninglowonammo.mp3", text = "I'm running low on ammo!"}
	},
	
	aus = {
		{sound = "ground_control/radio/aus/doesanyonehaveanyammo.mp3", text = "Does anyone have any ammo?"},
		{sound = "ground_control/radio/aus/ineedammo.mp3", text = "I need ammo!"},
		{sound = "ground_control/radio/aus/runningdry.mp3", text = "I'm running dry, oi, chuck me a mag!"}
	},
	
	bandlet = {
		{sound = "ground_control/radio/bandlet/mlia_nu_on_voobsce_pustoj.mp3", text = "Мля, ну он вообще пустой!"}
	},
	
	rus = {
		{sound = "ground_control/radio/rus/ammo1.mp3", text = "Мне нужны патроны!"},
		{sound = "ground_control/radio/rus/ammo2.mp3", text = "Патроны кончились!"},
		{sound = "ground_control/radio/rus/ammo3.mp3", text = "Давай боекомплект!"},
		{sound = "ground_control/radio/rus/ammo4.mp3", text = "Боеприпасы кончились!"}
	},
	
	ghetto = {
		{sound = "ground_control/radio/ghetto/needammo1.mp3", text = "Shit, I need some bullets!"},
		{sound = "ground_control/radio/ghetto/needammo2.mp3", text = "I need some ammo, cus'!"},
		{sound = "ground_control/radio/ghetto/needammo3.mp3", text = "Damn, man, I need bullets!"},
		{sound = "ground_control/radio/ghetto/needammo4.mp3", text = "Shit, my shooter's all out!"}
	}
}

command.menuText = "Need ammo"
command.category = GM.RadioCategories.Combat
command.onScreenText = "Need ammo"
command.onScreenColor = GM.HUDColors.limeYellow
command.displayTime = 5

function command:send(ply, commandId, category)
	local ourPos = ply:GetPos()
	ourPos.z = ourPos.z + 32
	
	for key, obj in pairs(team.GetPlayers(ply:Team())) do
		GAMEMODE:sendMarkedSpot(category, commandId, ply, obj, ourPos)
	end
end

function command:receive(sender, commandId, category, data)
	local markPos = data:ReadVector()
	GAMEMODE:AddMarker(markPos, self.onScreenText, self.onScreenColor, self.displayTime)
end

GM:registerRadioCommand(command)

local command = {}
command.tipId = "HELP_TEAMMATES"
command.variations = {us = {{sound = "ground_control/radio/us/ineedsomehelphere.mp3", text = "I need some help here!"},
		{sound = "ground_control/radio/us/ineedsomehelpoverhere.mp3", text = "I need some help over here!"}
	},

	aus = {
		{sound = "ground_control/radio/aus/givemeahand.mp3", text = "Oi, give me a hand!"},
		{sound = "ground_control/radio/aus/helpmemate.mp3", text = "Help me, mate!"},
		{sound = "ground_control/radio/aus/oihelpme.mp3", text = "Oi, help me!"}
	},
	
	bandlet = {
		{sound = "ground_control/radio/bandlet/gde_ty_voobsce_uviaz_nas_tut_schas_konchiat.mp3", text = "Где ты вообще увяз?! Нас тут сейчас кончат!"},
		{sound = "ground_control/radio/bandlet/my_schas_zagnemsa_bratan_cheshi_k_nam.mp3", text = "Мы сейчас загнёмся, братан, чеши к нам!"}
	},
	
	rus = {
		{sound = "ground_control/radio/rus/help1.mp3", text = "Нужна помощь!"},
		{sound = "ground_control/radio/rus/help2.mp3", text = "Нужна подмога."},
		{sound = "ground_control/radio/rus/help3.mp3", text = "Нужна помощь!"}
	},
	
	ghetto = {
		{sound = "ground_control/radio/ghetto/help1.mp3", text = "I need help, cus!"},
		{sound = "ground_control/radio/ghetto/help2.mp3", text = "Shit, help, niggas!"},
		{sound = "ground_control/radio/ghetto/help3.mp3", text = "Fuck man, I need help!"},
		{sound = "ground_control/radio/ghetto/help4.mp3", text = "Help me out, niggas!"}
	}
}

command.menuText = "Need help"
command.category = GM.RadioCategories.Status
command.onScreenText = "Need help"
command.onScreenColor = GM.HUDColors.blue
command.displayTime = 5

function command:send(ply, commandId, category)
	local ourPos = ply:GetPos()
	ourPos.z = ourPos.z + 32
	
	for key, obj in pairs(team.GetPlayers(ply:Team())) do
		GAMEMODE:sendMarkedSpot(category, commandId, ply, obj, ourPos)
	end
end

function command:receive(sender, commandId, category, data)
	local markPos = data:ReadVector()
	GAMEMODE:AddMarker(markPos, self.onScreenText, self.onScreenColor, self.displayTime)
end

GM:registerRadioCommand(command)

local command = {}
command.variations = {us = {{sound = "ground_control/radio/us/impinneddown.mp3", text = "I'm pinned down!"},
		{sound = "ground_control/radio/us/impinneddown2.mp3", text = "I'm pinned down!"}
	},

	aus = {
		{sound = "ground_control/radio/aus/theyreontome.mp3", text = "They're on to me, mate!"},
		{sound = "ground_control/radio/aus/theyreshootingatme.mp3", text = "They're shooting at me!"},
		{sound = "ground_control/radio/aus/iampinneddown.mp3", text = "I am pinned down, fuck me!"}
	},
	
	bandlet = {
		{sound = "ground_control/radio/bandlet/gde_ty_voobsce_uviaz_nas_tut_schas_konchiat.mp3", text = "Где ты вообще увяз?! Нас тут сейчас кончат!"},
		{sound = "ground_control/radio/bandlet/my_schas_zagnemsa_bratan_cheshi_k_nam.mp3", text = "Мы сейчас загнёмся, братан, чеши к нам!"}
	},
	
	rus = {
		{sound = "ground_control/radio/rus/pinned1.mp3", text = "Зажали суки, где помощь?!"},
		{sound = "ground_control/radio/rus/pinned2.mp3", text = "Мне нужна подмога, бля!"},
		{sound = "ground_control/radio/rus/pinned3.mp3", text = "Меня зажали, где помощь?!"}
	},
	
	ghetto = {
		{sound = "ground_control/radio/ghetto/pinned1.mp3", text = "Shit, I'm surrounded!"},
		{sound = "ground_control/radio/ghetto/pinned2.mp3", text = "Fuck, I'm surrounded, niggas!"},
		{sound = "ground_control/radio/ghetto/pinned3.mp3", text = "Damn, I'm pinned down or some shit!"}
	}
}

command.menuText = "Pinned down"
command.category = GM.RadioCategories.Status
command.onScreenText = "Pinned down"
command.onScreenColor = GM.HUDColors.red
command.displayTime = 5

function command:send(ply, commandId, category)
	local ourPos = ply:GetPos()
	ourPos.z = ourPos.z + 32
	
	for key, obj in pairs(team.GetPlayers(ply:Team())) do
		GAMEMODE:sendMarkedSpot(category, commandId, ply, obj, ourPos)
	end
end

function command:receive(sender, commandId, category, data)
	local markPos = data:ReadVector()
	GAMEMODE:AddMarker(markPos, self.onScreenText, self.onScreenColor, self.displayTime)
end

GM:registerRadioCommand(command)

local command = {}
command.variations = {us = {{sound = "ground_control/radio/us/approachingenemyposition.mp3", text = "Approaching enemy position!"},
		{sound = "ground_control/radio/us/closinginonenemyposition.mp3", text = "Closing in on enemy position!"}
	},
	
	aus = {
		{sound = "ground_control/radio/aus/watchthisgonnagetthedroponthem.mp3", text = "Watch this, I'm gonna get the drop on them."},
		{sound = "ground_control/radio/aus/theyllneverknowwhathitem.mp3", text = "They'll never know what hit 'em."},
		{sound = "ground_control/radio/aus/imapproachingthecontacts.mp3", text = "I'm approaching the contacts!"},
		{sound = "ground_control/radio/aus/gonnamakeamove.mp3", text = "I'm gonna make a move on them!"},
	},
	
	bandlet = {
		{sound = "ground_control/radio/bandlet/scha_vseh_poreshu.mp3", text = "Сейчас всех порешу!"},
		{sound = "ground_control/radio/bandlet/ne_tremsia_kodla_ne_tremsia.mp3", text = "Не трёмся кодла, не трёмся!"}
	},
	
	rus = {
		{sound = "ground_control/radio/rus/approaching1.mp3", text = "Подхожу к врагу."},
		{sound = "ground_control/radio/rus/approaching2.mp3", text = "Двигаюсь к врагу."},
		{sound = "ground_control/radio/rus/approaching3.mp3", text = "Приближаюсь к врагу."},
		{sound = "ground_control/radio/rus/approaching4.mp3", text = "Иду на контакт."},
		{sound = "ground_control/radio/rus/approaching5.mp3", text = "Иду на врага."},
		{sound = "ground_control/radio/rus/approaching6lel.mp3", text = "Иду на врага мамку."}
	},
	
	ghetto = {
		{sound = "ground_control/radio/ghetto/approaching1.mp3", text = "Aight, I'mma move up on these whiteboys!"},
		{sound = "ground_control/radio/ghetto/approaching2.mp3", text = "I'mma get closer to them pigs!"},
		{sound = "ground_control/radio/ghetto/approaching3.mp3", text = "I'm moving up on those punk-asses!"}
	}
}

command.menuText = "Approaching enemy"
command.category = GM.RadioCategories.Status
command.onScreenText = "Approaching enemy"
command.onScreenColor = GM.HUDColors.limeYellow
command.displayTime = 5
command.radioWait = 2.5

function command:send(ply, commandId, category)
	local ourPos = ply:GetPos()
	ourPos.z = ourPos.z + 32
	
	for key, obj in pairs(team.GetPlayers(ply:Team())) do
		GAMEMODE:sendMarkedSpot(category, commandId, ply, obj, ourPos)
	end
end

function command:receive(sender, commandId, category, data)
	local markPos = data:ReadVector()
	GAMEMODE:AddMarker(markPos, self.onScreenText, self.onScreenColor, self.displayTime)
end

GM:registerRadioCommand(command)

local command = {}
command.variations = {
	us = {{sound = "ground_control/radio/us/fragout.mp3", text = "Frag out!"},
		{sound = "ground_control/radio/us/fragout2.mp3", text = "Frag out!"},
		{sound = "ground_control/radio/us/throwingagrenade.mp3", text = "Throwing a grenade!"},
		{sound = "ground_control/radio/us/grenade.mp3", text = "Grenade!"}
	},
	
	aus = {
		{sound = "ground_control/radio/aus/fragout.mp3", text = "Frag out!"},
		{sound = "ground_control/radio/aus/grenade.mp3", text = "Grenade!"},
		{sound = "ground_control/radio/aus/throwingafrag.mp3", text = "Throwing a frag!"},
		{sound = "ground_control/radio/aus/throwinggrenade.mp3", text = "Throwing grenade!"}
	},
	
	bandlet = {
		{sound = "ground_control/radio/bandlet/kushaj_jablochko_suka.mp3", text = "Кушай яблочко, сука!"},
		{sound = "ground_control/radio/bandlet/limonchik_tebe_pindosina.mp3", text = "Лимончик тебе, пиндосина!"},
		{sound = "ground_control/radio/bandlet/na_suka_jablochko.mp3", text = "На, сука, яблочко!"}
	},
	
	rus = {
		{sound = "ground_control/radio/rus/fragout1.mp3", text = "Граната пошла."},
		{sound = "ground_control/radio/rus/fragout2.mp3", text = "Лимонка."},
		{sound = "ground_control/radio/rus/fragout3.mp3", text = "Кидаю лимонку."},
		{sound = "ground_control/radio/rus/fragout4.mp3", text = "Кидаю лимонку!"},
		{sound = "ground_control/radio/rus/fragout5.mp3", text = "Граната."},
		{sound = "ground_control/radio/rus/fragout6.mp3", text = "Шухер!"}
	},
	
	ghetto = {
		{sound = "ground_control/radio/ghetto/fragout1.mp3", text = "Fire in the hole, or some shit."},
		{sound = "ground_control/radio/ghetto/fragout2.mp3", text = "Watch out, niggas!"},
		{sound = "ground_control/radio/ghetto/fragout3.mp3", text = "Fire in the hole!"},
		{sound = "ground_control/radio/ghetto/fragout4.mp3", text = "Frag out, motherfuckers!"},
		{sound = "ground_control/radio/ghetto/fragout5.mp3", text = "Watch yo ass, I's be throwin dynamite!"},
		{sound = "ground_control/radio/ghetto/fragout6.mp3", text = "Ey, I'm throwin some explosives, look out!"}
	}
}

command.menuText = "Frag out"
command.category = GM.RadioCategories.special
command.tipId = "THROW_FRAGS"

GM:registerRadioCommand(command)

local command = {}
command.variations = {
	us = {
		{sound = "ground_control/radio/us/clear.mp3", text = "Clear."},
		{sound = "ground_control/radio/us/sectorclear.mp3", text = "Sector clear."}
	},
	
	aus = {
		{sound = "ground_control/radio/aus/clear.mp3", text = "Clear."},
		{sound = "ground_control/radio/aus/sectorclear.mp3", text = "Sector clear."},
		{sound = "ground_control/radio/aus/wereallgood.mp3", text = "We're all good, sector clear."},
		{sound = "ground_control/radio/aus/wereclear.mp3", text = "We're clear."},
		{sound = "ground_control/radio/aus/wereclearmate.mp3", text = "We're clear, mate."}
	},
	
	bandlet = {
		{sound = "ground_control/radio/bandlet/naidem_na_meha_porezhem.mp3", text = "Найдем - на меха порежем!"},
		{sound = "ground_control/radio/bandlet/nu_gde_ty_zanikalsa.mp3", text = "Ну где ты заныкался?"},
		{sound = "ground_control/radio/bandlet/vyhodi_po_horoshemu.mp3", text = "Выходи по-хорошему!"},
		{sound = "ground_control/radio/bandlet/vyhodi_poliubomu_naidem.mp3", text = "Выходи, по-любому найдём!"}
	},
	
	rus = {
		{sound = "ground_control/radio/rus/clear1.mp3", text = "Чисто."},
		{sound = "ground_control/radio/rus/clear2.mp3", text = "Все чисто."}
	},
	
	ghetto = {
		{sound = "ground_control/radio/ghetto/areaclear1.mp3", text = "Ain't nobody here."},
		{sound = "ground_control/radio/ghetto/areaclear2.mp3", text = "Area clear, niggas."},
		{sound = "ground_control/radio/ghetto/areaclear3.mp3", text = "Nobody here, bruh."},
		{sound = "ground_control/radio/ghetto/areaclear4.mp3", text = "Ain't no twelve around here."}
	}
}

command.menuText = "Area clear"
command.category = GM.RadioCategories.Status
command.onScreenText = "Area clear"
command.onScreenColor = GM.HUDColors.green
command.displayTime = 5

function command:send(ply, commandId, category)
	local ourPos = ply:GetPos()
	ourPos.z = ourPos.z + 32
	
	for key, obj in pairs(team.GetPlayers(ply:Team())) do
		GAMEMODE:sendMarkedSpot(category, commandId, ply, obj, ourPos)
	end
end

function command:receive(sender, commandId, category, data)
	local markPos = data:ReadVector()
	GAMEMODE:AddMarker(markPos, self.onScreenText, self.onScreenColor, self.displayTime)
end

GM:registerRadioCommand(command)

local command = {}
command.variations = {
	us = {
		{sound = "ground_control/radio/us/getemfrombehind.mp3", text = "Get 'em from behind!"},
		{sound = "ground_control/radio/us/flankthem.mp3", text = "Flank them!"}
	},
	
	aus = {
		{sound = "ground_control/radio/aus/getbehindthem.mp3", text = "Get behind them!"},
		{sound = "ground_control/radio/aus/getbehindthemmate.mp3", text = "Hey, get behind them, mate!"},
		{sound = "ground_control/radio/aus/oiflankem.mp3", text = "Oi, flank 'em!"}
	},
	
	bandlet = {
		{sound = "ground_control/radio/bandlet/bystro_obhodi_obhodi_etu_sheluponj.mp3", text = "Быстро - обходи, обходи эту шелупонь!"},
		{sound = "ground_control/radio/bandlet/ne_mandrazhuj_pocani_obhodim.mp3", text = "Не мандражуй, пацаны, обходим!"}
	},
	
	rus = {
		{sound = "ground_control/radio/rus/flank1.mp3", text = "Обходи, обходи!"},
		{sound = "ground_control/radio/rus/flank2.mp3", text = "Давай заходи с боку, сбоку!"},
		{sound = "ground_control/radio/rus/flank3.mp3", text = "С бока заходи!"},
		{sound = "ground_control/radio/rus/flank4.mp3", text = "Схади заходи, заходи сзади!"}
	},
	
	ghetto = {
		{sound = "ground_control/radio/ghetto/flankthem1.mp3", text = "Ey, go around them, niggas!"},
		{sound = "ground_control/radio/ghetto/flankthem2.mp3", text = "Get behind 'em and blast 'em fools!"},
		{sound = "ground_control/radio/ghetto/flankthem3.mp3", text = "Get around them pigs!"},
		{sound = "ground_control/radio/ghetto/flankthem4.mp3", text = "Go around them pigs!"}
	}
}

command.menuText = "Flank them"
command.category = GM.RadioCategories.Orders

GM:registerRadioCommand(command)

local command = {}
command.variations = {
	us = {
		{sound = "ground_control/radio/us/go.mp3", text = "Go!"},
		{sound = "ground_control/radio/us/gogogo.mp3", text = "Go, go, go!"},
		{sound = "ground_control/radio/us/move.mp3", text = "Move!"}
	},
	
	aus = {
		{sound = "ground_control/radio/aus/fuckingmove.mp3", text = "Fucking move!"},
		{sound = "ground_control/radio/aus/go.mp3", text = "Go!"},
		{sound = "ground_control/radio/aus/gogogo.mp3", text = "Go, go, go!"},
		{sound = "ground_control/radio/aus/move.mp3", text = "Move!"},
		{sound = "ground_control/radio/aus/moveit.mp3", text = "Move it!"}
	},
	
	bandlet = {
		{sound = "ground_control/radio/bandlet/a_nu_davaj_davaj.mp3", text = "А ну давай, давай!"},
		{sound = "ground_control/radio/bandlet/nu_podorvali_pocani.mp3", text = "Ну, подорвали, пацаны!"}
	},
	
	rus = {
		{sound = "ground_control/radio/rus/move1.mp3", text = "Пошли."},
		{sound = "ground_control/radio/rus/move2.mp3", text = "Вперед, вперед!"},
		{sound = "ground_control/radio/rus/move3.mp3", text = "Двигай!"}
	},
	
	ghetto = {
		{sound = "ground_control/radio/ghetto/move1.mp3", text = "Ey, move your black ass!"},
		{sound = "ground_control/radio/ghetto/move2.mp3", text = "Hurry up, nigga!"},
		{sound = "ground_control/radio/ghetto/move3.mp3", text = "Move, cus'!"},
		{sound = "ground_control/radio/ghetto/move4.mp3", text = "Move, bruh!"},
		{sound = "ground_control/radio/ghetto/move5.mp3", text = "Move up, niggas!"},
		{sound = "ground_control/radio/ghetto/move6.mp3", text = "Go, go, go, motherfuckers!"}
	}
}

command.menuText = "Move"
command.category = GM.RadioCategories.Orders

GM:registerRadioCommand(command)