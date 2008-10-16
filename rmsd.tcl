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

# rmsd.tcl
#    Functions to calculate rmsd.


proc itrajcomp::calc_rmsd {self} {
  # Check number of atoms in selections, and combined list of molecules
  if {[[namespace current]::CheckNatoms $self] == -1} {
    return -code return
  }
  
  return [[namespace current]::LoopFrames $self]
}

proc itrajcomp::calc_rmsd_prehook1 {self} {
  if {[set ${self}::opts(align)]} {
    # FIXME: as workaround this code was moved to frames.tcl
    #set ${self}::move_sel [atomselect [set ${self}::i] "all"]
  }
}

proc itrajcomp::calc_rmsd_prehook2 {self} {
  if {[set ${self}::opts(align)]} {
    [set ${self}::move_sel] frame [set ${self}::j]
  }
}

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

proc itrajcomp::calc_rmsd_options_update {} {
}
