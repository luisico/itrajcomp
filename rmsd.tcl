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
  namespace eval [namespace current]::${self}:: {
    if {$opts(align)} {
      set move_sel [atomselect $i "all"]
    }
  }
}

proc itrajcomp::calc_rmsd_prehook2 {self} {
  namespace eval [namespace current]::${self}:: {
    if {$opts(align)} {
      $move_sel frame $j
    }
  }
}

proc itrajcomp::calc_rmsd_hook {self} {
  namespace eval [namespace current]::${self}:: {
    if {$opts(align)} {
      set tmatrix [measure fit $s1 $s2]
      $move_sel move $tmatrix
    }
    return [measure rmsd $s1 $s2]
  }
}


proc itrajcomp::calc_rmsd_options {} {
  # Options for rmsd gui
  variable calc_rmsd_frame
  variable calc_rmsd_opts
  set calc_rmsd_opts(align) 0

  checkbutton $calc_rmsd_frame.align -text "align" -variable [namespace current]::calc_rmsd_opts(align)
  pack $calc_rmsd_frame.align -side top -anchor nw

  # Graph options
  variable calc_rmsd_graph
  array set calc_rmsd_graph {
    type         "frames"\
    format_data  "%8.4f"\
    format_key   "%3d %3d"\
    format_scale "%4.2f"\
    rep_style1   "NewRibbons"
  }
}

proc itrajcomp::calc_rmsd_options_update {} {
}
