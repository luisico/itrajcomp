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


namespace eval itrajcomp {
}

proc itrajcomp::Objnew {{self ":auto"} args} {
  # Generate namespace for a new object

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
    keys {} vals {}
    min 0 max 0
    data_index 0
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
  # Dete an object
  if {[info command [namespace current]::del] != ""} {[namespace current]::del $self}
  namespace delete [namespace current]::$self
#  interp alias {} $self {} {}
#  interp alias {} $self: {} {}
  uplevel 1 "catch {unset $self}" ;# remove caller's reference
}

proc itrajcomp::Objdispatch {self {cmd Objmethods} args} {
  # TODO: not used, remove?
  uplevel 1 [list [namespace current]::$cmd $self] $args
}

proc itrajcomp::Objmethods {self} {
  # Print list of methods
  set prefix [namespace current]::${self}::
  string map [list $prefix ""] [info commands $prefix*]
}

proc itrajcomp::Objvars {self} {
  # Print list of variables
  set prefix [namespace current]::${self}::
  string map [list $prefix ""] [info vars $prefix*]
}

proc itrajcomp::Objdump {self} {
  # Print list of variables and values
  puts "$self:"
  set prefix [namespace current]::${self}::

  foreach var [lsort [info var $prefix*]] {
    if {[string match *upproc_var* $var]} {
      continue
    }
    set vartxt [namespace tail $var]
    if {[array exists $var]} {
      puts "  $vartxt (array):"
      puts "     [array get $var]"
    } else {
      puts "  $vartxt: [set $var]"
    }
  }

}

proc itrajcomp::Objlist {} {
  # Print list of objects
  return [namespace children [namespace current]]
}

proc itrajcomp::Objclean {} {
  # Remove all objects
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

