#****h* itrajcomp/object
# NAME
# object
#
# DESCRIPTION
# Definition of the itrajcomp object and main methods.
#****

# FIXME: move to itrajcomp.tcl
namespace eval itrajcomp {
}

#****f* object/Objnew
# NAME
# Objnew
# SYNOPSIS
# itrajcomp::Objnew self args
# FUNCTION
# Generate namespace for a new object
# PARAMETERS
# * self -- object id
# * args -- arguments to pass to the new object
# RETURN VALUE
# New object
# SOURCE
proc itrajcomp::Objnew {{self ":auto"} args} {

  variable itcObjId
  if {[info command $self] != ""} {error "$self exists"}
  if {$self == ":auto"} {
    if {![info exists itcObjId]} {
      set itcObjId -1
    }
    set self "itc[incr itcObjId]"
  }

  # TODO: this is the only part that is dependent on itc objects. Move out?
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

  return $self
}
#****

#****f* object/Objdelete
# NAME
# Objdelete
# SYNOPSIS
# itrajcomp::Objdelete self
# FUNCTION
# Dete an object
# PARAMETERS
# * self -- object
# SOURCE
proc itrajcomp::Objdelete {self} {
  if {[info command [namespace current]::del] != ""} {[namespace current]::del $self}
  namespace delete [namespace current]::$self
  uplevel 1 "catch {unset $self}" ;# remove caller's reference
}
#****

#****f* object/Objmethods
# NAME
# Objmethods
# SYNOPSIS
# itrajcomp::Objmethods self
# FUNCTION
# Print list of methods
# PARAMETERS
# * self -- object
# SOURCE
proc itrajcomp::Objmethods {self} {
  set prefix [namespace current]::${self}::
  string map [list $prefix ""] [info commands $prefix*]
}
#****

#****f* object/Objvars
# NAME
# Objvars
# SYNOPSIS
# itrajcomp::Objvars self
# FUNCTION
# Print list of variables
# PARAMETERS
# * self -- object
# SOURCE
proc itrajcomp::Objvars {self} {
  set prefix [namespace current]::${self}::
  string map [list $prefix ""] [info vars $prefix*]
}
#****

#****f* object/Objdump
# NAME
# Objdump
# SYNOPSIS
# itrajcomp::Objdump self
# FUNCTION
# Print list of variables and values
# PARAMETERS
# * self -- object
# SOURCE
proc itrajcomp::Objdump {self} {
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
#****

#****f* object/Objlist
# NAME
# Objlist
# SYNOPSIS
# itrajcomp::Objlist
# FUNCTION
# Print list of objects
# RETURN VALUE
# List of objects
# SOURCE
proc itrajcomp::Objlist {} {
  return [namespace children [namespace current]]
}
#****

#****f* object/Objclean
# NAME
# Objclean
# SYNOPSIS
# itrajcomp::Objclean
# FUNCTION
# Remove all objects
# SOURCE
proc itrajcomp::Objclean {} {
  foreach self [namespace children [namespace current]] {
    [namespace current]::Objdelete [string trimleft $self [namespace current]]
  }
}
#****
