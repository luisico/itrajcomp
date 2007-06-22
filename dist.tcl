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

# dist.tcl
#    Functions to calculate the distance matrix.


proc itrajcomp::calc_dist {self} {
  # Check number of atoms in selections, and combined list of molecules
  if {[[namespace current]::CheckNatoms $self] == -1} {
    return -code return
  }

  # Define segments
  [namespace current]::DefineSegments $self

  # Precalculate coordinates of each segment
  [namespace current]::CoorSegments $self

  # Calculate distance matrix
  return [[namespace current]::LoopSegments $self]
}


proc itrajcomp::calc_dist_prehook1 {self} {
}

proc itrajcomp::calc_dist_prehook2 {self} {
}

proc itrajcomp::calc_dist_hook {self} {
  namespace eval [namespace current]::${self}:: {
    set dist {}
    foreach m $sets(mol_all) {
      foreach f [lindex $sets(frame1) [lsearch -exact $sets(mol_all) $m]] {
	set coor1 [lindex $coor($m:$f) $reg1]
	set coor2 [lindex $coor($m:$f) $reg2]
	lappend dist [veclength [vecsub $coor2 $coor1]]
      }
    }
    # TODO: add flexible data storage, to add more than one data output
    #vecstddev $dist
    return [vecmean $dist]
  }
}


proc itrajcomp::calc_dist_options {} {
  # Options for dist gui
  variable calc_dist_frame
  variable calc_dist_opts
  set calc_dist_opts(segment) "byatom"

  # by segment
  frame $calc_dist_frame.segment
  pack $calc_dist_frame.segment -side top -anchor nw
  label $calc_dist_frame.segment.l -text "Segments:"
  pack $calc_dist_frame.segment.l -side left
  foreach entry [list byatom byres] {
    radiobutton $calc_dist_frame.segment.$entry -text $entry -variable [namespace current]::calc_dist_opts(segment) -value $entry
    pack $calc_dist_frame.segment.$entry -side left
  }

  # Graph options
  variable calc_dist_graph
  array set calc_dist_graph {
    type         "segments"\
    format_data  "%8.4f"\
    format_key   "%3d %3s"\
    format_scale "%4.2f"\
    rep_style1   "CPK"
  }
}


proc itrajcomp::calc_dist_options_update {} {
  # Update options gui
  [namespace current]::Samemols on
}
