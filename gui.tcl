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
#      See maingui.tcl

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

    set win_obj [toplevel ".${self}_main"]

    wm protocol $win_obj WM_DELETE_WINDOW "[namespace parent]::Destroy $self"
    bind $win_obj <Unmap> "[namespace parent]::UpdateRes"
    bind $win_obj <Map> "[namespace parent]::UpdateRes"

    # TODO: provide option to rename the window (dialog?)
    set title "$self: $opts(type)"
    foreach v [array names opts] {
      append title " $v=$opts($v)"
    }
    wm title $win_obj $title
    wm iconname $win_obj $self 

    # Menu
    #-----
    set menubar [frame $win_obj.menubar -relief raised -bd 2]
    pack $win_obj.menubar -side top -padx 1 -fill x
    [namespace parent]::itcObjMenubar $self
    
    # Tabs
    #-----
    frame $win_obj.tabc
    pack $win_obj.tabc -side top -padx 1 -expand yes -fill both
    pack [buttonbar::create $menubar $win_obj.tabc] -side top -fill x

    # Graph
    variable tab_graph [buttonbar::add $menubar graph]
    buttonbar::name $menubar graph "Graph"
    [namespace parent]::itcObjGraph $self

    # Representation
    variable tab_rep [buttonbar::add $menubar rep]
    buttonbar::name $menubar rep "Representations"
    [namespace parent]::itcObjRep $self

    # Info
    variable tab_info [buttonbar::add $menubar info]
    buttonbar::name $menubar info "Info"
    [namespace parent]::itcObjInfo $self

    buttonbar::showframe $menubar graph
    update idletasks
  }
}


proc itrajcomp::itcObjMenubar {self} {
  # Menu for an itc object
  
  namespace eval [namespace current]::${self}:: {
    menubutton $menubar.file -text "File" -menu $menubar.file.menu -underline 0
    menu $menubar.file.menu -tearoff no
    #$menubar.file.menu add command -label "Save" -command "" -underline 0
    $menubar.file.menu add cascade -label "Save As..." -menu $menubar.file.menu.saveas -underline 0
    menu $menubar.file.menu.saveas -tearoff no
    foreach as [set [namespace parent]::save_format_list] {
      $menubar.file.menu.saveas add command -label $as -command "[namespace parent]::SaveDataBrowse $self $as"
    }
    $menubar.file.menu add command -label "View" -command "[namespace parent]::ViewData $self" -underline 0
    $menubar.file.menu add command -label "Hide" -command "wm withdraw .${self}_main" -underline 0
    $menubar.file.menu add command -label "Destroy" -command "[namespace parent]::Destroy $self" -underline 0
    pack $menubar.file -side left
    
    menubutton $menubar.transform -text "Transform" -menu $menubar.transform.menu -underline 0
    menu $menubar.transform.menu
    set transform_data1 1
    $menubar.transform.menu add checkbutton -label "Source is raw data" -variable "[namespace current]::transform_data1"
    $menubar.transform.menu add command -label "Reset to raw data" -command "[namespace parent]::TransformData $self copy 1" -underline 0
    $menubar.transform.menu add command -label "Inverse" -command "[namespace parent]::TransformData $self inverse 1" -underline 0
    $menubar.transform.menu add cascade -label "Normalize" -menu $menubar.transform.menu.normalize -underline 0
    menu $menubar.transform.menu.normalize -tearoff no
    foreach norm {minmax exp expmin} {
      $menubar.transform.menu.normalize add command -label $norm -command "[namespace parent]::TransformData $self norm_$norm 1"
    }
    pack $menubar.transform -side left
    
    menubutton $menubar.analysis -text "Analysis" -menu $menubar.analysis.menu -underline 0
    menu $menubar.analysis.menu -tearoff no
    $menubar.analysis.menu add command -label "Descriptive" -command "[namespace parent]::StatDescriptive $self" -underline 0
    pack $menubar.analysis -side left
    
    menubutton $menubar.help -text "Help" -menu $menubar.help.menu -underline 0
    menu $menubar.help.menu -tearoff no
    $menubar.help.menu add command -label "Keybindings" -command "[namespace parent]::help_keys $self" -underline 0
    $menubar.help.menu add command -label "About" -command "[namespace parent]::help_about [winfo parent $menubar]" -underline 0
    pack $menubar.help -side left
  }
}


