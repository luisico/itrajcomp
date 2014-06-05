#****h* itrajcomp/standard
# NAME
# standard
#
# DESCRIPTION
# Standard calculation types.
#****

#****f* standard/AddStandardCalc
# NAME
# AddStandardCalc
# SYNOPSIS
# itrajcomp::AddStandardCalc
# FUNCTION
# Standard calculation types for the vanilla itrajcomp plugin.
# SOURCE
proc itrajcomp::AddStandardCalc {} {
  # TODO: what is this doing here? setting a default?
  variable calctype "rmsd"
  global env

  # Frames mode
  set mode frames
  foreach type {rmsd rgyr contacts hbonds labels} desc {"Root mean square deviation" "Radius of gyrantion difference" "Number of contacts" "Number of hydrogen bonds" "VMD labels: distance, angles, dihedrals"} {
    [namespace current]::AddCalc $type $mode $desc [file join $env(ITRAJCOMPDIR) $type.tcl]
  }

  # Segments mode
  set mode segments
  foreach type {dist covar} desc {"Distance" "Covariance"} {
    [namespace current]::AddCalc $type $mode $desc [file join $env(ITRAJCOMPDIR) $type.tcl]
  }
}
#*****
