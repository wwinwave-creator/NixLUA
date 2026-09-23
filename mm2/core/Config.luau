return function(app)
    local config = {}
    function config:save(name)
        local path = app.Settings.path(name)
        assert(path, "Name: 1–32 letters, digits, _ or -")
        assert(writefile and isfolder and makefolder, "Filesystem functions unavailable")
        if not isfolder("NixLUA") then makefolder("NixLUA") end
        if not isfolder("NixLUA/MM2") then makefolder("NixLUA/MM2") end
        writefile(path, app.services.HttpService:JSONEncode({game = "MM2", version = 2, settings = app.settings}))
        app:notify("Saved config: " .. name)
    end
    function config:load(name)
        local path = app.Settings.path(name)
        assert(path, "Invalid config name")
        assert(readfile and isfile and isfile(path), "Config unavailable")
        local raw = readfile(path)
        assert(type(raw) == "string" and #raw <= 65536, "Config is too large")
        local values, err = app.Settings.decode(app.services.HttpService:JSONDecode(raw))
        assert(values, err)
        app:apply(values)
        app:notify("Loaded config: " .. name)
    end
    return config
end
