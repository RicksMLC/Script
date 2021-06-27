// CX-4181-2-FVT.ks
// Flight Verification Test.

wait until ship:unpacked.
clearscreen.

print "CX-4181-2-FVT.ks".

print "Counting down:".
from {local countdown is 10.} until countdown = 0 step {set countdown to countdown -1.} do {
    print "..." + countdown.
    wait 1.
}

// This is a trigger that constantly checks to see if our thrust is zero.
// If it is, it will attempt to stange and then return to where the script
// left off.  The PRESERVE keyword keeps the trigger active even after it
// has been triggered.
when MAXTHRUST = 0 then {
	print "Staging".
	stage.
	if (stage:NUMBER > 0) {
		PRESERVE.
	}
}

wait until SHIP:ALTITUDE > 1000.
wait until ship:altitude < 1000.

// Verify script is complete with a Part Test contract
set pList to ship:partsdubbed("kOSMachine1m").
set testPart to pList[0].
set testModule to testPart:GETMODULE("ModuleTestSubject").
//print testModule.
testModule:DOEVENT("run test").

print "DoEvent 'run test' executed.".

