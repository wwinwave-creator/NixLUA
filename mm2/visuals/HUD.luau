return function(app)
    local D = app.Draw
    local scope = app.scope:fork()
    local watermark = scope:add(D.label(app.overlay, UDim2.fromOffset(16, 16), UDim2.fromOffset(305, 30)))
    watermark.BackgroundTransparency, watermark.BackgroundColor3 = 0.1, Color3.fromRGB(12, 19, 29)
    D.new("UICorner", {CornerRadius = UDim.new(0, 6)}, watermark)
    local panel = scope:add(D.label(app.overlay, UDim2.fromOffset(16, 54), UDim2.fromOffset(305, 82)))
    panel.BackgroundTransparency, panel.BackgroundColor3 = 0.1, Color3.fromRGB(12, 19, 29)
    D.new("UICorner", {CornerRadius = UDim.new(0, 6)}, panel)
    local circle = scope:add(D.new("Frame", {BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5)}, app.overlay))
    D.new("UICorner", {CornerRadius = UDim.new(1, 0)}, circle)
    local stroke = D.new("UIStroke", {Thickness = 1, Transparency = 0.25}, circle)
    local cross = {}
    for i = 1, 4 do cross[i] = scope:add(D.line(app.overlay)) end
    local feature = {frames = 0, elapsed = 0, fps = 0}
    function feature:update(dt, camera)
        self.frames += 1 self.elapsed += dt
        if self.elapsed >= 1 then self.fps = math.floor(self.frames / self.elapsed) self.elapsed, self.frames = 0, 0 end
        local s, accent = app.settings, app:color("Accent")
        watermark.Visible, watermark.TextColor3 = s.Watermark, accent
        watermark.Text = string.format("NIX LUA  ·  MM2  ·  %d FPS  ·  v0.2", self.fps)
        panel.Visible, panel.TextColor3 = s.RolePanel, accent
        local names, own = {"Murderer: ?", "Sheriff: ?"}, app.game.entries[app.player]
        for _, entry in pairs(app.game.entries) do
            if entry.alive and entry.role == "Murderer" then names[1] = "Murderer: " .. entry.player.DisplayName end
            if entry.alive and (entry.role == "Sheriff" or entry.role == "Hero") then names[2] = entry.role .. ": " .. entry.player.DisplayName end
        end
        panel.Text = "You: " .. (own and own.role or "Unknown") .. "\n" .. table.concat(names, "\n")
        circle.Visible = s.AimEnabled and s.AimCircle
        circle.Size, stroke.Color = UDim2.fromOffset(s.AimRadius * 2, s.AimRadius * 2), accent
        local center = camera.ViewportSize / 2
        for index, line in ipairs(cross) do
            line.Visible = false
            if s.Crosshair then
                local angle = (index - 1) * math.pi / 2 + (s.CrosshairRotate and os.clock() or 0)
                local direction = Vector2.new(math.cos(angle), math.sin(angle))
                D.segment(line, center + direction * 3, center + direction * (3 + s.CrosshairSize), accent, 2)
            end
        end
    end
    return feature
end
