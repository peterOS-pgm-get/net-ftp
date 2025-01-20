--- Network FTP package. Uses the POS net module
_G.ftp = {
    ---If the package has been setup yet
    isSetup = false
}

local cfgPath = "/home/.appdata/ftp/cfg.json"
local defCfg = {
    path = "/home/ftp/",
    push = true,
    get = true,
    check = true,
    overwrite = true,
    delete = true,
}
local cfg = defCfg
local handlerID = -1

local function fixCfg()
    local good = true
    if not cfg.path then cfg.path = defCfg.path; good = false end
    if not cfg.push then cfg.push = defCfg.push; good = false end
    if not cfg.get then cfg.get = defCfg.get; good = false end
    if not cfg.check then cfg.check = defCfg.check; good = false end
    if not cfg.overwrite then cfg.overwrite = defCfg.overwrite; good = false end
    if not cfg.delete then cfg.delete = defCfg.delete; good = false end
    return not good
end

---Setup FTP functions.
ftp.setup = function()
    if ftp.isSetup then
        return
    end
    net.setup()
    net.open(net.standardPorts.ftp)
    if fs.exists(cfgPath) then
        local f = fs.open(cfgPath, "r")
        if f then
            cfg = textutils.unserialiseJSON(f.readAll())
            f.close()
            if cfg == nil then
                cfg = defCfg
            else
                if fixCfg() then
                    local fw = fs.open(cfgPath, "w")
                    if fw then
                        fw.write(textutils.serialiseJSON(cfg))
                        fw.close()
                    else
                        error('Could not write config',0)
                    end
                end
            end
        end
    else
        local f = fs.open(cfgPath, "w")
        if f then
            f.write(textutils.serialiseJSON(cfg))
            f.close()
        else
            error('could not write config',0)
        end
    end
    ftp.isSetup = true
end

--- Send a file to the remote
--- @param lFile string local file path
--- @param dest string|NetAddress remote domain name or IP
--- @param rFile string remote file path
--- @return boolean suc if it succeeded
--- @return string error error description
ftp.send = function(lFile, dest, rFile)
    ftp.setup()
    local f = fs.open(lFile, "r")
    if f == nil then
        -- error("Failed to read file", 0)
        return false, "Local File Access Error"
    end
    local rsp = net.sendAdvSync(net.standardPorts.ftp, dest, {
        type = "ftp",
        action = "push",
    }, {
        filename = rFile,
        file = f.readAll()
    })
    f.close()

    if type(rsp) == "string" then
        return false, rsp
    end

    if not rsp.header.suc then
        return false, rsp.header.response
    end

    return true, ""
end
--- Send a file to the remote
--- @param file string File contents
--- @param dest string|NetAddress remote domain name or IP
--- @param rFile string remote file path
--- @return boolean suc if it succeeded
--- @return string error error description
ftp.sendRaw = function(file, dest, rFile)
    ftp.setup()
    local rsp = net.sendAdvSync(net.standardPorts.ftp, dest, {
        type = "ftp",
        action = "push",
    }, {
        filename = rFile,
        file = file
    })

    if type(rsp) == "string" then
        return false, rsp
    end

    if not rsp.header.suc then
        return false, rsp.header.response
    end

    return true, ""
end
---Requests a file from remote and saves it to a local file
---@param rFile string remote file path
---@param remote string|NetAddress Remote domain name or IP
---@param lFile string local file path
---@return boolean suc if the request was successful
---@return string error error description
ftp.request = function(rFile, remote, lFile)
    ftp.setup()
    local rsp = net.sendAdvSync(net.standardPorts.ftp, remote, {
        type = "ftp",
        action = "get",
    }, {
        filename = rFile
    })

    if type(rsp) == "string" then
        return false, rsp
    end

    if not rsp.header.suc then
        return false, rsp.header.response
    end

    local f = fs.open(lFile, "w")
    if f == nil then
        return false, "Local File Access Error"
    end
    f.write(rsp.body.file)
    f.close()

    return true, ""
