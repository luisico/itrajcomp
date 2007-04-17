# dist.tcl
#    Functions to calculate the distance matrix.


proc itrajcomp::calc_dist {self} {
  tk_messageBox -title "Warning " -message "Not ready yet" -parent .itrajcomp
  return -1

  set byres ${self}::byres
  set normalize ${self}::normalize

  # Object format
  if {$byres} {
    set ${self}::graphtype "residues"
  } else {
    set ${self}::graphtype "atoms"
  }
  set ${self}::format_data "%8.4f"
  set ${self}::format_key  "%3d %3s"

  if {$normalize == "none"} {
    set ${self}::format_scale "%4.1f"
  } else {
    set ${self}::format_scale "%4.2f"
  }
  set ${self}::rep_style1  "CPK"  
  
  set mol1 [set ${self}::mol1]
  set mol2 [set ${self}::mol2]
  set sel1 [set ${self}::sel1]
  set sel2 [set ${self}::sel2]
  # Check number of atoms in selections, and combined list of molecules
  set mol_all [[namespace parent]::CheckNatoms $mol1 $sel1 $mol2 $sel2]
  if {$mol_all == -1} {
    return -code return
  }
  
  # Define segments
  [namespace current]::DefineSegments $self


  # Precalculate coordinates of each segment
  # Get coordinates for all molecules and frames
  if {$byres} {
    foreach r $segments {
      foreach i $mol_all {
	set s1 [atomselect $i "residue $r and ($sel1)"]
	#puts "DEBUG: mol $i"
	foreach j [lindex $frame1 [lsearch -exact $mol_all $i]] {
	  $s1 frame $j
	  #puts "DEBUG: frame $j"
	  lappend coor($i:$j) [measure center $s1]
	}
      }
    }
  } else {
    foreach i $mol_all {
      set s1 [atomselect $i $sel1]
      #puts "DEBUG: mol $i"
      foreach j [lindex $frame1 [lsearch -exact $mol_all $i]] {
	$s1 frame $j
	#puts "DEBUG: frame $j"
	set coor($i:$j) [$s1 get {x y z}]
      }
    }
  }

  if {$normalize != "none"} {
    [namespace current]::Normalize $normalize $self
  }

}


proc itrajcomp::calc_dist_prehook1 {self} {
}

proc itrajcomp::calc_dist_prehook2 {self} {
}

proc itrajcomp::calc_dist_hook {self} {
  namespace eval [namespace current]::${self}:: {
    set dist {}
    foreach m $mol_all {
      foreach f [lindex $frame1 [lsearch -exact $mol_all $m]] {
	set coor1 [lindex $coor($m:$f) $reg1]
	set coor2 [lindex $coor($m:$f) $reg2]
	lappend dist [veclength [vecsub $coor2 $coor1]]
      }
    }
    return [vecmean $dist]
  }
}


proc itrajcomp::calc_dist_options {} {
  # Options for dist
  variable calc_dist_options
  variable dist_vars [list byres normalize]
  variable byres 1
  variable normalize "none"

  checkbutton $calc_dist_options.byres -text "byres" -variable [namespace current]::byres
  pack $calc_dist_options.byres -side top -anchor nw

  frame $calc_dist_options.norm
  pack $calc_dist_options.norm -side top -anchor nw
  label $calc_dist_options.norm.l -text "Normalization:"
  pack $calc_dist_options.norm.l -side left
  foreach entry [list none exp expmin minmax] {
    radiobutton $calc_dist_options.norm.$entry -text $entry -variable [namespace current]::normalize -value $entry
    pack $calc_dist_options.norm.$entry -side left
  }
}


proc itrajcomp::calc_dist_options_update {} {
  # Update options gui
  [namespace current]::Samemols on
}
