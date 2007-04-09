#
#         iTrajComp v1.0
#
# interactive Trajectory Comparison
#
# http://physiology.med.cornell.edu/faculty/hweinstein/vmdplugins/itrajcomp

# Author
# ------
#      Luis Gracia, PhD
#      Department of Physiology & Biophysics
#      Weill Medical College of Cornell University
#      1300 York Avenue, Box 75
#      New York, NY 10021
#      lug2002@med.cornell.edu

# Description
# -----------
# 

# Documentation
# ------------
#      The documentation can be found in the README.txt file and
#      http://physiology.med.cornell.edu/faculty/hweinstein/vmdplugins/itrajcomp

# user.tcl
#    User calculation types.


proc itrajcomp::calc_standard {} {
  # Standard calculation types for the vanilla itrajcomp plugin.
  variable calctype "covar"
  global env
  foreach type {rmsd covar dist contacts hbonds labels} desc {"Root mean square deviation" "Covariance" "Distance" "Number of contacts" "Number of hydrogen bonds" "VMD labels: distance, angles, dihedrals"} {
    [namespace current]::AddCalc $type $desc [file join $env(ITRAJCOMPDIR) $type.tcl]
  }
}

# Source files containing the calculation code
# TODO: add this via the AddCalc proc 
#source [file join $env(ITRAJCOMPDIR) rmsd.tcl]
#source [file join $env(ITRAJCOMPDIR) contacts.tcl]
#source [file join $env(ITRAJCOMPDIR) hbonds.tcl]
#source [file join $env(ITRAJCOMPDIR) labels.tcl]
#source [file join $env(ITRAJCOMPDIR) covar.tcl]
#source [file join $env(ITRAJCOMPDIR) dist.tcl]
