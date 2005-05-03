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

# gui.tcl
#    GUI for the rmsdtt2 objects.


package provide rmsdtt2 2.0

proc rmsdtt2::NewPlot {self} {
  namespace eval [namespace current]::${self}:: {

    set rep_style_list [list Lines Bonds DynamicBonds HBonds Points VDW CPK Licorice Trace Tube Ribbons NewRibbons Cartoon NewCartoon MSMS Surf VolumeSlice Isosurface Dotted Solvent]
    set rep_color_list [list Name Type ResName ResType ResID Chain SegName Molecule Structure ColorID Beta Occupancy Mass Charge Pos User Index Backbone Throb Timestep Volume]
    set save_format_list [list tab matrix plotmtv plotmtv_binary postscript]

    variable add_rep
    variable info_key1
    variable info_key2
    variable info_value
    variable info_sticky  0
    variable p
    variable plot
    variable r_thres_rel  0.5
    variable N_crit_rel   0.5
    variable grid
    variable clustering_graphics 0
    variable rep_style1    NewRibbons
    variable rep_color1    Molecule
    variable rep_colorid1  0
    variable highlight    0.2
    variable save_format  tab
    

    set p [toplevel ".${self}_plot"]
    wm title $p "$self $type"
    
    frame $p.u -relief raised -bd 2
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
    entry $p.u.l.info.keys_entry1 -width 7 -textvariable [namespace current]::info_key1
    entry $p.u.l.info.keys_entry2 -width 7 -textvariable [namespace current]::info_key2
    pack $p.u.l.info.keys_label $p.u.l.info.keys_entry1 $p.u.l.info.keys_entry2 -side left
    
    label $p.u.l.info.rmsd_label -text "RMSD:"
    entry $p.u.l.info.rmsd_entry -width 8 -textvariable [namespace current]::info_value
    pack $p.u.l.info.rmsd_label $p.u.l.info.rmsd_entry -side left

    checkbutton $p.u.l.info.sticky -text "Sticky" -variable [namespace current]::info_sticky
    pack $p.u.l.info.sticky -side left

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
      $scale create rectangle 0 $y $rg_w [expr $y+$rg_h] -fill $color -outline $color
      set val [expr $val+ $reg]
      set y [expr $y+$rg_h]
    }
    
    set y $off
    set val $min
    set reg [expr double($max-$min)/$lb_n]
    for {set i 0} {$i <= $lb_n} {incr i} {
      $scale create line 15 $y $rg_w $y
      if {$type eq "rms"} { 
	$scale create text [expr $rg_w+1] $y -text [format "%4.2f" $val] -anchor w -font [list helvetica 6 normal] -tag "line$val"
	$scale bind "line$val" <Shift-B1-ButtonRelease> "[namespace parent]::MapCluster2 $self $val 1"
	$scale bind "line$val" <Control-B1-ButtonRelease> "[namespace parent]::MapCluster2 $self $val 0"
      } else {
	$scale create text [expr $rg_w+1] $y -text [format "%4i" [expr int($val)]] -anchor w -font [list helvetica 6 normal] -tag "line$val"
	$scale bind "line$val" <Shift-B1-ButtonRelease> "[namespace parent]::MapCluster2 $self $val 1"
	$scale bind "line$val" <Control-B1-ButtonRelease> "[namespace parent]::MapCluster2 $self $val 0"
      }
      set val [expr $val+ $reg]
      set y [expr $y+$lb_h]
    }
    
    # Clear button
    button $p.u.r.clear -text "Clear" -command "[namespace parent]::MapClear $self"
    pack $p.u.r.clear -side bottom

    # Zoom
    frame $p.u.r.zoom  -relief ridge -bd 2
    pack $p.u.r.zoom -side bottom

    label $p.u.r.zoom.label -text "Zoom"
    button $p.u.r.zoom.incr -text "+" -command "[namespace parent]::Zoom $self 1"
    entry $p.u.r.zoom.val -width 2 -textvariable [namespace current]::grid
    button $p.u.r.zoom.decr -text "-" -command "[namespace parent]::Zoom $self -1"
    pack $p.u.r.zoom.label $p.u.r.zoom.incr $p.u.r.zoom.val $p.u.r.zoom.decr
    
    # Calculation info
    frame $p.l.l.info -relief ridge -bd 4
    pack $p.l.l.info -side top -expand yes -fill x 

    label $p.l.l.info.type -text "$type" -font [list fixed 10 bold]
    pack $p.l.l.info.type -side left

    frame $p.l.l.info.sel
    pack $p.l.l.info.sel -side left

    foreach x [list 1 2] {
      label $p.l.l.info.sel.e$x -text "[set sel$x]" -relief sunken -bd 1
      pack $p.l.l.info.sel.e$x -side left -expand yes -fill x
    }
    
    switch $type {
      contacts {
	frame $p.l.l.info.other
	pack $p.l.l.info.other -side left
	label $p.l.l.info.other.cutoff -text "Cutoff: $cutoff"
	pack $p.l.l.info.other.cutoff -side left
      }
      hbonds {
	frame $p.l.l.info.other
	pack $p.l.l.info.other -side left
	label $p.l.l.info.other.cutoff_l -text "Cutoff: $cutoff" 
	label $p.l.l.info.other.angle_l -text "Angle: $angle"
	pack $p.l.l.info.other.cutoff $p.l.l.info.other.angle -side left
      }
    }
    
    # Display selection
    frame $p.l.l.rep -relief ridge -bd 4
    pack $p.l.l.rep -side top -expand yes -fill x 

    label $p.l.l.rep.l -text "Representation:"
    pack $p.l.l.rep.l -side top -anchor w
    foreach x [list 1] {
      frame $p.l.l.rep.disp$x
      pack $p.l.l.rep.disp$x -side left

      text $p.l.l.rep.disp$x.e -exportselection yes -height 3 -width 25 -wrap word
      $p.l.l.rep.disp$x.e insert end [set sel$x]
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

    button $p.l.l.rep.but -text "Update\nVMD" -command "[namespace parent]::UpdateSelection $self"
    pack $p.l.l.rep.but -side left


    if {$type eq "rms"} {
      # Clustering
      frame $p.l.l.cluster -relief ridge -bd 2
      pack $p.l.l.cluster -side top
      
      label $p.l.l.cluster.rthres_label -text "r(thres,rel):"
      entry $p.l.l.cluster.rthres -width 5 -textvariable [namespace current]::r_thres_rel
      label $p.l.l.cluster.ncrit_label -text "N(crit,rel):"
      entry $p.l.l.cluster.ncrit -width 5 -textvariable [namespace current]::N_crit_rel
      checkbutton $p.l.l.cluster.graphics -text "Graphics" -variable [namespace current]::clustering_graphics
      button $p.l.l.cluster.bt -text "Cluster" -command "[namespace parent]::Cluster $self"
      pack $p.l.l.cluster.rthres_label $p.l.l.cluster.rthres $p.l.l.cluster.ncrit_label $p.l.l.cluster.ncrit $p.l.l.cluster.graphics $p.l.l.cluster.bt -side left 
    }
    
    # Save button
    frame $p.l.l.save
    button $p.l.l.save.b -text "Save Data" -command "[namespace parent]::SaveDataBrowse $self"
    label $p.l.l.save.l -text "Format:"
    eval tk_optionMenu $p.l.l.save.m [namespace current]::save_format $save_format_list

    pack $p.l.l.save -side left
    pack $p.l.l.save.b $p.l.l.save.l $p.l.l.save.m -side left

    # View button
    button $p.l.l.view -text "View Data" -command "[namespace parent]::ViewData $self"
    pack $p.l.l.view -side left


    # Destroy button
    button $p.l.l.destroy -text "Destroy" -command "[namespace parent]::Destroy $self"
    pack $p.l.l.destroy -side right

    set grid 10
    [namespace parent]::Graph $self
  }
}


