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

# object.tcl
#    Definition of the itrajcomp object and main methods.


package provide itrajcomp 1.0

namespace eval itrajcomp {
}

proc itrajcomp::Objnew {{self ":auto"} args} {
  variable itcObjId
  if {[info command $self] != ""} {error "$self exists"}
  if {$self == ":auto"} {
    if {![info exists itcObjId]} {
      set itcObjId -1
    }
    set self "itcObj[incr itcObjId]"
  }
  
#  interp alias {} $self: {} namespace eval ::itrajcomp::$self
  array set defaults {
    mol1 0 frame1 0 mol2 0 frame2 0
    sel1 all sel2 all
  }
  foreach {key val} $args {
    set defaults($key) $val
  }
  namespace eval [namespace current]::$self variable [array get defaults]
  namespace eval [namespace current]::${self}:: variable self $self

#  interp alias {} $self {} [namespace current]::Objdispatch $self
  return $self
}

proc itrajcomp::Objdelete {self} {
  if {[info command [namespace current]::del] != ""} {[namespace current]::del $self}
  namespace delete [namespace current]::$self
#  interp alias {} $self {} {}
#  interp alias {} $self: {} {}
  uplevel 1 "catch {unset $self}" ;# remove caller's reference
}

proc itrajcomp::Objdispatch {self {cmd Objmethods} args} {
  uplevel 1 [list [namespace current]::$cmd $self] $args
}

proc itrajcomp::Objmethods {self} {
  set prefix [namespace current]::${self}::
  string map [list $prefix ""] [info commands $prefix*]
}

proc itrajcomp::Objvars {self} {
  set prefix [namespace current]::${self}::
  string map [list $prefix ""] [info vars $prefix*]
}

proc itrajcomp::Objdump {self} {
  puts "$self:"
  set prefix [namespace current]::${self}::

  foreach var [lsort [info var $prefix*]] {
    if {[string match *upproc_var* $var]} {
      continue
    }
    set vartxt [namespace tail $var]
    if {[array exists $var]} {
      puts "  $vartxt [array get $var]"
    } else {
      puts "  $vartxt [set $var]"
    }
  }

}

proc itrajcomp::Objlist {} {
  return [namespace children [namespace current]]
}

proc itrajcomp::Objclean {} {
  foreach self [namespace children [namespace current]] {
    [namespace current]::Objdelete [string trimleft $self [namespace current]]
  }
}
# proc itrajcomp::set {self args} {
#   set key [lindex $args 0]
#   set val [lrange $args 1 end]
#   set ::itrajcomp::${self}::$key $val
# }

# proc itrajcomp::get {self args} {
#   set key [lindex $args 0]
#   return ::itrajcomp::${self}::$key
# }


proc itrajcomp::Objcombine { formula } {
  variable combobj

  #puts "FORMULA: $formula"
  set line $formula
  regsub -all {\$(\d+)} $formula {$d(\1)} formula
  #puts "FORMULA: $formula"
  #puts "OBJECTS: $combobj"

  while { [regexp {\$(\d+)(.*)} $line junk obj line] } {
    set self($obj) "itcObj$obj"
    lappend selflist $obj
  }
  set s0 [lindex $selflist 0]

  if {[llength [array names self]] == 0} {
    puts "No objects in formula"
    return
  }

  foreach s [array names self] {
    set mol1($s)       [set $self($s)::mol1]
    set mol2($s)       [set $self($s)::mol2]
    set frame1($s)     [set $self($s)::frame1]
    set frame2($s)     [set $self($s)::frame2]
    set sel1($s)       [set $self($s)::sel1]
    set sel2($s)       [set $self($s)::sel2]
    set type($s)       [set $self($s)::type]
    set format_data($s) [set $self($s)::format_data]
    set format_key($s) [set $self($s)::format_key]
    set keys($s)       [set $self($s)::keys]
    set data($s)       [set $self($s)::vals]
  }
  
  # ToDo: check more things, like data has same format
  foreach check [list "type"] {
    set test [set $self($s0)::$check]
    for {set i 1} {$i < [llength $selflist]} {incr i} {
      if {[set $self([lindex $selflist $i])::$check] != $test} {
	tk_messageBox -title "Warning" -message "$check is not the same among the objects, cannot combine objects" -type ok
	return
      }
    }
  }

  set test [llength [set $self($s0)::keys]]
  for {set i 1} {$i < [llength $selflist]} {incr i} {
    if {[llength [set $self([lindex $selflist $i])::keys]] != $test} {
      tk_messageBox -title "Warning" -message "length of objects is not the same, cannot combine objects" -type ok
      return
    }
  }

  # By now parameters for combined object come from object with smaller number
  set defaults [list mol1 $mol1($s0) frame1 $frame1($s0) mol2 $mol2($s0) frame2 $frame2($s0) sel1 $sel1($s0) sel2 $sel2($s0) rep_sel1 "all" type "combination" format_data $format_data($s0) format_key $format_key($s0)]
  set r [eval [namespace current]::Objnew ":auto" $defaults]
  
  set zu 1
  for {set z 0} {$z < [llength $keys($s0)]} {incr z} {
    set key [lindex $keys($s0) $z]
    set indices [split $key :,]
    set i [lindex $indices 0]
    set j [lindex $indices 1]
    set k [lindex $indices 2]
    set l [lindex $indices 3]
    foreach s [array names self] {
      set d($s) [lindex $data($s) $z]
    }
    set result [expr $formula]
    if {$zu} {
      set min $result
      set max $result
      set zu 0
    }
    if {$result > $max} {
      set max $result
    }
    if {$result < $min} {
      set min $result
    }
    set ${r}::data($i:$j,$k:$l) $result
    puts -nonewline [format "%4d %6d   %4d %6d" $i $j $k $l]
    foreach s $selflist {
      puts -nonewline [format " %8.3f" $d($s)]
    }
    puts [format "   = %8.3f" $result]
  }
  set ${r}::min $min
  set ${r}::max $max

  namespace eval [namespace current]::${r}:: {
    variable min
    variable max
    variable data
    variable keys
    variable vals
    set keys [lsort -dictionary [array names data]]
    foreach key $keys {
      lappend vals $data($key)
    }
  }

  [namespace current]::NewPlot $r

}
