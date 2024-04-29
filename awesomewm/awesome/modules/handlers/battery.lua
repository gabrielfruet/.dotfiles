local M = {}

M.is_chargeable = function ()
    local power_supply_path = "/sys/class/power_supply/"
    local handle = io.popen("ls " .. power_supply_path)
    if not handle then
        print("Cannot open power supply directory.")
        return false
    end

    local result = handle:read("*all")
    handle:close()

    return result:match("BAT%d+") ~= nil
end

M.is_charging = function ()
    local battery_path = "/sys/class/power_supply/BAT0/"
    local status_file_path = battery_path .. "status"

    local status_file = io.open(status_file_path, "r")
    if not status_file then
        print("Cannot open battery status file.")
        return false
    end

    local charging_status = status_file:read("*all")
    status_file:close()

    return charging_status:match("Charging") ~= nil
end

M.bat_percentage = function()
    local battery_path = "/sys/class/power_supply/BAT0/capacity"  -- Adjust BAT0 if your battery is named differently
    local file = io.open(battery_path, "r")  -- Open the battery capacity file

    if not file then
        print("Failed to open file")
        return nil
    end

    local percentage = file:read("*all")  -- Read the content
    file:close()  -- Close the file

    return tonumber(percentage)  -- Convert string to number and return
end

return M
