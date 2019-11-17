local iv = require('nibui.InterpolatedValue')
local Widget = require('nibui.Widget')
local DynamicValue = require('nibui.DynamicValue')

local DEFAULT_W = env.width
local DEFAULT_H = env.height

local NOM = {}

function NOM.require(path, props)
    local nom = copy(require(path))

    if props then
        for k, v in pairs(props) do
            if type(k) == 'number' then
                table.insert(nom, v)
            else
                nom[k] = v
            end
        end
    end

    return nom
end

function NOM.percent(value, prop)
    return DynamicValue:new('dynamic', function (widget)
        return widget.parent[prop]*value/100
    end)
end

NOM.parent = {
    __index = function (self, prop)
        return DynamicValue:new('dynamic', function (widget)
            return widget.parent[prop]
        end)
    end
}

setmetatable(NOM.parent, NOM.parent)

function NOM.map(array, fn)
  local mapped_array = {}
  local count = 1

  for i, el in pairs(array) do
    push(mapped_array, fn(el, i, count))

    count = count+1
  end

  return unwrap(mapped_array)
end

function NOM.self(prop)
    return DynamicValue:new('dynamic', function (widget)
        return widget[prop]
    end)
end

function NOM.fn(fn)
    return DynamicValue:new('dynamic', fn)
end

function NOM.bottom_of(id)
    return DynamicValue:new('dynamic', function (widget)
        local element = widget.parent:find(id)

        if element then
            return element.y+element.h
        else
            terminal_print('bottom_of: could not find ', id)
        end
    end)
end

function NOM.left_of(id)
    return DynamicValue:new('dynamic', function (widget)
        local element = widget.parent:find(id)

        if element then
            return element.x
        else
            terminal_print('left_of: could not find ', id)
        end
    end)
end

NOM.top = NOM.parent.y
NOM.left = NOM.parent.x

NOM.right = NOM.left+NOM.parent.w
NOM.bottom = NOM.top+NOM.parent.h

NOM.width = NOM.parent.w
NOM.height = NOM.parent.h

-- static: Makes a document from a description
function NOM:make_document(desc, parent)
    local widget_desc = desc

    local widget = Widget:new(widget_desc, self, parent)

    for k, v in pairs(desc) do
        -- Only iterate over unamed properties
        -- we don't use ipairs to avoid stopping
        -- at nil
        if type(k) == "number" then
            local child = self:make_document(v, widget)

            -- Relationships
            push(widget.children, child)
        end
    end

    return widget
end

function NOM:new(desc)
    local instance = {
        features = {},
        cursor = {
            --offset = { x = -6, y = -8 },
            offset = { x = -1, y = 0 },
            default = {
                x = 48, y = 80,
                w = 8, h = 8
            },
            pointer = {
                x = 56, y = 80,
                w = 8, h = 8
            },
            state = 'default',
            dirty = true
        },
        mouse = { x = 0, y = 0 },
        event_queue = {},
        focused_widget = nil,
    }

    instanceof(instance, NOM)

    instance.root = instance:make_document(desc, {
        x = env.x, y = env.y,
        w = DEFAULT_W, h = DEFAULT_H,
    })

    return instance
end

function NOM:use(feature)
    self.features[feature] = true

    return self
end

function NOM:draw()
    self.root:draw()
    clip(env.x, env.y, env.width, env.height)

    if self.features.cursor then
        self:draw_cursor()
    end
end

function NOM:init()
    self:update(0)
    self.root:init()
end

function NOM:update(dt)
    self.root:update(dt)

    self:update_mouse()

    -- Fire all queued events
    self:do_fire()

    -- Update the cursor if needed
    if self.cursor.dirty then
        self.cursor.dirty = false

        local c = self.cursor[self.cursor.state]

        mouse_cursor(c.x, c.y, c.w, c.h, c.hx, c.hy)
    end

    -- Read keyboard events
    if self.focused_widget then
        local events = read_key_events()
        local input = read_keys()

        self:handle_keys(input, events)
    else
        self.focused_widget = self.root
    end
end

function NOM:find(selector, node)
    if selector:sub(1, 1) == '#' then
        local id = selector:sub(2, -1)

        if node then
            return node:find(id)
        else
            local found = self:find(selector, self.root)

            if not found then
                dprint('nom:', 'could not find', selector, '('..id..')')
            else
                return found
            end
        end
    end

    return nil
end

function NOM:draw_cursor()
    -- Deprecated in favor of native cursors

    -- local c = self.cursor[self.cursor.state]

    -- custom_sprite(self.mouse.x+self.cursor.offset.x, self.mouse.y+self.cursor.offset.y,
    --      c.x, c.y, c.w, c.h)
end

function NOM:set_cursor(state)
    self.cursor.state = state
    self.cursor.dirty = true
end

function NOM:update_mouse()
    local x, y = mouse_position()
    local drag = false

    if mouse_button_press(MOUSE_LEFT) or mouse_button_press(MOUSE_RIGHT) then
        self:click({ x = x, y = y }, true)
    end

    if mouse_button_down(MOUSE_LEFT) or mouse_button_down(MOUSE_RIGHT) then
        drag = true
    end

    if mouse_button_release(MOUSE_LEFT) or mouse_button_release(MOUSE_RIGHT) then
        self:click({ x = x, y = y })
    end

    if self.mouse.x ~= x or self.mouse.y ~= y then
        self:move({ x = x, y = y, drag = drag }, self.cursor.offset)
        self.mouse.x, self.mouse.y = x, y
    end
end

function NOM:fire(fn, priority)
    push(self.event_queue, {
             fn = fn,
             priority = priority
    })
end

function NOM:do_fire()
    sort(self.event_queue, function (a, b)
             return a.priority > b.priority
    end)

    local event

    repeat
        event = shift(self.event_queue)

        if event then
            event.fn()
        end
    until not event
end

function NOM:click(event, press)
    self.root:click(event, press)
end

function NOM:move(event, offset)
    self.root:move(event, offset)
end

function NOM:handle_keys(input, events)
    if #events > 0 then
        for _, evt in ipairs(events) do
            self.focused_widget:keyboard_event(evt)
        end
    end

    if #input > 0 then
        self.focused_widget:text_input(input)
    end
end

return NOM
