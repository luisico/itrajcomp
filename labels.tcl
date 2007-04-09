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

proc itrajcomp::labels { self } {

  # Access object variables
  foreach v [[namespace current]::Objvars $self] {
    #puts "$v --> [set ${self}::$v]"
    set $v [set ${self}::$v]
  }
  #puts "---------------"
  #puts [info vars]
  
  # Object format
  set graphtype   "frame"
  set format_data "%8.4f"
  set format_key  "%3d %3d"
  set format_scale "%4.2f"
  set header1     "mol"
  set header2     "frame"
  set rep_style1  "NewRibbons"

  # Calculate max numbers of iteractions
  set maxkeys 0
  foreach i $mol1 {
    foreach j [lindex $frame1 [lsearch -exact $mol1 $i]] {
      foreach k $mol2 {
	foreach l [lindex $frame2 [lsearch -exact $mol2 $k]] {
	  if {$diagonal} {
	    if {$i != $k || $j != $l} {
	      continue
	    }
	  }
	  if {[info exists foo($k:$l,$i:$j)]} {
	    continue
	  } else {
	    set foo($i:$j,$k:$l) 1
	    incr maxkeys
	  }
	}
      }
    }
  }
  
  # Get values for each mol
  set i 0
  foreach lab $labels_status {
    if {$lab == 1} {
      set alldata($i) [label graph $label_type $i]
    }
    incr i
  }
  if {! [array exists alldata]} {
    tk_messageBox -title "Warning" -message "No Labels have been selected" -type ok
    return 1
  }
  
  set z 1
  set count 0
  foreach i $mol1 {
    foreach j [lindex $frame1 [lsearch -exact $mol1 $i]] {
      foreach k $mol2 {
	foreach l [lindex $frame2 [lsearch -exact $mol2 $k]] {
	  if {$diagonal && $j != $l} {
	    continue
	  }
	  if {[info exists data($k:$l,$i:$j)]} {
	    #	      set data($i:$j,$k:$l) $data($k:$l,$i:$j)
	    continue
	  } else {
	    #puts "DEBUG: $i $j $k $l"
	    set rms 0
	    foreach v [array names alldata] {
	      set v1 [lindex $alldata($v) $j]
	      set v2 [lindex $alldata($v) $l]
	      set val [expr abs($v1-$v2)]
	      if {$val > 180 && ($label_type eq "Dihedrals" || $label_type eq "Angles")} {
		set val [expr abs($val -360)]
	      }
	      set rms [expr $rms + $val*$val]
	      #puts "DEBUG: $v1 $v2 $val [expr $val*$val] $rms"
	    }
	    
	    set data($i:$j,$k:$l) [expr sqrt($rms/([llength [array names alldata]]+1))]
	    #puts "DEBUG: $data($i:$j,$k:$l)\n"
	    
	    incr count
	    [namespace current]::ProgressBar $count $maxkeys
	    if {$z} {
	      set min $data($i:$j,$k:$l)
	      set max $data($i:$j,$k:$l)
	      set z 0
	    }
	    if {$data($i:$j,$k:$l) > $max} {
	      set max $data($i:$j,$k:$l)
	    }
	    if {$data($i:$j,$k:$l) < $min} {
	      set min $data($i:$j,$k:$l)
	    }
	  }
	}
      }
    }
  }
  set keys [lsort -dictionary [array names data]]
  foreach key $keys {
    lappend vals $data($key)
  }
  
  # Set object variables
  foreach v [[namespace current]::Objvars $self] {
    set ${self}::$v  [set $v]
    #puts "$v --->\t[set ${self}::$v]"
  }
  array set ${self}::data [array get data]

  return 0
}


proc itrajcomp::labels_options {} {
  # Options for labels
  variable labels_options
  variable labels_vars [list label_type labels_status]
  variable label_type "Dihedrals"
  variable labels_status
  variable labels_status_array

  frame $labels_options.labs
  pack $labels_options.labs -side top -anchor nw
  label $labels_options.labs.l -text "Labels:"
  pack $labels_options.labs.l -side left
  foreach entry [list Bonds Angles Dihedrals] {
    radiobutton $labels_options.labs.[string tolower $entry] -text $entry -variable [namespace current]::label_type -value $entry -command "[namespace current]::labels_options_update"
    pack $labels_options.labs.[string tolower $entry] -side left
  }
  menubutton $labels_options.labs.id -text "Id" -menu $labels_options.labs.id.m -relief raised
  menu $labels_options.labs.id.m
  pack $labels_options.labs.id -side left
}


proc itrajcomp::labels_options_update {} {
  # Update list of available labels and reset their status
  # Each label has the format: 'num_label (atom_label, atom_label,...)'
  #    * num_label is the label number
  #    * atom_label is $mol-$resname$resid-$name
  variable tab_calc
  variable label_type
  variable labels_options

  # TODO: why hold two variables with the same info?
  variable labels_status_array
  variable labels_status

  set labels [label list $label_type]
  set n [llength $labels]
  $labels_options.labs.id.m delete 0 end
  # TODO: don't reset their status (try to keep them when swithing between label types in the gui)
  array unset labels_status_array
  if {$n > 0} {
    $labels_options.labs.id config -state normal
    set nat [expr [llength [lindex $labels 0]] -2]
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
	if {$j < [expr $nat-1]} {
	  append label ", "
	}
      }
      append label ")"
      $labels_options.labs.id.m add checkbutton -label $label -variable [namespace current]::labels_status_array($i) -command "[namespace current]::labels_update_status $i"
    }
  }

  if {[info exists labels_status]} {
    unset labels_status
  }
  foreach x [array names labels_status_array ] {
    lappend labels_status $labels_status_array($x)
  }
}


proc itrajcomp::labels_update_status {i} {
  # Update status of a label
  variable labels_status_array
  variable labels_status
  
  set labels_status [lreplace $labels_status $i $i $labels_status_array($i)]
}


