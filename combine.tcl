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

# combine.tcl
#    Combine objects to create a new one.


proc itrajcomp::Combine {} {
  # Combine to objects
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
  listbox $c.obj.list.l -selectmode extended -exportselection no -height 5 -width 20 -yscrollcommand "$c.obj.list.scy set"
  scrollbar $c.obj.list.scy -orient vertical -command "$c.obj.list.l yview"
  pack $c.obj.list.l -side left -anchor w 
  pack $c.obj.list.scy -side left -anchor w -fill y

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

proc itrajcomp::CombineUpdate {widget} {
  # Update the list of object to combine
  variable combobj

  $widget selection set 0 end
  foreach i [lsort -integer -decreasing [$widget curselection]] {
    $widget delete 0 $i
  }
  
  set combobj {}
  foreach obj [[namespace current]::Objlist] {
    set name [namespace tail $obj]
    set num [string trim $name {itcObj}]
    set objects($num) $name
  }

  foreach num [lsort -integer [array names objects]] {
    set name $objects($num)
    $widget insert end "$name"
    lappend combobj $num
  }
}

proc itrajcomp::Objcombine {formula} {
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

  if {[llength [array names self]] == 0} {
    tk_messageBox -title "Warning" -message "No objects found in formula!"
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
    set type($s)        [set $self($s)::graph_opts(type)]
    set format_data($s) [set $self($s)::graph_opts(format_data)]
    set format_key($s)  [set $self($s)::graph_opts(format_key)]
    set keys($s)        [set $self($s)::keys]
    set data1($s)       [array get $self($s)::data1]
    set data_index($s)  [set $self($s)::data_index]
  }
  
  # ToDo: check more things, like data has same format
  foreach check [list "opts(type)"] {
    set test [set $self($s0)::$check]
    for {set i 1} {$i < [llength $selflist]} {incr i} {
      if {[set $self([lindex $selflist $i])::$check] != $test} {
	tk_messageBox -title "Warning" -message "$check is not the same among the objects, cannot combine objects" -type ok
	return
      }
    }
  }

  # Keys must be the same
  set test [llength [set $self($s0)::keys]]
  for {set i 1} {$i < [llength $selflist]} {incr i} {
    if {[llength [set $self([lindex $selflist $i])::keys]] != $test} {
      tk_messageBox -title "Warning" -message "length of objects is not the same, cannot combine objects" -type ok
      return
    }
  }

  # Create new object
  set obj [eval [namespace current]::Objnew ":auto"]

  # sets (by now parameters for combined object come from object with smaller number)
  array set ${obj}::sets [array get $self($s0)::sets]

  # datatype
  set ${obj}::datatype(mode) "single"
  set ${obj}::datatype(sets) "combined"
 
  # opts
  set ${obj}::opts(type) "combine"
  set ${obj}::opts(diagonal) [set $self($s0)::opts(diagonal)]
  # TODO: is not working with segments
  if {$type($s0) == "segments"} {
    set ${obj}::opts(segment) [set $self($s0)::opts(segment)]
    array set ${obj}::segments [array get $self($s0)::segments]
  }

  # graph_opts
  array set graph_opts {
    formats "f" format_key ""
    format_data "" format_scale ""
    rep_style1 NewRibbons
    rep_color1 Molecule
    rep_colorid1 0
  }
  set graph_opts(type) $type($s0)
  array set ${obj}::graph_opts [array get graph_opts]

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
}
