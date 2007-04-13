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


proc itrajcomp::itcObjGui {self} {
  # Initialize window for this object

  namespace eval [namespace current]::${self}:: {

    set rep_style_list [list Lines Bonds DynamicBonds HBonds Points VDW CPK Licorice Tube Trace Ribbons NewRibbons Cartoon NewCartoon MSMS Surf VolumeSlice Isosurface Beads Dotted Solvent]
    set rep_color_list [list Name Type Element ResName ResType ResID Chain SegName Conformation Molecule Structure ColorID Beta Occupancy Mass Charge Pos User Index Backbone Throb Timestep Volume]

    variable title
    variable r_thres_rel  0.5
    variable N_crit_rel   0.5
    variable clustering_graphics 0
    variable save_format  tab
    variable win_obj

    set win_obj [toplevel ".${self}_plot"]

    wm protocol $win_obj WM_DELETE_WINDOW "[namespace parent]::Destroy $self"

    # TODO: update title window when the entry $win_obj.title.title changes
    set title "$self: $type"
    foreach var $vars {
      append title " $var=[set $var]"
    }
    wm title $win_obj $title
    
    # Menu
    #-----
    set menubar [frame $win_obj.menubar -relief raised -bd 2]
    pack $win_obj.menubar -padx 1 -fill x
    [namespace parent]::itcObjMenubar $self $menubar
    
    # Tabs
    #-----
    frame $win_obj.tabc
    pack $win_obj.tabc -side bottom -padx 1 -expand yes -fill both
    pack [buttonbar::create $win_obj.tabs $win_obj.tabc] -side top -fill x

    # Info
    variable tab_info [buttonbar::add $win_obj.tabs info]
    buttonbar::name $win_obj.tabs info "Info"
    [namespace parent]::itcObjInfo $self

    # Graph
    variable tab_graph [buttonbar::add $win_obj.tabs graph]
    buttonbar::name $win_obj.tabs graph "Graph"
    [namespace parent]::itcObjGraph $self

    # Representation
    variable tab_rep [buttonbar::add $win_obj.tabs rep]
    buttonbar::name $win_obj.tabs rep "Representations"
    [namespace parent]::itcObjRep $self

    buttonbar::showframe $win_obj.tabs info
    update idletasks
  }
}


proc itrajcomp::itcObjMenubar {self w} {
  # Menu for an itcObj
    
  menubutton $w.file -text "File" -menu $w.file.menu -width 4 -underline 0
  menu $w.file.menu -tearoff no
  #$w.file.menu add command -label "Save" -command "" -underline 0
  $w.file.menu add cascade -label "Save As..." -menu $w.file.menu.saveas -underline 0
  menu $w.file.menu.saveas
  foreach as [set [namespace current]::save_format_list] {
    $w.file.menu.saveas add command -label $as -command "[namespace current]::SaveDataBrowse $self $as"
  }
  $w.file.menu add command -label "View" -command "[namespace current]::ViewData $self" -underline 0
  $w.file.menu add command -label "Destroy" -command "[namespace current]::Destroy $self" -underline 0
  pack $w.file -side left
  
  menubutton $w.analysis -text "Analysis" -menu $w.analysis.menu -width 5 -underline 0
  menu $w.analysis.menu -tearoff no
  $w.analysis.menu add command -label "Descriptive" -command "[namespace current]::StatDescriptive $self" -underline 0
  pack $w.analysis -side left
  
  menubutton $w.help -text "Help" -menu $w.help.menu -width 4 -underline 0
  menu $w.help.menu -tearoff no
  $w.help.menu add command -label "Keybindings" -command "[namespace current]::help_keys $self" -underline 0
  $w.help.menu add command -label "About" -command "[namespace current]::help_about [winfo parent $w]" -underline 0
  pack $w.help -side right
  
}


