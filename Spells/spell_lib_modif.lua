local addon, ATTdefault = ...
 
 dbRacial = {
	{["ability"] = 316231, ["id"] = 316231, ["cooldown"] = 120, ["race"] =  "Human" }, 
	{["ability"] = 316372, ["id"] = 316372, ["cooldown"] = 90, ["race"] =  "Orc" },
	{["ability"] = 316243, ["id"] = 316243, ["cooldown"] = 120, ["race"] =  "Dwarf" }, 
	{["ability"] = 316254, ["id"] = 316254, ["cooldown"] = 120, ["race"] =  "NightElf" },
	{["ability"] = 316380, ["id"] = 316380, ["cooldown"] = 120, ["race"] =  "Scourge" },
	{["ability"] = 316386, ["id"] = 316386, ["cooldown"] = 90,  ["race"] =  "Tauren" },
	{["ability"] = 316271, ["id"] = 316271, ["cooldown"] = 120,  ["race"] =  "Gnome" }, 
	{["ability"] = 316405, ["id"] = 316405, ["cooldown"] = 90, ["race"] =  "Troll" },
	{["ability"] = 316413, ["id"] = 316413, ["cooldown"] = 90, ["race"] =  "Naga" },
	{["ability"] = 316279, ["id"] = 316279, ["cooldown"] = 120, ["race"] =  "Draenei" },
	{["ability"] = 316393, ["id"] = 316393, ["cooldown"] = 120, ["race"] =  "Goblin" },
	{["ability"] = 316294, ["id"] = 316294, ["cooldown"] = 90, ["race"] =  "Queldo" }, 
	{["ability"] = 316443, ["id"] = 316443, ["cooldown"] = 120, ["race"] =  "Pandaren" },
	{["ability"] = 316289, ["id"] = 316289, ["cooldown"] = 90, ["race"] =  "Worgen" }, 
	{["ability"] = 316455, ["id"] = 316455, ["cooldown"] = 90, ["race"] =  "Vulpera" },
	{["ability"] = 316367, ["id"] = 316367, ["cooldown"] = 90, ["race"] =  "VoidElf" },
	{["ability"] = 316431, ["id"] = 316431, ["cooldown"] = 30, ["race"] =  "Nightborne" },
	{["ability"] = 316161, ["id"] = 316161, ["cooldown"] = 90, ["race"] =  "DarkIronDwarf" },
	{["ability"] = 316465, ["id"] = 316465, ["cooldown"] = 60, ["race"] =  "Eredar" },
	{["ability"] = 310810, ["id"] = 310810, ["cooldown"] = 120, ["race"] =  "ZandalariTroll" },
	{["ability"] = 319322, ["id"] = 319322, ["cooldown"] = 90, ["race"] =  "Lightforged" },
	{["ability"] = 320552, ["id"] = 320552, ["cooldown"] = 120, ["race"] =  "Dracthyr" },
 }

