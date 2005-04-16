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

# rmsdtt.tcl
#    Definition of the rmsdtt object" and main methods.


package provide rmsdtt2 2.0

namespace eval rmsdtt2 {
}

proc rmsdtt2::Objnew {{self ":auto"} args} {
  variable rmsdttObjId
  if {[info command $self] != ""} {error "$self exists"}
  if {$self == ":auto"} {
    if {![info exists rmsdttObjId]} {
      set rmsdttObjId -1
    }
    set self "rmsdttObj[incr rmsdttObjId]"
  }
  
#  interp alias {} $self: {} namespace eval ::rmsdtt2::$self
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

proc rmsdtt2::Objdelete {self} {
  if {[info command [namespace current]::del] != ""} {[namespace current]::del $self}
  namespace delete [namespace current]::$self
#  interp alias {} $self {} {}
#  interp alias {} $self: {} {}
  uplevel 1 "catch {unset $self}" ;# remove caller's reference
}

proc rmsdtt2::Objdispatch {self {cmd Objmethods} args} {
  uplevel 1 [list [namespace current]::$cmd $self] $args
}

proc rmsdtt2::Objmethods {self} {
  set prefix [namespace current]::${self}::
  string map [list $prefix ""] [info commands $prefix*]
}

proc rmsdtt2::Objvars {self} {
  set prefix [namespace current]::${self}::
  string map [list $prefix ""] [info vars $prefix*]
}

proc rmsdtt2::Objdump {self} {
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

proc rmsdtt2::Objlist {} {
  puts [namespace children [namespace current]]
}

proc rmsdtt2::Objclean {} {
  foreach self [namespace children [namespace current]] {
    [namespace current]::Objdelete [string trimleft $self [namespace current]]
  }
}
# proc rmsdtt2::set {self args} {
#   set key [lindex $args 0]
#   set val [lrange $args 1 end]
#   set ::rmsdtt2::${self}::$key $val
# }

# proc rmsdtt2::get {self args} {
#   set key [lindex $args 0]
#   return ::rmsdtt2::${self}::$key
# }


