local addon, ATTdbs = ...

ATTdbs.dbImport = {
	["DRUID"] = {
		{ ["ability"] = 29166, ["cooldown"] = 180, }, -- Innervate --
		{ ["ability"] = 22812, ["cooldown"] = 60, }, -- Barkskin -
		{ ["ability"] = 8983, ["cooldown"] = 60, }, -- Bash --
		{ ["ability"] = 17116, ["cooldown"] = 180, ['talent'] = 1, }, -- Nature's Swiftness - talent
		{ ["ability"] = 27009, ["cooldown"] = 60, }, -- Natures Grasp --talent rank
		{ ["ability"] = 33831, ["cooldown"] = 180, ['talent'] = 1,}, -- Force of Nature	-talent
		{ ["ability"] = 5229, ["cooldown"] = 60, }, -- Enrage
		--{	["ability"] = 27012, ["cooldown"] = 60,}, -- Hurricane
		{ ["ability"] = 26983, ["cooldown"] = 480, }, -- Tranquility
		{ ["ability"] = 33357, ["cooldown"] = 180, }, -- Dash
		{ ["ability"] = 5209, ["cooldown"] = 180, }, -- Challenging Roar *
		{ ["ability"] = 27047, ["cooldown"] = 5, }, -- Growl *
		{ ["ability"] = 9913, ["cooldown"] = 10, }, -- Prowl *
		{ ["ability"] = 26994, ["cooldown"] = 600, }, -- Rebirth * !
		--{	["ability"] = 16864, ["cooldown"] = 10,},  -- Omen of Clarity *
		{ ["ability"] = 16979, ["cooldown"] = 15, }, -- Feral Charge *
		{ ["ability"] = 49376, ["cooldown"] = 30, }, -- Cat Charge *
		{ ["ability"] = 18562, ["cooldown"] = 15, }, -- Swiftmend * - mod -set bonus
		{ ["ability"] = 53201, ["cooldown"] = 90, }, -- Starfall : New * -mod  -glyph
		{ ["ability"] = 61336, ["cooldown"] = 180, }, -- Survival Instincts : New *
		{ ["ability"] = 50334, ["cooldown"] = 180, }, -- Bersek : New *

	},
	["HUNTER"] = {
		{ ["ability"] = 19503, ["cooldown"] = 30, ['talent'] = 1,}, -- Scatter Shot --talent
		{ ["ability"] = 19263, ["cooldown"] = 90, }, -- Deterrence --talent
		{ ["ability"] = 14311, ["cooldown"] = 30, }, -- Freezing Trap -mod
		{ ["ability"] = 13809, ["cooldown"] = 30, }, -- Frost Trap -mod
		{ ["ability"] = 34600, ["cooldown"] = 30, }, -- Snake Trap -mod
		{ ["ability"] = 49067, ["cooldown"] = 30, }, -- Explosive Trap -mod
		{ ["ability"] = 49056, ["cooldown"] = 30, }, -- Immolation Trap
		{ ["ability"] = 34490, ["cooldown"] = 20, ['talent'] = 1,}, -- Silencing Shot -- talent
		{ ["ability"] = 27068, ["cooldown"] = 60, ['talent'] = 1,}, -- Wyvern Sting -- talent rank
		{ ["ability"] = 19577, ["cooldown"] = 60, }, -- Intimidation -- talent
		{ ["ability"] = 3045, ["cooldown"] = 300, }, -- Rapid Fire --mod
		{ ["ability"] = 5384, ["cooldown"] = 30, }, -- Feign Death
		{ ["ability"] = 19574, ["cooldown"] = 120, }, -- Bestial Wrath
		{ ["ability"] = 23989, ["cooldown"] = 180, }, -- Readiness
		{ ["ability"] = 34477, ["cooldown"] = 30, }, -- Misdirection
		{ ["ability"] = 1543, ["cooldown"] = 20, }, -- Flare
		{ ["ability"] = 14327, ["cooldown"] = 30, }, -- Scare Beast
		{ ["ability"] = 27019, ["cooldown"] = 6, }, -- Arcane Shot *
		{ ["ability"] = 36916, ["cooldown"] = 5, }, -- Mongoose Bite *
		{ ["ability"] = 27021, ["cooldown"] = 10, }, -- Multi-Shot *
		{ ["ability"] = 27014, ["cooldown"] = 6, }, -- Raptor Strike *
		{ ["ability"] = 19801, ["cooldown"] = 8, }, -- Tranquilizing Shot *
		--{	["ability"] = 27022, ["cooldown"] = 60,},  -- Volley *
		{ ["ability"] = 27065, ["cooldown"] = 10, }, -- Aimed Shot *
		{ ["ability"] = 27067, ["cooldown"] = 5, }, -- Counterattack *
		{ ["ability"] = 49012, ["cooldown"] = 60, }, -- Wyvern Sting: New * -mod glyph
		{ ["ability"] = 60192, ["cooldown"] = 30, }, -- Freezing Arrow: New * -mod
		{ ["ability"] = 67481, ["cooldown"] = 60, }, -- Roar of Sacrifice: New *
		{ ["ability"] = 53271, ["cooldown"] = 60, }, -- Master's Call: New *
		{ ["ability"] = 63672, ["cooldown"] = 30, }, -- Black Arrow New *

	},
	["MAGE"] = {
		{ ["ability"] = 1953, ["cooldown"] = 15, }, -- Blink
		{ ["ability"] = 2139, ["cooldown"] = 24, }, -- Counterspell
		{ ["ability"] = 45438, ["cooldown"] = 300, }, -- Ice Block -mod
		{ ["ability"] = 12472, ["cooldown"] = 180, ['talent'] = 1,}, -- Icy Veins -- talent
		{ ["ability"] = 31687, ["cooldown"] = 180, ['talent'] = 1,}, -- Summon Water Elemental -- talent -mod
		{ ["ability"] = 12043, ["cooldown"] = 120, ['talent'] = 1,}, -- Presence of Mind -- talent -mod
		{ ["ability"] = 11129, ["cooldown"] = 120, ['talent'] = 1,}, -- Combustion -- talent
		{ ["ability"] = 27087, ["cooldown"] = 10, }, -- Cone of Cold
		{ ["ability"] = 12042, ["cooldown"] = 120, ['talent'] = 1,}, -- Arcane Power -- talent
		{ ["ability"] = 11958, ["cooldown"] = 480, ['talent'] = 1,}, -- Cold Snap	 -- talent -mod
		{ ["ability"] = 42917, ["cooldown"] = 25, }, -- Frost Nova -mod
		{ ["ability"] = 33405, ["cooldown"] = 30, ['talent'] = 1,}, -- Ice Barrier
		{ ["ability"] = 42945, ["cooldown"] = 30, ['talent'] = 1,}, -- Blast Wave
		{ ["ability"] = 66, ["cooldown"] = 180, }, -- Invisibility -mod
		--{   ["ability"] = 28734,  ["cooldown"] = 30, ["race"] = {[1] = 10}, }, --Manatap belf
		{ ["ability"] = 32796, ["cooldown"] = 30, }, -- Frost Ward
		{ ["ability"] = 27128, ["cooldown"] = 30, }, -- Fire Ward
		{ ["ability"] = 27079, ["cooldown"] = 8, }, -- Fire Blast
		{ ["ability"] = 12051, ["cooldown"] = 240, }, -- Evocation
		--{	["ability"] = 33938, ["cooldown"] = 6,},  -- Pyroblast	 -- talent *
		{ ["ability"] = 42950, ["cooldown"] = 20, ['talent'] = 1,}, -- Dragon's Breath : New
		{ ["ability"] = 44572, ["cooldown"] = 30, ['talent'] = 1,}, -- Deep Freeze : New
		{ ["ability"] = 33395, ["cooldown"] = 30, ['talent'] = 1,}, --  Freeze : New --pet

	},
	["PALADIN"] = {
		{ ["ability"] = 10308, ["cooldown"] = 60, }, -- Hammer of Justice  -mod
		{ ["ability"] = 10278, ["cooldown"] = 300, }, -- Blessing of Protection -mod
		{ ["ability"] = 1044, ["cooldown"] = 25, }, -- Blessing of Freedom
		--{	["ability"] = 1020, ["cooldown"] = 300,},   -- Divine Shield : Prot only?
		{ ["ability"] = 642, ["cooldown"] = 300, }, -- Divine Shield : NEW -mod
		{ ["ability"] = 498, ["cooldown"] = 180, }, -- Divine Protection : NEW -mod
		{ ["ability"] = 31884, ["cooldown"] = 180, }, -- Avenging Wrath
		{ ["ability"] = 31842, ["cooldown"] = 180, }, -- Divine Illumination --talent
		{ ["ability"] = 20216, ["cooldown"] = 120, }, -- Divine Favor
		{ ["ability"] = 27139, ["cooldown"] = 30, }, -- Holy Wrath
		--{	["ability"] = 10326, ["cooldown"] = 30,}, -- Turn Evil
		{ ["ability"] = 27154, ["cooldown"] = 1200, }, -- Lay on Hands -mod
		{ ["ability"] = 20271, ["cooldown"] = 10, }, -- Judgement * -mod
		{ ["ability"] = 27180, ["cooldown"] = 6, }, -- Hammer of Wrath *
		{ ["ability"] = 27138, ["cooldown"] = 15, }, -- Exorcism *
		{ ["ability"] = 19752, ["cooldown"] = 600, }, -- Divine Intervention *
		{ ["ability"] = 27173, ["cooldown"] = 8, }, -- Consecration *  Light's Grace!!!!!!! cdr
		{ ["ability"] = 48825, ["cooldown"] = 6, }, -- Holy Shock * - new id --mod Glyph
		{ ["ability"] = 31821, ["cooldown"] = 120, ['talent'] = 1,}, -- Aura Mastery :New *
		{ ["ability"] = 64205, ["cooldown"] = 120, }, -- Divne Sacrifice :New *
		{ ["ability"] = 48827, ["cooldown"] = 30, }, -- Avenger's Shield :New *
		{ ["ability"] = 66008, ["cooldown"] = 60, ['talent'] = 1,}, -- Repentance :New *
		{ ["ability"] = 54428, ["cooldown"] = 60, }, -- Divine Plea :New *
		{ ["ability"] = 6940, ["cooldown"] = 120, }, --  Hand of Sacrifice :New *

	},
	["PRIEST"] = {
		{ ["ability"] = 10890, ["cooldown"] = 30, }, -- Psychic Scream  --mod and glyph?
		{ ["ability"] = 34433, ["cooldown"] = 300, }, -- Shadowfiend --here
		{ ["ability"] = 15487, ["cooldown"] = 45, ['talent'] = 1,}, -- Silence  --talent
		{ ["ability"] = 10060, ["cooldown"] = 120, ['talent'] = 1,}, -- Power Infusion --talent
		{ ["ability"] = 33206, ["cooldown"] = 180, ['talent'] = 1,}, -- Pain Suppression --talent -mod

		{ ["ability"] = 14751, ["cooldown"] = 180, ['talent'] = 1,}, -- Inner Focus -mod
		{ ["ability"] = 6346, ["cooldown"] = 180, }, -- Fear Ward
		--{   ["ability"] = 25467,  ["cooldown"] = 180 ,["race"] = {[1] = 5} ,}, --Devouring Plague --undead
		{ ["ability"] = 25437, ["cooldown"] = 120, ['talent'] = 1,}, --Desperate Prayer --human dwarf
		{ ["ability"] = 28275, ["cooldown"] = 180, ['talent'] = 1,}, -- Lightwell
		--{	["ability"] = 15286, ["cooldown"] = 10,}, -- Vampiric Embrace
		{ ["ability"] = 25375, ["cooldown"] = 8, }, --  Mind Blast -mod
		{ ["ability"] = 47585, ["cooldown"] = 120, ['talent'] = 1,}, --  Dispersion : New -mod Glyph
		{ ["ability"] = 64044, ["cooldown"] = 120, ['talent'] = 1,}, --  Psychic Horror : New
		{ ["ability"] = 48158, ["cooldown"] = 12, }, --  Shadow World: Death : New
		{ ["ability"] = 586, ["cooldown"] = 30, }, --  Fade : New

	},
	["ROGUE"] = {
		{ ["ability"] = 1766, ["cooldown"] = 10, }, -- Kick
		{ ["ability"] = 8643, ["cooldown"] = 20, }, -- Kidney Shot
		{ ["ability"] = 26669, ["cooldown"] = 180, }, -- Evasion
		{ ["ability"] = 31224, ["cooldown"] = 90, }, -- Cloak of Shadows -mod
		{ ["ability"] = 26889, ["cooldown"] = 180, }, -- Vanish  -mod
		{ ["ability"] = 2094, ["cooldown"] = 180, }, -- Blind -mod
		{ ["ability"] = 11305, ["cooldown"] = 180, }, -- Sprint
		{ ["ability"] = 14177, ["cooldown"] = 180, }, -- Cold Blood --talent
		{ ["ability"] = 13750, ["cooldown"] = 180, ['talent'] = 1,}, -- Adrenaline Rush --talent
		{ ["ability"] = 13877, ["cooldown"] = 120, ['talent'] = 1,}, -- Blade Flurry --talent
		{ ["ability"] = 36554, ["cooldown"] = 30, ['talent'] = 1,}, -- Shadowstep --talent -mod
		{ ["ability"] = 14185, ["cooldown"] = 480, ['talent'] = 1,}, -- Preparation --talent -mod
		{ ["ability"] = 1725, ["cooldown"] = 30, }, -- Distract
		{ ["ability"] = 27448, ["cooldown"] = 10, }, -- Feint
		{ ["ability"] = 38764, ["cooldown"] = 10, }, -- Gouge *
		{ ["ability"] = 1787, ["cooldown"] = 10, }, -- Stealth * -mod
		{ ["ability"] = 14278, ["cooldown"] = 20, ['talent'] = 1,}, -- Ghostly Strike *
		{ ["ability"] = 14183, ["cooldown"] = 20, ['talent'] = 1,}, -- Premeditation *
		{ ["ability"] = 14251, ["cooldown"] = 6, }, -- Riposte *
		{ ["ability"] = 51713, ["cooldown"] = 60, ['talent'] = 1,}, -- Shadow Dance: New *
		{ ["ability"] = 51690, ["cooldown"] = 120, ['talent'] = 1,}, -- Killing Spree: New *
		{ ["ability"] = 51722, ["cooldown"] = 60, }, -- Dismantle
		{ ["ability"] = 57934, ["cooldown"] = 30, }, -- Tricks of the Trade: New *


	},
	["SHAMAN"] = {
		{ ["ability"] = 16188, ["cooldown"] = 180, ['talent'] = 1,}, -- Nature's Swiftness --talent --mod set bonus
		{ ["ability"] = 8177, ["cooldown"] = 15, }, -- Grounding Totem
		{ ["ability"] = 30823, ["cooldown"] = 60, ['talent'] = 1,}, -- Shamanistic Rage - talent rank
		{ ["ability"] = 16166, ["cooldown"] = 180, ['talent'] = 1,}, -- Elemental Mastery - talent
		{ ["ability"] = 25454, ["cooldown"] = 6, }, -- Earth Shock
		{ ["ability"] = 25464, ["cooldown"] = 6, }, -- Frost Shock
		{ ["ability"] = 25457, ["cooldown"] = 6, }, -- Flame Shock
		{ ["ability"] = 16190, ["cooldown"] = 300, ['talent'] = 1,}, -- Mana Tide Totem --talent
		{ ["ability"] = 25525, ["cooldown"] = 30, }, -- Stoneclaw Totem
		{ ["ability"] = 2062, ["cooldown"] = 600, }, -- Earth Elemental Totem
		{ ["ability"] = 2894, ["cooldown"] = 600, }, -- Fire Elemental Totem
		{ ["ability"] = 32182, ["cooldown"] = 300, }, -- Heroism	--dranei
		{ ["ability"] = 2825, ["cooldown"] = 300, }, -- Bloodlust	--orc , tauren , troll
		{ ["ability"] = 25442, ["cooldown"] = 6, }, -- Chain Lightning*
		{ ["ability"] = 2484, ["cooldown"] = 15, }, -- Earthbind Totem
		{ ["ability"] = 25547, ["cooldown"] = 10, }, -- Fire Nova Totem*
		{ ["ability"] = 17364, ["cooldown"] = 8, }, -- Stormstrike
		{ ["ability"] = 51490, ["cooldown"] = 45, ['talent'] = 1,}, -- Thunderstorm :New -mod glyph
		{ ["ability"] = 57994, ["cooldown"] = 6, }, -- Wind Shear : New -mod
		{ ["ability"] = 51514, ["cooldown"] = 45, }, -- Hex: New

	},
	["WARLOCK"] = {
		{ ["ability"] = 19647, ["cooldown"] = 24, }, -- Spell Lock
		{ ["ability"] = 17928, ["cooldown"] = 40, }, -- Howl of Terror
		{ ["ability"] = 17925, ["cooldown"] = 120, }, -- Death Coil
		{ ["ability"] = 30546, ["cooldown"] = 15, }, -- Shadowburn -- talent rank
		{ ["ability"] = 18708, ["cooldown"] = 180, ['talent'] = 1,}, -- Fel Domination --talent
		--{	["ability"] = 18288, ["cooldown"] = 180,}, -- Amplify Curse
		{ ["ability"] = 29858, ["cooldown"] = 180, }, -- Soulshatter
		{ ["ability"] = 30910, ["cooldown"] = 60, }, -- Curse of Doom
		--{	["ability"] = 30545, ["cooldown"] = 60,}, -- Soul Fire
		{ ["ability"] = 28610, ["cooldown"] = 30, }, -- Shadow Ward
		{ ["ability"] = 1122, ["cooldown"] = 600, }, -- Inferno
		{ ["ability"] = 18540, ["cooldown"] = 1800, }, -- Ritual of Doom
		{ ["ability"] = 47847, ["cooldown"] = 20, ['talent'] = 1,}, -- Shadowfury : New
		{ ["ability"] = 48011, ["cooldown"] = 8, }, -- Devour Magic : New
		{ ["ability"] = 48020, ["cooldown"] = 30, }, -- Demonic Circle : New

	},
	["WARRIOR"] = {
		{ ["ability"] = 6552, ["cooldown"] = 10, }, -- Pummel
		{ ["ability"] = 23920, ["cooldown"] = 10, }, -- Spell Reflection
		{ ["ability"] = 3411, ["cooldown"] = 30, }, -- Intervene
		{ ["ability"] = 676, ["cooldown"] = 60, }, -- Disarm
		{ ["ability"] = 5246, ["cooldown"] = 120, }, --  Intimidating Shout
		{ ["ability"] = 12292, ["cooldown"] = 180, }, -- Death Wish --talent
		{ ["ability"] = 12975, ["cooldown"] = 180, ['talent'] = 1,}, -- Last Stand --talent
		{ ["ability"] = 12809, ["cooldown"] = 30, }, -- Concussion Blow --talent
		{ ["ability"] = 72, ["cooldown"] = 12, }, -- Shield Bash
		{ ["ability"] = 11578, ["cooldown"] = 15, }, -- Charge -mod -glyph 7%
		{ ["ability"] = 871, ["cooldown"] = 300, }, -- Shield Wall
		{ ["ability"] = 2565, ["cooldown"] = 60, }, -- Shield Block
		{ ["ability"] = 20230, ["cooldown"] = 300, }, -- Retaliation
		{ ["ability"] = 1719, ["cooldown"] = 300, }, -- Recklessness
		{ ["ability"] = 12328, ["cooldown"] = 30, ['talent'] = 1,}, -- Sweeping Strikes
		{ ["ability"] = 18499, ["cooldown"] = 30, }, -- Berserker Rage
		{ ["ability"] = 25266, ["cooldown"] = 120, }, -- Mocking Blow
		{ ["ability"] = 2687, ["cooldown"] = 60, }, -- Bloodrage *
		{ ["ability"] = 1161, ["cooldown"] = 180, }, -- Challenging Shout *
		{ ["ability"] = 355, ["cooldown"] = 8, }, -- Taunt *
		{ ["ability"] = 1680, ["cooldown"] = 10, }, -- Whirlwind *
		{ ["ability"] = 30335, ["cooldown"] = 4, ['talent'] = 1,}, -- Bloodthirst *
		{ ["ability"] = 30330, ["cooldown"] = 6, ['talent'] = 1,}, -- Mortal Strike *
		{ ["ability"] = 30356, ["cooldown"] = 6, }, -- Shield Slam *
		{ ["ability"] = 46924, ["cooldown"] = 90, ['talent'] = 1,}, -- Blade Storm : New *
		{ ["ability"] = 46968, ["cooldown"] = 20, ['talent'] = 1,}, -- Shockwave : New * -mod
		{ ["ability"] = 25275, ["cooldown"] = 30, }, -- intercept : New * -mod

	},
	["DEATHKNIGHT"] = {
		{ ["ability"] = 47528, ["cooldown"] = 10, }, -- Mind Freeze
		{ ["ability"] = 47481, ["cooldown"] = 60, }, -- Gnaw -mod ??
		{ ["ability"] = 48743, ["cooldown"] = 120, }, -- Death Pact
		{ ["ability"] = 49206, ["cooldown"] = 180, ['talent'] = 1,}, -- Summon Gargoyle
		{ ["ability"] = 51052, ["cooldown"] = 120, }, -- Anti-Magic Zone
		{ ["ability"] = 49576, ["cooldown"] = 35, }, -- Death Grip
		{ ["ability"] = 48707, ["cooldown"] = 45, }, -- Anti-Magic Shell
		{ ["ability"] = 47476, ["cooldown"] = 120, }, -- Strangulate
		{ ["ability"] = 49039, ["cooldown"] = 120, ['talent'] = 1,}, -- Lichborne
		{ ["ability"] = 49203, ["cooldown"] = 60, }, -- Hungering Cold
		{ ["ability"] = 51271, ["cooldown"] = 60, ['talent'] = 1,}, -- Unbreakable Armor
		{ ["ability"] = 48792, ["cooldown"] = 120, }, -- Icebound Fortitude
	},

}

