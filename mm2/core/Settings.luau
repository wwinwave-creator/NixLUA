local Settings = {schema = {}}
local function field(key, kind, default, a, b)
    Settings.schema[key] = {kind = kind, default = default, min = a, max = b, values = kind == "choice" and a or nil}
end
local function bool(key, value) field(key, "boolean", value == true) end
local function number(key, value, low, high) field(key, "number", value, low, high) end
local function choice(key, value, values) field(key, "choice", value, values) end
local function color(key, value) field(key, "color", value) end
bool("AimEnabled") bool("AimVisible", true) bool("AimGunOnly", true) bool("AimCircle", true)
choice("AimTarget", "Murderer", {"Murderer", "Armed", "Everyone"})
choice("AimPart", "Head", {"Head", "HumanoidRootPart"})
choice("AimKey", "MouseButton2", {"MouseButton2", "MouseButton1", "LeftAlt", "Q", "E"})
number("AimRadius", 150, 20, 500) number("AimSmoothing", 10, 1, 30)
number("AimPrediction", 0, 0, 250) number("AimRange", 600, 50, 2500)
bool("ESPEnabled") bool("ESPBoxes", true) bool("ESPNames", true) bool("ESPRoles", true)
bool("ESPDistance", true) bool("ESPHealth", true) bool("ESPWeapon") bool("ESPSkeleton")
bool("ESPTracers") bool("ESPArrows") bool("ESPChams") bool("ESPThroughWalls", true)
bool("ShowInnocent", true) bool("ShowUnknown", true) bool("GunESP", true)
number("ESPRange", 700, 50, 2500) number("ChamsOpacity", 30, 0, 100)
color("MurdererColor", "FF547B") color("SheriffColor", "65A7FF") color("HeroColor", "FFC870")
color("InnocentColor", "75D7B0") color("UnknownColor", "A5AABC") color("GunColor", "FFE08A")
bool("Fullbright") bool("NoFog") bool("TimeOverride") number("Time", 14, 0, 24)
bool("AmbientOverride") color("AmbientColor", "9889BB")
bool("ColorCorrection") number("Saturation", 15, -100, 100) number("Contrast", 10, -50, 50)
color("Tint", "FFFFFF") bool("Bloom") number("BloomIntensity", 10, 0, 100)
choice("Sky", "Game", {"Game", "Black Storm", "Roblox Classic"})
bool("FOVOverride") number("FOV", 85, 50, 120)
bool("Crosshair") number("CrosshairSize", 7, 3, 24) bool("CrosshairRotate")
color("EffectColor", "9B86FF") bool("RainbowEffects") bool("Trail") number("TrailLifetime", 10, 2, 40)
bool("ChinaHat") number("HatSize", 18, 8, 35) number("HatOpacity", 50, 10, 100)
bool("SelfChams") bool("JumpRings") bool("Sparkles")
bool("SpeedOverride") number("WalkSpeed", 22, 8, 60)
bool("JumpOverride") number("JumpPower", 60, 20, 120) bool("BunnyHop")
bool("Watermark", true) bool("RolePanel", true) bool("RoleNotifications", true)
color("Accent", "719DFF")
choice("MenuKey", "RightShift", {"RightShift", "Insert", "Home", "F4"})

function Settings.defaults()
    local result = {}
    for key, spec in pairs(Settings.schema) do result[key] = spec.default end
    return result
end
function Settings.validate(key, value)
    local spec = Settings.schema[key]
    if not spec then return nil end
    if spec.kind == "boolean" then if type(value) == "boolean" then return value end
    elseif spec.kind == "number" then
        if type(value) == "number" and value == value and math.abs(value) < math.huge then
            return math.floor(math.clamp(value, spec.min, spec.max) + 0.5)
        end
    elseif spec.kind == "color" then
        if type(value) == "string" and value:match("^%x%x%x%x%x%x$") then return value:upper() end
    elseif spec.kind == "choice" then
        if table.find(spec.values, value) then return value end
    end
    return nil
end
function Settings.decode(data)
    if type(data) ~= "table" or data.version ~= 2 or data.game ~= "MM2" or type(data.settings) ~= "table" then
        return nil, "Expected an MM2 config, version 2"
    end
    local values = Settings.defaults()
    for key, value in pairs(data.settings) do
        if Settings.schema[key] then
            local valid = Settings.validate(key, value)
            if valid == nil then return nil, "Invalid config field: " .. tostring(key) end
            values[key] = valid
        end
    end
    return values
end
function Settings.path(name)
    if type(name) ~= "string" or #name < 1 or #name > 32 or not name:match("^[%w_-]+$") then return nil end
    local upper = name:upper()
    if upper == "CON" or upper == "PRN" or upper == "AUX" or upper == "NUL"
        or upper:match("^COM%d$") or upper:match("^LPT%d$") then return nil end
    return "NixLUA/MM2/" .. name .. ".json"
end
return Settings