proc rmsdtt2::Graph {self} {
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
	    
	    $plot bind $key <Enter> "[namespace parent]::ShowPoint $self $key $data($key) 1"
	    $plot bind $key <B1-ButtonRelease> "[namespace parent]::MapPoint $self $key $data($key)" 
	    $plot bind $key <B2-ButtonRelease> "[namespace parent]::ShowPoint $self $key $data($key) 0"
	    $plot bind $key <B3-ButtonRelease> "[namespace parent]::MapCluster1 $self $key"
	    $plot bind $key <Shift-B3-ButtonRelease> "[namespace parent]::MapCluster2 $self $data($key) 1"
	    $plot bind $key <Control-B3-ButtonRelease> "[namespace parent]::MapCluster2 $self $data($key) 0"
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


proc rmsdtt2::ViewData {self} {
  set r [toplevel ".${self}_raw"]
  wm title $r "View $self"
  
  text $r.data -exportselection yes -width 80 -xscrollcommand "$r.xs set" -yscrollcommand "$r.ys set"
  scrollbar $r.xs -orient horizontal -command "$r.data xview"
  scrollbar $r.ys -orient vertical   -command "$r.data yview"
  
  pack $r.xs -side bottom -fill x
  pack $r.ys -side right -fill y
  pack $r.data -side right -expand yes -fill both
  
  set opt(dataformat) [set ${self}::dataformat]
  $r.data insert end [SaveData_tab [set ${self}::vals] [set ${self}::keys] [array get opt]]
}


proc rmsdtt2::Zoom {self zoom} {
  set grid [set ${self}::grid]
  set plot [set ${self}::plot]

  set old [expr 1.0*$grid]
  if {$zoom == -1} {
    if {$grid <= 1} return
    incr ${self}::grid -1
  } elseif {$zoom == 1} {
    if {$grid >= 20} return
    incr ${self}::grid
  }

  set grid [set ${self}::grid]
  
  set factor [expr $grid/$old]
  $plot scale all 0 0 $factor $factor
}


proc rmsdtt2::AddRep {self key} {
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
    set indices [split $key :]
    if {$rep_color1 eq "ColorID"} {
      set rep_list [[namespace current]::AddRep1 [lindex $indices 0] [lindex $indices 1] $rep_sel1 $rep_style1 [list $rep_color1 $rep_colorid1]]
    } else {
      set rep_list [[namespace current]::AddRep1 [lindex $indices 0] [lindex $indices 1] $rep_sel1 $rep_style1 $rep_color1]
    }
  }
  set ${self}::rep_list($key) $rep_list
  set ${self}::rep_num($key) $rep_num
}


