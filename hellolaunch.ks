// hellolaunch
// kOS tutorial number 1.
// Attempt auto launch.

wait until ship:unpacked.
clearscreen.

lock throttle to 1.0. // 1.0 is the max, 0.0 is idle.

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
	if (stage:NUMBER > 1) {
		PRESERVE.
	}
}

wait until SHIP:ALTITUDE > 1000.

// Verify script is complete with a Part Test contract
// https://github.com/jrossignol/ContractConfigurator/wiki/PartTest-Parameter

// Get the part:
set pList to ship:partsdubbed("kOSMachine1m").
set testPart to pList[0].
set testModule to testPart:GETMODULE("ModuleTestSubject").

print "Test part: " + testPart:Name + " Test module details:".
print testModule.

// Verify the self test works:
testModule:DOEVENT("run test").

