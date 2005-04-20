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
#    Main GUI for the rmsdtt2 plugin.


package provide rmsdtt2 2.0

namespace eval rmsdtt2 {
  namespace export rms init
  
  global env
  variable w
  #variable mol1_m_list
  #variable mol_ref

  variable tmpdir
  if { [info exists env(TMPDIR)] } {
    set tmpdir $env(TMPDIR)
  } else {
    set tmpdir /tmp
  }


}

proc rmsdtt2_tk_cb {} {
  ::rmsdtt2::init
  return $rmsdtt2::w
}

proc rmsdtt2::init {} {
  variable w

  # If already initialized, just turn on
  if { [winfo exists .rmsdtt2] } {
    wm deiconify $w
    return
  }
  
  # Create the main window
  set w [toplevel .rmsdtt2]
#  catch {destroy $w}
  wm title $w "RMSD Trajectory Tool"
  wm iconname $w "RMSDTT" 
  wm resizable $w 1 0

  variable mol1_def   top
  variable frame1_def all
  variable mol2_def   top
  variable frame2_def all

  variable mol1_m_list 0
  variable mol1_f_list 0
  variable mol2_m_list 0
  variable mol2_f_list 0

  variable skip1 0
  variable skip2 0

  variable selmod1 "no"
  variable selmod2 "no"

  variable samemols 0

  variable calctype "rms"
  
  variable cutoff 5.0
  variable angle 30.0

  # Menu
  frame $w.menubar -relief raised -bd 2
  pack $w.menubar -padx 1 -fill x

  menubutton $w.menubar.options -text "Options" -underline 0 -menu $w.menubar.options.menu -width 4
  menu $w.menubar.options.menu -tearoff no
  $w.menubar.options.menu add checkbutton -label "Progress bar" -variable [namespace current]::options(progress) -command "[namespace current]::ProgressBar 0 0"
  pack $w.menubar.options -side left

  menubutton $w.menubar.help -text "Help" -underline 0 -menu $w.menubar.help.menu -width 4
  menu $w.menubar.help.menu -tearoff no
  $w.menubar.help.menu add command -label "About" -command [namespace current]::about
  pack $w.menubar.help -side right

#  menubutton $w.menubar.debug -text "Debug" -underline 0 -menu $w.menubar.debug.menu -width 4
#  menu $w.menubar.debug.menu -tearoff no
#  $w.menubar.debug.menu add command -label "Reload packages" -command [source /home/luis/vmdplugins/rmsdtt/gui.tcl]
#  pack $w.menubar.debug -side right

  # Status line
  #--
  frame $w.status
  label $w.status.label -text "Status:"

  canvas $w.status.info -relief sunken -height 20 -highlightthickness 0
  $w.status.info xview moveto 0
  $w.status.info yview moveto 0
  $w.status.info create rect 0 0 0 0 -tag progress -fill cyan -outline cyan
  $w.status.info create text 5 4 -tag txt -anchor nw

  pack $w.status -side bottom -fill x -expand yes
  pack $w.status.label -side left
  pack $w.status.info -side left -fill x -expand yes
  #--


  # Frame for molecule/frame selection
  #--
  frame $w.mols
  pack $w.mols -side top -expand yes -fill x
  #--
  
  checkbutton $w.mols.same -text "Same selections" -variable [namespace current]::samemols -command [namespace current]::UpdateGUI
  pack $w.mols.same -side top

  # SET1
  #--
  frame $w.mols.mol1 -relief ridge -bd 4
  label $w.mols.mol1.title -text "Set 1"
  pack $w.mols.mol1 -side left -anchor nw -expand yes -fill x
  pack $w.mols.mol1.title -side top
  #--

  # a1
  #--
  frame $w.mols.mol1.a -relief ridge -bd 2
  label $w.mols.mol1.a.title -text "Atom selection:"
  text $w.mols.mol1.a.sel -exportselection yes -height 5 -width 30 -wrap word
  $w.mols.mol1.a.sel insert end "all"
  radiobutton $w.mols.mol1.a.no -text "None"      -variable [namespace current]::selmod1 -value "no"
  radiobutton $w.mols.mol1.a.bb -text "Backbone"  -variable [namespace current]::selmod1 -value "bb"
  radiobutton $w.mols.mol1.a.tr -text "Trace"     -variable [namespace current]::selmod1 -value "tr"
  radiobutton $w.mols.mol1.a.sc -text "Sidechain" -variable [namespace current]::selmod1 -value "sc"

  pack $w.mols.mol1.a -side bottom -expand yes -fill x
  pack $w.mols.mol1.a.title
  pack $w.mols.mol1.a.sel -side left -expand yes -fill x
  pack $w.mols.mol1.a.no $w.mols.mol1.a.bb $w.mols.mol1.a.tr $w.mols.mol1.a.sc -side top -anchor w
  #--

  # m1
  #--
  frame $w.mols.mol1.m -relief ridge -bd 2
  label $w.mols.mol1.m.title -text "Molecules:"
  radiobutton $w.mols.mol1.m.all -text "All"    -variable [namespace current]::mol1_def -value "all"
  radiobutton $w.mols.mol1.m.top -text "Top"    -variable [namespace current]::mol1_def -value "top"
  radiobutton $w.mols.mol1.m.act -text "Active" -variable [namespace current]::mol1_def -value "act"
  frame $w.mols.mol1.m.ids
  radiobutton $w.mols.mol1.m.ids.r -text "IDs:" -variable [namespace current]::mol1_def -value "id"
  entry $w.mols.mol1.m.ids.list -width 5 -textvariable [namespace current]::mol1_m_list

  pack $w.mols.mol1.m -side left
  pack $w.mols.mol1.m.title -side top
  pack $w.mols.mol1.m.all $w.mols.mol1.m.top $w.mols.mol1.m.act $w.mols.mol1.m.ids -side top -anchor w 
  pack $w.mols.mol1.m.ids.r $w.mols.mol1.m.ids.list -side left
  #--
  
  # f1
  #--
  frame $w.mols.mol1.f -relief ridge -bd 2
  label $w.mols.mol1.f.title -text "Frames:"
  radiobutton $w.mols.mol1.f.all -text "All"     -variable [namespace current]::frame1_def -value "all"
  radiobutton $w.mols.mol1.f.top -text "Current" -variable [namespace current]::frame1_def -value "cur"
  frame $w.mols.mol1.f.ids
  radiobutton $w.mols.mol1.f.ids.r -text "IDs:"  -variable [namespace current]::frame1_def -value "id"
  entry $w.mols.mol1.f.ids.list -width 5 -textvariable [namespace current]::mol1_f_list
  frame $w.mols.mol1.f.skip
  label $w.mols.mol1.f.skip.l -text "Skip:"
  entry $w.mols.mol1.f.skip.e -width 3 -textvariable [namespace current]::skip1

  pack $w.mols.mol1.f -side left -anchor n -expand yes -fill x
  pack $w.mols.mol1.f.title -side top
  pack $w.mols.mol1.f.all $w.mols.mol1.f.top -side top -anchor w 
  pack $w.mols.mol1.f.ids -side top -anchor w -expand yes -fill x
  pack $w.mols.mol1.f.skip -side top -anchor w 
  pack $w.mols.mol1.f.ids.r -side left
  pack $w.mols.mol1.f.ids.list -side left -expand yes -fill x
  pack $w.mols.mol1.f.skip.l $w.mols.mol1.f.skip.e -side left
  #--


  # SET2
  #--
  frame $w.mols.mol2 -relief ridge -bd 4
  label $w.mols.mol2.title -text "Set 2"
  pack $w.mols.mol2 -expand yes -fill x -side top -anchor n
  pack $w.mols.mol2.title -side top
  #--

  # a2
  #--
  frame $w.mols.mol2.a -relief ridge -bd 2
  label $w.mols.mol2.a.title -text "Atom selection:"
  text $w.mols.mol2.a.sel -exportselection yes -height 5 -width 30 -wrap word
  $w.mols.mol2.a.sel insert end "all"
  radiobutton $w.mols.mol2.a.no -text "None"      -variable [namespace current]::selmod2 -value "no"
  radiobutton $w.mols.mol2.a.bb -text "Backbone"  -variable [namespace current]::selmod2 -value "bb"
  radiobutton $w.mols.mol2.a.tr -text "Trace"     -variable [namespace current]::selmod2 -value "tr"
  radiobutton $w.mols.mol2.a.sc -text "Sidechain" -variable [namespace current]::selmod2 -value "sc"

  pack $w.mols.mol2.a -side bottom -expand yes -fill x
  pack $w.mols.mol2.a.title
  pack $w.mols.mol2.a.sel -side left -expand yes -fill x
  pack $w.mols.mol2.a.no $w.mols.mol2.a.bb $w.mols.mol2.a.tr $w.mols.mol2.a.sc -side top -anchor w
  #--

  # m2
  #--
  frame $w.mols.mol2.m -relief ridge -bd 2
  label $w.mols.mol2.m.title -text "Molecules:"
  radiobutton $w.mols.mol2.m.all -text "All"    -variable [namespace current]::mol2_def -value "all"
  radiobutton $w.mols.mol2.m.top -text "Top"    -variable [namespace current]::mol2_def -value "top"
  radiobutton $w.mols.mol2.m.act -text "Active" -variable [namespace current]::mol2_def -value "act"
  frame $w.mols.mol2.m.ids
  radiobutton $w.mols.mol2.m.ids.r -text "IDs:" -variable [namespace current]::mol2_def -value "id"
  entry $w.mols.mol2.m.ids.list -width 5 -textvariable [namespace current]::mol2_m_list

  pack $w.mols.mol2.m -side left
  pack $w.mols.mol2.m.title -side top
  pack $w.mols.mol2.m.all $w.mols.mol2.m.top $w.mols.mol2.m.act $w.mols.mol2.m.ids -side top -anchor w 
  pack $w.mols.mol2.m.ids.r $w.mols.mol2.m.ids.list -side left
  #--
  
  # f2
  #--
  frame $w.mols.mol2.f -relief ridge -bd 2
  label $w.mols.mol2.f.title -text "Frames:"
  radiobutton $w.mols.mol2.f.all -text "All"     -variable [namespace current]::frame2_def -value "all"
  radiobutton $w.mols.mol2.f.top -text "Current" -variable [namespace current]::frame2_def -value "cur"
  frame $w.mols.mol2.f.ids
  radiobutton $w.mols.mol2.f.ids.r -text "IDs:"  -variable [namespace current]::frame2_def -value "id"
  entry $w.mols.mol2.f.ids.list -width 5 -textvariable [namespace current]::mol2_f_list
  frame $w.mols.mol2.f.skip
  label $w.mols.mol2.f.skip.l -text "Skip:"
  entry $w.mols.mol2.f.skip.e -width 3 -textvariable [namespace current]::skip2

  pack $w.mols.mol2.f -side left -anchor n -expand yes -fill x
  pack $w.mols.mol2.f.title -side top
  pack $w.mols.mol2.f.all $w.mols.mol2.f.top -side top -anchor w 
  pack $w.mols.mol2.f.ids -side top -anchor w -expand yes -fill x
  pack $w.mols.mol2.f.skip -side top -anchor w 
  pack $w.mols.mol2.f.ids.r -side left
  pack $w.mols.mol2.f.ids.list -side left -expand yes -fill x
  pack $w.mols.mol2.f.skip.l $w.mols.mol2.f.skip.e -side left
  #--

 
  # Calculation
  #--
  frame $w.calc -relief ridge -bd 4
  label $w.calc.label -text "Calculation:"

  radiobutton $w.calc.rms      -text "Rmsd"      -variable [namespace current]::calctype -value "rms"      -command [namespace current]::UpdateGUI
  radiobutton $w.calc.contacts -text "Contacts" -variable [namespace current]::calctype -value "contacts" -command [namespace current]::UpdateGUI
  radiobutton $w.calc.hbonds   -text "Hbonds"   -variable [namespace current]::calctype -value "hbonds"   -command [namespace current]::UpdateGUI

  label $w.calc.cutoff_l -text "Cutoff:"
  entry $w.calc.cutoff -width 5 -textvariable [namespace current]::cutoff
  label $w.calc.angle_l -text "Angle:"
  entry $w.calc.angle  -width 5 -textvariable [namespace current]::angle

  button $w.calc.new -text "New object" -command "[namespace current]::CreateObject"

  pack $w.calc -side left -expand yes -fill x
  pack $w.calc.label $w.calc.rms $w.calc.contacts $w.calc.hbonds $w.calc.cutoff_l $w.calc.cutoff $w.calc.angle_l $w.calc.angle -side left
  pack $w.calc.new -side right
  #--

  [namespace current]::UpdateGUI

}