constellations = {
	[371796] = {
		id = 316231,
		icon = select(3, GetSpellInfo(316231)),
		cd = 120,
	},
	[371804] = {
		id = 316380,
		icon = select(3, GetSpellInfo(316380)),
		cd = 120,
	},
	[371798] = {
		id = 316413,
		icon = select(3, GetSpellInfo(316413)),
		cd = 90,
	},
	[371808] = {
		id = 316455,
		icon = select(3, GetSpellInfo(316455)),
		cd = 90,
	},
	[371795] = {
		id = 316393,
		icon = select(3, GetSpellInfo(316393)),
		cd = 120,
	},
	[371791] = {
		id = 316279,
		icon = select(3, GetSpellInfo(316279)),
		cd = 120,
	},
	[371801] = {
		id = 316372,
		icon = select(3, GetSpellInfo(316372)),
		cd = 90,
	},
	[371803] = {
		id = 316294,
		icon = select(3, GetSpellInfo(316294)),
		cd = 90,
	},
	[371788] = { --синд
		id = 316418,
		alt = {["316421"] = 1, ["302387"] = 1, ["316419"] = 1, ["316420"] = 1},
		icon = select(3, GetSpellInfo(316418)),
		cd = 90,
	},
	[371805] = {
		id = 316386,
		icon = select(3, GetSpellInfo(316386)),
		cd = 90,
	},
	[371806] = {
		id = 316405,
		icon = select(3, GetSpellInfo(316405)),
		cd = 90,
	},
	[371800] = {
		id = 316254,
		icon = select(3, GetSpellInfo(316254)),
		cd = 120,
	},
	[371802] = {
		id = 316443,
		icon = select(3, GetSpellInfo(316443)),
		cd = 120,
	},
	[371792] = {
		id = 316243,
		icon = select(3, GetSpellInfo(316243)),
		cd = 120,
	},
	[371794] = {
		id = 316271,
		icon = select(3, GetSpellInfo(316271)),
		cd = 120,
	},
	[371809] = {
		id = 316289,
		icon = select(3, GetSpellInfo(316289)),
		cd = 90,
	},
	[371799] = {
		id = 316431,
		icon = select(3, GetSpellInfo(316431)),
		cd = 30,
	},
	[371807] = {
		id = 316367,
		icon = select(3, GetSpellInfo(316367)),
		cd = 90,
	},
	[371789] = {
		id = 316161,
		icon = select(3, GetSpellInfo(316161)),
		cd = 90,
	},
	[371793] = {
		id = 316465,
		icon = select(3, GetSpellInfo(316465)),
		cd = 60,
	},
	[371810] = {
		id = 310810,
		icon = select(3, GetSpellInfo(310810)),
		cd = 90,
	},
	[371797] = {
		id = 319322,
		icon = select(3, GetSpellInfo(319322)),
		cd = 90,
	},
	[371790] = {
		id = 320552,
		icon = select(3, GetSpellInfo(320552)),
		cd = 120,
	}
}

 dbTrinket = {
	{["ability"] = 42292, ["id"] = 42292, ["cooldown"] = 120},
 }
 
 dbSpecs = {
	["MAGE"] = {
		["Arcane"] = 1,
		["Fire"] = 2,
		["Frost"] = 3,
	},
	["ROGUE"] = {
		["Assassination"] = 1,
		["Combat"] = 2,
		["Subtlety"] = 3,
	},
	["PALADIN"] = {
		["Holy"] = 1,
		["Protection"] = 2,
		["Retribution"] = 3,
	},
	["DEATHKNIGHT"] = {
		["Blood"] = 1,
		["Frost"] = 2,
		["Unholy"] = 3,
	},
	["DRUID"] = {
		["Balance"] = 1,
		["Feral"] = 2,
		["Restoration"] = 3,
	},
	["HUNTER"] = {
		["Beast Mastery"] = 1,
		["Marksmanship"] = 2,
		["Survival"] = 3,
	},
	["PRIEST"] = {
		["Discipline"] = 1,
		["Holy"] = 2,
		["Shadow Magic"] = 3,
	},
	["SHAMAN"] = {
		["Elemental Combat"] = 1,
		["Enhancement"] = 2,
		["Restoration"] = 3,
	},
	["WARLOCK"] = {
		["Affliction"] = 1,
		["Demonology"] = 2,
		["Destruction"] = 3,
	},
	["WARRIOR"] = {
		["Arms"] = 1,
		["Fury"] = 2,
		["Protection"] = 3,
	},
 }
 
