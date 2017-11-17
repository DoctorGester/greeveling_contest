---@class Candy : Entity
---@field heal_amount heal_amount
---@field was_eaten boolean
---@field expires_at number
---@field native_container_proxy CDOTA_Item_Physical
---@field native_item_proxy CDOTA_Item

function make_candy(native_container_proxy, native_item_proxy, heal_amount)
    local entity = make_entity(Entity_Type.CANDY, {
        heal_amount = heal_amount,
        was_eaten = false,
        native_container_proxy = native_container_proxy,
        native_item_proxy = native_item_proxy,
        expires_at = GameRules:GetGameTime() + 15.0
    })

    native_item_proxy.attached_entity = entity

    return entity
end

---@param candy Candy
function update_candy(candy)
    if GameRules:GetGameTime() >= candy.expires_at then
        print("Kill the candy")
        candy.is_destroyed_next_update = true
    end
end

---@param candy Candy
function destroy_candy(candy)
    if not candy.was_eaten then
        candy.native_container_proxy:Destroy()
        candy.native_item_proxy:Destroy()
    end
end