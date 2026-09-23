return function(app)
    local feature = {records = {}, guns = {}}
    local D = app.Draw
    local function make(entry)
        local scope = app.scope:fork()
        local group = scope:add(D.new("Frame", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1}, app.overlay))
        local box = D.new("Frame", {BackgroundTransparency = 1, Visible = false}, group)
        local stroke = D.new("UIStroke", {Thickness = 1}, box)
        local title = D.label(box, UDim2.new(0.5, -140, 0, -32), UDim2.fromOffset(280, 30))
        local detail = D.label(box, UDim2.new(0.5, -140, 1, 2), UDim2.fromOffset(280, 30))
        local health = D.new("Frame", {BackgroundColor3 = Color3.fromRGB(12, 16, 21), BorderSizePixel = 0,
            Size = UDim2.new(0, 3, 1, 0), Position = UDim2.fromOffset(-6, 0)}, box)
        local fill = D.new("Frame", {BorderSizePixel = 0, AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1)}, health)
        local highlight = scope:add(D.new("Highlight", {Adornee = entry.character, Enabled = false}, app.effectsRoot))
        local tracer = D.line(group)
        local arrow = D.label(group, UDim2.new(), UDim2.fromOffset(22, 22))
        arrow.Text = "▲" arrow.AnchorPoint = Vector2.new(0.5, 0.5) arrow.Visible = false
        local joints = {}
        for _, joint in ipairs(entry.character:GetDescendants()) do
            if joint:IsA("Motor6D") and joint.Part0 and joint.Part1 then
                table.insert(joints, {joint = joint, line = D.line(group)})
            end
        end
        return {scope = scope, character = entry.character, box = box, stroke = stroke, title = title,
            detail = detail, health = health, fill = fill, highlight = highlight, tracer = tracer, arrow = arrow, joints = joints}
    end
    local function hide(record)
        record.box.Visible = false record.highlight.Enabled = false record.tracer.Visible = false record.arrow.Visible = false
        for _, item in ipairs(record.joints) do item.line.Visible = false end
    end
    function feature:update(_, camera)
        local s = app.settings
        for player, record in pairs(self.records) do
            local entry = app.game.entries[player]
            if not entry or entry.character ~= record.character then record.scope:destroy() self.records[player] = nil else hide(record) end
        end
        for player, entry in pairs(app.game.entries) do
            if player ~= app.player and app.game:isAlive(entry) and s.ESPEnabled and (entry.role ~= "Innocent" or s.ShowInnocent)
                and (entry.role ~= "Unknown" or s.ShowUnknown) then
                local distance = (entry.root.Position - camera.CFrame.Position).Magnitude
                if distance <= s.ESPRange then
                    local r = self.records[player]
                    if not r then r = make(entry) self.records[player] = r end
                    local color = app:roleColor(entry.role)
                    r.highlight.Enabled = s.ESPChams
                    r.highlight.FillColor, r.highlight.OutlineColor = color, color
                    r.highlight.FillTransparency = 1 - s.ChamsOpacity / 100
                    r.highlight.DepthMode = s.ESPThroughWalls and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
                    local position, size = D.bounds(camera, entry.character)
                    local point, onScreen = D.project(camera, entry.root.Position)
                    if position then
                        r.box.Visible = true r.box.Position = UDim2.fromOffset(position.X, position.Y)
                        r.box.Size = UDim2.fromOffset(size.X, size.Y)
                        r.stroke.Enabled, r.stroke.Color = s.ESPBoxes, color
                        local titles = {}
                        if s.ESPNames then table.insert(titles, player.DisplayName) end
                        if s.ESPRoles then table.insert(titles, entry.role) end
                        r.title.Text, r.title.TextColor3 = table.concat(titles, "\n"), color
                        local details = {}
                        if s.ESPDistance then table.insert(details, math.floor(distance) .. " st") end
                        if s.ESPWeapon then table.insert(details, entry.weapon) end
                        r.detail.Text = table.concat(details, " · ")
                        r.health.Visible = s.ESPHealth
                        local ratio = math.clamp(entry.humanoid.Health / math.max(1, entry.humanoid.MaxHealth), 0, 1)
                        r.fill.Size = UDim2.fromScale(1, ratio)
                        r.fill.BackgroundColor3 = Color3.fromRGB(255, 80, 95):Lerp(Color3.fromRGB(90, 230, 150), ratio)
                    end
                    if s.ESPTracers and onScreen then D.segment(r.tracer, Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y - 4), point, color) end
                    if s.ESPSkeleton then
                        for _, item in ipairs(r.joints) do
                            local joint = item.joint
                            if joint.Parent and joint.Part0 and joint.Part1 then
                                local a, visibleA = D.project(camera, joint.Part0.Position)
                                local b, visibleB = D.project(camera, joint.Part1.Position)
                                if visibleA and visibleB then D.segment(item.line, a, b, color) end
                            end
                        end
                    end
                    if s.ESPArrows and not onScreen then
                        local delta = camera.CFrame:PointToObjectSpace(entry.root.Position)
                        local direction = Vector2.new(delta.X, -delta.Y)
                        if delta.Z > 0 then direction = Vector2.new(delta.X, math.abs(delta.Z)) end
                        if direction.Magnitude < 0.01 then direction = Vector2.new(0, -1) end
                        local p = camera.ViewportSize / 2 + direction.Unit * math.min(camera.ViewportSize.X, camera.ViewportSize.Y) * 0.39
                        r.arrow.Position = UDim2.fromOffset(p.X, p.Y)
                        r.arrow.Rotation = math.deg(math.atan2(direction.Y, direction.X)) + 90
                        r.arrow.TextColor3, r.arrow.Visible = color, true
                    end
                end
            end
        end
        for object, r in pairs(self.guns) do
            if not app.game.gunDrops[object] then r.scope:destroy() self.guns[object] = nil else r.label.Visible = false r.highlight.Enabled = false end
        end
        if s.GunESP then for object in pairs(app.game.gunDrops) do
            local position = app.game:dropPosition(object)
            if position and (position - camera.CFrame.Position).Magnitude <= s.ESPRange then
                local r = self.guns[object]
                if not r then
                    local scope = app.scope:fork()
                    r = {scope = scope, label = scope:add(D.label(app.overlay, UDim2.new(), UDim2.fromOffset(180, 20))),
                        highlight = scope:add(D.new("Highlight", {Adornee = object, FillTransparency = 0.4}, app.effectsRoot))}
                    r.label.AnchorPoint = Vector2.new(0.5, 0.5) self.guns[object] = r
                end
                local p, onScreen = D.project(camera, position)
                r.label.Position, r.label.Visible = UDim2.fromOffset(p.X, p.Y), onScreen
                r.label.Text, r.label.TextColor3 = "DROPPED GUN", app:color("GunColor")
                r.highlight.Enabled, r.highlight.FillColor, r.highlight.OutlineColor = true, app:color("GunColor"), app:color("GunColor")
            end
        end end
    end
    return feature
end
