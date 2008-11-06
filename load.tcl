#****h* itrajcomp/load
# NAME
# load -- Load data
#
# AUTHOR
# Luis Gracia
#
# DESCRIPTION
#
# Load data.
# 
# SEE ALSO
# More documentation can be found in:
# * README.txt
# * itrajcomp.tcl
# * http://physiology.med.cornell.edu/faculty/hweinstein/vmdplugins/itrajcomp
#
# TODO
# * Broken
# * Convert to a serialize object
#
# COPYRIGHT
# Copyright (C) 2005-2008 by Luis Gracia <lug2002@med.cornell.edu> 
#
#****

#****f* load/loadDataBrowse
# NAME
# loadDataBrowse
# SYNOPSIS
# itrajcomp::loadDataBrowse format
# FUNCTION
# Load GUI
# PARAMETERS
# * format -- format
# SOURCE
proc itrajcomp::loadDataBrowse {format} {
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
#*****

#****f* load/loadData
# NAME
# loadData
# SYNOPSIS
# itrajcomp::loadData file format
# FUNCTION
# Creates a new object based on the data in file
# PARAMETERS
# * file -- filename
# * format -- format
# RETURN VALUE
# 
# SOURCE
proc itrajcomp::loadData {file format} {
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
    tk_messageBox -title "Error" -message "Type not specified in input file"
    return
  }
  
  if {[llength [info procs "calc_$opts(type)_options"]] == 0} {
    tk_messageBox -title "Error" -message "Could not find calc_$opts(type)_options"
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
#*****

#****f* load/processData
# NAME
# processData
# SYNOPSIS
# itrajcomp::processData self alldata
# FUNCTION
# Process data loaded
# PARAMETERS
# * self -- object
# * alldata -- data to process
# RETURN VALUE
# 
# SOURCE
proc itrajcomp::processData {self alldata} {
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
#*****

#****f* load/loadData_tab
# NAME
# loadData_tab
# SYNOPSIS
# itrajcomp::loadData_tab fid
# FUNCTION
# Load data in tabular format
# PARAMETERS
# * fid -- file id
# RETURN VALUE
# Data loaded in tabular format
# SOURCE
proc itrajcomp::loadData_tab {fid} {
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
#*****
