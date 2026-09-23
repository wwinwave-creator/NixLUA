return function(app)
    local players = app.services.Players
    local storage = app.services.ReplicatedStorage
    local state = {entries = {}, roles = {}, busy = false, lastSuccess = -math.huge,
        lastRequest = -math.huge, lastScan = -math.huge, gunDrops = {}, diagnostics = "Waiting for role data"}
    local remote, generation = nil, 0
    local function tool(character, backpack, name)
        return (character and character:FindFirstChild(name)) or (backpack and backpack:FindFirstChild(name))
    end
    function state:isAlive(entry)
        return entry and entry.alive and entry.character.Parent ~= nil and entry.root.Parent ~= nil
            and entry.humanoid.Parent ~= nil and entry.humanoid.Health > 0
    end
    function state:refresh(now)
        if now - self.lastScan < 0.2 then return end
        self.lastScan = now
        local entries = {}
        for _, player in ipairs(players:GetPlayers()) do
            local character = player.Character
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            local root = character and character:FindFirstChild("HumanoidRootPart")
            if humanoid and root and root:IsA("BasePart") and character.Parent then
                local backpack = player:FindFirstChildOfClass("Backpack")
                local knife, gun = tool(character, backpack, "Knife"), tool(character, backpack, "Gun")
                local data = now - self.lastSuccess < 6 and self.roles[player.Name] or nil
                local role = app.Roles.resolve(data, knife ~= nil, gun ~= nil)
                local previous = self.entries[player]
                if app.settings.RoleNotifications and player ~= app.player and previous and previous.role ~= role
                    and (role == "Murderer" or role == "Sheriff" or role == "Hero") then
                    app:notify(player.DisplayName .. " → " .. role)
                end
                entries[player] = {player = player, character = character, humanoid = humanoid, root = root,
                    role = role, weapon = knife and "Knife" or gun and "Gun" or "—",
                    alive = humanoid.Health > 0 and role ~= "Dead"}
            end
        end
        self.entries = entries
    end
    function state:poll(now)
        if self.busy or now - self.lastRequest < 2 then return end
        self.lastRequest = now
        if not remote or not remote.Parent then
            remote = storage:FindFirstChild("GetPlayerData", true)
        end
        if not remote or not remote:IsA("RemoteFunction") then
            self.diagnostics = "GetPlayerData unavailable; using visible tools"
            return
        end
        self.busy = true
        generation += 1
        local ticket = generation
        -- Never invoke from RenderStepped; one request maximum, even if the server stalls.
        app.scope:spawn(function()
            local ok, data = pcall(function() return remote:InvokeServer() end)
            if not app.scope.alive or ticket ~= generation then return end
            self.busy = false
            if ok and type(data) == "table" then
                self.roles, self.lastSuccess = data, os.clock()
                self.diagnostics = "Role data available"
            else self.diagnostics = "Role request failed; using visible tools" end
        end)
    end
    local function track(object)
        if object.Name == "GunDrop" and (object:IsA("BasePart") or object:IsA("Model")) then state.gunDrops[object] = true end
    end
    for _, object in ipairs(workspace:GetDescendants()) do track(object) end
    app.scope:connect(workspace.DescendantAdded, track)
    app.scope:connect(workspace.DescendantRemoving, function(object) state.gunDrops[object] = nil end)
    function state:dropPosition(object)
        if not object.Parent then return nil end
        if object:IsA("BasePart") then return object.Position end
        if object:IsA("Model") then return object:GetPivot().Position end
        return nil
    end
    return state
end