proc itrajcomp::itcObjInfo {self} {
  # construct info gui
  namespace eval [namespace current]::${self}:: {

    # Calculation type
    labelframe $tab_info.calc -text "Calculation Type"
    pack $tab_info.calc -side top -anchor nw -expand yes -fill x

    label $tab_info.calc.type -text $type
    pack $tab_info.calc.type -side top -anchor nw
    
    # Calculation options
    labelframe $tab_info.opt -text "Calculation Options"
    pack $tab_info.opt -side top -anchor nw -expand yes -fill x
    
    set row 1
    grid columnconfigure $tab_info.opt 2 -weight 1
    foreach var [concat diagonal $vars] {
      incr row
      label $tab_info.opt.${var}_l -text "$var:"
      label $tab_info.opt.${var}_v -text "[set $var]"
      grid $tab_info.opt.${var}_l -row $row -column 1 -sticky nw
      grid $tab_info.opt.${var}_v -row $row -column 2 -sticky nw
    }

    # Selection set 1
    labelframe $tab_info.sel1 -text "Selection 1"
    pack $tab_info.sel1 -side top -anchor nw -expand yes -fill x

    set row 1
    grid columnconfigure $tab_info.sel1 2 -weight 1
    
    label $tab_info.sel1.mol_l -text "Molecule(s):"
    label $tab_info.sel1.mol_v -text "$mol1_def ($mol1)"
    grid $tab_info.sel1.mol_l -row $row -column 1 -sticky nw
    grid $tab_info.sel1.mol_v -row $row -column 2 -sticky nw

    # TODO: put frames for each mol in a different row
    incr row
    label $tab_info.sel1.frame_l -text "Frame(s):"
    label $tab_info.sel1.frame_v -text "$frame1_def ([[namespace parent]::SplitFrames $frame1])"
    grid $tab_info.sel1.frame_l -row $row -column 1 -sticky nw
    grid $tab_info.sel1.frame_v -row $row -column 2 -sticky nw

    incr row
    label $tab_info.sel1.atom_l -text "Atom Sel:"
    label $tab_info.sel1.atom_v -text "$sel1"
    grid $tab_info.sel1.atom_l -row $row -column 1 -sticky nw
    grid $tab_info.sel1.atom_v -row $row -column 2 -sticky nw

    # Selection set 2
    labelframe $tab_info.sel2 -text "Selection 2"
    pack $tab_info.sel2 -side top -anchor nw -expand yes -fill x

    set row 1
    grid columnconfigure $tab_info.sel2 2 -weight 1
    
    label $tab_info.sel2.mol_l -text "Molecule(s):"
    label $tab_info.sel2.mol_v -text "$mol2_def ($mol2)"
    grid $tab_info.sel2.mol_l -row $row -column 1 -sticky nw
    grid $tab_info.sel2.mol_v -row $row -column 2 -sticky nw

    incr row
    label $tab_info.sel2.frame_l -text "Frame(s):"
    label $tab_info.sel2.frame_v -text "$frame2_def ([[namespace parent]::SplitFrames $frame2])"
    grid $tab_info.sel2.frame_l -row $row -column 1 -sticky nw
    grid $tab_info.sel2.frame_v -row $row -column 2 -sticky nw

    incr row
    label $tab_info.sel2.atom_l -text "Atom Sel:"
    label $tab_info.sel2.atom_v -text "$sel2"
    grid $tab_info.sel2.atom_l -row $row -column 1 -sticky nw
    grid $tab_info.sel2.atom_v -row $row -column 2 -sticky nw

    # Molecules list
    labelframe $tab_info.mols -text "Molecules list"
    pack $tab_info.mols -side top -anchor nw -expand yes -fill x

    set row 1
    grid columnconfigure $tab_info.mols 3 -weight 1
    
    label $tab_info.mols.header_n -text "Name"
    grid $tab_info.mols.header_n -row $row -column 2 -sticky nw
    label $tab_info.mols.header_f -text "Files"
    grid $tab_info.mols.header_f -row $row -column 3 -sticky nw

    foreach m $mol1 {
      incr row
      label $tab_info.mols.l$m -text "$m:"
      grid $tab_info.mols.l$m -row $row -column 1 -sticky nw

      label $tab_info.mols.n$m -text "[molinfo $m get name]"
      grid $tab_info.mols.n$m -row $row -column 2 -sticky nw

      foreach file [eval concat [molinfo $m get filename]] {
	label $tab_info.mols.f$m$row -text "$file"
	grid $tab_info.mols.f$m$row -row $row -column 3 -sticky nw
	incr row
      }
    }

  }
}


