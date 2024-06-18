---@package ftp

---@class FTPMount FTP mount
---@field domain string Mount domain name
---@field path string Mount root path
---@field name string Mount name
---@field lPath string Local path *(Read Only)*
---@field con FTPConnection FTP connection to remote
local FTPMount = {}

---Create a new FTP mount
---@param name string Mount name
---@param url string Mount remote url
---@return FTPMount mount
function ftp.FTPMount(name, url)
    local o = {}
    setmetatable(o, { __index = FTPMount })
    o:__init__(name, url)
    return o
end

---Initialize the FTP mount object
---@package
---@param name string Mount name
---@param url string Mount remote url
function FTPMount:__init__(name, url)
    self.name = name
    _, self.domain, self.path = net.splitUrl(url)
    self.lPath = '/mnt/' .. name
    self.con = ftp.FTPConnection(self.domain, self.path)
    self.con:connect()
end

---Returns if the mount is connected to the remote
---@return boolean connected
function FTPMount:isConnected()
    return self.con.active
end

---Gets a display path for the path
---@protected
---@param path string Path from mount root
---@return string path Path from remote root
function FTPMount:_getDispPath(path)
    return 'ftp://'..self.domain..'/'..self.path..'/'..path
end

---Checks if a given file exists
---@param path string Path from mount root
---@return boolean exists
function FTPMount:exists(path)
    local s, r = self.con:check(path)
    if not s or type(r) ~= "boolean" then
        return false
    end
    return r
end

---Open a remote file
---@param path string Path from mount root
---@param mode string Mode string: <code>r</code>, <code>w</code>, or <code>a</code> (binary not implemented)
---@return Handle? handle File handle
---@return string? error Error message
function FTPMount:open(path, mode)
    if mode == 'r' then
        if not self:exists(path) then
            return nil, 'Remote file does not exist'
        end
        local rh = {}
        local s, r = self.con:getRaw(path)
        if not s then
            return nil, 'Unable to open remote file ' .. self:_getDispPath(path)
        end
        local text = r ---@type string|nil
        local _closed = false
        function rh.readLine(withTrailing)
            if _closed then error('File handle was already closed', 2) end
            if not text then return nil end
            withTrailing = withTrailing or false
            local st = text:find('\n')
            if not st then
                local t = text
                text = nil
                return t
            end
            if withTrailing then
                local t = text:sub(0, st)
                text = text:sub(st + 1)
                if text == '' then text = nil end
                return t
            end
            local t = text:sub(0, st - 1)
            text = text:sub(st + 1)
            if text == '' then text = nil end
            return t
        end

        function rh.readAll()
            if _closed then error('File handle was already closed', 2) end
            if not text then return nil end
            local t = text
            text = nil
            return t
        end

        function rh.read(count)
            if _closed then error('File handle was already closed', 2) end
            if not text then return nil end
            count = count or 1
            local t = text:sub(0, count)
            text = text:sub(1 + 1)
            if text == '' then text = nil end
            return t
        end

        function rh.close()
            _closed = true
            text = nil
        end

        return rh
    elseif mode == 'w' or mode == 'a' then
        local wh = {}
        local _text = ''
        if mode == 'a' then
            if not self:exists(path) then
                return nil, 'Remote file does not exist'
            end
            local s, r = self.con:getRaw(path)
            if not s then
                return nil, 'Unable to open remote  file ' .. self:_getDispPath(path)
            end
            _text = r
        end
        local _closed = false
        function wh.write(text)
            if _closed then error('File handle was already closed', 2) end
            _text = _text .. text
        end

        function wh.writeLine(text)
            if _closed then error('File handle was already closed', 2) end
            _text = _text .. text .. '\n'
        end

        function wh.flush()
            if _closed then error('File handle was already closed', 2) end
            self.con:putRaw(path, _text)
        end

        function wh.close()
            wh.flush()
            _closed = true
            _text = ''
        end

        -- function rh.readLine(withTrailing)
        --     withTrailing = withTrailing or false
        --     local st = text:find('\n')
        --     if not st then
        --         local t = text
        --         text = ''
        --         return t
        --     end
        --     if withTrailing then
        --         local t = text:sub(0, st)
        --         text = text:sub(st + 1)
        --         return t
        --     end
        --     local t = text:sub(0, st - 1)
        --     text = text:sub(st + 1)
        --     return t
        -- end
        -- function rh.readAll()
        --     local t = text
        --     text = ''
        --     return t
        -- end
        -- function rh.read(count)
        --     count = count or 1
        --     local t = text:sub(0, count)
        --     text = text:sub(1 + 1)
        --     return t
        -- end
        -- function rh.close() end
        return wh
    end
    return nil, 'Unknown mode, or not implemented for FTP'
end

---Deletes a file on the remote
---@param path string Path from mount root
---@return boolean deleted
function FTPMount:delete(path)
    local s, r = self.con:delete(path)
    if not s or type(r) == 'string' then
        return false
    end
    return r
end