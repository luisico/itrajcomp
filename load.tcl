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

# load.tcl
#    Load data.


# TODO: broken
# TODO: convert to a serialize object
proc itrajcomp::loadDataBrowse {format} {
  # Load GUI
  set vn [package present itrajcomp]
  if {[llength [info procs "loadData_$format"]] < 1} {
    tk_messageBox -title "iTrajComp v$vn - Error" -parent .itrajcomp -message "loadData_$format not implemented yet"
    return
  }

  set typeList {
    {"Data Files" ".dat .txt .out"}
    {"Postscript Files" ".ps"}
    {"All files" ".*"}
  }
  
  set file [tk_getOpenFile -filetypes $typeList -defaultextension ".dat" -title "Select file to open" -parent .itrajcomp]
  
  if { $file == "" } {
    return;
  }
  
  [namespace current]::loadData $file $format
}

proc itrajcomp::loadData {file format} {
  # Load data interface
  if {$file == ""} {
    return
  }

  set fid [open $file r]
  fconfigure $fid

  # Read header
  set section "other"
  while {![eof $fid]} {
    gets $fid line
    #puts "line $line"
    regsub -all {\s\s+} $line " " line
    regsub {^\s+}       $line ""  line
    regsub {\s+$}       $line ""  line
    #puts "temp $line"
    if {[regexp {^\#\*\s*(\w+)} $line junk section]} {
      #      set section $section
      puts "SECTION $section"
    } elseif {[regexp {^\#\s*(\w+)\s+(.*)} $line junk key val]} {
      #      puts "$key --> $val"
      set ${section}($key) $val
      set offset [tell $fid]
    } else {
      seek $fid $offset
      set data [[namespace current]::loadData_$format $fid]
      break
    }
  }
  close $fid

  # Type of object
  if {![info exists opts(type)]} {
    tk_messageBox -title "Warning" -message "Type not specified in input file"
    return
  }
  
  if {[llength [info procs "calc_$opts(type)_options"]] == 0} {
    tk_messageBox -title "Warning" -message "Could not find calc_$opts(type)_options"
    return
  }

  # Create new object
  set obj [eval [namespace current]::Objnew ":auto"]
  [namespace current]::processData $obj $data
  array set ${obj}::opts [array get opts]
  
  # datatype
  set ${obj}::datatype(mode) "single"
  set ${obj}::datatype(sets) "loaded"

  # opts
  set ${obj}::opts(type) "loaded"
  set ${obj}::opts(diagonal) 0

  # graph_opts
  array set graph_opts {
    formats "f" format_key ""
    format_data "" format_scale ""
    rep_style1 NewRibbons
    rep_color1 Molecule
    rep_colorid1 0
  }
  array set ${obj}::graph_opts [array get graph_opts]

  # other options
  set ${obj}::data_index 0

  # sets
  #?
  [namespace current]::PrepareData $obj
  [namespace current]::Status "Creating graph for $obj ..."
  [namespace current]::itcObjGui $obj
}

proc itrajcomp::processData {self alldata} {
  # Process data loaded
  set vals {}
  set keys {}
  for {set i 1} {$i < [llength $alldata]} {incr i} {
    set d [lindex $alldata $i]
    set val [lindex $d 4]
    set key "[lindex $d 0]:[lindex $d 1],[lindex $d 2]:[lindex $d 3]"
    lappend keys $key
    set data($key) $val
  }

  set ${self}::keys $keys
  array set ${self}::data [array get data]
}

proc itrajcomp::loadData_tab {fid} {
  # Load data in tabular format
  # Names
  set data {}
  gets $fid line
  regsub -all {\s\s+} $line " " line
  regsub {^\s+}       $line ""  line
  regsub {\s+$}       $line ""  line
  lappend data [split $line { }]

  # Data
  while {![eof $fid]} {
    gets $fid line
    #puts "line $line"
    if {[regexp {^$} $line junk junk]} {
      break
    }
    regsub -all {\s\s+} $line " " line
    regsub {^\s+}       $line ""  line
    regsub {\s+$}       $line ""  line
    #puts "temp $line"
    lappend data [split $line { }]
  }
  return $data
}
