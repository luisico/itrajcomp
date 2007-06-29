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

# save.tcl
#    Functions to save the data to external files.


proc itrajcomp::SaveDataBrowse {self {format "tab"}} {
  # GUI for saving
  set typeList {
    {"Data Files" ".dat .txt .out"}
    {"Postscript Files" ".ps .eps"}
    {"All files" ".*"}
  }
  
  set file [tk_getSaveFile -filetypes $typeList -defaultextension ".dat" -title "Select file to save data" -parent [set ${self}::win_obj]]
  
  if { $file == "" } {
    return;
  }
  
  [namespace current]::saveData $self $file $format
}


# Save data procs (general)
#                  -------
proc ::itrajcomp::saveData {self {fileout ""} {format "tab"} {options ""}} {
  # Save data to file interface
  array set opt $options

  if {[llength [info procs "SaveData_$format"]]} {
    if {$fileout != ""} {
      #puts "DEBUG: using file \"$fileout\" for output"
      set fileout_id [open $fileout w]
      fconfigure $fileout_id
      # Binary needs this (http://wiki.tcl.tk/1180)
      if {$format eq "plotmtv_binary"} {
	fconfigure $fileout_id -translation binary
      }
    } else {
      set fileout_id stdout
    }

    array set opt [array get ${self}::graph_opts]
    array set opt [array get ${self}::sets]
    set opt(plot) [set ${self}::plot]

    set output [SaveData_$format [set ${self}::vals] [set ${self}::keys] [array get opt]]

    if {$fileout != ""} {
      puts $fileout_id $output
      close $fileout_id
      # TODO: move this to the plotmtv code
      if {$format eq "plotmtv" || $format eq "plotmtv_binary"} {
	set status [catch {exec plotmtv $fileout &} msg]
	if { $status } {
	  tk_messageBox -title "Warning" -message "Could not open plotmtv\n\nError returned:\n $msg" -type ok -parent [set ${self}::win_obj]
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
proc ::itrajcomp::SaveData_postscript {data keys options} {
  # Create postcript data
  # TODO: add scale to ps
  array set opt $options
  return [$opt(plot) postscript]
}

# Save data procs (tabular)
#                  -------
proc ::itrajcomp::SaveData_tab {data keys options} {
  # Create tabular data
  array set opt $options

  set output ""
  # Object info
  foreach i [list type mol_all sel1 sel2] {
    if {[info exists opt($i)] && $opt($i) != ""} {
      append output "\# $i [set opt($i)]\n"
    }
  }

  # Data
  #set f_k [regsub -all {(%[0-9]+).?[0-9a-z]+} $opt(format_key) {\1s}]
  set f_d "%[lindex [regexp {%(\d+)} $opt(format_data)] 1]s"
  append output [format "%8s %8s   %8s %8s   $f_d\n" "$opt(header1)1" "$opt(header2)1" "$opt(header1)2" "$opt(header2)2" "val"]
  for {set z 0} {$z < [llength $keys]} {incr z} {
    set key [lindex $keys $z]
    set indices [split $key :,]
    set i [lindex $indices 0]
    set j [lindex $indices 1]
    set k [lindex $indices 2]
    set l [lindex $indices 3]
    append output [format "%8s %8s   %8s %8s   $opt(format_data)\n" $i $j $k $l [lindex $data $z]]
  }
  return $output
}

# Save data procs (matrix)
#                  ------
proc ::itrajcomp::SaveData_matrix {data keys options} {
  # Create matrix data
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
	  append output [format " $opt(format_data)" $values($i:$j,$k:$l)]
	}
      }
      append output "\n"
    }
  }
  return $output
}

# Save data procs (plotmtv)
#                  -------
proc ::itrajcomp::SaveData_plotmtv_binary {data keys options} {
  # Create plotmtv binary data
  lappend options binary 1
  return [[namespace current]::SaveData_plotmtv $data $keys $options]
}

proc ::itrajcomp::SaveData_plotmtv {data keys options} {
  # Create plotmtv data
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
  append output "% toplabel = \"$opt(type)\"\n"
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
      set columns [expr {$columns + 1}]
      #puts "$z [lindex $vals $z]"
      append output [format "  $opt(format_data)" [lindex $vals $z]]
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
