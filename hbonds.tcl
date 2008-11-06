#****h* itrajcomp/hbonds
# NAME
# hbonds -- Functions to calculate hydrogen bonds between selections
#
# AUTHOR
# Luis Gracia
#
# DESCRIPTION
#
# Functions to calculate hydrogen bonds between selections.
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

#****f* hbonds/calc_hbonds
# NAME
# calc_hbonds
# SYNOPSIS
# itrajcomp::calc_hbonds self
# FUNCTION
# This functions gets called when adding a new type of calculation.
# Hbonds calculation type
# PARAMETERS
# * self -- object
# RETURN VALUE
# Status code
# TODO
# Is this working? seems like only diagonal makes sense here
# SOURCE
proc itrajcomp::calc_hbonds {self} {

  set mol1 [set ${self}::sets(mol1)]
  set mol2 [set ${self}::sets(mol2)]
  if {$mol1 != $mol2} {
    tk_messageBox -title "Error " -message "Selections must come from the same molecule." -parent .itrajcomp
    return -code error
  }
  
  return [[namespace current]::LoopFrames $self]
}
#*****

#****f* hbonds/calc_hbonds_hook
# NAME
# calc_hbonds_hook
# SYNOPSIS
# itrajcomp::calc_hbonds_hook self
# FUNCTION
# This function gets called for each pair.
# Hbonds
# PARAMETERS
# * self -- object
# RETURN VALUE
# List with number of hbonds and hbonds list
# SOURCE
proc itrajcomp::calc_hbonds_hook {self} {
  set hbonds [measure hbonds [set ${self}::opts(cutoff)] [set ${self}::opts(angle)] [set ${self}::s1] [set ${self}::s2]]
  set number_hbonds [llength [lindex $hbonds 0]]
  return [list $number_hbonds $hbonds]
}
#*****

#****f* hbonds/calc_hbonds_options
# NAME
# calc_hbonds_options
# SYNOPSIS
# itrajcomp::calc_hbonds_options
# FUNCTION
# This functions gets called when adding a new type of calculation. It sets up the GUI and other options.
# SOURCE
proc itrajcomp::calc_hbonds_options {} {
  # Options for hbonds
  variable calc_hbonds_frame
  variable calc_hbonds_datatype
  set calc_hbonds_datatype(mode) "dual"
  set calc_hbonds_datatype(ascii) 1

  variable calc_hbonds_opts
  set calc_hbonds_opts(cutoff) 5.0
  set calc_hbonds_opts(angle) 30.0

  frame $calc_hbonds_frame.cutoff
  pack $calc_hbonds_frame.cutoff -side top -anchor nw
  label $calc_hbonds_frame.cutoff.l -text "Cutoff:"
  entry $calc_hbonds_frame.cutoff.v -width 5 -textvariable [namespace current]::calc_hbonds_opts(cutoff)
  pack $calc_hbonds_frame.cutoff.l $calc_hbonds_frame.cutoff.v -side left

  frame $calc_hbonds_frame.angle
  pack $calc_hbonds_frame.angle -side top -anchor nw
  label $calc_hbonds_frame.angle.l -text "Angle:"
  entry $calc_hbonds_frame.angle.v -width 5 -textvariable [namespace current]::calc_hbonds_opts(angle)
  pack $calc_hbonds_frame.angle.l $calc_hbonds_frame.angle.v -side left

  # Graph options
  variable calc_hbonds_graph
  array set calc_hbonds_graph {
    type         "frames"
    formats      "f"
    rep_style1   "NewRibbons"
    connect      "cones"
  }
}
#*****
