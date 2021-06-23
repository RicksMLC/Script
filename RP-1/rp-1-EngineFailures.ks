// rp-1-EngineFailures.ks library.

function CheckForEngineFailures {
    parameter engines.
    local isShutdown is false.
    for e in engines {
        // Detect if engine loses performance or shuts down.
        if e:thrust < e:maxthrust * 0.9 or e:thrust = 0 {
            print "Engine " + e:name + " '" + e:tag 
                + "' shutdown detected."
                + " thrust:" + round(e:thrust, 4) + " maxthrust:" + round(e:maxthrust, 4).
            for e in engines {
                print "   Shutting down "+ e:name + " '" + e:tag + "'".
                e:shutdown.
            }
            set isShutdown to true.
            break.
        }
    }
    return isShutdown.
}

function RunMultiEngineStage {
    parameter engineSpoolUpTime is 1.
    parameter verbose is false.

    wait engineSpoolUpTime.
    
    // TODO: parameterise to allow more than two groups.
    declare eAs to ship:partstaggedpattern("^S2-Ea").
    if verbose {
        print eAs.
    }
    declare eBs to ship:partstaggedpattern("^S2-Eb").
    if verbose {
        print eBs.
    }

    local isShutdownA is false.
    local isShutdownB is false.
    until isShutdownA and isShutdownB {
        local n is 1.
        for e in eAs {
            if verbose {
                PrintPairStatus(n, 
                    "Engine", e:tag, 
                    "Thrust", round(e:thrust, 4):tostring :padright(6) + " m: " + round(e:maxthrust, 4):tostring:padright(6)).
                set n to n + 1.                    
            }

        }
        set n to 3.
        for e in eBs {
            if verbose {
                PrintPairStatus(n, 
                    "Engine", e:tag, 
                    "Thrust", round(e:thrust, 4):tostring:padright(6) + " m: " + round(e:maxthrust, 4):tostring:padright(6)).
                set n to n + 1.
            }
        }

        set isShutdownA to CheckForEngineFailures(eAs).
        if isShutdownA {
            print "Engine Group A is shut down.".
            eAs:Clear().
        }
        set isShutdownB to CheckForEngineFailures(eBs).
        if isShutdownB {
            print "Engine Group B is shut down.".
            eBs:Clear().
        }
        wait 0.001.
    }
}
