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
  while {![eof $fid]} {
    gets $fid line
    #puts "line $line"
    regsub -all {\s\s+} $line " " line
    regsub {^\s+}       $line ""  line
    regsub {\s+$}       $line ""  line
    #puts "temp $line"
    if {[regexp {^\#\s*(\w+)\s+(.*)} $line junk key val]} {
      #puts "$key --> $val"
      set keys($key) $val
      set offset [tell $fid]
    } else {
      seek $fid $offset
      set data [[namespace current]::loadData_$format $fid]
      break
    }
  }
  close $fid
  
  set defaults [array get keys]
  lappend defaults rep_sel1 "all"
  switch $keys(type) {
    dist -
    covar {
      lappend defaults format_data "%8.4f"
      lappend defaults format_key "%3d %3s"
    }
    labels -
    rmsd {
      lappend defaults format_data "%8.4f"
      lappend defaults format_key "%3d %3d"
    }
    hbonds -
    contacts {
      lappend defaults format_data "%4i"
      lappend defaults format_key "%3d %3d"
      
    }


      lappend defaults 
  }
  
  set r [eval [namespace current]::Objnew ":auto" $defaults]
  [namespace current]::processData $r $data
  [namespace current]::NewPlot $r

}

proc itrajcomp::processData {self data} {
  # Process data loaded
  set vals {}
  set keys {}
  set segments {}
  set min [lindex [lindex $data 1] 4]
  set max $min
  for {set i 1} {$i < [llength $data]} {incr i} {
    set d [lindex $data $i]
    set val [lindex $d 4]
    set key "[lindex $d 0]:[lindex $d 1],[lindex $d 2]:[lindex $d 3]"
    lappend vals $val
    lappend keys $key
    lappend segments [lindex $d 0] [lindex $d 2]
    set temp($key) $val
    if {$val < $min} {
      set min $val
    } elseif {$val > $max} {
      set max $val
    }
  }

  set ${self}::min $min
  set ${self}::max $max
  set ${self}::segments [lsort -integer -unique $segments]
  set ${self}::keys $keys
  set ${self}::vals $vals
  array set ${self}::data [array get temp]

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
