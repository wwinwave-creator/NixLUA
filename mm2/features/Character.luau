return function(app)
    local feature = {character = nil, scope = nil, trail = nil, hat = nil, rings = {}, elapsed = 0}
    local D = app.Draw
    function feature:reset(character)
        if self.scope then self.scope:destroy() end
        self.character, self.scope = character, app.scope:fork()
        self.trail, self.hat, self.highlight, self.sparkles = nil, nil, nil, nil
        self.attachments, self.rings = nil, {}
        if not character then return end
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then self.scope:connect(humanoid.StateChanged, function(_, state)
            if not app.settings.JumpRings or state ~= Enum.HumanoidStateType.Jumping then return end
            local root = character:FindFirstChild("HumanoidRootPart")
            if not root then return end
            if #self.rings >= 8 then self.rings[1].scope:destroy() table.remove(self.rings, 1) end
            local ringScope = self.scope:fork()
            local ring = ringScope:add(D.new("Part", {Name = "NixLUA_JumpRing", Anchored = true, CanCollide = false,
                CanTouch = false, CanQuery = false, CastShadow = false, Material = Enum.Material.Neon,
                Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.035, 1, 1), Transparency = 0.35,
                CFrame = CFrame.new(root.Position - Vector3.new(0, humanoid.HipHeight + root.Size.Y / 2, 0)) * CFrame.Angles(0, 0, math.pi / 2)}, app.effectsRoot))
            table.insert(self.rings, {part = ring, scope = ringScope, born = os.clock()})
        end) end
    end
    function feature:update(dt, camera)
        local character = app.player.Character
        if character ~= self.character then self:reset(character) end
        if not character or not character.Parent then return end
        local s = app.settings
        local root, head = character:FindFirstChild("HumanoidRootPart"), character:FindFirstChild("Head")
        if not root or not head then return end
        local color = s.RainbowEffects and Color3.fromHSV((os.clock() * 0.15) % 1, 0.7, 1) or app:color("EffectColor")
        local thirdPerson = (camera.CFrame.Position - head.Position).Magnitude > 1.5
        if s.Trail and not self.trail then
            local a = self.scope:add(D.new("Attachment", {Position = Vector3.new(-0.65, 0, 0)}, root))
            local b = self.scope:add(D.new("Attachment", {Position = Vector3.new(0.65, 0, 0)}, root))
            self.trail = self.scope:add(D.new("Trail", {Attachment0 = a, Attachment1 = b, FaceCamera = true,
                LightEmission = 0.8, MinLength = 0.05, Transparency = NumberSequence.new(0.15, 1)}, root))
        end
        if self.trail then self.trail.Enabled = s.Trail self.trail.Lifetime = s.TrailLifetime / 10 self.trail.Color = ColorSequence.new(color) end
        if s.ChinaHat and not self.hat then
            self.hat = self.scope:add(D.new("Part", {Name = "NixLUA_Hat", Anchored = true, CanCollide = false,
                CanTouch = false, CanQuery = false, CastShadow = false, Material = Enum.Material.Neon, Size = Vector3.new(1, 1, 1)}, app.effectsRoot))
            self.mesh = D.new("SpecialMesh", {MeshId = "rbxassetid://1033714"}, self.hat)
        end
        if self.hat then
            self.hat.Transparency = s.ChinaHat and thirdPerson and (1 - s.HatOpacity / 100) or 1
            self.hat.Color, self.hat.CFrame = color, CFrame.new(head.Position + Vector3.new(0, 0.85, 0))
            self.mesh.Scale = Vector3.new(s.HatSize / 10, 0.7, s.HatSize / 10)
        end
        if s.SelfChams and not self.highlight then self.highlight = self.scope:add(D.new("Highlight", {Adornee = character, FillTransparency = 0.55}, app.effectsRoot)) end
        if self.highlight then self.highlight.Enabled = s.SelfChams and thirdPerson self.highlight.FillColor, self.highlight.OutlineColor = color, color end
        if s.Sparkles and not self.sparkles then self.sparkles = self.scope:add(D.new("Sparkles", {}, root)) end
        if self.sparkles then self.sparkles.Enabled, self.sparkles.SparkleColor = s.Sparkles, color end
        for i = #self.rings, 1, -1 do
            local ring = self.rings[i]
            local age = os.clock() - ring.born
            if age >= 0.8 or not s.JumpRings then ring.scope:destroy() table.remove(self.rings, i) else
                ring.part.Size = Vector3.new(0.035, 1 + age * 9, 1 + age * 9)
                ring.part.Color, ring.part.Transparency = color, 0.35 + age / 0.8 * 0.65
            end
        end
    end
    return feature
end
