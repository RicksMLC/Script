// AutoKomms.ks

wait until ship:unpacked.
core:DoEvent("open terminal").

print "AutoKomms.ks running...".

local ksList is list("psLib", "FlightLib", "LaunchLib", "OrbitLib", "KerbalKomms01").
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

print "Purging AutoKomms Scripts.".
for ks in ksList {
    if VOLUME(1):Exists(ks) {
        print " x  " + "1:/" + ks + ".ks".
        deletepath("1:/" + ks + ".ks").
    }
}
print " x  1:/boot/AutoKomms.ks".
deletepath("1:/boot/AutoKomms.ks").

print "Program Terminated.".