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
  namespace eval [namespace current]::${self}:: {
    
    variable mol1
    variable mol2
    variable frame1
    variable frame2
    variable sel1
    variable sel2
    variable keys {}
    variable vals {}
    variable data
    variable min
    variable max
    variable format_data "%8.4f"
    variable format_key "%3d %3d"
    variable diagonal
    variable labstype
    variable labsnum
    
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
    foreach lab $labsnum {
      if {$lab == 1} {
	set alldata($i) [label graph $labstype $i]
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
	      puts "DEBUG: $i $j $k $l"
	      set rms 0
	      foreach v [array names alldata] {
		set v1 [lindex $alldata($v) $j]
		set v2 [lindex $alldata($v) $l]
		set val [expr abs($v1-$v2)]
		if {$val > 180 && ($labstype eq "Dihedrals" || $labstype eq "Angles")} {
		  set val [expr abs($val -360)]
		}
		set rms [expr $rms + $val*$val]
		puts "DEBUG: $v1 $v2 $val [expr $val*$val] $rms"
	      }

	      set data($i:$j,$k:$l) [expr sqrt($rms/([llength [array names alldata]]+1))]
	      puts "DEBUG: $data($i:$j,$k:$l)\n"

	      incr count
	      [namespace parent]::ProgressBar $count $maxkeys
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
    
  }
  return 0
}






