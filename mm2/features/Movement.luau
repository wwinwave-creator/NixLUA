return function(app)
    local feature = {humanoid = nil, lastJump = 0}
    local scope = app.scope:fork()
    function feature:update()
        local entry = app.game.entries[app.player]
        local humanoid = entry and entry.humanoid
        if self.humanoid and self.humanoid ~= humanoid then scope:restore(self.humanoid) end
        self.humanoid = humanoid
        if not humanoid then return end
        if not app.game:isAlive(entry) then scope:restore(humanoid) return end
        local s, input = app.settings, app.services.UserInputService
        if s.SpeedOverride then scope:set(humanoid, "WalkSpeed", s.WalkSpeed) else scope:restore(humanoid, "WalkSpeed") end
        if s.JumpOverride then
            local property = humanoid.UseJumpPower and "JumpPower" or "JumpHeight"
            local other = humanoid.UseJumpPower and "JumpHeight" or "JumpPower"
            scope:restore(humanoid, other)
            local value = humanoid.UseJumpPower and s.JumpPower or s.JumpPower ^ 2 / (2 * math.max(1, workspace.Gravity))
            scope:set(humanoid, property, value)
        else scope:restore(humanoid, "JumpPower") scope:restore(humanoid, "JumpHeight") end
        if s.BunnyHop and not app.menu:isOpen() and not input:GetFocusedTextBox() and input:IsKeyDown(Enum.KeyCode.Space)
            and humanoid.FloorMaterial ~= Enum.Material.Air and not humanoid.Sit and os.clock() - self.lastJump > 0.12 then
            self.lastJump = os.clock() humanoid.Jump = true
        end
    end
    return feature
end
