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


proc itrajcomp::GraphFrames {self} {
  # Create matrix graph for objects
  namespace eval [namespace current]::${self}:: {
    variable map_active
    variable rep_active
    variable rep_list
    variable rep_num
    variable colors

    $plot delete all
    set maxkeys [llength $keys]
    set count 0
    
    set offx 0
    set offy 0
    set width 0
    for {set i 0} {$i < [llength $sets(mol1)]} {incr i} {
      set f1 [lindex $sets(frame1) $i]
      for {set j 0} { $j < [llength $f1]} {incr j} {
	set key1 "[lindex $sets(mol1) $i]:[lindex $f1 $j]"
	set rep_list($key1) {}
	set rep_num($key1) 0
	set offy 0
	for {set k 0} {$k < [llength $sets(mol2)]} {incr k} {
	  set f2 [lindex $sets(frame2) $k]
	  for {set l 0} { $l < [llength $f2]} {incr l} {
	    set key2 "[lindex $sets(mol2) $k]:[lindex $f2 $l]"
	    set rep_list($key2) {}
	    set rep_num($key2) 0
	    set key "$key1,$key2"
	    if {![info exists data($key)]} continue
	    set x [expr ($j+$offx)*($grid+$width)]
	    set y [expr ($l+$offy)*($grid+$width)]
	    set map_active($key) 0
	    set colors($key) [[namespace parent]::ColorScale $data($key) $max $min]
	    set colors_act($key) [[namespace parent]::ColorScale $data($key) $max $min 0.40]
	    #puts "$i $j -> $x $offx           $k $l - > $y $offy     = $data($key)    $colors($key)"
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
	  set offy [expr $offy+[llength $f2]]
	}
      }
      set offx [expr $offx+[llength $f1]]
    }
  }
}


proc itrajcomp::LoopFrames {self} {
  # Create fake hooks if they are not present
  variable calctype
  foreach hook {prehook1 prehook2 hook} {
    set proc "calc_${calctype}_$hook"
    if {[llength [info procs $proc]] < 1} {
      proc $proc {self} {}
    }
  }

  namespace eval [namespace current]::${self}:: {
  
    # Calculate max numbers of iteractions
    set maxkeys 0
    foreach i $sets(mol1) {
      foreach j [lindex $sets(frame1) [lsearch -exact $sets(mol1) $i]] {
	foreach k $sets(mol2) {
	  foreach l [lindex $sets(frame2) [lsearch -exact $sets(mol2) $k]] {
	    if {$opts(diagonal)} {
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
    
    # Calculate for each pair reference(mol,frame)-target(mol,frame)
    set z 1
    set min0 0
    set max0 0
    set count 0
    foreach i $sets(mol1) {
      set s1 [atomselect $i $sets(sel1)]
      #-> prehook1
      [namespace parent]::calc_$opts(type)_prehook1 $self
      foreach j [lindex $sets(frame1) [lsearch -exact $sets(mol1) $i]] {
	$s1 frame $j
	#-> prehook2
	[namespace parent]::calc_$opts(type)_prehook2 $self
	foreach k $sets(mol2) {
	  set s2 [atomselect $k $sets(sel2)]
	  foreach l [lindex $sets(frame2) [lsearch -exact $sets(mol2) $k]] {
	    if {$opts(diagonal) && $j != $l} {
	      continue
	    }
	    if {[info exists data0($k:$l,$i:$j)]} {
	      #	set data0($i:$j,$k:$l) $data0($k:$l,$i:$j)
	      continue
	    } else {
	      $s2 frame $l
	      #-> hook
	      set data0($i:$j,$k:$l) [[namespace parent]::calc_$opts(type)_hook $self]
	      #puts "$i $j $k $l $data0($i:$j,$k:$l)"
	      incr count
	      [namespace parent]::ProgressBar $count $maxkeys
	      # Calculate max and min
	      if {$z} {
		set min0 $data0($i:$j,$k:$l)
		set max0 $data0($i:$j,$k:$l)
		set z 0
	      }
	      if {$data0($i:$j,$k:$l) > $max0} {
		set max0 $data0($i:$j,$k:$l)
	      }
	      if {$data0($i:$j,$k:$l) < $min0} {
		set min0 $data0($i:$j,$k:$l)
	      }
	    }
	  }
	}
      }
    }
    
    # Create keys and values variables
    set keys [lsort -dictionary [array names data0]]
    foreach key $keys {
      lappend vals $data0($key)
    }

    [namespace parent]::TransformData $self
    
    return 0
  }
}
