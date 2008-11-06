#****h* itrajcomp/rmsd
# NAME
# rmsd -- Functions to calculate rmsd
#
# AUTHOR
# Luis Gracia
#
# DESCRIPTION
#
# Functions to calculate rmsd.
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

#****f* rmsd/calc_rmsd
# NAME
# calc_rmsd
# SYNOPSIS
# itrajcomp::calc_rmsd self
# FUNCTION
# This functions gets called when adding a new type of calculation.
# Rmsd calculation type
# PARAMETERS
# * self -- object
# RETURN VALUE
# Status code
# SOURCE
proc itrajcomp::calc_rmsd {self} {
  # Check number of atoms in selections, and combined list of molecules
  if {[[namespace current]::CheckNatoms $self] == -1} {
    return -code error
  }
  
  return [[namespace current]::LoopFrames $self]
}
#*****

#****f* rmsd/calc_rmsd_prehook1
# NAME
# calc_rmsd_prehook1
# SYNOPSIS
# itrajcomp::calc_rmsd_prehook1 self
# FUNCTION
# This functions gets called each time the first molecule in the pair changes
# PARAMETERS
# * self -- object
# SOURCE
proc itrajcomp::calc_rmsd_prehook1 {self} {
  if {[set ${self}::opts(align)]} {
    # FIXME: as workaround this code was moved to frames.tcl
    #set ${self}::move_sel [atomselect [set ${self}::i] "all"]
  }
}
#*****

#****f* rmsd/calc_rmsd_prehook2
# NAME
# calc_rmsd_prehook2
# SYNOPSIS
# itrajcomp::calc_rmsd_prehook2 self
# FUNCTION
# This functions gets called each time the frame of the first molecule in the pair changes.
# If the align option is on it updates the selection to the new frame
# PARAMETERS
# * self -- object
# SOURCE
proc itrajcomp::calc_rmsd_prehook2 {self} {
  if {[set ${self}::opts(align)]} {
    [set ${self}::move_sel] frame [set ${self}::j]
  }
}
#*****

#****f* rmsd/calc_rmsd_hook
# NAME
# calc_rmsd_hook
# SYNOPSIS
# itrajcomp::calc_rmsd_hook self
# FUNCTION
# This function gets called for each pair.
# Calculte the rmsd
# PARAMETERS
# * self -- object
# RETURN VALUE
# Rmsd
# SOURCE
proc itrajcomp::calc_rmsd_hook {self} {
  variable fast_rmsd

  if {[set ${self}::opts(align)]} {
    set tmatrix [measure fit [set ${self}::s1] [set ${self}::s2]]
    [set ${self}::move_sel] move $tmatrix
  }
  if {$fast_rmsd} {
    if {[set ${self}::opts(byres)]} {
      set rmsd [measure rmsd [set ${self}::s1] [set ${self}::s2] byres]
    } else {
      set rmsd [measure rmsd [set ${self}::s1] [set ${self}::s2] byatom]
    }
  } else {
    set rmsd [measure rmsd [set ${self}::s1] [set ${self}::s2]]
  }
  return $rmsd
}
#*****

#****f* rmsd/calc_rmsd_options
# NAME
# calc_rmsd_options
# SYNOPSIS
# itrajcomp::calc_rmsd_options
# FUNCTION
# This functions gets called when adding a new type of calculation. It sets up the GUI and other options.
# SOURCE
proc itrajcomp::calc_rmsd_options {} {
  # Test for hacked VMD version with fast_rmsd enabled.
  variable fast_rmsd
  if {![info exists fast_rmsd]} {
    set fast_rmsd 1
    if [catch { set test [measure rmsd [atomselect top "index 1"] [atomselect top "index 1"] byatom] } msg] {
      set fast_rmsd 0
    }
  }

  # Options for rmsd gui
  variable calc_rmsd_frame
  variable calc_rmsd_datatype

  variable calc_rmsd_opts
  set calc_rmsd_opts(align) 0

  checkbutton $calc_rmsd_frame.align -text "align" -variable [namespace current]::calc_rmsd_opts(align)
  pack $calc_rmsd_frame.align -side top -anchor nw

  if {$fast_rmsd} {
    set calc_rmsd_datatype(mode) "dual"
    set calc_rmsd_datatype(ascii) 0
    set calc_rmsd_opts(byres) 0
    checkbutton $calc_rmsd_frame.byres -text "byres" -variable [namespace current]::calc_rmsd_opts(byres)
    pack $calc_rmsd_frame.byres -side top -anchor nw
  } else {
    set calc_rmsd_datatype(mode) "single"
  }
  
  # Graph options
  variable calc_rmsd_graph
  array set calc_rmsd_graph {
    type         "frames"
    formats      "f"
    rep_style1   "NewRibbons"
  }
}
#*****

#****f* rmsd/calc_rmsd_options_update
# NAME
# calc_rmsd_options_update
# SYNOPSIS
# itrajcomp::calc_rmsd_options_update
# FUNCTION
# This function gets called when an update is issued for the GUI.
# SOURCE
proc itrajcomp::calc_rmsd_options_update {} {
}
#*****