ATTdbs.constellations = {
    [371796] = {
        ['constellation'] = 371796, ['ability'] = 375015, ['texture'] = select(3, GetSpellInfo(375015)), ['cooldown'] = 120,
    },
    [371804] = {
        ['constellation'] = 371804, ['ability'] = 374992, ['texture'] = select(3, GetSpellInfo(374992)), ['cooldown'] = 120,
    },
    [371798] = {
        ['constellation'] = 371798, ['ability'] = 374999, ['texture'] = select(3, GetSpellInfo(374999)), ['cooldown'] = 120,
    },
    [371808] = {
        ['constellation'] = 371808, ['ability'] = 375038, ['texture'] = select(3, GetSpellInfo(375038)), ['cooldown'] = 120,
    },
    [371795] = {
        ['constellation'] = 371795, ['ability'] = 374997, ['texture'] = select(3, GetSpellInfo(374997)), ['cooldown'] = 120,
    },
    [371791] = {
        ['constellation'] = 371791, ['ability'] = 375020, ['texture'] = select(3, GetSpellInfo(375020)), ['cooldown'] = 120,
    },
    [371801] = {
        ['constellation'] = 371801, ['ability'] = 374988, ['texture'] = select(3, GetSpellInfo(374988)), ['cooldown'] = 120,
    },
    [371803] = {
        ['constellation'] = 371803, ['ability'] = 375024, ['texture'] = select(3, GetSpellInfo(375024)), ['cooldown'] = 120,
    },
    [371788] = {
        ['constellation'] = 371788, ['ability'] = 375001, ['texture'] = select(3, GetSpellInfo(316418)), ['cooldown'] = 120,
        ['alt'] = {[316421] = 1, [302387] = 1, [316419] = 1, [316420] = 1},
    },
    [371805] = {
        ['constellation'] = 371805, ['ability'] = 374994, ['texture'] = select(3, GetSpellInfo(316386)), ['cooldown'] = 120,
    },
    [371806] = {
        ['constellation'] = 371806, ['ability'] = 374996, ['texture'] = select(3, GetSpellInfo(374996)), ['cooldown'] = 120,
    },
    [371800] = {
        ['constellation'] = 371800, ['ability'] = 375018, ['texture'] = select(3, GetSpellInfo(316254)), ['cooldown'] = 120,
        --['alt'] = {[130] = 1}, -- debug
    },
    [371802] = {
        ['constellation'] = 371802, ['ability'] = 375035, ['texture'] = select(3, GetSpellInfo(375035)), ['cooldown'] = 120,
    },
    [371792] = {
        ['constellation'] = 371792, ['ability'] = 375016, ['texture'] = select(3, GetSpellInfo(375016)), ['cooldown'] = 120,
    },
    [371794] = {
        ['constellation'] = 371794, ['ability'] = 375019, ['texture'] = select(3, GetSpellInfo(375019)), ['cooldown'] = 120,
    },
    [371809] = {
        ['constellation'] = 371809, ['ability'] = 375022, ['texture'] = select(3, GetSpellInfo(375022)), ['cooldown'] = 120,
    },
    [371799] = {
        ['constellation'] = 371799, ['ability'] = 375006, ['texture'] = select(3, GetSpellInfo(375006)), ['cooldown'] = 120,
    },
    [371807] = {
        ['constellation'] = 371807, ['ability'] = 375026, ['texture'] = select(3, GetSpellInfo(375026)), ['cooldown'] = 120,
    },
    [371789] = {
        ['constellation'] = 371789, ['ability'] = 375029, ['texture'] = select(3, GetSpellInfo(375029)), ['cooldown'] = 120,
    },
    [371793] = {
        ['constellation'] = 371793, ['ability'] = 375010, ['texture'] = select(3, GetSpellInfo(375010)), ['cooldown'] = 120,
    },
    [371810] = {
        ['constellation'] = 371810, ['ability'] = 375013, ['texture'] = select(3, GetSpellInfo(375013)), ['cooldown'] = 120,
    },
    [371797] = {
        ['constellation'] = 371797, ['ability'] = 375033, ['texture'] = select(3, GetSpellInfo(375033)), ['cooldown'] = 120,
    },
    [371790] = {
        ['constellation'] = 371790, ['ability'] = 375040, ['texture'] = select(3, GetSpellInfo(375040)), ['cooldown'] = 120,
    },
}