proc itrajcomp::itcObjInfo {self} {
  # Construct info gui
  namespace eval [namespace current]::${self}:: {

    frame $tab_info.frame
    pack $tab_info.frame -side top -anchor nw -expand yes -fill x

    # Calculation type
    labelframe $tab_info.frame.calc -text "Calculation Type"
    pack $tab_info.frame.calc -side top -anchor nw -expand yes -fill x

    label $tab_info.frame.calc.type -text $opts(type)
    pack $tab_info.frame.calc.type -side top -anchor nw
    
    # Calculation options
    labelframe $tab_info.frame.opt -text "Calculation Options"
    pack $tab_info.frame.opt -side top -anchor nw -expand yes -fill x
    
    set row 1
    grid columnconfigure $tab_info.frame.opt 2 -weight 1
    incr row
    label $tab_info.frame.opt.diagonal_l -text "diagonal:"
    label $tab_info.frame.opt.diagonal_v -text "$opts(diagonal)"
    grid $tab_info.frame.opt.diagonal_l -row $row -column 1 -sticky nw
    grid $tab_info.frame.opt.diagonal_v -row $row -column 2 -sticky nw
    foreach v [array names opts] {
      if { $v == "type" || $v == "diagonal" } {continue}
      incr row
      label $tab_info.frame.opt.${v}_l -text "$v:"
      label $tab_info.frame.opt.${v}_v -text "$opts($v)"
      grid $tab_info.frame.opt.${v}_l -row $row -column 1 -sticky nw
      grid $tab_info.frame.opt.${v}_v -row $row -column 2 -sticky nw
    }

    # Selection set 1
    labelframe $tab_info.frame.sel1 -text "Selection 1"
    pack $tab_info.frame.sel1 -side top -anchor nw -expand yes -fill x

    set row 1
    grid columnconfigure $tab_info.frame.sel1 2 -weight 1
    
    label $tab_info.frame.sel1.mol_l -text "Molecule(s):"
    label $tab_info.frame.sel1.mol_v -text "$sets(mol1_def) ($sets(mol1))"
    grid $tab_info.frame.sel1.mol_l -row $row -column 1 -sticky nw
    grid $tab_info.frame.sel1.mol_v -row $row -column 2 -sticky nw

    incr row
    label $tab_info.frame.sel1.frame_l -text "Frame(s):"
    label $tab_info.frame.sel1.frame_v -text "$sets(frame1_def) ([[namespace parent]::SplitFrames $sets(frame1)])"
    grid $tab_info.frame.sel1.frame_l -row $row -column 1 -sticky nw
    grid $tab_info.frame.sel1.frame_v -row $row -column 2 -sticky nw

    incr row
    label $tab_info.frame.sel1.atom_l -text "Atom Sel:"
    label $tab_info.frame.sel1.atom_v -text "$sets(sel1)"
    grid $tab_info.frame.sel1.atom_l -row $row -column 1 -sticky nw
    grid $tab_info.frame.sel1.atom_v -row $row -column 2 -sticky nw

    # Selection set 2
    labelframe $tab_info.frame.sel2 -text "Selection 2"
    pack $tab_info.frame.sel2 -side top -anchor nw -expand yes -fill x

    if {$sets(samemols)} {
      label $tab_info.frame.sel2.same -text "Same as selection 1"
      pack $tab_info.frame.sel2.same -side top -anchor nw
    } else {
      set row 1
      grid columnconfigure $tab_info.frame.sel2 2 -weight 1
      
      label $tab_info.frame.sel2.mol_l -text "Molecule(s):"
      label $tab_info.frame.sel2.mol_v -text "$sets(mol2_def) ($sets(mol2))"
      grid $tab_info.frame.sel2.mol_l -row $row -column 1 -sticky nw
      grid $tab_info.frame.sel2.mol_v -row $row -column 2 -sticky nw
      
      incr row
      label $tab_info.frame.sel2.frame_l -text "Frame(s):"
      label $tab_info.frame.sel2.frame_v -text "$sets(frame2_def) ([[namespace parent]::SplitFrames $sets(frame2)])"
      grid $tab_info.frame.sel2.frame_l -row $row -column 1 -sticky nw
      grid $tab_info.frame.sel2.frame_v -row $row -column 2 -sticky nw
      
      incr row
      label $tab_info.frame.sel2.atom_l -text "Atom Sel:"
      label $tab_info.frame.sel2.atom_v -text "$sets(sel2)"
      grid $tab_info.frame.sel2.atom_l -row $row -column 1 -sticky nw
      grid $tab_info.frame.sel2.atom_v -row $row -column 2 -sticky nw
    }

    # Molecules list
    labelframe $tab_info.frame.mols -text "Molecules list"
    pack $tab_info.frame.mols -side top -anchor nw -expand yes -fill x
    set row 1
    grid columnconfigure $tab_info.frame.mols 3 -weight 1
    
    label $tab_info.frame.mols.header_n -text "Name"
    grid $tab_info.frame.mols.header_n -row $row -column 2 -sticky nw
    label $tab_info.frame.mols.header_f -text "Files"
    grid $tab_info.frame.mols.header_f -row $row -column 3 -sticky nw

    foreach m $sets(mol1) {
      incr row
      label $tab_info.frame.mols.l$m -text "$m:"
      grid $tab_info.frame.mols.l$m -row $row -column 1 -sticky nw

      label $tab_info.frame.mols.n$m -text "[molinfo $m get name]"
      grid $tab_info.frame.mols.n$m -row $row -column 2 -sticky nw

      foreach file [eval concat [molinfo $m get filename]] {
        label $tab_info.frame.mols.f$m$row -text "$file"
        grid $tab_info.frame.mols.f$m$row -row $row -column 3 -sticky nw
        incr row
      }
    }
  }
}


