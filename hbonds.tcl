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
#      See maingui.tcl

# Documentation
# ------------
#      The documentation can be found in the README.txt file and
#      http://physiology.med.cornell.edu/faculty/hweinstein/vmdplugins/itrajcomp

# hbonds.tcl
#    Functions to calculate hydrogen bonds between selections.


# TODO: is this working? seems like only diagonal makes sense here
proc itrajcomp::calc_hbonds {self} {

  set mol1 [set ${self}::sets(mol1)]
  set mol2 [set ${self}::sets(mol2)]
  if {$mol1 != $mol2} {
    tk_messageBox -title "Warning " -message "Selections must come from the same molecule." -parent .itrajcomp
    return -code return
  }
  
  return [[namespace current]::LoopFrames $self]
}


proc itrajcomp::calc_hbonds_hook {self} {
  set hbonds [measure hbonds [set ${self}::opts(cutoff)] [set ${self}::opts(angle)] [set ${self}::s1] [set ${self}::s2]]
  set number_hbonds [llength [lindex $hbonds 0]]
  return [list $number_hbonds $hbonds]
}


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
