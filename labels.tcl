#****h* itrajcomp/labels
# NAME
# labels -- Functions to calculate distance between labels
#
# AUTHOR
# Luis Gracia
#
# DESCRIPTION
#
# Functions to calculate distance between labels (Atoms, Bonds, Angles, Dihedrals).
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

#****f* labels/calc_labels
# NAME
# calc_labels
# SYNOPSIS
# itrajcomp::calc_labels self
# FUNCTION
# This functions gets called when adding a new type of calculation.
# Labels calculation type
# PARAMETERS
# * self -- object
# RETURN VALUE
# Status code
# SOURCE
proc itrajcomp::calc_labels {self} {
  array set guiopts [array get ${self}::guiopts]
  
  # Get values for each mol
  set i 0
  if {! [info exists guiopts(labels_status)]} {
    tk_messageBox -title "Error" -message "No $guiopts(label_type) have been defined" -type ok
    return -code error
  }
  
  # Precalculate values
  foreach lab $guiopts(labels_status) {
    if {$lab == 1} {
      set alldata($i) [label graph $guiopts(label_type) $i]
    }
    incr i
  }
  if {! [array exists alldata]} {
    tk_messageBox -title "Error" -message "No $guiopts(label_type) have been selected" -type ok
    return -code error
  }
  array set ${self}::alldata [array get alldata]

  return [[namespace current]::LoopFrames $self]
}
#*****

#****f* labels/calc_labels_hook
# NAME
# calc_labels_hook
# SYNOPSIS
# itrajcomp::calc_labels_hook self
# FUNCTION
# This function gets called for each pair.
# Rmsd for labels
# PARAMETERS
# * self -- object
# RETURN VALUE
# List with number of hbonds and hbonds list
# SOURCE
proc itrajcomp::calc_labels_hook {self} {
  array set alldata [array get ${self}::alldata]
  set label_type [set ${self}::guiopts(label_type)]
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
#*****

#****f* labels/calc_labels_options
# NAME
# calc_labels_options
# SYNOPSIS
# itrajcomp::calc_labels_options
# FUNCTION
# This functions gets called when adding a new type of calculation. It sets up the GUI and other options.
# SOURCE
proc itrajcomp::calc_labels_options {} {
  # Options
  variable calc_labels_opts
  array set calc_labels_opts {
    mode         frames
    sets         dual
    ascii        0
    formats      f
    style        NewRibbons
  }

  # GUI options
  variable calc_labels_gui
  variable calc_labels_guiopts
  array set calc_labels_guiopts {
    label_type     Dihedrals
    labels_status  ""
  }

  frame $calc_labels_gui.labs
  pack $calc_labels_gui.labs -side top -anchor nw
  label $calc_labels_gui.labs.l -text "Labels:"
  pack $calc_labels_gui.labs.l -side left
  foreach entry [list Bonds Angles Dihedrals] {
    radiobutton $calc_labels_gui.labs.[string tolower $entry] -text $entry -variable [namespace current]::calc_labels_guiopts(label_type) -value $entry -command "[namespace current]::calc_labels_options_update"
    pack $calc_labels_gui.labs.[string tolower $entry] -side left
  }
  menubutton $calc_labels_gui.labs.id -text "Id" -menu $calc_labels_gui.labs.id.m -relief raised
  menu $calc_labels_gui.labs.id.m
  pack $calc_labels_gui.labs.id -side left
  [namespace current]::setBalloonHelp $calc_labels_gui.labs "Select the labels type and id"
}
#*****

#****f* labels/calc_labels_options_update
# NAME
# calc_labels_options_update
# SYNOPSIS
# itrajcomp::calc_labels_options_update
# FUNCTION
# This function gets called when an update is issued for the GUI.
# SOURCE
proc itrajcomp::calc_labels_options_update {} {
  # Update list of available labels and reset their status
  # Each label has the format: 'num_label (atom_label, atom_label,...)'
  #    * num_label is the label number
  #    * atom_label is $mol-$resname$resid-$name
  variable tab_calc
  variable calc_labels_gui
  variable calc_labels_guiopts

  # TODO: why hold two variables with the same info?
  variable labels_status_array

  set labels [label list $calc_labels_guiopts(label_type)]
  set n [llength $labels]
  $calc_labels_gui.labs.id.m delete 0 end
  # TODO: don't reset their status (try to keep them when swithing between label types in the gui)
  array unset labels_status_array
  if {$n > 0} {
    $calc_labels_gui.labs.id config -state normal
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
      $calc_labels_gui.labs.id.m add checkbutton -label $label -variable [namespace current]::labels_status_array($i) -command "[namespace current]::labels_update_status $i"
      #puts [array get labels_status_array]
    }
  }

  if {[info exists calc_labels_guiopts(labels_status)]} {
    unset calc_labels_guiopts(labels_status)
  }
  foreach x [array names labels_status_array ] {
    lappend calc_labels_guiopts(labels_status) $labels_status_array($x)
  }
}
#*****

#****f* rmsd/calc_labels_update_status
# NAME
# calc_labels_update_status
# SYNOPSIS
# itrajcomp::calc_labels_update_status
# FUNCTION
# Update labels
# PARAMETERS
# * id -- label id
# SOURCE
proc itrajcomp::labels_update_status {id} {
  # Update status of a label
  variable labels_status_array
  variable calc_labels_guiopts
  
  set calc_labels_guiopts(labels_status) [lreplace $calc_labels_guiopts(labels_status) $id $id $labels_status_array($id)]
}
#*****
