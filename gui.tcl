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
    set title "$self: $opts(type)"
    foreach v [array names opts] {
      append title " $v=$opts($v)"
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
    pack [buttonbar::create $menubar $win_obj.tabc] -side top -fill x

    # Info
    variable tab_info [buttonbar::add $menubar info]
    buttonbar::name $menubar info "Info"
    [namespace parent]::itcObjInfo $self

    # Graph
    variable tab_graph [buttonbar::add $menubar graph]
    buttonbar::name $menubar graph "Graph"
    [namespace parent]::itcObjGraph $self

    # Representation
    variable tab_rep [buttonbar::add $menubar rep]
    buttonbar::name $menubar rep "Representations"
    [namespace parent]::itcObjRep $self

    buttonbar::showframe $menubar graph
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
  pack $w.help -side left
}


proc itrajcomp::itcObjInfo {self} {
  # Construct info gui
  namespace eval [namespace current]::${self}:: {

    # Calculation type
    labelframe $tab_info.calc -text "Calculation Type"
    pack $tab_info.calc -side top -anchor nw -expand yes -fill x

    label $tab_info.calc.type -text $opts(type)
    pack $tab_info.calc.type -side top -anchor nw
    
    # Calculation options
    labelframe $tab_info.opt -text "Calculation Options"
    pack $tab_info.opt -side top -anchor nw -expand yes -fill x
    
    set row 1
    grid columnconfigure $tab_info.opt 2 -weight 1
    incr row
    label $tab_info.opt.diagonal_l -text "diagonal:"
    label $tab_info.opt.diagonal_v -text "$opts(diagonal)"
    grid $tab_info.opt.diagonal_l -row $row -column 1 -sticky nw
    grid $tab_info.opt.diagonal_v -row $row -column 2 -sticky nw
    foreach v [array names opts] {
      if { $v == "type" || $v == "diagonal" } {continue}
      incr row
      label $tab_info.opt.${v}_l -text "$v:"
      label $tab_info.opt.${v}_v -text "$opts($v)"
      grid $tab_info.opt.${v}_l -row $row -column 1 -sticky nw
      grid $tab_info.opt.${v}_v -row $row -column 2 -sticky nw
    }

    # Selection set 1
    labelframe $tab_info.sel1 -text "Selection 1"
    pack $tab_info.sel1 -side top -anchor nw -expand yes -fill x

    set row 1
    grid columnconfigure $tab_info.sel1 2 -weight 1
    
    label $tab_info.sel1.mol_l -text "Molecule(s):"
    label $tab_info.sel1.mol_v -text "$sets(mol1_def) ($sets(mol1))"
    grid $tab_info.sel1.mol_l -row $row -column 1 -sticky nw
    grid $tab_info.sel1.mol_v -row $row -column 2 -sticky nw

    # TODO: put frames for each mol in a different row
    incr row
    label $tab_info.sel1.frame_l -text "Frame(s):"
    label $tab_info.sel1.frame_v -text "$sets(frame1_def) ([[namespace parent]::SplitFrames $sets(frame1)])"
    grid $tab_info.sel1.frame_l -row $row -column 1 -sticky nw
    grid $tab_info.sel1.frame_v -row $row -column 2 -sticky nw

    incr row
    label $tab_info.sel1.atom_l -text "Atom Sel:"
    label $tab_info.sel1.atom_v -text "$sets(sel1)"
    grid $tab_info.sel1.atom_l -row $row -column 1 -sticky nw
    grid $tab_info.sel1.atom_v -row $row -column 2 -sticky nw

    # Selection set 2
    labelframe $tab_info.sel2 -text "Selection 2"
    pack $tab_info.sel2 -side top -anchor nw -expand yes -fill x

    set row 1
    grid columnconfigure $tab_info.sel2 2 -weight 1
    
    label $tab_info.sel2.mol_l -text "Molecule(s):"
    label $tab_info.sel2.mol_v -text "$sets(mol2_def) ($sets(mol2))"
    grid $tab_info.sel2.mol_l -row $row -column 1 -sticky nw
    grid $tab_info.sel2.mol_v -row $row -column 2 -sticky nw

    incr row
    label $tab_info.sel2.frame_l -text "Frame(s):"
    label $tab_info.sel2.frame_v -text "$sets(frame2_def) ([[namespace parent]::SplitFrames $sets(frame2)])"
    grid $tab_info.sel2.frame_l -row $row -column 1 -sticky nw
    grid $tab_info.sel2.frame_v -row $row -column 2 -sticky nw

    incr row
    label $tab_info.sel2.atom_l -text "Atom Sel:"
    label $tab_info.sel2.atom_v -text "$sets(sel2)"
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

    foreach m $sets(mol1) {
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

    frame $tab_graph.r.zoom.incr
    pack $tab_graph.r.zoom.incr
    button $tab_graph.r.zoom.incr.1 -text "+1" -width 2 -padx 1 -pady 0 -command "[namespace parent]::Zoom $self 1" -font [list helvetica 6]
    button $tab_graph.r.zoom.incr.5 -text "+5" -width 2 -padx 1 -pady 0 -command "[namespace parent]::Zoom $self 5" -font [list helvetica 6]
    pack $tab_graph.r.zoom.incr.1 $tab_graph.r.zoom.incr.5 -side left

    entry $tab_graph.r.zoom.val -width 2 -textvariable [namespace current]::grid
    pack $tab_graph.r.zoom.val -fill x

    frame $tab_graph.r.zoom.decr
    pack $tab_graph.r.zoom.decr
    button $tab_graph.r.zoom.decr.1 -text "-1" -width 2 -padx 1 -pady 0 -command "[namespace parent]::Zoom $self -1" -font [list helvetica 6]
    button $tab_graph.r.zoom.decr.5 -text "-5" -width 2 -padx 1 -pady 0 -command "[namespace parent]::Zoom $self -5" -font [list helvetica 6]
    pack $tab_graph.r.zoom.decr.1 $tab_graph.r.zoom.decr.5 -side left

    switch $graph_opts(type) {
      frames {
	set graph_opts(header1) "mol"
	set graph_opts(header2) "frame"
	[namespace parent]::GraphFrames $self
      }
      segments {
	switch $opts(segment) {
	  byres {
	    set graph_opts(header1) "residue"
	    set graph_opts(header2) "resname"
	    [namespace parent]::GraphSegments $self
	  }
	  byatom {
	    set graph_opts(header1) "index"
	    set graph_opts(header2) "name"
	    [namespace parent]::GraphSegments $self
	  }
	}
      }
    }
    # TODO: zoom to a better level depending on the size of the matrix and the space available
    [namespace parent]::Zoom $self -5
  }
}


proc itrajcomp::itcObjRep {self} {
  # construct representations gui
  namespace eval [namespace current]::${self}:: {

    foreach x [list 1] {
      frame $tab_rep.disp$x
      pack $tab_rep.disp$x -side left -expand yes -fill x

      # Selection
      #----------
      labelframe $tab_rep.disp$x.sel -text "Selection"
      pack $tab_rep.disp$x.sel -side left -anchor nw -expand yes -fill both
      
      text $tab_rep.disp$x.sel.e -exportselection yes -height 2 -width 25 -wrap word
      $tab_rep.disp$x.sel.e insert end $sets(rep_sel$x)
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

      menubutton $style.draw.m -text "Drawing" -menu $style.draw.m.list -textvariable [namespace current]::graph_opts(rep_style$x) -relief raised
      menu $style.draw.m.list
      foreach entry $rep_style_list {
 	$style.draw.m.list add radiobutton -label $entry -variable [namespace current]::graph_opts(rep_style$x) -value $entry -command "[namespace parent]::UpdateSelection $self"
      }
      pack $style.draw.m

      # Color
      frame $style.color
      pack $style.color -side top -anchor nw

      label $style.color.l -text "Color:"
      pack $style.color.l -side left

      menubutton $style.color.m -text "Color" -menu $style.color.m.list -textvariable [namespace current]::graph_opts(rep_color$x) -relief raised
      menu $style.color.m.list
      foreach entry $rep_color_list {
 	if {$entry eq "ColorID"} {
 	  $style.color.m.list add radiobutton -label $entry -variable [namespace current]::graph_opts(rep_color$x) -value $entry -command "$style.color.id config -state normal; [namespace parent]::UpdateSelection $self"
 	} else {
 	  $style.color.m.list add radiobutton -label $entry -variable [namespace current]::graph_opts(rep_color$x) -value $entry -command "$style.color.id config -state disable; [namespace parent]::UpdateSelection $self"
 	}
      }

      menubutton $style.color.id -text "ColorID" -menu $style.color.id.list -textvariable [namespace current]::graph_opts(rep_colorid$x) -relief raised -state disable
      menu $style.color.id.list
      set a [colorinfo colors]
      for {set i 0} {$i < [llength $a]} {incr i} {
  	$style.color.id.list add radiobutton -label "$i [lindex $a $i]" -variable [namespace current]::graph_opts(rep_colorid$x) -value $i -command "[namespace parent]::UpdateSelection $self"
      }
      pack $style.color.m $style.color.id -side left
    }

    # Update button
    #--------------
    button $tab_rep.but -text "Update"  -command "[namespace parent]::UpdateSelection $self"
    pack $tab_rep.but -side left
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
  array set graph_opts [array get ${self}::graph_opts]

  # Mean
  set mean 0.0
  foreach mykey [array names data] {
    set mean [expr $mean + $data($mykey)]
  }
  set mean [expr $mean / double([array size data] - 1)]

  # Std
  set sd 0.0
  foreach mykey [array names data] {
    set temp [expr $data($mykey) - $mean]
    set sd [expr $sd + $temp*$temp]
  }
  set sd [expr sqrt($sd / double([array size data] - 1))]

  set mean [format "$graph_opts(format_data)" $mean]
  set sd [format "$graph_opts(format_data)" $sd]

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
  array set graph_opts [array get ${self}::graph_opts]

  set rep_list [set ${self}::rep_list($key)]
  set rep_num [set ${self}::rep_num($key)]
  
  set rep_sel1 [[namespace current]::ParseSel [$tab_rep.disp1.sel.e get 1.0 end] ""]

  incr rep_num
  
  #puts "add $key = $rep_num"
  if {$rep_num <= 1} {
    if {$graph_opts(rep_color1) eq "ColorID"} {
      set color [list $graph_opts(rep_color1) $graph_opts(rep_colorid1)]
    } else {
      set color $graph_opts(rep_color1)
    }
    lassign [[namespace current]::ParseKey $self $key] m f s
    set rep_list [[namespace current]::AddRep1 $m $f $s $graph_opts(rep_style1) $color]
    
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
  array set graph_opts [array get ${self}::graph_opts]
  if {[set ${self}::info_sticky] && $stick} return
  
  set indices [split $key ,:]
  lassign $indices i j k l
  set ${self}::info_key1 [format "$graph_opts(format_key)" $i $j]
  set ${self}::info_key2 [format "$graph_opts(format_key)" $k $l]
  set ${self}::info_value [format "$graph_opts(format_data)" $val]
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
  array set opts [array get ${self}::opts]
  array set graph_opts [array get ${self}::graph_opts]
  array set rep_list [array get ${self}::rep_list]
 
  foreach key [array names rep_list] {
    if {[set ${self}::rep_num($key)] > 0} {
      lassign [[namespace current]::ParseKey $self $key] m f s
      set repname [mol repindex $m $rep_list($key)]
      mol modselect $repname $m $s
      switch $graph_opts(rep_style1) {
	HBonds {
	  if {[info exists opts(cutoff)]} {
	    if {[info exists opts(angle)]} {
	      mol modstyle $repname $m $graph_opts(rep_style1) $opts(cutoff) $opts(angle)
	    } else {
	      mol modstyle $repname $m $graph_opts(rep_style1) $opts(cutoff)
	    }
	  } else {
	    mol modstyle $repname $m $graph_opts(rep_style1)
	  }
	}
	default {
	  mol modstyle $repname $m $graph_opts(rep_style1)
	}
      }
      switch $graph_opts(rep_color1) {
	ColorID {
	  mol modcolor $repname $m $graph_opts(rep_color1) $graph_opts(rep_colorid1)
	}
	default {
	  mol modcolor $repname $m $graph_opts(rep_color1)
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


proc itrajcomp::help_keys {self} {
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
  array set graph_opts [array get ${self}::graph_opts]

  set scale [set ${self}::scale]
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

  set int 0
  if {[string index $graph_opts(format_scale) [expr [string length $graph_opts(format_scale)]-1] ] == "i"} {
    set int 1
  }

  # Upper offset
  set val $min
  set color [[namespace current]::ColorScale $val $max $min]
  $scale create rectangle 0 0 $c_w $offset -fill $color -outline $color -tag "rect$val"
  $scale bind "rect$val" <B2-ButtonRelease> "[namespace current]::MapCluster2 $self $val -1 1"
  $scale bind "rect$val" <B3-ButtonRelease> "[namespace current]::MapCluster2 $self $val 1 1"

  # Intervals
  set c_inc [expr double($max-$min)/$c_n]
  set val [expr $min+($c_inc/2)]
  set y $offset
  for {set i 0} {$i < $c_n} {incr i} {
    set color [[namespace current]::ColorScale $val $max $min]
    $scale create rectangle 0 $y $c_w [expr $y+$c_h] -fill $color -outline $color -tag "rect$val"
    $scale bind "rect$val" <B2-ButtonRelease> "[namespace current]::MapCluster2 $self $val -1 1"
    $scale bind "rect$val" <B3-ButtonRelease> "[namespace current]::MapCluster2 $self $val 1 1"
    set val [expr $val+ $c_inc]
    set y [expr $y+$c_h]
  }

  # Lower offset
  set val $max
  set color [[namespace current]::ColorScale $val $max $min]
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
  set l_inc [expr double($max-$min)/$l_n]

  for {set i 0} {$i <= $l_n} {incr i} {
    if {$int > 0} {
      set newval [expr int($val)]
    } else {
      set newval $val
    }
    $scale create line [expr $sc_w-5] $y $c_w $y
    $scale create text [expr $sc_w-10] $y -text [format $graph_opts(format_scale) $newval] -anchor e -font [list helvetica 7 normal] -tag "line$val"
    $scale bind "line$val" <B2-ButtonRelease> "[namespace current]::MapCluster2 $self $val -1 1"
    $scale bind "line$val" <B3-ButtonRelease> "[namespace current]::MapCluster2 $self $val 1 1"
    set val [expr $val+ $l_inc]
    set y [expr $y+$l_h]
  }
}