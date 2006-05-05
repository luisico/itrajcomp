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

# gui.tcl
#    GUI for iTrajComp objects.


proc itrajcomp::NewPlot {self} {
  namespace eval [namespace current]::${self}:: {

    set rep_style_list [list Lines Bonds DynamicBonds HBonds Points VDW CPK Licorice Trace Tube Ribbons NewRibbons Cartoon NewCartoon MSMS Surf VolumeSlice Isosurface Dotted Solvent]
    set rep_color_list [list Name Type ResName ResType ResID Chain SegName Molecule Structure ColorID Beta Occupancy Mass Charge Pos User Index Backbone Throb Timestep Volume]
    set save_format_list [list tab matrix plotmtv plotmtv_binary postscript]

    variable title
    variable add_rep
    variable info_key1
    variable info_key2
    variable info_value
    variable info_sticky  0
    variable map_add 0
    variable map_del 0
    variable p
    variable plot
    variable r_thres_rel  0.5
    variable N_crit_rel   0.5
    variable grid 10
    variable clustering_graphics 0
    #variable rep_style1    NewRibbons
    variable rep_color1    Molecule
    variable rep_colorid1  0
    variable highlight    0.2
    variable save_format  tab
    #variable labstype
    #variable labsnum

    set p [toplevel ".${self}_plot"]

    wm protocol $p WM_DELETE_WINDOW "[namespace parent]::Destroy $self"

    set title "$self: $type"
    switch $type {
      contacts {
	set title "$title cutoff=$cutoff"
      }
      hbonds {
	set title "$title cutoff=$cutoff angle=$angle"
      }
      labels {
	set title "$title type=$labstype"
      }
    }
    wm title $p $title
    
    # Menu
    frame $p.menubar -relief raised -bd 2
    pack $p.menubar -padx 1 -fill x
    
    menubutton $p.menubar.file -text "File" -menu $p.menubar.file.menu -width 4 -underline 0
    menu $p.menubar.file.menu -tearoff no
    #$p.menubar.file.menu add command -label "Save" -command "" -underline 0
    $p.menubar.file.menu add cascade -label "Save As..." -menu $p.menubar.file.menu.saveas -underline 0
    menu $p.menubar.file.menu.saveas
    foreach as $save_format_list {
      $p.menubar.file.menu.saveas add command -label $as -command "[namespace parent]::SaveDataBrowse $self $as"
    }
    $p.menubar.file.menu add command -label "View" -command "[namespace parent]::ViewData $self" -underline 0
    $p.menubar.file.menu add command -label "Destroy" -command "[namespace parent]::Destroy $self" -underline 0
    pack $p.menubar.file -side left
    
    menubutton $p.menubar.analysis -text "Analysis" -menu $p.menubar.analysis.menu -width 5 -underline 0
    menu $p.menubar.analysis.menu -tearoff no
    $p.menubar.analysis.menu add command -label "Descriptive" -command "[namespace parent]::StatDescriptive $self" -underline 0
    pack $p.menubar.analysis -side left

    menubutton $p.menubar.help -text "Help" -menu $p.menubar.help.menu -width 4 -underline 0
    menu $p.menubar.help.menu -tearoff no
    $p.menubar.help.menu add command -label "Keybindings" -command "[namespace parent]::help_keys $self" -underline 0
    $p.menubar.help.menu add command -label "About" -command "[namespace parent]::help_about $p" -underline 0
    pack $p.menubar.help -side right

    # Title
    labelframe $p.title -relief ridge -bd 2 -text "Title"
    pack $p.title -side top -fill x -expand y

    entry $p.title.title -textvariable [namespace current]::title -relief flat
    pack $p.title.title -side left -fill x -expand y

    # Main area
    labelframe $p.u -relief ridge -bd 2 -text "Graph"
    frame $p.l
    pack $p.u -side top -expand yes -fill both -pady 10
    pack $p.l -side bottom -anchor w

    frame $p.u.l
    frame $p.u.r
    frame $p.l.l
    pack $p.u.l -side left -expand yes -fill both
    pack $p.u.r -side right -fill y
    pack $p.l.l -side top -expand yes -fill x
#    pack $p.l.r -side right

    # Graph
    frame $p.u.l.canvas -relief raised -bd 2
    pack $p.u.l.canvas -side top -anchor nw -expand yes -fill both

    set plot [canvas $p.u.l.canvas.c -height 400 -width 400 -scrollregion {0 0 2000 2000} -xscrollcommand "$p.u.l.canvas.xs set" -yscrollcommand "$p.u.l.canvas.ys set" -xscrollincrement 10 -yscrollincrement 10]
    scrollbar $p.u.l.canvas.xs -orient horizontal -command "$plot xview"
    scrollbar $p.u.l.canvas.ys -orient vertical   -command "$plot yview"

    pack $p.u.l.canvas.xs -side bottom -fill x
    pack $p.u.l.canvas.ys -side right -fill y
    pack $plot -side right -expand yes -fill both

    # Info
    frame $p.u.l.info
    pack $p.u.l.info -side top -anchor nw
    
    label $p.u.l.info.keys_label -text "Keys:"
    entry $p.u.l.info.keys_entry1 -width 8 -textvariable [namespace current]::info_key1
    entry $p.u.l.info.keys_entry2 -width 8 -textvariable [namespace current]::info_key2
    pack $p.u.l.info.keys_label $p.u.l.info.keys_entry1 $p.u.l.info.keys_entry2 -side left
    
    label $p.u.l.info.rmsd_label -text "Value:"
    entry $p.u.l.info.rmsd_entry -width 8 -textvariable [namespace current]::info_value
    pack $p.u.l.info.rmsd_label $p.u.l.info.rmsd_entry -side left

    checkbutton $p.u.l.info.sticky -text "Sticky" -variable [namespace current]::info_sticky
    pack $p.u.l.info.sticky -side left

    checkbutton $p.u.l.info.mapadd -text "Add" -variable [namespace current]::map_add -command "set [namespace current]::map_del 0"
    pack $p.u.l.info.mapadd -side left

    checkbutton $p.u.l.info.mapdel -text "Del" -variable [namespace current]::map_del -command "set [namespace current]::map_add 0"
    pack $p.u.l.info.mapdel -side left

#    label $p.u.l.info.high_label -text "Highlight:"
#    entry $p.u.l.info.high_entry -width 3 -textvariable [namespace current]::highlight
#    pack $p.u.l.info.high_label $p.u.l.info.high_entry -side left

    # Scale
    set sc_w    40.
    set sc_h   200.
    set off     10.
    set rg_n    50
    set rg_w    20.
    set rg_h    [expr ($sc_h-2*$off)/$rg_n]
    set lb_n    10
    set lb_h    [expr $sc_h/($lb_n+1)]
    
    set scale [canvas $p.u.r.s -height $sc_h -width $sc_w -relief ridge -bd 1]
    pack $scale -side top
    
    set y $off
    set val $min
    set reg [expr double($max-$min)/$rg_n]
    for {set i 0} {$i <= $rg_n} {incr i} {
      set color [[namespace parent]::ColorScale $max $min $val 1.0]
      $scale create rectangle 0 $y $rg_w [expr $y+$rg_h] -fill $color -outline $color -tag "rect$val"
      $scale bind "rect$val" <B2-ButtonRelease> "[namespace parent]::MapCluster2 $self $val -1 1"
      $scale bind "rect$val" <B3-ButtonRelease> "[namespace parent]::MapCluster2 $self $val 1 1"
      set val [expr $val+ $reg]
      set y [expr $y+$rg_h]
    }
    
    set y $off
    set val $min
    set reg [expr double($max-$min)/$lb_n]
    for {set i 0} {$i <= $lb_n} {incr i} {
      $scale create line 15 $y $rg_w $y
      $scale create text [expr $rg_w+1] $y -text [format $format_scale $val] -anchor w -font [list helvetica 7 normal] -tag "line$val"
      $scale bind "line$val" <B2-ButtonRelease> "[namespace parent]::MapCluster2 $self $val -1 1"
      $scale bind "line$val" <B3-ButtonRelease> "[namespace parent]::MapCluster2 $self $val 1 1"
      set val [expr $val+ $reg]
      set y [expr $y+$lb_h]
    }
    
    # Clear button
    button $p.u.r.clear -text "Clear" -command "[namespace parent]::MapClear $self"
    pack $p.u.r.clear -side bottom

    # Zoom
    labelframe $p.u.r.zoom  -relief ridge -bd 2 -text "Zoom"
    pack $p.u.r.zoom -side bottom
    button $p.u.r.zoom.incr -text "+" -command "[namespace parent]::Zoom $self 1"
    entry $p.u.r.zoom.val -width 2 -textvariable [namespace current]::grid
    button $p.u.r.zoom.decr -text "-" -command "[namespace parent]::Zoom $self -1"
    pack $p.u.r.zoom.incr $p.u.r.zoom.val $p.u.r.zoom.decr
    
    # Calculation info
    labelframe $p.l.l.info -relief ridge -bd 4 -text "$type selections"
    pack $p.l.l.info -side top -expand yes -fill x 

    frame $p.l.l.info.sel
    pack $p.l.l.info.sel -side left

    foreach x [list 1 2] {
      label $p.l.l.info.sel.e$x -text "[set sel$x]" -relief sunken -bd 1 -font [list Helvetica 8]
      pack $p.l.l.info.sel.e$x -side left -expand yes -fill x
    }
    
    switch $type {
      contacts {
	label $p.l.l.info.other -text "Cutoff: $cutoff" -font [list Helvetica 8]
	pack $p.l.l.info.other -side left
      }
      hbonds {
	label $p.l.l.info.other -text "Cutoff: $cutoff; Angle: $angle" -font [list Helvetica 8]
	pack $p.l.l.info.other -side left
      }
      labels {
	for {set i 0} {$i < [llength $labsnum]} {incr i} {
	  if {[lindex $labsnum $i] == 1} {lappend labs [lindex $labsnum $i]}
	}
	label $p.l.l.info.other -text "Type: $labstype; Labels: $labs" -font [list Helvetica 8]
	pack $p.l.l.info.other -side left
      }
    }
    
    # Display selection
    labelframe $p.l.l.rep -relief ridge -bd 4 -text "Representation"
    pack $p.l.l.rep -side top -expand yes -fill x 

    button $p.l.l.rep.but -text "Update" -font [list Helvetica 8] -command "[namespace parent]::UpdateSelection $self"
    pack $p.l.l.rep.but -side left

    foreach x [list 1] {
      frame $p.l.l.rep.disp$x
      pack $p.l.l.rep.disp$x -side left

      text $p.l.l.rep.disp$x.e -exportselection yes -height 2 -width 25 -wrap word -font [list Helvetica 8]
      $p.l.l.rep.disp$x.e insert end [set rep_sel$x]
      pack $p.l.l.rep.disp$x.e -side top -anchor w

      frame $p.l.l.rep.disp$x.style
      pack $p.l.l.rep.disp$x.style -side top

      menubutton $p.l.l.rep.disp$x.style.s -text "Style" -menu $p.l.l.rep.disp$x.style.s.list -textvariable [namespace current]::rep_style$x -relief raised -font [list Helvetica 8]
      menu $p.l.l.rep.disp$x.style.s.list
      foreach entry $rep_style_list {
 	$p.l.l.rep.disp$x.style.s.list add radiobutton -label $entry -variable [namespace current]::rep_style$x -value $entry -command "[namespace parent]::UpdateSelection $self" -font [list Helvetica 8]
      }

      menubutton $p.l.l.rep.disp$x.style.c -text "Color" -menu $p.l.l.rep.disp$x.style.c.list -textvariable [namespace current]::rep_color$x -relief raised -font [list Helvetica 8]
      menu $p.l.l.rep.disp$x.style.c.list
      foreach entry $rep_color_list {
 	if {$entry eq "ColorID"} {
 	  $p.l.l.rep.disp$x.style.c.list add radiobutton -label $entry -variable [namespace current]::rep_color$x -value $entry -command "$p.l.l.rep.disp$x.style.id config -state normal; [namespace parent]::UpdateSelection $self" -font [list Helvetica 8]
 	} else {
 	  $p.l.l.rep.disp$x.style.c.list add radiobutton -label $entry -variable [namespace current]::rep_color$x -value $entry -command "$p.l.l.rep.disp$x.style.id config -state disable; [namespace parent]::UpdateSelection $self" -font [list Helvetica 8]
 	}
      }

      menubutton $p.l.l.rep.disp$x.style.id -text "ColorID" -menu $p.l.l.rep.disp$x.style.id.list -textvariable [namespace current]::rep_colorid$x -relief raised -state disable -font [list Helvetica 8]
      menu $p.l.l.rep.disp$x.style.id.list
      for {set i 0} {$i <= 16} {incr i} {
  	$p.l.l.rep.disp$x.style.id.list add radiobutton -label $i -variable [namespace current]::rep_colorid$x -value $i -command "[namespace parent]::UpdateSelection $self" -font [list Helvetica 8]
      }
      
      pack $p.l.l.rep.disp$x.style.s $p.l.l.rep.disp$x.style.c $p.l.l.rep.disp$x.style.id -side left
    }


#     if {$type eq "rmsd"} {
#       # Clustering
#       frame $p.l.l.cluster -relief ridge -bd 2
#       pack $p.l.l.cluster -side top
      
#       label $p.l.l.cluster.rthres_label -text "r(thres,rel):"
#       entry $p.l.l.cluster.rthres -width 5 -textvariable [namespace current]::r_thres_rel
#       label $p.l.l.cluster.ncrit_label -text "N(crit,rel):"
#       entry $p.l.lb.cluster.ncrit -width 5 -textvariable [namespace current]::N_crit_rel
#       checkbutton $p.l.l.cluster.graphics -text "Graphics" -variable [namespace current]::clustering_graphics
#       button $p.l.l.cluster.bt -text "Cluster" -command "[namespace parent]::Cluster $self"
#       pack $p.l.l.cluster.rthres_label $p.l.l.cluster.rthres $p.l.l.cluster.ncrit_label $p.l.l.cluster.ncrit $p.l.l.cluster.graphics $p.l.l.cluster.bt -side left 
#     }
    
    switch $type {
      rmsd -
      contacts -
      hbonds -
      labels {
	[namespace parent]::Graph $self
      }
      dist -
      covar {
	[namespace parent]::Graph2 $self
      }
    }
    [namespace parent]::Zoom $self -5
    
  }
}