proc itrajcomp::itcObjGraph {self} {
  # construct graph gui
  namespace eval [namespace current]::${self}:: {
    variable map_active
    variable info_key1
    variable info_key2
    variable info_value
    variable info_sticky 0
    variable map_add 0
    variable map_del 0
    variable highlight 0.2
    variable grid 1

    frame $tab_graph.l
    frame $tab_graph.r
    pack $tab_graph.l -side left -expand yes -fill both
    pack $tab_graph.r -side right -fill y

    # Graph
    frame $tab_graph.l.graph -relief raised -bd 2
    pack $tab_graph.l.graph -side top -anchor nw -expand yes -fill both

    variable plot [canvas $tab_graph.l.graph.c -height 400 -width 400 -xscrollcommand "$tab_graph.l.graph.xs set" -yscrollcommand "$tab_graph.l.graph.ys set" -xscrollincrement 10 -yscrollincrement 10 -bg white]
    scrollbar $tab_graph.l.graph.xs -orient horizontal -command "$plot xview"
    scrollbar $tab_graph.l.graph.ys -orient vertical   -command "$plot yview"

    pack $tab_graph.l.graph.xs -side bottom -fill x
    pack $tab_graph.l.graph.ys -side right -fill y
    pack $plot -side right -expand yes -fill both

    # Data to display (index)
    if {[llength $datatype(sets)] > 0 } {
      set type_frame [frame $tab_graph.l.type]
      pack $type_frame -side top -anchor nw
      
      label $type_frame.l -text "Set:"
      pack $type_frame.l -side left -anchor nw
      for {set i 0} {$i < [llength $datatype(sets)]} {incr i} {
        set t [lindex $datatype(sets) $i]
        radiobutton $type_frame.$t -text $t -variable [namespace current]::data_index -value $i -command "[namespace parent]::TransformData $self copy 1"
        pack $type_frame.$t -side left -anchor nw
      }
    }

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

    # Zoom with the mousewheel
    bind $plot <Button-4> "[namespace parent]::Zoom $self 1"
    bind $plot <Button-5> "[namespace parent]::Zoom $self -1"

    # Update and fit graph
    [namespace parent]::UpdateGraph $self
    [namespace parent]::FitGraph $self
  }
}


proc itrajcomp::UpdateGraph {self} {
  # Update the graph

  switch [set ${self}::graph_opts(type)] {
    frames {
      set ${self}::graph_opts(header1) "mol"
      set ${self}::graph_opts(header2) "frame"
      set ${self}::graph_opts(format_key) "%3d %3d"
      [namespace current]::GraphFrames $self
    }
    segments {
      set ${self}::graph_opts(format_key) "%3d %3s"
      switch [set ${self}::opts(segment)] {
        byres {
          set ${self}::graph_opts(header1) "residue"
          set ${self}::graph_opts(header2) "resname"
          [namespace current]::GraphSegments $self
        }
        byatom {
          set ${self}::graph_opts(header1) "index"
          set ${self}::graph_opts(header2) "name"
          [namespace current]::GraphSegments $self
        }
      }
    }
  }
  [namespace current]::UpdateScale $self
}


proc itrajcomp::FitGraph {self} {
  # Fit graph by zooming

  set plot [set ${self}::plot]
  lassign [$plot bbox all] x1 y1 widthP heightP
  set widthC [$plot cget -width]
  set heightC [$plot cget -height]
  set factor 0
  if {$widthP < $widthC} {
    set factor [expr {int($widthC/$widthP)}]
  }
  if {$heightP < $heightC} {
    set factor2 [expr {int($heightC/$heightP)}]
    if {$factor2 < $factor} {
      set factor $factor2
    }
  }
  if {$factor} {
    [namespace current]::Zoom $self $factor
  }
}


