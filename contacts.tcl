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

# contacs.tcl
#    Functions to calculate contacts between atoms.


package provide rmsdtt2 2.0

proc rmsdtt2::contacts { self } {
  namespace eval [namespace current]::${self}:: {
    
    variable mol1
    variable mol2
    variable frame1
    variable frame2
    variable sel1
    variable sel2
    variable keys {}
    variable vals {}
    variable data
    variable min
    variable max
    variable dataformat "%4i"
    variable cutoff
    
    # Calculate contacts
    set z 1
    foreach i $mol1 {
      set s1 [atomselect $i $sel1]
      foreach j [lindex $frame1 [lsearch -exact $mol1 $i]] {
	$s1 frame $j
	foreach k $mol2 {
	  set s2 [atomselect $k $sel2]
	  foreach l [lindex $frame2 [lsearch -exact $mol2 $k]] {
	    $s2 frame $l
	    if {[info exists data($k:$l,$i:$j)]} {
#	      set data($i:$j,$k:$l) $data($k:$l,$i:$j)
	      continue
	    } else {
	      set data($i:$j,$k:$l) [llength [lindex [measure contacts $cutoff $s1 $s2] 0]]
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