proc itrajcomp::Graph {self} {
  namespace eval [namespace current]::${self}:: {
    variable add_rep
    variable rep_list
    variable rep_num
    variable colors

    set maxkeys [llength $keys]
    set count 0
    
    set offx 0
    set offy 0
    set width 3
    for {set i 0} {$i < [llength $mol1]} {incr i} {
      set f1 [lindex $frame1 $i]
      for {set j 0} { $j < [llength $f1]} {incr j} {
	set key1 "[lindex $mol1 $i]:[lindex $f1 $j]"
	set rep_list($key1) {}
	set rep_num($key1) 0
	set offy 0
	for {set k 0} {$k < [llength $mol2]} {incr k} {
	  set f2 [lindex $frame2 $k]
	  for {set l 0} { $l < [llength $f2]} {incr l} {
	    set key2 "[lindex $mol2 $k]:[lindex $f2 $l]"
	    set rep_list($key2) {}
	    set rep_num($key2) 0
	    set key "$key1,$key2"
	    if {![info exists data($key)]} continue
	    set x [expr ($j+$offx)*($grid+$width)]
	    set y [expr ($l+$offy)*($grid+$width)]
	    set add_rep($key) 0
	    set colors($key) [[namespace parent]::ColorScale $max $min $data($key) 1.0]
	    #puts "$i $j -> $x $offx           $k $l - > $y $offy     = $data($key)    $color"
	    $plot create rectangle $x $y [expr $x+$grid] [expr $y+$grid] -fill $colors($key) -outline $colors($key) -tag $key -width $width
	    
	    $plot bind $key <Enter>            "[namespace parent]::ShowPoint $self $key $data($key) 1"
	    $plot bind $key <B1-ButtonRelease>  "[namespace parent]::MapPoint $self $key $data($key)" 
	    $plot bind $key <Shift-B1-ButtonRelease>   "[namespace parent]::MapCluster3 $self $key  0  0"
	    $plot bind $key <Shift-B2-ButtonRelease>   "[namespace parent]::MapCluster3 $self $key  0 -1"
	    $plot bind $key <Shift-B3-ButtonRelease>   "[namespace parent]::MapCluster3 $self $key  0  1"
	    $plot bind $key <Control-B1-ButtonRelease> "[namespace parent]::MapCluster2 $self $key  0  0"
	    $plot bind $key <Control-B2-ButtonRelease> "[namespace parent]::MapCluster2 $self $key -1  0"
	    $plot bind $key <Control-B3-ButtonRelease> "[namespace parent]::MapCluster2 $self $key  1  0"

	    incr count
	    [namespace parent]::ProgressBar $count $maxkeys
	  }
	  set offy [expr $offy+[llength $f2]]
	}
      }
      set offx [expr $offx+[llength $f1]]
    }
  }
}


