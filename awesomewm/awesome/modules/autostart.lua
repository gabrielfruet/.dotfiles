local awful = require('awful')

return {
    run = function()
        awful.spawn.with_shell(os.getenv('HOME') .. '/.screenlayout/default_dualmonitor.sh')
        awful.spawn.with_shell('picom --experimental-backends || picom')
    end
}

