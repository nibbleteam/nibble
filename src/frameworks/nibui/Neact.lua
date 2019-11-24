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
        if children[k] and children[k][1].props.key == props.key and component == children[k][1]._component then
            if Neact.props_differ(children[k][1].props, props) then
                if children[k][1].on_receive_props then
                    children[k][1]:on_receive_props(props)
                end

                children[k][1].props = props
            end

            instances = children[k]
        else
            local instance = component:new(props)

            instance._component = component
            instance._id = component_id

            if props.ref then
                props.ref(instance)
            end

            if instance.on_receive_props then
                instance:on_receive_props(props)
            end

            children[k] = {instance, {}}

            return instance
        end
    end

    return instances[1]
end
