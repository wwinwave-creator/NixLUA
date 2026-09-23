-- Upload loader.lua and the mm2 folder together at the repository root.
-- NixLUA_Source = {repo = "username/repository", ref = "main" or a commit SHA}
local env = (getgenv and getgenv()) or _G
print("[Nix LUA] Loader v0.2.1 started")
local source = env.NixLUA_Source
assert(type(source) == "table" and type(source.repo) == "string" and type(source.ref) == "string",
    "Set getgenv().NixLUA_Source = {repo = 'username/NixLUA', ref = 'main'} first")
assert(source.repo:match("^[%w_-]+/[%w_.-]+$"), "Invalid GitHub owner/repository")
assert(source.ref:match("^[%w_.-]+$") and not source.ref:find("..", 1, true), "Invalid Git ref; use a branch without / or commit SHA")
local base = "https://raw.githubusercontent.com/" .. source.repo .. "/" .. source.ref .. "/mm2/"
local names = {"core/Scope", "core/Settings", "core/Config", "games/Roles", "games/MM2", "visuals/Draw",
    "ui/Library", "ui/Menu", "features/Aim", "features/ESP", "features/World", "features/Character",
    "features/Movement", "visuals/HUD", "init"}
local chunks, modules = {}, {}
-- Fetch and compile every module before touching an existing instance.
for index, name in ipairs(names) do
    print(string.format("[Nix LUA] Download %d/%d: %s", index, #names, name))
    local ok, body = pcall(function() return game:HttpGet(base .. name .. ".luau") end)
    assert(ok and type(body) == "string", "[Nix LUA] Could not download " .. name .. ": " .. tostring(body))
    local chunk, err = loadstring(body, "NixLUA/" .. name)
    assert(chunk, "Could not compile " .. name .. ": " .. tostring(err))
    chunks[name] = chunk
end
for _, name in ipairs(names) do
    local ok, result = pcall(chunks[name])
    assert(ok, "Could not initialize module " .. name .. ": " .. tostring(result))
    assert(type(result) == "function" or type(result) == "table", "Invalid module export: " .. name)
    modules[name] = result
end
print("[Nix LUA] All modules loaded; initializing MM2")
return modules.init(modules)
