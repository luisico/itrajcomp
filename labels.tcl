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

# labels.tcl
#    Functions to calculate distance between labels (Atoms, Bonds, Angles, Dihedrals).


package provide itrajcomp 1.0

proc itrajcomp::calc_labels {self} {
  array set opts [array get ${self}::opts]
  
  # Get values for each mol
  set i 0
  if {! [info exists opts(labels_status)]} {
    tk_messageBox -title "Warning" -message "No $opts(label_type) have been defined" -type ok
    return 1
  }
    
  foreach lab $opts(labels_status) {
    if {$lab == 1} {
      set alldata($i) [label graph $opts(label_type) $i]
    }
    incr i
  }
  if {! [array exists alldata]} {
    tk_messageBox -title "Warning" -message "No $opts(label_type) have been selected" -type ok
    return 1
  }
  array set ${self}::alldata [array get alldata]

  return [[namespace current]::LoopFrames $self]
}


proc itrajcomp::calc_labels_hook {self} {
  array set alldata [array get ${self}::alldata]
  set label_type [set ${self}::opts(label_type)]
  set rms {}
  set rmstot 0
  set names [array names alldata]
  foreach v $names {
    set v1 [lindex $alldata($v) [set ${self}::j]]
    set v2 [lindex $alldata($v) [set ${self}::l]]
    set val [expr {abs($v1-$v2)}]
    if {$val > 180 && ($label_type eq "Dihedrals" || $label_type eq "Angles")} {
      set val [expr {abs($val -360)}]
    }
    set tmp [expr {$val*$val}]
    set rmstot [expr {$rmstot + $tmp}]
    lappend rms $tmp
    #puts "DEBUG: $v1 $v2 $val [expr $val*$val] $rms"
  }
  set rmstot [expr {sqrt($rmstot/([llength $names]+1))} ]
  return [list $rmstot $rms]
}


proc itrajcomp::calc_labels_options {} {
  # Options for labels
  variable calc_labels_frame
  variable calc_labels_datatype
  set calc_labels_datatype(mode) "dual"
  set calc_labels_datatype(ascii) 0

  variable calc_labels_opts
  set calc_labels_opts(label_type)  "Dihedrals"
  set calc_labels_opts(labels_status) ""

  frame $calc_labels_frame.labs
  pack $calc_labels_frame.labs -side top -anchor nw
  label $calc_labels_frame.labs.l -text "Labels:"
  pack $calc_labels_frame.labs.l -side left
  foreach entry [list Bonds Angles Dihedrals] {
    radiobutton $calc_labels_frame.labs.[string tolower $entry] -text $entry -variable [namespace current]::calc_labels_opts(label_type) -value $entry -command "[namespace current]::calc_labels_options_update"
    pack $calc_labels_frame.labs.[string tolower $entry] -side left
  }
  menubutton $calc_labels_frame.labs.id -text "Id" -menu $calc_labels_frame.labs.id.m -relief raised
  menu $calc_labels_frame.labs.id.m
  pack $calc_labels_frame.labs.id -side left

  # Graph options
  variable calc_labels_graph
  array set calc_labels_graph {
    type         "frames"\
    format_data  "%8.4f"\
    format_key   "%3d %3d"\
    format_scale "%4.2f"\
    rep_style1   "NewRibbons"
  }
}


proc itrajcomp::calc_labels_options_update {} {
  # Update list of available labels and reset their status
  # Each label has the format: 'num_label (atom_label, atom_label,...)'
  #    * num_label is the label number
  #    * atom_label is $mol-$resname$resid-$name
  variable tab_calc
  variable calc_labels_frame
  variable calc_labels_opts

  # TODO: why hold two variables with the same info?
  variable labels_status_array

  set labels [label list $calc_labels_opts(label_type)]
  set n [llength $labels]
  $calc_labels_frame.labs.id.m delete 0 end
  # TODO: don't reset their status (try to keep them when swithing between label types in the gui)
  array unset labels_status_array
  if {$n > 0} {
    $calc_labels_frame.labs.id config -state normal
    set nat [expr {[llength [lindex $labels 0]] -2}]
    for {set i 0} {$i < $n} {incr i} {
      set label "$i ("
      for {set j 0} {$j < $nat} {incr j} {
	set mol   [lindex [lindex [lindex $labels $i] $j] 0]
	set index [lindex [lindex [lindex $labels $i] $j] 1]
	set at    [atomselect $mol "index $index"]
	set resname [$at get resname]
	set resid   [$at get resid]
	set name    [$at get name]
	append label "$mol-$resname$resid-$name"
	if {$j < [expr {$nat-1}]} {
	  append label ", "
	}
      }
      append label ")"
      $calc_labels_frame.labs.id.m add checkbutton -label $label -variable [namespace current]::labels_status_array($i) -command "[namespace current]::labels_update_status $i"
      #puts [array get labels_status_array]
    }
  }

  if {[info exists calc_labels_opts(labels_status)]} {
    unset calc_labels_opts(labels_status)
  }
  foreach x [array names labels_status_array ] {
    lappend calc_labels_opts(labels_status) $labels_status_array($x)
  }
}


proc itrajcomp::labels_update_status {i} {
  # Update status of a label
  variable labels_status_array
  variable calc_labels_opts
  
  set calc_labels_opts(labels_status) [lreplace $calc_labels_opts(labels_status) $i $i $labels_status_array($i)]
}


