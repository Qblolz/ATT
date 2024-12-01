local addon, ATTdbs = ...

ATTdbs.cooldownResetters = {
	[GetSpellInfo(11958)] = { -- Cold Snap
		[42931] = 1, -- Cone of Cold
		[42917] = 1, -- Frost Nova
		[43012] = 1, -- Frost Ward
		[43039] = 1, -- Ice Barrier
		[45438] = 1, -- Ice Block
		[31687] = 1, -- Summon Water Elemental
		[44572] = 1, -- Deep Freeze
		[44545] = 1, -- Fingers of Frost
		[12472] = 1, -- Icy Veins
	},
	[GetSpellInfo(14185)] = { -- 2
		[14177] = 1, -- Cold Blood
		[26669] = 1, -- Evasion
		[11305] = 1, -- Sprint
		[26889] = 1, -- Vanish
		[36554] = 1, -- Shadowstep
		[1766] = 10, -- Kick
		[51722] = 60, -- Dismantle
	},
	[GetSpellInfo(23989)] = { -- 2
		[19503] = 1, -- Scatter Shot
		[60192] = 1, -- Freezing Arrow
		[13809] = 1, -- Frost Trap
		[14311] = 1, -- Freezing Trap
		[19574] = 1, -- Bestial Wrath
		[34490] = 1, -- Silencing Shot
		[19263] = 1, -- Deterrence
		[53271] = 1, -- Master's Call
		[49012] = 1, -- Wyvern Sting
	},
}

ATTdbs.ShareCD = {
	[GetSpellInfo(16979)] = { [49376] = 1, },
	[GetSpellInfo(49376)] = { [16979] = 1, },

	[GetSpellInfo(43010)] = { [43012] = 1, [32796] = 1, },
	[GetSpellInfo(43012)] = { [43010] = 1, [27128] = 1, },

	[GetSpellInfo(49231)] = { [49233] = 1, [49236] = 1, },
	[GetSpellInfo(49233)] = { [49231] = 1, [49233] = 1, },
	[GetSpellInfo(49236)] = { [49231] = 1, [49236] = 1, },

	--traps
	[GetSpellInfo(60192)] = { [14311] = 1, [13809] = 1, },
	[GetSpellInfo(14311)] = { [60192] = 1, [13809] = 1, },
	[GetSpellInfo(13809)] = { [60192] = 1, [14311] = 1, },

	[GetSpellInfo(49067)] = { [49056] = 1, },
	[GetSpellInfo(49056)] = { [49067] = 1, },
}

