#
#             RMSD Trajectory Tool
#
# A GUI interface for RMSD alignment and analysis
#

# Author
# ------
#      Luis Gracia, PhD
#      Weill Medical College, Cornel University, NY
#      lug2002@med.cornell.edu

# Description
# -----------
# This is re-write of the rmsdtt 1.0 plugin from scratch. The idea behind this
# re-write is that the rmsdtt plugin (base on the rmsd tool plugin) was not
# suitable to analysis of trajectories.

# Installation
# ------------
# To add this pluging to the VMD extensions menu you can either:
# a) add this to your .vmdrc:
#    vmd_install_extension rmsdtt2 rmsdtt2_tk_cb "WMC PhysBio/RMSDTT2"
#
# b) add this to your .vmdrc
#    if { [catch {package require rmsdtt2} msg] } {
#      puts "VMD RMSDTT2 package could not be loaded:\n$msg"
#    } elseif { [catch {menu tk register "rmsdtt2" rmsdtt2} msg] } {
#      puts "VMD RMSDTT2 could not be started:\n$msg"
#    }

# hbonds.tcl
#    Functions to calculate hydrogen bonds between selections.


package provide rmsdtt2 2.0

proc rmsdtt2::hbonds { self } {
  namespace eval [namespace current]::${self}:: {
    
    variable mol1
    variable mol2
    variable frame1
    variable frame2
    variable sel
    variable rep_sel
    variable keys {}
    variable vals {}
    variable data
    variable min
    variable max
    variable dataformat "%4i"
    variable cutoff
    variable angle
    
    # Combined list of molecules involved
    set mol_all [[namespace parent]::CombineMols $mol1 $mol2]
    #puts "DEBUG: mol_all = $mol_all"
    #puts "DEBUG: refs = [llength $mol1]; targets = [llength $mol2]; all = [llength $mol_all]"
    
    # Get number of atoms for each molecule only once
    foreach i $mol_all {
      set natoms($i) [[atomselect $i $sel frame 0] num]
    }
    
    # Calculate hbonds
    set z 1
    foreach i $mol1 {
      set sel1 [atomselect $i $sel]
      foreach j [lindex $frame1 [lsearch -exact $mol1 $i]] {
	$sel1 frame $j
	foreach k $mol2 {
	  set sel2 [atomselect $k $sel]
	  foreach l [lindex $frame2 [lsearch -exact $mol2 $k]] {
	    $sel2 frame $l
	    if {[info exists data($k:$l,$i:$j)]} {
#	      set data($i:$j,$k:$l) $data($k:$l,$i:$j)
	      continue
	    } else {
	      set data($i:$j,$k:$l) [llength [lindex [measure hbonds $cutoff $angle $sel1 $sel2] 0]]
	      if {$z} {
		set min $data($i:$j,$k:$l)
		set max $data($i:$j,$k:$l)
		set z 0
	      }
	      if {$data($i:$j,$k:$l) > $max} {
		set max $data($i:$j,$k:$l)
	      }
	      if {$data($i:$j,$k:$l) < $min} {
		set min $data($i:$j,$k:$l)
	      }
	    }
	  }
	}
      }
    }
    set keys [lsort -dictionary [array names data]]
    foreach key $keys {
      lappend vals $data($key)
    }
    
  }
}