proc rmsdtt2::DelRep {self key} {
  set rep_num [set ${self}::rep_num($key)]
  incr rep_num -1
  #puts "del $key = $rep_num"
  set indices [split $key :]
  if {$rep_num == 0} {
    [namespace current]::DelRep1 [set ${self}::rep_list($key)] [lindex $indices 0]
  }
  set ${self}::rep_num($key) $rep_num
}


proc rmsdtt2::ShowPoint {self key val stick} {
  if {[set ${self}::info_sticky] && $stick} return
  
  set indices [split $key ,:]
  set i [lindex $indices 0]
  set j [lindex $indices 1]
  set k [lindex $indices 2]
  set l [lindex $indices 3]
  set ${self}::info_key1 [format "%3d %3d" $i $j]
  set ${self}::info_key2 [format "%3d %3d" $k $l]
  set ${self}::info_value [format "[set ${self}::dataformat]" $val]
}


proc rmsdtt2::MapPoint {self key data} {
  set plot [set ${self}::plot]
  set add_rep [set ${self}::add_rep($key)]
  
  set indices [split $key ,]
  set key1 [lindex $indices 0]
  set key2 [lindex $indices 1]
  
  if {$add_rep == 0 } {
    set color black
    [namespace current]::AddRep $self $key1
    [namespace current]::AddRep $self $key2
    set add_rep 1
  } else {
    set color [set ${self}::colors($key)]
    [namespace current]::DelRep $self $key1
    [namespace current]::DelRep $self $key2
    set add_rep 0
  }
  $plot itemconfigure $key -outline $color

  set ${self}::add_rep($key) $add_rep
  [namespace current]::ShowPoint $self $key $data 0
}


