return function(app)
    local lib = app.modules["ui/Library"](app)
    app.library = lib
    lib.AccentColor = app:color("Accent")
    local window = lib:CreateWindow({Name = "NIX LUA", Content = "MURDER MYSTERY 2",
        Size = UDim2.fromOffset(760, 560), Keybind = app.settings.MenuKey,
        ConfigFolder = "NixLUA/MM2", Enable3DRenderer = false})
    window:SetAccount({Username = app.player.DisplayName, Expires = "Nix LUA · local", Profile = ""})
    local menu = {controls = {}, window = window, updating = false}
    local logger = lib:CreateLogger()
    function menu:notify(message) logger.new("info", tostring(message), 4) end
    function menu:isOpen() return window.Signal:GetValue() == true end
    function menu:sync(key)
        if key == "Accent" then lib.AccentColor = app:color("Accent") end
        if key == "MenuKey" then window.Keybind = app.settings.MenuKey end
        local control = self.controls[key]
        if control then
            self.updating = true
            local value = app.settings[key]
            if app.Settings.schema[key].kind == "color" then value = Color3.fromHex(value) end
            local ok, err = pcall(function() control:SetValue(value) end)
            self.updating = false
            if not ok then error(err) end
        end
    end
    local function control(section, key, title, hint)
        local spec = app.Settings.schema[key]
        local row = section:AddLabel(title)
        if hint then row:ToolTip(hint) end
        local config = {Default = app.settings[key], Flag = key, Callback = function(value)
            if not app.scope.alive or menu.updating then return end
            if typeof(value) == "Color3" then value = value:ToHex() end
            app:set(key, value, true)
        end}
        local element
        if spec.kind == "boolean" then element = row:AddToggle(config)
        elseif spec.kind == "number" then config.Min, config.Max, config.Rounding = spec.min, spec.max, 0 element = row:AddSlider(config)
        elseif spec.kind == "color" then config.Default = app:color(key) element = row:AddColorPicker(config)
        else config.Values, config.Multi, config.Size = spec.values, false, 140 element = row:AddDropdown(config) end
        menu.controls[key] = element
    end
    local function section(tab, name, side, controls)
        local group = tab:AddSection({Name = name, Position = side})
        for _, c in ipairs(controls) do control(group, c[1], c[2], c[3]) end
        return group
    end
    window:AddTabLabel("NIX / MM2")
    local aim = window:AddTab({Name = "Aim assist", Icon = "crosshairs"})
    section(aim, "ASSIST", "left", {{"AimEnabled", "Enable aim assist"}, {"AimKey", "Hold key"},
        {"AimTarget", "Targets"}, {"AimGunOnly", "Only with gun", "Checks for Gun in your character or backpack"},
        {"AimVisible", "Visibility check"}, {"AimPart", "Target part"}})
    section(aim, "TUNING", "right", {{"AimRadius", "Radius · px"}, {"AimSmoothing", "Smoothing", "Higher values turn more slowly"},
        {"AimPrediction", "Prediction · ms", "Linear velocity lead; keep at 0 unless needed"}, {"AimRange", "Range · studs"}, {"AimCircle", "FOV circle"}})
    local esp = window:AddTab({Name = "Player ESP", Icon = "eye"})
    section(esp, "OVERLAY", "left", {{"ESPEnabled", "Enable ESP"}, {"ESPBoxes", "Boxes"}, {"ESPNames", "Names"},
        {"ESPRoles", "Roles"}, {"ESPHealth", "Health bar"}, {"ESPDistance", "Distance"}, {"ESPWeapon", "Weapon"},
        {"ESPSkeleton", "Skeleton"}, {"ESPTracers", "Tracers"}, {"ESPArrows", "Offscreen arrows"}})
    section(esp, "FILTERS & CHAMS", "right", {{"ShowInnocent", "Show innocents"}, {"ShowUnknown", "Show unknown roles"},
        {"ESPRange", "Range · studs"}, {"ESPChams", "Character chams"}, {"ESPThroughWalls", "Chams through walls"},
        {"ChamsOpacity", "Fill opacity · %"}, {"GunESP", "Dropped gun ESP"}})
    local roles = window:AddTab({Name = "Roles & colors", Icon = "person"})
    section(roles, "ROLE COLORS", "left", {{"MurdererColor", "Murderer"}, {"SheriffColor", "Sheriff"}, {"HeroColor", "Hero"},
        {"InnocentColor", "Innocent"}, {"UnknownColor", "Unknown"}, {"GunColor", "Dropped gun"}})
    section(roles, "ROUND INFO", "right", {{"RolePanel", "Role panel"}, {"RoleNotifications", "Role notifications"}})
    local status = roles:AddSection({Name = "DATA SOURCE", Position = "right"})
    menu.status = status:AddLabel("Waiting for MM2 role data", true)
    status:AddLabel("Unknown roles remain Unknown; data expires after 6 seconds.", true)
    local world = window:AddTab({Name = "World", Icon = "globe"})
    section(world, "LIGHTING", "left", {{"Fullbright", "Fullbright"}, {"NoFog", "Remove fog"}, {"TimeOverride", "Override time"},
        {"Time", "Hour"}, {"AmbientOverride", "Custom ambient"}, {"AmbientColor", "Ambient tint"}, {"Sky", "Skybox"}})
    section(world, "POST PROCESSING", "right", {{"ColorCorrection", "Color correction"}, {"Saturation", "Saturation"},
        {"Contrast", "Contrast"}, {"Tint", "Tint"}, {"Bloom", "Bloom"}, {"BloomIntensity", "Bloom intensity"},
        {"FOVOverride", "Camera FOV override"}, {"FOV", "Camera FOV"}})
    local character = window:AddTab({Name = "Local visuals", Icon = "sparkles"})
    section(character, "CHARACTER", "left", {{"EffectColor", "Effect color"}, {"RainbowEffects", "Rainbow effects"},
        {"Trail", "Movement trail"}, {"TrailLifetime", "Trail lifetime · 0.1s"}, {"ChinaHat", "China hat"},
        {"HatSize", "Hat size · 0.1x"}, {"HatOpacity", "Hat opacity · %"}})
    section(character, "EXTRAS", "right", {{"SelfChams", "Self chams"}, {"JumpRings", "Jump pulses"}, {"Sparkles", "Sparkles"},
        {"Crosshair", "Crosshair"}, {"CrosshairSize", "Crosshair size"}, {"CrosshairRotate", "Rotate crosshair"}})
    local movement = window:AddTab({Name = "Movement", Icon = "person-running"})
    section(movement, "CHARACTER MOVEMENT", "left", {{"SpeedOverride", "Override walk speed"}, {"WalkSpeed", "Walk speed"},
        {"JumpOverride", "Override jump strength"}, {"JumpPower", "Jump power"}, {"BunnyHop", "Bunnyhop · hold Space"}})
    local notes = movement:AddSection({Name = "BEHAVIOR", Position = "right"})
    notes:AddLabel("Movement values are restored on disable and unload. The game may override them.", true)
    window:AddTabLabel("CONFIGURATION")
    local settings = window:AddTab({Name = "Settings", Icon = "gear"})
    section(settings, "INTERFACE", "left", {{"Accent", "Accent color"}, {"MenuKey", "Menu key"}, {"Watermark", "Watermark"}})
    local configs = settings:AddSection({Name = "LOCAL CONFIGS", Position = "right"})
    local configName = "default"
    configs:AddLabel("Config name"):AddTextInput({Default = configName, Callback = function(value) configName = value end})
    local function action(group, name, callback)
        group:AddButton({Name = name, Callback = function()
            if not app.scope.alive then return end
            local ok, err = pcall(callback)
            if not ok then app:notify(tostring(err)) end
        end})
    end
    action(configs, "Save config", function() app.config:save(configName) end)
    action(configs, "Load config", function() app.config:load(configName) end)
    action(configs, "Reset settings", function() app:apply(app.Settings.defaults()) end)
    local system = settings:AddSection({Name = "SYSTEM", Position = "left"})
    action(system, "Diagnostics", function() app:notify(app.game.diagnostics .. " | Place " .. tostring(game.PlaceId)) end)
    action(system, "Unload · End", function() app:Unload() end)
    window.Signal:SetValue(true)
    -- Explicit initial visibility, independent of delayed callbacks in the vendor UI.
    lib.ScreenGui.Enabled = true
    lib.ScreenGui.Name = "NixLUA_MM2_Menu"
    window.Root.Position = UDim2.fromScale(0.5, 0.5)
    window.Root.Visible = true
    window:SetRender(true)
    app.scope:add(function() window.Signal:SetValue(false) lib:Unload() end)
    return menu
end
