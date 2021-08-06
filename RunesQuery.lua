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

local INTRO_COLUMNS = {
	'Patch', 'Player', 'Team', 'Champion', 'Position',
	'PrimaryTree', 'SecondaryTree',
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

function h.getTabNumber(args)
	local pageNumber = tonumber(args.page)
	if pageNumber then
		return pageNumber
	end
	-- If the name of the final tab is Runes, that means that we're not in a
	-- position where the tab index actually corresponds to a data tab index
	if TabVariables.getName() == 'Runes' then
		return 1
	end
	return TabVariables.getIndex() or 1
end

function h.getQuery(args)
	local tabNumber = h.getTabNumber(args)
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
			'SP.PrimaryTree',
			'SP.SecondaryTree',
			'SP.Runes', -- keystone, 5 runes, 3 stats
			'SG.MatchHistory',
		},
		where = {
			('SG.OverviewPage = "%s"'):format(overviewPage),
			('SG.MatchHistory IS NOT NULL'),
			('MS.N_Page = %d'):format(tabNumber),
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
	for i, k in ipairs(RUNES_COLUMNS) do
		row[k] = row.Runes[i]
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
