local util_args = require('Module:ArgsUtil')
local util_cargo = require('Module:CargoUtil')
local util_esports = require('Module:EsportsUtil')
local util_html = require('Module:HtmlUtil')
local util_map = require('Module:MapUtil')
local util_table = require('Module:TableUtil')
local util_text = require('Module:TextUtil')
local util_vars = require('Module:VarsUtil')
local i18n = require('Module:I18nUtil')
local TabVariables = require('Module:TabVariables')

-- Runes Reforged data defined here only because Rune Trees are not stored in cargo yet.
local RUNES_REFORGED = {
	{
		name = "Domination",
		slots = {
			{
				name = "Keystone",
				runes = {
					{ name = "Electrocute" },
					{ name = "Predator" },
					{ name = "Dark Harvest" },
					{ name = "Hail of Blades" },
				}
			},
			{
				name = "Malice",
				runes = {
					{ name = "Cheap Shot" },
					{ name = "Taste of Blood" },
					{ name = "Sudden Impact" },
				}
			},
			{
				name = "Tracking",
				runes = {
					{ name = "Zombie Ward" },
					{ name = "Ghost Poro" },
					{ name = "Eyeball Collection" },
				}
			},
			{
				name = "Hunter",
				runes = {
					{ name = "Ravenous Hunter" },
					{ name = "Ingenious Hunter" },
					{ name = "Relentless Hunter" },
					{ name = "Ultimate Hunter" },
				}
			}
		}
	},
	{
		name = "Inspiration",
		slots = {
			{
				name = "Keystone",
				runes = {
					{ name = "Glacial Augment" },
					{ name = "Unsealed Spellbook" },
					{ name = "Prototype: Omnistone" },
				}
			},
			{
				name = "Contraption",
				runes = {
					{ name = "Hextech Flashtraption" },
					{ name = "Magical Footwear" },
					{ name = "Perfect Timing" },
				}
			},
			{
				name = "Tomorrow",
				runes = {
					{ name = "Future's Market" },
					{ name = "Minion Dematerializer" },
					{ name = "Biscuit Delivery" },
				}
			},
			{
				name = "Beyond",
				runes = {
					{ name = "Cosmic Insight" },
					{ name = "Approach Velocity" },
					{ name = "Time Warp Tonic" },
				}
			}
		}
	},
	{
		name = "Precision",
		slots = {
			{
				name = "Keystone",
				runes = {
					{ name = "Press the Attack" },
					{ name = "Lethal Tempo" },
					{ name = "Fleet Footwork" },
					{ name = "Conqueror" },
				}
			},
			{
				name = "Heroism",
				runes = {
					{ name = "Overheal" },
					{ name = "Triumph" },
					{ name = "Presence of Mind" },
				}
			},
			{
				name = "Legend",
				runes = {
					{ name = "Legend: Alacrity" },
					{ name = "Legend: Tenacity" },
					{ name = "Legend: Bloodline" },
				}
			},
			{
				name = "Combat",
				runes = {
					{ name = "Coup de Grace" },
					{ name = "Cut Down" },
					{ name = "Last Stand" },
				}
			}
		}
	},
	{
		name = "Resolve",
		slots = {
			{
				name = "Keystone",
				runes = {
					{ name = "Grasp of the Undying" },
					{ name = "Aftershock" },
					{ name = "Guardian" },
				}
			},
			{
				name = "Strength",
				runes = {
					{ name = "Demolish" },
					{ name = "Font of Life" },
					{ name = "Shield Bash" },
				}
			},
			{
				name = "Resistance",
				runes = {
					{ name = "Conditioning" },
					{ name = "Second Wind" },
					{ name = "Bone Plating" },
				}
			},
			{
				name = "Vitality",
				runes = {
					{ name = "Overgrowth" },
					{ name = "Revitalize" },
					{ name = "Unflinching" },
				}
			}
		}
	},
	{
		name = "Sorcery",
		slots = {
			{
				name = "Keystone",
				runes = {
					{ name = "Summon Aery" },
					{ name = "Arcane Comet" },
					{ name = "Phase Rush" },
				}
			},
			{
				name = "Artefact",
				runes = {
					{ name = "Nullifying Orb" },
					{ name = "Manaflow Band" },
					{ name = "Nimbus Cloak" },
				}
			},
			{
				name = "Excellence",
				runes = {
					{ name = "Transcendence" },
					{ name = "Celerity" },
					{ name = "Absolute Focus" },
				}
			},
			{
				name = "Power",
				runes = {
					{ name = "Scorch" },
					{ name = "Waterwalking" },
					{ name = "Gathering Storm" },
				}
			}
		}
	}
}

