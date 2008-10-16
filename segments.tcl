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
    variable map_active
    variable rep_active
    variable rep_list
    variable rep_num
    variable colors
    variable colors_act
    variable connect_lines

    $plot delete all
    set nsegments [llength $segments(number)]

    foreach key $keys {
      lassign [split $key ,:] i j k l
      set part2($i) $j
      set part2($k) $l
    }

    set maxkeys [llength $keys]
    set count 0
    
    set offx 0
    set offy 0
    set width 0
    for {set i 0} {$i < $nsegments} {incr i} {
      set key1 "[lindex $segments(number) $i]:$part2([lindex $segments(number) $i])"
      set rep_list($key1) {}
      set rep_num($key1) 0
      set offy 0
      for {set k 0} {$k < $nsegments} {incr k} {
        set key2 "[lindex $segments(number) $k]:$part2([lindex $segments(number) $k])"
        set rep_list($key2) {}
        set rep_num($key2) 0
        set key "$key1,$key2"
        #puts -nonewline "$key "
        if {![info exists data($key)]} {
          #puts ""
          continue
        }
        set x [expr {($i+$offx)*($grid+$width)}]
        set y [expr {($k+$offy)*($grid+$width)}]
        set map_active($key) 0
        set colors($key) [[namespace parent]::ColorScale $data($key) $max $min 1.0]
        set colors_act($key) [[namespace parent]::ColorScale $data($key) $max $min 0.40 1.0]
        #puts "-> $x $offx           $k $l - > $y $offy     = $data($key)    $color"
        $plot create rectangle $x $y [expr {$x+$grid}] [expr {$y+$grid}] -fill $colors($key) -outline $colors($key) -tag $key -width $width
        
        $plot bind $key <Enter>                    "[namespace parent]::ShowPoint $self $key $data($key) 1"
        $plot bind $key <B1-ButtonRelease>      	 "[namespace parent]::MapPoint $self $key $data($key)" 
        $plot bind $key <B2-ButtonRelease>         "[namespace parent]::ExplorePoint $self $key" 
        $plot bind $key <Shift-B1-ButtonRelease>   "[namespace parent]::MapCluster3 $self $key  0  0"
        $plot bind $key <Shift-B2-ButtonRelease>   "[namespace parent]::MapCluster3 $self $key  0 -1"
        $plot bind $key <Shift-B3-ButtonRelease>   "[namespace parent]::MapCluster3 $self $key  0  1"
        $plot bind $key <Control-B1-ButtonRelease> "[namespace parent]::MapCluster2 $self $key  0  0"
        $plot bind $key <Control-B2-ButtonRelease> "[namespace parent]::MapCluster2 $self $key -1  0"
        $plot bind $key <Control-B3-ButtonRelease> "[namespace parent]::MapCluster2 $self $key  1  0"

        incr count
        [namespace parent]::ProgressBar $count $maxkeys
      }
      set offy [expr {$offy+$k}]
      
    }
    set offx [expr {$offx+$i}]
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
    
    set nreg [llength $segments(number)]
    # Calculate max numbers of iterations
    set maxkeys [expr {($nreg*$nreg+$nreg)/2}]
    
    # Calculate min max later, when tranforming data0 -> data
    set count 0
    for {set reg1 0} {$reg1 < $nreg} {incr reg1} {
      set i [lindex $segments(number) $reg1]
      set j [lindex $segments(name) $reg1]
      set key1 "$i:$j"
      #-> prehook1
      [namespace parent]::calc_$opts(type)_prehook1 $self
      for {set reg2 0} {$reg2 < $nreg} {incr reg2} {
        set k [lindex $segments(number) $reg2]
        set l [lindex $segments(name) $reg2]
        set key2 "$k:$l"
        #-> prehook2
        [namespace parent]::calc_$opts(type)_prehook2 $self
        if {[info exists data0($key2,$key1)]} {
          continue
        } else {
          #-> hook
          set data0($key1,$key2) [[namespace parent]::calc_$opts(type)_hook $self]
          #puts "$i $k , $key1 $key2 , $data0($key1,$key2)"
          incr count
          [namespace parent]::ProgressBar $count $maxkeys
        }
      }
    }

    # Create keys and values variables
    set keys [lsort -dictionary [array names data0]]
    foreach key $keys {
      lappend vals $data0($key)
    }

    # Create data set for the graph
    [namespace parent]::PrepareData $self

    return 0
  }
}


proc itrajcomp::DefineSegments {self} {
  namespace eval [namespace current]::${self}:: {
    switch $opts(segment) {
      byres {
        set segments(number) [lsort -unique -integer [[atomselect [lindex $sets(mol_all) 0] $sets(sel1)] get residue]]
        set segments(name) {}
        foreach r $segments(number) {
          lappend segments(name) [string totitle [lindex [[atomselect [lindex $sets(mol_all) 0] "residue $r"] get resname] 0]]
        }
      }
      byatom {
        set segments(number) [[atomselect [lindex $sets(mol_all) 0] $sets(sel1)] get index]
        set segments(name) [[atomselect [lindex $sets(mol_all) 0] $sets(sel1)] get name]
      }
    }
  }
}


proc itrajcomp::CoorSegments {self} {
  namespace eval [namespace current]::${self}:: {
    switch $opts(segment) {
      byres {
        foreach r $segments(number) {
          #puts "DEBUG: seg $r"
          foreach i $sets(mol_all) {
            set s1 [atomselect $i "residue $r and ($sets(sel1))"]
            #puts "DEBUG: mol $i"
            foreach j [lindex $sets(frame1) [lsearch -exact $sets(mol_all) $i]] {
              $s1 frame $j
              #puts "DEBUG: frame $j"
              lappend coor($i:$j) [measure center $s1]
            }
          }
        }
      }
      byatom {
        foreach i $sets(mol_all) {
          set s1 [atomselect $i $sets(sel1)]
          #puts "DEBUG: mol $i"
          foreach j [lindex $sets(frame1) [lsearch -exact $sets(mol_all) $i]] {
            $s1 frame $j
            #puts "DEBUG: frame $j"
            set coor($i:$j) [$s1 get {x y z}]
            #puts "DEBUG: coor $coor($i:$j)"
          }
        }
      }
    }
    #puts [array get coor]
  }
}