proc itrajcomp::itcObjRep {self} {
  # construct representations gui
  namespace eval [namespace current]::${self}:: {

    frame $tab_rep.frame
    pack $tab_rep.frame -side top -anchor nw -expand yes -fill x

    variable rep_sw 1
    foreach x [list 1] {
      labelframe $tab_rep.frame.disp$x -text "Representation"
      pack $tab_rep.frame.disp$x -side top -expand yes -fill x

      checkbutton $tab_rep.frame.disp$x.sw -text "On/Off" -variable [namespace current]::rep_sw -command "[namespace parent]::UpdateSelection $self"
      pack $tab_rep.frame.disp$x.sw -side left

      # Selection
      #----------
      labelframe $tab_rep.frame.disp$x.sel -text "Selection"
      pack $tab_rep.frame.disp$x.sel -side left -anchor nw -expand yes -fill both
      
      text $tab_rep.frame.disp$x.sel.e -exportselection yes -height 2 -width 25 -wrap word
      $tab_rep.frame.disp$x.sel.e insert end $sets(rep_sel$x)
      pack $tab_rep.frame.disp$x.sel.e -side top -anchor w -expand yes -fill both
      
      # Style
      #------
      set style [labelframe $tab_rep.frame.disp$x.style -text "Style"]
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

    # TODO: change connect_sw to graphics_sw (and same with related variables)
    # TODO: add color schemes for connecting lines in the GUI interface
    # Connecting lines
    # segment graphs
    if {$graph_opts(type) == "segments"} {
      variable connect_sw 1
      #      variable connect_all 1
      labelframe $tab_rep.frame.connect -text "Connecting lines"
      pack $tab_rep.frame.connect -side top -expand yes -fill x

      checkbutton $tab_rep.frame.connect.sw -text "On/Off" -variable [namespace current]::connect_sw -command "[namespace parent]::UpdateSelection $self"
      pack $tab_rep.frame.connect.sw -side left
      #      checkbutton $tab_rep.frame.connect.all -text "All" -variable [namespace current]::connect_all -command "[namespace parent]::UpdateSelection $self"
      #      pack $tab_rep.frame.connect.all -side left
    }
    
    # frames graphs
    # TODO: add right type of data (dual?)
    if {$graph_opts(type) == "frames"} {
      variable connect_sw 1
      labelframe $tab_rep.frame.connect -text "Connecting lines"
      pack $tab_rep.frame.connect -side top -expand yes -fill x

      checkbutton $tab_rep.frame.connect.sw -text "On/Off" -variable [namespace current]::connect_sw -command "[namespace parent]::UpdateSelection $self"
      pack $tab_rep.frame.connect.sw -side left
      #      checkbutton $tab_rep.frame.connect.all -text "All" -variable [namespace current]::connect_all -command "[namespace parent]::UpdateSelection $self"
      #      pack $tab_rep.frame.connect.all -side left
    }

    # Update button
    #--------------
    button $tab_rep.frame.but -text "Update" -command "[namespace parent]::UpdateSelection $self"
    pack $tab_rep.frame.but -side top

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

  set values {}
  foreach key [array names data] {
    lappend values $data($key)
  }
  lassign [[namespace current]::stats $values] mean std min max

  lassign [[namespace current]::_format f] format_data format_scale
  set mean [format "$format_data" $mean]
  set std  [format "$format_data" $std]
  set min  [format "$format_data" $min]
  set max  [format "$format_data" $max]
  
  tk_messageBox -title "$self Stats"  -parent [set ${self}::win_obj] -message \
    "Descriptive statistics
----------------------------------------
Mean:\t$mean
Std:\t$std
Min:\t$min
Max:\t$max

"

}


proc itrajcomp::Zoom {self zoom} {
  # Zoom in and out in the matrix plot
  set grid [set ${self}::grid]
  set plot [set ${self}::plot]

  set maxzoom 40
  set minzoom 1

  if {$zoom < 0} {
    if {[expr {$grid+$zoom}] < $minzoom} {
      set zoom [expr {$minzoom - $grid}]
    }

  } elseif {$zoom > 0} {
    if {[expr {$grid+$zoom}] > $maxzoom} {
      set zoom [expr {$maxzoom - $grid}]
    }
  }
  if {$zoom == 0} {
    set tab_graph [set ${self}::tab_graph]
    [namespace current]::flash_widget $tab_graph.r.zoom.val
    return
  }

  set old [expr {1.0*$grid}]
  set grid [expr {$grid + $zoom}]
  set ${self}::grid $grid

  set factor [expr {$grid/$old}]
  $plot scale all 0 0 $factor $factor

  # Update scrollbars
  set bbox [$plot bbox all]
  if {[llength $bbox]} {
    $plot configure -scrollregion $bbox
  } else {
    $plot configure -scrollregion [list 0 0 [expr {[winfo width $plot]}] [expr {[winfo height $plot]}]]
  }
}


proc itrajcomp::AddRep {self key} {
  # Add graphic representation
  
  if {[set ${self}::rep_sw] == 0} {
    return
  }

  set tab_rep [set ${self}::tab_rep]
  array set graph_opts [array get ${self}::graph_opts]

  set rep_list [set ${self}::rep_list($key)]
  set rep_num [set ${self}::rep_num($key)]
  
  set rep_sel1 [[namespace current]::ParseSel [$tab_rep.frame.disp1.sel.e get 1.0 end] ""]

  incr rep_num
  
  #puts "add $key = $rep_num"
  if {$rep_num <= 1} {
    if {$graph_opts(rep_color1) eq "ColorID"} {
      set color [list $graph_opts(rep_color1) $graph_opts(rep_colorid1)]
    } else {
      set color $graph_opts(rep_color1)
    }
    lassign [[namespace current]::ParseKey $self $key] mols f s
    set rep_list {}
    foreach m $mols {
      lappend rep_list "$m:[[namespace current]::AddRep1 $m $f $s $graph_opts(rep_style1) $color]"
    }
    
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
    [namespace current]::DelRep1 [set ${self}::rep_list($key)]
  }
  set ${self}::rep_num($key) $rep_num
}


proc itrajcomp::AddConnect {self key} {
  # Connect two points
  
  # TODO: add graphics in a separate molecule?
  
  set connect_lines {}

  lassign [split $key ,] key1 key2

  switch [set ${self}::graph_opts(type)] {
    segments {
      # Add a line between two points (atoms or center of residue selection)

      #lassign [[namespace current]::ParseKey $self $key] mols frames sel0
      set mols [set ${self}::sets(mol1)]
      set frames [set ${self}::sets(frame1)]
      set tab_rep [set ${self}::tab_rep]
      set extra [[namespace current]::ParseSel [$tab_rep.frame.disp1.sel.e get 1.0 end] ""]

      for {set i 0} {$i < [llength $mols]} {incr i} {
        set m [lindex $mols $i]
        # TODO: use same color as in the cell
        graphics $m color 4
        
        switch [set ${self}::opts(segment)] {
          byatom {
            set sel1 [atomselect $m "index [lindex [split $key1 :] 0]"]
            set sel2 [atomselect $m "index [lindex [split $key2 :] 0]"]
          }
          byres {
            set sel1 [atomselect $m "residue [lindex [split $key1 :] 0] and ($extra)"]
            set sel2 [atomselect $m "residue [lindex [split $key2 :] 0] and ($extra)"]
          }
        }

        # TODO: connect_all
        #    if {[set ${self}::connect_all] == 1} {
        set molframes [lindex $frames $i]
        #    } else {
        #      set molframes [molinfo $m get frame]
        #    }
        foreach f $molframes {
          $sel1 frame $f
          $sel2 frame $f
          switch [set ${self}::opts(segment)] {
            byatom {
              lassign [$sel1 get {x y z}] coor1
              lassign [$sel2 get {x y z}] coor2
            }
            byres {
              set coor1 [measure center $sel1]
              set coor2 [measure center $sel2]
            }
          }
          set gid [graphics $m line $coor1 $coor2 width 1 style dashed]
          lappend connect_lines "$m:$gid"
          #puts "line $m $f $key $key2"
        }
      }
    }

    frames {
      switch [set ${self}::datatype(mode)] {
        single {
        }
        multiple {
        }
        dual {
          # TODO: draw different graphics (cone, line,..) based on calctype


          if {[set ${self}::datatype(ascii)]} {
	    lassign [split $key1 :] m1 f1
	    lassign [split $key2 :] m2 f2

	    # TODO: this will only work for hbonds
	    # try to generalize a bit more, maybe by specifying cones or lines, but
	    # also how format will be passed in data0 or/and which fields to use to draw the points
	    set nconnects [lindex [set ${self}::data0($key)] 0]
	    set connect_data [lindex [set ${self}::data0($key)] 1]
	    
	    set n_one_connect [llength $connect_data]
	    
	    # this should be passed with the calctype
	    set field1 1
	    set field2 0
	    # TODO: check field1 and field2 are within boundaries of n_one_connect
	    
	    set points1 [lindex $connect_data $field1]
	    set points2 [lindex $connect_data $field2]
	    
	    # TODO: other fields should be printed as well
	    #set hydrogens [lindex $connect_data 2]
	    
	    # set a different color for each cell, increasing colorID as they are selected to be drawn
	    set color [array size ${self}::connect_lines]
            [namespace current]::set_color top $color
	    
	    puts "Connects:"
	    for {set i 0} {$i < $nconnects} {incr i} {
	      set point1 [atomselect $m2 "index [lindex $points1 $i]" frame $f2]
	      set point2 [atomselect $m1 "index [lindex $points2 $i]" frame $f1]
	      set point1_label [$point1 get {resname resid name}]
	      set point2_label [$point2 get {resname resid name}]
	      set label ""
	      set gid ""
	      switch [set ${self}::graph_opts(connect)] {
		cones {
		  set label "cone"
		  set gid [[namespace current]::draw_cone top $point1 $point2 $color]
		}
		lines {
		  set label "line"
		  set gid [[namespace current]::draw_line top $point1 $point2 $color]
		}
		# TODO: Add default as lines (just in case, so gid is not empty
	      }
	      puts "$label $i ([lindex [colorinfo colors] $color]): $m1:$f1 [lindex $points2 $i] $point2_label -- $m2:$f2 [lindex $points1 $i] $point1_label"
	      lappend connect_lines "$m1:$gid"
	    }
	  }
        }
      }

    }
    
  }
  set ${self}::connect_lines($key) $connect_lines
}


proc itrajcomp::DelConnect {self key} {
  # Delete a line between two atoms
  if {[info exists ${self}::connect_lines($key)]} {
    foreach line [set ${self}::connect_lines($key)] {
      lassign [split $line :] m gid
      graphics $m delete $gid
    }
    unset ${self}::connect_lines($key)
  }
}


proc itrajcomp::ExplorePoint {self key} {
  # Print data for this cell
  switch [set ${self}::datatype(mode)] {
    single {
      set cell [set ${self}::data0($key)]
      set stats ""
    }
    multiple {
      set cell [set ${self}::data0($key)]
      set stats [set ${self}::data1($key)]
    }
    dual {
      if {[set ${self}::datatype(ascii)]} {
        set cell "[lindex [set ${self}::data0($key)] 0] ([lindex [set ${self}::data0($key)] 1])"
        set stats ""
      } else {
        set cell "[lindex [set ${self}::data0($key)] 0] ([lindex [set ${self}::data0($key)] 1])"
        set stats [lrange [set ${self}::data1($key)] 1 end]
      }
    }
  }

  puts "Data for cell $key"
  puts "   $cell"
  if {$stats != ""} {
    puts "Stats (avg, std, min, max):"
    puts "   $stats"
  }
}


proc itrajcomp::ShowPoint {self key val stick} {
  # Show information about a matrix cell
  array set graph_opts [array get ${self}::graph_opts]
  if {[set ${self}::info_sticky] && $stick} return
  
  lassign [split $key ,:] i j k l
  set ${self}::info_key1 [format "$graph_opts(format_key)" $i $j]
  set ${self}::info_key2 [format "$graph_opts(format_key)" $k $l]
  set ${self}::info_value [format "$graph_opts(format_data)" $val]
}


proc itrajcomp::MapAdd {self key {check 0}} {
  # Add a matrix cell to representation
  lassign [split $key ,] key1 key2
  
  set map_active [set ${self}::map_active($key)]
  if {$map_active == 1} {
    return
  }

  if {$check && $key1 == $key2} {
    return
  }
  
  set plot [set ${self}::plot]
  set color [set ${self}::colors_act($key)]
  $plot itemconfigure $key -fill $color
  $plot itemconfigure $key -outline black
  set ${self}::map_active($key) 1
  set ${self}::rep_active($key) 1
  [namespace current]::AddRep $self $key1
  [namespace current]::AddRep $self $key2
  
  if {[set ${self}::graph_opts(type)] == "segments"} {
    if {[set ${self}::connect_sw] == 1} {
      [namespace current]::AddConnect $self $key
    }
  }
  
  if {[set ${self}::graph_opts(type)] == "frames"} {
    switch [set ${self}::datatype(mode)] {
      single {
      }
      multiple {
      }
      dual {
        if {[set ${self}::datatype(ascii)]} {
          [namespace current]::AddConnect $self $key
        } else {
        }
      }
    }
  }
}


proc itrajcomp::MapDel {self key {check 0}} {
  # Delete a matrix cell from representation
  lassign [split $key ,] key1 key2

  set map_active [set ${self}::map_active($key)]
  if {$map_active == 0} {
    return
  }
  if {$check && $key1 == $key2} {
    return
  }
  
  set plot [set ${self}::plot]
  set color [set ${self}::colors($key)]
  $plot itemconfigure $key -fill $color
  $plot itemconfigure $key -outline $color
  set ${self}::map_active($key) 0
  
  if {[info exists ${self}::rep_active($key)]} {
    unset ${self}::rep_active($key)
    [namespace current]::DelRep $self $key1
    [namespace current]::DelRep $self $key2
  }
  
  lassign [[namespace current]::ParseKey $self $key] mols frames sel
  
  if {[set ${self}::graph_opts(type)] == "segments"} {
    [namespace current]::DelConnect $self $key
  }
  
  if {[set ${self}::graph_opts(type)] == "frames"} {
    switch [set ${self}::datatype(mode)] {
      single {
      }
      multiple {
      }
      dual {
        if {[set ${self}::datatype(ascii)]} {
          [namespace current]::DelConnect $self $key
        } else {
        }
      }
    }
  }
}


proc itrajcomp::MapPoint {self key data {mod 0}} {
  # Add/delete matrix cell to/from representation
  set map_active [set ${self}::map_active($key)]
  
  if {$map_active == 0 || $mod} {
    [namespace current]::MapAdd $self $key
    set mod 1
  }
  if {$map_active == 1 && !$mod} {
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

  variable map_active

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
    lassign [split $mykey ,] key1 key2
    if {$key1 eq $key2} {
      continue
    }
    if {!$mod1 || $mod1 == 1} {
      if {$data($mykey) >= $val} {
        set color black
        $plot itemconfigure $mykey -outline $color
        [namespace current]::AddRep $self $key1
        [namespace current]::AddRep $self $key2
        set ${self}::map_active($mykey) 1
        set ${self}::rep_active($mykey) 1
      }
    }
    if {!$mod1 || $mod1 == -1} {
      if {$data($mykey) <= $val} {
        set color black
        $plot itemconfigure $mykey -outline $color
        [namespace current]::AddRep $self $key1
        [namespace current]::AddRep $self $key2
        set ${self}::map_active($mykey) 1
        set ${self}::rep_active($mykey) 1
      }
    }
  }
}


proc itrajcomp::MapClear {self} {
  # Unselect all matrix cells
  set plot [set ${self}::plot]
  
  foreach key [set ${self}::keys] {
    if {[set ${self}::map_active($key)] == 1 } {
      $plot itemconfigure $key -fill [set ${self}::colors($key)]
      set ${self}::map_active($key) 0
      unset ${self}::rep_active($key)
    }
  }

  foreach key [array names ${self}::rep_list] {
    if {[set ${self}::rep_num($key)] > 0} {
      lassign [[namespace current]::ParseKey $self $key] m f s
      [namespace current]::DelRep1 [set ${self}::rep_list($key)]
      [namespace current]::DelConnect $self $key
      set ${self}::rep_num($key) 0
    }
  }
  #[namespace current]::RepList $self
  
  if {[set ${self}::graph_opts(type)] == "segments"} {
    foreach k [array names ${self}::connect_lines] {
      [namespace current]::DelConnect $self $k
    }
  }
  
  if {[set ${self}::graph_opts(type)] == "frames"} {
    switch [set ${self}::datatype(mode)] {
      single {
      }
      multiple {
      }
      dual {
        if {[set ${self}::datatype(ascii)]} {
          foreach k [array names ${self}::connect_lines] {
            [namespace current]::DelConnect $self $k
          }
        } else {
        }
      }
    }
  }

}


proc itrajcomp::UpdateSelection {self} {
  # Update representation in vmd window
  array set opts [array get ${self}::opts]
  array set graph_opts [array get ${self}::graph_opts]
  array set rep_list [array get ${self}::rep_list]
  set plot [set ${self}::plot]

  # On/Off representation
  set rep_sw [set ${self}::rep_sw]
  array set rep_active [array get ${self}::rep_active]
  foreach id [$plot find all] {
    set key [$plot gettags $id]
    lassign [split $key ,] key1 key2
    if {[$plot itemcget $id -outline] == "black"} {
      if {[info exists rep_active($key)]} {
        if {$rep_sw == 0} {
          unset ${self}::rep_active($key)
          [namespace current]::DelRep $self $key1
          [namespace current]::DelRep $self $key2
        }
      } else {
        if {$rep_sw == 1} {
          set ${self}::rep_active($key) 1
          [namespace current]::AddRep $self $key1
          [namespace current]::AddRep $self $key2
        }
      }
    }
  }
  
  # Representation style
  foreach key [array names rep_list] {
    if {[set ${self}::rep_num($key)] > 0} {
      lassign [[namespace current]::ParseKey $self $key] mols f s
      
      foreach r $rep_list($key) {
        lassign [split $r :] m rep
        
        set repname [mol repindex $m $rep]
        
        # Selection
        mol modselect $repname $m $s
        
        # Style
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
        
        # Color
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

  # On/Off connecting lines
  if {[set ${self}::graph_opts(type)] == "segments"} {
    set connect_sw [set ${self}::connect_sw]
    array set connect_lines [array get ${self}::connect_lines]
    foreach id [$plot find all] {
      set key [$plot gettags $id]
      if {[$plot itemcget $id -outline] == "black"} {
        if {[info exists connect_lines($key)]} {
          if {$connect_sw == 0} {
            [namespace current]::DelConnect $self $key
          }
        } else {
          if {$connect_sw == 1} {
            [namespace current]::AddConnect $self $key
          }
        }
      }
    }
  }

  # TODO: check for right type of data in frames (dual?)
  if {[set ${self}::graph_opts(type)] == "frames"} {
    set connect_sw [set ${self}::connect_sw]
    array set connect_lines [array get ${self}::connect_lines]
    foreach id [$plot find all] {
      set key [$plot gettags $id]
      if {[$plot itemcget $id -outline] == "black"} {
        if {[info exists connect_lines($key)]} {
          if {$connect_sw == 0} {
            [namespace current]::DelConnect $self $key
          }
        } else {
          if {$connect_sw == 1} {
            [namespace current]::AddConnect $self $key
          }
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
  [namespace current]::UpdateRes
}


proc itrajcomp::help_keys {self} {
  # Keybinding help
  set vn [package present itrajcomp]

  set r [toplevel ".${self}_keybindings"]
  wm title $r "iTrajComp v$vn - Keybindings"
  text $r.data -exportselection yes -width 80 -font [list helvetica 10]
  pack $r.data -side right -expand yes -fill both
  $r.data insert end "iTrajComp v$vn Keybindings\n\n" title
  $r.data insert end "B1\t" button
  $r.data insert end "Select/Deselect one cell.\n"
  $r.data insert end "B2\t" button
  $r.data insert end "Explore data for cell.\n"
  $r.data insert end "Shift-B1\t" button
  $r.data insert end "Selects all cells in column/row of data.\n"
  $r.data insert end "Shift-B2\t" button
  $r.data insert end "Selects all cells in column/row with values <= than data clicked.\n"
  $r.data insert end "Shift-B3\t" button
  $r.data insert end "Selects all cells in column/row with values => than data clicked.\n"
  $r.data insert end "Ctrl-B1\t" button
  $r.data insert end "Selects all cells.\n"
  $r.data insert end "Ctrl-B2\t" button
  $r.data insert end "Selects all cells with values <= than data clicked.\n"
  $r.data insert end "Ctrl-B3\t" button
  $r.data insert end "Selects all cells with values => than data clicked.\n\n\n"
  $r.data insert end "Copyright (C) Luis Gracia <lug2002@med.cornell.edu>\n"

  $r.data tag configure title -font [list helvetica 12 bold]
  $r.data tag configure button -font [list helvetica 10 bold]

}


proc itrajcomp::RepList {self} {
  # Print list of representations (for debuggin purposes)
  array set map_active [array get ${self}::map_active]
  array set rep_list [array get ${self}::rep_list]
  array set rep_num [array get ${self}::rep_num]

  foreach key [lsort [array names rep_list]] {
    puts "rep_list: $key $rep_list($key)"
  }
  foreach key [lsort [array names rep_num]] {
    puts "rep_num: $key $rep_num($key)"
  }
  foreach key [lsort [array names map_active]] {
    puts "map_active: $key $map_active($key)"
  }
  puts "-----"
}


proc itrajcomp::UpdateScale {self} {
  # Redraw scale
  array set graph_opts [array get ${self}::graph_opts]

  set scale [set ${self}::scale]
  set min [set ${self}::min]
  set max [set ${self}::max]

  set format_scale $graph_opts(format_scale)

  set sc_h [winfo height $scale]
  set sc_w [winfo width $scale]
  set offset 10.
  
  # Delete all
  $scale delete all
  
  # Colors
  #-------
  set c_n 50
  set c_w $sc_w
  set c_h [expr {($sc_h-2*$offset)/$c_n}]

  set int 0
  if {[string index $format_scale [expr {[string length $format_scale]-1}] ] == "i"} {
    set int 1
  }

  # Upper offset
  set val $min
  set color [[namespace current]::ColorScale $val $max $min]
  $scale create rectangle 0 0 $c_w $offset -fill $color -outline $color -tag "rect$val"
  $scale bind "rect$val" <B2-ButtonRelease> "[namespace current]::MapCluster2 $self $val -1 1"
  $scale bind "rect$val" <B3-ButtonRelease> "[namespace current]::MapCluster2 $self $val 1 1"

  # Intervals
  set c_inc [expr {double($max-$min)/$c_n}]
  set val [expr {$min+($c_inc/2)}]
  set y $offset
  for {set i 0} {$i < $c_n} {incr i} {
    set color [[namespace current]::ColorScale $val $max $min]
    $scale create rectangle 0 $y $c_w [expr {$y+$c_h}] -fill $color -outline $color -tag "rect$val"
    $scale bind "rect$val" <B2-ButtonRelease> "[namespace current]::MapCluster2 $self $val -1 1"
    $scale bind "rect$val" <B3-ButtonRelease> "[namespace current]::MapCluster2 $self $val 1 1"
    set val [expr {$val+ $c_inc}]
    set y [expr {$y+$c_h}]
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
  set l_h [expr {($sc_h-2*$offset)/$l_n}]
  
  # Intervals
  set val $min
  set y $offset
  set l_inc [expr {double($max-$min)/$l_n}]

  for {set i 0} {$i <= $l_n} {incr i} {
    if {$int > 0} {
      set newval [expr {int($val)}]
    } else {
      set newval $val
    }
    $scale create line [expr {$sc_w-5}] $y $c_w $y
    $scale create text [expr {$sc_w-10}] $y -text [format $format_scale $newval] -anchor e -font [list helvetica 7 normal] -tag "line$val"
    $scale bind "line$val" <B2-ButtonRelease> "[namespace current]::MapCluster2 $self $val -1 1"
    $scale bind "line$val" <B3-ButtonRelease> "[namespace current]::MapCluster2 $self $val 1 1"
    set val [expr {$val+ $l_inc}]
    set y [expr {$y+$l_h}]
  }
}
