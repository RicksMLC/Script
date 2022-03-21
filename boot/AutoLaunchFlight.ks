// AutoLaunchFlight.ks

wait until ship:unpacked.
core:DoEvent("open terminal").

print "AutoLaunchFlight.ks running...".

local ksList is list("psLib", "LaunchLib", "FlightLib", "OrbitLib", "LaunchFlightCtrl").
local reloadLibs is true.
if not HOMECONNECTION:ISCONNECTED {
    print "No comms connection available. Unable to load libraries".
}
for ks in ksList {
    deletepath(ks + ".ks").
    deletepath(ks + ".ksm").
    if exists("0:/" + ks + ".ksm") {
        copypath("0:/" + ks + ".ksm", "").
        set ext to ".ksm".
    } else {
        copypath("0:/" + ks + ".ks", "").
        set ext to ".ks".
    }
    print "Running: " + ks + ext.
    runoncepath(ks).
}

print "Program End.".