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

# utils.tcl
#    Utility functions.


# TODO: most of procs here are vmd related, rename to vmd?
proc itrajcomp::AddRep1 {i j sel style color} {
  # Add 1 representation to vmd
  mol rep $style
  mol selection $sel
  mol color $color
  mol addrep $i
  set name1 [mol repname $i [expr [molinfo $i get numreps]-1]]
  mol drawframes $i [expr [molinfo $i get numreps]-1] $j
  return $name1
}


proc itrajcomp::DelRep1 {reps} {
  # Delete 1 representation from vmd
  foreach r $reps {
    lassign [split $r :] i name
    mol delrep [mol repindex $i $name] $i
  }
}


proc itrajcomp::ParseMols {mols idlist {sort 1} } {
  # Parse molecule selection
  if {$mols eq "id"} {
    set mols $idlist
  }
  if {[lsearch $mols "all"] > -1} {
    set mols [molinfo list]
  }
  if {[set indices [lsearch -all $mols "top"]] > -1} {
    foreach i $indices {
      lset mols $i [molinfo top]
    }
  }
  if {[lsearch $mols "act"] > -1} {
    set mols [[namespace current]::GetActive]
  }
  if {[set indices [lsearch -all $mols "to"]] > -1} {
    foreach i $indices {
      set a [expr [lindex $mols [expr $i-1]] + 1]
      set b [expr [lindex $mols [expr $i+1]] - 1]
      set mols [lreplace $mols $i $i]
      for {set r $b} {$r >= $a} {set r [expr $r-1]} {
	set mols [linsert $mols $i $r]
      }
    }
  }
  if {$sort} {
    set mols [lsort -unique -integer $mols]
  }
  
  set invalid_mols {}
  for {set i 0} {$i < [llength $mols]} {incr i} {
    if {[lsearch [molinfo list] [lindex $mols $i]] > -1} {
      lappend valid_mols [lindex $mols $i]
    } else {
      lappend invalid_mols [lindex $mols $i]
    }
  }

  if {[llength $invalid_mols]} {
    tk_messageBox -title "Warning " -message "The following mols are not available: $invalid_mols" -parent .itrajcomp
    return -1
  } else {
    return $valid_mols
  }
}  


proc itrajcomp::ParseFrames {def mols skip idlist} {
  # Parse frame selection
  # Creates a list of lists (one for each mol)
  set frames {}
  foreach mol $mols {
    set list {}
    set nframes [molinfo $mol get numframes]
    if {$def == "all"} {
      for {set n 0} {$n < $nframes} {incr n} {
	lappend list $n
      }
    } elseif {$def == "cur"} {
      set list [molinfo $mol get frame]
    } elseif {$def == "id"} {
      if {[set indices [lsearch -all $idlist "to"]] > -1} {
	foreach i $indices {
	  set a [expr [lindex $idlist [expr $i-1]] + 1]
	  set b [expr [lindex $idlist [expr $i+1]] - 1]
	  set idlist [lreplace $idlist $i $i]
	  for {set r $b} {$r >= $a} {set r [expr $r-1]} {
	    set idlist [linsert $idlist $i $r]
	  }
	}
      }
      set list $idlist

      # Check frames are within mol range
      foreach f $list {
	if {$f >= $nframes} {
	  tk_messageBox -title "Warning " -message "Frame $f is out of range for mol $mol" -parent .itrajcomp
	  return -1
	}
      }
    }

    if {$skip} {
      set result {}
      set s [expr $skip+1]
      for {set i 0} {$i < [llength $list]} {incr i $s} {
	lappend result [lindex $list $i]
      }
      set list $result
    }

    lappend frames $list
  }

  return $frames
}


proc itrajcomp::SplitFrames {frames} {
  # Split frames for molecules
  set text {}
  for {set i 0} {$i < [llength $frames]} {incr i} {
    lappend text "\[[[namespace current]::Range [lindex $frames $i]]\]"
  }
  return [join $text]
}


proc itrajcomp::Range {numbers} {
  # Convert list of numbers range to a simple string

  set numbers [lsort -unique -integer $numbers]
  set start 0
  set end 0
  for {set i 1} {$i < [llength $numbers]} {incr i} {
    set a [lindex $numbers [expr $i-1]]
    set b [lindex $numbers $i]
    if { [expr $a+1] == $b } {
      set end $i
    } else {
      if {$start != $end} {
	lappend results "[lindex $numbers $start]-$a"
      } else {
	lappend results $a
      }
      set start $i
    }
  }
  if {[lindex $numbers $start] != $b} {
    lappend results "[lindex $numbers $start]-$b"
  } else {
    lappend results $b
  }
  return [join $results]
}


