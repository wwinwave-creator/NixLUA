return function(modules)
    local env = (getgenv and getgenv()) or _G
    if type(env.NixLUA) == "table" and type(env.NixLUA.Unload) == "function" then env.NixLUA:Unload() end
    local Scope, Settings = modules["core/Scope"], modules["core/Settings"]
    local app = {Version = "0.2.0", Game = "MM2", modules = modules, Settings = Settings,
        settings = Settings.defaults(), scope = Scope.new(), services = {}, colorCache = {}}
    env.NixLUA = app
    function app:Unload()
        self.scope:destroy()
        if env.NixLUA == self then env.NixLUA = nil end
    end
    function app:color(key)
        local hex = self.settings[key]
        if not self.colorCache[hex] then self.colorCache[hex] = Color3.fromHex(hex) end
        return self.colorCache[hex]
    end
    function app:roleColor(role)
        return self:color(self.Settings.schema[role .. "Color"] and role .. "Color" or "UnknownColor")
    end
    function app:notify(message)
        if self.menu then self.menu:notify(message) else warn("[Nix LUA] " .. tostring(message)) end
    end
    function app:set(key, value, fromUI)
        local valid = Settings.validate(key, value)
        if valid == nil then return false end
        self.settings[key] = valid
        if self.menu then
            if not fromUI then self.menu:sync(key)
            elseif key == "Accent" then self.library.AccentColor = self:color("Accent")
            elseif key == "MenuKey" then self.menu.window.Keybind = valid end
        end
        return true
    end
    function app:apply(values)
        for key, value in pairs(values) do self:set(key, value) end
    end
    local function initialize()
        for _, name in ipairs({"Players", "RunService", "UserInputService", "ReplicatedStorage", "Lighting", "HttpService"}) do
            app.services[name] = game:GetService(name)
        end
        app.player = app.services.Players.LocalPlayer
        assert(app.player, "Nix LUA requires a client")
        app.parent = app.player:WaitForChild("PlayerGui", 10)
        local hidden = gethui or get_hidden_gui
        if hidden then local ok, result = pcall(hidden) if ok and typeof(result) == "Instance" then app.parent = result end end
        assert(app.parent, "PlayerGui is unavailable")
        app.Draw, app.Roles = modules["visuals/Draw"], modules["games/Roles"]
        app.overlay = app.scope:add(app.Draw.new("ScreenGui", {Name = "NixLUA_MM2_Overlay", ResetOnSpawn = false,
            IgnoreGuiInset = true, DisplayOrder = 990, ZIndexBehavior = Enum.ZIndexBehavior.Sibling}, app.parent))
        app.effectsRoot = app.scope:add(app.Draw.new("Folder", {Name = "NixLUA_MM2_Effects"}, workspace))
        app.config = modules["core/Config"](app)
        app.game = modules["games/MM2"](app)
        app.menu = modules["ui/Menu"](app)
        app.features = {}
        for _, name in ipairs({"features/World", "features/Movement", "features/Character", "features/ESP", "features/Aim", "visuals/HUD"}) do
            table.insert(app.features, modules[name](app))
        end
        app.scope:connect(app.services.UserInputService.InputBegan, function(event)
            if event.KeyCode == Enum.KeyCode.End and not app.services.UserInputService:GetFocusedTextBox() then app:Unload() end
        end)
        local elapsed = 0
        local function render(dt)
            local camera = workspace.CurrentCamera
            if not camera then app.overlay.Enabled = false return end
            app.overlay.Enabled = true
            local now = os.clock()
            app.game:refresh(now)
            app.game:poll(now)
            for _, feature in ipairs(app.features) do feature:update(dt, camera) end
            elapsed += dt
            if elapsed > 1 then
                elapsed = 0
                local status = app.game.busy and (now - app.game.lastRequest > 8) and "Role request pending; using tool fallback" or app.game.diagnostics
                app.menu.status:SetText(status)
            end
        end
        local binding = "NixLUA_MM2_Render"
        app.services.RunService:BindToRenderStep(binding, Enum.RenderPriority.Camera.Value + 1, function(dt)
            if not app.scope.alive then return end
            local ok, err = xpcall(function() render(dt) end, debug.traceback)
            if not ok then warn("[Nix LUA] Runtime stopped: " .. tostring(err)) app:Unload() end
        end)
        app.scope:add(function() app.services.RunService:UnbindFromRenderStep(binding) end)
        app:notify("Nix LUA · MM2 ready | Insert: menu | End: unload")
    end
    local ok, err = xpcall(initialize, debug.traceback)
    if not ok then app:Unload() error("[Nix LUA] Startup failed:\n" .. tostring(err)) end
    return app
end
