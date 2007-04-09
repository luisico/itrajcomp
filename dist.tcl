# dist.tcl
#    Functions to calculate the distance matrix.


proc itrajcomp::dist { self } {
    
  # Access object variables
  foreach v [[namespace current]::Objvars $self] {
    #puts "$v --> [set ${self}::$v]"
    set $v [set ${self}::$v]
  }
  #puts "---------------"
  #puts [info vars]
  
  # Object format
  if {$byres} {
    set graphtype "residue"
    set header1   "residue"
    set header2   "resname"
  } else {
    set graphtype "atom"
    set header1   "index"
    set header2   "name"
  }
  set format_data "%8.4f"
  set format_key  "%3d %3s"
  if {$normalize == "none"} {
    set format_scale "%4.1f"
  } else {
    set format_scale "%4.2f"
  }
  set rep_style1  "CPK"
  
  
  # Check number of atoms in selections, and combined list of molecules
  set mol_all [[namespace current]::CheckNatoms $mol1 $sel1]
  if {$mol_all == -1} {
    return -code return
  }

  if {$byres} {
    set regions [lsort -unique -integer [[atomselect [lindex $mol_all 0] $sel1] get residue]]
    set names {}
    foreach r $regions {
      lappend names [lindex [[atomselect [lindex $mol_all 0] "residue $r"] get resname] 0]
      
      # Get coordinates for all molecules and frames
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
    set regions [[atomselect [lindex $mol_all 0] $sel1] get index]
    set names [[atomselect [lindex $mol_all 0] $sel1] get name]

    # Get coordinates for all molecules and frames
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

  set nreg [llength $regions]
  # Calculate max numbers of iterations
  set maxkeys [expr ($nreg*$nreg+$nreg)/2]
  
  
  # Calculate distance matrix
  set z 1
  set count 0
  for {set reg1 0} {$reg1 < $nreg} {incr reg1} {
    set i [lindex $regions $reg1]
    set j [lindex $names $reg1]
    set key1 "$i:$j"
    for {set reg2 0} {$reg2 < $nreg} {incr reg2} {
      set k [lindex $regions $reg2]
      set l [lindex $names $reg2]
      set key2 "$k:$l"
      if {[info exists data($key2,$key1)]} {
	continue
      } else {
	set dist {}
	foreach m $mol_all {
	  foreach f [lindex $frame1 [lsearch -exact $mol_all $m]] {
	    set coor1 [lindex $coor($m:$f) $reg1]
	    set coor2 [lindex $coor($m:$f) $reg2]
	    lappend dist [veclength [vecsub $coor2 $coor1]]
	  }
	}
	set data($key1,$key2) [vecmean $dist]
	#puts "$i $k , $key1 $key2 , $data($key1,$key2)"
	#puts "coor1: $coor1"
	#puts "coor2: $coor2"
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
  
  set keys [lsort -dictionary [array names data]]
  
  # Set object variables
  foreach v [[namespace current]::Objvars $self] {
    set ${self}::$v  [set $v]
    #puts "$v --->\t[set ${self}::$v]"
  }
  array set ${self}::data [array get data]

  if {$normalize != "none"} {
    [namespace current]::Normalize $normalize $self
  }

  foreach key $keys {
    lappend vals [set ${self}::data($key)]
  }

  return 0
}


proc itrajcomp::dist_options {} {
  # Options for dist
  variable dist_options
  variable dist_vars [list byres normalize]
  variable byres 1
  variable normalize "none"

  checkbutton $dist_options.byres -text "byres" -variable [namespace current]::byres
  pack $dist_options.byres -side top -anchor nw

  frame $dist_options.norm
  pack $dist_options.norm -side top -anchor nw
  label $dist_options.norm.l -text "Normalization:"
  pack $dist_options.norm.l -side left
  foreach entry [list none exp expmin minmax] {
    radiobutton $dist_options.norm.$entry -text $entry -variable [namespace current]::normalize -value $entry
    pack $dist_options.norm.$entry -side left
  }
}


proc itrajcomp::dist_options_update {} {
  # Update options gui
  [namespace current]::Samemols on
}
