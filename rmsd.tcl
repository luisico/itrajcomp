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


package provide itrajcomp 1.0

proc itrajcomp::rmsd { self } {
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
    variable align

    # Check number of atoms in selections, and combined list of molecules
    set mol_all [[namespace parent]::CheckNatoms $mol1 $sel1 $mol2 $sel2]
    if {$mol_all == -1} {
      return -code return
    }
    
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

    # Calculate rmsd for each pair reference(mol,frame)-target(mol,frame)
    set z 1
    set count 0
    foreach i $mol1 {
      set s1 [atomselect $i $sel1]
      if {$align} {
	set move_sel [atomselect $i "all"]
      }
      foreach j [lindex $frame1 [lsearch -exact $mol1 $i]] {
	$s1 frame $j
	if {$align} {
	  $move_sel frame $j
	}
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
	      if {$align} {
		set tmatrix [measure fit $s1 $s2]
		$move_sel move $tmatrix
	      }
	      set data($i:$j,$k:$l) [measure rmsd $s1 $s2]
#	      puts "$i $j $k $l $data($i:$j,$k:$l)"
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

