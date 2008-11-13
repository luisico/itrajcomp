#****h* itrajcomp/dist
# NAME
# dist -- Functions to calculate the distance matrix
#
# AUTHOR
# Luis Gracia
#
# DESCRIPTION
#
# Functions to calculate the distance matrix.
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

#****f* dist/calc_dist
# NAME
# calc_dist
# SYNOPSIS
# itrajcomp::calc_dist self
# FUNCTION
# This functions gets called when adding a new type of calculation.
# Dist calculation type
# PARAMETERS
# * self -- object
# RETURN VALUE
# Status code
# SOURCE
proc itrajcomp::calc_dist {self} {
  # Check number of atoms in selections, and combined list of molecules
  if {[[namespace current]::CheckNatoms $self] == -1} {
    return -code error
  }

  # Define segments
  [namespace current]::DefineSegments $self

  # Precalculate coordinates of each segment
  [namespace current]::CoorSegments $self

  # Calculate distance matrix
  return [[namespace current]::LoopSegments $self]
}
#*****

#****f* dist/calc_dist_prehook1
# NAME
# calc_dist_prehook1
# SYNOPSIS
# itrajcomp::calc_dist_prehook1 self
# FUNCTION
# This functions gets called each time the first segment in the pair changes
# PARAMETERS
# * self -- object
# SOURCE
proc itrajcomp::calc_dist_prehook1 {self} {
}
#*****

#****f* dist/calc_dist_prehook2
# NAME
# calc_dist_prehook2
# SYNOPSIS
# itrajcomp::calc_dist_prehook2 self
# FUNCTION
# This functions gets called each time the second segment in the pair changes.
# PARAMETERS
# * self -- object
# SOURCE
proc itrajcomp::calc_dist_prehook2 {self} {
}
#*****

#****f* dist/calc_dist_hook
# NAME
# calc_dist_hook
# SYNOPSIS
# itrajcomp::calc_dist_hook self
# FUNCTION
# This function gets called for each pair.
# Calculte the distance
# PARAMETERS
# * self -- object
# RETURN VALUE
# Distance
# SOURCE
proc itrajcomp::calc_dist_hook {self} {
  set dist {}
  set mol_all [set ${self}::sets(mol_all)]
  set frame1  [set ${self}::sets(frame1)]
  set reg1 [set ${self}::reg1]
  set reg2 [set ${self}::reg2]
  array set coor [array get ${self}::coor]
  foreach m $mol_all {
    foreach f [lindex $frame1 [lsearch -exact $mol_all $m]] {
      lappend dist [veclength [vecsub [lindex $coor($m:$f) $reg2] [lindex $coor($m:$f) $reg1]]]
    }
  }
  return $dist
}
#*****

#****f* dist/calc_dist_options
# NAME
# calc_dist_options
# SYNOPSIS
# itrajcomp::calc_dist_options
# FUNCTION
# This functions gets called when adding a new type of calculation. It sets up the GUI and other options.
# SOURCE
proc itrajcomp::calc_dist_options {} {
  # Options
  variable calc_dist_opts
  array set calc_dist_opts {
    type         segments
    mode         multiple
    formats      f
    rep_style1   CPK
  }

  # GUI options
  variable calc_dist_gui
  variable calc_dist_guiopts
  array set calc_dist_guiopts {
    segment           byatom
    force_samemols    1
  }

  # by segment
  frame $calc_dist_gui.segment
  pack $calc_dist_gui.segment -side top -anchor nw
  label $calc_dist_gui.segment.l -text "Segments:"
  pack $calc_dist_gui.segment.l -side left
  foreach entry [list byatom byres] {
    radiobutton $calc_dist_gui.segment.$entry -text $entry -variable [namespace current]::calc_dist_guiopts(segment) -value $entry
    pack $calc_dist_gui.segment.$entry -side left
  }
}
#*****