proc itrajcomp::ViewData {self} {
  set r [toplevel ".${self}_raw"]
  wm title $r "View $self"
  
  text $r.data -exportselection yes -width 80 -xscrollcommand "$r.xs set" -yscrollcommand "$r.ys set" -font [list fixed]
  scrollbar $r.xs -orient horizontal -command "$r.data xview"
  scrollbar $r.ys -orient vertical   -command "$r.data yview"
  
  pack $r.xs -side bottom -fill x
  pack $r.ys -side right -fill y
  pack $r.data -side right -expand yes -fill both
  
  $r.data insert end [[namespace current]::saveData $self "" "tab"]
}


proc itrajcomp::StatDescriptive {self} {
  
  array set data [array get ${self}::data]
  set format_data [set ${self}::format_data]

  # Mean
  set mean 0.0
  foreach mykey [array names data] {
    #puts "$mykey $data($mykey)"
    set mean [expr $mean + $data($mykey)]
  }
  set mean [expr $mean / double([array size data] - 1)]

  # Std
  set sd 0.0
  foreach mykey [array names data] {
    #puts "$mykey $data($mykey)"
    set temp [expr $data($mykey) - $mean]
    set sd [expr $sd + $temp*$temp]
  }
  set sd [expr sqrt($sd / double([array size data] - 1))]

  set mean [format "$format_data" $mean]
  set sd [format "$format_data" $sd]

  tk_messageBox -title "$self Stats"  -parent [set ${self}::p] -message \
    "Descriptive statistics
----------------------
Mean: $mean
 Std: $sd

"

}


