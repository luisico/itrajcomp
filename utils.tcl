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

# utils.tcl
#    Utility functions.


proc itrajcomp::AddRep1 {i j sel style color} {
  # Add 1 representation to vmd
  mol rep $style
  mol selection $sel
  mol color $color
  mol addrep $i
  set name1 [mol repname $i [expr {[molinfo $i get numreps]-1}]]
  mol drawframes $i [expr {[molinfo $i get numreps]-1}] $j
  return $name1
}


proc itrajcomp::DelRep1 {reps} {
  # Delete 1 representation from vmd
  foreach r $reps {
    lassign [split $r :] i name
    mol delrep [mol repindex $i $name] $i
  }
}


proc itrajcomp::ParseMols {mols idlist {sort 1} } {
  # Parse molecule selection
  if {$mols eq "id"} {
    set mols $idlist
  }
  if {[lsearch $mols "all"] > -1} {
    set mols [molinfo list]
  }
  if {[set indices [lsearch -all $mols "top"]] > -1} {
    foreach i $indices {
      lset mols $i [molinfo top]
    }
  }
  if {[lsearch $mols "act"] > -1} {
    set mols [[namespace current]::GetActive]
  }
  if {[set indices [lsearch -all $mols "to"]] > -1} {
    foreach i $indices {
      set a [expr [lindex $mols [expr $i-1]] + 1]
      set b [expr [lindex $mols [expr $i+1]] - 1]
      set mols [lreplace $mols $i $i]
      for {set r $b} {$r >= $a} {set r [expr {$r-1}]} {
        set mols [linsert $mols $i $r]
      }
    }
  }
  if {$sort} {
    set mols [lsort -unique -integer $mols]
  }
  
  set invalid_mols {}
  for {set i 0} {$i < [llength $mols]} {incr i} {
    if {[lsearch [molinfo list] [lindex $mols $i]] > -1} {
      lappend valid_mols [lindex $mols $i]
    } else {
      lappend invalid_mols [lindex $mols $i]
    }
  }

  if {[llength $invalid_mols]} {
    tk_messageBox -title "Warning " -message "The following mols are not available: $invalid_mols" -parent .itrajcomp
    return -1
  } else {
    return $valid_mols
  }
}  


proc itrajcomp::ParseFrames {def mols skip idlist} {
  # Parse frame selection
  # Creates a list of lists (one for each mol)
  set frames {}
  foreach mol $mols {
    set list {}
    set nframes [molinfo $mol get numframes]
    if {$def == "all"} {
      for {set n 0} {$n < $nframes} {incr n} {
        lappend list $n
      }
    } elseif {$def == "cur"} {
      set list [molinfo $mol get frame]
    } elseif {$def == "id"} {
      if {[set indices [lsearch -all $idlist "to"]] > -1} {
        foreach i $indices {
          set a [expr [lindex $idlist [expr $i-1]] + 1]
          set b [expr [lindex $idlist [expr $i+1]] - 1]
          set idlist [lreplace $idlist $i $i]
          for {set r $b} {$r >= $a} {set r [expr {$r-1}]} {
            set idlist [linsert $idlist $i $r]
          }
        }
      }
      set list $idlist

      # Check frames are within mol range
      foreach f $list {
        if {$f >= $nframes} {
          tk_messageBox -title "Warning " -message "Frame $f is out of range for mol $mol" -parent .itrajcomp
          return -1
        }
      }
    }

    if {$skip} {
      set result {}
      set s [expr {$skip+1}]
      for {set i 0} {$i < [llength $list]} {incr i $s} {
        lappend result [lindex $list $i]
      }
      set list $result
    }

    lappend frames $list
  }

  return $frames
}


proc itrajcomp::SplitFrames {frames} {
  # Split frames for molecules
  set text {}
  for {set i 0} {$i < [llength $frames]} {incr i} {
    lappend text "\[[[namespace current]::Range [lindex $frames $i]]\]"
  }
  return [join $text]
}