proc itrajcomp::itcObjGraph {self} {
  # construct graph gui
  namespace eval [namespace current]::${self}:: {
    variable add_rep
    variable info_key1
    variable info_key2
    variable info_value
    variable info_sticky 0
    variable map_add 0
    variable map_del 0
    variable highlight 0.2
    variable grid 10

    frame $tab_graph.l
    frame $tab_graph.r
    pack $tab_graph.l -side left -expand yes -fill both
    pack $tab_graph.r -side right -fill y

    # Graph
    frame $tab_graph.l.graph -relief raised -bd 2
    pack $tab_graph.l.graph -side top -anchor nw -expand yes -fill both

    variable plot [canvas $tab_graph.l.graph.c -height 400 -width 400 -scrollregion {0 0 2000 2000} -xscrollcommand "$tab_graph.l.graph.xs set" -yscrollcommand "$tab_graph.l.graph.ys set" -xscrollincrement 10 -yscrollincrement 10 -bg white]
    scrollbar $tab_graph.l.graph.xs -orient horizontal -command "$plot xview"
    scrollbar $tab_graph.l.graph.ys -orient vertical   -command "$plot yview"

    pack $tab_graph.l.graph.xs -side bottom -fill x
    pack $tab_graph.l.graph.ys -side right -fill y
    pack $plot -side right -expand yes -fill both

    # Info
    set info_frame [frame $tab_graph.l.info]
    pack $info_frame -side top -anchor nw

    label $info_frame.keys_label -text "Keys:"
    entry $info_frame.keys_entry1 -width 8 -textvariable [namespace current]::info_key1 -state readonly
    entry $info_frame.keys_entry2 -width 8 -textvariable [namespace current]::info_key2 -state readonly
    pack $info_frame.keys_label $info_frame.keys_entry1 $info_frame.keys_entry2 -side left
    
    label $info_frame.value_label -text "Value:"
    entry $info_frame.value_entry -width 8 -textvariable [namespace current]::info_value -state readonly
    pack $info_frame.value_label $info_frame.value_entry -side left

    checkbutton $info_frame.sticky -text "Sticky" -variable [namespace current]::info_sticky
    pack $info_frame.sticky -side left

    checkbutton $info_frame.mapadd -text "Add" -variable [namespace current]::map_add -command "set [namespace current]::map_del 0"
    pack $info_frame.mapadd -side left

    checkbutton $info_frame.mapdel -text "Del" -variable [namespace current]::map_del -command "set [namespace current]::map_add 0"
    pack $info_frame.mapdel -side left
    
#    label $info_frame.high_label -text "Highlight:"
#    entry $info_frame.high_entry -width 3 -textvariable [namespace current]::highlight
#    pack $info_frame.high_label $info_frame.high_entry -side left

    # Scale
    labelframe $tab_graph.r.scale -text "Scale"
    pack $tab_graph.r.scale -side top -expand yes -fill y

    set sc_w 40.
    #set scale [canvas $tab_graph.r.scale.c -height $sc_h -width $sc_w]
    set scale [canvas $tab_graph.r.scale.c -width $sc_w]
    pack $scale -side top -expand yes -fill y
    bind $scale <Configure> "[namespace parent]::UpdateScale $self"

    # Clear button
    button $tab_graph.r.clear -text "Clear" -command "[namespace parent]::MapClear $self"
    pack $tab_graph.r.clear -side bottom

    # Zoom
    labelframe $tab_graph.r.zoom  -relief ridge -bd 2 -text "Zoom"
    pack $tab_graph.r.zoom -side bottom
    button $tab_graph.r.zoom.incr -text "+" -command "[namespace parent]::Zoom $self 1"
    entry $tab_graph.r.zoom.val -width 2 -textvariable [namespace current]::grid
    button $tab_graph.r.zoom.decr -text "-" -command "[namespace parent]::Zoom $self -1"
    pack $tab_graph.r.zoom.incr $tab_graph.r.zoom.val $tab_graph.r.zoom.decr

    switch $graphtype {
      frame {
	[namespace parent]::Graph $self
      }
      atom -
      residue {
	[namespace parent]::Graph2 $self
      }
    }
    # TODO: zoom to a better level depending on the size of the matrix and the space available
    [namespace parent]::Zoom $self -5
  }
}


