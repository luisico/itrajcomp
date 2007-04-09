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


proc itrajcomp::contacts { self } {
    
  # Access object variables
  foreach v [[namespace current]::Objvars $self] {
    #puts "$v --> [set ${self}::$v]"
    set $v [set ${self}::$v]
  }
  #puts "---------------"
  #puts [info vars]
  
  # Object format
  set graphtype   "frame"
  set format_data "%4i"
  set format_key  "%3d %3d"
  set format_scale "%4i"
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

  # Calculate contacts
  set z 1
  set count 0
  foreach i $mol1 {
    set s1 [atomselect $i $sel1]
    foreach j [lindex $frame1 [lsearch -exact $mol1 $i]] {
      $s1 frame $j
      foreach k $mol2 {
	set s2 [atomselect $k $sel2]
	foreach l [lindex $frame2 [lsearch -exact $mol2 $k]] {
	  if {$diagonal && $j != $l} {
	    continue
	  }
	  if {[info exists data($k:$l,$i:$j)]} {
	    #	      set data($i:$j,$k:$l) $data($k:$l,$i:$j)
	    continue
	  } else {
	    $s2 frame $l
	    set data($i:$j,$k:$l) [llength [lindex [measure contacts $cutoff $s1 $s2] 0]]
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


proc itrajcomp::contacts_options {} {
  # Options for contacts
  variable contacts_options
  variable contacts_vars [list cutoff]
  variable cutoff 5.0

  frame $contacts_options.cutoff
  pack $contacts_options.cutoff -side top -anchor nw
  label $contacts_options.cutoff.l -text "Cutoff:"
  entry $contacts_options.cutoff.v -width 5 -textvariable [namespace current]::cutoff
  pack $contacts_options.cutoff.l $contacts_options.cutoff.v -side left
}
