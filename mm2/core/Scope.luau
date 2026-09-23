-- Own resources and reversible property overrides without changing global APIs.
local Scope = {}
Scope.__index = Scope
function Scope.new()
    return setmetatable({alive = true, items = {}, changes = {}, threads = {}, children = {}}, Scope)
end
function Scope:fork()
    local child = Scope.new()
    child.owner = self
    self.children[child] = true
    return child
end
function Scope:spawn(callback, ...)
    local done = false
    local args = table.pack(...)
    local thread = task.spawn(function()
        if self.alive then callback(table.unpack(args, 1, args.n)) end
        done = true
        self.threads[coroutine.running()] = nil
    end)
    if not done then self.threads[thread] = true end
    return thread
end
function Scope:delay(seconds, callback, ...)
    local args = table.pack(...)
    local thread = task.delay(seconds, function()
        if self.alive then callback(table.unpack(args, 1, args.n)) end
        self.threads[coroutine.running()] = nil
    end)
    self.threads[thread] = true
    return thread
end
function Scope:add(item)
    assert(self.alive, "Cannot add resources to a disposed scope")
    table.insert(self.items, item)
    return item
end
function Scope:connect(signal, callback)
    return self:add(signal:Connect(function(...) if self.alive then callback(...) end end))
end
function Scope:set(object, property, value)
    local original = self.changes[object]
    if not original then original = {} self.changes[object] = original end
    if original[property] == nil then original[property] = {object[property]} end
    object[property] = value
end
function Scope:restore(object, property)
    local original = self.changes[object]
    if not original then return end
    if property then
        if original[property] then pcall(function() object[property] = original[property][1] end) end
        original[property] = nil
        if next(original) == nil then self.changes[object] = nil end
    else
        for key, saved in pairs(original) do pcall(function() object[key] = saved[1] end) end
        self.changes[object] = nil
    end
end
function Scope:destroy()
    if not self.alive then return end
    self.alive = false
    if self.owner then self.owner.children[self] = nil end
    for child in pairs(self.children) do child:destroy() end
    for thread in pairs(self.threads) do
        if thread ~= coroutine.running() then pcall(task.cancel, thread) end
    end
    table.clear(self.threads)
    for i = #self.items, 1, -1 do
        local item = self.items[i]
        pcall(function()
            if type(item) == "function" then item()
            elseif type(item) == "thread" then if item ~= coroutine.running() then task.cancel(item) end
            elseif typeof(item) == "RBXScriptConnection" then item:Disconnect()
            elseif typeof(item) == "Instance" then item:Destroy()
            elseif type(item.destroy) == "function" then item:destroy()
            elseif type(item.Disconnect) == "function" then item:Disconnect() end
        end)
    end
    for object in pairs(self.changes) do self:restore(object) end
    table.clear(self.items)
end
return Scope
