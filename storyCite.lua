local util_vars = require('Module:VarsUtil') --from https://thealchemistcode.fandom.com/wiki/Module:VarsUtil
local util_link = require('Module:LinkUtil')
local cache = require('mw.ext.LuaCache')
local PREFIX = 'SC_CACHE_01-'
local dump
local p = {} --p stands for package
local h = {} --h stands for helper

-- from https://stackoverflow.com/a/7615129
function h.splitString (inputstr, sep)
		if sep == nil then
				sep = "%s"
		end
		local t = {}
		for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
				table.insert(t, str)
		end
		return t
end

function p.infoboxStore( frame )
	local args = frame:getParent().args
	local outputText = ""
	if args["citation text"] then
		outputText = args["citation text"]
	else
		if not args["separator"] then
			args["separator"] = ","
		end
		
		-- combines {{{anthology}}} and {{{audio anthology}}}
		if args["anthology"] and args["audio anthology"] then
			args["anthology"] = args["anthology"] .. ", " .. args["audio anthology"]
		elseif (not args["anthology"]) and args["audio anthology"] then
			args["anthology"] = args["audio anthology"]
		end
		
		-- combines {{{adapted from}}} and {{{novelisation of}}}
		if args["adapted from"] and args["novelisation of"] then
			args["adapted from"] = args["adapted from"] .. ", " .. args["novelisation of"]
		elseif (not args["adapted from"]) and args["novelisation of"] then
			args["adapted from"] = args["novelisation of"]
		end
		
		--gets and formats data for items that are unlinked	in the infobox
		local data = {["anthology"] = "", ["writer"] = "", ["publisher"] = "", ["adapted from"] = ""}
		for key, val in pairs(data) do
			if args[key] then
				local current = h.splitString(args[key], args["separator"])
				for i = 1, #current do
					data[key] = data[key] .. "[[" .. util_link.stripPipe(current[i]) .. "|" .. util_link.stripPipe(util_link.stripDab(current[i])) .. "]]"
					if i == #current-1 then
						data[key] = data[key] .. " and "
					elseif i == #current then
						data[key] = data[key]
					else
						data[key] = data[key] .. ", "
					end
				end
			end
		end
		
		--same concept as above but doesn't add links
		data["issues"] = ""
		if args["publication"] then
			local current = h.splitString(args["publication"], args["separator"])
			for i = 1, #current do
				data["issues"] = data["issues"] .. current[i]
				if i == #current-1 then
					data["issues"] = data["issues"] .. " and "
				elseif i == #current then
					data["issues"] = data["issues"]
				else
					data["issues"] = data["issues"] .. ", "
				end
			end
		end
		
		-- making series text
		if args["citation series"] then
			data["series"] = args["citation series"]
		elseif args["range"] then
			data["series"] = "\'\'[[" .. util_link.stripPipe(args["range"]) .. "|" .. util_link.stripPipe(util_link.stripDab(args["range"])) .. "]]\'\'"
		elseif args["series"] then
			if args["series"] == "[[Doctor Who television stories|''Doctor Who'' television stories]]" then
				data["series"] = "\'\'[[Doctor Who]]\'\'"
			else
				data["series"] = args["series"]
			end
			if args["season number"] then
				data["series"] = data["series"] .. " " .. "[[" .. util_link.stripPipe(args["season number"]) .. "|" .. util_link.stripPipe(util_link.stripDab(args["season number"])) .. "]]"
			end
		else
			data["series"] = ""
		end
		
		-- making release year text
		if args["release date"] or args["broadcast date"] or args["premiere"] or args["beta release date"] or args["cover date"] then
		args["release date"] = h.splitString(util_link.stripDab(args["release date"] or args["broadcast date"] or args["premiere"] or args["beta release date"] or args["cover date"]), "-")
			local releaseYear
			local releaseEndYear
			if #args["release date"] >= 2 then
				releaseYear = args["release date"][1]:gsub("%s+", ""):sub(-4)
				releaseEndYear = args["release date"][2]:gsub("%s+", ""):sub(-4)
				if tonumber(releaseEndYear) == nil then
					releaseEndYear = nil
				end
				if tonumber(releaseYear) == nil then
					releaseYear = releaseEndYear
					releaseEndYear = nil
				end
			else
				releaseYear = args["release date"][1]:gsub("%s+", ""):sub(-4)
			end
			if releaseEndYear and releaseYear and (releaseEndYear ~= releaseYear) then
				if (tonumber(releaseEndYear) - tonumber(releaseYear)) == 1 then
					data["release year"] = "in"
				else
					data["release year"] = "between"
				end
				data["release year"] = data["release year"] .. " the years [[" .. releaseYear .. " (releases)|" .. releaseYear .."]] and [[" .. releaseEndYear .. " (releases)|" .. releaseEndYear .. "]]"
			else
				data["release year"] = "in the year [[" .. releaseYear .. " (releases)|" .. releaseYear .."]]"
			end
		else
			data["release year"] = ""
		end
		
		-- making outputText
		local outputText = ""
		if data["adapted from"] ~= "" then
			outputText = outputText .. "Adapted from ''" .. data["adapted from"] .. "''"
			if data["writer"] ~= "" then
				outputText = outputText .. ", written by " .. data["writer"]
				if data["publisher"] ~= "" then
					outputText = outputText .. " and released by " .. data["publisher"]
				else
					outputText = outputText .. "and released "
				end
			elseif data["publisher"] ~= "" then
				outputText = outputText .. " and released by " .. data["publisher"]
			else
				outputText = outputText .. "and released "
			end
		elseif data["writer"] ~= "" then
			outputText = outputText .. "Written by " .. data["writer"]
			if data["publisher"] ~= "" then
				outputText = outputText .. " and released by " .. data["publisher"]
			else
				outputText = outputText .. "and released "
			end
		elseif data["publisher"] ~= "" then
			outputText = outputText .. " Released by " .. data["publisher"]
		else
			outputText = outputText .. "Released "
		end
		if data["anthology"] ~= "" then
				outputText = outputText .. " as part of ''" .. data["anthology"] .. "''"
				if data["series"] ~= "" then
					if (args["season number"] ~= "") or (args["season number"] ~= nil) then
						outputText = outputText .. " from " .. data["series"]
					else
						outputText = outputText .. " from the series " .. data["series"]
					end
				end
		elseif data["series"] ~= "" then
			if (args["season number"] ~= "") or (args["season number"] ~= nil) then
				outputText = outputText .. " as part of " .. data["series"]
			else
				outputText = outputText .. " as part of the series " .. data["series"]
			end
		end
		if data["release year"] ~= "" then
			outputText = outputText .. " " .. data["release year"]
		end
		if data["issues"] ~= "" then
			outputText = outputText .. " throught " .. data["issues"]
		end
		--fallback in case of an error
		if outputText == "" or outputText == nil then
		 	outputText = "No data."
		else
			outputText = outputText .. "."
		end
		
		--outputText = dump(data) --for testing
		local name = frame.args[1]
		local bin --used to store the output of the functions below
		bin = util_vars.setVar(PREFIX .. name, outputText)
		bin = cache.delete(PREFIX .. name)
		bin = cache.set(PREFIX .. name, outputText)
		bin = mw.smw.set("Story info", outputText) --documentation for this is down so I guessed the syntax. It doesn't seem to work.
	end