ATTdbs.dbModif = {
	[14311] = { ["mod"] = GetSpellInfo(34493), ["rank"] = { 2, 4, 6, }, },
	[13809] = { ["mod"] = GetSpellInfo(34493), ["rank"] = { 2, 4, 6, }, },
	[34600] = { ["mod"] = GetSpellInfo(34493), ["rank"] = { 2, 4, 6, }, },
	[27025] = { ["mod"] = GetSpellInfo(34493), ["rank"] = { 2, 4, 6, }, },
	[27023] = { ["mod"] = GetSpellInfo(34493), ["rank"] = { 2, 4, 6, }, },
	[60192] = { ["mod"] = GetSpellInfo(34493), ["rank"] = { 2, 4, 6, }, },
	[3045] = { ["mod"] = GetSpellInfo(34949), ["rank"] = { 60, 120, }, }, -- Rapid Fire

	[45438] = { ["mod"] = GetSpellInfo(31672), ["rank"] = { 21, 42, 60, }, }, --% 10 20 -- Ice Block  7% 14% 20%
	[27087] = { ["mod"] = GetSpellInfo(31672), ["rank"] = { 0.7, 1.4, 2, }, }, --% Cone of Cold
	[42917] = { ["mod"] = GetSpellInfo(31672), ["rank"] = { 1.75, 3.5, 5 }, }, -- Frost Nova
	[12472] = { ["mod"] = GetSpellInfo(31672), ["rank"] = { 12.5, 25, 36 }, }, -- Icy Veins
	[11958] = { ["mod"] = GetSpellInfo(55092), ["rank"] = { 48, 96, }, }, --% Cold Snap
	[33405] = { ["mod"] = GetSpellInfo(55092), ["rank"] = { 3, 6, }, }, --% Ice Barrier
	[31687] = { ["mod"] = GetSpellInfo(55092), ["rank"] = { 18, 36, }, }, --% Summon Water Elemental
	[66] = { ["mod"] = GetSpellInfo(44379), ["rank"] = { 27, 54, }, }, --% invis
	[12043] = { ["mod"] = GetSpellInfo(44379), ["rank"] = { 18, 36, }, }, --% presence of mind
	[12042] = { ["mod"] = GetSpellInfo(44379), ["rank"] = { 18, 36, }, }, --% presence of mind

	[10308] = { ["mod"] = GetSpellInfo(20488), ["rank"] = { 10, 20, }, }, --hoj *
	[10278] = { ["mod"] = GetSpellInfo(20175), ["rank"] = { 60, 120, }, }, --blessing *
	[642] = { ["mod"] = GetSpellInfo(31849), ["rank"] = { 30, 60, }, }, --divine shield *
	[498] = { ["mod"] = GetSpellInfo(31849), ["rank"] = { 30, 60, }, }, --divine protection *
	[27154] = { ["mod"] = GetSpellInfo(20235), ["rank"] = { 120, 240, }, }, -- Lay on Hands


	[10890] = { ["mod"] = GetSpellInfo(15448), ["rank"] = { 2, 4, 4, }, }, -- Psychic Scream

	[33206] = { ["mod"] = GetSpellInfo(47508), ["rank"] = { 18, 36, }, }, -- Pain sup
	[10060] = { ["mod"] = GetSpellInfo(47508), ["rank"] = { 12, 24, }, }, -- power infu
	[14751] = { ["mod"] = GetSpellInfo(47508), ["rank"] = { 18, 36, }, }, -- inner focus


	[31224] = { ["mod"] = GetSpellInfo(14066), ["rank"] = { 15, 30, }, }, -- cloack of shadows
	[2094] = { ["mod"] = GetSpellInfo(14066), ["rank"] = { 30, 60, }, }, --blind
	[26889] = { ["mod"] = GetSpellInfo(14066), ["rank"] = { 30, 60, }, }, -- vanish

	[36554] = { ["mod"] = GetSpellInfo(58415), ["rank"] = { 5, 10, }, }, -- shadowstep
	[57934] = { ["mod"] = GetSpellInfo(58415), ["rank"] = { 5, 10, }, }, -- Tricks of the Trade
	[1725] = { ["mod"] = GetSpellInfo(58415), ["rank"] = { 5, 10, }, }, -- Distract
	[14185] = { ["mod"] = GetSpellInfo(58415), ["rank"] = { 90, 180, }, }, -- prepar

	[26669] = { ["mod"] = GetSpellInfo(13872), ["rank"] = { 60, 60, }, }, -- Evasion
	[11305] = { ["mod"] = GetSpellInfo(13872), ["rank"] = { 60, 60, }, }, -- Sprint

	[8177] = { ["mod"] = GetSpellInfo(16293), ["rank"] = { 1, 2, }, }, -- Grounding Totem
	[25454] = { ["mod"] = GetSpellInfo(16116), ["rank"] = { 0.2, 0.4, 0.6, 0.8, 1, }, }, -- Earth Shock
	[25464] = { ["mod"] = GetSpellInfo(16116), ["rank"] = { 0.2, 0.4, 0.6, 0.8, 1, }, }, --Frost Shock
	[25457] = { ["mod"] = GetSpellInfo(16116), ["rank"] = { 0.2, 0.4, 0.6, 0.8, 1, }, }, -- Flame Shock
	[57994] = { ["mod"] = GetSpellInfo(16116), ["rank"] = { 0.2, 0.4, 0.6, 0.8, 1, }, }, -- Wind Shear

	[586] = { ["mod"] = GetSpellInfo(15311), ["rank"] = { 3, 6, }, }, --to add fade
	[34433] = { ["mod"] = GetSpellInfo(15311), ["rank"] = { 60, 120, }, }, -- Shadowfiend

	[25275] = { ["mod"] = GetSpellInfo(29889), ["rank"] = { 5, 10, }, }, -- intercept
	[27079] = { ["mod"] = GetSpellInfo(11080), ["rank"] = { 1, 2, }, }, -- Fire Blast
	[20271] = { ["mod"] = GetSpellInfo(25957), ["rank"] = { 1, 2, }, }, -- Judgement of Light
	[25375] = { ["mod"] = GetSpellInfo(15316), ["rank"] = { 0.5, 1, 1.5, 2, 2.5, }, }, -- Mind Blast
	[1787] = { ["mod"] = GetSpellInfo(14063), ["rank"] = { 2, 4, 6, }, }, -- stealth?
	[30330] = { ["mod"] = GetSpellInfo(35449), ["rank"] = { 0.3, 0.7, 1, }, }, -- Mortal Strike

	[26983] = { ["mod"] = GetSpellInfo(17124), ["rank"] = { 144, 288, }, }, -- Tranq
}