proc itrajcomp::Range {numbers} {
  # Convert list of numbers range to a simple string

  set numbers [lsort -unique -integer $numbers]

  if {[llength $numbers] == 1} {
    return $numbers
  }

  set start 0
  set end 0
  for {set i 1} {$i < [llength $numbers]} {incr i} {
    set a [lindex $numbers [expr {$i-1}]]
    set b [lindex $numbers $i]
    if { [expr {$a+1}] == $b } {
      set end $i
    } else {
      if {$start != $end} {
        lappend results "[lindex $numbers $start]-$a"
      } else {
        lappend results $a
      }
      set start $i
    }
  }
  if {[lindex $numbers $start] != $b} {
    lappend results "[lindex $numbers $start]-$b"
  } else {
    lappend results $b
  }
  return [join $results]
}


proc itrajcomp::CombineMols {args} {
  # Return a list of unique molecules
  set mols {}
  foreach i $args {
    foreach j $i {
      lappend mols $j
    }
  }
  return [lsort -unique $mols]
}


proc itrajcomp::Mean {values} {
  # Calculate the mean of a list of values
  set tot 0.0
  foreach n $values {
    set tot [expr {$tot+$n}]
  }
  set num [llength $values]
  set mean [expr {$tot/double($num)}]
  return $mean
}


proc itrajcomp::GetKeys {rms_values sort mol_ref mol_tar} {
  # Not used, remove?
  upvar $rms_values values
  
  if {$mol_ref == "all" && $mol_tar == "all"} {
    set sort 1
  }

  if {$sort} {
    set skeys [lsort -dictionary [array names values]]
  } else {
    set nref [ParseMols mol_ref 0]
    set ntar [ParseMols mol_tar 0]
    set skeys {}
    foreach i $mol_ref {
      foreach j $mol_tar {
        foreach k [lsort -dictionary [array names values "$i:*,$j:*"]] {
          lappend skeys $k
        }
      }
    }
  }
  return $skeys
}


proc itrajcomp::GetActive {} {
  # Identify the active molecule
  set active {}
  foreach i [molinfo list] {
    if { [molinfo $i get active] } {
      lappend active $i
    }
  }
  return $active
}


proc itrajcomp::ParseSel {orig selmod} {
  # Parse a selection text
  regsub -all "\#.*?\n" $orig  ""  temp1
  regsub -all "\n"      $temp1 " " temp2
  regsub -all " *$"     $temp2 ""  temp3
  if {$temp3 == "" } {
    set temp3 "all"
  }
  switch -exact $selmod {
    tr {
      append sel "($temp3) and name CA"
    }
    bb {
      append sel "($temp3) and name C CA N"
    }
    sc {
      append sel "($temp3) and sidechain"
    }
    no -
    default {
      append sel $temp3
    }
  }
  return $sel
}


proc itrajcomp::CheckNatoms {self} {
  # Check same number of atoms in two selections
  array set sets [array get ${self}::sets]
  
  foreach i $sets(mol1) {
    set natoms($i) [[atomselect $i $sets(sel1) frame 0] num]
  }
  
  if {$sets(mol2) != ""} {
    foreach i $sets(mol2) {
      set n [[atomselect $i $sets(sel2) frame 0] num]
      if {[info exists natoms($i)] && $natoms($i) != $n} {
        tk_messageBox -title "Warning " -message "Difference in atom selection between Set1 ($natoms($i)) and Set2 ($n) for molecule $i" -parent .itrajcomp
        return -1
      }
    }
  }

  foreach i $sets(mol_all) {
    foreach j $sets(mol_all) {
      if {$i < $j} {
        if {$natoms($i) != $natoms($j)} {
          tk_messageBox -title "Warning " -message "Selections differ for molecules $i ($natoms($i)) and $j ($natoms($j))" -parent .itrajcomp
          return -1
        }
      }
    }
  }
  
  return 1
}


