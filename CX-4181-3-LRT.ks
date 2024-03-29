// CX-4181-3-LRT.ks
// Launch and Recover Test.
// Tip: Add a parachute for the script to stage.

wait until ship:unpacked.
clearscreen.

lock throttle to 1.0. // 1.0 is the max, 0.0 is idle.
print "CX-4181-4-LRT.ks".
print "Launch and Recover Test:".
print " 1) Launch > 1,200m".
print " 2) Wait until < 1,200m".
print " 3) Stage to deploy chute".
print " 4) DOEVENT(Run Test) to complete the test".

print "Counting down:".
from {local countdown is 10.} until countdown = 0 step {set countdown to countdown -1.} do {
    print "..." + countdown.
    wait 1.
}

// This is a trigger that constantly checks to see if our thrust is zero.
// If it is, it will attempt to stage and then return to where the script
// left off.  The PRESERVE keyword keeps the trigger active even after it
// has been triggered.
when MAXTHRUST = 0 then {
	print "Staging".
	stage.
	if (stage:NUMBER > 1) {
		PRESERVE.
	}
	wait 0.001.
}

wait until ship:altitude > 1200.

wait until ship:altitude < 1200.
// This is the cheapest way... without checking for parachutes etc.
stage.

// Verify script is complete with a Part Test contract
set pList to ship:partsdubbed("kOSMachine1m").
set testPart to pList[0].
set testModule to testPart:GETMODULE("ModuleTestSubject").
//print testModule.
testModule:DOEVENT("run test").

print "DoEvent 'run test' executed.".

