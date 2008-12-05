#****h* itrajcomp/utils
# NAME
# utils -- Utility functions
#
# AUTHOR
# Luis Gracia
#
# DESCRIPTION
# Utility functions.
# 
# SEE ALSO
# More documentation can be found in:
# * README.txt
# * itrajcomp.tcl
# * http://physiology.med.cornell.edu/faculty/hweinstein/vmdplugins/itrajcomp
#
# COPYRIGHT
# Copyright (C) 2005-2008 by Luis Gracia <lug2002@med.cornell.edu> 
#
#****

#****f* utils/AddRep1
# NAME
# AddRep1
# SYNOPSIS
# itrajcomp::AddRep1 i j sel style color
# FUNCTION
# Add 1 representation to vmd
# PARAMETERS
# * mol -- molecule
# * frame -- frame
# * sel -- selection
# * style -- style
# * color -- color
# RETURN VALUE
# Representation name
# SOURCE
proc itrajcomp::AddRep1 {mol frame sel style color} {
  mol rep $style
  mol selection $sel
  mol color $color
  mol addrep $mol
  set name1 [mol repname $mol [expr {[molinfo $mol get numreps]-1}]]
  mol drawframes $mol [expr {[molinfo $mol get numreps]-1}] $frame
  return $name1
}
#*****

#****f* utils/DelRep1
# NAME
# DelRep1
# SYNOPSIS
# itrajcomp::DelRep1 reps
# FUNCTION
# Delete representations from vmd
# PARAMETERS
# * reps -- list of representation names to delete
# SOURCE
proc itrajcomp::DelRep1 {reps} {
  foreach r $reps {
    lassign [split $r :] i name
    mol delrep [mol repindex $i $name] $i
  }
}
#*****

#****f* utils/ParseMols
# NAME
# ParseMols
# SYNOPSIS
# itrajcomp::ParseMols
# FUNCTION
# Parse molecule selection
# PARAMETERS
# * mols -- molecule definition
# * idlist -- list of molecule ids
# * sort -- flag to return a sorted list of molecules without repetitions
# RETURN VALUE
# List of molecules
# SOURCE
proc itrajcomp::ParseMols {mols idlist {sort 1} } {
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
    tk_messageBox -title "Error" -message "The following mols are not available: $invalid_mols" -parent .itrajcomp
    return -1
  } else {
    return $valid_mols
  }
}  
#*****

