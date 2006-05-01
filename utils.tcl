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


package provide itrajcomp 1.0

proc itrajcomp::AddRep1 {i j sel style color} {
  variable w
  mol rep $style
  mol selection $sel
  mol color $color
  mol addrep $i
  set name1 [mol repname $i [expr [molinfo $i get numreps]-1]]
  mol drawframes $i [expr [molinfo $i get numreps]-1] $j
  return $name1
}


proc itrajcomp::AddRep2 {i j k l sel} {
  variable w
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
  mol delrep [mol repindex $i $name] $i
}


proc itrajcomp::DelRep2 {name i k} {
  mol delrep [mol repindex $i [lindex $name 0]] $i
  mol delrep [mol repindex $k [lindex $name 1]] $k
  #puts "delete [lindex $name 0]:[lindex $name 1]"
}


proc itrajcomp::ParseMols { mols idlist {sort 1} } {
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
  set mols {}
  foreach i $args {
    foreach j $i {
      lappend mols $j
    }
  }
  return [lsort -unique $mols]
}


proc itrajcomp::Mean { values } {
  set tot 0.0
  foreach n $values {
    set tot [expr $tot+$n]
  }
  set num [llength $values]
  set mean [expr $tot/$num]
  return $mean
}


proc itrajcomp::GetKeys { rms_values sort mol_ref mol_tar } {
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
  set active {}
  foreach i [molinfo list] {
    if { [molinfo $i get active] } {
      lappend active $i
    }
  }
  return $active
}


proc itrajcomp::ParseSel {orig selmod} {
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


proc itrajcomp::wlist {{W .}} {
   set list [list $W]
   foreach w [winfo children $W] {
     set list [concat $list [wlist $w]]
   }
   return $list
}


proc itrajcomp::ColorScale {max min i l} {
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
      set f 0:[expr [molinfo $m get numframes]-1]
      set s "index [lindex $indices 0]"
    }
    residue {
      set m [lindex [set ${self}::mol_all] 0]
      set f 0:[expr [molinfo $m get numframes]-1]
      set p [set ${self}::p]
      set extra [[namespace current]::ParseSel [$p.l.l.rep.disp1.e get 1.0 end] ""]
      set s "residue [lindex $indices 0] and ($extra)"
      puts $s
    }
  }

  return [list $m $f $s]
}