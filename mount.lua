local expect = require "cc.expect"

local mounts = {} ---@type FTPMount[]

local tempFile = '/home/.temp/ftp'

---Checks if a path is inside a mounted FTP file server
---@param _path string local filepath
---@return FTPMount|nil mount mount the path is in, or nil if not in a mounted file server
---@return string path the relative path inside the mount
local function isInMount(_path)
    expect(1, _path, 'string')
    _path = pos.realizePath(_path)
    if string.start(_path, '/mnt/') then
        local parts = string.split(_path, '/')
        if #parts < 3 then
            return nil, ''
        end
        local mnt = mounts[parts[3]]
        return mnt, table.concat(parts, '/', 4)
    else
        return nil, ''
    end
end

local fsExists = fs.exists
fs.exists = function(_path)
    expect(1, _path, 'string')
    local mnt, path = isInMount(_path)
    if mnt then
        if path == '' then return true end
        -- return mnt.con:check(_path)
        return mnt:exists(path)
    end
    return fsExists(_path)
end

local fsOpen = fs.open
fs.open = function(_path, _mode)
    expect(1, _path, 'string')
    expect(2, _mode, 'string')
    local mnt, path = isInMount(_path)
    if mnt then
        return mnt:open(path, _mode)
    end
    return fsOpen(_path, _mode)
end

local fsIsDriveRoot = fs.isDriveRoot
fs.isDriveRoot = function(_path)
    expect(1, _path, 'string')
    local mnt, path = isInMount(_path)
    if mnt then
        return path == '' or path == '/'
    end
    return fsIsDriveRoot(_path)
end

local fsList = fs.list
fs.list = function(_path)
    expect(1, _path, 'string')
    -- print('FS listening at: ' .. pos.realizePath(_path))
    if pos.realizePath(_path) == '/mnt' then
        local l = fsList(_path)
        if type(l) ~= 'table' then
            return l
        end
        ---@cast l table
        for n, _ in pairs(mounts) do
            table.insert(l, n)
        end
        return l
    end
    local mnt, path = isInMount(_path)
    if mnt then
        local r, l = mnt.con:list(path)
        if not r then
            error('Could not get list of files', 0)
            return
        end
        return l
    end
    return fsList(_path)
end
local fsIsDir = fs.isDir
fs.isDir = function(_path)
    expect(1, _path, 'string')
    local mnt, path = isInMount(_path)
    if not mnt then
        return fsIsDir(_path)
    end
    if path == '' then
        return true
    end
    local s, r = mnt.con:action('isDir', path)
    if not s or not r then
        error('FTP Error: ' .. r, 0)
    end
    return r.body.isDir
end

local fsGetSize = fs.getSize
fs.getSize = function(_path)
    expect(1, _path, 'string')
    local mnt, path = isInMount(_path)
    if mnt then
        return 0
    end
    return fsGetSize(_path)
end
local fsMakeDir = fs.makeDir
fs.makeDir = function(_path) -- STUB
    expect(1, _path, 'string')
    local mnt, path = isInMount(_path)
    if not mnt then
        return fsMakeDir(_path)
    end
    error('Operation not yet possible over FTP', 0)
end

local fsMove = fs.move
fs.move = function(_src, _dest)
    expect(1, _src, 'string')
    expect(2, _dest, 'string')
    local sMnt, sPath = isInMount(_src)
    local dMnt, dPath = isInMount(_dest)
    if not sMnt and not dMnt then
        return fsMove(_src, _dest)
    end

    local dFile = _dest
    if dMnt then
        dFile = tempFile
    end
    local sFile = _src
    if sMnt then
        sMnt.con:get(sPath, dFile)
        sMnt.con:delete(sPath)
        sFile = dFile
    else
        fs.delete(sFile)
    end
    if dMnt then
        dMnt.con:put(sFile, dPath)
    end
