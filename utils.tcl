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


proc itrajcomp::AddRep2 {i j k l sel} {
  # Add a pair (matrix cell) of representation to vmd
  mol rep Lines 2
  mol selection $sel
  mol addrep $i
  set name1 [mol repname $i [expr [molinfo $i get numreps]-1]]
  mol drawframes $i [expr [molinfo $i get numreps]-1] $j
  mol addrep $k
  mol drawframes $k [expr [molinfo $k get numreps]-1] $l
  set name2 [mol repname $k [expr [molinfo $k get numreps]-1]]
  #puts "create $name1:$name2"
  return "$name1:$name2"
}


proc itrajcomp::DelRep1 {name i} {
  # Delete 1 representation from vmd
  mol delrep [mol repindex $i $name] $i
}


proc itrajcomp::DelRep2 {name i k} {
  # Delete a pair (matrix cell) of representations from vmd
  mol delrep [mol repindex $i [lindex $name 0]] $i
  mol delrep [mol repindex $k [lindex $name 1]] $k
  #puts "delete [lindex $name 0]:[lindex $name 1]"
}


proc itrajcomp::ParseMols { mols idlist {sort 1} } {
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
  
  for {set i 0} {$i < [llength $mols]} {incr i} {
    if {[lsearch [molinfo list] [lindex $mols $i]] > -1} {
      lappend valid_mols [lindex $mols $i]
    }
  }

  return $valid_mols
}  


proc itrajcomp::ParseFrames { frames mols skip idlist } {
  # Parse frame selection
  set final {}
  foreach mol $mols {
    set list {}
    if {$frames == "all"} {
      for {set n 0} {$n < [molinfo $mol get numframes]} {incr n} {
	lappend list $n
      }
    } elseif {$frames == "cur"} {
      set list [molinfo $mol get frame]
    } elseif {$frames == "id"} {
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
    } else {
      set nframes [molinfo $mol get numframes]
      set list $frames
      foreach f $list {
	if {$f >= $nframes} {
	  puts "Frame ref $f for mol $mol is out of range"
	  return -code return
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
    lappend final $list
  }
  return $final
}


proc itrajcomp::CombineMols { args } {
  # Return a list of unique molecules
  set mols {}
  foreach i $args {
    foreach j $i {
      lappend mols $j
    }
  }
  return [lsort -unique $mols]
}


proc itrajcomp::Mean { values } {
  # Calculate the mean of a list of values
  set tot 0.0
  foreach n $values {
    set tot [expr $tot+$n]
  }
  set num [llength $values]
  set mean [expr $tot/$num]
  return $mean
}


proc itrajcomp::GetKeys { rms_values sort mol_ref mol_tar } {
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


proc itrajcomp::wlist {{w .}} {
  # Return a list of TKwidgets
   set list [list $w]
   foreach widget [winfo children $w] {
     set list [concat $list [wlist $widget]]
   }
   return $list
}


proc itrajcomp::ColorScale {max min i l} {
  # Color scale transformation
  if {$max == 0} {
    set max 1.0
  }

  set h [expr 2.0/3.0]
#  set l 1.0
  set s 1.0

  lassign [hls2rgb [expr ($h - $h*$i/$max)] $l $s] r g b

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


proc itrajcomp::CheckNatoms {mol1 sel1 {mol2 ""} {sel2 ""}} {
  # Check same number of atoms in two selections
  foreach i $mol1 {
    set natoms($i) [[atomselect $i $sel1 frame 0] num]
  }
  
  if {$mol2 != ""} {
    foreach i $mol2 {
      set natoms($i) [[atomselect $i $sel2 frame 0] num]
    }
    set mol_all [[namespace current]::CombineMols $mol1 $mol2]
  } else {
    set mol_all $mol1
  }

  foreach i $mol_all {
    foreach j $mol_all {
      if {$i < $j} {
	if {$natoms($i) != $natoms($j)} {
	  tk_messageBox -title "Warning " -message "Selections differ for molecules $i ($natoms($i)) and $j ($natoms($j))" -parent .itrajcomp
	  return -1
	}
      }
    }
  }
  
#  return $natoms([lindex $mol_all 0])
  return $mol_all
}


proc itrajcomp::ParseKey {self key} {
  # Parse a key to get mol, frame and selection back
  set graphtype [set ${self}::graphtype]
  set indices [split $key :]

  switch $graphtype {
    frame {
      lassign $indices m f
      set p [set ${self}::p]
      set s [[namespace current]::ParseSel [$p.l.l.rep.disp1.e get 1.0 end] ""]
    }
    atom {
      set m [lindex [set ${self}::mol_all] 0]
      set f [join [set ${self}::frame1] " "]
      set s "index [lindex $indices 0]"
    }
    residue {
      set m [lindex [set ${self}::mol_all] 0]
      set f [join [set ${self}::frame1] " "]
      set p [set ${self}::p]
      set extra [[namespace current]::ParseSel [$p.l.l.rep.disp1.e get 1.0 end] ""]
      set s "residue [lindex $indices 0] and ($extra)"
      puts $s
    }
  }

  return [list $m $f $s]
}



proc itrajcomp::Normalize {{type "expmin"} self} {
  # Normalize data
  array set data [array get ${self}::data]
  set keys [array names data]
  set min [set ${self}::min]
  set max [set ${self}::max]
  
  # minmax: min gets 0, max gets 1
  # exp: exponential
  # expmin: exponential shifted
  switch $type {
    minmax {
      set minmax [expr $max - $min]
      foreach key $keys {
	set data($key) [expr ($data($key)-$min) / $minmax]
      }
    }
    exp {
      foreach key $keys {
	set data($key) [expr 1 - exp(-$data($key))]
      }
    }
    expmin {
      foreach key $keys {
	set data($key) [expr 1 - exp(-($data($key)-$min))]
      }
    }
  }

  set ${self}::min 0
  set ${self}::max 1
  array set ${self}::data [array get data]

  return
}