local p = {} --p stands for package

-- from https://lol.fandom.com/wiki/Module:EsportsUtil
function p.stripDab(str)
    -- don't return second values
    local ret = str:gsub('_', ' '):gsub('%s*%(.*%)','')
    return ret
end

function p.stripPipe(str)
    local ret = str:gsub('%|.*',''):gsub('%]%]','')
    return ret
end

return p
