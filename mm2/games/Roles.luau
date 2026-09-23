-- Pure policy for MM2 data. Unknown is never silently treated as Innocent.
local Roles = {}
function Roles.resolve(data, knife, gun)
    if type(data) == "table" and (data.Dead == true or data.Killed == true) then return "Dead" end
    if knife then return "Murderer" end
    if gun then return type(data) == "table" and data.Role == "Sheriff" and "Sheriff" or "Hero" end
    if type(data) == "table" then
        if data.Role == "Murderer" or data.Role == "Sheriff" or data.Role == "Innocent" or data.Role == "Hero" then return data.Role end
    end
    return "Unknown"
end
function Roles.target(mode, role)
    if role == "Dead" then return false end
    if mode == "Murderer" then return role == "Murderer" end
    if mode == "Armed" then return role == "Murderer" or role == "Sheriff" or role == "Hero" end
    return mode == "Everyone"
end
return Roles
