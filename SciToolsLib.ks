// SciTools.ks Science library tools for collecting and transmitting science.

function GetSciModulesSilent {
	parameter sciName.
	local pList is ship:partsdubbed(sciName).
    local mList is List(false, List()).
	if plist:length = 0 {
        return mList.
    }
    set mList[0] to true.
    for p in pList {
        mList[1]:Add(p:GetModule("ModuleScienceExperiment")).
    }
    return mList.
}

function GetSciModules {
	parameter sciName.
	local mList is GetSciModulesSilent(sciName).
	if mList[0]  {
		print "SCIENCE: " + sciName + " detected x " + (mList[1]:Length).
	} else {
		set mList[1] to "SCIENCE Warning: No " + sciName + " detected".
		print mList[1].
	}
	return mList.
}

function SciValue {
	parameter sd.
    parameter isXmit.
	return sd:TITLE 
            + " worth " 
            + round(choose sd:TRANSMITVALUE if isXmit else sd:SCIENCEVALUE, 2) 
            + "(" + sd:DATAAMOUNT + "b)".
}

function DeployAndRetainSci {
    parameter sciModule.
    parameter xmitBeforeReset is true.
    parameter row is -1.
	print "SCIENCE: Deploy and Retain. " + sciModule:part:name.
    DeployAndTransmitSci(sciModule, false, false).
}

function DeployAndTransmitSci {
	parameter sciModule.
    parameter xmit is true.
    parameter xmitBeforeReset is true.
	parameter row is -1.

	print("SCIENCE: Collecting " + sciModule:part:name).
	if sciModule:HASDATA and not sciModule:RERUNNABLE { 
		print sciModule:part:name + " has data. No Rerun.".
		return.
	}
	if sciModule:HASDATA {
        if xmitBeforeReset {
            if sciModule:Data[0]:TRANSMITVALUE > 1 {
                print "Xmit old " + SciValue(sciModule:Data[0], true).
                sciModule:TRANSMIT.
            }
        }
		sciModule:DUMP.
        sciModule:RESET.
		wait 1.
	}
	sciModule:DEPLOY.
	// FIXME: Remove as this is blocking code, and the sci execFunc should not block.
	local n is 0.
	until sciModule:HASDATA {
		if row > -1 {
			PrintStatus(row, sciModule:part:name, "...":substring(0, n)).
			set n to mod(n + 1, 3).
		}
		wait 0.2.
	}
    if xmit {
	    if sciModule:Data[0]:TRANSMITVALUE > 1 {
		    print "Xmit "	+ SciValue(sciModule:Data[0], true).
		    sciModule:TRANSMIT.
	    } else {
		    print "Dumping " + SciValue(sciModule:Data[0], true).
	    }
        if not sciModule:INOPERABLE {
            sciModule:RESET.
        }
    } else {
        print "SCIENCE Retrieval:" + SciValue(sciModule:Data[0], false).
    }
}