end
---Requests a file from remote and return it's content
---@param rFile string remote file path
---@param remote string|NetAddress Remote domain name or IP
---@return boolean suc if the request was successful
---@return string rsp file text or error description
ftp.requestRaw = function(rFile, remote)
    ftp.setup()
    local rsp = net.sendAdvSync(net.standardPorts.ftp, remote, {
        type = "ftp",
        action = "get",
    }, {
        filename = rFile
    })

    if type(rsp) == "string" then
        return false, rsp
    end

    if not rsp.header.suc then
        return false, rsp.header.response
    end

    return true, rsp.body.file
end
---Check if a file exists on the remote
---@param rFile string remote path
---@param remote string|NetAddress remote domain or IP
---@return boolean suc if the check could be performed
---@return string|boolean rsp if the file existed OR error description
ftp.check = function(rFile, remote)
    ftp.setup()
    local rsp = net.sendAdvSync(net.standardPorts.ftp, remote, {
        type = "ftp",
        action = "check",
    }, {
        filename = rFile
    })

    if type(rsp) == "string" then
        return false, rsp
    end

    if not rsp.header.suc then
        return false, rsp.header.response
    end

    return true, rsp.body.exists
end
---List files and folders on remote
---@param rRoot string remote path
---@param remote string |NetAddress remote domain or IP
---@return boolean suc if the check could be performed
---@return string|table rsp list of files and folders OR error description
ftp.list = function(rRoot, remote)
    ftp.setup()
    local rsp = net.sendAdvSync(net.standardPorts.ftp, remote, {
        type = "ftp",
        action = "list",
    }, {
        root = rRoot
    })

    if type(rsp) ~= "table" then
        return false, rsp
    end

    if not rsp.header.suc then
        return false, rsp.header.response
    end

    return true, rsp.body.list
end
---Delete a file on the remote
---@param rFile string remote path
---@param remote string|NetAddress remote domain or IP
---@return boolean suc if the deletion succeeded
---@return string error error description
ftp.delete = function(rFile, remote)
    ftp.setup()
    local rsp = net.sendAdvSync(net.standardPorts.ftp, remote, {
        type = "ftp",
        action = "delete",
    }, {
        filename = rFile
    })

    if type(rsp) == "string" then
        return false, rsp
    end

    if not rsp.header.suc then
        return false, rsp.header.response
    end

    return true, ''
end
---Performs an FTP action on the remote
---@param action string FTP action name
---@param rFile string Remote file path
---@param remote string|NetAddress Remote domain or IP
---@return boolean suc if the action was successful
---@return string|table|nil rsp response from action OR error message
ftp.action = function(action, rFile, remote)
    ftp.setup()
    local rsp = net.sendAdvSync(net.standardPorts.ftp, remote, {
        type = "ftp",
        action = action,
    }, {
        filename = rFile
    })

    if type(rsp) ~= "table" then
        return false, rsp
    end

    if not rsp.header.suc then
        return false, rsp.header.response
    end

    return true, rsp
end

