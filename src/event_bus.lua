-- event_bus.lua
-- Simple pub/sub event system to decouple entities from global systems

local EventBus = {
    listeners = {},
}

function EventBus:on(event, callback, priority)
    if not self.listeners[event] then
        self.listeners[event] = {}
    end
    local handle = {
        event = event,
        callback = callback,
        priority = priority or 0,
    }
    table.insert(self.listeners[event], handle)
    table.sort(self.listeners[event], function(a, b)
        return a.priority > b.priority
    end)
    return handle
end

function EventBus:off(handle)
    if not handle or not handle.event then return end
    local listeners = self.listeners[handle.event]
    if not listeners then return end
    for i = #listeners, 1, -1 do
        if listeners[i] == handle then
            table.remove(listeners, i)
            return
        end
    end
end

function EventBus:emit(event, data)
    local listeners = self.listeners[event]
    if not listeners then return end
    for _, handle in ipairs(listeners) do
        handle.callback(data)
    end
end

function EventBus:reset()
    self.listeners = {}
end

return EventBus