ATTdbs.constellationsShare = {
	--[316254] = 120, -- debug
	[375015] = 90,
	[374992] = 90,
}

ATTdbs.dbTrinketsMerge = {
    --PvP Alt
    [42123] = 118059,
    [42122] = 118059,
    [118059] = 118059,
    [70392] = 118059,
    [70393] = 118059,
    [70394] = 118059,
    [70395] = 118059,
    [170602] = 118059,
    [170603] = 118059,
    [170604] = 118059,
    [170605] = 118059,
    [170606] = 118059,
    [170607] = 118059,
    [84943] = 118059,
    [84944] = 118059,
    [108058] = 118059,
    [108059] = 118059,
    [70602] = 118059,
    [70603] = 118059,
    [70604] = 118059,
    [70605] = 118059,
    [70606] = 118059,
    [70607] = 118059,
    [73538] = 118059,
    [73539] = 118059,
    [107058] = 118059,
    [107059] = 118059,
    [60795] = 118059,
    [60796] = 118059,
    [60797] = 118059,
    [60798] = 118059,
    [60794] = 118059,
    [60799] = 118059,
    [60800] = 118059,
    [60801] = 118059,
    [60806] = 118059,
    [60807] = 118059,
    [103250] = 118059,
    [103251] = 118059,
    [103050] = 118059,
    [103051] = 118059,
    [51377] = 118059,
    [51378] = 118059,
    [64789] = 118059,
    [64790] = 118059,
    [64791] = 118059,
    [64792] = 118059,
    [64793] = 118059,
    [64794] = 118059,
    [100159] = 118059,
    [100160] = 118059,
    [42124] = 118059,
    [42126] = 118059,
    --NecroticAlt
    [118195] = 118195,
    [118211] = 118195,
    [118212] = 118195,
    [112195] = 118195,
    [112211] = 118195,
    [112212] = 118195,
    [108195] = 118195,
    [108211] = 118195,
    [108212] = 118195,
    [107195] = 118195,
    [107211] = 118195,
    [107212] = 118195,
    [103399] = 118195,
    [137094] = 118195,
    [137095] = 118195,
    [103398] = 118195,
    [137078] = 118195,
    [137079] = 118195,
    [103397] = 118195,
    [137062] = 118195,
    [137063] = 118195,
    [103396] = 118195,
    [137046] = 118195,
    [137047] = 118195,
    [103395] = 118195,
    [137030] = 118195,
    [137031] = 118195,
    [103394] = 118195,
    [137014] = 118195,
    [137015] = 118195,
    --HealAlt
    [118196] = 118196,
    [118209] = 118196,
    [118210] = 118196,
    [112196] = 118196,
    [112209] = 118196,
    [112210] = 118196,
    [108196] = 118196,
    [108209] = 118196,
    [108210] = 118196,
    [107196] = 118196,
    [107209] = 118196,
    [107210] = 118196,
    [103405] = 118196,
    [137092] = 118196,
    [137093] = 118196,
    [103404] = 118196,
    [137076] = 118196,
    [137077] = 118196,
    [103403] = 118196,
    [137060] = 118196,
    [137061] = 118196,
    [103402] = 118196,
    [137044] = 118196,
    [137045] = 118196,
    [103401] = 118196,
    [137028] = 118196,
    [137029] = 118196,
    [103400] = 118196,
    [137012] = 118196,
    [137013] = 118196,
}