proc itrajcomp::Zoom {self zoom} {
  set grid [set ${self}::grid]
  set plot [set ${self}::plot]

  if {$zoom < 0} {
    if {$grid <= 1} return
  } elseif {$zoom > 0} {
    if {$grid >= 20} return
  } else {
    return
  }

  set old [expr 1.0*$grid]
  set grid [expr $grid + $zoom]
  set ${self}::grid $grid

  set factor [expr $grid/$old]
  $plot scale all 0 0 $factor $factor
}


proc itrajcomp::AddRep {self key} {
  set p [set ${self}::p]
  set rep_style1 [set ${self}::rep_style1]
  set rep_color1 [set ${self}::rep_color1]
  set rep_colorid1 [set ${self}::rep_colorid1]

  set rep_list [set ${self}::rep_list($key)]
  set rep_num [set ${self}::rep_num($key)]
  
  set rep_sel1 [[namespace current]::ParseSel [$p.l.l.rep.disp1.e get 1.0 end] ""]

  incr rep_num
  
  #puts "add $key = $rep_num"
  if {$rep_num <= 1} {
    if {$rep_color1 eq "ColorID"} {
      set color [list $rep_color1 $rep_colorid1]
    } else {
      set color $rep_color1
    }
    lassign [[namespace current]::ParseKey $self $key] m f s
    set rep_list [[namespace current]::AddRep1 $m $f $s $rep_style1 $color]
    
  }
  set ${self}::rep_list($key) $rep_list
  set ${self}::rep_num($key) $rep_num
}