proc itrajcomp::ParseKey {self key} {
  # Parse a key to get mol, frame and selection back
  array set graph_opts [array get ${self}::graph_opts]
  array set opts [array get ${self}::opts]
  array set sets [array get ${self}::sets]
  set indices [split $key :]

  switch $graph_opts(type) {
    frames {
      lassign $indices m f
      set tab_rep [set ${self}::tab_rep]
      set s [[namespace current]::ParseSel [$tab_rep.disp1.sel.e get 1.0 end] ""]
    }
    segments {
      switch $opts(segment) {
        byres {
          set m [join [set ${self}::sets(mol_all)] " "]
          set f [join [set ${self}::sets(frame1)] " "]
          set tab_rep [set ${self}::tab_rep]
          set extra [[namespace current]::ParseSel [$tab_rep.disp1.sel.e get 1.0 end] ""]
          set s "residue [lindex $indices 0] and ($extra)"
        }
        byatom {
          set m [join [set ${self}::sets(mol_all)] " "]
          set f [join [set ${self}::sets(frame1)] " "]
          set s "index [lindex $indices 0]"
        }
      }
    }
  }

  return [list $m $f $s]
}


proc itrajcomp::PrepareData {self} {
  set data_index [set ${self}::data_index]
  array set data0 [array get ${self}::data0]
  set keys [array names data0]

  switch [set ${self}::datatype(mode)] {
    single {
      array set data1 [array get data0]
      lassign [[namespace current]::minmax [array get data1]] min1 max1
    }

    multiple {
      foreach key $keys {
        set data1($key) [[namespace current]::stats $data0($key)]
        for {set i 0} {$i < [llength $data1($key)]} {incr i} {
          lappend values($i) [lindex $data1($key) $i]
        }
      }
      set min1 {}
      set max1 {}
      set ni $i
      for {set i 0} {$i < $ni} {incr i} {
        lassign [[namespace current]::stats $values($i) 0] mean min max
        lappend min1 $min
        lappend max1 $max
      }
    }

    dual {
      if {[set ${self}::datatype(ascii)]} {
        foreach key $keys {
          set data1($key) [lindex $data0($key) 0]
        }
        lassign [[namespace current]::minmax [array get data1]] min1 max1
      } else {
        foreach key $keys {
          set data1($key) [concat [lindex $data0($key) 0] [[namespace current]::stats [lindex $data0($key) 1]]]
          for {set i 0} {$i < [llength $data1($key)]} {incr i} {
            lappend values($i) [lindex $data1($key) $i]
          }
        }
        set min1 {}
        set max1 {}
        set ni $i
        for {set i 0} {$i < $ni} {incr i} {
          lassign [[namespace current]::stats $values($i) 0] mean min max
          lappend min1 $min
          lappend max1 $max
        }
      }
    }

  }
  array set ${self}::data1 [array get data1]

  set ${self}::min1 $min1
  set ${self}::max1 $max1

  [namespace current]::TransformData $self
}


proc itrajcomp::TransformData {self {type "copy"} {graph 0}} {
  set data_index [set ${self}::data_index]
  set formats [set ${self}::graph_opts(formats)]
  
  # Source data
  if {$type == "copy" || [set ${self}::transform_data1] == 1} {
    array set data1 [array get ${self}::data1]
    set min1 [lindex [set ${self}::min1] $data_index]
    set max1 [lindex [set ${self}::max1] $data_index]
  } else {
    array set data1 [array get ${self}::data]
    set min1 [set ${self}::min]
    set max1 [set ${self}::max]
  }

  set keys [array names data1]
  
  switch $type {
    copy {
      foreach key $keys {
        set data($key) [lindex $data1($key) $data_index]
      }
      lassign [[namespace current]::minmax [array get data]] min max
    }

    inverse {
      foreach key $keys {
        if {[lindex $data1($key) $data_index] != 0} {
          set data($key) [expr {1.0 / [lindex $data1($key) $data_index]}]
        } else {
          set data($key) [lindex $data1($key) $data_index]
        }
      }
      lassign [[namespace current]::minmax [array get data]] min max
      set formats "f"
    }

    norm_minmax {
      set minmax [expr {$max1-$min1}]
      foreach key $keys {
        set data($key) [expr {([lindex $data1($key) $data_index]-$min1) / $minmax}]
      }
      set min 0
      set max 1
      set formats "f"
    }

    norm_exp {
      foreach key $keys {
        set data($key) [expr {1.0 - exp(-[lindex $data1($key) $data_index])}]
      }
      lassign [[namespace current]::minmax [array get data]] min max
      set formats "f"
    }

    norm_expmin {
      foreach key $keys {
        set data($key) [expr {1.0 - exp(-([lindex $data1($key) $data_index]-$min1))}]
      }
      lassign [[namespace current]::minmax [array get data]] min max
      set formats "f"
    }
  }

  # Send back to object
  set ${self}::min $min
  set ${self}::max $max
  array set ${self}::data [array get data]
  # TODO: vals should also be updated? used in save and load, mostly

  # Update output format of values
  lassign [[namespace current]::_format $formats] format_data format_scale
  set ${self}::graph_opts(format_data) $format_data
  set ${self}::graph_opts(format_scale) $format_scale

  # Update plot
  if {$graph == 1} {
    [namespace current]::UpdateGraph $self
  }

  return
}


