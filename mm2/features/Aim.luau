return function(app)
    local feature = {target = nil}
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.IgnoreWater = true
    function feature:update(dt, camera)
        self.target = nil
        local s, input = app.settings, app.services.UserInputService
        local own = app.game.entries[app.player]
        if not s.AimEnabled or app.menu:isOpen() or input:GetFocusedTextBox() or not app.game:isAlive(own) then return end
        if s.AimGunOnly and own.weapon ~= "Gun" then return end
        local held
        if s.AimKey:sub(1, 11) == "MouseButton" then held = input:IsMouseButtonPressed(Enum.UserInputType[s.AimKey])
        else held = input:IsKeyDown(Enum.KeyCode[s.AimKey]) end
        if not held then return end
        local best, bestDistance = nil, s.AimRadius
        local center = camera.ViewportSize / 2
        params.FilterDescendantsInstances = {own.character, camera, app.effectsRoot}
        for player, entry in pairs(app.game.entries) do
            if player ~= app.player and app.game:isAlive(entry) and app.Roles.target(s.AimTarget, entry.role) then
                local part = entry.character:FindFirstChild(s.AimPart) or entry.root
                if part:IsA("BasePart") and (part.Position - camera.CFrame.Position).Magnitude <= s.AimRange then
                    local point = part.Position + part.AssemblyLinearVelocity * (s.AimPrediction / 1000)
                    local projected, onScreen = app.Draw.project(camera, point)
                    local distance = (projected - center).Magnitude
                    if onScreen and distance < bestDistance then
                        local hit = s.AimVisible and workspace:Raycast(camera.CFrame.Position, part.Position - camera.CFrame.Position, params) or nil
                        if not hit or hit.Instance:IsDescendantOf(entry.character) then
                            best, bestDistance, self.target = point, distance, entry
                        end
                    end
                end
            end
        end
        if best and (best - camera.CFrame.Position).Magnitude > 0.01 then
            camera.CFrame = camera.CFrame:Lerp(CFrame.lookAt(camera.CFrame.Position, best),
                1 - math.exp(-60 * math.min(dt, 0.1) / s.AimSmoothing))
        end
    end
    return feature
end
