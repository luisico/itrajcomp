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

  variable selmod "no"

  variable samemols 0

  variable calctype "rms"
  
  variable cutoff 5.0

  # Menu
  frame $w.menubar -relief raised -bd 2
  pack $w.menubar -padx 1 -fill x

  menubutton $w.menubar.debug -text "Debug" -underline 0 -menu $w.menubar.debug.menu -width 4
  menubutton $w.menubar.help -text "Help" -underline 0 -menu $w.menubar.help.menu -width 4
  menu $w.menubar.help.menu -tearoff no
  $w.menubar.help.menu add command -label "About" -command [namespace current]::about
  pack $w.menubar.help -side right

#  menu $w.menubar.debug.menu -tearoff no
#  $w.menubar.debug.menu add command -label "Reload packages" -command [source /home/luis/vmdplugins/rmsdtt/gui.tcl]
#  pack $w.menubar.debug -side right

  # Frame for molecule/frame selection
  #--
  frame $w.mols
  pack $w.mols -side top -expand yes -fill x
  #--
  
  # mol1 (reference)
  #--
  frame $w.mols.mol1 -relief ridge -bd 4
  label $w.mols.mol1.title -text "Set 1"
  pack $w.mols.mol1 -side left -anchor nw -expand yes -fill x
  pack $w.mols.mol1.title -side top
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

  # mol2 (reference)
  #--
  frame $w.mols.mol2 -relief ridge -bd 4
  label $w.mols.mol2.title -text "Set 2"
  checkbutton $w.mols.mol2.same -text "Same as set 1" -variable [namespace current]::samemols -command [namespace current]::UpdateGUI
  pack $w.mols.mol2 -expand yes -fill x -side top -anchor n
  pack $w.mols.mol2.title -side top
  pack $w.mols.mol2.same -side bottom
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

  # Atom selection
  #--
  frame $w.atoms -relief ridge -bd 4
  label $w.atoms.title -text "Atom selection:"
  text $w.atoms.sel -exportselection yes -height 5 -width 40 -wrap word
  $w.atoms.sel insert end "resid 5 to 85"
  radiobutton $w.atoms.no -text "None"      -variable [namespace current]::selmod -value "no"
  radiobutton $w.atoms.bb -text "Backbone"  -variable [namespace current]::selmod -value "bb"
  radiobutton $w.atoms.tr -text "Trace"     -variable [namespace current]::selmod -value "tr"
  radiobutton $w.atoms.sc -text "Sidechain" -variable [namespace current]::selmod -value "sc"

  pack $w.atoms -side top -expand yes -fill x
  pack $w.atoms.title
  pack $w.atoms.sel -side left -expand yes -fill x
  pack $w.atoms.no $w.atoms.bb $w.atoms.tr $w.atoms.sc -side top -anchor w
  #--
 
  # Calculation type
  #--
  frame $w.calc
  radiobutton $w.calc.rms      -text "Rmsd"     -variable [namespace current]::calctype -value "rms"
  radiobutton $w.calc.contacts -text "Contacts:" -variable [namespace current]::calctype -value "contacts"
  entry $w.calc.cutoff -width 5 -textvariable [namespace current]::cutoff

  pack $w.calc -side left
  pack $w.calc.rms $w.calc.contacts $w.calc.cutoff -side left -anchor n
  #--

  

  # New-object buttons
  #--
  button $w.new -text "New object" -command "[namespace current]::CreateObject"
  pack $w.new
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
  variable mol2_def
  variable frame2_def
  variable mol2_m_list
  variable mol2_f_list
  variable skip2
  variable selmod
  variable samemols
  variable calctype

  if {$samemols} {
    set mol2_def $mol1_def
    set frame2_def $frame1_def
    set mol2_m_list $mol1_m_list
    set mol2_f_list $mol1_f_list
    set skip2 $skip1
  }

  # Parse list of molecules
  set mol1 [[namespace current]::ParseMols $mol1_def $mol1_m_list]
  set mol2 [[namespace current]::ParseMols $mol2_def $mol2_m_list]

  # Parse frames
  set frame1 [[namespace current]::ParseFrames $frame1_def $mol1 $skip1 $mol1_f_list]
  set frame2 [[namespace current]::ParseFrames $frame2_def $mol2 $skip2 $mol2_f_list]

  #puts "$mol1 $frame1 $mol2 $frame2 $selmod"
  set sel [ParseSel [$w.atoms.sel get 1.0 end] $selmod]
  #puts $sel

  set r [[namespace current]::Objnew ":auto" mol1 $mol1 frame1 $frame1 mol2 $mol2 frame2 $frame2 sel $sel rep_sel $sel type $calctype]

  [namespace current]::$calctype $r