ATTdbs.dbModifGlyph = {
	[5209] = { ["mod"] = 57858, ["cd"] = 30, ["class"] = 11, },
	[33357] = { ["mod"] = 59219, ["cd"] = 36, ["class"] = 11, },
	[61384] = { ["mod"] = 63056, ["cd"] = 3, ["class"] = 11, },
	[53201] = { ["mod"] = 54828, ["cd"] = 30, ["class"] = 11, },
	[19574] = { ["mod"] = 56830, ["cd"] = 30, ["class"] = 2, },
	[19263] = { ["mod"] = 56850, ["cd"] = 10, ["class"] = 2, },
	[781] = { ["mod"] = 56844, ["cd"] = 5, ["class"] = 2, },
	[5384] = { ["mod"] = 57903, ["cd"] = 5, ["class"] = 2, },
	[49012] = { ["mod"] = 56848, ["cd"] = 6, ["class"] = 2, },
	[31687] = { ["mod"] = 56373, ["cd"] = 30, ["class"] = 9, },
	[48817] = { ["mod"] = 56420, ["cd"] = 15, ["class"] = 2, },
	[48788] = { ["mod"] = 57955, ["cd"] = 300, ["class"] = 2, },
	[47585] = { ["mod"] = 63229, ["cd"] = 45, ["class"] = 5, },
	[10890] = { ["mod"] = 55676, ["cd"] = 8, ["class"] = 5, },
	[586] = { ["mod"] = 55684, ["cd"] = 9, ["class"] = 5, },
	[6346] = { ["mod"] = 55678, ["cd"] = 60, ["class"] = 5, },
	[2894] = { ["mod"] = 55678, ["cd"] = 300, ["class"] = 7, },
	[59159] = { ["mod"] = 63270, ["cd"] = 10, ["class"] = 7, },
	[16166] = { ["mod"] = 55452, ["cd"] = 30, ["class"] = 7, },
	[556] = { ["mod"] = 58058, ["cd"] = 450, ["class"] = 7, },
	[17928] = { ["mod"] = 56217, ["cd"] = 8, ["class"] = 9, },
	[48020] = { ["mod"] = 63309, ["cd"] = 4, ["class"] = 9, },
	[12975] = { ["mod"] = 58376, ["cd"] = 60, ["class"] = 1, },
	[46968] = { ["mod"] = 63325, ["cd"] = 3, ["class"] = 1, },
	[46924] = { ["mod"] = 63324, ["cd"] = 15, ["class"] = 1, },
	[871] = { ["mod"] = 63329, ["cd"] = 120, ["class"] = 1, },
	[47476] = { ["mod"] = 58618, ["cd"] = 20, ["class"] = 6, },
	[14278] = { ["mod"] = 56814, ["cd"] = -10, ["class"] = 4, },
	[51690] = { ["mod"] = 63252, ["cd"] = 45, ["class"] = 4, },
	--https://www.wowhead.com/wotlk/spell=63231/glyph-of-guardian-spirit
	--https://www.wowhead.com/wotlk/spell=56819/glyph-of-preparation
}

ATTdbs.dbAuraRemoved = {
	[GetSpellInfo(14177)] = true,
	[GetSpellInfo(17116)] = true,
	--[GetSpellInfo(20580)]   = true,
	[GetSpellInfo(16166)] = true,
	[GetSpellInfo(18288)] = true,
	[GetSpellInfo(15473)] = true,
	[GetSpellInfo(14751)] = true,
	[GetSpellInfo(20216)] = true,
	[GetSpellInfo(12043)] = true,
	[GetSpellInfo(11129)] = true,
	[GetSpellInfo(1787)]  = true,
	[GetSpellInfo(9913)]  = true,
	--[GetSpellInfo(16188)]   = true,
}

ATTdbs.dbAuraApplied = {
	[GetSpellInfo(11129)] = true,
}

ATTdbs.dbBannedIds = { --quick fix before converting to ID
	[48445] = true,
}

