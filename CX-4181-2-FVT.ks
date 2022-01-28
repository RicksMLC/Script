// CX-4181-2-FVT.ks
// Flight Verification Test.
// Example Craft is an Stayputnik with a structure, SRB RT-5 "Flea" and launch clamps.
// Tip: Angle the ship for launch.

wait until ship:unpacked.

print "CX-4181-2-FVT.ks".
print "Flight Verification Test:".
print "  1) Launch to > 1,000m".
print "  2) Wait until < 1,000m".
print "  2) Run the test:".
print "  Part: kOSMachine1m | Module: ModuleTestSubject | DOEVENT(run test)".

print "Counting down:".
from {local countdown is 10.} until countdown = 0 step {set countdown to countdown -1.} do {
    print "..." + countdown.
    wait 1.
}

// This is a trigger that constantly checks to see if our thrust is zero.
// If it is, it will attempt to stage and then return to where the script
// left off.  The PRESERVE keyword keeps the trigger active after it has been triggered.
when MAXTHRUST = 0 then {
	print "Staging".
	stage.
	if (stage:NUMBER > 0) {
		PRESERVE.
	}
	wait 0.001.
}

wait until SHIP:ALTITUDE > 1000.
wait until ship:altitude < 1000.

// Part Test:
// Verify script is complete with a Part Test contract
set pList to ship:partsdubbed("kOSMachine1m").
set testPart to pList[0].
set testModule to testPart:GETMODULE("ModuleTestSubject").
//print testModule.
testModule:DOEVENT("run test").

print "DoEvent 'run test' executed.".