---Start an FTP file server on this device using config file
---@return boolean open if the server was started
ftp.host = function()
    if handlerID ~= -1 then
        return true
    end
    ftp.setup()
    local serverLog = pos.Logger('net-ftp-server.log',false)
    handlerID = net.registerMsgHandler(function(msg)
        if msg.port ~= net.standardPorts.ftp then return end
        if msg.header.type ~= "ftp" then return end
        if msg.dest == -1 then return end
        
        -- print("FTP Msg: " .. net.stringMessage(msg))
        -- print('Action: "'..msg.header.action..'"')
        
        if msg.header.action == "check" then
            if not cfg.check then
                serverLog:warn('Someone tried to check, but that is not allowed')
                net.reply(net.standardPorts.ftp, msg, {
                    type = "ftp",
                    suc = false,
                    response = "Invalid Action",
                    originDomain = cfg.domain,
                }, {})
                return
            end
            serverLog:debug('Received check for '..msg.body.filename)
            net.reply(net.standardPorts.ftp, msg, {
                type = "ftp",
                suc = true,
                originDomain = cfg.domain,
            }, {
                exists = fs.exists(cfg.path .. msg.body.filename)
            })
            return
        elseif msg.header.action == "list" then
            if not cfg.check then
                serverLog:warn('Someone tried to list, but that is not allowed')
                msg:reply(net.standardPorts.ftp, {
                    type = "ftp",
                    suc = false,
                    response = "Invalid Action",
                    originDomain = cfg.domain,
                }, {})
                return
            end
            serverLog:debug('Received list from '..msg.body.root)
            msg:reply(net.standardPorts.ftp, {
                type = "ftp",
                suc = true,
                originDomain = cfg.domain,
            }, {
                list = fs.list(cfg.path .. msg.body.root)
            })
            return
        elseif msg.header.action == "push" then
            if not cfg.push then
                serverLog:warn('Someone tried to push, but that is not allowed')
                net.reply(net.standardPorts.ftp, msg, {
                    type = "ftp",
                    suc = false,
                    response = "Invalid Action",
                    originDomain = cfg.domain,
                }, {})
                return
            end
            if (not cfg.overwrite) and fs.exists(cfg.path .. msg.body.filename) then
                serverLog:warn('Someone tried to overwrite, but that is not allowed')
                net.reply(net.standardPorts.ftp, msg, {
                    type = "ftp",
                    suc = false,
                    response = "File Already Exists",
                    originDomain = cfg.domain,
                }, {})
                return
            end
            serverLog:debug('Received push to '..msg.body.filename)
            local f, e = fs.open(cfg.path .. msg.body.filename, "w")
            if f == nil then
                serverLog:error('File access error: '..msg.body.filename..'; '..e)
                net.reply(net.standardPorts.ftp, msg, {
                    type = "ftp",
                    suc = false,
                    response = "File Access Error",
                    originDomain = cfg.domain,
                }, {})
                return
            end
            f.write(msg.body.file)
            f.close()
            net.reply(net.standardPorts.ftp, msg, {
                type = "ftp",
                suc = true,
                originDomain = cfg.domain,
            }, {})
            return
        elseif msg.header.action == "get" then
            if not cfg.get then
                serverLog:warn('Someone tried to get, but that is not allowed')
                net.reply(net.standardPorts.ftp, msg, {
                    type = "ftp",
                    suc = false,
                    response = "Invalid Action",
                    originDomain = cfg.domain,
                }, {})
                return
            end
            if not fs.exists(cfg.path .. msg.body.filename) then
                serverLog:warn('Someone tried to get a file that did not exist')
                net.reply(net.standardPorts.ftp, msg, {
                    type = "ftp",
                    suc = false,
                    response = "File Does Not Exist",
                    originDomain = cfg.domain,
                }, {})
                return
            end
            serverLog:debug('Received get for '..msg.body.filename)
            local f, e = fs.open(cfg.path .. msg.body.filename, "r")
            if f == nil then
                serverLog:error('File access error: '..msg.body.filename..'; '..e)
                net.reply(net.standardPorts.ftp, msg, {
                    type = "ftp",
                    suc = false,
                    response = "File Access Error",
                    originDomain = cfg.domain,
                }, {})
                return
            end
            net.reply(net.standardPorts.ftp, msg, {
                type = "ftp",
                suc = true,
                originDomain = cfg.domain,
            }, {
                file = f.readAll()
            })
            f.close()
            return
        elseif msg.header.action == "delete" then
            if not cfg.delete then
                serverLog:warn('Someone tried to delete, but that is not allowed')
                net.reply(net.standardPorts.ftp, msg, {
                    type = "ftp",
                    suc = false,
                    response = "Invalid Action",
                    originDomain = cfg.domain,
                }, {})
                return
            end
            serverLog:debug('Received delete for '..msg.body.filename)
            fs.delete(cfg.path .. msg.body.filename)
            net.reply(net.standardPorts.ftp, msg, {
                type = "ftp",
                suc = true,
                originDomain = cfg.domain,
            }, {})
            return
        elseif msg.header.action == "isDir" then
            serverLog:debug('Received is dir for '..msg.body.filename)
            net.reply(net.standardPorts.ftp, msg, {
                type = "ftp",
                suc = true,
                originDomain = cfg.domain,
            }, {
                isDir = fs.isDir(cfg.path .. msg.body.filename)
            })
            return
        elseif msg.header.action == "find" then
            serverLog:debug('Received find for '..msg.body.filename)
            fs.isDir(cfg.path .. msg.body.filename)
            net.reply(net.standardPorts.ftp, msg, {
                type = "ftp",
                suc = true,
                originDomain = cfg.domain,
            }, {
                list = fs.find(cfg.path .. msg.body.filename)
            })
            return
        elseif msg.header.action then
            -- print('Unknown action: ' .. msg.header.action)
            serverLog:warn('Received unknown action: '..msg.header.action)
            net.reply(net.standardPorts.ftp, msg, {
                type = "ftp",
                suc = false,
                response = "Unknown Action",
                originDomain = cfg.domain,
            }, {})
            return
        end
    end)
    return true