proc itrajcomp::minmax {values_array} {
  # Calculate max and min
  array set data $values_array

  set z 1
  set min 0
  set max 0
  foreach key [array names data] {
    if {$z} {
      set min $data($key)
      set max $data($key)
      set z 0
    }
    if {$data($key) > $max} {
      set max $data($key)
    } elseif {$data($key) < $min} {
      set min $data($key)
    }
  }
  return [list $min $max]
}


proc itrajcomp::stats {values {calc_std 1}} {
  # Calculate mean, std, min, max

  set mean 0.0
  set min [lindex $values 0]
  set max [lindex $values 0]
  set n [expr {double([llength $values])}]
  foreach val $values {
    set mean [expr {$mean + $val}]
    if {$val > $max} {
      set max $val
    } elseif {$val < $min} {
      set min $val
    }
  }
  set mean [expr {$mean / $n}]

  if {$calc_std} {
    set std 0.0
    #set sumc 0.0   ### http://en.wikipedia.org/wiki/Algorithms_for_calculating_variance
    foreach val $values {
      set tmp [expr {$val - $mean}]
      set std [expr {$std + $tmp*$tmp}]
      #set sumc [expr {$sumc + $tmp}]
    }  
    #set std2 [expr {sqrt( ($std - ($sumc*$sumc)/$n) / ($n-1) )}]
    set std [expr {sqrt($std / ($n-1))}]
    return [list $mean $std $min $max]
  } else {
    return [list $mean $min $max]
  }
}


proc itrajcomp::wlist {{w .}} {
  # Return a list of TKwidgets
  set list [list $w]
  foreach widget [winfo children $w] {
    set list [concat $list [wlist $widget]]
  }
  return $list
}


proc itrajcomp::ColorScale {val max min {s 1.0} {l 1.0}} {
  # Color scale transformation
  if {$max == 0} {
    set max 1.0
  }

  #set h [expr {2.0/3.0}]
  set h 0.666666666667
  #set l 1.0 luminosity
  #set s .5 saturation

  set r 0.5
  set g 0.5
  set b 0.5
  set diff [expr {$max-$min}]
  # TODO: better way to check for 0.0?
  if ([expr {$diff == 0.0 ? 0 : 1}]) {
      lassign [hls2rgb [expr {($h - $h*($val-$min)/$diff)}] $l $s] r g b
  }

  set r [expr {int($r*255)}]
  set g [expr {int($g*255)}]
  set b [expr {int($b*255)}]
  return [format "#%.2X%.2X%.2X" $r $g $b]
}


proc itrajcomp::hls2rgb {h l s} {
  # Transform from hls to rgb colors
  #http://wiki.tcl.tk/666
  # h, l and s are floats between 0.0 and 1.0, ditto for r, g and b
  # h = 0   => red
  # h = 1/3 => green
  # h = 2/3 => blue
  
  set h6 [expr {($h-floor($h))*6}]
  set r [expr {  $h6 <= 3 ? 2-$h6
                 : $h6-4}]
  set g [expr {  $h6 <= 2 ? $h6
                 : $h6 <= 5 ? 4-$h6
                 : $h6-6}]
  set b [expr {  $h6 <= 1 ? -$h6
                 : $h6 <= 4 ? $h6-2
                 : 6-$h6}]
  set r [expr {$r < 0.0 ? 0.0 : $r > 1.0 ? 1.0 : double($r)}]
  set g [expr {$g < 0.0 ? 0.0 : $g > 1.0 ? 1.0 : double($g)}]
  set b [expr {$b < 0.0 ? 0.0 : $b > 1.0 ? 1.0 : double($b)}]
  
  set r [expr {(($r-1)*$s+1)*$l}]
  set g [expr {(($g-1)*$s+1)*$l}]
  set b [expr {(($b-1)*$s+1)*$l}]
  return [list $r $g $b]
}


