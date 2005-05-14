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

proc rmsdtt2::SaveDataBrowse {self {format "tab"}} {
  set typeList {
    {"Data Files" ".dat .txt .out"}
    {"Postscript Files" ".ps"}
    {"All files" ".*"}
  }
  
  set file [tk_getSaveFile -filetypes $typeList -defaultextension ".dat" -title "Select file to save data" -parent [set ${self}::p]]
  
  if { $file == "" } {
    return;
  }
  
  [namespace current]::saveData $self $file $format]
}


# Save data procs (general)
#                  -------
proc ::rmsdtt2::saveData { self {fileout ""} {format "tab"} {options ""}} {
  array set opt $options

  if {[llength [info procs "SaveData_$format"]]} {
    if {$fileout != ""} {
      #puts "DEBUG: using file \"$fileout\" for output"
      set fileout_id [open $fileout w]
      fconfigure $fileout_id
    } else {
      set fileout_id stdout
    }

    set opt(mol1) [set ${self}::mol1]
    set opt(mol2) [set ${self}::mol2]
    set opt(frame1) [set ${self}::frame1]
    set opt(frame2) [set ${self}::frame2]
    set opt(dataformat) [set ${self}::dataformat]
    set opt(canvas) [set ${self}::p]

    set output [SaveData_$format [set ${self}::vals] [set ${self}::keys] [array get opt]]

    if {$fileout != ""} {
      puts $fileout_id $output
      close $fileout_id
      if {$format eq "plotmtv" || $format eq "plotmtv_binary"} {
	set status [catch {exec plotmtv $fileout &} msg]
	if { $status } {
	  tk_messageBox -title "Warning" -message "Could not open plotmtv\n\nError returned:\n $msg" -type ok -parent $p
	} 
      }
    } else {
      return $output
    }    
  } else {
    puts "WARNING: SaveData_$format not implemented yet"
  }
}


# Save data procs (postscript)
#                  ----------
proc ::rmsdtt2::SaveData_postscript {data keys options} {
  array set opt $options
  return [$opt(canvas).u.l.canvas.c postscript]
}

# Save data procs (tabular)
#                  -------
proc ::rmsdtt2::SaveData_tab {data keys options} {
  array set opt $options
  
  set output "mol1 frame1   mol2 frame2      rmsd\n"
  for {set z 0} {$z < [llength $keys]} {incr z} {
    set key [lindex $keys $z]
    set indices [split $key :,]
    set i [lindex $indices 0]
    set j [lindex $indices 1]
    set k [lindex $indices 2]
    set l [lindex $indices 3]
    append output [format "%4d %6d   %4d %6d   $opt(dataformat)\n" $i $j $k $l [lindex $data $z]]
  }
  return $output
}

# Save data procs (matrix)
#                  ------
proc ::rmsdtt2::SaveData_matrix {data keys options} {
  array set opt $options

  #puts "DEBUG: [array get opt]"
  
  # Create a rectangular matrix
  for {set z 0} {$z < [llength $keys]} {incr z} {
    set values([lindex $keys $z]) [lindex $data $z]
  }
  foreach key [array names values] {
    set indices [split $key ,]
    set key1 [lindex $indices 0]
    set key2 [lindex $indices 1]
    if {![info exists values($key2,$key1)]} {
      set values($key2,$key1) $values($key1,$key2)
    }
  }

  set output ""
  foreach i $opt(mol1) {
    foreach j [lindex $opt(frame1) [lsearch -exact $opt(mol1) $i]] {
      foreach k $opt(mol2) {
	foreach l [lindex $opt(frame2) [lsearch -exact $opt(mol2) $k]] {
	  append output [format " $opt(dataformat)" $values($i:$j,$k:$l)]
	}
      }
      append output "\n"
    }
  }
  return $output
}

# Save data procs (plotmtv)
#                  -------
proc ::rmsdtt2::SaveData_plotmtv_binary {data keys options} {
  lappend options binary 1
  return [[namespace current]::SaveData_plotmtv $data $keys $options]
}

proc ::rmsdtt2::SaveData_plotmtv {data keys options} {
  array set opt $options

  #puts "DEBUG: [array get opt]"

  for {set z 0} {$z < [llength $keys]} {incr z} {
    set values([lindex $keys $z]) [lindex $data $z]
  }
  foreach key [array names values] {
    set indices [split $key ,]
    set key1 [lindex $indices 0]
    set key2 [lindex $indices 1]
    if {![info exists values($key2,$key1)]} {
      set values($key2,$key1) $values($key1,$key2)
    }
  }

  set nx 0
  set ny 0
  foreach i $opt(mol1) {
    foreach j [lindex $opt(frame1) [lsearch -exact $opt(mol1) $i]] {
      incr nx
      foreach k $opt(mol2) {
	foreach l [lindex $opt(frame2) [lsearch -exact $opt(mol2) $k]] {
	  lappend vals $values($i:$j,$k:$l)
	  if {$nx == 1} {
	    incr ny
	  }
	}
      }
    }
  }

  set output "$ DATA=CONTOUR\n"
  append output "#% contours = ( 10 20 30 40 50 60 70 80 95 100 )\n"
  append output "% contfill\n"
  append output "% toplabel = \"Pairwise RMSD\"\n"
  append output "% ymin=0 ymax=$ny\n"
  append output "% xmin=0 xmax=$nx\n"
  append output "% nx=$nx ny=$ny\n"

  if {[info exists opt(binary)]} {
    append output "% BINARY\n"
    append output [binary format "d[llength $vals]" [eval list $vals]]
    append output "\n"
  } else {
    set columns 0
    for {set z 0} {$z < [llength $vals]} {incr z} {
      set columns [expr $columns + 1]
      #puts "$z [lindex $vals $z]"
      append output [format "  $opt(dataformat)" [lindex $vals $z]]
      if {$columns > 9} {
	set columns 0
	append output "\n"
      }
    }
    append output "\n"
  }

  append output "$ END\n"
  return $output
}
