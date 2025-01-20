local args = { ... }

if #args == 0 then
    error('Specify operation: get, push, check, list, host, unhost')
end

if args[1] == "host" then
    ftp.host()
    print("FTP server hosted")
    return
elseif args[1] == "unhost" then
    ftp.closeHost()
    print("FTP server unhosted")
    return
elseif args[1] == 'help' then
    print('Network File Transfer Protocol Help:')
    print('- host: Start a FTP fileserver based on config')
    print('- unhost: Stop the FTP fileserver')
    print('- list [remote]: List all files at remote path')
    print('- check [remote]: Check if the file a remote path exists')
    print('- get [remote] [local]: Get the file from remote and store to local')
    print('- push [local] [remote]: Push the local file to remote')
    print('- help: Print this list')
    return
end

if args[1] == 'push' then
    if #args < 3 then
        error('Too few arguments: ftp push [local] [remote]', 0)
        return
    elseif #args > 3 then
        error('Too many arguments: ftp push [local] [remote]', 0)
        return
    end
    local origin = args[2]
    local _, dest, path = net.splitUrl(args[3])

    local s, r = ftp.send(origin, dest, path)
    if s then
        print("File " .. origin .. " sent to ftp://" .. dest .. "/" .. path)
    else
        error("FTP Error: " .. r, 0)
    end
    return
end

if #args < 2 then
    error('Too few arguments: ftp {check/list} [remote] OR ftp get [remote] [local] OR ftp push [local] [remote]', 0)
end
local _, domain, path = net.splitUrl(args[2])
if args[1] == 'check' then
    local s, r = ftp.check(path, domain)
    if s then
        if r then
            print("File ftp://"..domain.."/"..path.." exists")
        else
            print("File ftp://"..domain.."/"..path.." does not exists")
        end
    else
        error("FTP Error: "..r, 0)
    end
elseif args[1] == "list" then
    local s, list = ftp.list(path, domain)
    if s then
        for _,f in pairs(list--[[@as table]]) do
            print(f)
        end
    else
        error("FTP Error: "..list, 0)
    end
elseif args[1] == "get" then
    if #args < 3 then
        error('Too few arguments: ftp get [remote] [local]', 0)
        return
    end
    local s, r = ftp.request(path, domain, args[3])
    if s then
        print("File gotten from ftp://"..domain.."/"..path..' and stored to '..args[3])
    else
        error("FTP Error: "..r, 0)
    end
else
    error("Unknown operation: get, push, check, list, host, unhost", 0)
end