proc itrajcomp::flash_widget {w {color yellow}} {
  # Flash a widget with yellow

  set oldcolor [$w cget -background]
  $w configure -background $color
  
  if [catch { 
    $w flash
  } msg] {
    [namespace current]::_flash_widget $w 0 $oldcolor
  }

  $w configure -background $oldcolor
}


proc itrajcomp::_flash_widget {w i color} {
  set oldcolor [$w cget -background]
  $w config -background $color
  incr i
  if {$i > 4} {
    return
  }
  after 60 [list [namespace current]::_flash_widget $w $i $oldcolor]
}


proc itrajcomp::highlight_widget {w {time 1000} {color yellow}} {
  # Highlight a widget with yellow
  set oldcolor [$w cget -background]
  $w config -background $color
  after $time [list $w config -background $oldcolor]
}


proc itrajcomp::_format {formats} {
  switch $formats {
    f {
      set data "%8.4f"
      set scale "%4.2f"
    }
    i {
      set data "%8i"
      set scale "%4i"
    }
  }

  return [list $data $scale]
}

### benchmark
#  set NREPEAT 10000
#  scan [time {
#    [namespace current]::stats $vals
#  } $NREPEAT] {%d} result
#  puts "$NREPEAT : $result"
### benchmark


proc itrajcomp::concat_opts {self} {
  # Concatenate opts in one line
  set options {}
  
  array set opts [array get ${self}::opts]
  if {$opts(diagonal)} {
    lappend options "diagonal"
  }
  
  foreach v [array names opts] {
    if { $v == "type" || $v == "diagonal" || $v == "segment"} {
      continue
    }
    if {$opts($v)} {
      lappend options "$v"
    }
  }

  return [join $options ", "]
}


proc itrajcomp::dataframe_yset args {
  variable dataframe
  eval [linsert $args 0 $dataframe.scrbar set]
  [namespace current]::dataframe_yview moveto [lindex [$dataframe.scrbar get] 0]
}


proc itrajcomp::dataframe_yview args {
  variable datalist
  foreach key [array names datalist] {
    eval [linsert $args 0 $datalist($key) yview]
  }
}


proc itrajcomp::dataframe_sel {widget} {
  variable datalist

  set sel [$widget curselection]
  foreach key [array names datalist] {
    $datalist($key) selection clear 0 end
    foreach item $sel {
      $datalist($key) selection set $item
    }
  }
}


proc itrajcomp::dataframe_color { {colorize 0} } {
  variable datalist

  set color "grey85"
  for {set i 0} {$i < [$datalist(id) size]} {incr i} {
    if {$colorize} {
      set coln [$datalist(id) get $i]
      while {$coln > 15} {
        set coln [expr {$coln - 16}]
      }
      set color [index2rgb $coln]
    } else {
      if {$color == "grey80"} {
        set color "grey85"
      } else {
        set color "grey80"
      }
    }
    foreach key [array names datalist] {
      $datalist($key) itemconfigure $i -background $color
    }
  }
}


proc itrajcomp::dataframe_mapper {widget} {
  variable datalist

  set sel [$widget curselection]
  set num [$datalist(id) get $sel]
  set name "itcObj$num"
  set window ".${name}_main"
  
  case [wm state $window] {
    iconic {
      wm deiconify $window
    }
    normal {
      wm withdraw $window
    }
    withdrawn {
      wm deiconify $window
    }
    default {
      return
    }
  }
  
  [namespace current]::UpdateRes
}