proc itrajcomp::CombineMols {args} {
  # Return a list of unique molecules
  set mols {}
  foreach i $args {
    foreach j $i {
      lappend mols $j
    }
  }
  return [lsort -unique $mols]
}


proc itrajcomp::Mean {values} {
  # Calculate the mean of a list of values
  set tot 0.0
  foreach n $values {
    set tot [expr $tot+$n]
  }
  set num [llength $values]
  set mean [expr $tot/$num]
  return $mean
}


proc itrajcomp::GetKeys {rms_values sort mol_ref mol_tar} {
  # Not used, remove?
  upvar $rms_values values
  
  if {$mol_ref == "all" && $mol_tar == "all"} {
    set sort 1
  }

  if {$sort} {
    set skeys [lsort -dictionary [array names values]]
  } else {
    set nref [ParseMols mol_ref 0]
    set ntar [ParseMols mol_tar 0]
    set skeys {}
    foreach i $mol_ref {
      foreach j $mol_tar {
	foreach k [lsort -dictionary [array names values "$i:*,$j:*"]] {
	  lappend skeys $k
	}
      }
    }
  }
  return $skeys
}


proc itrajcomp::GetActive {} {
  # Identify the active molecule
  set active {}
  foreach i [molinfo list] {
    if { [molinfo $i get active] } {
      lappend active $i
    }
  }
  return $active
}


proc itrajcomp::ParseSel {orig selmod} {
  # Parse a selection text
  regsub -all "\#.*?\n" $orig  ""  temp1
  regsub -all "\n"      $temp1 " " temp2
  regsub -all " *$"     $temp2 ""  temp3
  if {$temp3 == "" } {
    set temp3 "all"
  }
  switch -exact $selmod {
    tr {
      append sel "($temp3) and name CA"
    }
    bb {
      append sel "($temp3) and name C CA N"
    }
    sc {
      append sel "($temp3) and sidechain"
    }
    no -
    default {
      append sel $temp3
    }
  }
  return $sel
}


proc itrajcomp::CheckNatoms {self} {
  # Check same number of atoms in two selections
  array set sets [array get ${self}::sets]
  
  foreach i $sets(mol1) {
    set natoms($i) [[atomselect $i $sets(sel1) frame 0] num]
  }
  
  if {$sets(mol2) != ""} {
    foreach i $sets(mol2) {
      set n [[atomselect $i $sets(sel2) frame 0] num]
      if {[info exists natoms($i)] && $natoms($i) != $n} {
	tk_messageBox -title "Warning " -message "Difference in atom selection between Set1 ($natoms($i)) and Set2 ($n) for molecule $i" -parent .itrajcomp
	  return -1
      }
    }
  }

  foreach i $sets(mol_all) {
    foreach j $sets(mol_all) {
      if {$i < $j} {
	if {$natoms($i) != $natoms($j)} {
	  tk_messageBox -title "Warning " -message "Selections differ for molecules $i ($natoms($i)) and $j ($natoms($j))" -parent .itrajcomp
	  return -1
	}
      }
    }
  }
  
  return 1
}


proc itrajcomp::ParseKey {self key} {
  # Parse a key to get mol, frame and selection back
  array set graph_opts [array get ${self}::graph_opts]
  array set opts [array get ${self}::opts]
  array set sets [array get ${self}::sets]
  set indices [split $key :]

  switch $graph_opts(type) {
    frames {
      lassign $indices m f
      set tab_rep [set ${self}::tab_rep]
      set s [[namespace current]::ParseSel [$tab_rep.disp1.sel.e get 1.0 end] ""]
    }
    segments {
      switch $opts(segment) {
	byres {
	  set m [join [set ${self}::sets(mol_all)] " "]
	  set f [join [set ${self}::sets(frame1)] " "]
	  set tab_rep [set ${self}::tab_rep]
	  set extra [[namespace current]::ParseSel [$tab_rep.disp1.sel.e get 1.0 end] ""]
	  set s "residue [lindex $indices 0] and ($extra)"
	}
	byatom {
	  set m [join [set ${self}::sets(mol_all)] " "]
	  set f [join [set ${self}::sets(frame1)] " "]
	  set s "index [lindex $indices 0]"
	}
      }
    }
  }

  return [list $m $f $s]
}