proc rmsdtt2::CreateObject {} {
  variable w
  variable mol1_def
  variable frame1_def
  variable mol1_m_list
  variable mol1_f_list
  variable skip1
  variable selmod1

  variable mol2_def
  variable frame2_def
  variable mol2_m_list
  variable mol2_f_list
  variable skip2
  variable selmod2

  variable samemols
  variable calctype
  variable cutoff
  variable angle

  if {$samemols} {
    set mol2_def $mol1_def
    set frame2_def $frame1_def
    set mol2_m_list $mol1_m_list
    set mol2_f_list $mol1_f_list
    set skip2 $skip1
    set selmod2 $selmod1
    $w.mols.mol2.a.sel config -state normal
    $w.mols.mol2.a.sel delete 1.0 end
    $w.mols.mol2.a.sel insert end [$w.mols.mol1.a.sel get 1.0 end]
    $w.mols.mol2.a.sel config -state disable
  }

  # Parse list of molecules
  set mol1 [[namespace current]::ParseMols $mol1_def $mol1_m_list]
  set mol2 [[namespace current]::ParseMols $mol2_def $mol2_m_list]

  # Parse frames
  set frame1 [[namespace current]::ParseFrames $frame1_def $mol1 $skip1 $mol1_f_list]
  set frame2 [[namespace current]::ParseFrames $frame2_def $mol2 $skip2 $mol2_f_list]

  #puts "$mol1 $frame1 $mol2 $frame2 $selmod"
  set sel1 [ParseSel [$w.mols.mol1.a.sel get 1.0 end] $selmod1]
  set sel2 [ParseSel [$w.mols.mol2.a.sel get 1.0 end] $selmod2]

  set defaults [list mol1 $mol1 frame1 $frame1 mol2 $mol2 frame2 $frame2 sel1 $sel1 sel2 $sel2 rep_sel1 $sel1 type $calctype]
  switch $calctype {
    contacts {
      lappend defaults cutoff $cutoff
    }
    hbonds {
      lappend defaults cutoff $cutoff angle $angle
    }
  }
  set r [eval [namespace current]::Objnew ":auto" $defaults]

#  [namespace current]::Objdump $r
  [namespace current]::Status "Calculating $calctype ..."
  [namespace current]::$calctype $r
  [namespace current]::Status "Creating graph for $r ..."
  [namespace current]::NewPlot $r
#  [namespace current]::ClearStatus

}