proc itrajcomp::DelRep {self key} {
  set rep_num [set ${self}::rep_num($key)]

  incr rep_num -1
  #puts "del $key = $rep_num"
  if {$rep_num == 0} {
    lassign [[namespace current]::ParseKey $self $key] m f s
    [namespace current]::DelRep1 [set ${self}::rep_list($key)] $m
  }
  set ${self}::rep_num($key) $rep_num
}


proc itrajcomp::ShowPoint {self key val stick} {
  if {[set ${self}::info_sticky] && $stick} return
  
  set indices [split $key ,:]
  lassign $indices i j k l
  set ${self}::info_key1 [format "[set ${self}::format_key]" $i $j]
  set ${self}::info_key2 [format "[set ${self}::format_key]" $k $l]
  set ${self}::info_value [format "[set ${self}::format_data]" $val]
}


proc itrajcomp::MapAdd {self key {check 0}} {
  set indices [split $key ,]
  lassign $indices key1 key2
  
  set add_rep [set ${self}::add_rep($key)]
  if {$add_rep == 1} {
    return
  }

  if {$check && $key1 == $key2} {
    return
  }
  
  set plot [set ${self}::plot]
  $plot itemconfigure $key -outline black
  set ${self}::add_rep($key) 1
  [namespace current]::AddRep $self $key1
  [namespace current]::AddRep $self $key2
}