proc rmsdtt2::MapCluster1 {self key} {
  variable add_rep

  set keys [set ${self}::keys]
  set type [set ${self}::type]
  set plot [set ${self}::plot]
  array set data [array get ${self}::data]

  set indices [split $key ,:]
  set i [lindex $indices 0]
  set j [lindex $indices 1]
  set ref1 "$i:$j"

  [namespace current]::MapClear $self

  [namespace current]::AddRep $self $ref1
  foreach mykey [array names data $ref1,*] {
    set indices [split $mykey ,:]
    set k [lindex $indices 2]
    set l [lindex $indices 3]
    if {$type eq "rms"} {
      if {$data($mykey) <= $data($key)} {
	set color black
	$plot itemconfigure $mykey -outline $color
	set ${self}::add_rep($mykey) 1
	[namespace current]::AddRep $self $k:$l
      }
    } else {
      if {$data($mykey) >= $data($key)} {
	set color black
	$plot itemconfigure $mykey -outline $color
	set ${self}::add_rep($mykey) 1
	[namespace current]::AddRep $self $k:$l
      }
    }
  }
  foreach mykey [array names data *,$ref1] {
    set indices [split $mykey ,:]
    set k [lindex $indices 0]
    set l [lindex $indices 1]
    if {$type eq "rms"} {
      if {$data($mykey) <= $data($key)} {
	set color black
	$plot itemconfigure $mykey -outline $color
	set ${self}::add_rep($mykey) 1
	[namespace current]::AddRep $self $k:$l
      }
    } else {
      if {$data($mykey) >= $data($key)} {
	set color black
	$plot itemconfigure $mykey -outline $color
	set ${self}::add_rep($mykey) 1
	[namespace current]::AddRep $self $k:$l
      }
    }
  }

  [namespace current]::ShowPoint $self $key $data($key) 0
}


proc rmsdtt2::MapCluster2 {self val mode} {
  set plot [set ${self}::plot]
  array set data [array get ${self}::data]

  [namespace current]::MapClear $self
  foreach mykey [set ${self}::keys] {
    set indices [split $mykey ,]
    set key1 [lindex $indices 0]
    set key2 [lindex $indices 1]
    if {$mode} {
      if {$data($mykey) >= $val} {
	set color black
	$plot itemconfigure $mykey -outline $color
	[namespace current]::AddRep $self $key1
	[namespace current]::AddRep $self $key2
	set ${self}::add_rep($mykey) 1
      }
    } else {
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


proc rmsdtt2::MapClear {self} {
  set plot [set ${self}::plot]
  
  foreach key [set ${self}::keys] {
    if {[set ${self}::add_rep($key)] == 1 } {
      $plot itemconfigure $key -outline [set ${self}::colors($key)]
      set ${self}::add_rep($key) 0
    }
  }

  foreach key [array names ${self}::rep_list] {
    if {[set ${self}::rep_num($key)] > 0} {
      set indices [split $key :]
      set i [lindex $indices 0]
      [namespace current]::DelRep1 [set ${self}::rep_list($key)] $i
      set ${self}::rep_num($key) 0
    }
  }
}


proc rmsdtt2::UpdateSelection {self} {
  set p [set ${self}::p]
  set rep_style1 [set ${self}::rep_style1]
  set rep_color1 [set ${self}::rep_color1]
  set rep_colorid1 [set ${self}::rep_colorid1]
  
  array set rep_list [array get ${self}::rep_list]

  set rep_sel1 [[namespace current]::ParseSel [$p.l.l.rep.disp1.e get 1.0 end] ""]
  foreach key [array names rep_list] {
    if {[set ${self}::rep_num($key)] > 0} {
      set indices [split $key :]
      set i [lindex $indices 0]
      set j [lindex $indices 1]
      set repname [mol repindex $i $rep_list($key)]
      mol modselect $repname $i $rep_sel1
      switch $rep_style1 {
	HBonds {
	  mol modstyle  $repname $i $rep_style1 [set ${self}::cutoff] [set ${self}::angle]
	}
	default {
	  mol modstyle  $repname $i $rep_style1
	}
      }
      switch $rep_color1 {
	ColorID {
	  mol modcolor  $repname $i $rep_color1 $rep_colorid1
	}
	default {
	  mol modcolor  $repname $i $rep_color1
	}
      }
    }
  }
}


proc rmsdtt2::Destroy {self} {
  [namespace current]::MapClear $self
  catch {destroy [set ${self}::p]}
  [namespace current]::Objdelete $self
}
