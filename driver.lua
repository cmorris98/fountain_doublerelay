-- do	--Version globals
-- 	if (C4.GetDriverConfigInfo) then
-- 		VERSION = C4:GetDriverConfigInfo ("version")
-- 	else
-- 		VERSION = 'Incompatible with this OS'
-- 	end
-- end

do	--Globals
	Fountain = {}
	Timer = {}
	FOUNTAIN_PROXY = 5000
	PULSE_ON = PULSE_ON or 500
	PULSE_OFF = PULSE_OFF or 500
	HOLD_OR_PULSE_ON_RELAY = HOLD_OR_PULSE_ON_RELAY or 'Pulse'
	HOLD_OR_PULSE_OFF_RELAY = HOLD_OR_PULSE_OFF_RELAY or 'Pulse'
	ON_RELAY = 1
	OFF_RELAY = 2
	ON_CONTACT = 3
	OFF_CONTACT = 4
	DEBUG_PRINT = DEBUG_PRINT or false
end

function dbg (strDebugText, ...)
	if (DEBUG_PRINT) then 
		print (os.date ('%x %X : ') .. (strDebugText or ''), ...) 
	end
end

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

	if (strProperty == 'Debug Print') then
		if (value == 'Off') then
			dbg('Turning off debug print')
			DEBUG_PRINT = false
		elseif (value == 'On') then
			DEBUG_PRINT = true
			dbg('Turning on debug print')
		end
	elseif (strProperty == 'Pulse Time On (milliseconds)') then
		PULSE_ON = tonumber(value)
		dbg('PULSE_ON set to ' .. PULSE_ON)
	elseif (strProperty == 'Pulse Time Off (milliseconds)') then
		PULSE_OFF = tonumber(value)
		dbg('PULSE_OFF set to ' .. PULSE_OFF)
	elseif (strProperty == 'Hold or Pulse On') then
		HOLD_OR_PULSE_ON_RELAY = value
		dbg('HOLD_OR_PULSE_ON_RELAY set to ' .. HOLD_OR_PULSE_ON_RELAY)
	elseif (strProperty == 'Hold or Pulse Off') then
		HOLD_OR_PULSE_OFF_RELAY = value
		dbg('HOLD_OR_PULSE_OFF_RELAY set to ' .. HOLD_OR_PULSE_OFF_RELAY)
	end
end

-- -- function Helper.DriverInfo (info)
-- -- 	C4:UpdateProperty ('Driver Information', info)
-- -- 	print (os.date ('%x %X : ') .. info)
-- -- end

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
		if (strCommand == "CLOSED" or strCommand == "STATE_ClOSED") then
			dbg('Foutain is ON')
			C4:SendToProxy (FOUNTAIN_PROXY, 'UP', {LEVEL = 1}, "NOTIFY", true)
		elseif (strCommand == "OPENED" or strCommand == "STATE_OPENED") then
			dbg('Fountain is turning OFF')
		end
	end

	if (idBinding == OFF_CONTACT) then
		if (strCommand == "CLOSED" or strCommand == "STATE_ClOSED") then
			dbg('Foutain is OFF')
			C4:SendToProxy (FOUNTAIN_PROXY, 'DOWN', {LEVEL = 1}, "NOTIFY", true)
		elseif (strCommand == "OPENED" or strCommand == "STATE_OPENED") then
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
	if (HOLD_OR_PULSE_ON_RELAY == 'Pulse') then
		Timer.PulseOn = C4:AddTimer (PULSE_ON, 'MILLISECONDS', false)
	end
end

function Fountain.OffCommand ()
	dbg ('Turning off fountain')
	C4:SendToProxy (ON_RELAY, "OPEN", '')
	C4:SendToProxy (OFF_RELAY, "CLOSE", '')
	if (HOLD_OR_PULSE_OFF_RELAY == 'Pulse') then
		Timer.PulseOff = C4:AddTimer (PULSE_OFF, 'MILLISECONDS', false)
	end
end

-- When the timer expires, open appropriate relay
function OnTimerExpired (idTimer)
	dbg('timer ' .. idTimer .. ' expired')

	if (idTimer == Timer.PulseOn) then
		C4:SendToProxy (ON_RELAY, "OPEN", '')
	elseif (idTimer == Timer.PulseOff) then
		C4:SendToProxy (OFF_RELAY, "OPEN", '')
	end
end
