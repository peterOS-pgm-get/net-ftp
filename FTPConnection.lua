---@package netFtp

---@class FTPConnection
---@field domain string Remote domain name
---@field root string Remote root path
---@field active boolean If the connection is currently active (connected)
local FTPConnection = {}

---Create a new FTP Connection
---@constructor FTPConnection
---@param domain string Remote domain name OR URL
---@param path string|nil Remote root path. If absent <code>domain</code> is assumed to be URL
---@return FTPConnection connection
function ftp.FTPConnection(domain, path)
    local o = {}
    setmetatable(o, { __index = FTPConnection })
    if not path then
        _, domain, path = net.splitUrl(domain)
    end
    o:__init__(domain, path)
    return o
end

---Initializes the connection
---@param domain string Remote domain name
---@param root string|nil Optional. Remote root path
function FTPConnection:__init__(domain, root)
    self.domain = domain
    self.root = root or ''
    self.active = false
end

---Connect to the remote
---@return boolean suc if the connection succeeded
function FTPConnection:connect()
    local r, e = ftp.list(self.root, self.domain)
    if not r then
        print('FTP Error: '..e, 0)
        return false
    end
    self.active = true
    return true
end

---Get the full remote path.
---@package
---@param path string Remote path
---@return string path Full remote path including connection root path
function FTPConnection:_fullPath(path)
    if string.start(path, '/') then
        return self.root .. path
    else
        return self.root .. '/' .. path
    end
end

---Get the list of files and folders
---@param path string Remote path from connection root
---@return boolean suc If the list could be gotten
---@return string|table rsp List of files and folders OR error string if failed
function FTPConnection:list(path)
    if not self.active then
        return false, 'Connection not open'
    end
    path = self:_fullPath(path or '')
    return ftp.list(path, self.domain)
end

---Checks if a file or folder exists
---@param path string Remote path from connection root
---@return boolean suc If the check could be performed
---@return string|boolean rsp If the file existed OR error string if failed
function FTPConnection:check(path)
    if not self.active then
        return false, 'Connection not open'
    end
    path = self:_fullPath(path or '')
    return ftp.check(path, self.domain)
end

---Delete a file on the remote
---@param path string Remote path from connection root
---@return boolean suc If the deletion could be performed
---@return string error Error string
function FTPConnection:delete(path)
    if not self.active then
        return false, 'Connection not open'
    end
    path = self:_fullPath(path or '')
    return ftp.delete(path, self.domain)
end

---Gets a file from the remote
---@param rPath string Remote path of file
---@param lPath string Local path to save to
---@return boolean suc If the file was gotten successfully
---@return string error Error description
function FTPConnection:get(rPath, lPath)
    if not self.active then
        return false, 'Connection not open'
    end
    rPath = self:_fullPath(rPath or '')
    return ftp.request(rPath, self.domain, lPath)
end

---Gets a file from the remote
---@param path string Remote path of file
---@return boolean suc If the file was gotten successfully
---@return string fsp File content or error description
function FTPConnection:getRaw(path)
    if not self.active then
        return false, 'Connection not open'
    end
    path = self:_fullPath(path or '')
    return ftp.requestRaw(path, self.domain)
end

---Sends a file to the remote
---@param lPath string Local file path
---@param rPath string Remote file path from connection root
---@return boolean suc If the file was sent successfully
---@return string error Error description
function FTPConnection:put(lPath, rPath)
    if not self.active then
        return false, 'Connection not open'
    end
    rPath = self:_fullPath(rPath or '')
    return ftp.send(lPath, self.domain, rPath)
end
---Sends a file to the remote
---@param rPath string Remote file path from connection root
---@param file string File contents
---@return boolean suc If the file was sent successfully
---@return string error Error description
function FTPConnection:putRaw(rPath, file)
    if not self.active then
        return false, 'Connection not open'
    end
    rPath = self:_fullPath(rPath or '')
    return ftp.sendRaw(file, self.domain, rPath)
end

---Performs an ftp action on the remote
---@param action string action name
---@param path string path from remote root
---@return boolean suc if the action was successfully
---@return string|table|nil rsp response fro action OR error message
function FTPConnection:action(action, path)
    if not self.active then
        return false, 'Connection not open'
    end
    path = self:_fullPath(path)
    return ftp.action(action, path, self.domain)
end