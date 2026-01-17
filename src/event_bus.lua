-- event_bus.lua
-- Simple pub/sub event system to decouple entities from global systems

local EventBus = {
    listeners = {},
    -- Event queue for deferred events (processed at end of frame)
    deferredQueue = {},
}

-- Register a callback for an event
-- Returns a handle that can be used to unsubscribe
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
    -- Sort by priority (higher priority = called first)
    table.sort(self.listeners[event], function(a, b)
        return a.priority > b.priority
    end)
    return handle
end

-- Unsubscribe a specific listener
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

-- Emit an event immediately to all listeners
-- Returns collected results from handlers (useful for aggregating data)
function EventBus:emit(event, data)
    local listeners = self.listeners[event]
    if not listeners then return {} end

    local results = {}
    for _, handle in ipairs(listeners) do
        local result = handle.callback(data)
        if result ~= nil then
            table.insert(results, result)
        end
    end
    return results
end

-- Queue an event to be processed later (end of frame)
function EventBus:defer(event, data)
    table.insert(self.deferredQueue, {event = event, data = data})
end

-- Process all deferred events
function EventBus:processDeferredEvents()
    local queue = self.deferredQueue
    self.deferredQueue = {}
    for _, item in ipairs(queue) do
        self:emit(item.event, item.data)
    end
end

-- Clear all listeners for a specific event
function EventBus:clearEvent(event)
    self.listeners[event] = nil
end

-- Reset the entire event bus (call between runs)
function EventBus:reset()
    self.listeners = {}
    self.deferredQueue = {}
end

-- Debug: Get count of listeners for an event
function EventBus:getListenerCount(event)
    if not self.listeners[event] then return 0 end
    return #self.listeners[event]
end

return EventBus
