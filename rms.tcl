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

# rms.tcl
#    Functions to calculate rms.


package provide rmsdtt2 2.0

proc rmsdtt2::DoRmsd {} {
  variable w
  variable mol1_def
  variable frame1_def
  variable mol1_m_list
  variable mol1_f_list
  variable skip1
  variable mol2_def
  variable frame2_def
  variable mol2_m_list
  variable mol2_f_list
  variable skip2
  variable selmod
  variable samemols

  if {$samemols} {
    set mol2_def $mol1_def
    set frame2_def $frame1_def
    set mol2_m_list $mol1_m_list
    set mol2_f_list $mol1_f_list
    set skip2 $skip1
  }

  # Parse list of molecules
  set mol1 [[namespace current]::ParseMols $mol1_def $mol1_m_list]
  set mol2 [[namespace current]::ParseMols $mol2_def $mol2_m_list]

  # Parse frames
  set frame1 [[namespace current]::ParseFrames $frame1_def $mol1 $skip1 $mol1_f_list]
  set frame2 [[namespace current]::ParseFrames $frame2_def $mol2 $skip2 $mol2_f_list]

  #puts "$mol1 $frame1 $mol2 $frame2 $selmod"
  set sel [ParseSel [$w.atoms.sel get 1.0 end] $selmod]
  #puts $sel

  set r [[namespace current]::Objnew ":auto" mol1 $mol1 frame1 $frame1 mol2 $mol2 frame2 $frame2 sel $sel rep_sel $sel]

  [namespace current]::Objdump $r
  [namespace current]::rms $r
  [namespace current]::NewPlot $r

}


proc rmsdtt2::rms { self } {
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
    
    # Combined list of molecules involved
    set mol_all [[namespace parent]::CombineMols $mol1 $mol2]
    #puts "DEBUG: mol_all = $mol_all"
    #puts "DEBUG: refs = [llength $mol1]; targets = [llength $mol2]; all = [llength $mol_all]"
    
    # Get number of atoms for each molecule only once
    foreach i $mol_all {
      set natoms($i) [[atomselect $i $sel frame 0] num]
    }
    
    # Check number of atoms in selections
    foreach i $mol_all {
      foreach j $mol_all {
	if {$i < $j} {
	  if {$natoms($i) != $natoms($j)} {
	    puts "Selections differ for molecules $i ($natoms($i)) and $j ($natoms($j))"
	    return -code return
	  }
	}
      }
    }
    
    # Calculate rmsd for each pair reference(mol,frame)-target(mol,frame)
    set max 0
    set min 0
#    set z 1
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
	      set data($i:$j,$k:$l) [measure rmsd $sel1 $sel2]
#	      if {$z} {
#		set min $data($i:$j,$k:$l)
#		set z 0
#	      }
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

