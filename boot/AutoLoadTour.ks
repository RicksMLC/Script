// AutoLoadTour.ks

wait until ship:unpacked.
core:DoEvent("open terminal").

print "AutoTourLoad.ks running...".

local ksList is list("psLib", "FlightLib", "OrbitLib", "AutoTour03").
local reloadLibs is true.
if not HOMECONNECTION:ISCONNECTED {
    print "No comms connection available. Running with existing libraries.".
    set reloadLibs to false.
}

for ks in ksList {
    if reloadLibs {
        deletepath(ks + ".ks").
        copypath("0:/" + ks + ".ks", "").
    }
    if VOLUME(1):Exists(ks) {
        print "Running: " + ks.
        runoncepath(ks).
    } else {
        print "Script ' " + ks + "' not found - skipping.".
    }
}
print "Program Terminated.".