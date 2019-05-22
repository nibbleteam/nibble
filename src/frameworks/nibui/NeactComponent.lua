local NOM = require 'nibui.NOM'

local NeactComponent = {
    is_neact_component = true,
}

function NeactComponent:new()
    return new(NeactComponent, { state = {}, props = {}})
end

function NeactComponent:set_state(state)
    self.state = state

    local nom = NOM:new(self._root:_render_to_description(self._root, {}))

    self._root._nom.root = nom.root;
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

        return self:_render_table_to_description(root, id, description)
    end

    return {}
end

function NeactComponent:nom()
    local nom = NOM:new(self:_render_to_description(self, {}))

    self._nom = nom

    return nom
end

function NeactComponent:_is_neact_element(e)
    return e and type(e) == 'table' and e[1] and type(e[1]) == 'table' and e[1].is_neact_component
end

return NeactComponent
