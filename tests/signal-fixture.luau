local Creator = { Signals = {} }
-- PRODUCTION

local function connection(connected)
	return { Connected = connected }
end

local liveA = connection(true)
local dead = connection(false)
local liveB = connection(true)
Creator.Signals = { liveA, nil, dead, liveB }
Creator.CompactSignals()
assert(#Creator.Signals == 2, "disconnected and missing connections are removed")
assert(Creator.Signals[1] == liveA and Creator.Signals[2] == liveB, "live order is preserved")

Creator.Signals = { connection(true), connection(true), connection(true) }
Creator.CompactSignals()
assert(#Creator.Signals == 3, "a scan with no dead connection keeps every listener")

local removed = connection(true)
Creator.Signals = { removed, connection(true) }
removed.Connected = false
Creator.CompactSignals()
assert(#Creator.Signals == 1 and Creator.Signals[1].Connected, "a connection that dies before the scan is dropped")
print("Signals: compaction keeps live listeners and drops the rest")