#  [namespace current]::Objdump $r
  [namespace current]::NewPlot $r

}


proc rmsdtt2::UpdateGUI {} {
  variable w
  variable samemols

  set widgets [list m.title m.all m.top m.act m.ids.r m.ids.list f.title f.all f.top f.ids.r f.ids.list f.skip.l f.skip.e]
  if {$samemols} {
    set state "disable"
  } else {
    set state "normal"
  }
  
  foreach widget $widgets {
    $w.mols.mol2.$widget config -state $state
  }

}


proc rmsdtt2::Graph {self} {
  namespace eval [namespace current]::${self}:: {
    variable add_rep
    variable rep_list
    variable rep_num
    variable colors

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
	    $plot bind $key <Shift-B3-ButtonRelease> "[namespace current]::MapCluster2 $key"
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

    set rep_style_list [list Lines Bonds DynamicBonds Hbonds Points VDW CPK Licorice Trace Tube Ribbons NewRibbons Cartoon NewCartoon MSMS Surf VolumeSlice Isosurface Dotted Solvent]
    set rep_color_list [list Name Type ResName ResType ResID Chain SegName Molecule Structure ColorID Beta Occupancy Mass Charge Pos User Index Backbone Throb Timestep Volume]
    set save_format_list [list tab matrix plotmtv plotmtv_binary]

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
    variable rep_style    NewRibbons
    variable rep_color    Molecule
    variable rep_colorid  0
    variable highlight    0.2
    variable save_format  tab
    

    set p [toplevel ".${self}_plot"]
    wm title $p "RMSDtt object $self"
    
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
    set sc_w    30.
    set sc_h   200.
    set off     10.
    set rg_n    50
    set rg_w    10.
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
      $scale create text 12 $y -text [format "%4.2f" $val] -anchor w -font [list helvetica 6 normal]
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
    
    # Display selection
    frame $p.l.l.atoms -relief ridge -bd 4
    frame $p.l.l.atoms.orig
    label $p.l.l.atoms.orig.l -text "Original atom selection:"
    entry $p.l.l.atoms.orig.e -width [expr [llength $sel]*4] -textvariable [namespace current]::sel -state disable
    frame $p.l.l.atoms.sel
    label $p.l.l.atoms.sel.l -text "Display atom selection:"
    text $p.l.l.atoms.sel.e -exportselection yes -height 3 -width 40 -wrap word
    $p.l.l.atoms.sel.e insert end $sel
    button $p.l.l.atoms.sel.b -text "Update" -command "[namespace current]::UpdateSelection"

    pack $p.l.l.atoms -side top -expand yes -fill x
    pack $p.l.l.atoms.orig -side top -anchor w
    pack $p.l.l.atoms.orig.l $p.l.l.atoms.orig.e -side left
    pack $p.l.l.atoms.sel -side top -expand yes -fill x
    pack $p.l.l.atoms.sel.l -side top -anchor w
    pack $p.l.l.atoms.sel.e -side left -expand yes -fill x
    pack $p.l.l.atoms.sel.b -side left

    frame $p.l.l.atoms.reps
    pack $p.l.l.atoms.reps -side top -anchor w

    frame $p.l.l.atoms.reps.style
    label $p.l.l.atoms.reps.style.l -text "Style method:"

    eval tk_optionMenu $p.l.l.atoms.reps.style.m [namespace current]::rep_style $rep_style_list
    pack $p.l.l.atoms.reps.style -side left
    pack $p.l.l.atoms.reps.style.l $p.l.l.atoms.reps.style.m -side left

    frame $p.l.l.atoms.reps.color
    label $p.l.l.atoms.reps.color.l -text "Color method:"
#    eval tk_optionMenu $p.l.l.atoms.reps.color.m [namespace current]::rep_color $rep_color_list
    menubutton $p.l.l.atoms.reps.color.m -text "Color" -menu $p.l.l.atoms.reps.color.m.list -textvariable [namespace current]::rep_color -relief raised
    menu $p.l.l.atoms.reps.color.m.list

    menubutton $p.l.l.atoms.reps.color.id -text "ColorID" -menu $p.l.l.atoms.reps.color.id.list -textvariable [namespace current]::rep_colorid -relief raised -state disable
    menu $p.l.l.atoms.reps.color.id.list
    for {set i 0} {$i <= 16} {incr i} {
      $p.l.l.atoms.reps.color.id.list add radiobutton -label $i -variable [namespace current]::rep_colorid -value $i -command "[namespace current]::UpdateSelection"
    }

    foreach entry $rep_color_list {
      if {$entry eq "ColorID"} {
	$p.l.l.atoms.reps.color.m.list add radiobutton -label $entry -variable [namespace current]::rep_color -value $entry -command "$p.l.l.atoms.reps.color.id config -state normal; [namespace current]::UpdateSelection"
      } else {
	$p.l.l.atoms.reps.color.m.list add radiobutton -label $entry -variable [namespace current]::rep_color -value $entry -command "$p.l.l.atoms.reps.color.id config -state disable; [namespace current]::UpdateSelection"
      }
    }
    pack $p.l.l.atoms.reps.color -side left
    pack $p.l.l.atoms.reps.color.l $p.l.l.atoms.reps.color.m -side left
    pack $p.l.l.atoms.reps.color.id -side left

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

    # Destroy button
    button $p.l.l.destroy -text "Destroy" -command "[namespace current]::Destroy"
    pack $p.l.l.destroy -side right


    set grid 10
    [namespace parent]::Graph $self
    
    proc SaveData {} {
      variable save_format
      variable self
      
      set typeList {
	{"Data Files" ".dat .txt .out"}
	{"All files" ".*"}
      }
      
      set file [tk_getSaveFile -filetypes $typeList -defaultextension ".dat" -title "Select file to save data"]

      if { $file == "" } {
        return;
      }

      [namespace parent]::saveData $self $file $save_format
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

    proc MapCluster2 {key} {
      variable add_rep
      variable plot
      variable max
      variable min
      variable data
      variable keys
      variable rep_sel
      variable highlight
      variable type
      
      [namespace current]::MapClear
      foreach mykey $keys {
	set indices [split $mykey ,]
	set key1 [lindex $indices 0]
	set key2 [lindex $indices 1]
	if {$type eq "rms"} {
	  if {$data($mykey) <= $data($key)} {
	    set color black
	    $plot itemconfigure $mykey -outline $color
	    [namespace current]::AddRep $key1
	    [namespace current]::AddRep $key2
	    set add_rep($mykey) 1
	  }
	} else {
	  if {$data($mykey) >= $data($key)} {
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
      variable rep_sel
      variable rep_style
      variable rep_color
      variable rep_colorid
      variable rep_list
      variable rep_num

      set rep_sel [[namespace parent]::ParseSel [$p.l.l.atoms.sel.e get 1.0 end] ""]
      foreach key [array names rep_list] {
	if {$rep_num($key) > 0} {
	  set indices [split $key :]
	  set i [lindex $indices 0]
	  set j [lindex $indices 1]
	  set repname [mol repindex $i $rep_list($key)]
	  mol modselect $repname $i $rep_sel
	  mol modstyle  $repname $i $rep_style
	  if {$rep_color eq "ColorID"} {
	    mol modcolor  $repname $i $rep_color $rep_colorid
	  } else {
	    mol modcolor  $repname $i $rep_color
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
      variable rep_sel
      variable rep_style
      variable rep_color
      variable rep_colorid
      
      set rep_sel [[namespace parent]::ParseSel [$p.l.l.atoms.sel.e get 1.0 end] ""]
      set indices [split $key :]
      set rep_num($key) [expr $rep_num($key) +1]
      #puts "add $key = $rep_num($key)"
      if {$rep_num($key) <= 1} {
	if {$rep_color eq "ColorID"} {
	  set rep_list($key) [[namespace parent]::AddRep1 [lindex $indices 0] [lindex $indices 1] $rep_sel $rep_style [list $rep_color $rep_colorid]]
	} else {
	  set rep_list($key) [[namespace parent]::AddRep1 [lindex $indices 0] [lindex $indices 1] $rep_sel $rep_style $rep_color]
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
  #set color [[namespace parent]::ColorScale $max $min $data($key) $highlight]
  #$plot itemconfigure $key -outline $color

  set reg [expr $i/$max]

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
    tk_messageBox -title "About rmsdtt2 $vn" -message \
"rmsdtt2 version $vn

Copyright (C) Luis Gracia <lug2002@med.cornell.edu> 

"
}



