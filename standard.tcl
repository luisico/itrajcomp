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

# standard.tcl
#    Standard calculation types.


proc itrajcomp::AddStandardCalc {} {
  # Standard calculation types for the vanilla itrajcomp plugin.
  variable calctype "rmsd"
  global env

  foreach type {rmsd contacts hbonds labels} desc {"Root mean square deviation" "Number of contacts" "Number of hydrogen bonds" "VMD labels: distance, angles, dihedrals"} {
    [namespace current]::AddCalc $type $desc [file join $env(ITRAJCOMPDIR) $type.tcl]
  }

#  foreach type {dist covar} desc {"Distance" "Covariance"} {
#    [namespace current]::AddCalc $type $desc [file join $env(ITRAJCOMPDIR) $type.tcl]
#  }
  [namespace current]::AddCalc dist "Distance" [file join $env(ITRAJCOMPDIR) dist.tcl]

}
