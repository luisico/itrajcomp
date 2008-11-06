#****h* itrajcomp/standard
# NAME
# standard -- Standard calculation types
#
# AUTHOR
# Luis Gracia
#
# DESCRIPTION
#
# Standard calculation types.
# 
# SEE ALSO
# More documentation can be found in:
# * README.txt
# * itrajcomp.tcl
# * http://physiology.med.cornell.edu/faculty/hweinstein/vmdplugins/itrajcomp
#
# COPYRIGHT
# Copyright (C) 2005-2008 by Luis Gracia <lug2002@med.cornell.edu> 
#
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
  variable calctype "rmsd"
  global env

  # Type frames
  foreach type {rmsd rgyr contacts hbonds labels} desc {"Root mean square deviation" "Radius of gyrantion difference" "Number of contacts" "Number of hydrogen bonds" "VMD labels: distance, angles, dihedrals"} {
    [namespace current]::AddCalc $type $desc [file join $env(ITRAJCOMPDIR) $type.tcl]
  }

  # Type segments
  foreach type {dist covar} desc {"Distance" "Covariance"} {
    [namespace current]::AddCalc $type $desc [file join $env(ITRAJCOMPDIR) $type.tcl]
  }
}
#*****
