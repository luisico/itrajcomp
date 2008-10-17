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

    # options is an array
    set output [SaveData_$format $self $options]

    if {$fileout != ""} {
      puts $fileout_id $output
      close $fileout_id
      # TODO: move this to the plotmtv code?
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
proc ::itrajcomp::SaveData_postscript {self {options ""}} {
  # Create postcript data
  # TODO: add scale to ps
  set plot [set ${self}::plot]
  return [$plot postscript]
}

# Save data procs (tabular)
#                  -------
proc ::itrajcomp::SaveData_tab_raw {self {options ""}} {
  # Tabular format with all the raw data
  lappend options raw 1
  return [[namespace current]::SaveData_tab $self $options]
}


proc ::itrajcomp::SaveData_tab {self {options ""}} {
  # Create tabular data
  array set opt $options

  set keys [set ${self}::keys]
  set data_index [set ${self}::data_index]
  array set graph_opts [array get ${self}::graph_opts]
  array set opts [array get ${self}::opts]
  array set sets [array get ${self}::sets]
  array set datatype [array get ${self}::datatype]

  set output ""
  # Object info
  
  # datatype
  append output "\#* datatype\n"
  foreach key [array names datatype] {
    if {$datatype($key) != ""} {
      append output "\# $key $datatype($key)\n"
    }
  }

  # opts
  append output "\#* opts\n"
  foreach key [array names opts] {
    if {$opts($key) != ""} {
      append output "\# $key $opts($key)\n"
    }
  }

  # graph_opts
  append output "\#* graph_opts\n"
  foreach key [array names graph_opts] {
    if {$graph_opts($key) != ""} {
      append output "\# $key $graph_opts($key)\n"
    }
  }

  # sets
  append output "\#* sets\n"
  foreach key [array names sets] {
    if {$sets($key) != ""} {
      append output "\# $key $sets($key)\n"
    }
  }


  # Output
  #set f_k [regsub -all {(%[0-9]+).?[0-9a-z]+} $graph_opts(format_key) {\1s}]
  regexp {%(\d+)} $graph_opts(format_data) foo fd
  set fd "%${fd}s"

  if {[info exists opt(raw)] && $opt(raw) == 1} {

    array set data [array get ${self}::data0]
    append output [format "%8s %8s   %8s %8s" "$graph_opts(header1)1" "$graph_opts(header2)1" "$graph_opts(header1)2" "$graph_opts(header2)2  "]
    switch $datatype(mode) {
      single {
        append output [format " $fd" [lindex $datatype(sets) 0]]
      }
      multiple {
        set ndata [llength $data([lindex $keys 0])]
        for {set i 0} {$i < $ndata} {incr i} {
          append output [format " $fd" "val$i"]
        }
      }
      dual {
        append output [format " $fd" [lindex $datatype(sets) 0]]
        set ndata [llength [lindex $data([lindex $keys 0]) 1]]
        for {set i 0} {$i < $ndata} {incr i} {
          append output [format " $fd" "val$i"]
        }
      }
    }
    append output "\n"
    
    foreach key $keys {
      lassign [split $key :,] i j k l
      append output [format "%8s %8s   %8s %8s  " $i $j $k $l]
      switch $datatype(mode) {
        single {
          append output [format " $graph_opts(format_data)" $data($key)]
        }
        multiple {
          for {set i 0} {$i < $ndata} {incr i} {
            append output [format " $graph_opts(format_data)" [lindex $data($key) $i]]
          }
        }
        dual {
          append output [format " $graph_opts(format_data)" [lindex $data($key) 0]]
          set values [lindex $data($key) 1]
          puts $values
          foreach val $values {
            append output [format " $graph_opts(format_data)" $val]
          }
        }
      }
      append output "\n"
    }

  } else {
    
    array set data [array get ${self}::data1]
    append output [format "%8s %8s   %8s %8s  " "$graph_opts(header1)1" "$graph_opts(header2)1" "$graph_opts(header1)2" "$graph_opts(header2)2"]
    foreach s $datatype(sets) {
      append output [format " $fd" $s]
    }
    append output "\n"

    foreach key $keys {
      lassign [split $key :,] i j k l
      append output [format "%8s %8s   %8s %8s  " $i $j $k $l [lindex $data($key) $data_index]]
      for {set s 0} {$s < [llength $datatype(sets)]} {incr s} {
        append output [format " $graph_opts(format_data)" [lindex $data($key) $s]]
      }
      append output "\n"
    }
  }

  return $output
}

# Save data procs (matrix)
#                  ------
proc ::itrajcomp::SaveData_matrix {self {options ""}} {
  # Create matrix data

  array set graph_opts [array get ${self}::graph_opts]

  lassign [[namespace current]::create_matrix $self] nrow ncol values
  return [[namespace current]::print_matrix $nrow $ncol $values $graph_opts(format_data)]
}

# Save data procs (plotmtv)
#                  -------
proc ::itrajcomp::SaveData_plotmtv_binary {self {options ""}} {
  # Create plotmtv binary data
  lappend options binary 1
  return [[namespace current]::SaveData_plotmtv $self $options]
}

proc ::itrajcomp::SaveData_plotmtv {self {options ""}} {
  # Create plotmtv data
  array set opt $options
  array set graph_opts [array get ${self}::graph_opts]

  lassign [[namespace current]::create_matrix $self] nrow ncol values

  set output "$ DATA=CONTOUR\n"
  append output "#% contours = ( 10 20 30 40 50 60 70 80 95 100 )\n"
  append output "% contfill\n"
  append output "% toplabel = \"$graph_opts(type)\"\n"
  append output "% ymin=0 ymax=$ncol\n"
  append output "% xmin=0 xmax=$nrow\n"
  append output "% nx=$nrow ny=$ncol\n"

  if {[info exists opt(binary)]} {
    append output "% BINARY\n"
    append output [binary format "d[llength $vals]" [eval list $vals]]
    append output "\n"
  } else {
    append output [[namespace current]::print_matrix $nrow 9 $values $graph_opts(format_data)]
  }

  append output "$ END\n"
  return $output
}


proc itrajcomp::create_matrix {self} {
  # Return an ordered list of values to create a rectangular matrix

  set keys [set ${self}::keys]
  array set data [array get ${self}::data1]
  set data_index [set ${self}::data_index]
  array set graph_opts [array get ${self}::graph_opts]
  array set sets [array get ${self}::sets]

  # Create a rectangular matrix
  foreach key $keys {
    lassign [split $key ,] key1 key2
    if {![info exists data($key2,$key1)]} {
      set data($key2,$key1) $data($key1,$key2)
    }
  }

  # Create ordered list of values
  set nx 0
  set ny 0
  set vals {}
  switch [set ${self}::graph_opts(type)] {
    frames {
      for {set i 0} {$i < [llength $sets(mol1)]} {incr i} {
        set f1 [lindex $sets(frame1) $i]
        for {set j 0} { $j < [llength $f1]} {incr j} {
          incr nx
          for {set k 0} {$k < [llength $sets(mol2)]} {incr k} {
            set f2 [lindex $sets(frame2) $k]
            for {set l 0} { $l < [llength $f2]} {incr l} {
              lappend vals [lindex $data($i:$j,$k:$l) $data_index]
              if {$nx == 1} {
                incr ny
              }
            }
          }
        }
      }
    }
    segments {
      foreach key $keys {
        lassign [split $key ,:] i j k l
        set part2($i) $j
        set part2($k) $l
      }
      array set segments [array get ${self}::segments]
      set nsegments [llength $segments(number)]
      for {set i 0} {$i < $nsegments} {incr i} {
        set key1 "[lindex $segments(number) $i]:$part2([lindex $segments(number) $i])"
        incr nx
        for {set k 0} {$k < $nsegments} {incr k} {
          set key2 "[lindex $segments(number) $k]:$part2([lindex $segments(number) $k])"
          lappend vals [lindex $data($key1,$key2) $data_index]
          if {$nx == 1} {
            incr ny
          }
        }
      }
    }
  }

  return [list $ny $nx $vals]
}



proc itrajcomp::print_matrix {nrow ncol values format} {
  # Return a rectangular matrix with ncol columns to print
  set output ""
  set columns 0
  for {set z 0} {$z < [llength $values]} {incr z} {
    incr columns
    append output [format " $format" [lindex $values $z]]
    if {$columns >= $nrow} {
      set columns 0
      append output "\n"
    }
  }
  append output "\n"
  return $output
}
