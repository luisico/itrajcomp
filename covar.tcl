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


proc itrajcomp::calc_covar {self} {
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
    set format_scale "%4.1f"
  } else {
    set format_scale "%4.2f"
  }
  set ${self}::rep_style1  "CPK"  
  
  set mol1 [set ${self}::mol1]
  set mol2 [set ${self}::mol2]
  set sel1 [set ${self}::sel1]
  set sel2 [set ${self}::sel2]
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
    set segments [lsort -unique -integer [[atomselect [lindex $mol_all 0] $sel1] get residue]]
    set names {}

    set temp {}
    set start 0
    foreach r $segments {
      lappend names [lindex [[atomselect [lindex $mol_all 0] "residue $r"] get resname] 0]
      set end [expr $start + [[atomselect [lindex $mol_all 0] "residue $r and ($sel1)"] num] -1]
      lappend temp [vecmean [lrange $rmsf $start $end]]
      set start [expr $end + 1]
    }
    set rmsf $temp

  } else {
    set segments [[atomselect [lindex $mol_all 0] $sel1] get index]
    set names [[atomselect [lindex $mol_all 0] $sel1] get name]
  }
  
  if {$normalize != "none"} {
    [namespace current]::Normalize $normalize $self
  }

}


proc itrajcomp::calc_covar_prehook1 {self} {
  namespace eval [namespace current]::${self}:: {
    set rmsf1 [lindex $rmsf $reg1]
  }
}

proc itrajcomp::calc_covar_prehook2 {self} {
  namespace eval [namespace current]::${self}:: {
    set rmsf2 [lindex $rmsf $reg2]
  }
}

proc itrajcomp::calc_covar_hook {self} {
  namespace eval [namespace current]::${self}:: {
    return [expr $rmsf1*$rmsf2]
  }
}


proc itrajcomp::calc_covar_options {} {
  # Options for covar
  variable calc_covar_options
  variable covar_vars [list byres normalize]
  variable byres 1
  variable normalize "none"

  checkbutton $calc_covar_options.byres -text "byres" -variable [namespace current]::byres
  pack $calc_covar_options.byres -side top -anchor nw

  frame $calc_covar_options.norm
  pack $calc_covar_options.norm -side top -anchor nw
  label $calc_covar_options.norm.l -text "Normalization:"
  pack $calc_covar_options.norm.l -side left
  foreach entry [list none exp expmin minmax] {
    radiobutton $calc_covar_options.norm.$entry -text $entry -variable [namespace current]::normalize -value $entry
    pack $calc_covar_options.norm.$entry -side left
  }
}


proc itrajcomp::calc_covar_options_update {} {
  # Update options gui
  [namespace current]::Samemols on
}
