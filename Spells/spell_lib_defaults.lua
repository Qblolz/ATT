local addon, ATTdefault = ...

 ATTdefault.defaultAbilities = {
	["DRUID"] = {
		["ALL"] = {	-- All specs
			{29166, 180}, -- Innervate
			{22812, 60},  -- Barkskin
			{8983, 60},   -- Bash
		},
		["Feral"] = {
			{50334, 180}, -- Berserk
			{16979, 15},  -- Feral Charge - Bear
			{61336, 180}, -- Survival Instincts
		},
		["Restoration"] = {
			{17116, 180}, -- Nature's Swiftness
			{18562, 13},  -- Swiftmend
		},
		["Balance"] = {
			{53201, 60},  -- Starfall
		},
	},
	["HUNTER"] = {
		["ALL"] = {	-- All specs
			{14311, 28},  -- Freezing Trap
			{19503, 30},  -- Scatter Shot
			{60192, 28},  -- Freezing Arrow
			{13809, 28},  -- Frost Trap			
			{19263, 90},  -- Deterrence
			{67481, 60},  -- Roar of Sacrifice
			{53271, 60},  -- Master's Call
			
		},
		["Beast Mastery"] = {
			{19574, 120}, -- Bestial Wrath
		},
		["Marksmanship"] = {
			{34490, 20},  -- Silencing Shot
			{23989, 180}, -- Readiness
		},
		["Survival"] = {
			{49012, 30},  -- Wyvern Sting
		},
	},
	["MAGE"] = 	{
		["ALL"] = {	-- All specs
			{1953, 15},   -- Blink
			{2139, 24},   -- Counterspell
			{12051, 240}, -- Evocation
			{45438, 300}, -- Ice Block
		},
		["Frost"] = {
			{44572, 30},  -- Deep Freeze
			{11958, 384}, -- Cold Snap
		},
		["Fire"] = {
			{11129, 120}, -- Combustion
			{42950, 20}, -- Dragon's Breath
		},
		["Arcane"] = {
			{12043, 60}, -- Presence of Mind
		},
	},
	["PALADIN"] = {
		["ALL"] = {	-- All specs
			{10308, 40},  -- Hammer of Justice
			{1044, 25},   -- Hand of Freedom
			{54428, 60},  -- Divine Plea
			{6940, 120},  -- Hand of Sacrifice
			{10278, 180}, -- Hand of Protection
			{642, 300},   -- Divine Shield
			{64205, 120}, -- Divine Sacrifice
			{48827, 30},  -- Avenger's Shield
		},
		["Retribution"] = {
			{66008, 60},  -- Repentance
		},
		["Holy"] = {
			{31821, 120}, -- Aura Mastery
			{48825, 5},   -- Holy Shock
		},
		["Protection"] = {},
	},
	["PRIEST"] = {
		["ALL"] = {	-- All specs	
			{10890,27},  -- Psychic Scream
			{48158, 12},  -- Shadow World: Death
			{34433, 300}, -- Shadowfiend
			{6346, 180}, -- Fear Ward
		},
		["Discipline"] = {
			{33206, 144}, -- Pain Suppression
		},
		["Holy"] = {},
		["Shadow Magic"] = {
			{47585, 75}, -- Dispersion
			{15487, 45}, -- Silence 
			{64044, 120}, -- Psychic Horror
		},
	},
	["ROGUE"] = {
		["ALL"] = {	-- All specs
			{1766, 10},   -- Kick
			{8643, 20},   -- Kidney Shot
			{31224, 60},  -- Cloak of Shadows
			{51722, 60},  -- Dismantle
			{2094, 120},  -- Blind
			{26889, 120}, -- Vanish
		},
		["Assassination"] = {
			{14177, 180}, -- Cold Blood
		},
		["Combat"] = {
			{51690, 120}, -- Killing Spree
		},
		["Subtlety"] = {
			{14185, 300}, -- Preparation
			{51713, 60}, -- Shadow Dance
			{36554, 20}, -- Shadowstep
		},
	},
	["SHAMAN"] = {
		["ALL"] = {	-- All specs
			{57994, 6},   -- Wind Shear
			{51514, 45},  -- Hex
			{8177, 15},   -- Grounding Totem
		},
		["Elemental Combat"] = {
			{51490, 45}, -- Thunderstorm (45s - 10s glyph)
			{16166, 180}, -- Elemental Mastery
		},
		["Enhancement"] = {
			{30823, 60}, -- Shamanistic Rage
		},
		["Restoration"] = {
			{16188, 120}, -- Nature's Swiftness
		},
	},
	["WARLOCK"] = {
		["ALL"] = {	-- All specs
			{19647, 24},  -- Spell Lock
			{17925, 120}, -- Death Coil
			{18708, 180}, -- Fel Domination
			{48011, 8},   -- Devour Magic
			{48020, 30},  -- Demonic Circle: Teleport
			{18708, 180}, -- Fel Domination
		},
		["Affliction"] = {
		},
		["Demonology"] = {
		},
		["Destruction"] = {
			{47847, 20},  -- Shadowfury
		},
	},
	["WARRIOR"] = {
		["ALL"] = {	-- All specs
			{6552, 10},   -- Pummel
			{72, 12},     -- Shield Bash
			{11578, 13},  -- Charge
			{47996, 15},  -- Intercept
			{871, 300},   -- Shield Wall
			{2565, 60},   -- Shield Block
			{676, 60},    -- Disarm
		},
		["Arms"] = {
			{46924, 90},  -- Bladestorm
		},
		["Fury"] = {
		},
		["Protection"] = {
			{12809, 30},  -- Concussion Blow
			{46968, 17},  -- Shockwave
		},
	},
	["DEATHKNIGHT"] = {
		["ALL"] = {	-- All specs
			{47528, 10},  -- Mind Freeze
			{48743, 120}, -- Death Pact
			{51052, 120}, -- Anti-Magic Zone
			{49576, 35},  -- Death Grip
			{48707, 45},  -- Anti-Magic Shell
			{49039, 120}, -- Lichborne
			{47476, 120}, -- Strangulate
			{51271, 60},  -- Unbreakable Armor
			{48792, 120}, -- Icebound Fortitude
		},
		["Blood"] = {
		},
		["Frost"] = {
			{49203, 60},  -- Hungering Cold
		},
		["Unholy"] = {
			{47481, 20},  -- Gnaw
			{49206, 180}, -- Summon Gargoyle
		},
	},
}