proc itrajcomp::itcObjRep {self} {
  # construct representations gui
  namespace eval [namespace current]::${self}:: {
    #variable rep_style1    NewRibbons
    variable rep_color1    Molecule
    variable rep_colorid1  0

    foreach x [list 1] {
      frame $tab_rep.disp$x
      pack $tab_rep.disp$x -side left -expand yes -fill x

      # Selection
      #----------
      labelframe $tab_rep.disp$x.sel -text "Selection"
      pack $tab_rep.disp$x.sel -side left -anchor nw -expand yes -fill both
      
      text $tab_rep.disp$x.sel.e -exportselection yes -height 2 -width 25 -wrap word
      $tab_rep.disp$x.sel.e insert end [set rep_sel$x]
      pack $tab_rep.disp$x.sel.e -side top -anchor w -expand yes -fill both
    
      # Style
      #------
      set style [labelframe $tab_rep.disp$x.style -text "Style"]
      pack $style -side left

      # Draw
      frame $style.draw
      pack $style.draw -side top -anchor nw

      label $style.draw.l -text "Drawing:"
      pack $style.draw.l -side left

      menubutton $style.draw.m -text "Drawing" -menu $style.draw.m.list -textvariable [namespace current]::rep_style$x -relief raised
      menu $style.draw.m.list
      foreach entry $rep_style_list {
 	$style.draw.m.list add radiobutton -label $entry -variable [namespace current]::rep_style$x -value $entry -command "[namespace parent]::UpdateSelection $self"
      }
      pack $style.draw.m

      # Color
      frame $style.color
      pack $style.color -side top -anchor nw

      label $style.color.l -text "Color:"
      pack $style.color.l -side left

      menubutton $style.color.m -text "Color" -menu $style.color.m.list -textvariable [namespace current]::rep_color$x -relief raised
      menu $style.color.m.list
      foreach entry $rep_color_list {
 	if {$entry eq "ColorID"} {
 	  $style.color.m.list add radiobutton -label $entry -variable [namespace current]::rep_color$x -value $entry -command "$style.color.id config -state normal; [namespace parent]::UpdateSelection $self"
 	} else {
 	  $style.color.m.list add radiobutton -label $entry -variable [namespace current]::rep_color$x -value $entry -command "$style.color.id config -state disable; [namespace parent]::UpdateSelection $self"
 	}
      }

      menubutton $style.color.id -text "ColorID" -menu $style.color.id.list -textvariable [namespace current]::rep_colorid$x -relief raised -state disable
      menu $style.color.id.list
      set a [colorinfo colors]
      for {set i 0} {$i < [llength $a]} {incr i} {
  	$style.color.id.list add radiobutton -label "$i [lindex $a $i]" -variable [namespace current]::rep_colorid$x -value $i -command "[namespace parent]::UpdateSelection $self"
      }
      pack $style.color.m $style.color.id -side left
    }

    # Update button
    #--------------
    button $tab_rep.but -text "Update"  -command "[namespace parent]::UpdateSelection $self"
    pack $tab_rep.but -side left


  }
}


