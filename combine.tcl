#****h* itrajcomp/combine
# NAME
# combine -- Combine objects to create a new one
#
# AUTHOR
# Luis Gracia
#
# DESCRIPTION
# Combine objects to create a new one.
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

#****f* combine/Combine
# NAME
# Combine
# SYNOPSIS
# itrajcomp::Combine
# FUNCTION
# Combine objects GUI
# SOURCE
proc itrajcomp::Combine {} {
  variable c
  set debug 0

  set c [toplevel .itrajcompcomb]
  wm title $c "iTrajComp - Combine"
  wm iconname $c "iTrajComp" 
  wm resizable $c 1 0

  frame $c.obj
  pack $c.obj -side top -anchor w
  label $c.obj.title -text "Objects:"
  pack $c.obj.title -side top -anchor w

  frame $c.obj.list
  pack $c.obj.list -side top -anchor w
  listbox $c.obj.list.l -selectmode single -exportselection no -height 5 -width 20 -yscrollcommand "$c.obj.list.scy set"
  scrollbar $c.obj.list.scy -orient vertical -command "$c.obj.list.l yview"
  pack $c.obj.list.l -side left -anchor w 
  pack $c.obj.list.scy -side left -anchor w -fill y
  
  bind $c.obj.list.l <Double-Button-1> "[namespace current]::CombineSel %W"

  frame $c.formula
  pack $c.formula -side top -anchor w
  label $c.formula.l -text "Formula:"
  entry $c.formula.e -textvariable [namespace current]::formula
  pack $c.formula.l $c.formula.e -side left -expand yes -fill x

  button $c.combine -text "Combine" -command [namespace code {Objcombine $formula}]
  button $c.update -text "Update" -command "[namespace current]::CombineUpdate $c.obj.list.l"
  pack $c.combine $c.update -side top

  CombineUpdate $c.obj.list.l
}
#*****

#****f* combine/CombineSel
# NAME
# CombineSel
# SYNOPSIS
# itrajcomp::CombineSel widget
# FUNCTION
# Add selected object to the formula
# PARAMETERS
# * widget -- widget to display objects
# SOURCE
proc itrajcomp::CombineSel {widget} {
  variable c

  set sel [$widget curselection]
  set obj [$widget get $sel]
  set num [string trim $obj {itc}]
  puts "$sel - $obj - $num"
  $c.formula.e insert insert "\$$num"
}
#*****

#****f* combine/CombineUpdate
# NAME
# CombineUpdate
# SYNOPSIS
# itrajcomp::CombineUpdate widget
# FUNCTION
# Update the list of object to combine
# PARAMETERS
# * widget -- widget to update
# SOURCE
proc itrajcomp::CombineUpdate {widget} {
  #  variable combobj

  $widget selection set 0 end
  foreach i [lsort -integer -decreasing [$widget curselection]] {
    $widget delete 0 $i
  }
  
  #  set combobj {}
  foreach obj [[namespace current]::Objlist] {
    set name [namespace tail $obj]
    set num [string trim $name {itc}]
    set objects($num) $name
  }

  foreach num [lsort -integer [array names objects]] {
    set name $objects($num)
    $widget insert end "$name"
    #    lappend combobj $num
  }
}
#*****

#****f* combine/Objcombine
# NAME
# Objcombine
# SYNOPSIS
# itrajcomp::Objcombine formula
# FUNCTION
# Creates a new object based on formula
# PARAMETERS
# * formula -- formula
# SOURCE
proc itrajcomp::Objcombine {formula} {
  #  variable combobj

  #puts "FORMULA: $formula"
  set line $formula
  regsub -all {\$(\d+)} $formula {$d(\1)} formula
  #puts "FORMULA: $formula"
  #puts "OBJECTS: $combobj"

  while { [regexp {\$(\d+)(.*)} $line junk obj line] } {
    set self($obj) "itc$obj"
    lappend selflist $obj
  }

  if {[llength [array names self]] == 0} {
    tk_messageBox -title "Error" -message "No objects found in formula!"
    return
  }

  set s0 [lindex $selflist 0]

  foreach s [array names self] {
    set mol1($s)        [set $self($s)::sets(mol1)]
    set mol2($s)        [set $self($s)::sets(mol2)]
    set frame1($s)      [set $self($s)::sets(frame1)]
    set frame2($s)      [set $self($s)::sets(frame2)]
    set sel1($s)        [set $self($s)::sets(sel1)]
    set sel2($s)        [set $self($s)::sets(sel2)]
    set mode($s)        [set $self($s)::opts(mode)]
    set format_data($s) [set $self($s)::opts(format_data)]
    set format_key($s)  [set $self($s)::opts(format_key)]
    set keys($s)        [set $self($s)::keys]
    set data1($s)       [array get $self($s)::data1]
    set data_index($s)  [set $self($s)::data_index]
  }
  
  # ToDo: check more things, like data has same format
  foreach check [list "opts(calctype)"] {
    set test [set $self($s0)::$check]
    for {set i 1} {$i < [llength $selflist]} {incr i} {
      if {[set $self([lindex $selflist $i])::$check] != $test} {
        tk_messageBox -title "Error" -message "$check is not the same among the objects, cannot combine objects" -type ok
        return
      }
    }
  }

  # Keys must be the same
  set test [llength [set $self($s0)::keys]]
  for {set i 1} {$i < [llength $selflist]} {incr i} {
    if {[llength [set $self([lindex $selflist $i])::keys]] != $test} {
      tk_messageBox -title "Error" -message "length of objects is not the same, cannot combine objects" -type ok
      return
    }
  }

  # Create new object
  set obj [eval [namespace current]::Objnew ":auto"]

  # sets (by now parameters for combined object come from object with smaller number)
  array set ${obj}::sets [array get $self($s0)::sets]

  # opts
  array set opts {
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
  set ${obj}::opts(collections) "combined"
  set ${obj}::opts(calctype) "combine"
  set ${obj}::opts(mode) $mode($s0)

  # Gui opts
  set ${obj}::guiopts(diagonal) [set $self($s0)::guiopts(diagonal)]
  # TODO: is not working with segments
  if {$mode($s0) == "segments"} {
    set ${obj}::guiopts(segment) [set $self($s0)::guiopts(segment)]
    array set ${obj}::segments [array get $self($s0)::segments]
  }
  
  # other options
  set ${obj}::data_index 0

  # Combine with formula
  foreach key $keys($s0) {
    foreach s [array names self] {
      array set d1 $data1($s)
      #puts $data1($s)
      #puts [array get d1]
      set d($s) [lindex $d1($key) $data_index($s)]
      #puts "$s -- $key -- $data_index($s)  --- $d($s)"
    }
    set result [expr $formula]
    set ${obj}::data0($key) $result
    puts -nonewline "$key"
    foreach s $selflist {
      puts -nonewline [format " %8.3f" $d($s)]
    }
    puts [format "   = %8.3f" $result]
  }

  [namespace current]::PrepareData $obj
  [namespace current]::Status "Creating graph for $obj ..."
  [namespace current]::itcObjGui $obj
  [namespace current]::UpdateRes
}
#*****