proc itrajcomp::TransformData {self {type "copy"} {graph 0}} {
  # Source data
  if {$type == "copy" || [set ${self}::transform_source] == 0} {
    array set data0 [array get ${self}::data0]
    set keys [array names data0]
    set min0 [set ${self}::min0]
    set max0 [set ${self}::max0]
  } else {
    array set data0 [array get ${self}::data]
    set keys [array names data0]
    set min0 [set ${self}::min]
    set max0 [set ${self}::max]
  }

  switch $type {
    copy {
      set min $min0
      set max $max0
      array set data [array get data0]
    }
    inverse {
      set z 1
      set min 0
      set max 0
      foreach key $keys {
	if {$data0($key) != 0} {
	  set data($key) [expr 1.0/$data0($key)]
	} else {
	  set data($key) $data0($key)
	}
	
	# Calculate max and min
	if {$z} {
	  set min $data($key)
	  set max $data($key)
	  set z 0
	}
	if {$data($key) > $max} {
	  set max $data($key)
	}
	if {$data($key) < $min} {
	  set min $data($key)
	}
      }
    }
    norm_minmax {
      set minmax [expr $max0 - $min0]
      foreach key $keys {
	set data($key) [expr ($data0($key)-$min0) / $minmax]
      }
      set min 0
      set max 1
    }
    norm_exp {
      foreach key $keys {
	set data($key) [expr 1 - exp(-$data0($key))]
      }
      set min 0
      set max 1
    }
    norm_expmin {
      foreach key $keys {
	set data($key) [expr 1 - exp(-($data0($key)-$min0))]
      }
      set min 0
      set max 1
    }
  }

  # Send back to object
  set ${self}::min $min
  set ${self}::max $max
  array set ${self}::data [array get data]
  # TODO: vals should also be updated? used in save and load, mostly

  # Update plot
  if {$graph == 1} {
    # TODO: only works with frames (not segments)
    [namespace current]::UpdateGraph $self
    #[namespace current]::GraphFrames $self
  }

  return
}


proc itrajcomp::wlist {{w .}} {
  # Return a list of TKwidgets
   set list [list $w]
   foreach widget [winfo children $w] {
     set list [concat $list [wlist $widget]]
   }
   return $list
}


proc itrajcomp::ColorScale {val max min {s 1.0} {l 1.0}} {
  # Color scale transformation
  if {$max == 0} {
    set max 1.0
  }

  set h [expr 2.0/3.0]
  #set l 1.0 luminosity
  #set s .5 saturation

  lassign [hls2rgb [expr ($h - $h*($val-$min)/($max-$min))] $l $s] r g b

  set r [expr int($r*255)]
  set g [expr int($g*255)]
  set b [expr int($b*255)]
  return [format "#%.2X%.2X%.2X" $r $g $b]
}


proc itrajcomp::hls2rgb {h l s} {
  # Transform from hls to rgb colors
  #http://wiki.tcl.tk/666
  # h, l and s are floats between 0.0 and 1.0, ditto for r, g and b
  # h = 0   => red
  # h = 1/3 => green
  # h = 2/3 => blue
  
  set h6 [expr {($h-floor($h))*6}]
  set r [expr {  $h6 <= 3 ? 2-$h6
		 : $h6-4}]
  set g [expr {  $h6 <= 2 ? $h6
		 : $h6 <= 5 ? 4-$h6
		 : $h6-6}]
  set b [expr {  $h6 <= 1 ? -$h6
		 : $h6 <= 4 ? $h6-2
		 : 6-$h6}]
  set r [expr {$r < 0.0 ? 0.0 : $r > 1.0 ? 1.0 : double($r)}]
  set g [expr {$g < 0.0 ? 0.0 : $g > 1.0 ? 1.0 : double($g)}]
  set b [expr {$b < 0.0 ? 0.0 : $b > 1.0 ? 1.0 : double($b)}]
  
  set r [expr {(($r-1)*$s+1)*$l}]
  set g [expr {(($g-1)*$s+1)*$l}]
  set b [expr {(($b-1)*$s+1)*$l}]
  return [list $r $g $b]
}
