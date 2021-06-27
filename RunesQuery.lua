local util_args = require('Module:ArgsUtil')
local util_cargo = require('Module:CargoUtil')
local util_esports = require('Module:EsportsUtil')
local util_table = require('Module:TableUtil')
local util_text = require('Module:TextUtil')
local util_vars = require('Module:VarsUtil')
local m_tab_vars = require('Module:TabVariables')

-- Maybe move this to /data
local RUNE_FORGED = {
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

local p = {}
local h = {}

function p.main(frame)
	local args = util_args.merge()
	return p._main(args)
end

function p._main(args)
	local tabNumber = args.page or m_tab_vars.getIndex() or 1
	local overviewPage = util_esports.getOverviewPage(args.overviewPage)
	local rows = util_cargo.queryAndCast{
		tables = 'ScoreboardGames=SG, MatchSchedule=MS, ScoreboardTeams=ST, ScoreboardPlayers=SP, Teams',
		join = {
			'SG.MatchId = MS.MatchId',
			'SG.UniqueGame = ST.UniqueGame',
			'ST.GameTeamId = SP.GameTeamId',
			'ST.Team = Teams.Name',
		},
		fields = {
			'SG.N_Page',
			'SG.N_MatchInTab',
			'SG.N_MatchInPage',
			'SG.N_GameInMatch',
			'SG.Patch = V',
			'SP.Name = Player',
			'COALESCE(Teams.Short,Teams.Name,ST.Team) = Team',
			'SP.Champion = Champion',
			'SP.IngameRole = Position',
			-- 'SP.KeystoneMastery=Keystone', -- unused ??
			'SP.Runes = Runes', -- keystone, 5 runes, 3 stats
			'SG.MatchHistory = MH',
		},
		where = {
			('SG.OverviewPage = "%s"'):format(overviewPage),
			'SG.MatchHistory IS NOT NULL',
			('SG.N_Page = %d'):format(tabNumber),
		},
		orderBy = 'SG.N_Page, SG.N_MatchInPage, SG.N_MatchInTab, SG.N_GameInMatch',
	}
	local headers = {
		'V', 'Player', 'Team', 'Champion', 'Position', 'Tree', 'Secondary',
		'Keystone', 'Rune 1', 'Rune 2', 'Rune 3', 'Rune 4', 'Rune 5',
		'Stat 1', 'Stat 2', 'Stat 3', 'MH',
	}
	local root = mw.html.create()
	h.printTable(root, headers, rows)
	return tostring(root)
end

function h.printTable(root, headers, rows)
	local tbl = root:tag('table'):addClass('wikitable runedata hoverable-rows')
	h.printHeaders(tbl, headers)
	h.printRows(tbl, headers, rows)
end

function h.printHeaders(tbl, headers)
	local tr = tbl:tag('tr'):addClass('runedata-header')
	for _, s in ipairs(headers) do
		tr:tag('th'):wikitext(s)
	end
end

function h.printRows(tbl, headers, rows)
	for i, row in ipairs(rows) do
		local tr = tbl:tag('tr')
		tr:addClass('rune-line-'..row.Position)
		row.MH = row.MH:gsub("^http://", "https://")
		row.MH = '['..row.MH.. ' Link]'
		h.parseRuneTrees(row)
		for _, k in ipairs(headers) do
			tr:tag('td'):wikitext(row[k])
		end
	end
end

function h.parseRuneTrees(row)
	local runes = row.Runes
	local getTree = function(runeName)
		for _, runePath in ipairs(RUNE_FORGED) do
			for _, slot in ipairs(runePath.slots) do
				for _, rune in ipairs(slot.runes) do
					if rune.name == runeName then
						return runePath.name
					end
				end
			end
		end
	end
	if type(runes) == 'string' then
		runes = util_text.split(runes)
	end
	local treeTally = {}
	for _, runeName in ipairs(runes) do
		local treeName = getTree(runeName)
		if treeName ~= nil then
			treeTally[treeName] = (treeTally[treeName] or 0) + 1
		end
	end
	local t = {}
	for name, count in pairs(treeTally) do
		t[#t+1] = {count=count, name=name}
	end
	table.sort(t, function(a,b) return a.count > b.count end)
	row.Tree = t[1].name
	row.Secondary = t[2].name
	for i, k in ipairs({
		'Keystone', 'Rune 1', 'Rune 2', 'Rune 3', 'Rune 4', 'Rune 5',
		'Stat 1', 'Stat 2', 'Stat 3',
	}) do
		row[k] = runes[i]
	end
end

function p.test()
	return p._main{
		overviewPage = 'LCS/2021 Season/Spring Season',
		page = 1
	}
end

return p
