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

# save.tcl
#    Functions to save the data to external files.


package provide rmsdtt2 2.0

# Save data procs (general)
#                  -------
proc ::rmsdtt2::saveData { data {format "tab"} {fileout ""} {sort 0} {mol_ref "all"} {mol_tar "all"} {options ""} } {
  upvar $data values
  array set opt $options

  if {[llength [info procs "SaveData_$format"]]} {
    if {$fileout != ""} {
      #puts "DEBUG: using file \"$fileout\" for output"
      set fileout_id [open $fileout w]
      fconfigure $fileout_id
      
      set keys [GetKeys values $sort $mol_ref $mol_tar]
      
      ParseMols mol_ref
      ParseMols mol_tar
      set opt(mol_ref) $mol_ref
      set opt(mol_tar) $mol_tar
      set loptions [array get opt]
      SaveData_$format values $keys $loptions $fileout_id
      
      close $fileout_id
    }
  } else {
    puts "WARNING: SaveData_$format not implemented yet"
  }
}

# Save data procs (tabular)
#                  -------
proc ::rmsdtt2::SaveData_tab {data keys options id} {
  upvar $data values
  #array set opt $options
  
  puts $id "mref  fref   mol frame      rmsd"

  foreach key $keys {
    set indices [split $key :]
    set i [lindex $indices 0]
    set j [lindex $indices 1]
    set k [lindex $indices 2]
    set l [lindex $indices 3]
    puts $id [format "%4d %5d   %3d %5d   %7.3f" $i $j $k $l $values($key)]
  }
}


# Save data procs (plotmtv)
#                  -------
proc ::rmsdtt2::SaveData_plotmtv {data keys options id} {
  upvar $data values
  array set opt $options

  #puts "DEBUG: [array get opt]"
  
  set nx 0
  foreach i [CombineMols $opt(mol_ref) $opt(mol_tar)] {
    set nx [expr $nx + [molinfo $i get numframes]]
  }
  
  puts $id "$ DATA=CONTOUR"
  puts $id "#% contours = ( 10 20 30 40 50 60 70 80 95 100 )"
  puts $id "% contfill"
  puts $id "% toplabel = \"Pairwise RMSD\""
  puts $id "% ymin=0 ymax=$nx"
  puts $id "% xmin=0 xmax=$nx"
  puts $id "% nx=$nx ny=$nx"
  if {[info exists opt(binary)]} {
    puts $id "% BINARY"
    foreach key $keys {
      lappend vals $values($key)
    }
    puts $id [binary format "d[llength $vals]" [eval list $vals]]
  } else {
    set columns 0
    foreach key $keys {
      set columns [expr $columns + 1]
      puts -nonewline $id [format "  %6.4f" $values($key)]
      if {$columns > 9} {
	set columns 0
	puts $id ""
      }
    }
  }

  puts $id "$ END"
}