proc itrajcomp::MapDel {self key {check 0}} {
  set indices [split $key ,]
  lassign $indices key1 key2

  set add_rep [set ${self}::add_rep($key)]
  if {$add_rep == 0} {
    return
  }
  if {$check && $key1 == $key2} {
    return
  }
  
  set plot [set ${self}::plot]
  set color [set ${self}::colors($key)]
  $plot itemconfigure $key -outline $color
  set ${self}::add_rep($key) 0
  [namespace current]::DelRep $self $key1
  [namespace current]::DelRep $self $key2

}

proc itrajcomp::MapPoint {self key data {mod 0}} {
  set add_rep [set ${self}::add_rep($key)]
  
  if {$add_rep == 0 || $mod} {
    [namespace current]::MapAdd $self $key
    set mod 1
  }
  if {$add_rep == 1 && !$mod} {
    [namespace current]::MapDel $self $key
  }

  [namespace current]::ShowPoint $self $key $data 0
  #[namespace current]::RepList $self
}


proc itrajcomp::MapCluster3 {self key {mod1 0} {mod2 0}} {
  variable add_rep

  set keys [set ${self}::keys]
  set plot [set ${self}::plot]
  set map_add [set ${self}::map_add]
  set map_del [set ${self}::map_del]
  array set data [array get ${self}::data]

  set indices [split $key ,]
  
  if {!$map_add && !$map_del} {
    [namespace current]::MapClear $self
    set map_add 1
  }

  # Column
  if {!$mod1 || $mod1 == 1} {
    set ref [lindex $indices 0]
    foreach mykey [array names data $ref,*] {
      if {$mod2 == 0} {
	if {$map_add} {
	  [namespace current]::MapAdd $self $mykey
	} else {
	  [namespace current]::MapDel $self $mykey
	}
      } elseif {$mod2 == 1} {
	if {$data($mykey) <= $data($key)} {
	  if {$map_add} {
	    [namespace current]::MapAdd $self $mykey
	  } else {
	    [namespace current]::MapDel $self $mykey
	  }
	}
      } elseif {$mod2 == -1} {
	if {$data($mykey) >= $data($key)} {
	  if {$map_add} {
	    [namespace current]::MapAdd $self $mykey
	  } else {
	    [namespace current]::MapDel $self $mykey
	  }
	}
      }
    }
  }

  # Row
  if {!$mod1 || $mod1 == 2} {
    if {$mod1 == 2} {
      set ref [lindex $indices 1]
    } else {
      set ref [lindex $indices 0]
    }
    foreach mykey [array names data *,$ref] {
      if {$mod2 == 0} {
	if {$map_add} {
	  if {!$mod1} {
	    [namespace current]::MapAdd $self $mykey 1
	  }
	} else {
	  if {!$mod1} {
	    [namespace current]::MapDel $self $mykey 1
	  }
	}
      } elseif {$mod2 == 1} {
	if {$data($mykey) <= $data($key)} {
	  if {$map_add} {
	    if {!$mod1} {
	      [namespace current]::MapAdd $self $mykey 1
	    }
	  } else {
	    if {!$mod1} {
	      [namespace current]::MapDel $self $mykey 1
	    }
	  }
	}
      } elseif {$mod2 == -1} {
	if {$data($mykey) >= $data($key)} {
	  if {$map_add} {
	    if {!$mod1} {
	      [namespace current]::MapAdd $self $mykey 1
	    }
	  } else {
	    if {!$mod1} {
	      [namespace current]::MapDel $self $mykey 1
	    }
	  }
	}
      }
    }
  }

  [namespace current]::ShowPoint $self $key $data($key) 0
  #[namespace current]::RepList $self
}


