local Draw = {}
function Draw.new(class, properties, parent)
    local object = Instance.new(class)
    for key, value in pairs(properties) do object[key] = value end
    object.Parent = parent
    return object
end
function Draw.label(parent, position, size)
    return Draw.new("TextLabel", {BackgroundTransparency = 1, Position = position, Size = size,
        Text = "", TextSize = 12, Font = Enum.Font.GothamMedium, TextColor3 = Color3.new(1, 1, 1),
        TextStrokeTransparency = 0.25}, parent)
end
function Draw.line(parent)
    return Draw.new("Frame", {BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Visible = false}, parent)
end
function Draw.segment(line, a, b, color, thickness)
    local delta = b - a
    line.Position = UDim2.fromOffset((a.X + b.X) / 2, (a.Y + b.Y) / 2)
    line.Size = UDim2.fromOffset(delta.Magnitude, thickness or 1)
    line.Rotation = math.deg(math.atan2(delta.Y, delta.X))
    line.BackgroundColor3 = color
    line.Visible = true
end
function Draw.project(camera, point)
    local screen, onScreen = camera:WorldToViewportPoint(point)
    return Vector2.new(screen.X, screen.Y), onScreen and screen.Z > 0.1, screen.Z
end
function Draw.bounds(camera, character)
    local cf, size = character:GetBoundingBox()
    local half = size / 2
    local low, high = Vector2.new(math.huge, math.huge), Vector2.new(-math.huge, -math.huge)
    for x = -1, 1, 2 do for y = -1, 1, 2 do for z = -1, 1, 2 do
        local p = camera:WorldToViewportPoint(cf:PointToWorldSpace(Vector3.new(x * half.X, y * half.Y, z * half.Z)))
        if p.Z < 0.1 then return nil end
        low = Vector2.new(math.min(low.X, p.X), math.min(low.Y, p.Y))
        high = Vector2.new(math.max(high.X, p.X), math.max(high.Y, p.Y))
    end end end
    local viewport = camera.ViewportSize
    if high.X < 0 or high.Y < 0 or low.X > viewport.X or low.Y > viewport.Y then return nil end
    return low, high - low
end
return Draw