ATTdbs.dbTrinkets = {
	{
	 ["ability"] = 42292, ["trinketId"] = 118059, ["cooldown"] = 120, ["isPvPtrinket"] = true, -- pvp
    },
    {
     ["ability"] = 308878, ["trinketId"] = 118195, ["cooldown"] = 120, ["isPvPtrinket"] = true, -- necro
    },
    {
     ["ability"] = 373936, ["trinketId"] = 118196, ["cooldown"] = 120, ["isPvPtrinket"] = true, -- heal
    },
}

ATTdbs.dbItemBonus = {

	[41939] = 41939,
	[41873] = 41873,
	[41874] = 41874,
	[41940] = 41940,
	[41875] = 41875,
    [51488] = 51488,
    [103127] = 103127,
    [103327] = 103327,
    [107135] = 107135,
    [108135] = 108135,
    [112135] = 112135,
    [118135] = 118135,
    [41941] = 41941,
    [51483] = 51483,
    [103132] = 103132,
    [103332] = 103332,
    [107140] = 107140,
    [108140] = 108140,
    [112140] = 112140,
    [118140] = 118140,
}

ATTdbs.dbSetBonus = {
    -- PVP PRIEST scream CDr
	[33717] = 44297,
	[33744] = 44297,
	[35053] = 44297,
	[35083] = 44297,
	[41847] = 44297,
	[41872] = 44297,
	[41873] = 44297,
	[41937] = 44297,
	[41938] = 44297,
	[41939] = 44297,
	[41875] = 44297,
	[51488] = 44297,
	[103127] = 44297,
	[103327] = 44297,
	[107135] = 44297,
	[108135] = 44297,
	[112135] = 44297,
	[118135] = 44297,
	[41941] = 44297,
	[51483] = 44297,
	[103132] = 44297,
	[103332] = 44297,
	[107140] = 44297,
	[108140] = 44297,
	[112140] = 44297,
	[118140] = 44297,
	-- PVP PRIEST scream CDr

	[16828] = 23556, -- 205
	[16829] = 23556,
	[16830] = 23556,
	[16833] = 23556,
	[16831] = 23556,
	[16834] = 23556,
	[16835] = 23556,
	[16836] = 23556,

	[29087] = 37292, --638
	[29086] = 37292,
	[29090] = 37292,
	[29088] = 37292,
	[29089] = 37292,

	[31041] = 3841700, --678 fix
	[31032] = 3841700,
	[31037] = 3841700,
	[31045] = 3841700,
	[31047] = 3841700,
	[34571] = 3841700,
	[34445] = 3841700,
	[34554] = 3841700,

    -- PVP RESTO DRUID - Swiftness CDr
	[41268] = 38417, --774
	[41269] = 38417,
	[41270] = 38417,
	[41271] = 38417,
	[41272] = 38417,
	[41284] = 38417, --45
	[41319] = 38417,
	[41296] = 38417,
	[41273] = 38417,
	[41308] = 38417,
	[41286] = 38417, --61
	[41320] = 38417,
	[41297] = 38417,
	[41274] = 38417,
	[41309] = 38417,
	[41287] = 38417, --96
	[41321] = 38417,
	[41298] = 38417,
	[41275] = 38417,
	[41310] = 38417,
	[41322] = 38417,
	[41276] = 38417,
	[41311] = 38417,
	[41288] = 38417,
	[41299] = 38417,
	[51421] = 38417,
	[51424] = 38417,
	[51419] = 38417,
	[51420] = 38417,
	[51422] = 38417,
	[103075] = 38417,
	[103078] = 38417,
	[103073] = 38417,
	[103074] = 38417,
	[103076] = 38417,
	[103275] = 38417,
    [103278] = 38417,
    [103273] = 38417,
    [103274] = 38417,
    [103276] = 38417,
    [107083] = 38417,
    [107086] = 38417,
    [107081] = 38417,
    [107082] = 38417,
    [107084] = 38417,
    [108083] = 38417,
    [108086] = 38417,
    [108081] = 38417,
    [108082] = 38417,
    [108084] = 38417,
    [112083] = 38417,
    [112086] = 38417,
    [112081] = 38417,
    [112082] = 38417,
    [112084] = 38417,
    [118083] = 38417,
    [118086] = 38417,
    [118081] = 38417,
    [118082] = 38417,
    [118084] = 38417,
    -- PVP RESTO DRUID - Swiftness CDr

	[21355] = 26106, --493
	[21353] = 26106,
	[21354] = 26106,
	[21356] = 26106,
	[21357] = 26106,

	[29093] = 37297, --639
	[29094] = 37297,
	[29091] = 37297,
	[29092] = 37297,
	[29095] = 37297,

	[28228] = 37481, --650
	[27474] = 37481,
	[28275] = 37481,
	[27874] = 37481,
	[27801] = 37481,
    -- PVP Hunter tram CDr
	[41084] = 61256, --771
	[41140] = 61256,
	[41154] = 61256,
	[41202] = 61256,
	[41214] = 61256,
	[41085] = 61256, -- 42
	[41141] = 61256,
	[41155] = 61256,
	[41203] = 61256,
	[41215] = 61256,
	[41086] = 61256, -- 58
	[41142] = 61256,
	[41156] = 61256,
	[41204] = 61256,
	[41216] = 61256,
	[41087] = 61256, -- 93
	[41143] = 61256,
	[41157] = 61256,
	[41205] = 61256,
	[41217] = 61256,
	[41158] = 61256,
	[41218] = 61256,
	[41088] = 61256,
	[41144] = 61256,
	[41206] = 61256,
	[51460] = 61256,
	[51462] = 61256,
	[51458] = 61256,
	[51459] = 61256,
	[51461] = 61256,
	[103105] = 61256,
	[103107] = 61256,
	[103103] = 61256,
	[103104] = 61256,
	[103106] = 61256,
	[103305] = 61256,
    [103307] = 61256,
    [103303] = 61256,
    [103304] = 61256,
    [103306] = 61256,
    [107113] = 61256,
    [107115] = 61256,
    [107111] = 61256,
    [107112] = 61256,
    [107114] = 61256,
    [108113] = 61256,
    [108115] = 61256,
    [108111] = 61256,
    [108112] = 61256,
    [108114] = 61256,
    [112113] = 61256,
    [112115] = 61256,
    [112111] = 61256,
    [112112] = 61256,
    [112114] = 61256,
    [118113] = 61256,
    [118115] = 61256,
    [118111] = 61256,
    [118112] = 61256,
    [118114] = 61256,
    -- PVP Hunter tram CDr

	[29076] = 37439, -- 648
	[29080] = 37439,
	[29078] = 37439,
	[29079] = 37439,
	[29077] = 37439,

	[22502] = 28763, -- 526
	[22503] = 28763,
	[22498] = 28763,
	[22501] = 28763,
	[22497] = 28763,
	[22496] = 28763,
	[22500] = 28763,
	[22499] = 28763,
	[23062] = 28763,

	[22430] = 28774, -- 528
	[22431] = 28774,
	[22426] = 28774,
	[22428] = 28774,
	[22427] = 28774,
	[22429] = 28774,
	[22425] = 28774,
	[22424] = 28774,
	[23066] = 28774,


	[40780] = 61776, -- 779
	[40798] = 61776,
	[40818] = 61776,
	[40838] = 61776,
	[40858] = 61776,
	[40782] = 61776, -- 50
	[40802] = 61776,
	[40821] = 61776,
	[40842] = 61776,
	[40861] = 61776,
	[40785] = 61776, -- 66
	[40805] = 61776,
	[40825] = 61776,
	[40846] = 61776,
	[40864] = 61776,
	[40788] = 61776, -- 101
	[40808] = 61776,
	[40828] = 61776,
	[40849] = 61776,
	[40869] = 61776,

	[29062] = 37183,
	[29061] = 37183,
	[29065] = 37183,
	[29063] = 37183,
	[29064] = 37183,

	[28203] = 37181,
	[27535] = 37181,
	[28285] = 37181,
	[27839] = 37181,
	[27739] = 37181,

	[16827] = 21874,
	[16824] = 21874,
	[16825] = 21874,
	[16820] = 21874,
	[16821] = 21874,
	[16826] = 21874,
	[16822] = 21874,
	[16823] = 21874,

	[19617] = 24469,
	[19954] = 24469,
	[19836] = 24469,
	[19835] = 24469,
	[19834] = 24469,

	[21359] = 26112,
	[21360] = 26112,
	[21361] = 26112,
	[21362] = 26112,
	[21364] = 26112,
    -- PVP Shaman ground CDr
	[40987] = 44299,
	[41004] = 44299,
	[41016] = 44299,
	[41030] = 44299,
	[41041] = 44299,
	[40986] = 44299,
	[40998] = 44299,
	[41010] = 44299,
	[41023] = 44299,
	[41024] = 44299,
	[40989] = 44299,
	[41005] = 44299,
	[41017] = 44299,
	[41031] = 44299,
	[41042] = 44299,
	[40988] = 44299,
	[40999] = 44299,
	[41011] = 44299,
	[41025] = 44299,
	[41036] = 44299,
	[40991] = 44299,
	[41006] = 44299,
	[41018] = 44299,
	[41032] = 44299,
	[41043] = 44299,
	[40990] = 44299,
	[41000] = 44299,
	[41012] = 44299,
	[41026] = 44299,
	[41037] = 44299,
	[40993] = 44299,
	[41007] = 44299,
	[41019] = 44299,
	[41033] = 44299,
	[41044] = 44299,
	[40992] = 44299,
	[41001] = 44299,
	[41013] = 44299,
	[41027] = 44299,
	[41038] = 44299,
	[41020] = 44299,
	[41045] = 44299,
	[40995] = 44299,
	[41008] = 44299,
	[41034] = 44299,
	[51511] = 44299,
	[51514] = 44299,
	[51509] = 44299,
	[51510] = 44299,
	[51512] = 44299,
	[103155] = 44299,
	[103158] = 44299,
	[103153] = 44299,
	[103154] = 44299,
	[103156] = 44299,
	[103355] = 44299,
    [103358] = 44299,
    [103353] = 44299,
    [103354] = 44299,
    [103356] = 44299,
    [107163] = 44299,
    [107166] = 44299,
    [107161] = 44299,
    [107162] = 44299,
    [107164] = 44299,
    [108163] = 44299,
    [108166] = 44299,
    [108161] = 44299,
    [108162] = 44299,
    [108164] = 44299,
    [112163] = 44299,
    [112166] = 44299,
    [112161] = 44299,
    [112162] = 44299,
    [112164] = 44299,
    [118163] = 44299,
    [118166] = 44299,
    [118161] = 44299,
    [118162] = 44299,
    [118164] = 44299,
    [41014] = 44299,
    [41039] = 44299,
    [40994] = 44299,
    [41002] = 44299,
    [41028] = 44299,
    [51499] = 44299,
    [51502] = 44299,
    [51497] = 44299,
    [51498] = 44299,
    [51500] = 44299,
    [103143] = 44299,
    [103146] = 44299,
    [103141] = 44299,
    [103142] = 44299,
    [103144] = 44299,
    [103343] = 44299,
    [103346] = 44299,
    [103341] = 44299,
    [103342] = 44299,
    [103344] = 44299,
    [107151] = 44299,
    [107154] = 44299,
    [107149] = 44299,
    [107150] = 44299,
    [107152] = 44299,
    [108151] = 44299,
    [108154] = 44299,
    [108149] = 44299,
    [108150] = 44299,
    [108152] = 44299,
    [112151] = 44299,
    [112154] = 44299,
    [112149] = 44299,
    [112150] = 44299,
    [112152] = 44299,
    [118151] = 44299,
    [118154] = 44299,
    [118149] = 44299,
    [118150] = 44299,
    [118152] = 44299,
    -- PVP Shaman ground CDr

	[29032] = 37211,
	[29029] = 37211,
	[29028] = 37211,
	[29030] = 37211,
	[29031] = 37211,

	[35391] = 38466,
	[35392] = 38466,
	[35393] = 38466,
	[35394] = 38466,
	[35395] = 38466,

	[31640] = 38499,
	[31641] = 38499,
	[31642] = 38499,
	[31643] = 38499,
	[31644] = 38499,
	[31646] = 38499,
	[31647] = 38499,
	[31648] = 38499,
	[31649] = 38499,
	[31650] = 38499,
    -- PVP shaman storm strike CDr
	[41078] = 33018,
	[41134] = 33018,
	[41148] = 33018,
	[41160] = 33018,
	[41208] = 33018,
	[41079] = 33018,
	[41135] = 33018,
	[41149] = 33018,
	[41162] = 33018,
	[41209] = 33018,
	[41080] = 33018,
	[41136] = 33018,
	[41150] = 33018,
	[41198] = 33018,
	[41210] = 33018,
	[41081] = 33018,
	[41137] = 33018,
	[41151] = 33018,
	[41199] = 33018,
	[41211] = 33018,
	[41152] = 33018,
	[41212] = 33018,
	[41082] = 33018,
	[41138] = 33018,
	[41200] = 33018,
	[51505] = 33018,
	[51508] = 33018,
	[51503] = 33018,
	[51504] = 33018,
	[51506] = 33018,
	[103149] = 33018,
	[103152] = 33018,
	[103147] = 33018,
	[103148] = 33018,
	[103150] = 33018,
	[103349] = 33018,
    [103352] = 33018,
    [103347] = 33018,
    [103348] = 33018,
    [103350] = 33018,
    [107157] = 33018,
    [107160] = 33018,
    [107155] = 33018,
    [107156] = 33018,
    [107158] = 33018,
    [108157] = 33018,
    [108160] = 33018,
    [108155] = 33018,
    [108156] = 33018,
    [108158] = 33018,
    [112157] = 33018,
    [112160] = 33018,
    [112155] = 33018,
    [112156] = 33018,
    [112158] = 33018,
    [118157] = 33018,
    [118160] = 33018,
    [118155] = 33018,
    [118156] = 33018,
    [118158] = 33018,
    -- PVP shaman storm strike CDr

	[19951] = 24456,
	[19577] = 24456,
	[19824] = 24456,
	[19823] = 24456,
	[19822] = 24456,
    -- PVP warrior intercept
	[40778] = 22738,
	[40797] = 22738,
	[40816] = 22738,
	[40836] = 22738,
	[40856] = 22738,

	[40783] = 22738,
	[40801] = 22738,
	[40819] = 22738,
	[40840] = 22738,
	[40859] = 22738,

	[40786] = 22738,
	[40804] = 22738,
	[40823] = 22738,
	[40844] = 22738,
	[40862] = 22738,

	[40789] = 22738,
	[40807] = 22738,
	[40826] = 22738,
	[40847] = 22738,
	[40866] = 22738,

	[40829] = 22738,
	[40870] = 22738,
	[40790] = 22738,
	[40810] = 22738,
	[40850] = 22738,

	[51543] = 22738,
	[51545] = 22738,
	[51541] = 22738,
	[51542] = 22738,
	[51544] = 22738,

	[103178] = 22738,
	[103180] = 22738,
	[103176] = 22738,
	[103177] = 22738,
	[103179] = 22738,

	[103378] = 22738,
	[103380] = 22738,
	[103376] = 22738,
	[103377] = 22738,
	[103379] = 22738,

	[107186] = 22738,
	[107188] = 22738,
	[107184] = 22738,
	[107185] = 22738,
	[107187] = 22738,

	[108186] = 22738,
    [108188] = 22738,
    [108184] = 22738,
    [108185] = 22738,
    [108187] = 22738,

    [112186] = 22738,
    [112188] = 22738,
    [112184] = 22738,
    [112185] = 22738,
    [112187] = 22738,

    [118186] = 22738,
    [118188] = 22738,
    [118184] = 22738,
    [118185] = 22738,
    [118187] = 22738,
    -- PVP warrior intercept
}
