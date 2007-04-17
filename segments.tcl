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

# frames.tcl
#    Frames objects.


proc itrajcomp::GraphSegments {self} {
  # Create graph for object with segment information (atoms, residue,...)
  namespace eval [namespace current]::${self}:: {
    variable add_rep
    variable rep_list
    variable rep_num
    variable colors
    variable segments

    set nsegments [llength $segments]
    #puts "$nsegments -> $segments"

    foreach key $keys {
      lassign [split $key ,:] i j k l
      set part2($i) $j
      set part2($k) $l
    }

    set maxkeys [llength $keys]
    set count 0
    
    set offx 0
    set offy 0
    set width 3
    for {set i 0} {$i < $nsegments} {incr i} {
      set key1 "[lindex $segments $i]:$part2([lindex $segments $i])"
      set rep_list($key1) {}
      set rep_num($key1) 0
      set offy 0
      for {set k 0} {$k < $nsegments} {incr k} {
	set key2 "[lindex $segments $k]:$part2([lindex $segments $k])"
	set rep_list($key2) {}
	set rep_num($key2) 0
	set key "$key1,$key2"
	#puts -nonewline "$key "
	if {![info exists data($key)]} {
	  #puts ""
	  continue
	}
	set x [expr ($i+$offx)*($grid+$width)]
	set y [expr ($k+$offy)*($grid+$width)]
	set add_rep($key) 0
	set colors($key) [[namespace parent]::ColorScale $data($key) $max $min]
	#puts "-> $x $offx           $k $l - > $y $offy     = $data($key)    $color"
	$plot create rectangle $x $y [expr $x+$grid] [expr $y+$grid] -fill $colors($key) -outline $colors($key) -tag $key -width $width
	
	$plot bind $key <Enter>            "[namespace parent]::ShowPoint $self $key $data($key) 1"
	$plot bind $key <B1-ButtonRelease>  "[namespace parent]::MapPoint $self $key $data($key)" 
	$plot bind $key <Shift-B1-ButtonRelease>   "[namespace parent]::MapCluster3 $self $key  0  0"
	$plot bind $key <Shift-B2-ButtonRelease>   "[namespace parent]::MapCluster3 $self $key  0 -1"
	$plot bind $key <Shift-B3-ButtonRelease>   "[namespace parent]::MapCluster3 $self $key  0  1"
	$plot bind $key <Control-B1-ButtonRelease> "[namespace parent]::MapCluster2 $self $key  0  0"
	$plot bind $key <Control-B2-ButtonRelease> "[namespace parent]::MapCluster2 $self $key -1  0"
	$plot bind $key <Control-B3-ButtonRelease> "[namespace parent]::MapCluster2 $self $key  1  0"

	incr count
	[namespace parent]::ProgressBar $count $maxkeys
      }
      set offy [expr $offy+$k]
      
    }
    set offx [expr $offx+$i]
    
  }
}


proc itrajcomp::LoopSegments {self} {
  # Create fake hooks if they are not present
  variable calctype
  foreach hook {prehook1 prehook2 hook} {
    set proc "calc_${calctype}_$hook"
    if {[llength [info procs $proc]] < 1} {
      proc $proc {self} {}
    }
  }

  namespace eval [namespace current]::${self}:: {
    
    set nreg [llength $segments]
    # Calculate max numbers of iterations
    set maxkeys [expr ($nreg*$nreg+$nreg)/2]
    
    set z 1
    set count 0
    for {set reg1 0} {$reg1 < $nreg} {incr reg1} {
      set i [lindex $segments $reg1]
      set j [lindex $names $reg1]
      set key1 "$i:$j"
      #-> prehook1
      [namespace parent]::calc_${type}_prehook1 $self
      for {set reg2 0} {$reg2 < $nreg} {incr reg2} {
	set k [lindex $segments $reg2]
	set l [lindex $names $reg2]
	set key2 "$k:$l"
	#-> prehook2
	[namespace parent]::calc_${type}_prehook2 $self
	if {[info exists data($key2,$key1)]} {
	  continue
	} else {
	  #-> hook
	  set data($key1,$key2) [[namespace parent]::calc_${type}_hook $self]
	  #puts "$i $k , $key1 $key2 , $data($key1,$key2)"
	  incr count
	  [namespace current]::ProgressBar $count $maxkeys
	  if {$z} {
	    set min $data($key1,$key2)
	    set max $data($key1,$key2)
	    set z 0
	  }
	  if {$data($key1,$key2) > $max} {
	    set max $data($key1,$key2)
	  }
	  if {$data($key1,$key2) < $min} {
	    set min $data($key1,$key2)
	  }
	}
      }
    }
  }
}


# TODO: generalize more
proc itrajcomp::DefineSegments {self} {
  namespace eval [namespace current]::${self}:: {
    if {$byres} {
      set segments [lsort -unique -integer [[atomselect [lindex $mol_all 0] $sel1] get residue]]
      set names {}
      foreach r $segments {
	lappend names [lindex [[atomselect [lindex $mol_all 0] "residue $r"] get resname] 0]
      }
    } else {
      set segments [[atomselect [lindex $mol_all 0] $sel1] get index]
      set names [[atomselect [lindex $mol_all 0] $sel1] get name]
    }
  }
}