proc itrajcomp::MapCluster1 {self key {mod 0}} {
  variable add_rep

  set keys [set ${self}::keys]
  set type [set ${self}::type]
  set plot [set ${self}::plot]
  array set data [array get ${self}::data]

  set indices [split $key ,:]
  set val $data($key)
  [namespace current]::MapClear $self

  if {!$mod || $mod == 1} {
    set ref "[lindex $indices 0]:[lindex $indices 1]"
    [namespace current]::AddRep $self $ref
    foreach mykey [array names data $ref,*] {
      set indices [split $mykey ,:]
      set k [lindex $indices 2]
      set l [lindex $indices 3]
      if {$type eq "rmsd"} {
	if {$data($mykey) <= $val} {
	  set color black
	  $plot itemconfigure $mykey -outline $color
	  set ${self}::add_rep($mykey) 1
	  [namespace current]::AddRep $self $k:$l
	}
      } else {
	if {$data($mykey) >= $val} {
	  set color black
	  $plot itemconfigure $mykey -outline $color
	  set ${self}::add_rep($mykey) 1
	  [namespace current]::AddRep $self $k:$l
	}
      }
    }
  }
  if {!$mod || $mod == 2} {
    if {$mod} {
      set ref "[lindex $indices 2]:[lindex $indices 3]"
    } else {
      set ref "[lindex $indices 0]:[lindex $indices 1]"
    }
    [namespace current]::AddRep $self $ref
    foreach mykey [array names data *,$ref] {
      set indices [split $mykey ,:]
      set k [lindex $indices 0]
      set l [lindex $indices 1]
      if {$type eq "rmsd"} {
	if {$data($mykey) <= $val} {
	  set color black
	  $plot itemconfigure $mykey -outline $color
	  set ${self}::add_rep($mykey) 1
	  [namespace current]::AddRep $self $k:$l
	}
      } else {
	if {$data($mykey) >= $val} {
	  set color black
	  $plot itemconfigure $mykey -outline $color
	  set ${self}::add_rep($mykey) 1
	  [namespace current]::AddRep $self $k:$l
	}
      }
    }
  }

  [namespace current]::ShowPoint $self $key $data($key) 0
}


proc itrajcomp::MapCluster2 {self key {mod1 0} {mod2 0} } {
  set plot [set ${self}::plot]
  array set data [array get ${self}::data]

  if {$mod2} {
    set val $key
  } else {
    set val $data($key)
  }

  [namespace current]::MapClear $self
  foreach mykey [set ${self}::keys] {
    set indices [split $mykey ,]
    lassign $indices key1 key2
    if {!$mod1 || $mod1 == 1} {
      if {$data($mykey) >= $val} {
	set color black
	$plot itemconfigure $mykey -outline $color
	[namespace current]::AddRep $self $key1
	[namespace current]::AddRep $self $key2
	set ${self}::add_rep($mykey) 1
      }
    }
    if {!$mod1 || $mod1 == -1} {
      if {$data($mykey) <= $val} {
	set color black
	$plot itemconfigure $mykey -outline $color
	[namespace current]::AddRep $self $key1
	[namespace current]::AddRep $self $key2
	set ${self}::add_rep($mykey) 1
      }
    }
  }
}


proc itrajcomp::MapClear {self} {
  set plot [set ${self}::plot]
  
  foreach key [set ${self}::keys] {
    if {[set ${self}::add_rep($key)] == 1 } {
      $plot itemconfigure $key -outline [set ${self}::colors($key)]
      set ${self}::add_rep($key) 0
    }
  }

  foreach key [array names ${self}::rep_list] {
    if {[set ${self}::rep_num($key)] > 0} {
      lassign [[namespace current]::ParseKey $self $key] m f s
      [namespace current]::DelRep1 [set ${self}::rep_list($key)] $m
      set ${self}::rep_num($key) 0
    }
  }
  #[namespace current]::RepList $self
  
}


proc itrajcomp::UpdateSelection {self} {
  set p [set ${self}::p]
  set rep_style1 [set ${self}::rep_style1]
  set rep_color1 [set ${self}::rep_color1]
  set rep_colorid1 [set ${self}::rep_colorid1]
  
  array set rep_list [array get ${self}::rep_list]
 
  foreach key [array names rep_list] {
    if {[set ${self}::rep_num($key)] > 0} {
      lassign [[namespace current]::ParseKey $self $key] m f s
      set repname [mol repindex $m $rep_list($key)]
      mol modselect $repname $m $s
      switch $rep_style1 {
	HBonds {
	  mol modstyle  $repname $m $rep_style1 [set ${self}::cutoff] [set ${self}::angle]
	}
	default {
	  mol modstyle  $repname $m $rep_style1
	}
      }
      switch $rep_color1 {
	ColorID {
	  mol modcolor  $repname $m $rep_color1 $rep_colorid1
	}
	default {
	  mol modcolor  $repname $m $rep_color1
	}
      }
    }
  }
}


proc itrajcomp::Destroy {self} {
  [namespace current]::MapClear $self
  catch {destroy [set ${self}::p]}
  [namespace current]::Objdelete $self
}


