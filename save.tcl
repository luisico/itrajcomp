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
proc ::rmsdtt2::saveData { self {fileout ""} {format "tab"} {options ""}} {
  array set opt $options
  
  variable ${self}::keys
  variable ${self}::vals
  variable ${self}::mol1
  variable ${self}::mol2

  if {[llength [info procs "SaveData_$format"]]} {
    if {$fileout != ""} {
      #puts "DEBUG: using file \"$fileout\" for output"
      set fileout_id [open $fileout w]
      fconfigure $fileout_id
      
      set opt(mols) [CombineMols $mol1 $mol2]

      switch -exact format {
	plotmtv {
	  SaveData_$format $vals $keys $fileout_id [array get opt]
	}
	default {
	  SaveData_$format $vals $keys $fileout_id [array get opt]
	}
      }
      close $fileout_id
    }
  } else {
    puts "WARNING: SaveData_$format not implemented yet"
  }
  
}


# Save data procs (tabular)
#                  -------
proc ::rmsdtt2::SaveData_tab {data keys id options} {
  #array set opt $options
  
  puts $id "mol1 frame1   mol2 frame2      rmsd"

  for {set z 0} {$z < [llength $keys]} {incr z} {
    set key [lindex $keys $z]
    set indices [split $key :,]
    set i [lindex $indices 0]
    set j [lindex $indices 1]
    set k [lindex $indices 2]
    set l [lindex $indices 3]
    puts $id [format "%4d %6d   %4d %6d   %7.3f" $i $j $k $l [lindex $data $z]]
  }
}

# Save data procs (plotmtv)
#                  -------
proc ::rmsdtt2::SaveData_plotmtv {data keys id options} {
  array set opt $options

  #puts "DEBUG: [array get opt]"

  set nx [expr round(sqrt(2*[llength $data]+1/4)-0.5) ]
  puts $id "$ DATA=CONTOUR"
  puts $id "#% contours = ( 10 20 30 40 50 60 70 80 95 100 )"
  puts $id "% contfill"
  puts $id "% toplabel = \"Pairwise RMSD\""
  puts $id "% ymin=0 ymax=$nx"
  puts $id "% xmin=0 xmax=$nx"
  puts $id "% nx=$nx ny=$nx"

  # Create a rectangular matrix filling with 0.0
  set last 0
  set values {}
  
  for {set z 0} {$z < $nx} {incr z} {
    set y [expr ($nx-1) - $z]
    #puts -nonewline "DEBUG $z: "
    for {set u 0} {$u < $z} {incr u} {
      lappend values 0.0
      #puts -nonewline [format "  %6.4f" 0.0]
    }
    for {set x $last} {$x <= [expr $last+$y]} {incr x} {
      lappend values [lindex $data $x]
      #puts -nonewline [format "  %6.4f" [lindex $data $x]]
    }
    set last $x
    #puts ""
  }
  
  if {[info exists opt(binary)]} {
    puts $id "% BINARY"
    puts $id [binary format "d[llength $values]" [eval list $values]]
  } else {
    set columns 0
    for {set z 0} {$z < [llength $values]} {incr z} {
      set columns [expr $columns + 1]
      #puts "$z [lindex $values $z]"
      puts -nonewline $id [format "  %6.4f" [lindex $values $z]]
      if {$columns > 9} {
	set columns 0
	puts $id ""
      }
    }
    puts $id ""
  }

  puts $id "$ END"
}

