all_greevil_eggs = {}

---@class Greevil_Egg : Entity
---@field public native_item_proxy CDOTA_Item
---@field public native_container_proxy CDOTA_Item_Physical

---@return Greevil_Egg
function make_greevil_egg(at_position)
    local native_item_proxy = CreateItem( "item_greevil_egg", nil, nil )
    local native_container_proxy = CreateItemOnPositionSync(at_position, native_item_proxy)

    return make_greevil_egg_from_existing_item(native_item_proxy, native_container_proxy)
end

function make_greevil_egg_from_existing_item(native_item_proxy, native_container_proxy)
    local egg = make_entity(Entity_Type.GREEVIL_EGG, {
        native_item_proxy = native_item_proxy,
        native_container_proxy = native_container_proxy
    })

    native_item_proxy.attached_entity = egg

    return egg
end