-- do	--Version globals
-- 	if (C4.GetDriverConfigInfo) then
-- 		VERSION = C4:GetDriverConfigInfo ("version")
-- 	else
-- 		VERSION = 'Incompatible with this OS'
-- 	end
-- end

do	--Globals
	TEST_PROPERTY = TEST_PROPERTY or 'Hello World 2'

	Fountain = {}
	FOUNTAIN_PROXY = 5000
	PULSE = 500
	ON_RELAY = 1
	OFF_RELAY = 2
	ON_CONTACT = 3
	OFF_CONTACT = 4
	DEBUGPRINT = true
end

function dbg (strDebugText, ...)
	if (DEBUGPRINT) then 
		print (os.date ('%x %X : ') .. (strDebugText or ''), ...) 
	end
end

-- function dbgdump (strDebugText, ...)
-- 	if (DEBUGPRINT) then 
-- 		hexdump (strDebugText or '') 
-- 		print (...) 
-- 	end
-- end

function OnDriverDestroyed ()
	dbg('OnDriverDestroyed called')
	C4:DestroyServer ()
end

function OnPropertyChanged (strProperty)
	dbg('OnPropertyChanged')
	local value = Properties[strProperty]
	dbg('OnPropertyChanged called with Property: ' .. strProperty .. ' value: ' .. value)

	if (value == nil) then
		dbg ('OnPropertyChanged, nil value for Property: ' .. strProperty)
		return
	end

	if (strProperty == 'TestProperty') then
		if (value == 'Off') then
			DEBUGPRINT = false
		elseif (value == 'On') then
			DEBUGPRINT = true
		end
		dbg('TestProperty set to ' .. value)
	end
end

-- -- function Helper.DriverInfo (info)
-- -- 	C4:UpdateProperty ('Driver Information', info)
-- -- 	print (os.date ('%x %X : ') .. info)
-- -- end

-- -- When the timer expires, open both relays
-- function OnTimerExpired (idTimer)
-- 	dbg('timer ' .. idTimer .. 'expired')
-- 	C4:SendToProxy (ON_RELAY, "OPEN", '')
-- 	C4:SendToProxy (OFF_RELAY, "OPEN", '')
-- end

function ReceivedFromProxy (idBinding, strCommand, tParams)
	dbg (idBinding .. ' command: ' .. strCommand)

	-- If it came from the fountain proxy we expect either ON or OFF
	if (idBinding == FOUNTAIN_PROXY) then
		if (strCommand == "UP") then
			Fountain.OnCommand()
		elseif (strCommand == "DOWN") then
			Fountain.OffCommand()
		end
	end

	if (idBinding == ON_CONTACT) then
		if (strCommand == "CLOSED") then
			dbg('Foutain is ON')
			C4:SendToProxy (FOUNTAIN_PROXY, 'UP', {LEVEL = 1}, "NOTIFY", true)
		elseif (strCommand == "OPENED") then
			dbg('Fountain is turning OFF')
		end
	end

	if (idBinding == OFF_CONTACT) then
		if (strCommand == "CLOSED") then
			dbg('Foutain is OFF')
			C4:SendToProxy (FOUNTAIN_PROXY, 'DOWN', {LEVEL = 1}, "NOTIFY", true)
		elseif (strCommand == "OPENED") then
			dbg('Fountain is turning ON')
		end
	end
end

-- function Fountain.SetRelayType ()
-- 	C4:SetPropertyAttribs('Pulse Time (milliseconds)', 0)
-- 	C4:SetPropertyAttribs('Stop Method', 0)
-- 	C4:SetPropertyAttribs('Fail Safe (Seconds)', 0)
-- end

function Fountain.OnCommand ()
	dbg ('Turning on fountain')
	C4:SendToProxy (ON_RELAY, "CLOSE", '')
	C4:SendToProxy (OFF_RELAY, "OPEN", '')
	-- C4:AddTimer (PULSE, 'MILLISECONDS', false)
end

function Fountain.OffCommand ()
	dbg ('Turning off fountain')
	C4:SendToProxy (ON_RELAY, "OPEN", '')
	C4:SendToProxy (OFF_RELAY, "CLOSE", '')
	-- C4:AddTimer (PULSE, 'MILLISECONDS', false)
end