#****f* utils/ParseFrames
# NAME
# ParseFrames
# SYNOPSIS
# itrajcomp::ParseFrames def mols skip idlist
# FUNCTION
# Parse frame selection
# PARAMETERS
# * def -- frames definition 
# * mols -- molecules
# * skip -- skip every this frames
# * idlist -- list of frames ids
# RETURN VALUE
# List containing a list of frames per molecule
# SOURCE
proc itrajcomp::ParseFrames {def mols skip idlist} {
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
          tk_messageBox -title "Error" -message "Frame $f is out of range for mol $mol" -parent .itrajcomp
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
#*****

#****f* utils/SplitFrames
# NAME
# SplitFrames
# SYNOPSIS
# itrajcomp::SplitFrames frames
# FUNCTION
# Split frames for molecules
# PARAMETERS
# * frames -- list of frames
# RETURN VALUE
# String with the list of frames ina compact way.
# SOURCE
proc itrajcomp::SplitFrames {frames} {
  set text {}
  for {set i 0} {$i < [llength $frames]} {incr i} {
    lappend text "\[[[namespace current]::Range [lindex $frames $i]]\]"
  }
  return [join $text]
}
#*****

#****f* utils/Range
# NAME
# Range
# SYNOPSIS
# itrajcomp::Range numbers
# FUNCTION
# Convert list of numbers range to a simple string
# PARAMETERS
# * numbers -- list of numbers
# RETURN VALUE
# String with the range
# SOURCE
proc itrajcomp::Range {numbers} {
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
#*****

#****f* utils/CombineMols
# NAME
# CombineMols
# SYNOPSIS
# itrajcomp::CombineMols args
# FUNCTION
# Return a list of unique molecules
# PARAMETERS
# * args -- list of molecules
# RETURN VALUE
# List of molecules
# SOURCE
proc itrajcomp::CombineMols {args} {
  set mols {}
  foreach i $args {
    foreach j $i {
      lappend mols $j
    }
  }
  return [lsort -unique $mols]
}
#*****

#****f* utils/Mean
# NAME
# Mean
# SYNOPSIS
# itrajcomp::Mean values
# FUNCTION
# Calculate the mean of a list of values
# PARAMETERS
# * values -- values
# RETURN VALUE
# Mean
# SOURCE
proc itrajcomp::Mean {values} {
  set tot 0.0
  foreach n $values {
    set tot [expr {$tot+$n}]
  }
  set num [llength $values]
  set mean [expr {$tot/double($num)}]
  return $mean
}
#*****

#****f* utils/GetActive
# NAME
# GetActive
# SYNOPSIS
# itrajcomp::GetActive
# FUNCTION
# Identify the active molecule
# RETURN VALUE
# ID of active molecule
# SOURCE
proc itrajcomp::GetActive {} {
  set active {}
  foreach i [molinfo list] {
    if { [molinfo $i get active] } {
      lappend active $i
    }
  }
  return $active
}
#*****

#****f* utils/ParseSel
# NAME
# ParseSel
# SYNOPSIS
# itrajcomp::ParseSel orig selmod
# FUNCTION
# Parse a selection text
# PARAMETERS
# * orig --  selection string
# * selmod -- selection modifier
# RETURN VALUE
# Selection string
# SOURCE
proc itrajcomp::ParseSel {orig selmod} {
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
#*****

#****f* utils/CheckNatoms
# NAME
# CheckNatoms
# SYNOPSIS
# itrajcomp::CheckNatoms self
# FUNCTION
# Checks if the two sets of selections in an object have the same number of atoms.
# PARAMETERS
# * self -- object
# RETURN VALUE
# Status code
# SOURCE
proc itrajcomp::CheckNatoms {self} {
  array set sets [array get ${self}::sets]
  
  foreach i $sets(mol1) {
    set natoms($i) [[atomselect $i $sets(sel1) frame 0] num]
  }
  
  if {$sets(mol2) != ""} {
    foreach i $sets(mol2) {
      set n [[atomselect $i $sets(sel2) frame 0] num]
      if {[info exists natoms($i)] && $natoms($i) != $n} {
        tk_messageBox -title "Error" -message "Difference in atom selection between Set1 ($natoms($i)) and Set2 ($n) for molecule $i" -parent .itrajcomp
        return -1
      }
    }
  }

  foreach i $sets(mol_all) {
    foreach j $sets(mol_all) {
      if {$i < $j} {
        if {$natoms($i) != $natoms($j)} {
          tk_messageBox -title "Error" -message "Selections differ for molecules $i ($natoms($i)) and $j ($natoms($j))" -parent .itrajcomp
          return -1
        }
      }
    }
  }
  
  return 1
}
#*****

#****f* utils/ParseKey
# NAME
# ParseKey
# SYNOPSIS
# itrajcomp::ParseKey self key
# FUNCTION
# Parses a key to get mol, frame and selection back
# PARAMETERS
# * self -- object
# * key -- cell key
# RETURN VALUE
# List with mol, frame and selection
# SOURCE
proc itrajcomp::ParseKey {self key} {
  array set opts [array get ${self}::opts]
  array set guiopts [array get ${self}::guiopts]
  array set sets [array get ${self}::sets]
  set indices [split $key :]

  switch $opts(mode) {
    frames {
      lassign $indices m f
      set tab_rep [set ${self}::tab_rep]
      set s [[namespace current]::ParseSel [$tab_rep.frame.disp.sel.e get 1.0 end] ""]
    }
    segments {
      switch $guiopts(segment) {
        byres {
          set m [join [set ${self}::sets(mol_all)] " "]
          set f [join [set ${self}::sets(frame1)] " "]
          set tab_rep [set ${self}::tab_rep]
          set extra [[namespace current]::ParseSel [$tab_rep.frame.disp.sel.e get 1.0 end] ""]
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
#*****

#****f* utils/PrepareData
# NAME
# PrepareData
# SYNOPSIS
# itrajcomp::PrepareData self
# FUNCTION
# Prepares the data for the graph
# PARAMETERS
# * self -- object
# SOURCE
proc itrajcomp::PrepareData {self} {
  set data_index [set ${self}::data_index]
  array set data0 [array get ${self}::data0]
  set keys [array names data0]

  switch [set ${self}::opts(sets)] {
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
      if {[set ${self}::opts(ascii)]} {
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
#*****

#****f* utils/TransformData
# NAME
# TransformData
# SYNOPSIS
# itrajcomp::TransformData self transform graph
# FUNCTION
# Transforms the data
# PARAMETERS
# * self -- object
# * transform -- type of transformation
# * graph -- switch to update the graph
# SOURCE
proc itrajcomp::TransformData {self {transform "copy"} {graph 0}} {
  set data_index [set ${self}::data_index]
  set formats [set ${self}::opts(formats)]
  
  # Source data
  if {$transform == "copy" || [set ${self}::transform_data1] == 1} {
    array set data1 [array get ${self}::data1]
    set min1 [lindex [set ${self}::min1] $data_index]
    set max1 [lindex [set ${self}::max1] $data_index]
  } else {
    array set data1 [array get ${self}::data]
    set min1 [set ${self}::min]
    set max1 [set ${self}::max]
  }

  set keys [array names data1]
  
  switch $transform {
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
  set ${self}::opts(format_data) $format_data
  set ${self}::opts(format_scale) $format_scale

  # Update plot
  if {$graph == 1} {
    [namespace current]::UpdateGraph $self
  }
}
#*****

#****f* utils/minmax
# NAME
# minmax
# SYNOPSIS
# itrajcomp::minmax values_array
# FUNCTION
# Calculate max and min
# PARAMETERS
# * values -- array of values
# RETURN VALUE
# List with min and max values
# SOURCE
proc itrajcomp::minmax {values} {
  array set data $values

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
#*****

#****f* utils/stats
# NAME
# stats
# SYNOPSIS
# itrajcomp::stats values calc_std
# FUNCTION
# Calculate mean, std, min, max
# PARAMETERS
# * values -- list of values
# * calc_std -- flag to calculate standard dev
# RETURN VALUE
# List with mean, std (if requested), min and max values
# SOURCE
proc itrajcomp::stats {values {calc_std 1}} {
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
		if {$n > 1} {
			set std [expr {sqrt($std / ($n-1))}]
		}
			return [list $mean $std $min $max]
  } else {
    return [list $mean $min $max]
  }
}
#*****
### benchmark
#  set NREPEAT 10000
#  scan [time {
#    [namespace current]::stats $vals
#  } $NREPEAT] {%d} result
#  puts "$NREPEAT : $result"
### benchmark


#****f* utils/wlist
# NAME
# wlist
# SYNOPSIS
# itrajcomp::wlist widget
# FUNCTION
# Return a list of TKwidgets
# PARAMETERS
# * widget -- root widget 
# RETURN VALUE
# List of widgets 
# SOURCE
proc itrajcomp::wlist {{widget .}} {
  set list [list $widget]
  foreach w [winfo children $widget] {
    set list [concat $list [wlist $w]]
  }
  return $list
}
#*****

#****f* utils/ColorScale
# NAME
# ColorScale
# SYNOPSIS
# itrajcomp::ColorScale val max min s l
# FUNCTION
# Color scale transformation
# PARAMETERS
# * val -- value to color
# * max -- max value in scale
# * min -- min value in scale
# * s -- saturation
# * l -- luminosity
# RETURN VALUE
# String with rgb values
# SOURCE
proc itrajcomp::ColorScale {val max min {s 1.0} {l 1.0}} {
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
#*****

#****f* utils/hls2rgb
# NAME
# hls2rgb
# SYNOPSIS
# itrajcomp::hls2rgb h l s
# FUNCTION
# Transform from hls to rgb colors
# PARAMETERS
# * h -- hue
# * l -- luminosity
# * s -- saturation
# RETURN VALUE
# List of RGB values in 0-1 range
# SEE ALSO
# http://wiki.tcl.tk/666
# SOURCE
proc itrajcomp::hls2rgb {h l s} {
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
#*****

#****f* utils/flash_widget
# NAME
# flash_widget
# SYNOPSIS
# itrajcomp::flash_widget widget color
# FUNCTION
# Flash a widget with color
# PARAMETERS
# * widget -- widget
# * color -- color
# SOURCE
proc itrajcomp::flash_widget {widget {color yellow}} {
  set oldcolor [$widget cget -background]
  $widget configure -background $color
  
  if [catch { 
    $widget flash
  } msg] {
    [namespace current]::_flash_widget $widget 0 $oldcolor
  }

  $widget configure -background $oldcolor
}
#*****

#****f* utils/_flash_widget
# NAME
# _flash_widget
# SYNOPSIS
# itrajcomp::_flash_widget widget i color
# FUNCTION
# Flash a widget with a color. Custom implementation if [widget flash] fails
# PARAMETERS
# * widget -- widget
# * i -- repetition
# * color -- color
# SOURCE
proc itrajcomp::_flash_widget {widget i color} {
  set oldcolor [$widget cget -background]
  $widget config -background $color
  incr i
  if {$i > 4} {
    return
  }
  after 60 [list [namespace current]::_flash_widget $widget $i $oldcolor]
}
#*****

#****f* utils/highlight_widget
# NAME
# highlight_widget
# SYNOPSIS
# itrajcomp::highlight_widget widget time color
# FUNCTION
# Highlight a widget with color
# PARAMETERS
# * widget -- widget
# * time -- time in ms
# * color -- color
# SOURCE
proc itrajcomp::highlight_widget {widget {time 1000} {color yellow}} {
  set oldcolor [$widget cget -background]
  $widget config -background $color
  after $time [list $widget config -background $oldcolor]
}
#*****

#****f* utils/_format
# NAME
# _format
# SYNOPSIS
# itrajcomp::_format format
# FUNCTION
# Set data formats strings for data and scales. Normally used in printf functions.
# PARAMETERS
# * format -- format (f for float, i for integer)
# RETURN VALUE
# List with format strings
# SOURCE
proc itrajcomp::_format {format} {
  switch $format {
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
#*****

#****f* utils/concat_guiopts
# NAME
# concat_guiopts
# SYNOPSIS
# itrajcomp::concat_guiopts self
# FUNCTION
# Concatenate object guiopts in one line
# PARAMETERS
# * self -- object
# RETURN VALUE
# String with options
# SOURCE
proc itrajcomp::concat_guiopts {self} {
  set options {}
  
  array set guiopts [array get ${self}::guiopts]
  if {$guiopts(diagonal)} {
    lappend options "diagonal"
  }
  
  foreach v [array names guiopts] {
    if { $v == "diagonal" || $v == "segment"} {
      continue
    }
    if {$guiopts($v)} {
      lappend options "$v"
    }
  }

  return [join $options ", "]
}
#*****

#****f* utils/dataframe_yset
# NAME
# dataframe_yset
# SYNOPSIS
# itrajcomp::dataframe_yset args
# FUNCTION
# Call functions to move graph view when scrollbar changes
# PARAMETERS
# * args -- args
# SOURCE
proc itrajcomp::dataframe_yset {args} {
  variable dataframe
  eval [linsert $args 0 $dataframe.scrbar set]
  [namespace current]::dataframe_yview moveto [lindex [$dataframe.scrbar get] 0]
}
#*****

#****f* utils/dataframe_yview
# NAME
# dataframe_yview
# SYNOPSIS
# itrajcomp::dataframe_yview args
# FUNCTION
# Move graph to follow scrollbar
# PARAMETERS
# * args -- args
# SOURCE
proc itrajcomp::dataframe_yview {args} {
  variable datalist
  foreach key [array names datalist] {
    eval [linsert $args 0 $datalist($key) yview]
  }
}
#*****

#****f* utils/dataframe_sel
# NAME
# dataframe_sel
# SYNOPSIS
# itrajcomp::dataframe_sel widget
# FUNCTION
# Sets a row as selected in the results tab
# PARAMETERS
# * widget -- listbox widget
# SOURCE
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
#*****

#****f* utils/dataframe_color
# NAME
# dataframe_color
# SYNOPSIS
# itrajcomp::dataframe_color colorize
# FUNCTION
# Colors a row in the results tab
# PARAMETERS
# * colorize -- flag to color
# SOURCE
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
#*****

#****f* utils/dataframe_mapper
# NAME
# dataframe_mapper
# SYNOPSIS
# itrajcomp::dataframe_mapper widget
# FUNCTION
# Toogles iconification of an object by clicking its row in the results tab.
# PARAMETERS
# * widget -- listbox widget
# SOURCE
proc itrajcomp::dataframe_mapper {widget} {
  variable datalist

  set sel [$widget curselection]
  set num [$datalist(id) get $sel]
  set name "itc$num"
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
#*****