proc itrajcomp::Graph {self} {
  # Create matrix graph for objects
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


proc itrajcomp::Graph2 {self} {
  # Create graph for object with region information (atoms, residue,...)
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


proc itrajcomp::ViewData {self} {
  # Create window to view data in tabular format
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
  # Create window to view statistics
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

  tk_messageBox -title "$self Stats"  -parent [set ${self}::win_obj] -message \
    "Descriptive statistics
----------------------
Mean: $mean
 Std: $sd

"

}


proc itrajcomp::Zoom {self zoom} {
  # Zoom in and out in the matrix plot
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
  # Add graphic representation
  set tab_rep [set ${self}::tab_rep]
  set rep_style1 [set ${self}::rep_style1]
  set rep_color1 [set ${self}::rep_color1]
  set rep_colorid1 [set ${self}::rep_colorid1]

  set rep_list [set ${self}::rep_list($key)]
  set rep_num [set ${self}::rep_num($key)]
  
  set rep_sel1 [[namespace current]::ParseSel [$tab_rep.disp1.sel.e get 1.0 end] ""]

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
  # Delete graphic representation
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
  # Show information about a matrix cell
  if {[set ${self}::info_sticky] && $stick} return
  
  set indices [split $key ,:]
  lassign $indices i j k l
  set ${self}::info_key1 [format "[set ${self}::format_key]" $i $j]
  set ${self}::info_key2 [format "[set ${self}::format_key]" $k $l]
  set ${self}::info_value [format "[set ${self}::format_data]" $val]
}


proc itrajcomp::MapAdd {self key {check 0}} {
  # Add a matrix cell to representation
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
  # Delete a matrix cell from representation
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
  # Add/delete matrix cell to/from representation
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
  # Select matrix cells
  #  in column/row
  #    mod1 = 0: select both columns and rows
  #    mod1 = 1: select only columns
  #    mod1 = 2: select only rows
  #  with values
  #    mod2 = 0: all
  #    mod2 = 1: less/equal than selected cell
  #    mod2 =-1: greater/equal than selected cell

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


proc itrajcomp::MapCluster2 {self key {mod1 0} {mod2 0} } {
  # Select matrix cells
  #  with values
  #    mod1 = 0: all values
  #    mod1 = 1: >= than reference cell
  #    mod1 =-1: <= than reference cell
  # with reference value in
  #    mod2 = 0: selected cell
  #    mod2 = 1: scale

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
    if {$key1 eq $key2} {
      continue
    }
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
  # Unselect all matrix cells
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
  # Update representation in vmd window
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
	  if {[info exists ${self}::cutoff]} {
	    set cutoff [set ${self}::cutoff]
	    if {[info exists ${self}::angle]} {
	      set angle [set ${self}::angle]
	      mol modstyle  $repname $m $rep_style1 $cutoff $angle
	    } else {
	      mol modstyle  $repname $m $rep_style1 $cutoff
	    }
	  } else {
	    mol modstyle  $repname $m $rep_style1
	  }
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
  # Destroy object window and delete object
  [namespace current]::MapClear $self
  catch {destroy [set ${self}::win_obj]}
  [namespace current]::Objdelete $self
}


proc itrajcomp::help_keys { self } {
  # Keybinding help
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


proc itrajcomp::RepList {self} {
  # Print list of representations (for debuggin purposes)
  # TODO: not use, remove? or move to a debugging proc
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


proc itrajcomp::UpdateScale {self} {
  # Redraw scale

  set scale [set ${self}::scale]
  set format_scale [set ${self}::format_scale]
  set min [set ${self}::min]
  set max [set ${self}::max]

  set sc_h [winfo height $scale]
  set sc_w [winfo width $scale]
  set offset 10.
  
  # Delete all
  $scale delete all
  
  # Colors
  #-------
  set c_n 50
  set c_w $sc_w
  set c_h [expr ($sc_h-2*$offset)/$c_n]

  # Calculate interval increments
  if {[string index $format_scale [expr [string length $format_scale]-1] ] == "i"} {
    set c_inc [expr ($max-$min)/$c_n]
  } else {
    set c_inc [expr double($max-$min)/$c_n]
  }

  # Upper offset
  set val $min
  set color [[namespace current]::ColorScale $max $min $val 1.0]
  $scale create rectangle 0 0 $c_w $offset -fill $color -outline $color -tag "rect$val"
  $scale bind "rect$val" <B2-ButtonRelease> "[namespace current]::MapCluster2 $self $val -1 1"
  $scale bind "rect$val" <B3-ButtonRelease> "[namespace current]::MapCluster2 $self $val 1 1"

  # Intervals
  set val [expr $min+($min+$c_inc)/2]
  set y $offset
  for {set i 0} {$i < $c_n} {incr i} {
    set color [[namespace current]::ColorScale $max $min $val 1.0]
    $scale create rectangle 0 $y $c_w [expr $y+$c_h] -fill $color -outline $color -tag "rect$val"
    $scale bind "rect$val" <B2-ButtonRelease> "[namespace current]::MapCluster2 $self $val -1 1"
    $scale bind "rect$val" <B3-ButtonRelease> "[namespace current]::MapCluster2 $self $val 1 1"
    set val [expr $val+ $c_inc]
    set y [expr $y+$c_h]
  }

  # Lower offset
  set val $max
  set color [[namespace current]::ColorScale $max $min $val 1.0]
  $scale create rectangle 0 $y $c_w $sc_h -fill $color -outline $color -tag "rect$val"
  $scale bind "rect$val" <B2-ButtonRelease> "[namespace current]::MapCluster2 $self $val -1 1"
  $scale bind "rect$val" <B3-ButtonRelease> "[namespace current]::MapCluster2 $self $val 1 1"

  # Labels
  #-------
  set l_n 10
  set l_h [expr ($sc_h-2*$offset)/$l_n]
  
  # Intervals
  set val $min
  set y $offset
  if {[string index $format_scale [expr [string length $format_scale]-1] ] == "i"} {
    set l_inc [expr ($max-$min)/$l_n]
  } else {
    set l_inc [expr double($max-$min)/$l_n]
  }
  for {set i 0} {$i <= $l_n} {incr i} {
    $scale create line [expr $sc_w-5] $y $c_w $y
    $scale create text [expr $sc_w-10] $y -text [format $format_scale $val] -anchor e -font [list helvetica 7 normal] -tag "line$val"
    $scale bind "line$val" <B2-ButtonRelease> "[namespace current]::MapCluster2 $self $val -1 1"
    $scale bind "line$val" <B3-ButtonRelease> "[namespace current]::MapCluster2 $self $val 1 1"
    set val [expr $val+ $l_inc]
    set y [expr $y+$l_h]
  }
}