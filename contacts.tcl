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

# contacs.tcl
#    Functions to calculate contacts between atoms.


proc itrajcomp::calc_contacts {self} {
  return [[namespace current]::LoopFrames $self]
}


proc itrajcomp::calc_contacts_hook {self} {
  namespace eval [namespace current]::${self}:: {
    set contacts [measure contacts $opts(cutoff) $s1 $s2]
    set number_contacts [llength [lindex $contacts 0]]
    return [list $number_contacts $contacts]
    #return $number_contacts
  }
}


proc itrajcomp::calc_contacts_options {} {
  # Options for contacts
  variable calc_contacts_frame
  variable calc_contacts_datatype
  set calc_contacts_datatype(mode) "dual"
  set calc_contacts_datatype(ascii) 1
    
  variable calc_contacts_opts
  set calc_contacts_opts(cutoff) 5.0

  frame $calc_contacts_frame.cutoff
  pack $calc_contacts_frame.cutoff -side top -anchor nw
  label $calc_contacts_frame.cutoff.l -text "Cutoff:"
  entry $calc_contacts_frame.cutoff.v -width 5 -textvariable [namespace current]::calc_contacts_opts(cutoff)
  pack $calc_contacts_frame.cutoff.l $calc_contacts_frame.cutoff.v -side left

  # Graph options
  variable calc_contacts_graph
  array set calc_contacts_graph {
    type         "frames"\
    format_data  "%4i"\
    format_key   "%3d %3d"\
    format_scale "%4i"\
    rep_style1   "NewRibbons"
  }
}
