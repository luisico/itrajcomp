#****h* itrajcomp/load
# NAME
# load
#
# DESCRIPTION
# Load data.
#
# TODO
# * Broken
# * Convert to a serialize object
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
  if {![info exists opts(calctype)]} {
    tk_messageBox -title "Error" -message "Type not specified in input file"
    return
  }

  if {[llength [info procs "calc_$opts(calctype)_options"]] == 0} {
    tk_messageBox -title "Error" -message "Could not find calc_$opts(calctype)_options"
    return
  }

  # Create new object
  set obj [eval [namespace current]::Objnew ":auto"]
  [namespace current]::processData $obj $data

  # opts
  array set opts {
    mode "frames"
    sets "single"
    ascii 0
    formats "f"
    format_key ""
    format_data ""
    format_scale ""
    style NewRibbons
    color Molecule
    colorID 0
    connect lines
  }
  array set ${obj}::opts [array get opts]
  set ${obj}::opts(collections) "loaded"
  set ${obj}::opts(calctype) "loaded"

  # guiopts
  array set ${obj}::guiopts [array get guiopts]
  set ${obj}::guiopts(diagonal) 0

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
