// FirstUnboxing.ks
// Remove the shrink-wrap and run the self-test on the launch pad.
// This is co-ordinated with the Contract Configurator kOS CX-4181 Self-Test contract.
// CMD: 
//   run "0:/FirstUnboxing.ks".
wait until ship:unpacked.

clearscreen.
print "FirstUnboxing.ks: Test the kOS cardboard box contains a machine.".

// Get the part:
set pList to ship:partsdubbed("kOSMachine1m").
set testPart to pList[0].
set testModule to testPart:GETMODULE("ModuleTestSubject").

print "Test part: " + testPart:Name + " Test module details:".
print testModule.

// Verify the self test works:
testModule:DOEVENT("run test").

print "DoEvent 'run test' complete.".
