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

# maingui.tcl
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
  $w.menubar.help.menu add command -label "About" -command [namespace current]::help_about
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


proc rmsdtt2::help_about { {parent .rmsdtt2} } {
  set vn [package present rmsdtt2]
  tk_messageBox -title "About rmsdtt2 $vn"  -parent $parent -message \
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
