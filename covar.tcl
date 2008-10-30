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
#      See maingui.tcl

# Documentation
# ------------
#      The documentation can be found in the README.txt file and
#      http://physiology.med.cornell.edu/faculty/hweinstein/vmdplugins/itrajcomp

# covar.tcl
#    Functions to calculate the covariance matrix.


proc itrajcomp::calc_covar {self} {
  # Check number of atoms in selections, and combined list of molecules
  if {[[namespace current]::CheckNatoms $self] == -1} {
    return -code error
  }

  # Define segments
  [namespace current]::DefineSegments $self

  namespace eval [namespace current]::${self}:: {
    # Check if any of the molecules has a single frame
    set not1frame 1
    foreach i $sets(mol_all) {
      if {[molinfo $i get numframes] == 1} {
        set not1frame 0
        break
      }
    }
    
    # Precalculate rmsf of each segment
    if {$sets(frame1_def) == "all" && $not1frame == 1} {
      # All molecules have more than 1 frame
      set count 0
      foreach i $sets(mol_all) {
        set nframes [molinfo $i get numframes]
        set temp [measure rmsf [atomselect $i $sets(sel1)] first 0 last [expr {$nframes -1}] step 1]
        for {set n 0} {$n < [llength $temp]} {incr n} {
          lset temp $n [expr {[lindex $temp $n] * [lindex $temp $n] * $nframes} ]
        }
        if {$count eq 0} {
          set rmsf $temp
        } else {
          set rmsf [vecadd $rmsf $temp]
        }
        set count [expr {$count + $nframes} ]
      }
      for {set n 0} {$n < [llength $rmsf]} {incr n} {
        lset rmsf $n [expr {sqrt([lindex $rmsf $n] / double($count))} ]
      }
      #puts "DEBUG: rmsf $rmsf"
      
    } else {
      # At least one molecule has only 1 frame
      # Calculate rmsf for each atom in one run
      set count 0
      set a {}
      set b {}
      foreach i $sets(mol_all) {
        set s1 [atomselect $i $sets(sel1)]
        #puts "DEBUG: mol $i"
        foreach j [lindex $sets(frame1) [lsearch -exact $sets(mol_all) $i]] {
          $s1 frame $j
          #puts "DEBUG: frame $j"
          set coor [$s1 get {x y z}]
          if {$count eq 0} {
            set b $coor
            set a $coor
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
      set factor [expr {1./double($count)} ]
      set rmsf $a
      for {set n 0} {$n < [llength $b]} {incr n} {
        set temp_a [vecscale [lindex $a $n] $factor]
        set temp_b [vecscale [lindex $b $n] $factor]
        lset a $n $temp_a
        lset b $n $temp_b
        lset rmsf $n [expr {sqrt($temp_a - [veclength2 $temp_b])} ]
      }
      #puts "DEBUG:-------"
      #puts "DEBUG: aa $a"
      #puts "DEBUG: bb $b"
      #puts "DEBUG: rmsf $rmsf"
      #puts "DEBUG: meas [measure rmsf $s1 first 0 last [expr [molinfo $i get numframes] -1] step 1]"
    }

    if {$opts(segment) == "byres"} {
      set temp {}
      set start 0
      foreach r $segments(number) {
        set end [expr {$start + [[atomselect [lindex $sets(mol_all) 0] "residue $r and ($sets(sel1))"] num] -1}]
        lappend temp [vecmean [lrange $rmsf $start $end]]
        set start [expr {$end + 1}]
      }
      set rmsf $temp
    }
  }

  # Calculate covariance matrix
  return [[namespace current]::LoopSegments $self]
}


proc itrajcomp::calc_covar_prehook1 {self} {
  set ${self}::rmsf1 [lindex [set ${self}::rmsf] [set ${self}::reg1]]
}


proc itrajcomp::calc_covar_prehook2 {self} {
  set ${self}::rmsf2 [lindex [set ${self}::rmsf] [set ${self}::reg2]]
}


proc itrajcomp::calc_covar_hook {self} {
  return [expr {[set ${self}::rmsf1] * [set ${self}::rmsf2]} ]
}


proc itrajcomp::calc_covar_options {} {
  # Options for covar
  variable calc_covar_frame
  variable calc_covar_datatyper
  set calc_covar_datatype(mode) "single"

  variable calc_covar_opts
  set calc_covar_opts(segment) "byres"
  set calc_covar_opts(force_samemols) 1

  # by segment
  frame $calc_covar_frame.segment
  pack $calc_covar_frame.segment -side top -anchor nw
  label $calc_covar_frame.segment.l -text "Segments:"
  pack $calc_covar_frame.segment.l -side left
  foreach entry [list byatom byres] {
    radiobutton $calc_covar_frame.segment.$entry -text $entry -variable [namespace current]::calc_covar_opts(segment) -value $entry
    pack $calc_covar_frame.segment.$entry -side left
  }

  # Graph options
  variable calc_covar_graph
  array set calc_covar_graph {
    type         "segments"
    formats      "f"
    rep_style1   "CPK"
  }
}