local INTRO_COLUMNS = {
	'Patch', 'Player', 'Team', 'Champion', 'Position',
	'Primary', 'Secondary',
}
local RUNES_COLUMNS = {
	'Keystone', 'Rune1', 'Rune2', 'Rune3', 'Rune4', 'Rune5',
	'Stat1', 'Stat2', 'Stat3',
}
local OUTRO_COLUMNS = { 'MatchHistory' }
local COLUMNS = util_table.mergeArrays(INTRO_COLUMNS, RUNES_COLUMNS, OUTRO_COLUMNS)

local p = {}
local h = {}

function p.test()
	return p._main{
		overviewPage = 'LCS/2021 Season/Spring Season',
		page = 1
	}
end

-- "Helper" function to serialize the tree names, so that they can be stored in cargo.
-- {{#invoke:RunesQuery|treename|Grasp of the Undying,Demolish,Bone Plating,Overgrowth,Biscuit Delivery,Time Warp Tonic,Adaptive Force,Adaptive Force,Armor}}
-- returns: {"Primary":"Resolve","Secondary":"Inspiration"}
function p.treename(frame)
	local args = util_args.merge()
	local runeNames = args[1] or args.runes
	if not runeNames then return end
	local trees = h.getRuneTreeNamesFromRuneNames(runeNames)
	-- Serialize
	return mw.text.jsonEncode(trees)
end

function p.main(frame)
	local args = util_args.merge()
	return p._main(args)
end

function p._main(args)
	i18n.init('RunesQuery')
	local query = h.getQuery(args)
	local data = util_cargo.queryAndCast(query)
	util_map.rowsInPlace(data, h.processRow)
	return h.makeOutput(data)
end

function h.getQuery(args)
	local tabNumber = args.page or TabVariables.getIndex() or 1
	local overviewPage = util_esports.getOverviewPage(args.overviewPage)
	local ret = {
		tables = {
			'ScoreboardGames=SG',
			'MatchSchedule=MS',
			'ScoreboardTeams=ST',
			'ScoreboardPlayers=SP',
			'Teams',
		},
		join = {
			'SG.MatchId = MS.MatchId',
			'SG.UniqueGame = ST.UniqueGame',
			'ST.GameTeamId = SP.GameTeamId',
			'ST.Team = Teams.Name',
		},
		fields = {
			'SG.Patch',
			'SP.Name = Player',
			'COALESCE(Teams.Short,Teams.Name,ST.Team) = Team',
			'SP.Champion',
			'SP.IngameRole = Position',
			-- 'SP.KeystoneMastery=Keystone', -- unused ??
			'SP.Runes', -- keystone, 5 runes, 3 stats
			'SG.MatchHistory',
		},
		where = {
			('SG.OverviewPage = "%s"'):format(overviewPage),
			('SG.MatchHistory IS NOT NULL'),
			('SG.N_Page = %d'):format(tabNumber),
		},
		orderBy = 'MS.N_Page, MS.N_MatchInPage, SG.N_GameInMatch',
	}
	return ret
end

function h.processRow(row)
	row.classes = {'rune-line-'..row.Position} -- required for toggle
	row.MatchHistory = util_text.extLink(row.MatchHistory:gsub("^http://", "https://")) -- ensure HTTPS
	row.Runes = util_text.splitIfString(row.Runes)
	h.parseRuneTrees(row)
end

function h.parseRuneTrees(row)
	local trees = h.getRuneTreeNamesFromRuneNames(row.Runes)
	util_table.merge(row, trees)
	for i, k in ipairs(RUNES_COLUMNS) do
		row[k] = row.Runes[i]
	end
end

function h.getRuneTreeNamesFromRuneNames(runeNames)
	local runeNames = util_text.splitIfString(runeNames)
	local treeTally = {}
	for _, runeName in ipairs(runeNames) do
		local treeName = h.getRuneTreeNameFromRuneName(runeName)
		if treeName ~= nil then
			treeTally[treeName] = (treeTally[treeName] or 0) + 1
		end
	end
	local t = {}
	for name, count in pairs(treeTally) do
		t[#t+1] = {count=count, name=name}
	end
	-- Sort from most to least
	table.sort(t, function(a,b) return a.count > b.count end)
	return {
		Primary = t[1].name,
		Secondary = t[2].name,
	}
end

function h.getRuneTreeNameFromRuneName(runeName)
	for _, runePath in ipairs(RUNES_REFORGED) do
		for _, slot in ipairs(runePath.slots) do
			for _, rune in ipairs(slot.runes) do
				if rune.name == runeName then
					return runePath.name
				end
			end
		end
	end
end

-- Output
function h.makeOutput(data)
	local output = mw.html.create()
	local tbl = output:tag('table')
		:addClass('wikitable runedata hoverable-rows')
	h.printHeaders(tbl)
	util_html.printRowsByList(tbl, data, COLUMNS)
	return tostring(output)
end

function h.printHeaders(tbl)
	util_html.printHeaderFromI18n(tbl, COLUMNS)
		:addClass('runedata-header')
end

return p
