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

# covar.tcl
#    Functions to calculate the covariance matrix.


proc itrajcomp::covar { self } {
    
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

  set not1frame 1
  foreach i $mol_all {
    if {[molinfo $i get numframes] == 1} {
      set not1frame 0
      break
    }
  }
  
  if {$frame1_def == "all" && $not1frame == 1} {
    set count 0
    foreach i $mol_all {
      set nframes [molinfo $i get numframes]
      set temp [measure rmsf [atomselect $i $sel1] first 0 last [expr $nframes -1] step 1]
      for {set n 0} {$n < [llength $temp]} {incr n} {
	lset temp $n [expr [lindex $temp $n] * [lindex $temp $n] * $nframes]
      }
      if {$count eq 0} {
	set rmsf $temp
      } else {
	set rmsf [vecadd $rmsf $temp]
      }
      set count [expr $count + $nframes]
    }
    set factor [expr 1./double($count)]
    for {set n 0} {$n < [llength $rmsf]} {incr n} {
      lset rmsf $n [expr sqrt([lindex $rmsf $n] * $factor)]
    }
    #puts "DEBUG: rmsf $rmsf"
    
  } else {
    # Calculate rmsf for each atom in one run
    set count 0
    set a {}
    set b {}
    foreach i $mol_all {
      set s1 [atomselect $i $sel1]
      #puts "DEBUG: mol $i"
      foreach j [lindex $frame1 [lsearch -exact $mol_all $i]] {
	$s1 frame $j
	#puts "DEBUG: frame $j"
	set coor [$s1 get {x y z}]
	if {$count eq 0} {
	  set b $coor
	  set a $b
	  for {set n 0} {$n < [llength $a]} {incr n} {
	    lset a $n [vecdot [lindex $coor $n] [lindex $coor $n]]
	  }
	} else {
	  for {set n 0} {$n < [llength $a]} {incr n} {
	    lset b $n [vecadd [lindex $b $n] [lindex $coor $n]]
	    lset a $n [vecadd [lindex $a $n] [vecdot [lindex $coor $n] [lindex $coor $n]]]
	  }
	}
	#puts "DEBUG: count $count"
	#puts "DEBUG: c $coor"
	#puts "DEBUG: a $a"
	#puts "DEBUG: b $b"
	incr count
      }
    }
    set factor [expr 1./double($count)]
    set rmsf $a
    for {set n 0} {$n < [llength $b]} {incr n} {
      lset b $n [vecscale [lindex $b $n] $factor]
      lset a $n [vecscale [lindex $a $n] $factor]
      lset rmsf $n [expr sqrt([lindex $a $n]-[veclength2 [lindex $b $n]])]
    }
    #puts "DEBUG:-------"
    #puts "DEBUG: aa $a"
    #puts "DEBUG: bb $b"
    #puts "DEBUG: rmsf $rmsf"
    #puts "DEBUG: meas [measure rmsf $s1 first 0 last [expr [molinfo $i get numframes] -1] step 1]"
  }
  
  if {$byres} {
    set regions [lsort -unique -integer [[atomselect [lindex $mol_all 0] $sel1] get residue]]
    set names {}
    set temp {}
    set start 0
    foreach r $regions {
      lappend names [lindex [[atomselect [lindex $mol_all 0] "residue $r"] get resname] 0]
      set end [expr $start + [[atomselect [lindex $mol_all 0] "residue $r and ($sel1)"] num] -1]
      lappend temp [vecmean [lrange $rmsf $start $end]]
      set start [expr $end + 1]
    }
    set rmsf $temp
  } else {
    set regions [[atomselect [lindex $mol_all 0] $sel1] get index]
    set names [[atomselect [lindex $mol_all 0] $sel1] get name]
  }
  
  set nreg [llength $regions]
  # Calculate max numbers of iterations
  set maxkeys [expr ($nreg*$nreg+$nreg)/2]
  
  
  # Calculate covariance matrix
  set z 1
  set count 0
  for {set reg1 0} {$reg1 < $nreg} {incr reg1} {
    set i [lindex $regions $reg1]
    set j [lindex $names $reg1]
    set key1 "$i:$j"
    set rmsf1 [lindex $rmsf $reg1]
    for {set reg2 0} {$reg2 < $nreg} {incr reg2} {
      set k [lindex $regions $reg2]
      set l [lindex $names $reg2]
      set key2 "$k:$l"
      set rmsf2 [lindex $rmsf $reg2]
      if {[info exists data($key2,$key1)]} {
	continue
      } else {
	set data($key1,$key2) [expr $rmsf1*$rmsf2]
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

