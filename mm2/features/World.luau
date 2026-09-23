return function(app)
    local feature = {camera = nil, skyMode = "Game", skyScope = nil}
    local scope = app.scope:fork()
    local lighting = app.services.Lighting
    local correction = scope:add(app.Draw.new("ColorCorrectionEffect", {Name = "NixLUA_Color", Enabled = false}, lighting))
    local bloom = scope:add(app.Draw.new("BloomEffect", {Name = "NixLUA_Bloom", Enabled = false, Size = 24, Threshold = 1}, lighting))
    local skies = {
        ["Black Storm"] = {"15502511288", "15502508460", "15502510289", "15502507918", "15502509398", "15502511911"},
        ["Roblox Classic"] = {"bk", "dn", "ft", "lf", "rt", "up"},
    }
    function feature:update(_, camera)
        local s = app.settings
        if self.camera and self.camera ~= camera then scope:restore(self.camera) end
        self.camera = camera
        if s.FOVOverride then scope:set(camera, "FieldOfView", s.FOV) else scope:restore(camera, "FieldOfView") end
        if s.Fullbright then scope:set(lighting, "Brightness", 2) scope:set(lighting, "GlobalShadows", false)
        else scope:restore(lighting, "Brightness") scope:restore(lighting, "GlobalShadows") end
        for _, key in ipairs({"Ambient", "OutdoorAmbient"}) do
            if s.AmbientOverride or s.Fullbright then scope:set(lighting, key, s.AmbientOverride and app:color("AmbientColor") or Color3.fromRGB(170, 170, 170))
            else scope:restore(lighting, key) end
        end
        if s.TimeOverride then scope:set(lighting, "ClockTime", s.Time) else scope:restore(lighting, "ClockTime") end
        for _, property in ipairs({"FogStart", "FogEnd"}) do
            if s.NoFog then scope:set(lighting, property, 1000000) else scope:restore(lighting, property) end
        end
        for _, object in ipairs(lighting:GetChildren()) do
            if object:IsA("Atmosphere") then
                if s.NoFog then scope:set(object, "Density", 0) scope:set(object, "Haze", 0) else scope:restore(object) end
            end
        end
        correction.Enabled = s.ColorCorrection
        correction.Saturation, correction.Contrast, correction.TintColor = s.Saturation / 100, s.Contrast / 100, app:color("Tint")
        bloom.Enabled, bloom.Intensity = s.Bloom, s.BloomIntensity / 50
        if self.skyMode ~= s.Sky then
            if self.skyScope then self.skyScope:destroy() self.skyScope = nil end
            self.skyMode = s.Sky
            if s.Sky ~= "Game" then
                self.skyScope = app.scope:fork()
                local sky = lighting:FindFirstChildOfClass("Sky")
                if not sky then sky = self.skyScope:add(Instance.new("Sky")) sky.Parent = lighting end
                for index, key in ipairs({"SkyboxBk", "SkyboxDn", "SkyboxFt", "SkyboxLf", "SkyboxRt", "SkyboxUp"}) do
                    local value = skies[s.Sky][index]
                    self.skyScope:set(sky, key, s.Sky == "Roblox Classic" and ("rbxasset://textures/sky/sky512_" .. value .. ".tex") or ("rbxassetid://" .. value))
                end
            end
        end
    end
    return feature
end
