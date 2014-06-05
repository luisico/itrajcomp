#****h* itrajcomp/hacks
# NAME
# hacks
#
# DESCRIPTION
# Test for VMD hacks
#****

#****f* hacks/test_hacks
# NAME
# test_hacks
#
# FUNCTION
# Tests all hacks
#
# SOURCE
proc itrajcomp::test_hacks {} {
  variable hacks
  [namespace current]::hack_fast_rmsd
}
#*****

#****f* hacks/hack_fast_rmsd
# NAME
# hack_fast_rmsd
# FUNCTION
# Tests if the fast_rmsd hack is present in vmd
# SOURCE
proc itrajcomp::hack_fast_rmsd {} {
  variable hacks

  if {![info exists hacks(fast_rmsd)]} {
    set hacks(fast_rmsd) 1
    if [catch { set test [measure rmsd [atomselect top "index 1"] [atomselect top "index 1"] byatom] } msg] {
      set hacks(fast_rmsd) 0
    }
  }
}
#*****