proc rmsdtt2::UpdateGUI {} {
  variable w
  variable samemols
  variable calctype
   
  if {$samemols} {
    set state "disable"
  } else {
    set state "normal"
  }
  
  foreach widget [[namespace current]::wlist $w.mols.mol2] {
    if {[winfo class $widget] eq "Frame"} {
      continue
    }
    $widget config -state $state
  }

  switch $calctype {
    contacts {
      $w.calc.cutoff_l config -state normal
      $w.calc.cutoff   config -state normal
      $w.calc.angle_l  config -state disable
      $w.calc.angle    config -state disable
    }
    hbonds {
      $w.calc.cutoff_l config -state normal
      $w.calc.cutoff   config -state normal
      $w.calc.angle_l  config -state normal
      $w.calc.angle    config -state normal
    }
    default {
      $w.calc.cutoff_l config -state disable
      $w.calc.cutoff   config -state disable
      $w.calc.angle_l  config -state disable
      $w.calc.angle    config -state disable
    }
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
	    
	    $plot bind $key <Enter> "[namespace current]::ShowPoint $key $data($key) 1"
	    $plot bind $key <B1-ButtonRelease> "[namespace current]::MapPoint $key $data($key)" 
	    $plot bind $key <B2-ButtonRelease> "[namespace current]::ShowPoint $key $data($key) 0"
	    $plot bind $key <B3-ButtonRelease> "[namespace current]::MapCluster1 $key"
	    $plot bind $key <Shift-B3-ButtonRelease> "[namespace current]::MapCluster2g $data($key)"
	    $plot bind $key <Control-B3-ButtonRelease> "[namespace current]::MapCluster2l $data($key)"
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
	$scale bind "line$val" <Shift-B1-ButtonRelease> "[namespace current]::MapCluster2g $val"
	$scale bind "line$val" <Control-B1-ButtonRelease> "[namespace current]::MapCluster2l $val"
      } else {
	$scale create text [expr $rg_w+1] $y -text [format "%4i" [expr int($val)]] -anchor w -font [list helvetica 6 normal] -tag "line$val"
	$scale bind "line$val" <Shift-B1-ButtonRelease> "[namespace current]::MapCluster2g $val"
	$scale bind "line$val" <Control-B1-ButtonRelease> "[namespace current]::MapCluster2l $val"
      }
      set val [expr $val+ $reg]
      set y [expr $y+$lb_h]
    }
    
    # Clear button
    button $p.u.r.clear -text "Clear" -command "[namespace current]::MapClear"
    pack $p.u.r.clear -side bottom

    # Zoom
    frame $p.u.r.zoom  -relief ridge -bd 2
    pack $p.u.r.zoom -side bottom

    label $p.u.r.zoom.label -text "Zoom"
    button $p.u.r.zoom.incr -text "+" -command "[namespace current]::Zoom 1"
    entry $p.u.r.zoom.val -width 2 -textvariable [namespace current]::grid
    button $p.u.r.zoom.decr -text "-" -command "[namespace current]::Zoom -1"
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
 	$p.l.l.rep.disp$x.style.s.list add radiobutton -label $entry -variable [namespace current]::rep_style$x -value $entry -command "[namespace current]::UpdateSelection" -font [list Helvetica 8]
      }

      menubutton $p.l.l.rep.disp$x.style.c -text "Color" -menu $p.l.l.rep.disp$x.style.c.list -textvariable [namespace current]::rep_color$x -relief raised -font [list Helvetica 8]
      menu $p.l.l.rep.disp$x.style.c.list
      foreach entry $rep_color_list {
 	if {$entry eq "ColorID"} {
 	  $p.l.l.rep.disp$x.style.c.list add radiobutton -label $entry -variable [namespace current]::rep_color$x -value $entry -command "$p.l.l.rep.disp$x.style.id config -state normal; [namespace current]::UpdateSelection" -font [list Helvetica 8]
 	} else {
 	  $p.l.l.rep.disp$x.style.c.list add radiobutton -label $entry -variable [namespace current]::rep_color$x -value $entry -command "$p.l.l.rep.disp$x.style.id config -state disable; [namespace current]::UpdateSelection" -font [list Helvetica 8]
 	}
      }

      menubutton $p.l.l.rep.disp$x.style.id -text "ColorID" -menu $p.l.l.rep.disp$x.style.id.list -textvariable [namespace current]::rep_colorid$x -relief raised -state disable -font [list Helvetica 8]
      menu $p.l.l.rep.disp$x.style.id.list
      for {set i 0} {$i <= 16} {incr i} {
  	$p.l.l.rep.disp$x.style.id.list add radiobutton -label $i -variable [namespace current]::rep_colorid$x -value $i -command "[namespace current]::UpdateSelection" -font [list Helvetica 8]
      }
      
      pack $p.l.l.rep.disp$x.style.s $p.l.l.rep.disp$x.style.c $p.l.l.rep.disp$x.style.id -side left
    }

    button $p.l.l.rep.but -text "Update\nVMD" -command "[namespace current]::UpdateSelection"
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
      button $p.l.l.cluster.bt -text "Cluster" -command "[namespace current]::Cluster"
      pack $p.l.l.cluster.rthres_label $p.l.l.cluster.rthres $p.l.l.cluster.ncrit_label $p.l.l.cluster.ncrit $p.l.l.cluster.graphics $p.l.l.cluster.bt -side left 
    }
    
    # Save button
    frame $p.l.l.save
    button $p.l.l.save.b -text "Save Data" -command "[namespace current]::SaveData"
    label $p.l.l.save.l -text "Format:"
    eval tk_optionMenu $p.l.l.save.m [namespace current]::save_format $save_format_list

    pack $p.l.l.save -side left
    pack $p.l.l.save.b $p.l.l.save.l $p.l.l.save.m -side left

    # View button
    button $p.l.l.view -text "View Data" -command "[namespace current]::ViewData"
    pack $p.l.l.view -side left


    # Destroy button
    button $p.l.l.destroy -text "Destroy" -command "[namespace current]::Destroy"
    pack $p.l.l.destroy -side right


    set grid 10
    [namespace parent]::Graph $self
    
    proc SaveData {} {
      variable save_format
      variable self
      variable p
      
      set typeList {
	{"Data Files" ".dat .txt .out"}
	{"All files" ".*"}
      }
      
      set file [tk_getSaveFile -filetypes $typeList -defaultextension ".dat" -title "Select file to save data" -parent $p]

      if { $file == "" } {
        return;
      }

      [namespace parent]::saveData $self $file $save_format
    }

    proc ViewData {} {
      variable self
      variable p
      variable r
      variable keys
      variable vals
      variable dataformat      
      
      set r [toplevel ".${self}_raw"]
      wm title $r "View $self"

      text $r.data -exportselection yes -width 80 -xscrollcommand "$r.xs set" -yscrollcommand "$r.ys set"
      scrollbar $r.xs -orient horizontal -command "$r.data xview"
      scrollbar $r.ys -orient vertical   -command "$r.data yview"

      pack $r.xs -side bottom -fill x
      pack $r.ys -side right -fill y
      pack $r.data -side right -expand yes -fill both

      $r.data insert end "mol1 frame1   mol2 frame2      rmsd\n"
      for {set z 0} {$z < [llength $keys]} {incr z} {
	set key [lindex $keys $z]
	set indices [split $key :,]
	set i [lindex $indices 0]
	set j [lindex $indices 1]
	set k [lindex $indices 2]
	set l [lindex $indices 3]
	$r.data insert end [format "%4d %6d   %4d %6d   $dataformat\n" $i $j $k $l [lindex $vals $z]]
      }

    }

    proc ShowPoint {key val stick} {
      variable info_key1
      variable info_key2
      variable info_value
      variable info_sticky
      variable dataformat
      
      if {$info_sticky && $stick} return

      set indices [split $key ,:]
      set i [lindex $indices 0]
      set j [lindex $indices 1]
      set k [lindex $indices 2]
      set l [lindex $indices 3]
      set info_key1 [format "%3d %3d" $i $j]
      set info_key2 [format "%3d %3d" $k $l]
      set info_value [format "$dataformat" $val]
    }

    proc MapPoint {key data} {
      variable add_rep
      variable plot
      variable max
      variable min
      variable highlight
      variable colors

      set indices [split $key ,]
      set key1 [lindex $indices 0]
      set key2 [lindex $indices 1]
      
      if {$add_rep($key) == 0 } {
	set color black
	[namespace current]::AddRep $key1
	[namespace current]::AddRep $key2
	set add_rep($key) 1
      } else {
	set color $colors($key)
	[namespace current]::DelRep $key1
	[namespace current]::DelRep $key2
	set add_rep($key) 0
      }
      $plot itemconfigure $key -outline $color

      [namespace current]::ShowPoint $key $data 0
    }
 
    proc MapCluster1 {key} {
      variable add_rep
      variable plot
      variable max
      variable min
      variable data
      variable keys
      variable highlight
      variable type
      
      set indices [split $key ,:]
      set i [lindex $indices 0]
      set j [lindex $indices 1]
      set ref1 "$i:$j"

      [namespace current]::MapClear

      [namespace current]::AddRep $ref1
      foreach mykey [array names data $ref1,*] {
	set indices [split $mykey ,:]
	set k [lindex $indices 2]
	set l [lindex $indices 3]
	if {$type eq "rms"} {
	  if {$data($mykey) <= $data($key)} {
	    set color black
	    $plot itemconfigure $mykey -outline $color
	    set add_rep($mykey) 1
	    [namespace current]::AddRep $k:$l
	  }
	} else {
	  if {$data($mykey) >= $data($key)} {
	    set color black
	    $plot itemconfigure $mykey -outline $color
	    set add_rep($mykey) 1
	    [namespace current]::AddRep $k:$l
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
	    set add_rep($mykey) 1
	    [namespace current]::AddRep $k:$l
	  }
	} else {
	  if {$data($mykey) >= $data($key)} {
	    set color black
	    $plot itemconfigure $mykey -outline $color
	    set add_rep($mykey) 1
	    [namespace current]::AddRep $k:$l
	  }
	}
      }

      [namespace current]::ShowPoint $key $data($key) 0

    }

    proc MapCluster2g {val} {
      [namespace current]::MapCluster2 $val 1
    }

    proc MapCluster2l {val} {
      [namespace current]::MapCluster2 $val 0
    }

    proc MapCluster2 {val mode} {
      variable add_rep
      variable plot
      variable max
      variable min
      variable data
      variable keys
      variable rep_sel1
      variable highlight
      variable type
      
      [namespace current]::MapClear
      foreach mykey $keys {
	set indices [split $mykey ,]
	set key1 [lindex $indices 0]
	set key2 [lindex $indices 1]
	if {$mode} {
	  if {$data($mykey) >= $val} {
	    set color black
	    $plot itemconfigure $mykey -outline $color
	    [namespace current]::AddRep $key1
	    [namespace current]::AddRep $key2
	    set add_rep($mykey) 1
	  }
	} else {
	  if {$data($mykey) <= $val} {
	    set color black
	    $plot itemconfigure $mykey -outline $color
	    [namespace current]::AddRep $key1
	    [namespace current]::AddRep $key2
	    set add_rep($mykey) 1
	  }
	}
      }
    }

    proc MapClear {} {
      variable add_rep
      variable rep_list
      variable rep_num
      variable plot
      variable max
      variable min
      variable data
      variable keys
      variable colors
      
      foreach key $keys {
	if {$add_rep($key) == 1 } {
	  $plot itemconfigure $key -outline $colors($key)
	  set add_rep($key) 0
	}
      }

      foreach key [array names rep_list] {
	if {$rep_num($key) > 0} {
	  set indices [split $key :]
	  set i [lindex $indices 0]
	  [namespace parent]::DelRep1 $rep_list($key) $i
	  set rep_num($key) 0
	}
      }

    }

    proc UpdateSelection {} {
      variable p
      variable rep_sel1
      variable rep_style1
      variable rep_color1
      variable rep_colorid1
      variable rep_list
      variable rep_num

      set rep_sel1 [[namespace parent]::ParseSel [$p.l.l.rep.disp1.e get 1.0 end] ""]
      foreach key [array names rep_list] {
	if {$rep_num($key) > 0} {
	  set indices [split $key :]
	  set i [lindex $indices 0]
	  set j [lindex $indices 1]
	  set repname [mol repindex $i $rep_list($key)]
	  mol modselect $repname $i $rep_sel1
	  switch $rep_style1 {
	    HBonds {
	      variable cutoff
	      variable angle
	      mol modstyle  $repname $i $rep_style1 $cutoff $angle
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

    proc Zoom {zoom} {
      variable grid
      variable self
      variable plot
      
      set old [expr 1.0*$grid]
      if {$zoom == -1} {
	if {$grid <= 1} return
	incr grid -1
      } elseif {$zoom == 1} {
	if {$grid >= 20} return
	incr grid
      }
      
      set factor [expr $grid/$old]
      $plot scale all 0 0 $factor $factor
    }

    proc Cluster {} {
      variable keys
      variable data
      variable csize
      variable mol1
      variable frame1
      variable min
      variable max
      variable plot
      variable clustering_graphics
      variable r_thres_rel
      variable N_crit_rel
      variable add_rep
      variable highlight
      
      puts "Clustering: $clustering_graphics"
      
      if {$clustering_graphics} [namespace current]::MapClear

      set nc 0
      foreach i $mol1 {
	foreach j [lindex $frame1 [lsearch -exact $mol1 $i]] {
	  set csize($i:$j) 0
	  set conf($i:$j) 1
	  incr nc
	}
      }
      
      set z 0
      while {$z>=0} {
	puts "iteration $z:"

	### 2.
	set r_max 0
	foreach key $keys {
	  set indices [split $key ,]
	  set key1 [lindex $indices 0]
	  set key2 [lindex $indices 1]
	  if {$conf($key1) == 0 || $conf($key2) == 0} continue
	  #if {$key1 eq $key2} continue
	  if {$data($key) > $r_max} {
	    set r_max $data($key)
	  }
	}
	set r_thres [expr $r_thres_rel * $r_max]
	
	### 3.
	foreach key $keys {
	  set indices [split $key ,]
	  set key1 [lindex $indices 0]
	  set key2 [lindex $indices 1]
	  if {$conf($key1) == 0 || $conf($key2) == 0} continue
	  if {$data($key) <= $r_thres} {
	    set csize($key1) [expr $csize($key1) +1]
	    if {$key1 ne $key2} {
	      set csize($key2) [expr $csize($key2) +1]
	    }
	    if {$clustering_graphics} {
	      set add_rep($key) 1
	    }
	  }
	}
	set N_max 0
	foreach key [array names csize] {
	  if {$conf($key) == 0} continue
	  if {$csize($key) > $N_max} {
	    set N_max $csize($key)
	  }
	}
	set N_crit [expr $N_crit_rel * $N_max]
	
	puts [format "\tN_crit_rel:  %4.2f    N_crit:  %5.2f   N_max: %5.2f" \
		$N_crit_rel $N_crit $N_max]
	puts [format "\tr_thres_rel: %4.2f    r_thres: %5.2f   r_max: %5.2f" \
		$r_thres_rel $r_thres $r_max]
	puts "\tNumber confs: $nc"

	### 4.
	set stop_here 1
	foreach key [array names csize] {
	  if {$conf($key) == 0} continue
	  if {$csize($key) < $N_crit} {
	    set stop_here 0
	    incr nc -1
	    set conf($key) 0
	    if {$clustering_graphics} {
	      foreach mykey [array names data $key,*] {
		set add_rep($mykey) 0
	      }
	      foreach mykey [array names data *,$key] {
		set add_rep($mykey) 0
	      }
	    }
	  }
	}

	incr z

	if {$stop_here == 1} {
	  if {$clustering_graphics} {
	    foreach key [array names add_rep] {
	      if {$add_rep($key) == 1} {
		if {$data($key) <= $r_thres} {
		  $plot itemconfigure $key -outline black
		} else {
		  set add_rep($key) 0
		}
	      }
	    }
	  }
	  puts -nonewline "\t"
	  foreach key [array names csize] {
	    if {$conf($key) == 0} continue
	    puts -nonewline "$key\($csize($key)) "
	    if {$clustering_graphics} {
	      [namespace current]::AddRep $key
	    }
	  }
	  puts ""
	  return
	}

	foreach key [array names csize] {
	  if {$conf($key) == 0} continue
	  set csize($key) 0
	}
	incr z
      }
    }

    proc AddRep {key} {
      variable rep_list
      variable rep_num
      variable p
      variable rep_sel1
      variable rep_style1
      variable rep_color1
      variable rep_colorid1

      set rep_sel1 [[namespace parent]::ParseSel [$p.l.l.rep.disp1.e get 1.0 end] ""]
      set indices [split $key :]
      set rep_num($key) [expr $rep_num($key) +1]
      #puts "add $key = $rep_num($key)"
      if {$rep_num($key) <= 1} {
	if {$rep_color1 eq "ColorID"} {
	  set rep_list($key) [[namespace parent]::AddRep1 [lindex $indices 0] [lindex $indices 1] $rep_sel1 $rep_style1 [list $rep_color1 $rep_colorid1]]
	} else {
	  set rep_list($key) [[namespace parent]::AddRep1 [lindex $indices 0] [lindex $indices 1] $rep_sel1 $rep_style1 $rep_color1]
	}
      }
    }
    
    proc DelRep {key} {
      variable rep_list
      variable rep_num
      
      set indices [split $key :]
      set rep_num($key) [expr $rep_num($key) -1]
      #puts "del $key = $rep_num($key)"
      if {$rep_num($key) == 0} {
	[namespace parent]::DelRep1 $rep_list($key) [lindex $indices 0]
      }
    }

    proc Destroy {} {
      variable self
      variable p

      [namespace current]::MapClear
      catch {destroy $p}
      [namespace parent]::Objdelete $self
    }
  }
}


proc rmsdtt2::ColorScale {max min i l} {
  if {$max == 0} {
    set max 1.0
  }

  set h [expr 2.0/3.0]
#  set l 1.0
  set s 1.0

  lassign [hls2rgb [expr ($h - $h*$i/$max)] $l $s] r g b

  set r [expr int($r*255)]
  set g [expr int($g*255)]
  set b [expr int($b*255)]
  return [format "#%.2X%.2X%.2X" $r $g $b]
}


proc rmsdtt2::hls2rgb {h l s} {
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


proc rmsdtt2::about { } {
    set vn [package present rmsdtt2]
    tk_messageBox -title "About rmsdtt2 $vn"  -parent .rmsdtt2 -message \
"rmsdtt2 version $vn

Copyright (C) Luis Gracia <lug2002@med.cornell.edu> 

"
}


proc rmsdtt2::ProgressBar {num max} {
  variable w
  variable options

  set wp $w.status.info
  set height [winfo height $wp]

  if {$num == 0} {
    set x 0
    set height 0
    $wp coords progress 0 0 $x $height
    $wp lower progress
    update idletasks
  }

  if {!$options(progress)} return

  if {$max == 0} {
    set x 0
  } else {
    set width [winfo width $wp]
    set x [expr ($num * $width / double($max))]
  }
  $wp coords progress 0 0 $x $height
  $wp lower progress
  update idletasks
}


proc rmsdtt2::Status {txt} {
  variable w
  $w.status.info itemconfigure txt -text $txt
  update idletasks

}


proc rmsdtt2::ClearStatus {} {
  after 1000 "[namespace current]::Status {}"
  after 1000 "[namespace current]::ProgressBar 1 0"
}



