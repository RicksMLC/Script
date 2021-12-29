// CX-4181-4-Orbit.ks
// Rick's Mid-Life Crisis
// Script for loading other scripts.

wait until ship:unpacked.
core:DoEvent("open terminal").
print "CX-4181-4-Orbit.ks running...".
set ksList to list("psLib", "CX-4181-4-OVT").
set runList to "".
local ext is "".
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


