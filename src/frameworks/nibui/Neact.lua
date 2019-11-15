Neact = {
    -- Stores class instances during the
    -- entire lifetime of the app
    instances_tree = {nil, {}}
}

Neact.Component = require 'nibui.NeactComponent'

function Neact.props_differ(a, b)
    for k, v in zip(a, b) do
        if a[k] ~= b[k] then
            return true
        end
    end

    return false
end

function Neact.component_to_instance(component_id, component, props)
    local instances = Neact.instances_tree

    for _, k in ipairs(component_id) do
        local children = instances[2]

        -- TODO: remove numeric keys
        if children[k] and not Neact.props_differ(children[k][1].props, props) then
            instances = children[k]
        else
            local instance = component:new(props)

            instance._id = component_id

            if props.ref then
                props.ref(instance)
            end

            children[k] = {instance, {}}

            return instance
        end
    end

    return instances[1]
end