end

---Close the FTP host
ftp.closeHost = function()
    ftp.setup()
    net.unregisterMsgHandler(handlerID)
    handlerID = -1
end

---Gets the network message handler ID. For debug purposes
---@return integer handlerID network message handler ID
ftp.getHandlerId = function()
    return handlerID
end

---Creates a new Connection Object
---@param domain string|number Domain name or IP of remote
---@param rootPath string root path at domain
---@return table con Connection object
local function Connection(domain, rootPath)
    rootPath = rootPath or ''
    local o = {
        domain = domain,
        root = rootPath,
        active = false
    }
    ---Connect to the remote
    ---@return boolean suc if the connection succeeded
    function o:connect()
        local r, e = ftp.list(self.root, self.domain)
        if not r then
            print('FTP Error: '..e, 0)
            return false
        end
        self.active = true
        return true
    end

    ---Get the full remote path.
    ---@param path string remote path
    ---@return string path full remote path including connection root path
    function o:_fullPath(path)
        if string.start(path, '/') then
            return self.root .. path
        else
            return self.root .. '/' .. path
        end
    end

    ---Get the list of files and folders
    ---@param path string remote path from connection root
    ---@return boolean suc if the list could be gotten
    ---@return string|table rsp list of files and folders OR error string if failed
    function o:list(path)
        if not self.active then
            return false, 'Connection not open'
        end
        path = self:_fullPath(path or '')
        return ftp.list(path, self.domain)
    end

    ---Checks if a file or folder exists
    ---@param path string remote path from connection root
    ---@return boolean suc if the check could be performed
    ---@return string|boolean rsp if the file existed OR error string if failed
    function o:check(path)
        if not self.active then
            return false, 'Connection not open'
        end
        path = self:_fullPath(path or '')
        return ftp.check(path, self.domain)
    end

    ---Delete a file on the remote
    ---@param path string remote path from connection root
    ---@return boolean suc if the deletion could be performed
    ---@return string error error string
    function o:delete(path)
        if not self.active then
            return false, 'Connection not open'
        end
        path = self:_fullPath(path or '')
        return ftp.delete(path, self.domain)
    end

    ---Gets a file from the remote
    ---@param rPath string remote path of file
    ---@param lPath string local path to save to
    ---@return boolean suc if the file was gotten successfully
    ---@return string error error description
    function o:get(rPath, lPath)
        if not self.active then
            return false, 'Connection not open'
        end
        rPath = self:_fullPath(rPath or '')
        return ftp.request(rPath, self.domain, lPath)
    end

    ---Sends a file to the remote
    ---@param lPath string local file path
    ---@param rPath string remote file path from connection root
    ---@return boolean suc if the file was sent successful
    ---@return string error error description
    function o:put(lPath, rPath)
        if not self.active then
            return false, 'Connection not open'
        end
        rPath = self:_fullPath(rPath or '')
        return ftp.send(lPath, self.domain, rPath)
    end

    ---Performs an ftp action on the remote
    ---@param action string action name
    ---@param path string path from remote root
    ---@return boolean suc if the action was successful
    ---@return string|table|nil rsp response from action OR error message
    function o:action(action, path)
        if not self.active then
            return false, 'Connection not open'
        end
        path = self:_fullPath(path or '')
        return ftp.action(action, path, self.domain)
    end

    return o
end
---Connect to a remote file server
---@param url string full URL of remote including domain and path
---@return FTPConnection con Connection object
ftp.connect = function(url)
    -- local _, domain, path = net.splitUrl(url)
    -- local con = Connection(domain, path)
    -- con:connect()
    -- return con
    return ftp.FTPConnection(url)
end

dofile('/os/bin/net-ftp/FTPConnection.lua')
dofile('/os/bin/net-ftp/FTPMount.lua')