dbSpecAbilities = {
	["ROGUE"] = {
		[14185] = { -- Preparation
			talentGroup = 3,
			index = 14,
		},
		[51713] = { -- Shadow Dance
			talentGroup = 3,
			index = 28,
		},
		[36554] = { -- Shadow Step
			talentGroup = 3,
			index = 25,
		},
		[51690] = { -- Killing Spree
			talentGroup = 2,
			index = 28,
		},
		[14177] = { -- Cold Blood
			talentGroup = 1,
			index = 13,
		},
	},
	["PRIEST"] = {
		[47585] = { -- Dispersion
			talentGroup = 3,
			index = 27,
		},
		[33206] = { -- Pain Suppression
			talentGroup = 1,
			index = 25,
		},
		[15487] = { -- Silence
			talentGroup = 3,
			index = 13,
		},
		[64044] = { -- Psychic Horror
			talentGroup = 3,
			index = 23,
		},
	},
	["DRUID"] = {
		[53201] = {  -- Starfall
			talentGroup = 1,
			index = 28,
		},
		[61336] = { -- Survival Instincts
			talentGroup = 2,
			index = 7,
		},
		[16979] = {  -- Feral Charge - Bear
			talentGroup = 2,
			index = 14,
		},
		[50334] = { -- Berserk
			talentGroup = 2,
			index = 30,
		},
		[17116] = { -- Nature's Swiftness
			talentGroup = 3,
			index = 12,
		},
		[18562] = { -- Swiftmend
			talentGroup = 3,
			index = 18,
		},
	},
	["HUNTER"] = {
		[19574] = { -- Bestial Wrath
			talentGroup = 1,
			index = 18,
		},
		[23989] = { -- Readiness
			talentGroup = 2,
			index = 14,
		},
		[34490] = { -- Silencing Shot
			talentGroup = 2,
			index = 24,
		},
		[19503] = { -- Scatter Shot
			talentGroup = 3,
			index = 9,
		},
		[49012] = { -- Wyvern Sting
			talentGroup = 3,
			index = 20,
		},
	},
	["MAGE"] = 	{
		[12043] = { -- Presence of Mind
			talentGroup = 1,
			index = 16,
		},
		[11129] = { -- Combustion
			talentGroup = 2,
			index = 20,
		},
		[42950] = { -- Dragon's Breath
			talentGroup = 2,
			index = 25,
		},
		[11958] = { -- Cold Snap
			talentGroup = 3,
			index = 14,
		},
		[44572] = { -- Deep Freeze
			talentGroup = 3,
			index = 28,
		},
	},
	["PALADIN"] = {
		[31821] = { -- Aura Mastery
			talentGroup = 1,
			index = 6,
		},
		[48825] = { -- Holy Shock
			talentGroup = 1,
			index = 18,
		},
		[64205] = { -- Divine Sacrifice
			talentGroup = 2,
			index = 6,
		},
		[48827] = { -- Avenger's Shield
			talentGroup = 2,
			index = 22,
		},
		[66008] = { -- Repentance
			talentGroup = 3,
			index = 18,
		},
	},
	["SHAMAN"] = {
		[16188] = { -- Nature's Swiftness
			talentGroup = 3,
			index = 13,
		},
		[16166] = { -- Elemental Mastery
			talentGroup = 1,
			index = 16
		},
		[51490] = { -- Thunderstorm
			talentGroup = 1,
			index = 25,
		},
		[30823] = { -- Shamanistic Rage
			talentGroup = 2,
			index = 26
		},
	},
	["WARLOCK"] = {
		[47847] = { -- Shadowfury
			talentGroup = 3,
			index = 23,
		},
		[18708] = { -- Fel Domination
			talentGroup = 2,
			index = 10,
		},
	},
	["WARRIOR"] = {
		[46924] = { -- Bladestorm
			talentGroup = 1,
			index = 31,
		},
		[12809] = { -- Concussion Blow
			talentGroup = 3,
			index = 14,
		},
		[46968] = { -- Shockwave
			talentGroup = 3,
			index = 27,
		},
	},
	["DEATHKNIGHT"] = {
		[49039] = { -- Lichborne
			talentGroup = 2,
			index = 8,
		},
		[49203] = { -- Hungering Cold
			talentGroup = 2,
			index = 20,
		},
		[51271] = { -- Unbreakable Armor
			talentGroup = 2,
			index = 24,
		},
		[51052] = { -- Anti-Magic Zone
			talentGroup = 3,
			index = 22,
		},
		[49206] = { -- Summon Gargoyle
			talentGroup = 3,
			index = 31,
		},
	},
}

overallCooldowns = {
	["Human"] = {
		[316231] = 90,
		[42292] = 90,
	},
	["Scourge"] = {
		[316380] = 45,
	},
}
