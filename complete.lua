local completion = require "cc.shell.completion"
local complete = completion.build(
    { completion.choice, { "get", "push", "check", "list", "host", "unhost", "help" } }
)

return { complete=complete }