end

function h.getInfo(story)
	local info 
	local bin --used to store the output of storing functions
	if util_vars.getVar(PREFIX .. story) then
		info = util_vars.getVar(PREFIX .. story)
	elseif cache.get(PREFIX .. story) then
		info = cache.get(PREFIX .. story)
		bin = util_vars.setVar(PREFIX .. story, info)
	elseif mw.smw.ask( story .. "\n?Story info") then
		info = mw.smw.ask( story .. "\n?Story info")
		bin = util_vars.setVar(PREFIX .. story, info)
		bin = cache.delete(PREFIX .. name)
		bin = cache.set(PREFIX .. story, info)
	else
		info = "No data."
	end
	return info
end

function p.displayCitation(frame)
	local story = frame:getParent().args[1]
	return "''[[" .. story .. "|" .. util_link.stripDab(story) .. "]]'' <sup><span class=\"mw-customtoggle-{{#vardefineecho:id|{{#expr:{{#var:id|0}}+1}}}}\">+</span> <span class=\"mw-collapsible mw-collapsed\" id=\"mw-customcollapsible-{{#var:id}}\">" .. h.getInfo(story) .. "</span></sup>"
end

--[[for testing that data is being collected.
	from https://sandbox.semantic-mediawiki.org/wiki/Module:Smw
	This dumps the variable (converts it into a string representation of itself)--]]
dump = function(entity, indent, omitType)
	local entity = entity
	local indent = indent and indent or ''
	local omitType = omitType
	if type( entity ) == 'table' then
		local subtable
		if not omitType then
			subtable = '(table)[' .. #entity .. ']:'
		end
		indent = indent .. '\t'
		for k, v in pairs( entity ) do
			subtable = concat(subtable, '\n', indent, k, ': ', dump(v, indent, omitType))
		end
		return subtable
	elseif type( entity ) == 'nil' or type( entity ) == 'function' or type( entity ) == 'boolean' then
		return ( not omitType and '(' .. type(entity) .. ') ' or '' ) .. print(entity)
	elseif type( entity ) == 'string' then
		entity = mw.ustring.gsub(mw.ustring.gsub(entity, "\\'", "'"), "'", "\\'")
		return concat(omitType or '(string) ', '\'', entity, '\'')
	else
		-- number value expected
		return concat(omitType or '(' .. type( entity ) .. ') ', entity)
	end
end

return p
