local NOM = require 'nibui.NOM'
local Widget = require 'nibui.Widget'

local NeactComponent = {
  is_neact_component = true,
}

local function update_parent_refs(widget, parent)
  widget.parent = parent

  for _, child in ipairs(widget.children or {}) do
    update_parent_refs(child, parent)
  end

  return widget
end

local function update_widget(widget, new_widget, time, easing)
  -- Calculates the new widget hash from its properties
  new_widget:update_hash()

  -- Always update functions since no state is kept in them
  -- FIXME: someone may dynamically update functions?
  for k, v in pairs(new_widget) do
    if type(v) == "function" then
      widget[k] = new_widget[k]
    end
  end

  for k, v in pairs(new_widget.props) do
    if type(v) == "function" then
      widget.props[k] = new_widget.props[k]
    end
  end

  -- Only update if something has changed
  if widget.hash ~= new_widget.hash then
    -- Update the current widget props with the new widget props
    -- without destroying the current widget
    for k, v in pairs(new_widget.props) do
      if widget.props[k].isdynamicvalue and
        widget.props[k].kind == "interpolated" then
        widget[k] = { new_widget[k], time, easing }

        -- Avoid flickering
        widget.props[k].cache = nil
      else
        widget.props[k] = new_widget.props[k]
      end
    end

    widget:set_dirty()
  end

  local children = new_widget.children

  for i, child in ipairs(children) do
    if widget.children[i] then
      update_widget(widget.children[i], child, time, easing)
    else
      child.parent = widget
      widget.children[i] = child
    end
  end

  widget.children[#children+1] = nil
end

function NeactComponent:new()
  return new(NeactComponent, { state = {}, props = {}})
end

function NeactComponent:set_state(state, time, easing)
  for k, v in pairs(state) do
    self.state[k] = v
  end

  -- Render a new NOM description
  local desc = self:_render_to_description(self._root, self._id or {})

  desc.neact_generated_by = nil

  -- Build a new NOM widget from the scription,
  -- with the same parent as the previous widget
  local widget = self._root._nom:make_document(desc, self._widget.parent)

  -- Update the current widget with the new one
  update_widget(self._widget, widget, time, easing)
end

function NeactComponent:_render_table_to_description(root, id, description)
  local plain_description = {}

  -- Iterate over the children
  for k, element in pairs(description) do
    if self:_is_neact_element(element) then
      component = element[1]

      local instance_id = concat(id, { element.id or component })

      local instance = Neact.component_to_instance(instance_id, component, element)

      plain_description[k] = instance:_render_to_description(root, instance_id)
    elseif type(element) == 'table' and type(k) == 'number' then
      plain_description[k] = self:_render_table_to_description(root, id, element)
    else
      plain_description[k] = element
    end
  end

  return plain_description
end

function NeactComponent:_render_to_description(root, id)
  self._root = root

  if self.render then
    local description = self:render(self.state, self.props)

    description.neact_generated_by = self

    return self:_render_table_to_description(root, id, description)
  end

  return {}
end

function NeactComponent:nom()
  local desc = self:_render_to_description(self, {})

  local nom = NOM:new(desc)

  self._nom = nom

  return nom
end

function NeactComponent:_is_neact_element(e)
  return e and type(e) == 'table' and e[1] and type(e[1]) == 'table' and e[1].is_neact_component
end

return NeactComponent