proc itrajcomp::help_keys { self } {
  set vn [package present itrajcomp]

  set r [toplevel ".${self}_keybindings"]
  wm title $r "iTrajComp - Keybindings $vn"
  text $r.data -exportselection yes -width 80 -font [list helvetica 10]
  pack $r.data -side right -expand yes -fill both
  $r.data insert end "iTrajComp v$vn Keybindings\n\n" title
  $r.data insert end "B1\t" button
  $r.data insert end "Select/Deselect one point.\n"
  $r.data insert end "Shift-B1\t" button
  $r.data insert end "Selects all points in column/row of data.\n"
  $r.data insert end "Shift-B2\t" button
  $r.data insert end "Selects all points in column/row with values <= than data clicked.\n"
  $r.data insert end "Shift-B3\t" button
  $r.data insert end "Selects all points in column/row with values => than data clicked.\n"
  $r.data insert end "Ctrl-B1\t" button
  $r.data insert end "Selects all points.\n"
  $r.data insert end "Ctrl-B2\t" button
  $r.data insert end "Selects all points with values <= than data clicked.\n"
  $r.data insert end "Ctrl-B3\t" button
  $r.data insert end "Selects all points with values => than data clicked.\n\n\n"
  $r.data insert end "Copyright (C) Luis Gracia <lug2002@med.cornell.edu>\n"

  $r.data tag configure title -font [list helvetica 12 bold]
  $r.data tag configure button -font [list helvetica 10 bold]

}




proc itrajcomp::Graph2 {self} {
  namespace eval [namespace current]::${self}:: {
    variable add_rep
    variable rep_list
    variable rep_num
    variable colors
    variable regions

    set nregions [llength $regions]
    #puts "$nregions -> $regions"

    foreach key $keys {
      lassign [split $key ,:] i j k l
      set part2($i) $j
      set part2($k) $l
    }

    set maxkeys [llength $keys]
    set count 0
    
    set offx 0
    set offy 0
    set width 3
    for {set i 0} {$i < $nregions} {incr i} {
      set key1 "[lindex $regions $i]:$part2([lindex $regions $i])"
      set rep_list($key1) {}
      set rep_num($key1) 0
      set offy 0
      for {set k 0} {$k < $nregions} {incr k} {
	set key2 "[lindex $regions $k]:$part2([lindex $regions $k])"
	set rep_list($key2) {}
	set rep_num($key2) 0
	set key "$key1,$key2"
	#puts -nonewline "$key "
	if {![info exists data($key)]} {
	  #puts ""
	  continue
	}
	set x [expr ($i+$offx)*($grid+$width)]
	set y [expr ($k+$offy)*($grid+$width)]
	set add_rep($key) 0
	set colors($key) [[namespace parent]::ColorScale $max $min $data($key) 1.0]
	#puts "-> $x $offx           $k $l - > $y $offy     = $data($key)    $color"
	$plot create rectangle $x $y [expr $x+$grid] [expr $y+$grid] -fill $colors($key) -outline $colors($key) -tag $key -width $width
	
	$plot bind $key <Enter>            "[namespace parent]::ShowPoint $self $key $data($key) 1"
	$plot bind $key <B1-ButtonRelease>  "[namespace parent]::MapPoint $self $key $data($key)" 
	$plot bind $key <Shift-B1-ButtonRelease>   "[namespace parent]::MapCluster3 $self $key  0  0"
	$plot bind $key <Shift-B2-ButtonRelease>   "[namespace parent]::MapCluster3 $self $key  0 -1"
	$plot bind $key <Shift-B3-ButtonRelease>   "[namespace parent]::MapCluster3 $self $key  0  1"
	$plot bind $key <Control-B1-ButtonRelease> "[namespace parent]::MapCluster2 $self $key  0  0"
	$plot bind $key <Control-B2-ButtonRelease> "[namespace parent]::MapCluster2 $self $key -1  0"
	$plot bind $key <Control-B3-ButtonRelease> "[namespace parent]::MapCluster2 $self $key  1  0"

	incr count
	[namespace parent]::ProgressBar $count $maxkeys
      }
      set offy [expr $offy+$k]
      
    }
    set offx [expr $offx+$i]
    
  }
}


proc itrajcomp::RepList {self} {
  array set rep_list [array get ${self}::rep_list]
  array set add_rep [array get ${self}::add_rep]
  array set rep_num [array get ${self}::rep_num]

  foreach key [lsort [array names rep_list]] {
    puts "rep_list: $key $rep_list($key)"
  }
  foreach key [lsort [array names rep_num]] {
    puts "rep_num: $key $rep_num($key)"
  }
  foreach key [lsort [array names add_rep]] {
    puts "add_rep: $key $add_rep($key)"
  }
  puts "-----"
}