end
local fsCopy = fs.copy
fs.copy = function(_src, _dest)
    expect(1, _src, 'string')
    expect(2, _dest, 'string')
    local sMnt, sPath = isInMount(_src)
    local dMnt, dPath = isInMount(_dest)
    if not sMnt and not dMnt then
        return fsCopy(_src, _dest)
    end

    local dFile = _dest
    if dMnt then
        dFile = tempFile
    end
    local sFile = _src
    if sMnt then
        sMnt.con:get(sPath, dFile)
        sFile = dFile
    end
    if dMnt then
        dMnt.con:put(sFile, dPath)
    end
end

local fsDelete = fs.delete
fs.delete = function(_path)
    expect(1, _path, 'string')
    local mnt, path = isInMount(_path)
    if not mnt then
        return fsDelete(_path)
    end
    return mnt:delete(path)
    -- mnt.con:delete(path)
end

local fsGetDrive = fs.getDrive
fs.getDrive = function(_path)
    expect(1, _path, 'string')
    local mnt, path = isInMount(_path)
    if not mnt then
        _path = pos.realizePath(_path)
        if string.start(_path, '/mnt/') then
            return nil
        end
        return fsGetDrive(_path)
    end
    return mnt.name
end
local fsGetFreeSpace = fs.getFreeSpace
fs.getFreeSpace = function(_path) -- STUB
    expect(1, _path, 'string')
    local mnt, path = isInMount(_path)
    if not mnt then
        return fsGetFreeSpace(_path)
    end
    return 1e9
end
local fsGetCapacity = fs.getCapacity
fs.getCapacity = function(_path) -- STUB
    expect(1, _path, 'string')
    local mnt, path = isInMount(_path)
    if not mnt then
        return fsGetCapacity(_path)
    end
    return 1e9
end
local fsFind = fs.find
fs.find = function(_path)
    expect(1, _path, 'string')
    local mnt, path = isInMount(_path)
    if not mnt then
        return fsFind(_path)
    end
    local s, r = mnt.con:action('find', _path)
    if not s or not r then
        error('FTP Error: ' .. r, 0)
    end
    return r.body.list
end
local fsAttributes = fs.attributes
fs.attributes = function(_path) -- STUB
    expect(1, _path, 'string')
    local mnt, path = isInMount(_path)
    if not mnt then
        return fsAttributes(_path)
    end
    error('Operation not yet possible over FTP', 0)
end


---Mount an ftp file server as a local directory
---@param name string local mount name
---@param remote string remote file server url
---@return boolean mounted if the mount was successful
local function mount(name, remote)
    local path = '/mnt/' .. name
    -- if fs.exists(path) then
    --     error('Something is already mounted at ' .. path, 0)
    --     return false
    -- end
    local _, domain, rPath = net.splitUrl(remote)
    -- local mnt = {
    --     domain = domain,
    --     path = rPath,
    --     name = name,
    --     lPath = path,
    --     con = ftp.connect(remote)
    -- }
    local mnt = ftp.FTPMount(name, remote)
    if not mnt:isConnected() then
        error('Could not find remote ftp://' .. domain .. '/' .. rPath, 0)
        return false
    end
    mounts[name] = mnt
    return true
end
---Unmount and ftp file server
---@param name string local mount name
---@return boolean unmounted if the remote was unmounted
local function unmount(name)
    if not mounts[name] then
        return false
    end
    mounts[name] = nil
    return true
end
---Get a list of all mounted ftp file servers
---@return table mounts list of local names for mounts
local function listMounts()
    local list = {}
    for name, _ in pairs(mounts) do
        table.insert(list, name)
    end
    return list
end
---Gets the details about the named mount
---@param name string local mount name
---@return table|nil mount Table containing name, domain, and root OR nil if mount did not exist
local function getMount(name)
    if not mounts[name] then
        return nil
    end
    local mnt = mounts[name]
    return {
        name = mnt.name,
        domain = mnt.domain,
        root = mnt.path,
        con = mnt.con
    }
end

---FTP mounting module, used to mount FTP file servers as local directories under /mnt/
ftp.mount = {
    mount = mount,
    unmount = unmount,
    list = listMounts,
    getMount = getMount
}