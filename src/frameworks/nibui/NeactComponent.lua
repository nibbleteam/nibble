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

function NeactComponent:new()
  return new(NeactComponent, { state = {}, props = {}})
end

function NeactComponent:set_state(state, time, easing)
  for k, v in pairs(state) do
    self.state[k] = v
  end

  local desc = self:_render_to_description(self._root, self._id or {})

  desc.neact_generated_by = nil

  local widget = self._root._nom:make_document(desc, self._widget.parent)

  for k, v in pairs(widget.props) do
    if self._widget.props[k].isdynamicvalue and
       self._widget.props[k].kind == "interpolated" then
      self._widget[k] = { widget[k], time, easing }
    else
      self._widget.props[k] = widget.props[k]
    end
  end

  local children = widget.children

  for i, child in ipairs(children) do
    child.parent = self._widget
    self._widget.children[i] = child
  end

  self._widget.children[#children+1] = nil

  self._widget:set_dirty()
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
