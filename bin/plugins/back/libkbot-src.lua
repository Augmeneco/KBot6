libkb = {}

function libkb.scandir(directory) 
    local i, t, popen = 0, {}, io.popen 
    local pfile = popen('ls -a "'..directory..'"') 
    for filename in pfile:lines() do 
        if not libkb.check(filename,{'.','..'}) then
            i = i + 1 
            t[i] = filename 
        end
    end 
    pfile:close() 
    return t
end

function libkb.check(str,t)
    for _, v in pairs(t) do
        if v == str then return true end
    end
    return t[str] ~= nil
end

function split(text,del)
    ret = {}
    layout = "[^DEL]+"
    layout = layout:gsub('DEL',del)
    for i in text:gmatch(layout) do ret[#ret+1]=i end
    return ret
end

function libkb.fix_names(msg)
    user_text = split(msg.text,' ')
    table.remove(user_text,1)
    table.remove(user_text,1)
    user_text = table.concat(user_text,' ')

    msg.toho = msg.peer_id
    msg.userid = msg.from_id
    msg.text_split = split(msg.text,' ')
    msg.user_text = user_text
    return msg
end

function libkb.apisay(...)
    args = ...
    vkapi('messages.send',{message=args[1],peer_id=args[2]})
end

return libkb