ATTdbs.dbModifBonus = {
	[29166] = { ["mod"] = { 37297 }, ["cd"] = { 48 }, ["rank"] = { 4 }, },
	[17116] = { ["mod"] = { 37292 }, ["cd"] = { 24 }, ["rank"] = { 4 }, },
	[26994] = { ["mod"] = { 26106 }, ["cd"] = { 600 }, ["rank"] = { 5 }, },
	[14311] = { ["mod"] = { 37481, 61256 }, ["cd"] = { 4, 2 }, ["rank"] = { 2, 4 }, },
	[49056] = { ["mod"] = { 37481, 61256 }, ["cd"] = { 4, 2 }, ["rank"] = { 2, 4 }, },
	[13809] = { ["mod"] = { 37481, 61256 }, ["cd"] = { 4, 2 }, ["rank"] = { 2, 4 }, },
	[49067] = { ["mod"] = { 37481, 61256 }, ["cd"] = { 4, 2 }, ["rank"] = { 2, 4 }, },
	[34600] = { ["mod"] = { 37481, 61256 }, ["cd"] = { 4, 2 }, ["rank"] = { 2, 4 }, },
	[63672] = { ["mod"] = { 37481, 61256 }, ["cd"] = { 4, 2 }, ["rank"] = { 2, 4 }, },
	[60192] = { ["mod"] = { 37481, 61256 }, ["cd"] = { 4, 2 }, ["rank"] = { 2, 4 }, },
	[16188] = { ["mod"] = { 37211, 38466, 38499 }, ["cd"] = { 24, 24, 24 }, ["rank"] = { 4, 4, 4 }, },
	[2094] = { ["mod"] = { 24469 }, ["cd"] = { 5 }, ["rank"] = { 3 }, },
	[26669] = { ["mod"] = { 26112 }, ["cd"] = { 60 }, ["rank"] = { 3 }, },
	[8177] = { ["mod"] = { 44299 }, ["cd"] = { 1.5 }, ["rank"] = { 4 }, },
	[17364] = { ["mod"] = { 33018 }, ["cd"] = { 2 }, ["rank"] = { 4 }, },
	[5246] = { ["mod"] = { 24456 }, ["cd"] = { 15 }, ["rank"] = { 3 }, },
	[42945] = { ["mod"] = { 37439 }, ["cd"] = { 4 }, ["rank"] = { 4 }, },
	[45438] = { ["mod"] = { 37439 }, ["cd"] = { 40 }, ["rank"] = { 4 }, },
	[12043] = { ["mod"] = { 37439 }, ["cd"] = { 24 }, ["rank"] = { 4 }, },
	[12051] = { ["mod"] = { 28763 }, ["cd"] = { 60 }, ["rank"] = { 2 }, },
	[20216] = { ["mod"] = { 37183 }, ["cd"] = { 15 }, ["rank"] = { 4 }, },
	[27154] = { ["mod"] = { 28774 }, ["cd"] = { 720 }, ["rank"] = { 4 }, },
	[31789] = { ["mod"] = { 37181 }, ["cd"] = { 2 }, ["rank"] = { 4 }, }, --not in import short cd
	[20271] = { ["mod"] = { 61776 }, ["cd"] = { 1 }, ["rank"] = { 4 }, },
	[53408] = { ["mod"] = { 61776 }, ["cd"] = { 1 }, ["rank"] = { 4 }, }, --not in import short cd
	[53407] = { ["mod"] = { 61776 }, ["cd"] = { 1 }, ["rank"] = { 4 }, }, --not in import short cd
	[25275] = { ["mod"] = { 22738 }, ["cd"] = { 5 }, ["rank"] = { 4 }, },
	[1856] = { ["mod"] = { 21874 }, ["cd"] = { 30 }, ["rank"] = { 2 }, },
	[26983] = { ["mod"] = { 23556 }, ["cd"] = { 28 }, ["rank"] = { 8 }, }, -- at max rank

	[18562] = { ["mod"] = { 38417, 3841700 }, ["cd"] = { 2, 2 }, ["rank"] = { 4, 2 }, },

	[586] = { ["mod"] = { 14154 }, ["cd"] = { 2 }, ["rank"] = { 1 }, }, --
	[10890] = { ["mod"] = { 41873, 41874, 41875, 41939, 41940, 41941, 51483, 51488, 103127, 103132, 103327, 103332, 107135, 107140, 108135, 108140, 112135, 112140, 118135, 118140 }, ["cd"] = { 3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3 }, ["rank"] = { 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1 }, }, --
	[1766] = { ["mod"] = { 19617 }, ["cd"] = { 0.5 }, ["rank"] = { 1 }, }, --
	[5384] = { ["mod"] = { 19621 }, ["cd"] = { 2 }, ["rank"] = { 1 }, }, --
	[20608] = { ["mod"] = { 22345 }, ["cd"] = { 600 }, ["rank"] = { 1 }, }, --not in import passive
}